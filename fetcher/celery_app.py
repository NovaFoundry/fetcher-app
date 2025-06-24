# 使用相对导入替代绝对导入
from celery import Celery
from core.config import settings

# 创建Celery实例
celery_app = Celery(
    'fetcher',
    broker=settings.celery_config.get('broker_url'),
    backend=settings.celery_config.get('result_backend')
)

# 配置Celery
celery_app.conf.update(
    task_serializer='json',
    accept_content=['json'],  # 只接受json类型的内容
    result_serializer='json',
    timezone=settings.celery_config.get("timezone"),
    enable_utc=settings.celery_config.get("enable_utc"),
    broker_connection_retry_on_startup=True,  # 添加启动时的连接重试设置
    result_expires=settings.celery_config.get("result_expires"),
)

# 自动发现任务，使用相对路径
# celery_app.autodiscover_tasks(['tasks'])