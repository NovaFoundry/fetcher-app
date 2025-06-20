#!/bin/bash

#
# mitmproxy-control.sh
#
# 用途: 控制mitmproxy的运行，支持多种模式
# 配置文件: config.yaml
#

# 配置文件路径
CONFIG_FILE="${HOME}/.mitmproxy/config.yaml"
PID_FILE="$(dirname "$0")/.mitmproxy.pid"

# 颜色定义
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
NC="\033[0m" # 无颜色

# 打印带颜色的消息
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# 打印分隔线
print_separator() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# 检查配置文件是否存在
check_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        print_message "$RED" "❌ 错误: 配置文件 $CONFIG_FILE 不存在"
        exit 1
    fi
}

# 从配置文件中读取值
get_config_value() {
    local key=$1
    local value
    
    # 使用yq工具读取yaml文件，如果没有安装则提示安装
    if command -v yq &> /dev/null; then
        value=$(yq eval ".$key" "$CONFIG_FILE")
    else
        # 使用grep和sed作为备选方案
        value=$(grep "^$key:" "$CONFIG_FILE" | sed "s/^$key:[[:space:]]*//")
        
        # 如果没有找到值，提示安装yq
        if [ -z "$value" ]; then
            print_message "$YELLOW" "⚠️  警告: 无法读取配置值 '$key'。建议安装yq工具以更好地解析YAML:"
            print_message "$YELLOW" "   brew install yq"
            return 1
        fi
    fi
    
    echo "$value"
    return 0
}

# 检查mitmproxy是否已安装
check_mitmproxy() {
    if ! command -v mitmproxy &> /dev/null && ! command -v mitmweb &> /dev/null; then
        print_message "$RED" "❌ 错误: mitmproxy 未安装"
        print_message "$YELLOW" "📥 安装步骤:"
        print_message "$YELLOW" "   pip install mitmproxy"
        exit 1
    fi
}

# 检查进程是否在运行
is_running() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null; then
            return 0 # 进程正在运行
        fi
    fi
    return 1 # 进程未运行
}

# 启动mitmproxy
start_mitmproxy() {
    local mode=$1
    local web_port=$(get_config_value "web_port")
    local listen_port=$(get_config_value "listen_port")
    local upstream_mode=$(get_config_value "mode[0]" | sed 's/"//g')
    local allow_hosts=$(get_config_value "allow_hosts[0]" | sed 's/"//g')
    
    # 如果已经在运行，则退出
    if is_running; then
        print_message "$YELLOW" "⚠️  mitmproxy 已经在运行中 (PID: $(cat "$PID_FILE"))"
        return 1
    fi
    
    # 根据模式启动不同的命令
    case "$mode" in
        web)
            print_message "$GREEN" "🚀 启动 mitmweb..."
            print_message "$BLUE" "   Web界面端口: $web_port"
            print_message "$BLUE" "   监听端口: $listen_port"
            print_message "$BLUE" "   模式: $upstream_mode"
            print_message "$BLUE" "   允许主机: $allow_hosts"
            
            # 启动mitmweb
            nohup mitmweb --web-port "$web_port" \
                         --listen-port "$listen_port" \
                         --mode "$upstream_mode" \
                         --allow-hosts "$allow_hosts" \
                         -s "$(dirname "$0")/tiktok_handler.py" \
                         >> "$(dirname "$0")/mitmproxy.log" 2>&1 &
            
            echo $! > "$PID_FILE"
            print_message "$GREEN" "✅ mitmweb 已启动 (PID: $!)"
            print_message "$GREEN" "📊 Web界面: http://localhost:$web_port/"
            ;;
            
        console)
            print_message "$GREEN" "🚀 启动 mitmproxy 控制台模式..."
            print_message "$BLUE" "   监听端口: $listen_port"
            print_message "$BLUE" "   模式: $upstream_mode"
            print_message "$BLUE" "   允许主机: $allow_hosts"
            
            # 启动mitmproxy控制台
            mitmproxy --listen-port "$listen_port" \
                     --mode "$upstream_mode" \
                     --allow-hosts "$allow_hosts" \
                     -s "$(dirname "$0")/tiktok_handler.py"
            ;;
            
        dump)
            print_message "$GREEN" "🚀 启动 mitmdump..."
            print_message "$BLUE" "   监听端口: $listen_port"
            print_message "$BLUE" "   模式: $upstream_mode"
            print_message "$BLUE" "   允许主机: $allow_hosts"
            
            # 启动mitmdump
            nohup mitmdump --listen-port "$listen_port" \
                         --mode "$upstream_mode" \
                         --allow-hosts "$allow_hosts" \
                         -s "$(dirname "$0")/tiktok_handler.py" \
                         >> "$(dirname "$0")/mitmproxy.log" 2>&1 &
            
            echo $! > "$PID_FILE"
            print_message "$GREEN" "✅ mitmdump 已启动 (PID: $!)"
            ;;
            
        *)
            print_message "$RED" "❌ 错误: 未知模式 '$mode'"
            print_usage
            exit 1
            ;;
    esac
}

# 停止mitmproxy
stop_mitmproxy() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null; then
            print_message "$YELLOW" "🛑 停止 mitmproxy (PID: $pid)..."
            kill "$pid"
            rm "$PID_FILE"
            print_message "$GREEN" "✅ mitmproxy 已停止"
        else
            print_message "$YELLOW" "⚠️  mitmproxy 未在运行，但PID文件存在"
            rm "$PID_FILE"
        fi
    else
        print_message "$YELLOW" "⚠️  mitmproxy 未在运行"
    fi
}

# 检查mitmproxy状态
check_status() {
    if is_running; then
        local pid=$(cat "$PID_FILE")
        print_message "$GREEN" "✅ mitmproxy 正在运行 (PID: $pid)"
        
        # 显示配置信息
        local web_port=$(get_config_value "web_port")
        local listen_port=$(get_config_value "listen_port")
        local upstream_mode=$(get_config_value "mode[0]" | sed 's/"//g')
        
        print_message "$BLUE" "   Web界面端口: $web_port"
        print_message "$BLUE" "   监听端口: $listen_port"
        print_message "$BLUE" "   模式: $upstream_mode"
        
        # 检查是否是web模式
        if ps -p "$pid" -o command= | grep -q "mitmweb"; then
            print_message "$GREEN" "📊 Web界面: http://localhost:$web_port/"
        fi
    else
        print_message "$YELLOW" "⚠️  mitmproxy 未在运行"
    fi
}

# 安装证书到Android设备
install_certificate() {
    local cert_script="$(dirname "$0")/install_certificate_android_emulator-mitmproxy-mac.sh"
    local listen_port=$(get_config_value "listen_port")
    
    if [ ! -f "$cert_script" ]; then
        print_message "$RED" "❌ 错误: 证书安装脚本不存在: $cert_script"
        exit 1
    fi
    
    # 自动检测合适的IP地址
    local host_ip="127.0.0.1"
    
    # 检查是否在Docker环境中运行
    if [ -f "/.dockerenv" ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
        print_message "$YELLOW" "⚠️ 检测到Docker环境，尝试获取宿主机IP..."
        
        # 尝试使用host.docker.internal (适用于Docker Desktop for Mac/Windows)
        if ping -c 1 host.docker.internal &>/dev/null; then
            host_ip=$(getent hosts host.docker.internal | awk '{ print $1 }')
            print_message "$GREEN" "✅ 使用Docker宿主机IP: $host_ip (host.docker.internal)"
        else
            # 尝试获取默认网关IP (通常是Docker网桥上的宿主机IP)
            local gateway_ip=$(ip route | grep default | awk '{print $3}')
            if [ -n "$gateway_ip" ]; then
                host_ip="$gateway_ip"
                print_message "$GREEN" "✅ 使用Docker网关IP: $host_ip"
            else
                # 尝试获取非本地IP
                local detected_ip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -n 1)
                if [ -n "$detected_ip" ]; then
                    host_ip="$detected_ip"
                    print_message "$GREEN" "✅ 使用检测到的IP: $host_ip"
                else
                    print_message "$YELLOW" "⚠️ 无法自动检测宿主机IP，使用默认IP: $host_ip"
                    print_message "$YELLOW" "  如果连接失败，请手动指定正确的宿主机IP"
                fi
            fi
        fi
    else
        # 非Docker环境，尝试获取本机非回环IP
        print_message "$GREEN" "🔒 安装mitmproxy证书到Android设备..."
        print_message "$YELLOW" "⚠️ 尝试获取本机非回环IP..."
        
        # 尝试获取非本地IP
        local detected_ip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -n 1)
        if [ -n "$detected_ip" ]; then
            host_ip="$detected_ip"
            print_message "$GREEN" "✅ 使用检测到的IP: $host_ip"
        else
            print_message "$YELLOW" "⚠️ 无法自动检测本机IP，使用默认IP: $host_ip"
            print_message "$YELLOW" "  如果连接失败，请手动指定正确的IP"
        fi
    fi
    
    print_message "$GREEN" "🔒 使用IP: $host_ip 安装mitmproxy证书到Android设备..."
    bash "$cert_script" -m all -i "$host_ip" -p "$listen_port"
}

# 移除Android设备上的代理设置
remove_proxy() {
    local cert_script="$(dirname "$0")/install_certificate_android_emulator-mitmproxy-mac.sh"
    
    if [ ! -f "$cert_script" ]; then
        print_message "$RED" "❌ 错误: 证书安装脚本不存在: $cert_script"
        exit 1
    fi
    
    print_message "$GREEN" "🔄 移除Android设备上的代理设置..."
    bash "$cert_script" -m revertProxy
}

# 重启mitmproxy
restart_mitmproxy() {
    local mode=$1
    
    # 获取当前运行模式（如果正在运行）
    local current_mode=""
    if is_running; then
        local pid=$(cat "$PID_FILE")
        if ps -p "$pid" -o command= | grep -q "mitmweb"; then
            current_mode="web"
        elif ps -p "$pid" -o command= | grep -q "mitmdump"; then
            current_mode="dump"
        else
            current_mode="console"
        fi
    fi
    
    # 如果没有指定模式，则使用当前模式（如果正在运行）
    if [ -z "$mode" ] && [ -n "$current_mode" ]; then
        mode="$current_mode"
        print_message "$BLUE" "使用当前模式重启: $mode"
    elif [ -z "$mode" ]; then
        # 如果没有指定模式且当前未运行，则默认使用web模式
        mode="web"
        print_message "$BLUE" "使用默认模式重启: $mode"
    fi
    
    # 停止当前运行的mitmproxy
    stop_mitmproxy
    
    # 启动mitmproxy
    print_message "$GREEN" "🔄 重启 mitmproxy..."
    start_mitmproxy "$mode"
}

# 显示使用帮助
print_usage() {
    echo "用法: $0 <命令> [选项]"
    echo ""
    echo "命令:"
    echo "  start <模式>    启动mitmproxy (模式: web, console, dump)"
    echo "  stop            停止mitmproxy"
    echo "  restart <模式>  重启mitmproxy (可选指定模式，默认使用当前模式)"
    echo "  status          检查mitmproxy状态"
    echo "  cert            安装mitmproxy证书到Android设备"
    echo "  revert          移除Android设备上的代理设置"
    echo "  help            显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 start web     以Web界面模式启动mitmproxy"
    echo "  $0 start console 以控制台模式启动mitmproxy"
    echo "  $0 start dump    以dump模式启动mitmproxy"
    echo "  $0 restart       使用当前模式重启mitmproxy"
    echo "  $0 restart web   以Web界面模式重启mitmproxy"
    echo "  $0 stop          停止mitmproxy"
    echo "  $0 status        检查mitmproxy状态"
    echo "  $0 cert          安装证书到Android设备"
    echo "  $0 revert        移除Android设备上的代理设置"
}

# 主函数
main() {
    # 检查命令行参数
    if [ $# -lt 1 ]; then
        print_usage
        exit 1
    fi
    
    # 解析命令
    local command=$1
    shift
    
    # 显示标题
    print_separator
    print_message "$GREEN" "🔄 mitmproxy 控制脚本"
    print_separator
    
    # 检查配置文件
    check_config
    
    # 根据命令执行相应操作
    case "$command" in
        start)
            if [ $# -lt 1 ]; then
                print_message "$RED" "❌ 错误: 缺少模式参数"
                print_usage
                exit 1
            fi
            check_mitmproxy
            start_mitmproxy "$1"
            ;;
        stop)
            stop_mitmproxy
            ;;
        restart)
            check_mitmproxy
            restart_mitmproxy "$1"
            ;;
        status)
            check_status
            ;;
        cert)
            install_certificate
            ;;
        revert)
            remove_proxy
            ;;
        help)
            print_usage
            ;;
        *)
            print_message "$RED" "❌ 错误: 未知命令 '$command'"
            print_usage
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"