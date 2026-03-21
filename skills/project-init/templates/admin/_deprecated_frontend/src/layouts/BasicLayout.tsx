import { ProLayout } from '@ant-design/pro-components';
import { Outlet, useNavigate, useLocation } from 'umi';
import {
  HomeOutlined,
  UserOutlined,
  SettingOutlined,
} from '@ant-design/icons';

const menuItems = [
  {
    path: '/home',
    name: '首页',
    icon: <HomeOutlined />,
  },
  {
    path: '/users',
    name: '用户管理',
    icon: <UserOutlined />,
  },
];

export default function BasicLayout() {
  const navigate = useNavigate();
  const location = useLocation();

  return (
    <ProLayout
      title="{{PROJECT_NAME}} Admin"
      logo="/logo.svg"
      layout="mix"
      splitMenus={false}
      fixedHeader
      fixSiderbar
      route={{
        path: '/',
        routes: menuItems,
      }}
      location={{
        pathname: location.pathname,
      }}
      menuItemRender={(item, dom) => (
        <div onClick={() => item.path && navigate(item.path)}>
          {dom}
        </div>
      )}
      rightContentRender={() => (
        <div style={{ marginRight: 24 }}>
          <SettingOutlined style={{ marginRight: 8 }} />
          设置
        </div>
      )}
    >
      <Outlet />
    </ProLayout>
  );
}
