immortalwrt 华南理工校园版版本编译，集成 luci-app-scutclient

798x 保持原有的 hanwckf/immortalwrt-mt798x `openwrt-21.02` 内核和分区布局，源码锁定在项目最后一次 798x 编译使用的基线。原有目标和 U-Boot 不变。

Passwall 从官方仓库独立拉取固定的新版本（当前为 26.9.1），OpenClash 也从官方仓库独立拉取固定的 v0.47.156。Passwall 配套 Sing-box 1.14.0，并使用 Go 1.25.14；只启用 Sing-box。Xray、mosdns 和 openvpn-server 不编译，以控制固件体积。其他插件沿用原项目配置。

由于我只有 360T7 和 JCG Q20，其他机型测试有限。编译可在 GitHub Actions 手动启动，也会在推送到 `main` 时启动；`package.conf` 可按需调整。
