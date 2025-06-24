import redis
from app.core.config import settings

class RedisClient:
    """
    Redis连接工具类，支持获取业务Redis实例
    """
    def __init__(self):
        self._client = None

    def get_client(self):
        """
        获取业务Redis连接实例（用于存储任务、stream等）
        """
        if self._client is None:
            self._client = redis.Redis.from_url(settings.get_redis_url())
        return self._client

    def get_custom_client(self, db=0):
        """
        获取指定db的Redis实例
        """
        url = settings.get_redis_url()
        # 替换db号
        url = url.rsplit('/', 1)[0] + f'/{db}'
        return redis.Redis.from_url(url)

redis_client = RedisClient()