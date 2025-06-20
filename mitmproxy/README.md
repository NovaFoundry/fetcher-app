# 原始脚本
原始脚本 install_certificate_android_emulator-proxyman-mac-xxx.sh来源于 proxyman mac版本

## 安装证书和配置代理
### 参考运行命令如下
```bash
bash '/Applications/Proxyman.app/Contents/Frameworks/ProxymanCore.framework/Resources/install_certificate_android_emulator.sh' \
  -m all \
  -i 192.168.10.244 \
  -p 9091 \
  -c '/Users/x'x'x/Library/Application Support/com.proxyman.NSProxy/app-data/proxyman-ca.pem'
```
### 运行结果如下
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📱 Install Proxyman Certificate to Android Emulator/Device Script
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️  Important Notes:
   • Only supports Android Emulators with Google APIs
   • DO NOT support Google Play Store version

📚 Documentation:
   https://docs.proxyman.com/debug-devices/android-device/automatic-script-for-android-emulator
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚙️  Settings:
   Mode                : all
   IP Address          : 192.168.10.244
   Port                : 9091
   Certificate Path    : /Users/xxx/Library/Application Support/com.proxyman.NSProxy/app-data/proxyman-ca.pem
   Include Physical Dev: false

Checking adb command...
✅ ADB found at: /opt/homebrew/bin/adb
1. Checking Android Emulators Status...
✅ Status: Device Ready
2. Configuring HTTP Proxy...
   Target: Proxyman (192.168.10.244:9091)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🤖 Processing Emulator Device: emulator-5554
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Proxy configured successfully for Emulator Device emulator-5554

3. Installing Proxyman Certificate to System-Level CA...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🤖 Processing Emulator Device: emulator-5554
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/Users/xxx/Library/Application Support/com.proxyman.NSPr... 1 file pushed, 0 skipped. 5.8 MB/s (1903 bytes in 0.000s)
📂 Using certificate source: /apex/com.android.conscrypt/cacerts
✅ Certificate injection completed for Emulator Device emulator-5554

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Installation Complete!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📝 Next Steps:
   1. Restart your app from Android Studio
   2. Enjoy Proxyman!

## 删除证书和代理
### 参考运行命令如下
```bash
bash '/Applications/Proxyman.app/Contents/Frameworks/ProxymanCore.framework/Resources/install_certificate_android_emulator.sh' \
  -m revertProxy
```
### 运行结果如下
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📱 Install Proxyman Certificate to Android Emulator/Device Script
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️  Important Notes:
   • Only supports Android Emulators with Google APIs
   • DO NOT support Google Play Store version

📚 Documentation:
   https://docs.proxyman.com/debug-devices/android-device/automatic-script-for-android-emulator
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚙️  Settings:
   Mode                : revertProxy
   Include Physical Dev: false

Checking adb command...
✅ ADB found at: /opt/homebrew/bin/adb
1. Checking Android Emulators Status...
✅ Status: Device Ready
2. Reverting HTTP Proxy Settings...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🤖 Processing Emulator Device: emulator-5554
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Proxy settings removed successfully for Emulator Device emulator-5554

# mitmproxy
## 安装mitmproxy
```bash
brew install mitmproxy
```
## 生成mitmproxy证书
安装mitmproxy后，它会自动在首次运行时生成证书。证书默认保存在以下位置：
```plaintext
~/.mitmproxy/mitmproxy-ca-cert.pem
```
如果您想手动生成或重新生成证书，可以运行：
```bash
mitmproxy --set confdir=~/.mitmproxy
```
然后按 q 退出，证书会被保存在配置目录中。
## mitmproxy 脚本
本脚本 install_certificate_android_emulator-mitmproxy-mac.sh 用于在Android模拟器或设备上安装mitmproxy证书并配置HTTP代理，基于Proxyman的原始脚本修改而来。


功能特点：
- 支持Android模拟器和设备
- 基于mitmproxy证书
- 配置HTTP代理
- 支持Proxyman的证书安装

使用前提
- 已安装Android Debug Bridge (adb)
- 已安装mitmproxy
- Android模拟器已启动或物理设备已连接
- 仅支持带有Google API的Android模拟器
- 不支持Google Play Store版本
### 使用方法
#### 安装证书和配置代理
```bash
bash './install_certificate_android_emulator-mitmproxy-mac.sh' \
  -m all \
  -i 127.0.0.1 \
  -p 8080 \
  -c ~/.mitmproxy/mitmproxy-ca-cert.pem
```
参数说明：

- -m all : 执行全部操作（安装证书和配置代理）
- -i 127.0.0.1 : 代理服务器IP地址  **【强烈建议使用局域网IP而非127.0.0.1】**
- -p 8080 : 代理服务器端口
- -c ~/.mitmproxy/mitmproxy-ca-cert.pem : mitmproxy证书路径
如果不指定证书路径，脚本会尝试使用默认位置： ~/.mitmproxy/mitmproxy-ca-cert.pem
#### 仅配置代理
```bash
bash './install_certificate_android_emulator-mitmproxy-mac.sh' \
  -m proxy \
  -i 127.0.0.1 \
  -p 8080
```
#### 仅安装证书
```bash
bash './install_certificate_android_emulator-mitmproxy-mac.sh' \
  -m certificate \
  -i 127.0.0.1 \
  -p 8080 \
  -c ~/.mitmproxy/mitmproxy-ca-cert.pem
```
#### 恢复代理设置（移除代理）
```bash
bash './install_certificate_android_emulator-mitmproxy-mac.sh' \
  -m revertProxy
```
#### 包含物理设备
默认情况下，脚本只处理模拟器设备。如果要包含物理设备，添加 --include-physical 参数：
```bash
bash './install_certificate_android_emulator-mitmproxy-mac.sh' \
  -m all \
  -i 127.0.0.1 \
  -p 8080 \
  -c ~/.mitmproxy/mitmproxy-ca-cert.pem \
  --include-physical
```