const express = require("express");
const crypto = require("crypto");
const User = require("../../models/User");
const { authenticateToken } = require("../../middleware/auth");
const {
  authLimiter,
  keyManagementLimiter,
} = require("../../middleware/rate-limit");
const { audit } = require("../../utils/auditLogger");

const router = express.Router();

// POST /admin/keygen - Generate key pair for admin user
router.post("/keygen", keyManagementLimiter, async (req, res) => {
  try {
    // restriction using environment variables
    const now = new Date();
    const hour = now.getHours();
    const minute = now.getMinutes();

    const allowedHour = parseInt(process.env.ALLOWED_KEYGEN_HOUR) || 4;
    const allowedMinuteStart =
      parseInt(process.env.ALLOWED_KEYGEN_MINUTE_START) || 0;
    const allowedMinuteEnd =
      parseInt(process.env.ALLOWED_KEYGEN_MINUTE_END) || 5;

    if (
      !(
        hour === allowedHour &&
        minute >= allowedMinuteStart &&
        minute <= allowedMinuteEnd
      )
    ) {
      return res.status(403).json({
        error: "Forbidden",
        message: "Key generation not allowed at this time",
      });
    }

    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        error: "Bad Request",
        message: "Email is required to generate keys",
      });
    }

    // Find and verify the admin user
    const user = await User.findOne({ email: email.toLowerCase() });
    if (!user || user.role !== "admin") {
      return res.status(403).json({
        error: "Forbidden",
        message: "Only admin users can generate cryptographic keys",
      });
    }

    // Generate ECDSA P-256 key pair
    const { publicKey, privateKey } = crypto.generateKeyPairSync("ec", {
      namedCurve: "P-256",
      publicKeyEncoding: {
        type: "spki",
        format: "pem",
      },
      privateKeyEncoding: {
        type: "pkcs8",
        format: "pem",
      },
    });

    // Store public key in database
    await User.findByIdAndUpdate(user._id, {
      publicKey: publicKey,
    });

    // Return both keys to client (client will store private key securely)
    res.json({
      success: true,
      publicKey: publicKey,
      privateKey: privateKey,
      message:
        "Key pair generated successfully. Store the private key securely on your device.",
    });
  } catch (error) {
    console.error("Key generation error:", error);
    res.status(500).json({
      error: "Internal Server Error",
      message: "Failed to generate cryptographic keys",
    });
  }
});

// POST /admin/challenge - Generate authentication challenge
router.post("/challenge", authLimiter, async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        error: "Bad Request",
        message: "Email is required",
      });
    }

    // Find user by email
    const user = await User.findOne({ email: email.toLowerCase() });
    if (!user || user.role !== "admin" || !user.publicKey) {
      return res.status(401).json({
        error: "Unauthorized",
        message:
          "Invalid credentials or user not configured for key authentication",
      });
    }

    // Generate random challenge (32 bytes)
    const challenge = crypto.randomBytes(32).toString("hex");
    const timestamp = Date.now();

    // Store challenge temporarily (in production, use Redis or similar)
    // For now, we'll include it in the response and verify it later
    const fullChallenge = `${challenge}.${timestamp}`;

    res.json({
      challenge: fullChallenge,
      userId: user._id,
    });
  } catch (error) {
    console.error("Challenge generation error:", error);
    res.status(500).json({
      error: "Internal Server Error",
      message: "Failed to generate authentication challenge",
    });
  }
});

// POST /admin/verify - Verify signature and authenticate
router.post("/verify", authLimiter, async (req, res) => {
  try {
    const { challenge, signature, userId } = req.body;

    if (!challenge || !signature || !userId) {
      return res.status(400).json({
        error: "Bad Request",
        message: "Challenge, signature, and userId are required",
      });
    }

    // Find user
    const user = await User.findById(userId);
    if (!user || user.role !== "admin" || !user.publicKey) {
      // Audit failed login attempt
      await audit.logLoginFailure(userId, req.ip, "invalid_user_or_key");
      return res.status(401).json({
        error: "Unauthorized",
        message: "Invalid user or not configured for key authentication",
      });
    }

    // Verify signature (DER format from frontend)
    console.log("🔐 Signature verification debug:");
    console.log("- Challenge:", challenge);
    console.log("- Signature length:", signature.length);
    console.log("- Signature (first 50 chars):", signature.substring(0, 50));
    console.log("- User public key exists:", !!user.publicKey);

    const verifier = crypto.createVerify("SHA256");
    verifier.update(challenge);

    // Convert hex signature to Buffer for DER format verification
    const signatureBuffer = Buffer.from(signature, "hex");
    console.log("- Signature buffer length:", signatureBuffer.length);

    let isValid;
    try {
      isValid = verifier.verify(user.publicKey, signatureBuffer);
      console.log("- Verification result:", isValid);
    } catch (verifyError) {
      console.log("❌ Signature verification error:", verifyError.message);
      console.log("- Error details:", verifyError);
      throw new Error("Signature verification failed: " + verifyError.message);
    }

    if (!isValid) {
      // Audit failed login attempt
      await audit.logLoginFailure(user.email, req.ip, "invalid_signature");
      return res.status(401).json({
        error: "Unauthorized",
        message: "Invalid signature",
      });
    }

    // Check challenge timestamp (prevent replay attacks)
    const challengeParts = challenge.split(".");
    if (challengeParts.length !== 2) {
      return res.status(400).json({
        error: "Bad Request",
        message: "Invalid challenge format",
      });
    }

    const timestamp = parseInt(challengeParts[1]);
    const now = Date.now();
    const challengeAge = now - timestamp;

    // Challenge expires after 5 minutes
    if (challengeAge > 5 * 60 * 1000) {
      // Audit failed login attempt
      await audit.logLoginFailure(user.email, req.ip, "challenge_expired");
      return res.status(401).json({
        error: "Unauthorized",
        message: "Challenge expired",
      });
    }

    // Generate JWT token for authenticated session
    const jwt = require("jsonwebtoken");
    const token = jwt.sign(
      {
        id: user._id,
        email: user.email,
        role: user.role,
        permissions: user.permissions,
      },
      process.env.JWT_SECRET || "fallback-secret",
      { expiresIn: "1h" }, // Shorter expiration for admin sessions
    );

    // Audit successful login
    await audit.logLoginSuccess(
      user._id.toString(),
      user.email,
      req.ip,
      req.get("User-Agent"),
    );

    res.json({
      success: true,
      token: token,
      user: {
        id: user._id,
        email: user.email,
        role: user.role,
        permissions: user.permissions,
      },
    });
  } catch (error) {
    console.error("Signature verification error:", error);
    res.status(500).json({
      error: "Internal Server Error",
      message: "Failed to verify signature",
    });
  }
});

module.exports = router;
