import redis
from app.core.config import settings
import time

# 设备-账号映射管理
class AVDManager:
    def __init__(self, redis_client):
        self.redis = redis_client

    def load_config(self):
        """
        从配置文件加载设备-账号映射，写入Redis。
        每台设备写入：账号、密码、状态（空闲）、冷却到期时间（0）等。
        """
        avd_prefix = settings.avd_prefix
        cooldown = int(settings.cooldown_seconds)
        for dev in settings.avd_devices:
            avd_ip = dev['avd_ip']
            key = f"{avd_prefix}{avd_ip}"
            value = {
                'account': dev['account'],
                'password': dev.get('password', ''),
                'status': 'idle',  # idle/busy/cooldown
                'cooldown_until': 0,  # 时间戳，0表示可用
            }
            self.redis.hmset(key, value)
        # 可选：记录所有设备列表
        self.redis.sadd(f"{avd_prefix}all", *[dev['avd_ip'] for dev in settings.avd_devices])

    def allocate_avd(self):
        """
        分配空闲的AVD+账号对。
        1. 遍历所有设备，查找status为idle且cooldown_until<=当前时间的设备。
        2. 分配后将status设为busy。
        3. 返回设备信息（含账号、密码、IP）。
        """
        avd_prefix = settings.avd_prefix
        now = int(time.time())
        avd_ips = self.redis.smembers(f"{avd_prefix}all")
        for avd_ip in avd_ips:
            avd_ip = avd_ip.decode() if isinstance(avd_ip, bytes) else avd_ip
            key = f"{avd_prefix}{avd_ip}"
            info = self.redis.hgetall(key)
            status = info.get(b'status', b'').decode()
            cooldown_until = int(info.get(b'cooldown_until', b'0'))
            if status == 'idle' and cooldown_until <= now:
                # 分配该设备
                self.redis.hset(key, 'status', 'busy')
                return {
                    'avd_ip': avd_ip,
                    'account': info.get(b'account', b'').decode(),
                    'password': info.get(b'password', b'').decode(),
                }
        return None  # 没有可用设备

    def release_avd(self, avd_ip):
        """
        释放AVD设备，设置冷却时间。
        1. 将status设为cooldown
        2. 设置cooldown_until为当前时间+冷却秒数
        """
        avd_prefix = settings.avd_prefix
        cooldown = int(settings.cooldown_seconds)
        key = f"{avd_prefix}{avd_ip}"
        cooldown_until = int(time.time()) + cooldown
        self.redis.hmset(key, {'status': 'cooldown', 'cooldown_until': cooldown_until})