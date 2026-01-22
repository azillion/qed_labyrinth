import type { Metadata } from "next";
import { Cinzel, Inter } from "next/font/google";
import "./globals.css";

const cinzel = Cinzel({
  variable: "--font-cinzel",
  subsets: ["latin"],
  weight: ["400", "700"],
});

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "The Dark Grimoire - Free Text-Based MORPG",
  description: "A free text-based MORPG set in the world of Valorn. Forge alliances, battle ancient evils, and write your legend.",
  keywords: ["MORPG", "text-based game", "RPG", "online game", "fantasy", "Valorn", "free to play"],
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body
        className={`${cinzel.variable} ${inter.variable} font-sans antialiased`}
        style={{ fontFamily: "var(--font-inter), sans-serif" }}
      >
        {children}
      </body>
    </html>
  );
}
