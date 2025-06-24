/* eslint-disable @next/next/no-img-element */
"use client"

import { signIn, signOut, useSession } from 'next-auth/react';
import { Session } from "next-auth";
import Link from 'next/link';
import Image from 'next/image';
import React, { useEffect, useState } from 'react'
import { HiHome, HiDotsHorizontal } from 'react-icons/hi';
import { signInToBackend } from '../api/rails-app/api'


export default function Sidebar() {
  const { data: session } = useSession() as { data: Session | null };

  useEffect(() => {
    //@ts-ignore
    if (session && session.id_token) {
      console.log('Attempt signin with id token:', session)
      //@ts-ignore
      signInToBackend(session.id_token)
        .then(data => {
          console.log('Signed in to backend:', data);
        })
        .catch(error => {
          console.error('Error signing in to backend:', error);
        });
    }
  }, [session]);

  return (
    <div className='flex flex-col p-3 justify-between h-screen'>
      <div className='flex flex-col gap-4 p-3'>
        <div className='flex items-center justify-start'>
          <Link href='/' className='flex items-center p-3 hover:bg-gray-100 rounded-full transition-all duration-200 gap-2 w-fit'>
            <Image src="/assets/MyHub_icon.png" width={30} height={30} alt="Loading" />
            <span className='font-bold hidden xl:inline'>Home</span>
          </Link>
        </div>
      { session 
        ? <button className='bg-blue-400 text-white rounded-full hover:brightness-95 transition-all duration-200 w-48 h-9 shadow-md hidden xl:inline'
        onClick={() => signOut()}
        >
          Sign Out
        </button>
        :<button className='bg-blue-400 text-white rounded-full hover:brightness-95 transition-all duration-200 w-48 h-9 shadow-md hidden xl:inline'
        onClick={() => signIn()}
        >
          Sign In
        </button>
      }
      </div>
      {
        session && (
          <div className='text-gray-700 text-sm flex items-center cursor-pointer p-3 hover:bg-gray-100 rounded-full transition-all duration-200'>
            <img src={session?.user?.image ?? ''} alt='usr-img' className='h-10 w-10 rounded-full xl:mr-2'/>
            <div className='hidden xl:inline'>
              <h4 className='font-bold'>{session?.user?.name}</h4>
              <p className='text-gray-500'>@{session?.user?.username}</p>
            </div>
            <HiDotsHorizontal className='h-5 xl:ml-8 hidden xl:inline' />
          </div>
        )
      }
    </div>
  )
}

