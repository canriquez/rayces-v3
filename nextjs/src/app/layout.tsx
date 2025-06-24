import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import Sidebar from "./components/Sidebar";
import News from "./components/News";
import SessionWrapper from "./components/SessionWrapper";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "MyHub Documentation News",
  description: "Share what is good..",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <SessionWrapper>
    <html lang="en">
      <body className={inter.className}>
        <div className='flex justify-between max-w-7xl mx-auto'>
          <div className='hidden sm:inline border-r h-screen sticky top-0'>
            <Sidebar />
          </div>
          <div className='w-2xl flex-1'>{children}</div>
          <div className='lg:flex-col p-3 h-screen border-l hidden lg:flex w-[28rem] sticky top-0'>
            <div className='sticky top-0 bg-white py-2'>
              <input
                type='text'
                placeholder="Search"
                className='bg-gray-100 border border-gray-200 rounded-3xl text-sm w-full px-4 py-2'
              ></input>
            </div>
            <News/>
          </div>
        </div>
      </body>
    </html>
    </SessionWrapper>
  );
}
