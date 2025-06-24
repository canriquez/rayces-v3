/* eslint-disable @next/next/no-img-element */
'use client';

import { useSession } from 'next-auth/react'
import Image from 'next/image';

import React, { useState } from 'react'

export default function Input() {
  const {data: session } = useSession();
  const [content, setContent] = useState("");
  const [summary, setSummary] = useState("");
  const [loading, setLoading] = useState(false);

  const appDomain = process.env.NEXT_PUBLIC_DOMAIN;
  const apiToken = process.env.NEXT_PUBLIC_API_LLM_TOKEN || 'will_not_work';

  if (!session) return null;

  const handleContentChange = (event: React.ChangeEvent<HTMLTextAreaElement>) => {
    setContent(event.target.value);
  }

  const handleSubmit = () => {
    setSummary('');
    setLoading(true);

    const prompt = `You are a expert copy writer on technical software development blogposts.
      Produce a summary of this blogpost in no more than 2 sentences. If some unrelated content is included
      is introduced or too short to understand, explain the user that there is not
      enough copy to produce a clear summary. When the input is the correct one, 
      make sure to mention the exact author usernames (if possible) 
      Make the summary serious, and informative to make it easy
      for readers to understand the content below: 
      """ ${content} """.`;

    fetch(`https://${appDomain}/api/v2/llm/generate`, {
      method: "POST",
      headers: {
        "X-ApiToken": apiToken,
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: JSON.stringify({
        template: prompt
      })
    })
      .then((res) => {
        console.log('RES', res)
        if (!res.ok) {
          setSummary('Failed to fetch')
        }
        return res.json()})
      .then((data) => {
        const response = data.candidates[0].content.parts[0].text;
        setLoading(false);
        setSummary(response);
      })
      .catch((error) => {
        console.error('Error:', error);
        alert('Something went wrong... try again later');
        setLoading(false);
      });
  }

  return (
    <div className='flex border-b border-gray-200 p-3 space-x-3 w-full'>
      <img src={session?.user?.image || ''} alt='user-img' className='h-11 w-11 rounded-full cursor-pointer hover:brightmess-95'/>
      <div className='w-full divide-y divide-gray-200 '>
        <textarea
          className='w-full border-none outline-none tracking-wide min-h-[50px] text-gray-700'
          placeholder='Paste your documentation here so..' rows={8}
          onChange={handleContentChange}
        ></textarea>
        <div className='flex items-center justify-start p-2.5'>
          <button
            onClick={ handleSubmit }
            disabled={!content || loading}
            className='bg-blue-400 text-white px-4 py-1.5 rounded-full font-bold shadow-md hover:brigthness-95 disabled:opacity-50'>
            Summarize me
          </button>
          {loading && <Image src="/assets/loader.gif" width={35} height={35} alt="Loading" />}
        </div>
        <div>
          {summary}
        </div>
      </div>
    </div>
  )
}
