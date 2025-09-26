import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Preskor - Crypto Football Prediction Markets",
  description:
    "Trade on football match outcomes with cryptocurrency. Make predictions, earn rewards, and join the future of sports betting.",
  keywords: [
    "crypto",
    "football",
    "prediction",
    "markets",
    "blockchain",
    "betting",
  ],
  authors: [{ name: "Preskor Team" }],
  creator: "Preskor",
  openGraph: {
    title: "Preskor - Crypto Football Prediction Markets",
    description:
      "Trade on football match outcomes with cryptocurrency. Make predictions, earn rewards, and join the future of sports betting.",
    type: "website",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased`}
      >
        {children}
      </body>
    </html>
  );
}
