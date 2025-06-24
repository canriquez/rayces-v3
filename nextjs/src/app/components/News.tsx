/* eslint-disable @next/next/no-img-element */
"use client"

import { useSession } from 'next-auth/react';
import React, { useEffect, useState } from 'react'
import { fetchAllPosts } from '../api/rails-app/api';
import { GitHubAuthors } from './Post';

export default function News() {
  const { data: session } = useSession();
  const [posts, setPosts] = useState<any[]>([]);
  const [news, setNews] = useState([])
  const [articleNumber, setArticleNum] = useState(3);

useEffect(() => {
  //@ts-ignore
  if (session?.id_token) {
    //@ts-ignore
    fetchAllPosts(session.id_token)
      .then(data => setPosts(data))
      .catch(error => console.error('Error fetching all posts:', error));
  } else {
    console.log('No session available')
  }
}, [session]);

  return (
    <div className='text-gray-too space-y-3 bg-gray-100 rounded-xl pt-2'>
      <h4 className='font-bold text-xl px-4'>Top 10 Most Viewed Articles</h4>
      {posts.slice(0, articleNumber).map((post: any, index) => {
        return (
          <div key={post.metadata.slug}>
            <a href='#' target='_blank'>
              <div className='flex items-center justify-between px-4 py-2 space-x-1 hover:bg-gray-200 transition duration-200'>
                <div className='space-y-0.5'>
                  <h6 className='text-sm font-bold'>{post.metadata.title}</h6>
                  <p className='text-xs font-medium text-gray-500'>
                    {post.source}
                  </p>
                </div>
                <div className='pl-5'>
                  <GitHubAuthors post={post}/>
                </div>
              </div>
            </a>
          </div>
      )})}
          <button
            onClick={() => setArticleNum(articleNumber+3)}
            className='w-full py-2 bg-gray-200 hover:bg-gray-300 transition duration-300'
          >
            Load more
          </button>
    </div>
  )
}
