import Link from 'next/link';
import React from 'react';
import IconActions from './IconActions';
import { HiDotsHorizontal } from 'react-icons/hi';
import { RiRobot2Line } from "react-icons/ri";



type Post = {
  id: number;
  content: string,
  metadata: Record<string, any>,
  liked_by_current_user: boolean
  creation_date: string;
  created_at: string;
};
interface PostProps {
  post: Post;
  id: number;
  updatePosts: () => void;
}

interface TooltipProps {
  text: string;
}

interface Props {
  post: Post;
}

const Tooltip: React.FC<TooltipProps> = ({ text }) => {
  return (
    <div className="absolute bottom-full mb-2 hidden group-hover:block whitespace-no-wrap bg-gray-800 text-white text-xs rounded py-1 px-2 z-10">
      @{text}
    </div>
  );
};

export const GitHubAuthors: React.FC<Props> = ({ post }) => {
  return (
    <div className="flex space-x-2">
      {post.metadata?.authors?.map((author: string) => (
        <div key={author} className="relative group">
          <img
            src={`https://github.com/${author}.png`}
            alt={`author: ${author}`}
            className="w-8 h-8 rounded-full"
          />
          <Tooltip text={author} />
        </div>
      ))}
    </div>
  );
};

import { format, parseISO } from 'date-fns';

export function formatCreationDate(dateString: string) {
  const date = parseISO(dateString);
  return format(date, "MMMM do, yyyy");
}



const Post: React.FC<PostProps> = ({ post, id, updatePosts }) => {
  return (
    <div className='flex-col p-3 border-b border-gray-200 hover:bg-gray-50'>
      <div className='flex items-center justify-between mb-4'>
        <GitHubAuthors post={post}/>
        <div className='flex items-center justify-between'>
          <div className='authors flex items-center space-x-1 whitespace-nowrap'>
            {post?.metadata?.authors?.map((author: string, index: number) => (
              <span key={index+author} className='text-xs truncate'>@{author}{post?.metadata?.authors.length > index+1 ? ', ' :''}</span>
            ))}
          </div>
          <HiDotsHorizontal className='ml-2 text-sm' />
        </div>
      </div>
      <div className='flex-1'>
        <h4 className='font-bold text-sm mb-3 text-wrap'>{post?.metadata?.title}</h4>
        <Link href={'/posts/${id}'}>
            <p className='text-gray-800 text-sm my-3'>{post?.metadata?.summary}</p>
        </Link>
        <div className='flex items-center justify-between'>
          <IconActions
            id={id}
            isLikedByUser={post.liked_by_current_user}
            refresh={updatePosts}
          />
          <div className='flex items-center'>
            <RiRobot2Line
              className='h-8 w-8 cursor-pointer rounded-full transition text-sky-600
              duration-200 ease-in-out p-2 hover:text-sky-500 hover:bg-sky-100'
            />
            <div className='text-xs italic text-gray-400'>
              @ {formatCreationDate(post.created_at)}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Post;
