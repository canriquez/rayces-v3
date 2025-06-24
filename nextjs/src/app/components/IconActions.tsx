'use client'

import React, { useEffect, useState } from 'react'
import { HiOutlineChat, HiOutlineHeart, HiHeart, HiOutlineTrash } from 'react-icons/hi'
import { CgLoadbarSound } from "react-icons/cg";
import { IoBookmarkOutline } from "react-icons/io5";
import { useSession } from  'next-auth/react'
import { signIn } from 'next-auth/react';
import { dislikePostByUser, likePostByUser } from '../api/rails-app/api';


interface IconActionsProps {
  id: number;
  isLikedByUser: boolean;
  refresh: () => void;
}

const IconActions: React.FC<IconActionsProps> = ({ id, isLikedByUser, refresh }) => {
  const { data: session } = useSession();

  const likePost = async() => {
      if (session) {
        if(!isLikedByUser) {
          //@ts-ignore
          await likePostByUser(session.id_token, id)
            .then(() => refresh())
            .catch(error => console.error('Error liking post:', error));
        } else {
          //@ts-ignore
          await dislikePostByUser(session.id_token, id)
            .then(() => refresh())
            .catch(error => console.error('Error liking post:', error));
        }

      } else {
        signIn();
      }
  }
  return (
    <div className='flex justify-start gap-5 p-2 text-gray-500'>
      <HiOutlineChat className='h-8 w-8 cursor-pointer rounded-full transition
      duration-200 ease-in-out p-2 hover:text-sky-500 hover:bg-sky-100'/>
      {
        isLikedByUser
        ?<HiHeart
        onClick={likePost}
        className='h-8 w-8 cursor-pointer rounded-full transition text-red-600
        duration-200 ease-in-out p-2 hover:text-red-500 hover:bg-red-100'
        />
        :<HiOutlineHeart
        onClick={likePost}
        className='h-8 w-8 cursor-pointer rounded-full transition
        duration-200 ease-in-out p-2 hover:text-red-500 hover:bg-red-100'
        />
      }

      <CgLoadbarSound className='h-8 w-8 cursor-pointer rounded-full transition
      duration-200 ease-in-out p-2 hover:text-sky-500 hover:bg-sky-100'/>
      <IoBookmarkOutline className='h-8 w-8 cursor-pointer rounded-full transition
      duration-200 ease-in-out p-2 hover:text-sky-500 hover:bg-sky-100'/>
    </div>
  )
}

export default IconActions;
