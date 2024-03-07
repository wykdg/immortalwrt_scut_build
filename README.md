immortalwrt 华南理工校园版版本编译,集成luci-app-scutclient，和半成品的联通加速

当前完成了7621和798x的集成，
7621用[immortalwrt 21.02](https://github.com/immortalwrt/immortalwrt/tree/openwrt-21.02),  
798x基于hanwckf的项目[immortalwrt-798x](https://github.com/hanwckf/immortalwrt-mt798x)    
由于我只有360t7和jcg q20，所以测试有限，其他版本不确定是否正常  

7621 mini只加了一点插件。full带了ssr、passwall和mosdns，这几个太大了，uboot只能先刷mini的，再进系统sysupgrade。

编译方法：  
1. 直接在github action手动启动编译  
2. package.conf为我个人喜好选择的库,可自行调整 
