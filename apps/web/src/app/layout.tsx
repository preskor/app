import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "@radix-ui/themes/styles.css";
import "./globals.css";
import Main from "@/app/main";

const inter = Inter({
  variable: "--font-geist-sans",
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
    <html lang="en" suppressHydrationWarning>
      <body
        suppressHydrationWarning
        className={`${inter.variable} antialiased`}
      >
        <Main>{children}</Main>
      </body>
    </html>
  );
}
