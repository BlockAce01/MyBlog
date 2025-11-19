"use client";

import type React from "react";
import { useState, useEffect, useRef } from "react";
import { Layout } from "@/components/layout";
import type { BlogPost, Comment } from "@/lib/types";
import { Eye, Heart, MessageCircle } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import HTMLRenderer from "@/components/HTMLRenderer";
import { CommentForm } from "@/components/comment-form";
import { CommentCard } from "@/components/comment-card";
import { ReplyForm } from "@/components/reply-form";
import { OptimizedImage } from "@/components/OptimizedImage";

import { getPost, getComments, likePost, incrementViewCount } from "@/lib/data";
import { useParams } from "next/navigation";

export default function PostPage() {
  const params = useParams();
  const id = params?.id as string;
  const hasViewed = useRef(false);

  const [post, setPost] = useState<BlogPost | null>(null);
  const [comments, setComments] = useState<Comment[]>([]);
  const [liked, setLiked] = useState(false);
  const [likeCount, setLikeCount] = useState(0);
  const [loading, setLoading] = useState(true);
  const [replyingTo, setReplyingTo] = useState<string | null>(null);
  const [expandedReplies, setExpandedReplies] = useState<Set<string>>(
    new Set(),
  );

  useEffect(() => {
    if (id && !hasViewed.current) {
      const fetchData = async () => {
        setLoading(true);
        try {
          // Normalize ID to lowercase for consistent matching
          const normalizedId = id.toLowerCase();

          // Check session storage BEFORE fetching data
          const viewedPosts = JSON.parse(
            sessionStorage.getItem("blogPostViews") || "{}",
          );

          if (!viewedPosts[normalizedId]) {
            // Immediately mark as viewed to prevent concurrent increments
            viewedPosts[normalizedId] = true;
            sessionStorage.setItem(
              "blogPostViews",
              JSON.stringify(viewedPosts),
            );

            // Then increment the view count
            try {
              await incrementViewCount(normalizedId);
            } catch (viewError) {
              console.error("Failed to increment view count:", viewError);
              // Don't throw here - we don't want view count errors to break the page load
            }
          }

          const postData = await getPost(normalizedId);

          setPost(postData);

          // Use the actual post ID (not slug) to fetch comments
          if (postData) {
            const commentsData = await getComments(postData.id);
            setComments(commentsData);
          }

          if (postData) {
            setLikeCount(postData.likeCount);
            // Check if user has already liked this post
            const userId =
              typeof window !== "undefined"
                ? localStorage.getItem("userId")
                : null;
            if (userId && postData.likedBy?.includes(userId)) {
              setLiked(true);
            }
          }
        } catch (error) {
          console.error("Error loading post:", error);
        } finally {
          setLoading(false);
          hasViewed.current = true;
        }
      };
      fetchData();
    }
  }, [id]);

  const handleLike = async () => {
    if (post) {
      try {
        const result = await likePost(post.id);
        if (result) {
          setLiked(result.isLiked);
          setLikeCount(result.likeCount);
        }
      } catch (error) {
        console.error("Failed to like post:", error);
        // Show user-friendly error message
        alert(
          `Unable to like post: ${error instanceof Error ? error.message : "Unknown error"}`,
        );
      }
    }
  };

  const handleCommentAdded = async () => {
    // Refresh comments after a new comment is added
    if (post) {
      const commentsData = await getComments(post.id);
      setComments(commentsData);
    }
  };

  const handleReply = (commentId: string) => {
    // console.log('handleReply called with:', commentId);
    // console.log('Current replyingTo:', replyingTo);
    setReplyingTo(commentId);
    // console.log('Set replyingTo to:', commentId);
  };

  const handleReplyCancel = () => {
    setReplyingTo(null);
  };

  const handleReplyAdded = async () => {
    // console.log('handleReplyAdded called - refreshing comments');
    // Refresh comments after a reply is added
    if (post) {
      try {
        const commentsData = await getComments(post.id);
        // console.log('Refreshed comments:', commentsData.length, 'comments');
        setComments(commentsData);
        // Clear any expanded reply states to reset the view
        setExpandedReplies(new Set());
      } catch (error) {
        console.error("Error refreshing comments:", error);
      }
    }
    setReplyingTo(null);
  };

  const handleToggleReplies = (commentId: string) => {
    const newExpanded = new Set(expandedReplies);
    if (newExpanded.has(commentId)) {
      newExpanded.delete(commentId);
    } else {
      newExpanded.add(commentId);
    }
    setExpandedReplies(newExpanded);
  };

  if (loading) {
    return (
      <Layout>
        <div className="text-center">Loading...</div>
      </Layout>
    );
  }

  if (!post) {
    return (
      <Layout>
        <div className="text-center">Post not found</div>
      </Layout>
    );
  }

  const formattedDate = new Date(post.publicationDate).toLocaleDateString(
    "en-US",
    {
      year: "numeric",
      month: "long",
      day: "numeric",
    },
  );

  return (
    <Layout>
      <article className="w-full max-w-4xl mx-auto px-0 sm:px-6 lg:px-8">
        {/* Cover Photo */}
        {post.coverPhotoUrl &&
          post.coverPhotoUrl !==
            "https://via.placeholder.com/800x400?text=No+Image" && (
            <div className="mb-6 sm:mb-8 rounded-lg overflow-hidden aspect-[2/1]">
              <OptimizedImage
                src={post.coverPhotoUrl}
                alt={post.title}
                width={800}
                height={400}
                className="w-full h-full object-cover cover-photo"
              />
            </div>
          )}

        {/* Post Header */}
        <header className="mb-6 sm:mb-8">
          <h1 className="text-2xl sm:text-3xl lg:text-4xl font-bold font-sans text-foreground mb-3 sm:mb-4 leading-tight">
            {post.title}
          </h1>
          <div className="flex flex-col sm:flex-row sm:items-center sm:space-x-4 space-y-2 sm:space-y-0 text-muted-foreground text-sm">
            <span>{formattedDate}</span>
            <div className="flex items-center space-x-4">
              <div className="flex items-center space-x-1">
                <Eye className="w-4 h-4" />
                <span>{post.viewCount}</span>
              </div>
            </div>
          </div>
          {post.tags && post.tags.length > 0 && (
            <div className="flex flex-wrap gap-2 mt-3 sm:mt-4">
              {post.tags.map((tag) => (
                <Badge key={tag} variant="secondary" className="text-xs">
                  {tag}
                </Badge>
              ))}
            </div>
          )}
        </header>

        {/* Post Content */}
        <div className="mb-12">
          <HTMLRenderer html={post.content} />
        </div>

        {/* Engagement Section */}
        <div className="border-t border-border pt-8 mb-12">
          <div className="flex items-center justify-center">
            <Button
              variant={liked ? "default" : "outline"}
              size="lg"
              onClick={handleLike}
              className="flex items-center space-x-2"
            >
              <Heart className={`w-5 h-5 ${liked ? "fill-current" : ""}`} />
              <span>{likeCount}</span>
            </Button>
          </div>
        </div>

        {/* Comments Section */}
        <section className="border-t border-border pt-8">
          <div className="max-w-2xl mx-auto">
            <h2 className="text-xl sm:text-2xl font-bold font-sans text-foreground mb-6 flex items-center">
              <MessageCircle className="w-5 h-5 sm:w-6 sm:h-6 mr-2" />
              Comments ({comments.length})
            </h2>

            {/* Existing Comments */}
            <div className="space-y-6 mb-8">
              {comments.map((comment, index) => {
                // Generate a unique key for React - use comment.id if available, otherwise create a unique temp ID
                const uniqueKey =
                  comment.id ||
                  `temp-comment-${index}-${Date.now()}-${Math.random()}`;
                const commentId = comment.id || uniqueKey;

                return (
                  <div key={`comment-${uniqueKey}`}>
                    <CommentCard
                      comment={{ ...comment, id: commentId }}
                      onReply={handleReply}
                      showReplies={expandedReplies.has(commentId)}
                      onToggleReplies={handleToggleReplies}
                    />
                    {replyingTo === commentId && (
                      <ReplyForm
                        key={`reply-form-${uniqueKey}`}
                        postId={post.id}
                        parentCommentId={commentId}
                        onReplyAdded={handleReplyAdded}
                        onCancel={handleReplyCancel}
                      />
                    )}
                  </div>
                );
              })}
            </div>

            {/* Comment Form */}
            <CommentForm postId={post.id} onCommentAdded={handleCommentAdded} />
          </div>
        </section>
      </article>
    </Layout>
  );
}
