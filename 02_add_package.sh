


#从配置文件读取
file_content=$(cat ../package.conf)
# 在每一行前面添加"config"，在后面添加"=y"
new_content=$(echo "$file_content" | awk '{print "CONFIG_PACKAGE_" $0 "=y"}')
# 将修改后的内容追加到.config文件中
echo "$new_content" >> .config



