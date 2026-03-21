import { Card, Row, Col, Statistic } from 'antd';
import { UserOutlined, FileOutlined, CheckCircleOutlined } from '@ant-design/icons';

export default function Home() {
  return (
    <div style={{ padding: 24 }}>
      <h2>欢迎使用 {{PROJECT_NAME}} Admin</h2>

      <Row gutter={16} style={{ marginTop: 24 }}>
        <Col span={8}>
          <Card>
            <Statistic
              title="用户总数"
              value={1128}
              prefix={<UserOutlined />}
            />
          </Card>
        </Col>
        <Col span={8}>
          <Card>
            <Statistic
              title="文档数量"
              value={93}
              prefix={<FileOutlined />}
            />
          </Card>
        </Col>
        <Col span={8}>
          <Card>
            <Statistic
              title="已完成任务"
              value={56}
              prefix={<CheckCircleOutlined />}
              valueStyle={{ color: '#3f8600' }}
            />
          </Card>
        </Col>
      </Row>

      <Card style={{ marginTop: 24 }} title="快速开始">
        <ul>
          <li>查看 <a href="/swagger" target="_blank">Swagger API 文档</a></li>
          <li>管理 <a href="/users">用户列表</a></li>
        </ul>
      </Card>
    </div>
  );
}
