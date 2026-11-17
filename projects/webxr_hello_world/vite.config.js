import { defineConfig } from 'vite';
import basicSsl from '@vitejs/plugin-basic-ssl';

export default defineConfig(({ mode }) => {
  const isHttps = process.env.VITE_HTTPS === 'true' || process.argv.includes('--https');
  return {
    server: {
      host: '0.0.0.0',
      port: 5173,
      https: isHttps
    },
    preview: {
      host: '0.0.0.0',
      port: 5173
    },
    plugins: isHttps ? [basicSsl()] : []
  };
});
