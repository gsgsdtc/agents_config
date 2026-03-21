import { defineConfig } from 'umi';

export default defineConfig({
  title: '{{PROJECT_NAME}} Admin',
  links: [{ rel: 'icon', href: '/favicon.ico' }],
  routes: [
    {
      path: '/',
      component: '@/layouts/BasicLayout',
      routes: [
        { path: '/', redirect: '/home' },
        { path: '/home', component: '@/pages/Home' },
        { path: '/users', component: '@/pages/User' },
        { path: '/*', component: '@/pages/404' },
      ],
    },
  ],
  proxy: {
    '/api': {
      target: 'http://localhost:5000',
      changeOrigin: true,
    },
    '/swagger': {
      target: 'http://localhost:5000',
      changeOrigin: true,
    },
  },
  antd: {},
  layout: false,
  npmClient: 'npm',
});
