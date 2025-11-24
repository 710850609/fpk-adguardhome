fpk_version=0.1
adhome_version="latest"
app_version="${fpk_version}-${adhome_version}"
fpk_name="adguard-home-${app_version}.fpk"

echo "开始打包 adguard-home.fpk"
fnpack build --directory adguard-home/

rm -f "${fpk_name}"
mv adguard-home.fpk "${fpk_name}"
echo "打包完成: ${fpk_name}"
