import type { ReactNode } from "react";
import "./globals.css";
export const metadata = { title: "Pethinho Hotel", description: "Creche, hospedagem e banho e tosa" };
export default function RootLayout({ children }: { children: ReactNode }) { return <html lang="pt-BR"><body>{children}</body></html>; }
