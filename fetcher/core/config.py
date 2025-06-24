import os
import yaml
from pathlib import Path

class Settings:
    """
    全局配置加载类，支持从YAML文件加载所有配置（celery、redis、avd等）
    """
    def __init__(self, config_path=None):
        if config_path is None:
            config_path = Path(__file__).parent / "../config/config.yaml"
        with open(config_path, 'r', encoding='utf-8') as f:
            self._cfg = yaml.safe_load(f)
        # Celery配置
        self.celery = self._cfg.get('celery', {})
        # Redis业务配置
        self.redis = self._cfg.get('redis', {})
        # AVD设备与账号映射
        self.avd_devices = self._cfg.get('avd_devices', [])
        # 设备冷却时间
        self.cooldown_seconds = self._cfg.get('cooldown_seconds', 600)

    @property
    def celery_config(self):
        """
        获取Celery相关配置
        """
        return self.celery

    @property
    def redis_config(self):
        """
        获取业务Redis相关配置
        """
        return self.redis

    def get_redis_url(self):
        """
        获取业务Redis连接URL
        """
        host = self.redis.get('host', 'localhost')
        port = self.redis.get('port', 6379)
        db = self.redis.get('db', 2)
        password = self.redis.get('password', '')
        if password:
            return f"redis://:{password}@{host}:{port}/{db}"
        else:
            return f"redis://{host}:{port}/{db}"

    @property
    def stream_prefix(self):
        return self.redis.get('stream_prefix', 'tiktok:stream:')

    @property
    def task_status_prefix(self):
        return self.redis.get('task_status_prefix', 'tiktok:task:')

    @property
    def idempotency_prefix(self):
        return self.redis.get('idempotency_prefix', 'tiktok:idemp:')

    @property
    def avd_prefix(self):
        return self.redis.get('avd_prefix', 'tiktok:avd:')

settings = Settings() 