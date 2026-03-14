# 社区智慧养老服务平台（SpringBoot + Vue）

## 1. 项目简介
本项目是一个基于 `Spring Boot + Vue + MySQL + Redis` 的社区智慧养老服务平台，采用前后端分离架构，覆盖以下角色：

- 老年用户端（`ELDER`）
- 家属端（`FAMILY`）
- 服务商端（`PROVIDER`）
- 社区管理端（`ADMIN`）

系统围绕“服务发布 -> 预约执行 -> 健康监测 -> 应急处置 -> 评价投诉”构建完整业务闭环。

---

## 2. 技术栈与运行环境

### 后端
- JDK 17
- Spring Boot 3.2.6
- Spring Security + JWT
- MyBatis-Plus
- MySQL 8.0
- Redis 7
- WebSocket（STOMP）

### 前端
- Node.js 20+
- Vue 3
- Element Plus
- Axios
- Vite

### 容器化
- Docker
- Docker Compose

---

## 3. 项目结构

```text
.
├── backend/                      # Spring Boot 后端
│   ├── src/main/java/com/tjw/eldercare
│   │   ├── config               # 安全与 WebSocket 配置
│   │   ├── controller           # API 控制器
│   │   ├── entity / mapper      # 实体与 MyBatis-Plus Mapper
│   │   ├── service              # 业务服务
│   │   └── security             # JWT 过滤器与令牌组件
│   └── src/main/resources
│       ├── application.yml
│       ├── schema.sql
│       └── data.sql
├── frontend/                     # Vue 前端
│   └── scripts/docker-dev-entrypoint.sh
├── docker-compose.yml
├── start-docker.sh               # Docker 一键启动脚本
├── start-local.sh                # 本地开发辅助启动脚本
├── stop-project.sh               # 停止项目相关容器与本地进程
├── README.md
└── Open.md
```

---

## 4. 先关闭项目相关端口

无论你之前是用 Docker 启动，还是本地跑过前后端，都建议先执行一次：

```bash
./stop-project.sh
```

这个脚本会：

- 停掉本项目的 Docker 容器
- 结束本项目残留的本地后端 / 前端进程
- 释放项目常用的 `5173`、`8080`、`8081`、`3307`、`6380` 等端口

说明：

- 它不会停掉你机器里常驻的系统 MySQL / Redis 服务
- 如果你本机一直有 `3306` / `6379` 被系统服务占用，这是正常现象

---

## 5. 启动方案一：Docker + 脚本一键启动（推荐）

这是最省心的一套方案。前端、后端、MySQL、Redis 都会自动启动，不需要你自己手动开服务。

### 启动命令

```bash
./start-docker.sh
```

脚本会自动完成：

- MySQL 初始化并导入 `schema.sql`、`data.sql`
- Redis 启动并通过健康检查
- 后端下载 Maven 依赖并执行 `mvn spring-boot:run`
- 前端首次执行 `npm ci`，随后启动 Vite 开发服务器
- 自动检测宿主机端口是否被占用，并在必要时改用备用端口：
  - 前端：`5173 -> 5174`
  - 后端：`8080 -> 8081`
  - MySQL：`3306 -> 3307`
  - Redis：`6379 -> 6380`

脚本执行完成后会直接打印本次实际使用的端口。

### 常用命令

```bash
# 启动
./start-docker.sh

# 停止
./stop-project.sh

# 查看 Docker 服务状态
docker compose --env-file .docker-runtime.env ps

# 查看日志
docker compose --env-file .docker-runtime.env logs -f
docker compose --env-file .docker-runtime.env logs -f backend
```

### Docker 启动实现说明

当前 Docker 方案是“开发式容器”：

- 后端容器通过环境变量连接 `mysql`、`redis` 服务
- 前端容器通过 `VITE_API_PROXY_TARGET=http://backend:8080` 代理 `/api` 和 `/ws`
- MySQL、Redis 使用健康检查，后端会等待它们就绪后再启动
- Maven 本地仓库和前端 `node_modules` 使用 Docker 卷缓存，避免每次重新下载
- 启动脚本会把运行时端口写入根目录的 `.docker-runtime.env`

固定使用到的环境变量如下：

- `SPRING_DATASOURCE_URL`
- `SPRING_DATASOURCE_USERNAME`
- `SPRING_DATASOURCE_PASSWORD`
- `SPRING_DATA_REDIS_HOST`
- `SPRING_DATA_REDIS_PORT`
- `VITE_API_PROXY_TARGET`
- `FRONTEND_PORT`
- `BACKEND_PORT`
- `MYSQL_PORT`
- `REDIS_PORT`

---

## 6. 启动方案二：本地手动启动前后端

这套方案适合你自己在终端里分别启动前端和后端。

### 1）先准备数据库和 Redis

- 本地已经安装并启动 MySQL / Redis；或者
- 你先用 Docker 方案启动整套环境，再停掉前后端，只保留数据库和 Redis 也可以

### 2）启动后端

```bash
cd backend
mvn spring-boot:run
```

如果本机 MySQL 账号不是默认的 `root / root1234`，请先设置环境变量：

```bash
export SPRING_DATASOURCE_URL='jdbc:mysql://localhost:3306/eldercare?useUnicode=true&characterEncoding=utf-8&serverTimezone=Asia/Shanghai'
export SPRING_DATASOURCE_USERNAME='你的 MySQL 用户名'
export SPRING_DATASOURCE_PASSWORD='你的 MySQL 密码'
export SPRING_DATA_REDIS_HOST='localhost'
export SPRING_DATA_REDIS_PORT='6379'
mvn spring-boot:run
```

如果 `8080` 已被占用，可改用其他端口：

```bash
SERVER_PORT=8081 mvn spring-boot:run
```

### 3）启动前端

```bash
cd frontend
npm install
npm run dev
```

如果后端不是 `8080`，启动前端前请设置代理目标：

```bash
cd frontend
export VITE_API_PROXY_TARGET='http://localhost:8081'
npm install
npm run dev
```

如果 `5173` 被占用，也可以改前端端口：

```bash
cd frontend
export VITE_DEV_PORT='5174'
npm run dev
```

### 4）可选：使用本地辅助脚本

如果你不想每次手动 export 环境变量，也可以用辅助脚本：

```bash
./start-local.sh
```

它会自动：

- 检测 `8080` / `5173` 是否被占用
- 自动切到 `8081` / `5174`
- 自动设置 `VITE_API_PROXY_TARGET`
- 首次安装前端依赖
- 在 `.logs/backend.log`、`.logs/frontend.log` 输出日志

本地直接开发时常见地址：

- 后端：http://localhost:8080
- 后端备用：http://localhost:8081
- MySQL：localhost:3306
- Redis：localhost:6379
- 前端：http://localhost:5173
- 前端备用：http://localhost:5174

---

## 7. 默认演示账号

默认密码均为 `123456`：

- 老年用户：`demo_elder`
- 家属：`demo_family`
- 服务商：`demo_provider`
- 管理员：`demo_admin`

---

## 8. 业务功能

1. 用户注册、登录与多角色权限控制
2. 服务商发布服务，老人/家属预约服务
3. 健康数据上传与高风险预警
4. 紧急呼叫与事件通知
5. 服务投诉与管理端查看
6. 业务数据沉淀，为后续统计分析预留接口与表结构

---

## 9. 关键说明

1. JDBC 驱动使用 `mysql-connector-j`，数据库驱动类为 `com.mysql.cj.jdbc.Driver`
2. 鉴权采用 `JWT + Spring Security`
3. WebSocket 端点为 `/ws`
4. 前端 API 基础路径为 `/api`

---

## 10. 后续扩展建议

- 接入地图定位 API（应急定位、服务范围规划）
- 接入短信网关（告警、预约提醒）
- 增加可视化统计大屏
- 引入任务调度与消息队列提升高并发稳定性
