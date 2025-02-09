import { Hero } from "@/components/hero"
import { Footer } from "@/components/footer"
import { Button } from "@/components/ui/button"

const APP_URL = process.env.APP_URL || "http://localhost:3000"

export default function Home() {
  return (
    <div className="min-h-screen bg-background text-foreground flex flex-col">
      <Hero>
        <h1 className="text-6xl md:text-8xl font-bold text-stone-100 font-serif tracking-wide drop-shadow-lg">
          IRON PSALM
        </h1>
        <p className="text-lg md:text-xl text-stone-200/90 max-w-2xl font-serif leading-relaxed drop-shadow text-center">
          Where Reality Unravels. A dark fantasy realm where humanity clings to existence.
        </p>
        <div className="flex gap-4 items-center justify-center">
          <Button asChild>
            <a href={`${APP_URL}`}>Enter the Realm</a>
          </Button>
          <Button asChild variant="secondary">
            <a href="/lore">Discover the Lore</a>
          </Button>
        </div>
      </Hero>
      <Footer />
    </div>
  )
}
