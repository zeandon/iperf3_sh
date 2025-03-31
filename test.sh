      
#!/bin/bash


# ===================== 全局配置 =====================
REMOTE_SERVER="root@192.168.1.1"             # OpenWRT路由器地址
LOCAL_SERVER_IPS=("192.168.1.108" "192.168.1.101" "192.168.1.156")  # 本地服务端绑定IP
LOCAL_CLIENT_IPS=("192.168.1.180" "192.168.1.154" "192.168.1.102") 
LOCAL_PORTS=(5301 5302 5303)                 # 本地服务端端口（5301-5303）
REMOTE_PORTS=(5304 5305 5306)                # 远程服务端端口（5304-5306）
RUN_TIME=100
BITRATE="100M"

# ===================== 终端启动函数 =====================
launch_terminal() {
  local title="$1"
  local command="$2"
  
  if command -v gnome-terminal &> /dev/null; then
    gnome-terminal --title="$title" -- bash -c "$command; exec bash"
  elif command -v konsole &> /dev/null; then
    konsole --new-tab -p tabtitle="$title" -e bash -c "$command; exec bash"
  elif command -v xterm &> /dev/null; then
    xterm -T "$title" -e bash -c "$command; exec bash"
  else
    echo "错误：未找到支持的终端模拟器"
    exit 1
  fi
}

# ===================== 核心功能 =====================

# 启动所有测试服务
start_all_tests() {
  # 本地服务端（绑定指定IP）
  for i in "${!LOCAL_PORTS[@]}"; do
    launch_terminal "Local Server ${LOCAL_PORTS[i]}" \
      "iperf3 -s -p ${LOCAL_PORTS[i]} -B ${LOCAL_SERVER_IPS[i]}"
  done

  # 远程服务端（OpenWRT）
  for i in "${!REMOTE_PORTS[@]}"; do
    launch_terminal "Remote Server ${REMOTE_PORTS[i]}" \
      "ssh $REMOTE_SERVER 'iperf3 -s -p ${REMOTE_PORTS[i]}'"
  done

  # 远程客户端 -> 本地服务端
  for i in "${!LOCAL_PORTS[@]}"; do
     launch_terminal "Remote Client ${LOCAL_PORTS[i]}" \
       "ssh $REMOTE_SERVER 'iperf3 -c ${LOCAL_SERVER_IPS[i]} -u -B ${REMOTE_SERVER#*@} -b $BITRATE -p ${LOCAL_PORTS[i]} -t $RUN_TIME'"
  done

  # 本地客户端 -> 远程服务端
  for i in "${!REMOTE_PORTS[@]}"; do
  launch_terminal "Local Client ${REMOTE_PORTS[i]}" \
    "iperf3 -c ${REMOTE_SERVER#*@} -u -B ${LOCAL_CLIENT_IPS[i]} -b $BITRATE -p ${REMOTE_PORTS[i]} -t $RUN_TIME"
  done

  echo "[+] 所有测试服务已启动！"
}

# 关闭远程服务端（适配OpenWRT无pkill）
stop_remote_servers() {
  echo "正在关闭远程服务端..."
  for port in "${REMOTE_PORTS[@]}"; do
    pid=$(ssh $REMOTE_SERVER "ps | grep 'iperf3 -s -p $port' | grep -v grep | awk '{print \$1}'")
    if [ -n "$pid" ]; then
      ssh $REMOTE_SERVER "kill -9 $pid"
      echo "端口 $port (PID $pid) 已关闭"
    else
      echo "端口 $port 未找到进程"
    fi
  done
}

# ===================== 交互菜单 =====================
show_menu() {
  clear
  echo "======================================"
  echo "    iPerf3 Test"
  echo "======================================"
  echo "  1. 启动全部测试服务"
  echo "  2. 关闭远程服务端"
  echo "  3. 退出"
  echo "======================================"
  read -p "请输入选项 [1-3]: " choice

  case $choice in
    1) start_all_tests ;;
    2) stop_remote_servers ;;
    3) exit 0 ;;
    *) echo "[!] 无效输入，请重新选择"; sleep 1 ;;
  esac
  read -p "按回车返回菜单..."
}

# ===================== 主程序 =====================
while true; do
  show_menu
done

