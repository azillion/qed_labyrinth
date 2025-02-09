import * as React from "react"
import { Slot } from "@radix-ui/react-slot"
import { cva } from "class-variance-authority"
import { cn } from "@/lib/utils"

const buttonVariants = cva(
  "inline-flex items-center justify-center rounded-sm font-serif tracking-wide transition-all duration-200",
  {
    variants: {
      variant: {
        default: "border-2 border-stone-300/40 bg-black/50 hover:bg-stone-900/50 hover:border-stone-300/60 text-stone-100 hover:shadow-[0_0_15px_rgba(255,255,255,0.1)] hover:-translate-y-0.5",
        secondary: "border-2 border-stone-300/30 bg-black/40 hover:bg-stone-900/40 hover:border-stone-300/50 text-stone-200/90 hover:shadow-[0_0_12px_rgba(255,255,255,0.07)] hover:-translate-y-0.5",
      },
      size: {
        default: "h-10 px-6 text-sm sm:h-12 sm:px-8 sm:text-base",
        small: "h-8 px-4 text-sm",
        large: "h-14 px-10 text-lg",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
)

const Button = React.forwardRef(({ className, variant, size, asChild = false, ...props }, ref) => {
  const Comp = asChild ? Slot : "button"
  return (
    <Comp
      className={cn(buttonVariants({ variant, size, className }))}
      ref={ref}
      {...props}
    />
  )
})
Button.displayName = "Button"

export { Button, buttonVariants }
