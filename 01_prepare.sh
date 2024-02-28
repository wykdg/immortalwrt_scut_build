#拉取代码
git clone --depth=1 https://github.com/hanwckf/immortalwrt-mt798x.git

cd immortalwrt-mt798x
./scripts/feeds update -a

# 单独拉取mosdns的库
rm -rf feeds/packages/net/v2ray-geodata
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 20.x feeds/packages/lang/golang
git clone https://github.com/sbwml/luci-app-mosdns -b v5 package/mosdns
git clone https://github.com/sbwml/v2ray-geodata package/v2ray-geodata

#单独拉取scutclient
rm -rf feeds/luci/applications/luci-app-scutclient/
git clone https://github.com/hanwckf/luci-app-scutclient.git feeds/luci/applications/luci-app-scutclient 

#单独拉取联通加速
mkdir package/scut-unicom
wget https://raw.githubusercontent.com/wykdg/route_script/master/scut-unicom/Makefile -O package/scut-unicom/Makefile

./scripts/feeds install -a


#在启动项加入联通加速
sed -i '3i #如果使用联通加速，删除前面的#，并填充后面的值\n#sleep 10 && /usr/share/scut_unicom/add_route.sh server_ip username password' package/base-files/files/etc/rc.local 
#将ttyd改成默认root登录
sed -i "s/option command '\/bin\/login'/option command '\/bin\/login -f root'/" feeds/packages/utils/ttyd/files/ttyd.config 


sed  -i "s/exit 0/[ ! -f '\/usr\/sbin\/trojan' ] \&\& [ -f '\/usr\/bin\/trojan-go' ] \&\& ln -sf \/usr\/bin\/trojan-go \/usr\/bin\/trojan\nexit 0/" package/emortal/default-settings/files/99-default-settings                


#编译7981
cat defconfig/mt7981-ax3000.config >.config

#从配置文件读取
file_content=$(cat ../package.conf)
# 在每一行前面添加"config"，在后面添加"=y"
new_content=$(echo "$file_content" | awk '{print "CONFIG_PACKAGE_" $0 "=y"}')
# 将修改后的内容追加到.config文件中
echo "$new_content" >> .config

make defconfig

