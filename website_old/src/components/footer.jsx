import Image from "next/image"
import { cn } from "@/lib/utils"

const footerLinks = [
  { href: '/', icon: '/home.svg', label: 'Home' },
  { href: '/lore', icon: '/scroll.svg', label: 'Lore' },
  { href: '/blog', icon: '/scroll.svg', label: 'Blog' },
  { href: '/chronicles', icon: '/scroll.svg', label: 'Chronicles' },
  { href: '/characters', icon: '/sword.svg', label: 'Characters' },
  { href: '/world', icon: '/world.svg', label: 'World' },
]

export function Footer({ className, ...props }) {
  return (
    <footer className={cn("relative z-10 py-4 bg-black backdrop-blur-md border-t border-stone-700/20", className)} {...props}>
      <div className="container mx-auto px-4 flex justify-center gap-6">
        {footerLinks.map(({ href, icon, label }) => (
          <a
            key={href}
            className="flex items-center gap-2 text-stone-300/90 hover:text-stone-100 transition-colors font-serif"
            href={href}
          >
            <Image
              src={icon}
              alt={label}
              width={16}
              height={16}
              className="opacity-100 invert"
            />
            {label}
          </a>
        ))}
      </div>
    </footer>
  )
} 