fpk_version="build-0.5"
adh_version="0.107.71"
bin_file="AdGuardHome/app/bin/AdGuardHome"
build_all="$1"

if [ ! -f "${bin_file}" ] || [ "${build_all}" == "all" ]; then
    echo "AdGuardHome 预编译文件不存在: $bin_file, 开始下载预编译版本..."
    proxy_url="https://gh.llkk.cc"
    rm -f AdGuardHome-linux-amd64.tar.gz
    wget -O AdGuardHome-linux-amd64.tar.gz "${proxy_url}/https://github.com/AdguardTeam/AdGuardHome/releases/download/v${adh_version}/AdGuardHome_linux_amd64.tar.gz"
    echo "下载完成，开始解压文件到 $bin_file 目录"
    mkdir AdGuardHome-linux-amd64
    tar -xzf AdGuardHome-linux-amd64.tar.gz -C AdGuardHome-linux-amd64
    rm -f "$bin_file"
    mv AdGuardHome-linux-amd64/AdGuardHome/AdGuardHome "$bin_file"
    # echo "清理下载数据"
    rm -rf AdGuardHome-linux-amd64
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


app_version="${adh_version}-${fpk_version}"
sed -i "s|^[[:space:]]*version[[:space:]]*=.*|version=${app_version}|" 'AdGuardHome/manifest'
echo "设置 FPK 版本号为: ${app_version}"

echo "开始打包 AdGuardHome.fpk"
fnpack build --directory AdGuardHome/


fpk_name="AdGuardHome-${app_version}.fpk"
rm -f "${fpk_name}"
mv AdGuardHome.fpk "${fpk_name}"
echo "打包完成: ${fpk_name}"