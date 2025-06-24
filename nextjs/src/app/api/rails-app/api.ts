export async function signInToBackend(idToken: string) {
  const response = await fetch('http://localhost:4000/sign_in', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${idToken}`,
      'Content-Type': 'application/json'
    }
  });

  if (!response.ok) {
    throw new Error('Failed to sign in to backend');
  }

  return response.json();
}

export async function fetchAllPosts(idToken: string) {
  const response = await fetch('http://localhost:4000/posts', {
    method: 'GET',
    headers: {
      'Authorization': `Bearer ${idToken}`,
      'Content-Type': 'application/json'
    }
  });

  if (!response.ok) {
    throw new Error('Failed to fetch posts');
  }

  return response.json();
}

export async function fetchPostById(idToken: string, postId: number) {
  const response = await fetch(`http://localhost:4000/posts/${postId}`, {
    method: 'GET',
    headers: {
      'Authorization': `Bearer ${idToken}`,
      'Content-Type': 'application/json'
    }
  });

  if (!response.ok) {
    throw new Error(`Failed to fetch post with ID ${postId}`);
  }

  return response.json();
}

export async function likePostByUser(idToken: string, postId: number) {
  const response = await fetch(`http://localhost:4000/posts/${postId}/like`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${idToken}`,
      'Content-Type': 'application/json'
    }
  });

  if (!response.ok) {
    throw new Error('Failed to like post');
  }

  return response.json();
}

export async function dislikePostByUser(idToken: string, postId: number) {
  const response = await fetch(`http://localhost:4000/posts/${postId}/like`, {
    method: 'DELETE',
    headers: {
      'Authorization': `Bearer ${idToken}`,
      'Content-Type': 'application/json'
    }
  });

  if (!response.ok) {
    throw new Error('Failed to dislike post');
  }

  return response.json();
}


