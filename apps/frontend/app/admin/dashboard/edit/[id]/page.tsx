"use client";

import { useState, useEffect, useCallback } from "react";
import { useRouter, useParams } from "next/navigation";
import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Alert, AlertDescription } from "@/components/ui/alert";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Loader2, ArrowLeft, Save, AlertCircle } from "lucide-react";
import { useAuth } from "@/hooks/use-auth";
import { getPost, updateBlogPost } from "@/lib/data";
import { getTextContentFromHtml } from "@/lib/html-utils";
import type { BlogPost } from "@/lib/types";
import RichTextEditor from "@/components/RichTextEditor";

export default function EditBlogPostPage() {
  const { isAuthenticated, isLoading: authLoading } = useAuth();
  const params = useParams();
  const postId = params?.id as string;
  const navigate = useRouter();

  const [formData, setFormData] = useState({
    title: "",
    content: "",
    excerpt: "",
    coverPhotoUrl: "",
    tags: [] as string[],
    status: "draft" as "draft" | "published" | "hidden" | "scheduled",
    scheduledPublishDate: "",
  });

  const [tagInput, setTagInput] = useState("");
  const [errors, setErrors] = useState<{ [key: string]: string }>({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [submitError, setSubmitError] = useState("");
  const [originalPost, setOriginalPost] = useState<BlogPost | null>(null);

  const fetchPost = useCallback(async () => {
    try {
      setIsLoading(true);
      const post = await getPost(postId, true); // Pass true for admin to get any post regardless of status

      if (post) {
        setOriginalPost(post);
        setFormData({
          title: post.title,
          content: post.content,
          excerpt: post.summary,
          coverPhotoUrl: post.coverPhotoUrl || "",
          tags: post.tags,
          status: post.status || "draft",
          scheduledPublishDate: post.scheduledPublishDate || "",
        });
      } else {
        setSubmitError("Blog post not found.");
      }
    } catch (err) {
      console.error("Failed to fetch post:", err);
      setSubmitError("Failed to load blog post. Please try again.");
    } finally {
      setIsLoading(false);
    }
  }, [postId]);

  useEffect(() => {
    if (isAuthenticated && !authLoading && postId) {
      fetchPost();
    }
  }, [isAuthenticated, authLoading, postId, fetchPost]);

  const validateForm = () => {
    const newErrors: { [key: string]: string } = {};

    if (!formData.title.trim()) {
      newErrors.title = "Title is required";
    } else if (formData.title.length > 200) {
      newErrors.title = "Title must be less than 200 characters";
    }

    if (!formData.content.trim()) {
      newErrors.content = "Content is required";
    } else if (formData.content.length > 50000) {
      newErrors.content = "Content must be less than 50,000 characters";
    }

    if (!formData.excerpt.trim()) {
      newErrors.excerpt = "Excerpt is required";
    } else if (formData.excerpt.length > 500) {
      newErrors.excerpt = "Excerpt must be less than 500 characters";
    }

    // Validate scheduled publish date
    if (formData.status === "scheduled" && !formData.scheduledPublishDate) {
      newErrors.scheduledPublishDate =
        "Scheduled publish date is required when status is scheduled";
    }

    if (
      formData.status === "scheduled" &&
      formData.scheduledPublishDate &&
      new Date(formData.scheduledPublishDate) <= new Date()
    ) {
      newErrors.scheduledPublishDate =
        "Scheduled publish date must be in the future";
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleInputChange = (field: string, value: string) => {
    setFormData((prev: typeof formData) => ({
      ...prev,
      [field]: value,
    }));

    // Clear error when user starts typing
    if (errors[field]) {
      setErrors((prev: typeof errors) => ({
        ...prev,
        [field]: "",
      }));
    }
  };

  const handleAddTag = () => {
    const tag = tagInput.trim().toLowerCase();
    if (tag && !formData.tags.includes(tag)) {
      setFormData((prev: typeof formData) => ({
        ...prev,
        tags: [...prev.tags, tag],
      }));
      setTagInput("");
    }
  };

  const handleRemoveTag = (tagToRemove: string) => {
    setFormData((prev: typeof formData) => ({
      ...prev,
      tags: prev.tags.filter((tag: string) => tag !== tagToRemove),
    }));
  };

  const handleTagKeyPress = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === "Enter") {
      e.preventDefault();
      handleAddTag();
    }
  };

  const handleStatusChange = (
    status: "draft" | "published" | "hidden" | "scheduled",
  ) => {
    setFormData((prev: typeof formData) => ({
      ...prev,
      status,
      scheduledPublishDate:
        status === "scheduled" ? prev.scheduledPublishDate : "",
    }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitError("");

    if (!validateForm()) {
      return;
    }

    setIsSubmitting(true);

    try {
      const updateData = {
        id: postId,
        title: formData.title,
        content: formData.content,
        excerpt: formData.excerpt,
        coverPhotoUrl: formData.coverPhotoUrl,
        tags: formData.tags,
        status: formData.status,
        scheduledPublishDate: formData.scheduledPublishDate || undefined,
        version: originalPost?.version || 0,
      };

      const result = await updateBlogPost(updateData);

      if (result) {
        navigate.push("/admin/dashboard");
      } else {
        setSubmitError("Failed to update blog post. Please try again.");
      }
    } catch (error) {
      console.error("Failed to update blog post:", error);
      setSubmitError(
        "An error occurred while updating the blog post. Please try again.",
      );
    } finally {
      setIsSubmitting(false);
    }
  };

  if (authLoading || isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin" />
      </div>
    );
  }

  if (!isAuthenticated) {
    return null; // useAuth will handle redirect
  }

  if (!originalPost) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <Card className="w-full max-w-md">
          <CardContent className="pt-6">
            <div className="text-center">
              <AlertCircle className="h-12 w-12 text-red-500 mx-auto mb-4" />
              <h2 className="text-xl font-semibold mb-2">Post Not Found</h2>
              <p className="text-gray-600 mb-4">
                The blog post you're trying to edit doesn't exist or has been
                deleted.
              </p>
              <Link href="/admin/dashboard">
                <Button>Back to Dashboard</Button>
              </Link>
            </div>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-4">
            <div className="flex items-center space-x-4">
              <Link href="/admin/dashboard">
                <Button variant="outline" size="sm">
                  <ArrowLeft className="h-4 w-4 mr-2" />
                  Back to Dashboard
                </Button>
              </Link>
              <div>
                <h1 className="text-2xl font-bold text-gray-900">
                  Edit Blog Post
                </h1>
                <p className="text-sm text-gray-600">
                  Make changes to your blog post
                </p>
              </div>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-4xl mx-auto py-6 px-4 sm:px-6 lg:px-8">
        {submitError && (
          <Alert variant="destructive" className="mb-6">
            <AlertDescription>{submitError}</AlertDescription>
          </Alert>
        )}

        <form onSubmit={handleSubmit}>
          <div className="space-y-6">
            {/* Title */}
            <Card>
              <CardHeader>
                <CardTitle>Basic Information</CardTitle>
                <CardDescription></CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="title">Title *</Label>
                  <Input
                    id="title"
                    value={formData.title}
                    onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                      handleInputChange("title", e.target.value)
                    }
                    className={errors.title ? "border-red-500" : ""}
                    placeholder="Enter a compelling title for your blog post"
                    disabled={isSubmitting}
                  />
                  {errors.title && (
                    <p className="text-sm text-red-500">{errors.title}</p>
                  )}
                  <p className="text-sm text-gray-500">
                    {formData.title.length}/200 characters
                  </p>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="excerpt">Excerpt *</Label>
                  <Textarea
                    id="excerpt"
                    value={formData.excerpt}
                    onChange={(e: React.ChangeEvent<HTMLTextAreaElement>) =>
                      handleInputChange("excerpt", e.target.value)
                    }
                    className={errors.excerpt ? "border-red-500" : ""}
                    placeholder="Write a brief summary of your blog post"
                    rows={3}
                    disabled={isSubmitting}
                  />
                  {errors.excerpt && (
                    <p className="text-sm text-red-500">{errors.excerpt}</p>
                  )}
                  <p className="text-sm text-gray-500">
                    {formData.excerpt.length}/500 characters
                  </p>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="coverPhotoUrl">Cover Photo URL</Label>
                  <Input
                    id="coverPhotoUrl"
                    value={formData.coverPhotoUrl}
                    onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                      handleInputChange("coverPhotoUrl", e.target.value)
                    }
                    placeholder="https://example.com/image.jpg"
                    disabled={isSubmitting}
                  />
                </div>
              </CardContent>
            </Card>

            {/* Content */}
            <Card>
              <CardHeader>
                <CardTitle>Body</CardTitle>
                <CardDescription></CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  <Label htmlFor="content">Content *</Label>
                  <RichTextEditor
                    value={formData.content}
                    onChange={(value) => handleInputChange("content", value)}
                    disabled={isSubmitting}
                    height={500}
                  />
                  {errors.content && (
                    <p className="text-sm text-red-500">{errors.content}</p>
                  )}
                  <p className="text-sm text-gray-500">
                    {getTextContentFromHtml(formData.content).length}/50,000
                    characters (HTML tags excluded)
                  </p>
                </div>
              </CardContent>
            </Card>

            {/* Tags */}
            <Card>
              <CardHeader>
                <CardTitle>Tags</CardTitle>
                <CardDescription></CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="flex space-x-2">
                  <Input
                    value={tagInput}
                    onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                      setTagInput(e.target.value)
                    }
                    onKeyPress={handleTagKeyPress}
                    placeholder="Add a tag..."
                    disabled={isSubmitting}
                  />
                  <Button
                    type="button"
                    onClick={handleAddTag}
                    disabled={!tagInput.trim() || isSubmitting}
                  >
                    Add Tag
                  </Button>
                </div>

                {formData.tags.length > 0 && (
                  <div className="flex flex-wrap gap-2">
                    {formData.tags.map((tag: string) => (
                      <span
                        key={tag}
                        className="inline-flex items-center px-2 py-1 rounded-full text-xs bg-blue-100 text-blue-800"
                      >
                        {tag}
                        <button
                          type="button"
                          onClick={() => handleRemoveTag(tag)}
                          className="ml-1 text-blue-600 hover:text-blue-800"
                          disabled={isSubmitting}
                        >
                          ×
                        </button>
                      </span>
                    ))}
                  </div>
                )}
              </CardContent>
            </Card>

            {/* Publishing Options */}
            <Card>
              <CardHeader>
                <CardTitle>Publishing Options</CardTitle>
                <CardDescription></CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="status">Status</Label>
                  <Select
                    value={formData.status}
                    onValueChange={handleStatusChange}
                    disabled={isSubmitting}
                  >
                    <SelectTrigger>
                      <SelectValue placeholder="Select status" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="draft">Draft</SelectItem>
                      <SelectItem value="published">Published</SelectItem>
                      <SelectItem value="hidden">Hidden</SelectItem>
                      <SelectItem value="scheduled">Scheduled</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                {formData.status === "scheduled" && (
                  <div className="space-y-2">
                    <Label htmlFor="scheduledPublishDate">
                      Publish Date & Time
                    </Label>
                    <Input
                      id="scheduledPublishDate"
                      type="datetime-local"
                      value={formData.scheduledPublishDate}
                      onChange={(e) =>
                        handleInputChange(
                          "scheduledPublishDate",
                          e.target.value,
                        )
                      }
                      className={
                        errors.scheduledPublishDate ? "border-red-500" : ""
                      }
                      disabled={isSubmitting}
                      min={new Date().toISOString().slice(0, 16)}
                    />
                    {errors.scheduledPublishDate && (
                      <p className="text-sm text-red-500">
                        {errors.scheduledPublishDate}
                      </p>
                    )}
                    <p className="text-sm text-gray-500">
                      Select when this post should be automatically published
                    </p>
                  </div>
                )}

                <div className="text-sm text-gray-500">
                  {formData.status === "draft" &&
                    "This post will be saved as a draft and not visible to readers."}
                  {formData.status === "published" &&
                    "This post will be published and visible to readers immediately."}
                  {formData.status === "hidden" &&
                    "This post will be saved but hidden from readers."}
                  {formData.status === "scheduled" &&
                    "This post will be published automatically at the scheduled time."}
                </div>
              </CardContent>
            </Card>

            {/* Submit Buttons */}
            <div className="flex justify-end space-x-4">
              <Link href="/admin/dashboard">
                <Button type="button" variant="outline" disabled={isSubmitting}>
                  Cancel
                </Button>
              </Link>
              <Button type="submit" disabled={isSubmitting}>
                {isSubmitting ? (
                  <>
                    <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                    Updating Post...
                  </>
                ) : (
                  <>
                    <Save className="h-4 w-4 mr-2" />
                    Update Post
                  </>
                )}
              </Button>
            </div>
          </div>
        </form>
      </main>
    </div>
  );
}
