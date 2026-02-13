# 社区智慧养老服务平台（SpringBoot + Vue）

## 1. 项目简介
本项目实现一个基于 **SpringBoot + Vue + MySQL + Redis** 的社区智慧养老服务平台，采用前后端分离架构，覆盖：
- 老年用户端（ELDER）
- 家属端（FAMILY）
- 服务商端（PROVIDER）
- 社区管理端（ADMIN）

系统围绕“服务发布—预约执行—健康监测—应急处置—评价投诉”构建全流程闭环。

---

## 2. 技术栈与运行环境
### 后端
- JDK 17
- Spring Boot 3.2.6
- Spring Security + JWT
- MyBatis-Plus
- MySQL 8.0
- Redis 7
- WebSocket (STOMP)

### 前端
- Node.js 20+
- Vue 3
- Element Plus
- Axios
- Vite

### 容器化
- Docker / Docker Compose（推荐）

---

## 3. 业务功能
1. 用户注册、登录与多角色权限控制（Spring Security）
2. 服务商发布服务，老人/家属预约服务
3. 健康数据上传与高风险预警（WebSocket推送）
4. 紧急呼叫与事件通知
5. 服务投诉与管理端查看
6. 基础数据沉淀，为后续多维统计分析预留接口与表结构

---

## 4. 业务流程
1. 用户注册并按角色登录。
2. 服务商发布养老服务项目。
3. 老人或家属浏览服务并提交预约。
4. 服务执行中产生流程状态追踪（`full_trace`）。
5. 老人上报健康指标，异常时系统推送预警。
6. 发生突发情况可发起应急呼叫，管理端实时接收。
7. 服务完成后可提交评价/投诉，管理端跟踪处置。

---

## 5. 项目结构
```text
.
├── backend/                      # SpringBoot后端
│   ├── src/main/java/com/tjw/eldercare
│   │   ├── config               # 安全与WebSocket配置
│   │   ├── controller           # API控制器
│   │   ├── entity/mapper        # MyBatis-Plus实体与Mapper
│   │   ├── service              # 业务服务
│   │   └── security             # JWT过滤与令牌组件
│   └── src/main/resources
│       ├── application.yml
│       ├── schema.sql
│       └── data.sql
├── frontend/                     # Vue前端
├── docker-compose.yml
├── README.md
└── Open.md
```

---

## 6. 快速启动

### 方式A：Docker Compose（一键启动，推荐）
```bash
docker compose up -d
```

访问：
- 前端：http://localhost:5173
- 后端：http://localhost:8080
- MySQL：localhost:3306
- Redis：localhost:6379

### 方式B：本地开发启动
#### 1）启动MySQL与Redis
- 创建数据库：`eldercare`
- 执行：`backend/src/main/resources/schema.sql`
- 执行：`backend/src/main/resources/data.sql`

#### 2）启动后端
```bash
cd backend
mvn spring-boot:run
```

#### 3）启动前端
```bash
cd frontend
npm install
npm run dev
```

---

## 7. 默认演示账号（密码均为 `123456`）
- 老年用户：`demo_elder`
- 家属：`demo_family`
- 服务商：`demo_provider`
- 管理员：`demo_admin`

---

## 8. 关键问题应对说明
1. **适老化界面与统一布局**：前端统一使用 Element Plus 设计规范，采用高对比色、简化操作路径。
2. **JDBC驱动与数据库连接**：后端锁定 `mysql-connector-j`，并在 `application.yml` 中配置 `com.mysql.cj.jdbc.Driver`。
3. **多角色多状态数据一致性**：核心业务表按流程拆分，预约/投诉等状态字段标准化，便于事务扩展。
4. **系统安全性**：JWT鉴权 + Spring Security接口保护，密码BCrypt加密，敏感业务接口按角色授权。

---

## 9. 后续扩展建议
- 接入地图定位API（应急定位、服务范围规划）
- 接入短信网关（告警/预约提醒）
- 增加可视化统计大屏（按社区、服务类型、风险等级分布）
- 引入任务调度与消息队列提高高并发稳定性
