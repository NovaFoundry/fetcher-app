from fastapi import FastAPI
from api import tiktok_user
from core.config import settings
from core.redis_client import redis_client
from core.avd_manager import AVDManager

app = FastAPI()

# 注册tiktok相关路由
app.include_router(tiktok_user.router)

@app.on_event("startup")
async def startup_event():
    """
    应用启动时的初始化操作：
    1. 初始化Redis连接
    2. 加载AVD设备账号配置到Redis
    """
    # 初始化Redis连接
    r = redis_client.get_client()
    # 加载AVD设备账号配置到Redis
    avd_mgr = AVDManager(r)
    avd_mgr.load_config()  # 该方法需实现：将settings.avd_devices写入Redis，设置冷却等
    print("[Startup] AVD设备账号配置已加载到Redis")

    # TODO: 调用核心初始化逻辑
    pass 