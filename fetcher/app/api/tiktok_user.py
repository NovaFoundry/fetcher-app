from fastapi import APIRouter, Header, HTTPException, Depends, status
from app.celery_app import celery_app
from app.models.tiktok import SuggestionTaskRequest, CaptureDataRequest, TaskStatusResponse, SuggestionTaskResponse
from typing import Optional
from app.core.redis_client import redis_client
from app.core.idempotency import IdempotencyManager
from app.core.task_status import TaskStatusManager
from app.utils import generate_task_id

router = APIRouter()

# 依赖注入函数，获取Redis客户端和管理器实例
def get_redis():
    return redis_client.get_client()

def get_idempotency_manager():
    return IdempotencyManager(get_redis())

def get_task_status_manager():
    return TaskStatusManager(get_redis())

@router.post("/tiktok/user/suggestions", response_model=SuggestionTaskResponse)
def create_suggestion_task(
    body: SuggestionTaskRequest,
    idempotency_key: Optional[str] = Header(None, alias="Idempotency-Key"),
    idempotency_manager: IdempotencyManager = Depends(get_idempotency_manager),
    task_status_manager: TaskStatusManager = Depends(get_task_status_manager)
):
    """
    创建TikTok用户推荐任务，支持幂等性。
    
    ## 接口说明
    该接口用于创建一个新的TikTok用户推荐获取任务。系统将启动一个异步任务，
    通过模拟器打开TikTok应用，搜索指定用户并获取其推荐的用户列表。
    
    ## 请求参数
    - **body**: 请求体，包含任务相关参数
      - **task_id**: 外部任务ID，由调用方生成，用于幂等性控制
      - **username**: 要查询的TikTok用户名
      - **count**: 需要获取的推荐用户数量
      - **follows**: 关注数过滤条件
        - **min**: 最小关注数
        - **max**: 最大关注数
    - **Idempotency-Key**: 幂等性键，用于防止重复提交
    
    ## 请求示例
    ```json
    {
      "task_id": "1f35cebd29cf15ef6a7c453cdaffcddb",
      "username": "deedydas",
      "count": 20,
      "follows": {
        "min": 100,
        "max": 1000
      }
    }
    ```
    
    ## 响应示例
    ```json
    {
      "task_id": "1f35cebd29cf15ef6a7c453cdaffcddb",
      "status": "pending",
      "message": "任务已创建"
    }
    ```
    """
    # 参数校验
    if body.follows.min > body.follows.max:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="关注数过滤条件无效：最小值不能大于最大值"
        )
    
    if body.count <= 0 or body.count > 100:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="请求数量无效：必须在1-100之间"
        )
    
    if not body.username or len(body.username) < 2:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="用户名无效：长度必须大于等于2"
        )
    
    # 处理幂等性
    task_id = body.task_id
    
    # 如果提供了Idempotency-Key，检查是否已存在相同请求
    if idempotency_key:
        # 检查是否已存在相同的幂等性键
        if idempotency_manager.check_and_set(idempotency_key, task_id):
            # 新请求，继续处理
            pass
        else:
            # 已存在的请求，获取当前状态并返回
            status_info = task_status_manager.get_status(task_id)
            if status_info:
                return SuggestionTaskResponse(
                    task_id=task_id,
                    status=status_info.get("status", "pending"),
                    message="任务已存在"
                )

    # 设置初始任务状态
    task_status_manager.set_status(task_id, "pending", 0)
    
    # 分发Celery任务
    celery_app.send_task(
        "tasks.tiktok.process_suggestions",
        args=(task_id, body.username, body.count, body.follows.model_dump()),
        kwargs={}
    )
    
    return SuggestionTaskResponse(task_id=task_id, status="pending", message="任务已创建")

@router.post("/tiktok/user/data/capture")
def capture_user_data(
    body: CaptureDataRequest
):
    """
    接收mitmproxy推送的TikTok用户主页suggested列表数据。
    
    ## 接口说明
    该接口用于接收由mitmproxy捕获的TikTok应用中用户推荐列表数据。
    数据将被写入Redis Stream并通知相应的Celery任务进行处理。
    此接口主要供内部系统使用，不对外开放。
    
    ## 请求参数
    - **body**: 请求体
      - **avd_ip**: AVD设备IP，用于标识数据来源
      - **data**: 抓包得到的suggested用户数据列表
    
    ## 请求示例
    ```json
    {
      "avd_ip": "10.0.2.15",
      "data": [
        {
          "user_id": "12345678",
          "username": "example_user",
          "display_name": "Example User",
          "follower_count": 5000,
          "following_count": 500,
          "bio": "This is an example bio"
        }
      ]
    }
    ```
    
    ## 响应示例
    ```json
    {
      "status": "ok"
    }
    ```
    """
    # TODO: 数据写入Redis Stream，通知Celery任务
    return {"status": "ok"}

@router.get("/tiktok/user/suggestions/{task_id}", response_model=TaskStatusResponse)
def get_task_status(
    task_id: str,
    task_status_manager: TaskStatusManager = Depends(get_task_status_manager)
):
    """
    查询任务状态。
    
    ## 接口说明
    该接口用于查询指定任务ID的TikTok用户推荐获取任务的执行状态和进度。
    
    ## 路径参数
    - **task_id**: 任务ID，与创建任务时提供的task_id一致
    
    ## 响应参数
    - **task_id**: 任务ID
    - **status**: 任务状态，可能的值包括：
      - pending: 等待执行
      - running: 正在执行
      - completed: 已完成
      - failed: 执行失败
    - **progress**: 任务进度，0-100的整数
    - **result**: 任务结果，仅在status为completed时有值
    
    ## 响应示例
    ```json
    {
      "task_id": "1f35cebd29cf15ef6a7c453cdaffcddb",
      "status": "running",
      "progress": 50,
      "result": null
    }
    ```
    
    完成后的响应示例：
    ```json
    {
      "task_id": "1f35cebd29cf15ef6a7c453cdaffcddb",
      "status": "completed",
      "progress": 100,
      "result": [
        {
          "user_id": "12345678",
          "username": "example_user",
          "display_name": "Example User",
          "follower_count": 5000,
          "following_count": 500,
          "bio": "This is an example bio"
        }
      ]
    }
    ```
    """
    # 查询Redis任务状态
    status_info = task_status_manager.get_status(task_id)
    if not status_info:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"任务 {task_id} 不存在"
        )
    
    return TaskStatusResponse(
        task_id=task_id,
        status=status_info.get("status", "pending"),
        progress=status_info.get("progress", 0),
        result=status_info.get("result")
    )