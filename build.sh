buidl_version="7"
adh_version="0.107.71"
bin_file="AdGuardHome/app/bin/AdGuardHome"


declare -A PARAMS

# 默认值
PARAMS[build_all]="false"
PARAMS[build_pre]="false"

# 解析 key=value 格式的参数
for arg in "$@"; do
  if [[ "$arg" == *=* ]]; then
    key="${arg%%=*}"
    value="${arg#*=}"
    PARAMS["$key"]="$value"
  else
    # 处理标志参数
    case "$arg" in
      --pre)
        PARAMS[pre]="true"
        ;;
      *)
        echo "忽略未知参数: $arg"
        ;;
    esac
  fi
done

build_all="${PARAMS[build_all]}"
build_pre="${PARAMS[build_pre]}"
arch="${PARAMS[arch]:-linux_amd64}"
echo "build_all: ${PARAMS[build_all]}"
echo "build_pre: ${PARAMS[build_pre]}"


if [ ! -f "${bin_file}" ] || [ "${build_all}" == "all" ]; then
    echo "AdGuardHome 预编译文件不存在: $bin_file, 开始下载预编译版本..."
    proxy_url="https://gh.llkk.cc"
    rm -f AdGuardHome.tar.gz
    download_url="https://github.com/AdguardTeam/AdGuardHome/releases/download/v${adh_version}/AdGuardHome_${arch}.tar.gz"
    # download_url="${proxy_url}/${download_url}"
    wget -O AdGuardHome.tar.gz "${download_url}"
    echo "下载完成，开始解压文件到 $bin_file 目录"
    mkdir AdGuardHome-dist
    tar -xzf AdGuardHome-linux-amd64.tar.gz -C AdGuardHome-dist
    rm -f "$bin_file"
    mv AdGuardHome-dist/AdGuardHome/AdGuardHome "$bin_file"
    # echo "清理下载数据"
    rm -rf AdGuardHome-dist
fi


# 下载py离线依赖
echo "创建并激活py虚拟环境"
cd script
python3 -m venv .venv
source .venv/bin/activate
# pip install -r requirements.txt
# 回写固定版本
# pip freeze > requirements.txt
rm -rf wheels
echo "下载离线包, 使用pip: $(pip --version)"
pip download -d wheels -r requirements.txt
cd ../
# 下载 wheel 到本地
app_script_path="AdGuardHome/app/script/"
rm -rf "${app_script_path}"
echo "写入脚本到app"
rm -rf  "${app_script_path}"
rsync -a --exclude='.venv'  script/  "${app_script_path}"


fpk_version="${adh_version}-${buidl_version}"
if [ "$build_pre" == 'true' ];then 
    fpk_version="${fpk_version}-pre"
fi
sed -i "s|^[[:space:]]*version[[:space:]]*=.*|version=${fpk_version}|" 'AdGuardHome/manifest'
echo "设置 FPK 版本号为: ${fpk_version}"

echo "开始打包 AdGuardHome.fpk"
fnpack build --directory AdGuardHome/


fpk_name="AdGuardHome_${arch}-${fpk_version}.fpk"
rm -f "${fpk_name}"
mv AdGuardHome.fpk "${fpk_name}"
echo "打包完成: ${fpk_name}"