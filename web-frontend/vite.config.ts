import path from 'path';
import { defineConfig, loadEnv } from 'vite';
import react from '@vitejs/plugin-react';
import { VitePWA } from 'vite-plugin-pwa';

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, '.', '');

  // Determine the correct API target based on environment
  const apiTarget = process.env.VITE_API_URL || 'http://localhost:3000';

  return {
    server: {
      port: 5173,
      host: '0.0.0.0',
      proxy: {
        '/api': {
          target: apiTarget,
          changeOrigin: true,
          secure: false,
        },
      },
    },
    plugins: [
      react(),
      VitePWA({
        registerType: 'autoUpdate',
        includeAssets: ['logo.svg', 'brand/logo.png', 'brand/apple-touch-icon.png', 'brand/icon-192.png', 'brand/icon-512.png', 'brand/icon-maskable-512.png'],
        manifest: {
          name: 'Go-With-Us',
          short_name: 'GoWithUs',
          description: 'แอปพลิเคชันสำหรับหาเพื่อนเที่ยว',
          theme_color: '#ffffff',
          background_color: '#ffffff',
          display: 'standalone',
          icons: [
            { src: '/brand/icon-192.png', sizes: '192x192', type: 'image/png', purpose: 'any' },
            { src: '/brand/icon-512.png', sizes: '512x512', type: 'image/png', purpose: 'any' },
            { src: '/brand/icon-maskable-512.png', sizes: '512x512', type: 'image/png', purpose: 'maskable' }
          ]
        }
      })
    ],
    define: {
      'process.env.API_KEY': JSON.stringify(env.GEMINI_API_KEY),
      'process.env.GEMINI_API_KEY': JSON.stringify(env.GEMINI_API_KEY)
    },
    resolve: {
      alias: {
        '@': path.resolve(__dirname, '.'),
      }
    }
  };
});
