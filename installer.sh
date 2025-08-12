#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

generate_uuid() {
    if command -v uuidgen &> /dev/null; then
        uuidgen | tr '[:upper:]' '[:lower:]'
    elif command -v python3 &> /dev/null; then
        python3 -c "import uuid; print(str(uuid.uuid4()))"
    else
        hexdump -n 16 -e '4/4 "%08X" 1 "\n"' /dev/urandom | sed 's/\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)/\1\2\3\4-\5\6-\7\8-\9\10-\11\12\13\14\15\16/' | tr '[:upper:]' '[:lower:]'
    fi
}

clear

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}    Python Xray Argo One-Click Install Script    ${NC}"
echo -e "${GREEN}========================================${NC}"
echo
echo -e "${BLUE}基于項目: ${YELLOW}https://github.com/eooce/python-xray-argo${NC}"
echo -e "${BLUE}GitHub: ${YELLOW}https://github.com/${NC}"
echo -e "${BLUE}Discord群: ${YELLOW}https://discord.gg/WTMWtmV${NC}"
echo
echo -e "${GREEN}提供極速和完整兩種配置模式，簡化部署流程${NC}"
echo

echo -e "${YELLOW}請選擇配置模式:${NC}"
echo -e "${BLUE}1) 極速模式 - 只修改UUID並啓動${NC}"
echo -e "${BLUE}2) 完整模式 - 詳細配置所有選項${NC}"
echo
read -p "請輸入選擇 (1/2): " MODE_CHOICE

echo -e "${BLUE}檢查並安裝依賴...${NC}"
if ! command -v python3 &> /dev/null; then
    echo -e "${YELLOW}正在安裝 Python3...${NC}"
    sudo apt-get update && sudo apt-get install -y python3 python3-pip
fi

if ! python3 -c "import requests" &> /dev/null; then
    echo -e "${YELLOW}正在安裝 Python 依賴...${NC}"
    pip3 install requests
fi

PROJECT_DIR="python-xray-argo"
if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${BLUE}下載完整倉庫...${NC}"
    if command -v git &> /dev/null; then
        git clone https://github.com/eooce/python-xray-argo.git
    else
        echo -e "${YELLOW}Git未安裝，使用wget下載...${NC}"
        wget -q https://github.com/eooce/python-xray-argo/archive/refs/heads/main.zip -O python-xray-argo.zip
        if command -v unzip &> /dev/null; then
            unzip -q python-xray-argo.zip
            mv python-xray-argo-main python-xray-argo
            rm python-xray-argo.zip
        else
            echo -e "${YELLOW}正在安裝 unzip...${NC}"
            sudo apt-get install -y unzip
            unzip -q python-xray-argo.zip
            mv python-xray-argo-main python-xray-argo
            rm python-xray-argo.zip
        fi
    fi
    
    if [ $? -ne 0 ] || [ ! -d "$PROJECT_DIR" ]; then
        echo -e "${RED}下載失敗，請檢查網絡連接${NC}"
        exit 1
    fi
fi

cd "$PROJECT_DIR"

echo -e "${GREEN}依賴安裝完成！${NC}"
echo

if [ ! -f "app.py" ]; then
    echo -e "${RED}未找到app.py文件！${NC}"
    exit 1
fi

cp app.py app.py.backup
echo -e "${YELLOW}已備份原始文件爲 app.py.backup${NC}"

if [ "$MODE_CHOICE" = "1" ]; then
    echo -e "${BLUE}=== 極速模式 ===${NC}"
    echo
    
    echo -e "${YELLOW}當前UUID: $(grep "UUID = " app.py | head -1 | cut -d"'" -f2)${NC}"
    read -p "請輸入新的 UUID (留空自動生成): " UUID_INPUT
    if [ -z "$UUID_INPUT" ]; then
        UUID_INPUT=$(generate_uuid)
        echo -e "${GREEN}自動生成UUID: $UUID_INPUT${NC}"
    fi
    
    sed -i "s/UUID = os.environ.get('UUID', '[^']*')/UUID = os.environ.get('UUID', '$UUID_INPUT')/" app.py
    echo -e "${GREEN}UUID 已設置爲: $UUID_INPUT${NC}"
    
    sed -i "s/CFIP = os.environ.get('CFIP', '[^']*')/CFIP = os.environ.get('CFIP', 'cloudflare.com')/" app.py
    echo -e "${GREEN}優選IP已自動設置爲: cloudflare.com${NC}"
    
    echo
    echo -e "${GREEN}極速配置完成！正在啓動服務...${NC}"
    echo
    
else
    echo -e "${BLUE}=== 完整配置模式 ===${NC}"
    echo
    
    echo -e "${YELLOW}當前UUID: $(grep "UUID = " app.py | head -1 | cut -d"'" -f2)${NC}"
    read -p "請輸入新的 UUID (留空自動生成): " UUID_INPUT
    if [ -z "$UUID_INPUT" ]; then
        UUID_INPUT=$(generate_uuid)
        echo -e "${GREEN}自動生成UUID: $UUID_INPUT${NC}"
    fi
    sed -i "s/UUID = os.environ.get('UUID', '[^']*')/UUID = os.environ.get('UUID', '$UUID_INPUT')/" app.py
    echo -e "${GREEN}UUID 已設置爲: $UUID_INPUT${NC}"

    echo -e "${YELLOW}當前節點名稱: $(grep "NAME = " app.py | head -1 | cut -d"'" -f4)${NC}"
    read -p "請輸入節點名稱 (留空保持不變): " NAME_INPUT
    if [ -n "$NAME_INPUT" ]; then
        sed -i "s/NAME = os.environ.get('NAME', '[^']*')/NAME = os.environ.get('NAME', '$NAME_INPUT')/" app.py
        echo -e "${GREEN}節點名稱已設置爲: $NAME_INPUT${NC}"
    fi

    echo -e "${YELLOW}當前服務端口: $(grep "PORT = int" app.py | grep -o "or [0-9]*" | cut -d" " -f2)${NC}"
    read -p "請輸入服務端口 (留空保持不變): " PORT_INPUT
    if [ -n "$PORT_INPUT" ]; then
        sed -i "s/PORT = int(os.environ.get('SERVER_PORT') or os.environ.get('PORT') or [0-9]*)/PORT = int(os.environ.get('SERVER_PORT') or os.environ.get('PORT') or $PORT_INPUT)/" app.py
        echo -e "${GREEN}端口已設置爲: $PORT_INPUT${NC}"
    fi

    echo -e "${YELLOW}當前優選IP: $(grep "CFIP = " app.py | cut -d"'" -f4)${NC}"
    read -p "請輸入優選IP/域名 (留空使用默認 cloudflare.com): " CFIP_INPUT
    if [ -z "$CFIP_INPUT" ]; then
        CFIP_INPUT="cloudflare.com"
    fi
    sed -i "s/CFIP = os.environ.get('CFIP', '[^']*')/CFIP = os.environ.get('CFIP', '$CFIP_INPUT')/" app.py
    echo -e "${GREEN}優選IP已設置爲: $CFIP_INPUT${NC}"

    echo -e "${YELLOW}當前優選端口: $(grep "CFPORT = " app.py | cut -d"'" -f4)${NC}"
    read -p "請輸入優選端口 (留空保持不變): " CFPORT_INPUT
    if [ -n "$CFPORT_INPUT" ]; then
        sed -i "s/CFPORT = int(os.environ.get('CFPORT', '[^']*'))/CFPORT = int(os.environ.get('CFPORT', '$CFPORT_INPUT'))/" app.py
        echo -e "${GREEN}優選端口已設置爲: $CFPORT_INPUT${NC}"
    fi

    echo -e "${YELLOW}當前Argo端口: $(grep "ARGO_PORT = " app.py | cut -d"'" -f4)${NC}"
    read -p "請輸入 Argo 端口 (留空保持不變): " ARGO_PORT_INPUT
    if [ -n "$ARGO_PORT_INPUT" ]; then
        sed -i "s/ARGO_PORT = int(os.environ.get('ARGO_PORT', '[^']*'))/ARGO_PORT = int(os.environ.get('ARGO_PORT', '$ARGO_PORT_INPUT'))/" app.py
        echo -e "${GREEN}Argo端口已設置爲: $ARGO_PORT_INPUT${NC}"
    fi

    echo -e "${YELLOW}當前訂閱路徑: $(grep "SUB_PATH = " app.py | cut -d"'" -f4)${NC}"
    read -p "請輸入訂閱路徑 (留空保持不變): " SUB_PATH_INPUT
    if [ -n "$SUB_PATH_INPUT" ]; then
        sed -i "s/SUB_PATH = os.environ.get('SUB_PATH', '[^']*')/SUB_PATH = os.environ.get('SUB_PATH', '$SUB_PATH_INPUT')/" app.py
        echo -e "${GREEN}訂閱路徑已設置爲: $SUB_PATH_INPUT${NC}"
    fi

    echo
    echo -e "${YELLOW}是否配置高級選項? (y/n)${NC}"
    read -p "> " ADVANCED_CONFIG

    if [ "$ADVANCED_CONFIG" = "y" ] || [ "$ADVANCED_CONFIG" = "Y" ]; then
        echo -e "${YELLOW}當前上傳URL: $(grep "UPLOAD_URL = " app.py | cut -d"'" -f4)${NC}"
        read -p "請輸入上傳URL (留空保持不變): " UPLOAD_URL_INPUT
        if [ -n "$UPLOAD_URL_INPUT" ]; then
            sed -i "s|UPLOAD_URL = os.environ.get('UPLOAD_URL', '[^']*')|UPLOAD_URL = os.environ.get('UPLOAD_URL', '$UPLOAD_URL_INPUT')|" app.py
            echo -e "${GREEN}上傳URL已設置${NC}"
        fi

        echo -e "${YELLOW}當前項目URL: $(grep "PROJECT_URL = " app.py | cut -d"'" -f4)${NC}"
        read -p "請輸入項目URL (留空保持不變): " PROJECT_URL_INPUT
        if [ -n "$PROJECT_URL_INPUT" ]; then
            sed -i "s|PROJECT_URL = os.environ.get('PROJECT_URL', '[^']*')|PROJECT_URL = os.environ.get('PROJECT_URL', '$PROJECT_URL_INPUT')|" app.py
            echo -e "${GREEN}項目URL已設置${NC}"
        fi

        echo -e "${YELLOW}當前自動保活狀態: $(grep "AUTO_ACCESS = " app.py | grep -o "'[^']*'" | tail -1 | tr -d "'")${NC}"
        echo -e "${YELLOW}是否啓用自動保活? (y/n)${NC}"
        read -p "> " AUTO_ACCESS_INPUT
        if [ "$AUTO_ACCESS_INPUT" = "y" ] || [ "$AUTO_ACCESS_INPUT" = "Y" ]; then
            sed -i "s/AUTO_ACCESS = os.environ.get('AUTO_ACCESS', '[^']*')/AUTO_ACCESS = os.environ.get('AUTO_ACCESS', 'true')/" app.py
            echo -e "${GREEN}自動保活已啓用${NC}"
        elif [ "$AUTO_ACCESS_INPUT" = "n" ] || [ "$AUTO_ACCESS_INPUT" = "N" ]; then
            sed -i "s/AUTO_ACCESS = os.environ.get('AUTO_ACCESS', '[^']*')/AUTO_ACCESS = os.environ.get('AUTO_ACCESS', 'false')/" app.py
            echo -e "${GREEN}自動保活已禁用${NC}"
        fi

        echo -e "${YELLOW}當前哪吒服務器: $(grep "NEZHA_SERVER = " app.py | cut -d"'" -f4)${NC}"
        read -p "請輸入哪吒服務器地址 (留空保持不變): " NEZHA_SERVER_INPUT
        if [ -n "$NEZHA_SERVER_INPUT" ]; then
            sed -i "s|NEZHA_SERVER = os.environ.get('NEZHA_SERVER', '[^']*')|NEZHA_SERVER = os.environ.get('NEZHA_SERVER', '$NEZHA_SERVER_INPUT')|" app.py
            
            echo -e "${YELLOW}當前哪吒端口: $(grep "NEZHA_PORT = " app.py | cut -d"'" -f4)${NC}"
            read -p "請輸入哪吒端口 (v1版本留空): " NEZHA_PORT_INPUT
            if [ -n "$NEZHA_PORT_INPUT" ]; then
                sed -i "s|NEZHA_PORT = os.environ.get('NEZHA_PORT', '[^']*')|NEZHA_PORT = os.environ.get('NEZHA_PORT', '$NEZHA_PORT_INPUT')|" app.py
            fi
            
            echo -e "${YELLOW}當前哪吒密鑰: $(grep "NEZHA_KEY = " app.py | cut -d"'" -f4)${NC}"
            read -p "請輸入哪吒密鑰: " NEZHA_KEY_INPUT
            if [ -n "$NEZHA_KEY_INPUT" ]; then
                sed -i "s|NEZHA_KEY = os.environ.get('NEZHA_KEY', '[^']*')|NEZHA_KEY = os.environ.get('NEZHA_KEY', '$NEZHA_KEY_INPUT')|" app.py
            fi
            echo -e "${GREEN}哪吒配置已設置${NC}"
        fi

        echo -e "${YELLOW}當前Argo域名: $(grep "ARGO_DOMAIN = " app.py | cut -d"'" -f4)${NC}"
        read -p "請輸入 Argo 固定隧道域名 (留空保持不變): " ARGO_DOMAIN_INPUT
        if [ -n "$ARGO_DOMAIN_INPUT" ]; then
            sed -i "s|ARGO_DOMAIN = os.environ.get('ARGO_DOMAIN', '[^']*')|ARGO_DOMAIN = os.environ.get('ARGO_DOMAIN', '$ARGO_DOMAIN_INPUT')|" app.py
            
            echo -e "${YELLOW}當前Argo密鑰: $(grep "ARGO_AUTH = " app.py | cut -d"'" -f4)${NC}"
            read -p "請輸入 Argo 固定隧道密鑰: " ARGO_AUTH_INPUT
            if [ -n "$ARGO_AUTH_INPUT" ]; then
                sed -i "s|ARGO_AUTH = os.environ.get('ARGO_AUTH', '[^']*')|ARGO_AUTH = os.environ.get('ARGO_AUTH', '$ARGO_AUTH_INPUT')|" app.py
            fi
            echo -e "${GREEN}Argo固定隧道配置已設置${NC}"
        fi

        echo -e "${YELLOW}當前Bot Token: $(grep "BOT_TOKEN = " app.py | cut -d"'" -f4)${NC}"
        read -p "請輸入 Telegram Bot Token (留空保持不變): " BOT_TOKEN_INPUT
        if [ -n "$BOT_TOKEN_INPUT" ]; then
            sed -i "s|BOT_TOKEN = os.environ.get('BOT_TOKEN', '[^']*')|BOT_TOKEN = os.environ.get('BOT_TOKEN', '$BOT_TOKEN_INPUT')|" app.py
            
            echo -e "${YELLOW}當前Chat ID: $(grep "CHAT_ID = " app.py | cut -d"'" -f4)${NC}"
            read -p "請輸入 Telegram Chat ID: " CHAT_ID_INPUT
            if [ -n "$CHAT_ID_INPUT" ]; then
                sed -i "s|CHAT_ID = os.environ.get('CHAT_ID', '[^']*')|CHAT_ID = os.environ.get('CHAT_ID', '$CHAT_ID_INPUT')|" app.py
            fi
            echo -e "${GREEN}Telegram配置已設置${NC}"
        fi
    fi

    echo
    echo -e "${GREEN}完整配置完成！${NC}"
fi

echo -e "${YELLOW}=== 當前配置摘要 ===${NC}"
echo -e "UUID: $(grep "UUID = " app.py | head -1 | cut -d"'" -f2)"
echo -e "節點名稱: $(grep "NAME = " app.py | head -1 | cut -d"'" -f4)"
echo -e "服務端口: $(grep "PORT = int" app.py | grep -o "or [0-9]*" | cut -d" " -f2)"
echo -e "優選IP: $(grep "CFIP = " app.py | cut -d"'" -f4)"
echo -e "優選端口: $(grep "CFPORT = " app.py | cut -d"'" -f4)"
echo -e "訂閱路徑: $(grep "SUB_PATH = " app.py | cut -d"'" -f4)"
echo -e "${YELLOW}========================${NC}"
echo

echo -e "${BLUE}正在啓動服務...${NC}"
echo -e "${YELLOW}當前工作目錄：$(pwd)${NC}"
echo

nohup python3 app.py > app.log 2>&1 &
APP_PID=$!

echo -e "${GREEN}服務已在後台啓動，PID: $APP_PID${NC}"
echo -e "${YELLOW}日志文件: $(pwd)/app.log${NC}"

echo -e "${BLUE}等待服務啓動...${NC}"
sleep 10

if ps -p $APP_PID > /dev/null; then
    echo -e "${GREEN}服務運行正常${NC}"
else
    echo -e "${RED}服務啓動失敗，請檢查日志${NC}"
    echo -e "${YELLOW}查看日志: tail -f app.log${NC}"
    exit 1
fi

SERVICE_PORT=$(grep "PORT = int" app.py | grep -o "or [0-9]*" | cut -d" " -f2)
CURRENT_UUID=$(grep "UUID = " app.py | head -1 | cut -d"'" -f2)
SUB_PATH_VALUE=$(grep "SUB_PATH = " app.py | cut -d"'" -f4)

echo -e "${BLUE}等待節點信息生成...${NC}"
sleep 15

NODE_INFO=""
if [ -f ".cache/sub.txt" ]; then
    NODE_INFO=$(cat .cache/sub.txt)
elif [ -f "sub.txt" ]; then
    NODE_INFO=$(cat sub.txt)
fi

echo
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}           部署完成！                   ${NC}"
echo -e "${GREEN}========================================${NC}"
echo

echo -e "${YELLOW}=== 服務信息 ===${NC}"
echo -e "服務狀態: ${GREEN}運行中${NC}"
echo -e "進程PID: ${BLUE}$APP_PID${NC}"
echo -e "服務端口: ${BLUE}$SERVICE_PORT${NC}"
echo -e "UUID: ${BLUE}$CURRENT_UUID${NC}"
echo -e "訂閱路徑: ${BLUE}/$SUB_PATH_VALUE${NC}"
echo

echo -e "${YELLOW}=== 訪問地址 ===${NC}"
if command -v curl &> /dev/null; then
    PUBLIC_IP=$(curl -s https://api.ipify.org 2>/dev/null || echo "獲取失敗")
    if [ "$PUBLIC_IP" != "獲取失敗" ]; then
        echo -e "訂閱地址: ${GREEN}http://$PUBLIC_IP:$SERVICE_PORT/$SUB_PATH_VALUE${NC}"
        echo -e "管理面板: ${GREEN}http://$PUBLIC_IP:$SERVICE_PORT${NC}"
    fi
fi
echo -e "本地訂閱: ${GREEN}http://localhost:$SERVICE_PORT/$SUB_PATH_VALUE${NC}"
echo -e "本地面板: ${GREEN}http://localhost:$SERVICE_PORT${NC}"
echo

if [ -n "$NODE_INFO" ]; then
    echo -e "${YELLOW}=== 節點信息 ===${NC}"
    DECODED_NODES=$(echo "$NODE_INFO" | base64 -d 2>/dev/null || echo "$NODE_INFO")
    echo -e "${GREEN}原始節點配置:${NC}"
    echo "$DECODED_NODES"
    echo
    echo -e "${GREEN}訂閱鏈接 (Base64編碼):${NC}"
    echo "$NODE_INFO"
    echo
else
    echo -e "${YELLOW}=== 節點信息 ===${NC}"
    echo -e "${RED}節點信息還未生成，請稍等幾分鍾後查看日志或手動訪問訂閱地址${NC}"
    echo
fi

echo -e "${YELLOW}=== 管理命令 ===${NC}"
echo -e "查看日志: ${BLUE}tail -f $(pwd)/app.log${NC}"
echo -e "停止服務: ${BLUE}kill $APP_PID${NC}"
echo -e "重啓服務: ${BLUE}kill $APP_PID && nohup python3 app.py > app.log 2>&1 &${NC}"
echo -e "查看進程: ${BLUE}ps aux | grep python3${NC}"
echo

echo -e "${YELLOW}=== 重要提示 ===${NC}"
echo -e "${GREEN}服務正在後台運行，請等待Argo隧道建立完成${NC}"
echo -e "${GREEN}如果使用臨時隧道，域名會在幾分鍾後出現在日志中${NC}"
echo -e "${GREEN}建議10-15分鍾後再次查看訂閱地址獲取最新節點信息${NC}"
echo -e "${GREEN}可以通過日志查看詳細的啓動過程和隧道信息${NC}"
echo

echo -e "${GREEN}部署完成！感謝使用！${NC}"
