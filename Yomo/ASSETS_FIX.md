# Xcode 项目配置说明

## Assets.xcassets 位置

你的 Xcode 项目使用的 Assets 路径是：
`/Users/mystery/Desktop/YOMO/Yomo/Yomo/Assets.xcassets/`

**重要**: 不是 `ios/Yomo/Assets.xcassets/`！

## 如果还有 Assets 错误

### 在 Xcode 中手动检查：

1. **点击左侧的 Assets.xcassets** 文件夹
2. **查看右侧 File Inspector** (⌥⌘1)
3. **确认路径**应该显示：
   ```
   Location: /Users/mystery/Desktop/YOMO/Yomo/Yomo/Assets.xcassets
   ```

### 如果路径错误：

**方法 A: 删除并重新添加**

1. 右键点击 **Assets.xcassets** → **Delete** → 选择 **Remove Reference** (不要选 Move to Trash)
2. 在 Finder 中打开：`/Users/mystery/Desktop/YOMO/Yomo/Yomo/`
3. 拖拽 **Assets.xcassets** 文件夹到 Xcode 左侧的 Yomo 文件夹中
4. 确保勾选：
   - ✅ Copy items if needed
   - ✅ Create groups
   - ✅ Add to targets: Yomo

**方法 B: 修改路径**

1. 点击 Assets.xcassets
2. 右侧 File Inspector → Location → 点击文件夹图标
3. 选择正确的路径：`/Users/mystery/Desktop/YOMO/Yomo/Yomo/Assets.xcassets`

## 验证 Assets 内容

Assets 应该包含：
- ✅ **AccentColor.colorset/** (品牌蓝色)
- ✅ **AppIcon.appiconset/** (App 图标占位)
- ✅ **Contents.json** (目录配置)

## Clean Build 后测试

1. ⇧⌘K (Clean Build Folder)
2. ⌘B (Build)
3. 如果成功，运行 ⌘R

## 如果 AppIcon 警告仍然存在

这是正常的！因为我们还没有添加实际的 App 图标图片，只有占位结构。

**可以忽略此警告**，不影响运行。

等到 Day 7 polish 阶段再添加真实图标。
