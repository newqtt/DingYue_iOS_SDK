//
//  AliyunLogManager+Example.swift
//  DingYue_iOS_SDK
//
//  Created by DingYue SDK on 2025/01/03.
//

import Foundation

// MARK: - 使用示例和最佳实践
/*
 
 ## AliyunLogManager 使用示例
 
 ### 1. 基础使用
 
 ```swift
 // 使用默认配置快速初始化
 AliyunLogManager.shared.quickInit()
 
 // 或者使用自定义配置初始化
 let success = AliyunLogManager.shared.initializeAliyunLog(
     endpoint: "https://your-endpoint.aliyuncs.com",
     project: "your-project",
     logstore: "your-logstore",
     accessKeyId: "your-access-key-id",
     accessKeySecret: "your-access-key-secret",
     source: "your-app-name",
     topic: "your-topic"
 )
 
 if success {
     print("阿里云日志客户端初始化成功")
 }
 ```
 
 ### 2. 发送日志
 
 ```swift
 // 发送简单日志
 AliyunLogManager.shared.log("用户登录成功")
 
 // 发送带额外信息的日志
 AliyunLogManager.shared.sendLogToAliyun(
     message: "用户购买商品", 
     additionalContent: [
         "product_id": "premium_monthly",
         "price": "9.99",
         "currency": "USD"
     ]
 )
 
 // 发送事件日志
 AliyunLogManager.shared.sendEventLog(
     eventName: "button_click",
     eventData: [
         "button_name": "purchase_button",
         "screen": "paywall",
         "user_type": "free_user"
     ]
 )
 ```
 
 ### 3. 发送错误日志
 
 ```swift
 do {
     // 一些可能出错的操作
     try someRiskyOperation()
 } catch {
     AliyunLogManager.shared.logError(error, context: "用户购买流程")
 }
 ```
 
 ### 4. 调试日志
 
 ```swift
 func someFunction() {
     AliyunLogManager.shared.logDebug("开始执行某个重要操作")
     
     // 执行操作...
     
     AliyunLogManager.shared.logDebug("操作执行完成")
 }
 ```
 
 ### 5. 设置日志回调（可选）
 
 ```swift
 AliyunLogManager.shared.logCallback = { message in
     print("日志管理器: \(message)")
     // 可以在这里更新UI或执行其他操作
 }
 ```
 
 ### 6. 检查初始化状态
 
 ```swift
 if AliyunLogManager.shared.isClientInitialized() {
     AliyunLogManager.shared.log("客户端已准备就绪")
 } else {
     print("客户端未初始化")
 }
 ```
 
 ### 7. 销毁客户端（通常在应用退出时）
 
 ```swift
 AliyunLogManager.shared.destroyClient()
 ```
 
 */

// MARK: - 与现有SDK集成的示例
extension AliyunLogManager {
    
    /// 集成到现有的DYMobileSDK中的示例方法
    /// 可以在DYMobileSDK的相关位置调用
    public static func integrateWithSDK() {
        // 在SDK初始化时调用
        shared.quickInit()
        
        // 设置日志回调，与现有的DYMLogManager集成
        shared.logCallback = { message in
            DYMLogManager.logMessage("Aliyun: \(message)")
        }
        
        // 发送SDK初始化成功的日志
        shared.sendEventLog(
            eventName: "sdk_initialized",
            eventData: [
                "sdk_version": UserProperties.sdkVersion,
                "sdk_build": UserProperties.sdkVersionBuild
            ]
        )
    }
    
    /// 跟踪用户事件的便利方法
    /// 可以与现有的事件跟踪系统集成
    public func trackUserEvent(_ eventName: String, parameters: [String: Any]? = nil) {
        sendEventLog(eventName: eventName, eventData: parameters)
    }
    
    /// 跟踪购买事件
    public func trackPurchaseEvent(productId: String, price: String, currency: String, success: Bool) {
        sendEventLog(
            eventName: success ? "purchase_success" : "purchase_failed",
            eventData: [
                "product_id": productId,
                "price": price,
                "currency": currency,
                "timestamp": Date().timeIntervalSince1970
            ]
        )
    }
    
    /// 跟踪页面浏览事件
    public func trackPageView(pageName: String, duration: TimeInterval? = nil) {
        var eventData: [String: Any] = ["page_name": pageName]
        if let duration = duration {
            eventData["duration"] = duration
        }
        
        sendEventLog(eventName: "page_view", eventData: eventData)
    }
    
    /// 跟踪应用生命周期事件
    public func trackAppLifecycle(event: AppLifecycleEvent) {
        sendEventLog(
            eventName: "app_lifecycle",
            eventData: [
                "lifecycle_event": event.rawValue,
                "timestamp": Date().timeIntervalSince1970
            ]
        )
    }
}

// MARK: - 应用生命周期事件枚举
public enum AppLifecycleEvent: String {
    case launched = "app_launched"
    case backgrounded = "app_backgrounded"
    case foregrounded = "app_foregrounded"
    case terminated = "app_terminated"
    case memoryWarning = "memory_warning"
} 