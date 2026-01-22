import { Geist, Geist_Mono } from "next/font/google";
import { Crimson_Text } from 'next/font/google';
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

const crimsonText = Crimson_Text({
  subsets: ['latin'],
  weight: ['400', '600', '700'],
  variable: '--font-crimson',
});

export const metadata = {
  title: "Iron Psalm",
  description: "Where Reality Unravels.",
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <head>
        <script defer data-domain="ironpsalm.com" src="https://plausible.io/js/script.js"></script>
      </head>
      <body
        className={`${geistSans.variable} ${geistMono.variable} ${crimsonText.variable} antialiased font-serif`}
      >
        {children}
      </body>
    </html>
  );
}
