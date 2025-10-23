# My Blog: A Full-Stack MERN Blog with Robust AWS Deployment

## Project Overview

**My Blog** is a personal full-stack blog application designed to showcase technical experiments, achievements, and knowledge sharing. It provides a platform for me to publish content, while allowing visitors to interact through comments and likes. The application is built with a modern MERN (MongoDB, Express.js, React/Next.js, Node.js) stack and deployed on a scalable and secure AWS infrastructure.

## Features

- **Dynamic Blog Post Display:** Users can browse and view blog posts with rich content rendering.
- **Interactive Commenting System:** Visitors can leave comments on posts after authenticating via Google OAuth, fostering community engagement.
- **Post Liking Mechanism:** Users can express appreciation for posts, with their likes tracked to prevent multiple likes from the same user.
- **Secure Admin Dashboard:** A dedicated interface for administrators to manage blog content.
- **Comprehensive CRUD Operations:** Admins can Create, Read, Update, and Delete blog posts.
- **Flexible Post Management:** Posts can be set to various statuses including `draft`, `published`, `hidden`, and `scheduled` for future publication.
- **Views Tracking:** Each post's view count is recorded to gauge popularity.

## Technology Stack

- **Frontend:** Next.js 14+ (TypeScript), React, Tailwind CSS, shadcn/ui components.
- **Backend:** Node.js, Express.js (JavaScript ES6+).
- **Database:** MongoDB Atlas (cloud-hosted NoSQL database).
- **Package Manager:** pnpm.
- **Authentication:** JWT-based for general API access, Google OAuth for public comments, and RSA Key-based authentication for admin access.
- **Containerization:** Docker and Docker Compose.
- **Infrastructure as Code:** Terraform for AWS resource provisioning and management.

## Architecture Overview

The `My Blog` application follows a microservices-oriented architecture, deployed as Docker containers on a single AWS EC2 instance, and exposed globally via AWS CloudFront.

- **Frontend (Next.js):** The user-facing application, built with Next.js, handles server-side rendering (SSR) and client-side interactions.
- **Backend (Node.js/Express):** A RESTful API that serves data to the frontend, handles business logic, authentication, and interacts with the MongoDB Atlas database.
- **Database (MongoDB Atlas):** A fully managed, cloud-hosted MongoDB service that stores all blog posts, comments, and user data.
- **Deployment:** Both frontend and backend applications are containerized using Docker. `docker-compose` orchestrates these containers on a single EC2 instance.

## Security Mechanisms

Security is a paramount concern in `My Blog`, implemented through several layers:

- **Admin Authentication (RSA Keys):**
  - Administrators authenticate using a robust RSA key pair challenge-response mechanism.
  - A public key is securely stored in the database, while the private key remains on the admin's local device.
  - The backend issues a unique challenge, which the client signs with its private key. The backend then verifies this signature using the stored public key.
  - Successful authentication results in a short-lived JWT token for session management.
- **Public User Authentication (Google OAuth):**
  - For commenting, public users authenticate securely via Google OAuth, leveraging Google's robust identity management.
  - Upon successful OAuth, a JWT token is issued and stored locally for subsequent comment submissions.
- **Role-Based Access Control (RBAC):**
  - The `adminOnly` middleware ensures that only authenticated administrators with the necessary permissions can access sensitive routes and perform CRUD operations.
- **Rate Limiting:**
  - `express-rate-limit` middleware is implemented across various endpoints (authentication, key management, general API) to prevent brute-force attacks, denial-of-service (DoS), and API abuse.
- **IP Allowlisting:**
  - A custom IP allowlisting middleware restricts access to critical admin endpoints to a predefined set of trusted IP addresses, adding an extra layer of network security.
- **Environment Variables:**
  - All sensitive configurations (e.g., database connection strings, API keys, JWT secrets) are managed through environment variables, preventing hardcoding of secrets in the codebase.

## AWS Services Used

The `My Blog` application is deployed on AWS, leveraging several services for scalability, reliability, and security:

- **Amazon EC2 (Elastic Compute Cloud):**
  - A virtual server (Ubuntu 22.04 LTS) hosts the Docker containers for the frontend, backend, and Nginx reverse proxy.
  - User data scripts automate the installation of Docker, Docker Compose, and AWS SSM Agent for secure remote management.
  - An Elastic IP provides a static public IP address for the instance.
- **Amazon ECR (Elastic Container Registry):**
  - Private Docker image repositories for `myblog/frontend`, `myblog/backend`, and `myblog/nginx`.
  - Integrated with CI/CD pipelines for secure storage and versioning of application images.
  - Lifecycle policies automatically clean up old images.
- **Amazon CloudFront:**
  - A global Content Delivery Network (CDN) that serves the blog content with low latency and high availability.
  - Configured to redirect all HTTP traffic to HTTPS, ensuring secure communication.
  - Caches static assets, improving load times and reducing the load on the EC2 instance.
- **Amazon Route 53:**
  - A highly available and scalable cloud Domain Name System (DNS) web service.
  - Manages the custom domain (`blog.yugankavinda.me`), resolving it to the CloudFront distribution.
  - Used for DNS validation of ACM certificates.
- **AWS IAM (Identity and Access Management):**
  - Manages access to AWS resources.
  - An IAM User with programmatic access is configured for GitHub Actions, allowing it to push/pull images from ECR and deploy updates via SSM.
  - An IAM Role is attached to the EC2 instance, granting necessary permissions for SSM management and ECR read-only access.
- **AWS ACM (Certificate Manager):**
  - Provides SSL/TLS certificates for free, enabling HTTPS for the CloudFront distribution and ensuring secure data transfer.
- **MongoDB Atlas:**
  - While not an AWS service, it's the cloud-hosted database solution for `My Blog`, providing a managed, scalable, and secure NoSQL database.

## Infrastructure as Code & DevOps Practices

This project demonstrates modern DevOps practices through comprehensive Infrastructure as Code (IaC) implementation:

### Terraform Infrastructure Management

- **Complete AWS Infrastructure Provisioning:** All AWS resources (EC2, CloudFront, ECR, Route 53, IAM, ACM) are defined and managed through Terraform configurations.
- **Modular Architecture:** Infrastructure is organized into logical modules (main.tf, iam.tf, ecr.tf, cloudfront.tf, route53.tf) for maintainability.
- **Environment Variables:** Sensitive configurations and customizable parameters are managed through Terraform variables.
- **Resource Tagging:** Consistent tagging strategy with `Project = "MyBlog"` for resource organization and cost tracking.
- **Multi-Region Deployment:** ECR repositories and ACM certificates are provisioned in `us-east-1` for global compatibility.

### CI/CD Pipeline Design

- **GitHub Actions Integration:** Automated CI/CD pipelines using GitHub Actions for building, testing, and deployment.
- **Docker Image Management:** Multi-stage Docker builds with ECR integration for secure image storage and versioning.
- **AWS SSM Deployment:** Secure deployment to EC2 instances using AWS Systems Manager (SSM) for remote command execution.
- **Infrastructure Updates:** Terraform configurations support blue-green deployments and infrastructure updates without downtime.

### Containerization Strategy

- **Docker Compose Orchestration:** Local development environment using Docker Compose for consistent development and testing.
- **Multi-Container Architecture:** Separate containers for frontend, backend, and reverse proxy (Nginx) with proper networking.
- **Environment Consistency:** Docker ensures identical runtime environments across development, staging, and production.

### Security in DevOps

- **Infrastructure Security:** Security groups, IAM roles, and network configurations managed through code.
- **Secret Management:** Environment variables and AWS Parameter Store for secure credential management.
- **Access Control:** Least-privilege IAM policies and IP-based restrictions implemented at infrastructure level.

## Deployment Strategy

The project utilizes Docker Compose for local orchestration and is designed for CI/CD with GitHub Actions. Docker images are pushed to ECR, and deployments to the EC2 instance are managed via AWS SSM.

## Local Development Setup

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/BlockAce01/My Blog.git
    cd My Blog
    ```
2.  **Install dependencies:**
    ```bash
    pnpm install
    ```
3.  **Configure environment variables:**
    Copy `.env.example` to `.env` in both `apps/frontend` and `apps/backend` and fill in the required values (e.g., MongoDB Atlas connection string, Google OAuth credentials, JWT secret).
4.  **Run with Docker Compose:**
    ```bash
    docker-compose up --build
    ```
    This will build and start the frontend, backend, and Nginx services
