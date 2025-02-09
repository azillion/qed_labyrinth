import { cn } from "@/lib/utils"

export function Hero({ 
  className,
  children,
  backgroundImage = '/kingdom2.png',
  ...props
}) {
  return (
    <div className={cn("relative flex-1 flex items-center justify-center", className)} {...props}>
      {/* Hero Background */}
      <div 
        className="absolute inset-0 bg-cover bg-center"
        style={{
          backgroundImage: `url('${backgroundImage}')`,
        }}
      >
        {/* Lighter overlay that maintains readability */}
        <div className="absolute inset-0 bg-gradient-to-b from-black/70 via-black/30 to-black/70" />
        <div className="absolute inset-0 bg-black/20" />
      </div>

      {/* Hero Content */}
      <div className="relative z-10 container mx-auto px-4 flex flex-col items-center justify-center gap-8">
        {children}
      </div>
    </div>
  )
} 