export default function Home() {
  return (
    <div className="min-h-screen bg-stone-950 text-stone-200">
      {/* Noise texture overlay */}
      <div className="fixed inset-0 opacity-[0.03] pointer-events-none"
        style={{
          backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noise'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noise)'/%3E%3C/svg%3E")`,
        }}
      />
      
      {/* Vignette effect */}
      <div className="fixed inset-0 pointer-events-none bg-[radial-gradient(ellipse_at_center,_transparent_0%,_rgba(0,0,0,0.4)_100%)]" />

      {/* Content */}
      <div className="relative">
        {/* Header */}
        <header className="border-b-2 border-amber-900/30 bg-stone-950/80 backdrop-blur-sm">
          <div className="max-w-5xl mx-auto flex items-center justify-between px-6 py-4">
            <div className="font-serif text-xl tracking-[0.2em] text-amber-200/90 uppercase">
              The Dark Grimoire
            </div>
            <nav className="hidden md:flex gap-8 text-sm tracking-wider uppercase">
              <a href="#about" className="text-stone-500 hover:text-amber-200 transition border-b border-transparent hover:border-amber-900/50 pb-1">About</a>
              <a href="#features" className="text-stone-500 hover:text-amber-200 transition border-b border-transparent hover:border-amber-900/50 pb-1">Features</a>
              <a href="https://forums.darkgrimoire.com" className="text-stone-500 hover:text-amber-200 transition border-b border-transparent hover:border-amber-900/50 pb-1">Forum</a>
              <a href="https://darkgrimoire.com/help.php" className="text-stone-500 hover:text-amber-200 transition border-b border-transparent hover:border-amber-900/50 pb-1">Help</a>
            </nav>
            <a
              href="https://darkgrimoire.com/register.php"
              className="text-sm tracking-wider uppercase text-amber-200/80 border border-amber-900/50 px-4 py-2 hover:bg-amber-900/20 hover:border-amber-800/60 transition"
            >
              Enter
            </a>
          </div>
        </header>

        {/* Hero Section */}
        <main className="flex flex-col items-center justify-center px-6 py-20 text-center">
          {/* Ornamental top */}
          <div className="flex items-center gap-4 mb-8 text-amber-900/60">
            <div className="w-16 h-px bg-gradient-to-r from-transparent to-amber-900/60" />
            <span className="text-2xl">✧</span>
            <div className="w-16 h-px bg-gradient-to-l from-transparent to-amber-900/60" />
          </div>

          <h1 className="font-serif text-5xl sm:text-6xl md:text-7xl tracking-[0.15em] uppercase">
            <span className="text-amber-100 drop-shadow-[0_0_30px_rgba(251,191,36,0.15)]">
              Dark Grimoire
            </span>
          </h1>
          
          {/* Ornamental bottom */}
          <div className="flex items-center gap-4 mt-6 mb-8 text-amber-900/60">
            <div className="w-24 h-px bg-gradient-to-r from-transparent to-amber-900/60" />
            <span className="text-sm tracking-[0.3em] text-stone-600 uppercase">Est. 2002</span>
            <div className="w-24 h-px bg-gradient-to-l from-transparent to-amber-900/60" />
          </div>
          
          <p className="max-w-xl text-lg leading-relaxed text-stone-400 font-light">
            A free text-based MORPG set in the world of Valorn. 
            Forge alliances, battle ancient evils, and write your legend.
          </p>

          <div className="mt-10 flex gap-6">
            <a
              href="https://darkgrimoire.com/register.php"
              className="group relative px-8 py-3 text-sm tracking-wider uppercase text-amber-100 overflow-hidden"
            >
              <span className="absolute inset-0 border-2 border-amber-900/60 group-hover:border-amber-700/60 transition" />
              <span className="absolute inset-[3px] border border-amber-900/30 group-hover:border-amber-700/40 transition" />
              <span className="absolute inset-0 bg-amber-900/10 group-hover:bg-amber-900/20 transition" />
              <span className="relative">Begin Your Journey</span>
            </a>
            <a
              href="#about"
              className="px-8 py-3 text-sm tracking-wider uppercase text-stone-500 hover:text-amber-200 transition border-b border-stone-800 hover:border-amber-900/50"
            >
              Learn More
            </a>
          </div>
        </main>

        {/* Decorative divider */}
        <Divider />

        {/* About Section */}
        <section id="about" className="max-w-4xl mx-auto px-6 py-16">
          <div className="relative border border-amber-900/30 bg-stone-900/30 p-8 md:p-12">
            {/* Corner ornaments */}
            <div className="absolute top-0 left-0 w-4 h-4 border-t-2 border-l-2 border-amber-900/50 -translate-x-px -translate-y-px" />
            <div className="absolute top-0 right-0 w-4 h-4 border-t-2 border-r-2 border-amber-900/50 translate-x-px -translate-y-px" />
            <div className="absolute bottom-0 left-0 w-4 h-4 border-b-2 border-l-2 border-amber-900/50 -translate-x-px translate-y-px" />
            <div className="absolute bottom-0 right-0 w-4 h-4 border-b-2 border-r-2 border-amber-900/50 translate-x-px translate-y-px" />
            
            <h2 className="font-serif text-2xl tracking-[0.15em] text-amber-200/90 uppercase mb-8 text-center">
              Welcome to Valorn
            </h2>
            <div className="space-y-6 text-stone-400 leading-relaxed">
              <p>
                The Dark Grimoire is a free multiplayer online role playing game unlike any other. 
                It features amazing adventure, intricate storylines, and above all a vibrant, 
                highly interactive community.
              </p>
              <p>
                You will start out in a small town as an initiate, learning the ways of Valorn 
                under the guidance of the many seasoned adventurers you will meet during your travels. 
                In a world torn apart by terrifying demons, dark beasts, and mysterious monsters, 
                your strongest weapon against the oncoming hordes is the camaraderie you develop with others.
              </p>
            </div>
          </div>
        </section>

        {/* Decorative divider */}
        <Divider />

        {/* Features Section */}
        <section id="features" className="max-w-5xl mx-auto px-6 py-16">
          <h2 className="text-center font-serif text-2xl tracking-[0.15em] text-amber-200/90 uppercase mb-12">
            Why Adventurers Choose Valorn
          </h2>
          
          <div className="grid gap-8 md:grid-cols-2">
            <FeatureCard
              title="A Living World"
              description="Valorn breathes with activity. The world evolves around you, and your actions leave a lasting mark on its history."
            />
            <FeatureCard
              title="Deep Roleplay"
              description="Craft your character's story through rich text-based interactions. Every conversation matters, every choice shapes your destiny."
            />
            <FeatureCard
              title="Legendary Community"
              description="Join a vibrant community of adventurers. Form guilds, forge lifelong friendships, and face the darkness together."
            />
            <FeatureCard
              title="Epic Quests"
              description="Battle terrifying demons, explore ancient ruins, and uncover mysteries that have haunted Valorn for centuries."
            />
          </div>
        </section>

        {/* Decorative divider */}
        <Divider />

        {/* CTA Section */}
        <section className="max-w-3xl mx-auto px-6 py-20 text-center">
          <div className="flex items-center justify-center gap-4 mb-6 text-amber-900/60">
            <span className="text-xl">⚔</span>
          </div>
          <h2 className="font-serif text-3xl tracking-[0.15em] text-amber-100 uppercase">
            Your Legend Awaits
          </h2>
          <p className="mt-6 text-lg text-stone-400">
            Thousands of adventurers have already begun their journey in Valorn. 
            Will you join them in the fight against the darkness?
          </p>
          <a
            href="https://darkgrimoire.com/register.php"
            className="group relative inline-block mt-10 px-10 py-4 text-sm tracking-wider uppercase text-amber-100"
          >
            <span className="absolute inset-0 border-2 border-amber-900/60 group-hover:border-amber-700/60 transition" />
            <span className="absolute inset-[3px] border border-amber-900/30 group-hover:border-amber-700/40 transition" />
            <span className="absolute inset-0 bg-amber-900/10 group-hover:bg-amber-900/20 transition" />
            <span className="relative">Create Your Character</span>
          </a>
        </section>

        {/* Footer */}
        <footer className="border-t border-amber-900/20 px-6 py-12">
          <div className="max-w-4xl mx-auto text-center">
            <div className="flex justify-center gap-8 mb-6 text-sm tracking-wider uppercase">
              <a href="https://darkgrimoire.com/contact.php" className="text-stone-600 hover:text-amber-200 transition">Contact</a>
              <span className="text-stone-800">•</span>
              <a href="https://darkgrimoire.com/privacy.php" className="text-stone-600 hover:text-amber-200 transition">Privacy</a>
              <span className="text-stone-800">•</span>
              <a href="https://forums.darkgrimoire.com" className="text-stone-600 hover:text-amber-200 transition">Forum</a>
            </div>
            <p className="text-stone-700 text-sm tracking-wider">
              The Dark Grimoire — A free text-based MORPG since 2002
            </p>
          </div>
        </footer>
      </div>
    </div>
  );
}

function Divider() {
  return (
    <div className="flex items-center justify-center gap-4 py-4 text-amber-900/40">
      <div className="w-32 h-px bg-gradient-to-r from-transparent to-amber-900/40" />
      <span>◆</span>
      <div className="w-32 h-px bg-gradient-to-l from-transparent to-amber-900/40" />
    </div>
  );
}

function FeatureCard({ title, description }: { title: string; description: string }) {
  return (
    <div className="relative border border-stone-800/80 bg-stone-900/20 p-6 hover:border-amber-900/40 hover:bg-stone-900/30 transition group">
      {/* Subtle corner accents */}
      <div className="absolute top-0 left-0 w-2 h-2 border-t border-l border-amber-900/30 group-hover:border-amber-800/50 transition" />
      <div className="absolute top-0 right-0 w-2 h-2 border-t border-r border-amber-900/30 group-hover:border-amber-800/50 transition" />
      <div className="absolute bottom-0 left-0 w-2 h-2 border-b border-l border-amber-900/30 group-hover:border-amber-800/50 transition" />
      <div className="absolute bottom-0 right-0 w-2 h-2 border-b border-r border-amber-900/30 group-hover:border-amber-800/50 transition" />
      
      <h3 className="font-serif text-lg tracking-wider text-amber-200/90 uppercase mb-3">{title}</h3>
      <p className="text-sm leading-relaxed text-stone-500">{description}</p>
    </div>
  );
}
