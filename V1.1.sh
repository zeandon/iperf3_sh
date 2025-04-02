#!/bin/bash

# ===================== 全局配置 =====================
REMOTE_SERVER="root@192.168.1.1"                                                                                # OpenWRT路由器IP地址
LOCAL_IPS=("192.168.1.108" "192.168.1.101" "192.168.1.156" "192.168.1.180" "192.168.1.154" "192.168.1.102")     # 本地客户端IP地址
REMOTE_PORTS=(5301 5302 5303 5304 5305 5306)                                                                    # 远程服务端端口（5301-5306）
RUN_TIME=10                                                                                                     # 运行时间（s）
BITRATE="100M"                                                                                                  # 比特率上限（bit/s）

# ===================== 终端启动函数 =====================
launch_terminal() {
  # 将第一个输入参数赋值给局部变量title，用于设置终端窗口的标题
  # 将第二个输入参数赋值给局部变量command，用于表示需要在终端中执行的命令
  local title="$1"
  local command="$2"
  
  # 检测支持的终端模拟器
  # 如果不加 exec bash，终端窗口会在 $command 执行完成后立即关闭
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
  # 在log文件中打出一条分割线
  echo -e "\n===================================================================================================================\n" >> iperf3.log

  # 远程服务端（OpenWRT）
  for i in "${!REMOTE_PORTS[@]}"; do
    launch_terminal "Remote Server ${REMOTE_PORTS[i]}" \
      "ssh $REMOTE_SERVER 'iperf3 -s -p ${REMOTE_PORTS[i]}'"
  done

  # 5301-5303 本地客户端 -> 远程服务端    5304-5306 本地客户端 <- 远程服务端
  for i in "${!REMOTE_PORTS[@]}"; do
    if ((i < 3)); then
    launch_terminal "Local Client ${REMOTE_PORTS[i]}" \
    "iperf3 -c ${REMOTE_SERVER#*@} -u -B ${LOCAL_IPS[i]} -b $BITRATE -p ${REMOTE_PORTS[i]} -t $RUN_TIME | while IFS= read -r line; do echo \"\$(date +'%Y-%m-%d %H:%M:%S') \$line\"; done | grep -E \"sender|receiver\" >> iperf3.log && echo -e \"\n${REMOTE_PORTS[i]} 本地客户端 -> 远程服务器\n\" >> iperf3.log"
    else
    launch_terminal "Local Client ${REMOTE_PORTS[i]}" \
    "iperf3 -c ${REMOTE_SERVER#*@} -u -B ${LOCAL_IPS[i]} -b $BITRATE -p ${REMOTE_PORTS[i]} -t $RUN_TIME -R | while IFS= read -r line; do echo \"\$(date +'%Y-%m-%d %H:%M:%S') \$line\"; done | grep -E \"sender|receiver\" >> iperf3.log && echo -e \"\n${REMOTE_PORTS[i]} 本地客户端 <- 远程服务器\n\" >> iperf3.log"
    fi
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


