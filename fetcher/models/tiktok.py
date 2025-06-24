from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List

class FollowsFilter(BaseModel):
    min: int = Field(..., description="最小关注数")
    max: int = Field(..., description="最大关注数")

class SuggestionTaskRequest(BaseModel):
    task_id: str = Field(..., description="外部任务ID，由调用方生成")
    username: str = Field(..., description="tiktok用户名")
    count: int = Field(..., description="需要获取的推荐用户数量")
    follows: FollowsFilter = Field(..., description="关注数过滤条件")

class SuggestionTaskResponse(BaseModel):
    task_id: str
    status: str
    message: str

class CaptureDataRequest(BaseModel):
    avd_ip: str = Field(..., description="AVD设备IP")
    data: List[Dict[str, Any]] = Field(..., description="抓包得到的suggested用户数据列表")

class TaskStatusResponse(BaseModel):
    task_id: str
    status: str
    progress: int
    result: Optional[Any] 