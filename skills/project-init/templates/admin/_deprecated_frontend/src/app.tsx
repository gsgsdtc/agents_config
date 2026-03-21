import { ConfigProvider } from 'antd';
import zhCN from 'antd/locale/zh_CN';

export function rootContainer(container: React.ReactNode) {
  return (
    <ConfigProvider locale={zhCN}>
      {container}
    </ConfigProvider>
  );
}

export const layout = {
  title: '{{PROJECT_NAME}} Admin',
  logo: '/logo.svg',
};
