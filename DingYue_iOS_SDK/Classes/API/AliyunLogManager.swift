//
//  AliyunLogManager.swift
//  DingYue_iOS_SDK
//
//  Created by DingYue SDK on 2025/01/03.
//

import Foundation
import AliyunLogProducer

/// 阿里云日志管理器 - 单例类
/// 负责管理阿里云日志SDK的初始化和日志发送功能
public class AliyunLogManager {
    
    // MARK: - 单例
    /// 单例实例
    public static let shared = AliyunLogManager()
    
    // MARK: - 私有属性
    /// 阿里云日志客户端
    private var aliClient: LogProducerClient?
    
    /// 是否已经初始化
    private var isInitialized: Bool = false
    
    /// 线程安全队列
    private let syncQueue = DispatchQueue(label: "com.dingyue.aliyun.log", qos: .utility)
    
    /// 日志记录回调
    public var logCallback: ((String) -> Void)?
    
    // MARK: - 初始化
    private init() {
        DYMLogManager.logMessage("AliyunLogManager 实例已创建")
    }
    
    // MARK: - 公共方法
    
    /// 初始化阿里云日志客户端
    /// - Parameters:
    ///   - endpoint: 阿里云日志服务endpoint
    ///   - project: 项目名称
    ///   - logstore: 日志库名称
    ///   - accessKeyId: AccessKey ID
    ///   - accessKeySecret: AccessKey Secret
    ///   - source: 日志来源标识，默认为"qtt_core"
    ///   - topic: 日志主题，默认为"phonetracker"
    /// - Returns: 初始化是否成功
    @discardableResult
    public func initializeAliyunLog(
        endpoint: String = "https://aigolden.info",
        project: String = "ios-log-event",
        logstore: String = "events",
        accessKeyId: String = "fuckkeyid",
        accessKeySecret: String = "terceskcuf",
        source: String = "qtt_core",
        topic: String = "phonetracker"
    ) -> Bool {
        return syncQueue.sync {
            addLog("正在初始化阿里云日志客户端...")
            
            // 如果已经初始化，先销毁之前的实例
            if isInitialized {
                addLog("检测到已存在的客户端，正在重新初始化...")
                aliClient = nil
                isInitialized = false
            }
            
            // 创建配置对象
            guard let config = LogProducerConfig(
                endpoint: endpoint,
                project: project,
                logstore: logstore,
                accessKeyID: accessKeyId,
                accessKeySecret: accessKeySecret
            ) else {
                addLog("错误: 创建LogProducerConfig失败")
                return false
            }
            
            // 设置配置参数
            configureLogProducer(config: config, source: source, topic: topic)
            
            // 创建客户端
            aliClient = LogProducerClient(logProducerConfig: config)
            
            if aliClient != nil {
                isInitialized = true
                addLog("阿里云日志客户端初始化成功")
                return true
            } else {
                addLog("错误: 阿里云日志客户端初始化失败")
                return false
            }
        }
    }
    
    /// 发送日志到阿里云
    /// - Parameters:
    ///   - message: 日志消息内容
    ///   - additionalContent: 额外的日志内容字典
    public func sendLogToAliyun(message: String, additionalContent: [String: String]? = nil) {
        syncQueue.async { [weak self] in
            guard let self = self else { return }
            
            let timestamp = self.getCurrentTimestamp()
            let finalMessage = "\(message) - \(timestamp)"
            
            // 检查客户端是否已初始化
            guard let client = self.aliClient, self.isInitialized else {
                self.addLog("错误: 阿里云客户端未初始化，无法发送日志")
                return
            }
            
            // 创建日志对象
            let log = Log()
            let logTime = Date().timeIntervalSince1970
            log.setTime(useconds_t(logTime))
            
            // 添加基础内容
            log.putContent("event", value: finalMessage)
            log.putContent("timestamp", value: timestamp)
            
            // 添加额外内容
            if let additionalContent = additionalContent {
                for (key, value) in additionalContent {
                    log.putContent(key, value: value)
                }
            }
            
            // 添加设备信息
            self.addDeviceInfo(to: log)
            
            // 发送日志
            client.add(log)
            
            self.addLog("成功发送日志到阿里云: \(finalMessage)")
            DYMLogManager.logMessage("发送日志到阿里云: \(finalMessage)")
        }
    }
    
    /// 发送自定义事件日志
    /// - Parameters:
    ///   - eventName: 事件名称
    ///   - eventData: 事件数据字典
    public func sendEventLog(eventName: String, eventData: [String: Any]? = nil) {
        var content: [String: String] = [
            "event_name": eventName,
        ]
        
        // 转换事件数据
        if let eventData = eventData {
            for (key, value) in eventData {
                content["\(key)"] = "\(value)"
            }
        }
        
        sendLogToAliyun(message: "Event: \(eventName)", additionalContent: content)
    }
    
    /// 检查客户端是否已初始化
    /// - Returns: 是否已初始化
    public func isClientInitialized() -> Bool {
        return syncQueue.sync {
            return isInitialized && aliClient != nil
        }
    }
    
    /// 销毁阿里云日志客户端
    public func destroyClient() {
        syncQueue.sync {
            if isInitialized {
                aliClient = nil
                isInitialized = false
                addLog("阿里云日志客户端已销毁")
            }
        }
    }
    
    // MARK: - 私有方法
    
    /// 配置日志生产者
    private func configureLogProducer(config: LogProducerConfig, source: String, topic: String) {
        // 设置主题和来源
        config.setSource(source)
        config.setTopic(topic)
        
        // 开启断点续传功能
        config.setPersistent(1)
        
        // 设置持久化文件路径
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let persistentFilePath = "\(documentsPath)/log-phonetracker.dat"
        config.setPersistentFilePath(persistentFilePath)
        
        // 每次AddLog强制刷新，高可靠性场景建议打开
        config.setPersistentForceFlush(0)
        
        // 持久化文件滚动个数，建议设置成10
        config.setPersistentMaxFileCount(10)
        
        // 每个持久化文件的大小，建议设置成1-10M
        config.setPersistentMaxFileSize(1024 * 1024)
        
        // 本地最多缓存的日志数，不建议超过1M，通常设置为65536即可
        config.setPersistentMaxLogCount(65536)
        
        // 设置时间获取函数
        config.setGetTimeUnixFunc { () -> UInt32 in
            let time = Date().timeIntervalSince1970
            return UInt32(time)
        }
    }
    
    /// 添加设备信息到日志
    private func addDeviceInfo(to log: Log) {
        // 添加设备基础信息
        log.putContent("platform", value: "iOS")
        log.putContent("device_model", value: UIDevice.current.model)
        log.putContent("system_version", value: UIDevice.current.systemVersion)
        
        // 添加应用信息
        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            log.putContent("app_version", value: appVersion)
        }
        
        if let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            log.putContent("build_number", value: buildNumber)
        }
        
        // 添加SDK版本信息
        log.putContent("sdk_version", value: UserProperties.sdkVersion)
        log.putContent("sdk_build", value: "\(UserProperties.sdkVersionBuild)")
        
        // 添加用户标识
        log.putContent("user_id", value: UserProperties.requestUUID)
    }
    
    /// 获取当前时间戳字符串
    private func getCurrentTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: Date())
    }
    
    /// 添加日志记录
    private func addLog(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.logCallback?(message)
            DYMLogManager.logMessage("AliyunLogManager: \(message)")
        }
    }
}

// MARK: - 便利方法扩展
extension AliyunLogManager {
    
    /// 快速初始化（使用默认参数）
    @discardableResult
    public func quickInit() -> Bool {
        return initializeAliyunLog()
    }
    
    /// 发送简单的文本日志
    public func log(_ message: String) {
        sendLogToAliyun(message: message)
    }
    
    /// 发送错误日志
    public func logError(_ error: Error, context: String? = nil) {
        var content: [String: String] = [
            "error_description": error.localizedDescription,
            "error_type": "error"
        ]
        
        if let context = context {
            content["error_context"] = context
        }
        
        sendLogToAliyun(message: "Error: \(error.localizedDescription)", additionalContent: content)
    }
    
    /// 发送调试日志
    public func logDebug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        let content: [String: String] = [
            "debug_file": fileName,
            "debug_function": function,
            "debug_line": "\(line)",
            "log_level": "debug"
        ]
        
        sendLogToAliyun(message: "Debug: \(message)", additionalContent: content)
    }
} 
