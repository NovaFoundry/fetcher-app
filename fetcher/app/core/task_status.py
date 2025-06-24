import redis

class TaskStatusManager:
    def __init__(self, redis_client):
        self.redis = redis_client

    def set_status(self, task_id: str, status: str, progress: int = 0, result=None):
        """
        设置任务状态、进度和结果。
        """
        # TODO: 状态写入Redis
        pass

    def get_status(self, task_id: str):
        """
        获取任务状态。
        """
        # TODO: 查询Redis
        pass 