"use client";

import { Theme } from "@radix-ui/themes";

type MainProps = {
  children: React.ReactNode;
};

export default function Main({ children }: MainProps) {
  return <Theme accentColor="teal">{children}</Theme>;
}
