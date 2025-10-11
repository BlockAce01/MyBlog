"use client";

import { OptimizedImage } from "./OptimizedImage";
import { HTMLCodeBlock } from "./HTMLCodeBlock";

interface BlogImageRendererProps {
  html: string;
  className?: string;
}

export function BlogImageRenderer({
  html,
  className = "",
}: BlogImageRendererProps) {
  // Helper function to parse style string into React CSSProperties
  const parseStyleString = (styleString: string): React.CSSProperties => {
    const style: Record<string, string> = {};
    if (!styleString) return style;

    const declarations = styleString.split(";").filter((decl) => decl.trim());
    declarations.forEach((declaration) => {
      const [property, value] = declaration.split(":").map((s) => s.trim());
      if (property && value) {
        // Convert CSS property names to camelCase for React
        const camelProperty = property.replace(/-([a-z])/g, (_, letter) =>
          letter.toUpperCase(),
        );
        style[camelProperty] = value;
      }
    });

    return style as React.CSSProperties;
  };

  // Parse HTML and extract image information
  const processHTML = (htmlContent: string) => {
    const parser = new DOMParser();
    const doc = parser.parseFromString(htmlContent, "text/html");
    const images = doc.querySelectorAll("img");

    // Convert NodeList to array for processing
    const imageElements = Array.from(images);

    if (imageElements.length === 0) {
      return { hasImages: false, processedHtml: htmlContent };
    }

    // Process each image and replace with placeholder
    const imageData: Array<{
      id: string;
      src: string;
      alt: string;
      className: string;
      width?: string;
      height?: string;
      style?: string;
      title?: string;
    }> = [];

    imageElements.forEach((img, index) => {
      const src = img.getAttribute("src") || "";
      const alt = img.getAttribute("alt") || "";
      const imgClass = img.getAttribute("class") || "";
      const width = img.getAttribute("width") || undefined;
      const height = img.getAttribute("height") || undefined;
      const style = img.getAttribute("style") || undefined;
      const title = img.getAttribute("title") || undefined;

      const placeholderId = `__blog_image_${index}__`;
      imageData.push({
        id: placeholderId,
        src,
        alt,
        className: imgClass,
        width,
        height,
        style,
        title,
      });

      // Replace the img tag with a placeholder
      const placeholder = doc.createTextNode(placeholderId);
      img.parentNode?.replaceChild(placeholder, img);
    });

    return {
      hasImages: true,
      processedHtml: doc.body.innerHTML,
      imageData,
    };
  };

  const { hasImages, processedHtml, imageData } = processHTML(html);

  if (!hasImages) {
    // Check if content has code blocks even without images
    const hasCodeBlocks = /<pre[^>]*>[\s\S]*?<\/pre>/g.test(html);
    if (hasCodeBlocks) {
      // Split content by code blocks and render them separately
      const parts = html.split(/(<pre[^>]*>[\s\S]*?<\/pre>)/g);

      return (
        <div className={className}>
          {parts.map((part, index) => {
            // Check if this part is a code block
            const codeBlockMatch = part.match(/^<pre[^>]*>([\s\S]*?)<\/pre>$/);
            if (codeBlockMatch) {
              return <HTMLCodeBlock key={index} htmlContent={part} />;
            }

            // Regular HTML content
            if (part.trim()) {
              return (
                <div
                  key={`html-${index}`}
                  dangerouslySetInnerHTML={{ __html: part }}
                />
              );
            }

            return null;
          })}
        </div>
      );
    }

    return (
      <div className={className} dangerouslySetInnerHTML={{ __html: html }} />
    );
  }

  // Check if processed content has code blocks
  const hasCodeBlocks = /<pre[^>]*>[\s\S]*?<\/pre>/g.test(processedHtml);

  if (hasCodeBlocks) {
    // Split by both image placeholders and code blocks
    const parts = processedHtml.split(
      /(__blog_image_\d+__|<pre[^>]*>[\s\S]*?<\/pre>)/g,
    );

    return (
      <div className={className}>
        {parts.map((part, index) => {
          const imageMatch = part.match(/__blog_image_(\d+)__/);
          if (imageMatch) {
            const imageIndex = parseInt(imageMatch[1]);
            const imageInfo = imageData?.[imageIndex];

            if (imageInfo) {
              return (
                <OptimizedImage
                  key={`image-${imageIndex}`}
                  src={imageInfo.src}
                  alt={imageInfo.alt}
                  className={`rounded-lg ${imageInfo.className}`}
                  width={
                    imageInfo.width ? parseInt(imageInfo.width) : undefined
                  }
                  height={
                    imageInfo.height ? parseInt(imageInfo.height) : undefined
                  }
                  title={imageInfo.title}
                  style={
                    imageInfo.style
                      ? parseStyleString(imageInfo.style)
                      : undefined
                  }
                />
              );
            }
          }

          // Check if this part is a code block
          const codeBlockMatch = part.match(/^<pre[^>]*>([\s\S]*?)<\/pre>$/);
          if (codeBlockMatch) {
            return <HTMLCodeBlock key={index} htmlContent={part} />;
          }

          // Regular HTML content
          if (part.trim()) {
            return (
              <div
                key={`html-${index}`}
                dangerouslySetInnerHTML={{ __html: part }}
              />
            );
          }

          return null;
        })}
      </div>
    );
  }

  // Split HTML by image placeholders and render with React components
  const parts = processedHtml.split(/(__blog_image_\d+__)/g);

  return (
    <div className={className}>
      {parts.map((part, index) => {
        const imageMatch = part.match(/__blog_image_(\d+)__/);
        if (imageMatch) {
          const imageIndex = parseInt(imageMatch[1]);
          const imageInfo = imageData?.[imageIndex];

          if (imageInfo) {
            return (
              <OptimizedImage
                key={`image-${imageIndex}`}
                src={imageInfo.src}
                alt={imageInfo.alt}
                className={`rounded-lg ${imageInfo.className}`}
                width={imageInfo.width ? parseInt(imageInfo.width) : undefined}
                height={
                  imageInfo.height ? parseInt(imageInfo.height) : undefined
                }
                title={imageInfo.title}
                style={
                  imageInfo.style
                    ? parseStyleString(imageInfo.style)
                    : undefined
                }
              />
            );
          }
        }

        // Regular HTML content
        if (part.trim()) {
          return (
            <div
              key={`html-${index}`}
              dangerouslySetInnerHTML={{ __html: part }}
            />
          );
        }

        return null;
      })}
    </div>
  );
}
