"use client"

import { ReactNode } from "react";
import { SessionProvider } from "next-auth/react"

interface Props {
  children: ReactNode;
}

const SessionWrapper = ({children}: Props): JSX.Element => {
  return <SessionProvider>{children}</SessionProvider>
}

export default SessionWrapper;