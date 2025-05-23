//
//  DYMobileSDK+AliyunLog.swift
//  DingYue_iOS_SDK
//
//  Created by DingYue SDK on 2025/01/03.
//

import Foundation

// MARK: - DYMobileSDK 阿里云日志扩展
extension DYMobileSDK {
    
    // MARK: - 阿里云日志配置
    
    /// 阿里云日志是否启用
    @objc public static var aliyunLogEnabled: Bool = false {
        didSet {
            if aliyunLogEnabled {
                initializeAliyunLogIfNeeded()
            } else {
                AliyunLogManager.shared.destroyClient()
            }
        }
    }
    
    /// 初始化阿里云日志（如果需要）
    private static func initializeAliyunLogIfNeeded() {
        guard aliyunLogEnabled && !AliyunLogManager.shared.isClientInitialized() else {
            return
        }
        
        // 使用默认配置初始化
        let success = AliyunLogManager.shared.quickInit()
        
        if success {
            DYMLogManager.logMessage("阿里云日志服务初始化成功")
            
            // 设置日志回调
            AliyunLogManager.shared.logCallback = { message in
                DYMLogManager.logMessage("AliyunLog: \(message)")
            }
            
            // 发送SDK启动日志
            AliyunLogManager.shared.sendEventLog(
                eventName: "sdk_started",
                eventData: [
                    "sdk_version": UserProperties.sdkVersion,
                    "sdk_build": UserProperties.sdkVersionBuild,
                    "platform": "iOS"
                ]
            )
        } else {
            DYMLogManager.logError("阿里云日志服务初始化失败")
        }
    }
    
    // MARK: - 阿里云日志方法
    
    /// 发送自定义日志到阿里云
    /// - Parameters:
    ///   - message: 日志消息
    ///   - additionalData: 附加数据
    @objc public class func sendAliyunLog(_ message: String, additionalData: [String: String]? = nil) {
        guard aliyunLogEnabled else { return }
        AliyunLogManager.shared.sendLogToAliyun(message: message, additionalContent: additionalData)
    }
    
    /// 发送事件日志到阿里云
    /// - Parameters:
    ///   - eventName: 事件名称
    ///   - eventData: 事件数据
    @objc public class func sendAliyunEventLog(_ eventName: String, eventData: [String: Any]? = nil) {
        guard aliyunLogEnabled else { return }
        AliyunLogManager.shared.sendEventLog(eventName: eventName, eventData: eventData)
    }
    
    /// 发送错误日志到阿里云
    /// - Parameters:
    ///   - error: 错误对象
    ///   - context: 错误上下文
    @objc public class func sendAliyunErrorLog(_ error: NSError, context: String? = nil) {
        guard aliyunLogEnabled else { return }
        AliyunLogManager.shared.logError(error, context: context)
    }
    
    /// 使用自定义配置初始化阿里云日志
    /// - Parameters:
    ///   - endpoint: 阿里云日志服务endpoint
    ///   - project: 项目名称
    ///   - logstore: 日志库名称
    ///   - accessKeyId: AccessKey ID
    ///   - accessKeySecret: AccessKey Secret
    ///   - source: 日志来源标识
    ///   - topic: 日志主题
    /// - Returns: 初始化是否成功
    @objc @discardableResult
    public class func initializeAliyunLog(
        endpoint: String,
        project: String,
        logstore: String,
        accessKeyId: String,
        accessKeySecret: String,
        source: String = "qtt_core",
        topic: String = "phonetracker"
    ) -> Bool {
        aliyunLogEnabled = true
        
        let success = AliyunLogManager.shared.initializeAliyunLog(
            endpoint: endpoint,
            project: project,
            logstore: logstore,
            accessKeyId: accessKeyId,
            accessKeySecret: accessKeySecret,
            source: source,
            topic: topic
        )
        
        if success {
            // 设置日志回调
            AliyunLogManager.shared.logCallback = { message in
                DYMLogManager.logMessage("AliyunLog: \(message)")
            }
        }
        
        return success
    }
}

// MARK: - 内部日志集成
extension DYMobileSDK {
    
    /// 内部方法：发送会话事件到阿里云
    internal static func logSessionEvent(_ eventName: String, data: [String: Any]? = nil) {
        guard aliyunLogEnabled else { return }
        
        var eventData = data ?? [:]
        eventData["event_category"] = "session"
        eventData["user_id"] = UserProperties.requestUUID
        
        AliyunLogManager.shared.sendEventLog(eventName: eventName, eventData: eventData)
    }
    
    /// 内部方法：发送购买事件到阿里云
    internal static func logPurchaseEvent(
        productId: String,
        price: String?,
        success: Bool,
        errorMessage: String? = nil
    ) {
        guard aliyunLogEnabled else { return }
        
        var eventData: [String: Any] = [
            "product_id": productId,
            "success": success,
            "event_category": "purchase"
        ]
        
        if let price = price {
            eventData["price"] = price
        }
        
        if let errorMessage = errorMessage {
            eventData["error_message"] = errorMessage
        }
        
        let eventName = success ? "purchase_success" : "purchase_failed"
        AliyunLogManager.shared.sendEventLog(eventName: eventName, eventData: eventData)
    }
    
    /// 内部方法：发送用户行为事件到阿里云
    internal static func logUserBehaviorEvent(_ eventName: String, extra: String? = nil, user: String? = nil) {
        guard aliyunLogEnabled else { return }
        
        var eventData: [String: Any] = [
            "event_category": "user_behavior",
            "user_id": UserProperties.requestUUID
        ]
        
        if let extra = extra {
            eventData["extra"] = extra
        }
        
        if let user = user {
            eventData["associated_user"] = user
        }
        
        AliyunLogManager.shared.sendEventLog(eventName: eventName, eventData: eventData)
    }
    
    /// 内部方法：发送API调用事件到阿里云
    internal static func logAPIEvent(
        apiName: String,
        success: Bool,
        responseTime: TimeInterval? = nil,
        statusCode: String? = nil,
        errorMessage: String? = nil
    ) {
        guard aliyunLogEnabled else { return }
        
        var eventData: [String: Any] = [
            "api_name": apiName,
            "success": success,
            "event_category": "api_call"
        ]
        
        if let responseTime = responseTime {
            eventData["response_time"] = responseTime
        }
        
        if let statusCode = statusCode {
            eventData["status_code"] = statusCode
        }
        
        if let errorMessage = errorMessage {
            eventData["error_message"] = errorMessage
        }
        
        let eventName = success ? "api_call_success" : "api_call_failed"
        AliyunLogManager.shared.sendEventLog(eventName: eventName, eventData: eventData)
    }
}

// MARK: - 应用生命周期事件集成
extension DYMobileSDK {
    
    /// 应用启动时调用（建议在activate方法中调用）
    internal static func logAppLaunchEvent() {
        guard aliyunLogEnabled else { return }
        
        let eventData: [String: Any] = [
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            "build_number": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown",
            "sdk_version": UserProperties.sdkVersion,
            "device_model": UIDevice.current.model,
            "system_version": UIDevice.current.systemVersion,
            "event_category": "app_lifecycle"
        ]
        
        AliyunLogManager.shared.sendEventLog(eventName: "app_launch", eventData: eventData)
    }
    
    /// 应用进入后台时调用
    @objc public class func logAppBackgroundEvent() {
        AliyunLogManager.shared.trackAppLifecycle(event: .backgrounded)
    }
    
    /// 应用进入前台时调用
    @objc public class func logAppForegroundEvent() {
        AliyunLogManager.shared.trackAppLifecycle(event: .foregrounded)
    }
    
    /// 应用内存警告时调用
    @objc public class func logMemoryWarningEvent() {
        AliyunLogManager.shared.trackAppLifecycle(event: .memoryWarning)
    }
}

// MARK: - 示例集成方法
extension DYMobileSDK {
    
    /// 示例：如何在现有的track方法中集成阿里云日志
    internal static func enhancedTrack(event: String, extra: String? = nil, user: String? = nil) {
        // 调用原有的track方法
        track(event: event, extra: extra, user: user)
        
        // 同时发送到阿里云（如果启用）
        logUserBehaviorEvent(event, extra: extra, user: user)
    }
    
    /// 示例：如何在现有的purchase方法中集成阿里云日志
    /// 这个方法展示了如何在购买流程中添加日志记录
    internal static func enhancedPurchaseTracking(
        productId: String,
        success: Bool,
        receipt: String?,
        purchaseResult: [[String: Any]]?,
        error: Error?
    ) {
        // 提取价格信息（如果可用）
        var price: String?
        if let purchaseResult = purchaseResult, !purchaseResult.isEmpty {
            // 尝试从购买结果中提取价格信息
            price = purchaseResult.first?["price"] as? String
        }
        
        // 发送购买事件到阿里云
        logPurchaseEvent(
            productId: productId,
            price: price,
            success: success,
            errorMessage: error?.localizedDescription
        )
        
        // 如果购买成功，发送额外的成功事件
        if success {
            sendAliyunEventLog("purchase_completed", eventData: [
                "product_id": productId,
                "has_receipt": receipt != nil,
                "purchase_result_count": purchaseResult?.count ?? 0
            ])
        }
    }
} 