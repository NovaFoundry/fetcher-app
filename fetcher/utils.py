"""
通用工具函数模块
"""

def generate_task_id() -> str:
    """
    生成唯一任务ID，可基于UUID或其他算法。
    """
    import uuid
    return uuid.uuid4().hex 