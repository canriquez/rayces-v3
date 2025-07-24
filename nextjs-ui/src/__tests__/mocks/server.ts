// MSW Server Setup for Node.js (Jest)
import { setupServer } from 'msw/node';
import { handlers } from './handlers';

// Create MSW server instance
export const server = setupServer(...handlers);

// Test setup utilities
export const setupMSW = () => {
  beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
  afterEach(() => server.resetHandlers());
  afterAll(() => server.close());
};