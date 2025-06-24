# Fetcher App

## 项目简介
本项目用于自动化抓取TikTok用户推荐数据，基于FastAPI、Celery、Redis、Appium、mitmproxy等技术栈，支持任务分发、数据抓取、幂等性、任务状态管理和资源清理。

## 目录结构
```
fetcher/
├── api/
├── core/
├── models/
├── tasks/
├── main.py
├── celery_app.py
└── utils.py
```

## 主要功能
- FastAPI 提供任务提交、数据推送、任务状态查询接口
- Celery 任务队列，支持分布式任务处理
- Redis 用于任务状态、幂等性、设备账号管理
- mitmproxy 实现数据实时推送
- 支持多设备多账号并发、冷却、资源清理

## 如何启动项目
1. **进入项目目录**

   ```bash
   cd fetcher-app
   ```
2. **创建并激活虚拟环境**

   ```bash
   python3 -m venv .venv
   source .venv/bin/activate
   ```
3. **安装依赖**

   ```bash
   pip install -r requirements.txt
   ```

4. **启动 FastAPI 服务**

   ```bash
   uvicorn main:app --reload
   ```
   - 默认监听 127.0.0.1:8000，可通过 `--host` 和 `--port` 参数自定义。

5. **启动 Celery Worker**

   ```bash
   celery -A celery_app worker --loglevel=info
   ```
   - `-A celery_app.celery_app` 指定 Celery 实例。
   - `--loglevel=info` 可根据需要调整日志级别。 