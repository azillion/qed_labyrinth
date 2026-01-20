import { Hero } from "@/components/hero";
import { Footer } from "@/components/footer";
import { posts } from "@/content/posts";

export const metadata = {
  title: "Iron Psalm | Blog",
  description: "Development updates and articles from the Iron Psalm team",
};

export default function BlogPage() {
  return (
    <div className="min-h-screen bg-background text-foreground flex flex-col">
      <Hero className="min-h-[15vh]">
        <div className="max-w-4xl mx-auto text-center">
          <h1 className="text-3xl font-bold text-stone-100 font-serif tracking-wide drop-shadow-lg mb-2">
            Dev Blog
          </h1>
          <p className="text-sm text-stone-200/90 font-serif leading-relaxed drop-shadow max-w-2xl mx-auto">
            Articles, updates, and notes from the road ahead.
          </p>
        </div>
      </Hero>

      {/* Post list */}
      <section className="relative z-10 bg-black/80 backdrop-blur-md py-16 border-t border-stone-700/20">
        <div className="container mx-auto px-4 flex flex-col gap-12 max-w-4xl">
          {posts
            .sort((a, b) => new Date(b.date) - new Date(a.date))
            .map(({ slug, title, date, excerpt }) => (
              <article key={slug} className="group">
                <div className="border border-stone-700/30 rounded-lg p-8 hover:border-stone-600/50 transition-colors bg-black/40 backdrop-blur-sm">
                  <h2 className="text-3xl font-semibold text-stone-100 font-serif mb-3 group-hover:text-stone-50 transition-colors">
                    <a href={`/blog/${slug}`} className="hover:underline decoration-stone-500">
                      {title}
                    </a>
                  </h2>
                  <time className="text-sm text-stone-400 mb-4 block" dateTime={date}>
                    {new Date(date).toLocaleDateString(undefined, {
                      year: "numeric",
                      month: "long",
                      day: "numeric",
                    })}
                  </time>
                  <p className="text-stone-300/90 leading-relaxed text-lg mb-6">{excerpt}</p>
                  <a
                    href={`/blog/${slug}`}
                    className="inline-flex items-center gap-2 text-stone-400 hover:text-stone-200 transition-colors font-medium"
                  >
                    Read more 
                    <span className="group-hover:translate-x-1 transition-transform">→</span>
                  </a>
                </div>
              </article>
            ))}
        </div>
      </section>

      <Footer />
    </div>
  );
}
