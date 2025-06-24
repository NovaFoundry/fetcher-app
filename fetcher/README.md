# Fetcher App

## 项目简介
本项目用于自动化抓取TikTok用户推荐数据，基于FastAPI、Celery、Redis、Appium、mitmproxy等技术栈，支持任务分发、数据抓取、幂等性、任务状态管理和资源清理。

## 目录结构
```
fetcher-app/
├── fetcher/
│   ├── api/
│   ├── core/
│   ├── models/
│   ├── tasks/
│   ├── main.py
│   ├── celery_app.py
│   └── utils.py
├── mitmproxy/
├── requirements.txt
├── README.md
└── .env
```

## 主要功能
- FastAPI 提供任务提交、数据推送、任务状态查询接口
- Celery 任务队列，支持分布式任务处理
- Redis 用于任务状态、幂等性、设备账号管理
- mitmproxy 实现数据实时推送
- 支持多设备多账号并发、冷却、资源清理

## 如何启动项目

1. **安装依赖**

   ```bash
   pip install -r requirements.txt
   ```

2. **启动 FastAPI 服务**

   ```bash
   uvicorn main:app --reload
   ```
   - 默认监听 127.0.0.1:8000，可通过 `--host` 和 `--port` 参数自定义。

3. **启动 Celery Worker**

   ```bash
   celery -A celery_app.celery_app worker --loglevel=info
   ```
   - `-A celery_app.celery_app` 指定 Celery 实例。
   - `--loglevel=info` 可根据需要调整日志级别。

4. **启动 mitmproxy 并加载脚本**

   假设你已写好 `mitmproxy/tiktok_capture.py`，可用如下命令启动：

   ```bash
   mitmdump -s mitmproxy/tiktok_capture.py
   ```
   - 你可以根据实际需求传递参数或修改脚本。

5. **检查 Redis 服务**

   确保你的 Redis 服务已启动，并且配置文件中的端口、db号等与实际一致。

6. **访问接口**

   - 任务提交接口：`POST /tiktok/user/suggestions`
   - 数据推送接口：`POST /tiktok/user/data/capture`
   - 任务状态查询接口：`GET /tiktok/user/suggestions/{task_id}`

   可用 Postman、curl 或前端页面进行调试。

7. **其他说明**

   - 配置文件统一在 `fetcher/config/config.yaml`，如需调整端口、db号、账号等，直接修改此文件即可。
   - 日志、异常、任务状态等可在终端和 Redis 中查看。

如需一键启动脚本、Docker 支持或遇到任何启动问题，欢迎随时提问！

## 环境变量
参考.env文件配置Redis等参数。 