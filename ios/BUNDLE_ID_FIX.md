# ⚠️ Bundle Identifier 配置说明

## 当前状态

- **Xcode Bundle ID**: `com.yomo.Yomo`
- **Firebase 配置的 Bundle ID**: `com.yomo.app`

## ❌ 问题

这两个不匹配会导致：
- Google Sign-In 失败
- Firebase Authentication 无法工作
- Firestore 连接失败
- 推送通知无法注册

## ✅ 解决方法（二选一）

### 推荐：方案 A - 修改 Xcode Bundle ID 为 com.yomo.app

1. 在 Xcode 中选择项目
2. General → Identity → Bundle Identifier
3. 改为：`com.yomo.app`
4. 保存（⌘S）

**此方案无需修改任何代码文件！**

---

### 方案 B - 在 Firebase Console 添加新的 iOS App

如果你想保持 `com.yomo.Yomo`：

#### Step 1: Firebase Console 配置

1. 打开 https://console.firebase.google.com/project/yomo-5fba1
2. 点击齿轮图标 → **Project Settings**
3. 滚动到 **Your apps** 部分
4. 点击 **Add app** → 选择 **iOS**
5. Apple bundle ID: 输入 `com.yomo.Yomo`
6. App nickname: `Yomo iOS`
7. 点击 **Register app**
8. **下载新的 GoogleService-Info.plist**
9. 点击 **Continue** → **Continue** → 完成

#### Step 2: 替换配置文件

```bash
# 备份旧文件
mv /Users/mystery/Desktop/YOMO/ios/Yomo/Resources/GoogleService-Info.plist \
   /Users/mystery/Desktop/YOMO/GoogleService-Info.plist.backup

# 将从 Firebase 下载的新文件复制到这里
cp ~/Downloads/GoogleService-Info.plist \
   /Users/mystery/Desktop/YOMO/ios/Yomo/Resources/
```

#### Step 3: 在 Xcode 中更新 App Groups

1. Xcode → 项目设置 → **Signing & Capabilities**
2. 找到 **App Groups** 部分
3. 删除 `group.com.yomo.app`
4. 添加 `group.com.yomo.Yomo`

## 验证配置是否正确

运行此命令检查：

```bash
# 检查 Firebase 配置中的 Bundle ID
grep -A 1 "BUNDLE_ID" /Users/mystery/Desktop/YOMO/ios/Yomo/Resources/GoogleService-Info.plist
```

应该输出：
```xml
<key>BUNDLE_ID</key>
<string>com.yomo.Yomo</string>
```

## 当前代码已更新

我已经将以下文件更新为 `com.yomo.Yomo`：
- ✅ `Constants.swift` - Bundle ID 和 App Group ID
- ✅ `Info.plist` - App Groups 配置

**但是**，如果你选择方案 A（改回 com.yomo.app），只需：
1. 在 Xcode 改 Bundle Identifier
2. 恢复 `Constants.swift` 和 `Info.plist` 为 `com.yomo.app`

---

## 我的建议 💡

**使用方案 A**（修改 Xcode 为 `com.yomo.app`）：
- ✅ 最简单
- ✅ 无需重新配置 Firebase
- ✅ 无需下载新文件
- ✅ 1 分钟搞定

方案 B 虽然可行，但需要更多步骤且容易出错。

---

## 修改完成后测试

1. Clean Build Folder (⇧⌘K)
2. 重新运行 (⌘R)
3. 点击 "Continue with Google"
4. 应该能正常弹出 Google 登录界面

如果失败，检查：
```bash
# 查看 Xcode 控制台错误日志
# 常见错误：
# - "The bundle identifier does not match..."
# - "FirebaseApp failed to configure..."
```

请告诉我你选择哪个方案，我可以继续协助！
