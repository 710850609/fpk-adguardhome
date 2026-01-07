build_version=9
# adh_version=$(curl -s https://api.github.com/repos/AdguardTeam/AdGuardHome/releases/latest | jq -r .tag_name | sed 's/^v//')
set -x
adh_version=$(curl -v --max-time 30 https://api.github.com/repos/AdguardTeam/AdGuardHome/releases/latest 2>&1)
echo "curl原始返回=$adh_version" >&2
adh_version=$(echo "$adh_version" | jq -r .tag_name 2>&1 | sed 's/^v//')
echo "最终adh_version=$adh_version" >&2

bin_file="AdGuardHome/app/bin/AdGuardHome"


declare -A PARAMS

# 默认值
PARAMS[build_all]="false"
PARAMS[build_pre]="false"
# linux-amd64, linux-arm64
PARAMS[arch]="linux-amd64"

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
arch="${PARAMS[arch]}"
echo "build_all: ${build_all}"
echo "build_pre: ${build_pre}"
echo "arch: ${arch}"


if [ -f "${bin_file}" ];then 
    # 读已下载的版本
    cuVersion=$(./${bin_file} --version | sed -n 's/AdGuard Home, version v//p')
    echo "已下载源码版本: $cuVersion"
    echo "最新版本: $adh_version"
    if [[ "$cuVersion" < "$adh_version" ]]; then
        echo "已下载源码版本小于最新版本，删除后重新下载"
        rm -rf ${bin_file}
    else
        echo "已下载版本大于等于目标版本，无需重新下载"
    fi
fi
if [ ! -f "${bin_file}" ] || [ "${build_all}" == "all" ]; then
    echo "AdGuardHome 预编译文件不存在: $bin_file, 开始下载预编译版本..."
    proxy_url="https://gh.llkk.cc"
    rm -f AdGuardHome.tar.gz
    arch_type=${arch//-/_}
    download_url="https://github.com/AdguardTeam/AdGuardHome/releases/download/v${adh_version}/AdGuardHome_${arch_type}.tar.gz"
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


fpk_version="${adh_version}-${build_version}"
if [ "$build_pre" == 'true' ];then 
    fpk_version="${fpk_version}-pre"
fi
sed -i "s|^[[:space:]]*version[[:space:]]*=.*|version=${fpk_version}|" 'AdGuardHome/manifest'
echo "设置 FPK 版本号为: ${fpk_version}"

echo "开始打包 AdGuardHome.fpk"
# fnpack build --directory AdGuardHome/
./fnpack.sh build --directory AdGuardHome || { echo "打包失败"; exit 1; }


fpk_name="AdGuardHome-${arch}-${fpk_version}.fpk"
rm -f "${fpk_name}"
mv AdGuardHome.fpk "${fpk_name}"
echo "打包完成: ${fpk_name}"