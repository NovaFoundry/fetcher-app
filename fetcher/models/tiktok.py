from pydantic import BaseModel, Field, validator
from typing import Optional, Dict, Any, List

class FollowsFilter(BaseModel):
    min: int = Field(..., description="最小关注数")
    max: int = Field(..., description="最大关注数")
    
    @validator('max')
    def max_must_be_greater_than_min(cls, v, values):
        if 'min' in values and v < values['min']:
            raise ValueError('最大值必须大于或等于最小值')
        return v

class SuggestionTaskRequest(BaseModel):
    task_id: str = Field(..., description="外部任务ID，由调用方生成")
    username: str = Field(..., description="tiktok用户名")
    count: int = Field(..., ge=1, le=100, description="需要获取的推荐用户数量")
    follows: FollowsFilter = Field(..., description="关注数过滤条件")
    
    @validator('username')
    def username_must_be_valid(cls, v):
        if not v or len(v) < 2:
            raise ValueError('用户名长度必须大于等于2')
        return v

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