import NextAuth from 'next-auth'

import GoogleProvider from 'next-auth/providers/google'

const handler = NextAuth({
  providers: [
    GoogleProvider({
      clientId: process.env.GOOGLE_CLIENT_ID,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET,
      authorization: {
        params: {
          prompt: "consent",
          access_type: "offline",
          response_type: "code",
          //hd: "spatialnetworks.com",
          scope: "openid email profile",
          idToken: true, //This is required to actually get the idToken from google: https://github.com/nextauthjs/next-auth/blob/v4/packages/next-auth/src/providers/google.ts
        },
      },
    }),
  ],
  callbacks: {
    async jwt({ token, account }) {
      if (account) {
        token.idToken = account.id_token;
      }
      return token;
    },
    async session({ session, token }){
      session.user.username = session.user.name
        .split(' ')
        .join('')
        .toLocaleLowerCase();
      session.user.uid = token.sub;
      session.id_token = token.idToken;
      return session
    }
  },
})

export {handler as GET, handler as POST};