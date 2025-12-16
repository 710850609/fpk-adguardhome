fpk_version="build-0.1"
adh_version="0.107.71"
bin_file="AdGuardHome/app/bin/AdGuardHome"

if [ ! -f "${bin_file}" ]; then
    echo "AdGuardHome 预编译文件不存在: $bin_file, 开始下载预编译版本..."
    proxy_url = "https://wget.la"
    wget -O AdGuardHome-linux-amd64.tar.gz "https://github.com/AdguardTeam/AdGuardHome/releases/download/v${adh_version}/AdGuardHome_linux_amd64.tar.gz"
    echo "下载完成，开始解压文件到 $bin_file 目录"
    tar -xzf AdGuardHome-linux-amd64.tar.gz

    mv AdGuardHome/AdGuardHome "$bin_file"
    echo "清理下载数据"
    rm -rf AdGuardHome
    rm -f AdGuardHome_linux_amd64.tar.gz
fi

# 压缩py脚本
echo "打包脚本"
rm -f AdGuardHome/cmd/script.zip
zip -rq AdGuardHome/cmd/script.zip ./script

app_version="${adh_version}-${fpk_version}"
sed -i "s|^[[:space:]]*version[[:space:]]*=.*|version=${app_version}|" 'AdGuardHome/manifest'
echo "设置 FPK 版本号为: ${app_version}"

echo "开始打包 AdGuardHome.fpk"
fnpack build --directory AdGuardHome/


fpk_name="AdGuardHome-${app_version}.fpk"
rm -f "${fpk_name}"
mv AdGuardHome.fpk "${fpk_name}"
echo "打包完成: ${fpk_name}"
