import { authToken } from '@features/auth/stores/auth';
import { API_URL } from './constants';

const BASE_URL = API_URL;

const getHeaders = () => {
  const headers = {
    'Content-Type': 'application/json',
  };
  
  const token = authToken();
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }
  
  return headers;
};

async function fetchWrapper(endpoint, options = {}) {
  const url = `${BASE_URL}${endpoint}`;
  const headers = getHeaders();
  
  try {
    const response = await fetch(url, {
      ...options,
      headers: {
        ...headers,
        ...options.headers,
      },
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || 'Something went wrong');
    }

    return await response.json();
  } catch (error) {
    console.error('API Error:', error);
    throw error;
  }
}

// HTTP method helpers
export const fetcher = {
  get: (endpoint) => fetchWrapper(endpoint),
  
  post: (endpoint, data = {}) => fetchWrapper(endpoint, {
    method: 'POST',
    body: JSON.stringify(data),
  }),
  
  put: (endpoint, data = {}) => fetchWrapper(endpoint, {
    method: 'PUT',
    body: JSON.stringify(data),
  }),
  
  patch: (endpoint, data = {}) => fetchWrapper(endpoint, {
    method: 'PATCH',
    body: JSON.stringify(data),
  }),
  
  delete: (endpoint) => fetchWrapper(endpoint, {
    method: 'DELETE',
  }),
};

export default fetcher;
