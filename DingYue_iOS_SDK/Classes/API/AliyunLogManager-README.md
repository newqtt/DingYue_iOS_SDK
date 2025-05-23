# AliyunLogManager - 阿里云日志管理器

## 简介

`AliyunLogManager` 是一个线程安全的单例类，用于管理阿里云日志服务SDK的初始化和日志发送功能。它提供了简单易用的API来发送各种类型的日志到阿里云日志服务。

## 特性

- ✅ 单例模式，全局唯一实例
- ✅ 线程安全，支持多线程并发调用
- ✅ 自动设备信息收集
- ✅ 支持断点续传和本地缓存
- ✅ 灵活的配置选项
- ✅ 丰富的便利方法
- ✅ 与现有SDK无缝集成

## 快速开始

### 1. 初始化

```swift
// 使用默认配置快速初始化
AliyunLogManager.shared.quickInit()

// 或者使用自定义配置
let success = AliyunLogManager.shared.initializeAliyunLog(
    endpoint: "https://your-endpoint.aliyuncs.com",
    project: "your-project",
    logstore: "your-logstore",
    accessKeyId: "your-access-key-id",
    accessKeySecret: "your-access-key-secret"
)
```

### 2. 发送日志

```swift
// 发送简单日志
AliyunLogManager.shared.log("用户登录成功")

// 发送事件日志
AliyunLogManager.shared.sendEventLog(
    eventName: "user_action",
    eventData: ["action": "login", "success": true]
)
```

## API 参考

### 核心方法

#### `initializeAliyunLog()`
初始化阿里云日志客户端

**参数:**
- `endpoint`: 阿里云日志服务endpoint
- `project`: 项目名称  
- `logstore`: 日志库名称
- `accessKeyId`: AccessKey ID
- `accessKeySecret`: AccessKey Secret
- `source`: 日志来源标识 (默认: "qtt_core")
- `topic`: 日志主题 (默认: "phonetracker")

**返回值:** `Bool` - 初始化是否成功

#### `sendLogToAliyun(message:additionalContent:)`
发送日志到阿里云

**参数:**
- `message`: 日志消息内容
- `additionalContent`: 额外的日志内容字典 (可选)

#### `sendEventLog(eventName:eventData:)`
发送自定义事件日志

**参数:**
- `eventName`: 事件名称
- `eventData`: 事件数据字典 (可选)

### 便利方法

#### `log(_:)`
发送简单的文本日志

#### `logError(_:context:)`
发送错误日志

#### `logDebug(_:file:function:line:)`
发送调试日志，自动包含文件名、函数名和行号

#### `trackUserEvent(_:parameters:)`
跟踪用户事件

#### `trackPurchaseEvent(productId:price:currency:success:)`
跟踪购买事件

#### `trackPageView(pageName:duration:)`
跟踪页面浏览事件

## 配置说明

### 默认配置参数

```swift
endpoint: "https://getimage.icu"
project: "ios-log-event"  
logstore: "events"
accessKeyId: "fuckkeyid"
accessKeySecret: "terceskcuf"
source: "qtt_core"
topic: "phonetracker"
```

### 持久化配置

- **断点续传**: 已启用，确保日志不丢失
- **本地缓存**: 最多65536条日志
- **文件大小**: 每个持久化文件最大1MB
- **文件数量**: 最多10个滚动文件
- **存储路径**: `Documents/log-phonetracker.dat`

## 自动收集的设备信息

每条日志都会自动包含以下设备和应用信息：

- `platform`: "iOS"
- `device_model`: 设备型号
- `system_version`: 系统版本
- `app_version`: 应用版本
- `build_number`: 构建号
- `sdk_version`: SDK版本
- `sdk_build`: SDK构建号
- `user_id`: 用户唯一标识

## 线程安全

`AliyunLogManager` 使用串行队列确保线程安全：

- 所有配置操作在同步队列中执行
- 日志发送在异步队列中执行，不阻塞主线程
- 支持多线程并发调用

## 错误处理

```swift
// 检查客户端状态
if AliyunLogManager.shared.isClientInitialized() {
    // 发送日志
    AliyunLogManager.shared.log("客户端已准备就绪")
} else {
    // 处理未初始化的情况
    print("客户端未初始化，请先调用初始化方法")
}

// 设置日志回调监听状态
AliyunLogManager.shared.logCallback = { message in
    print("日志状态: \(message)")
}
```

## 与现有SDK集成

```swift
// 在应用启动时集成
AliyunLogManager.integrateWithSDK()

// 在现有事件跟踪中使用
func trackEvent(name: String, parameters: [String: Any]?) {
    // 现有的事件跟踪逻辑
    DYMEventManager.shared.track(event: name, extra: parameters)
    
    // 同时发送到阿里云
    AliyunLogManager.shared.trackUserEvent(name, parameters: parameters)
}
```

## 最佳实践

1. **在应用启动时初始化**
   ```swift
   func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
       AliyunLogManager.shared.quickInit()
       return true
   }
   ```

2. **使用有意义的事件名称**
   ```swift
   // 好的示例
   AliyunLogManager.shared.sendEventLog(eventName: "user_purchase_completed")
   
   // 避免这样
   AliyunLogManager.shared.sendEventLog(eventName: "event1")
   ```

3. **合理使用额外信息**
   ```swift
   AliyunLogManager.shared.sendLogToAliyun(
       message: "用户完成购买",
       additionalContent: [
           "product_id": "premium_monthly",
           "price": "9.99",
           "payment_method": "apple_pay"
       ]
   )
   ```

4. **在应用退出时清理资源**
   ```swift
   func applicationWillTerminate(_ application: UIApplication) {
       AliyunLogManager.shared.destroyClient()
   }
   ```

## 注意事项

- 确保在网络可用时进行初始化
- 敏感信息不要记录在日志中
- 合理控制日志频率，避免过度发送
- 在生产环境中谨慎使用调试日志

## 问题排查

### 常见问题

1. **初始化失败**
   - 检查网络连接
   - 验证AccessKey信息
   - 确认endpoint地址正确

2. **日志发送失败**
   - 检查客户端是否已初始化
   - 验证项目和日志库配置
   - 查看错误日志回调

3. **性能问题**
   - 检查日志发送频率
   - 调整本地缓存配置
   - 使用异步发送避免阻塞

### 调试方法

```swift
// 启用详细日志
AliyunLogManager.shared.logCallback = { message in
    print("AliyunLog: \(message)")
}

// 检查初始化状态
print("Client initialized: \(AliyunLogManager.shared.isClientInitialized())")
``` 