#!/usr/bin/env python3

"""
TikTok响应数据处理脚本

用途：捕获特定路径的TikTok API响应并打印数据
"""

import json
from mitmproxy import http
from mitmproxy import ctx


class TikTokHandler:
    """处理TikTok的mitmproxy插件"""
    
    def __init__(self):
        self.suggestions_path = "/tiktok/user/relation/maf/list/v1"
    
    def response(self, flow: http.HTTPFlow) -> None:
        """处理HTTP响应"""
        # 检查请求路径是否匹配目标路径
        if self.suggestions_path in flow.request.pretty_url:
            ctx.log.info(f"\n{'='*50}")
            ctx.log.info(f"捕获到目标路径: {flow.request.pretty_url}")
            ctx.log.info(f"请求方法: {flow.request.method}")
            ctx.log.info(f"状态码: {flow.response.status_code}")
            ctx.log.info(f"响应头: {dict(flow.response.headers)}")
            client_ip = flow.client_conn.address[0]
            client_port = flow.client_conn.address[1]
            ctx.log.info(f"客户端信息: {client_ip}:{client_port}")


            if flow.response.status_code == 200:
                # 获取响应数据
                try:
                    response_data = flow.response.content
                    # 尝试解析为JSON
                    try:
                        json_data = json.loads(response_data)
                        ctx.log.info("解析响应数据成功")
                    except json.JSONDecodeError:
                        # 如果不是JSON格式，则打印原始数据
                        ctx.error("响应数据(非JSON格式):")
                        ctx.error.info(response_data.decode('utf-8', errors='replace'))
                except Exception as e:
                    ctx.log.error(f"处理响应时出错: {str(e)}")
            else:
                ctx.error.info(f"响应状态码: {flow.response.status_code}, 响应内容: {flow.response.content}")
            ctx.log.info(f"\n{'='*50}\n")


# 添加插件实例到mitmproxy
addons = [TikTokHandler()]