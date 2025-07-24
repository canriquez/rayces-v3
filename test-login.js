#!/usr/bin/env node

const axios = require('axios');

async function testLogin() {
  try {
    console.log('Testing login endpoint...');
    
    const response = await axios.post('http://localhost:4000/login', {
      user: {
        email: 'admin@rayces.com',
        password: 'password123'
      }
    }, {
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Organization-Subdomain': 'rayces'
      }
    });
    
    console.log('\nLogin successful!');
    console.log('Status:', response.data.status);
    console.log('User:', response.data.data);
    console.log('Token:', response.data.token);
    
    // Test protected endpoint with token
    console.log('\nTesting protected endpoint with token...');
    const protectedResponse = await axios.get('http://localhost:4000/api/v1/users', {
      headers: {
        'Authorization': `Bearer ${response.data.token}`,
        'X-Organization-Subdomain': 'rayces'
      }
    });
    
    console.log('Protected endpoint response:', protectedResponse.data);
    
  } catch (error) {
    console.error('Error:', error.response?.data || error.message);
  }
}

testLogin();