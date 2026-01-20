import { Hero } from "@/components/hero";
import { Footer } from "@/components/footer";
import { posts } from "@/content/posts";
import { notFound } from "next/navigation";
import { BlogImage } from "@/components/BlogImage";

export async function generateStaticParams() {
  return posts.map((post) => ({ slug: post.slug }));
}

export async function generateMetadata({ params }) {
  const { slug } = await params;
  const post = posts.find((p) => p.slug === slug);
  if (!post) return {};
  return {
    title: `${post.title} | Iron Psalm Blog`,
    description: post.excerpt,
  };
}

export default async function BlogPostPage({ params }) {
  const { slug } = await params;
  const post = posts.find((p) => p.slug === slug);

  if (!post) {
    notFound();
  }

  return (
    <div className="min-h-screen bg-background text-foreground flex flex-col">
      <Hero className="min-h-[20vh]">
        <div className="max-w-4xl mx-auto text-center">
          <h1 className="text-4xl font-bold text-stone-100 font-serif tracking-wide drop-shadow-lg mb-4">
            {post.title}
          </h1>
          <time className="text-base text-stone-400 font-serif" dateTime={post.date}>
            {new Date(post.date).toLocaleDateString(undefined, {
              year: "numeric",
              month: "long",
              day: "numeric",
            })}
          </time>
        </div>
      </Hero>

      <article className="relative z-10 bg-black/80 backdrop-blur-md py-16 border-t border-stone-700/20">
        <div className="container mx-auto px-4 max-w-4xl">
          <div className="mb-8">
            <a 
              href="/blog" 
              className="inline-flex items-center gap-2 text-stone-400 hover:text-stone-200 transition-colors font-medium"
            >
              <span className="hover:-translate-x-1 transition-transform">←</span>
              Back to Blog
            </a>
          </div>
          <div className="prose prose-invert prose-lg max-w-none">
            <div className="font-serif leading-relaxed text-stone-200/90 text-lg">
              {post.content.split('\n').map((line, index) => {
                // Check if line contains an image markdown
                const imageMatch = line.match(/!\[([^\]]*)\]\(([^)]+)\)/);
                if (imageMatch) {
                  const [, alt, src] = imageMatch;
                  return <BlogImage key={index} src={src} alt={alt} />;
                }
                
                // Handle headers
                if (line.startsWith('## ')) {
                  return <h2 key={index} className="text-2xl font-bold text-stone-100 mt-8 mb-4">{line.replace('## ', '')}</h2>;
                }
                if (line.startsWith('### ')) {
                  return <h3 key={index} className="text-xl font-semibold text-stone-100 mt-6 mb-3">{line.replace('### ', '')}</h3>;
                }
                
                // Handle horizontal rule
                if (line.trim() === '---') {
                  return <hr key={index} className="border-stone-700 my-8" />;
                }
                
                // Handle bold text
                if (line.includes('**')) {
                  const parts = line.split(/(\*\*[^*]+\*\*)/g);
                  return (
                    <p key={index} className="mb-4">
                      {parts.map((part, partIndex) => {
                        if (part.startsWith('**') && part.endsWith('**')) {
                          return <strong key={partIndex} className="font-semibold text-stone-100">{part.slice(2, -2)}</strong>;
                        }
                        return part;
                      })}
                    </p>
                  );
                }
                
                // Regular paragraphs
                if (line.trim()) {
                  return <p key={index} className="mb-4">{line}</p>;
                }
                
                return null;
              })}
            </div>
          </div>
        </div>
      </article>

      <Footer />
    </div>
  );
}
