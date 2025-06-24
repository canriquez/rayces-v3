import React from 'react';
import Post from './Post';

interface FeedProps {
  posts: any[];
  updatePosts: () => void;
}

const Feed: React.FC<FeedProps> = ({ posts, updatePosts }) => {
  if (!posts.length) {
    return <div>..</div>;
  } else {
    console.log('posts: ', posts);
  }

  return (
    <div>
      {posts.map((post, index) => (
        <Post
          key={post.created_at+index}
          post={post} id={post.id}
          updatePosts={updatePosts} 
        />
      ))}
    </div>
  );
};
export default Feed;
