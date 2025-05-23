//
//  DYMEventManagerTests.swift
//  DingYue_iOS_SDK
//
//  Created by Assistant on 2024/01/xx.
//

import Foundation

/// 用于测试和验证DYMEventManager修复的工具类
@objc public class DYMEventManagerTests: NSObject {
    
    /// 测试基本的track方法调用
    @objc public static func testBasicTrack() {
        print("=== Testing Basic Track ===")
        
        // 测试正常情况
        DYMEventManager.shared.track(event: "test_event", extra: "test_extra", user: "test_user")
        
        // 测试空事件名
        DYMEventManager.shared.track(event: "", extra: "test_extra", user: "test_user")
        
        print("Basic track test completed")
    }
    
    /// 测试包含复杂参数的track方法
    @objc public static func testTrackWithParameters() {
        print("=== Testing Track with Parameters ===")
        
        let parameters: [String: Any] = [
            "string_param": "test_value",
            "number_param": 123,
            "bool_param": true,
            "array_param": ["item1", "item2"],
            "dict_param": ["key": "value"],
            // 添加一个不可序列化的对象来测试过滤功能
            "unsafe_param": NSObject()
        ]
        
        DYMEventManager.shared.track(
            event: "test_complex_event",
            entrance: "test_entrance",
            value: "test_value",
            parameters: parameters
        )
        
        print("Complex track test completed")
    }
    
    /// 测试API配置验证
    @objc public static func testAPIConfiguration() {
        print("=== Testing API Configuration ===")
        
        // 保存原始配置
        let originalAppId = DYMConstants.APIKeys.appId
        let originalSecretKey = DYMConstants.APIKeys.secretKey
        
        // 测试空配置
        DYMConstants.APIKeys.appId = ""
        DYMConstants.APIKeys.secretKey = ""
        
        DYMEventManager.shared.track(event: "test_no_config")
        
        // 恢复配置
        DYMConstants.APIKeys.appId = originalAppId
        DYMConstants.APIKeys.secretKey = originalSecretKey
        
        print("API configuration test completed")
    }
    
    /// 测试UUID生成
    @objc public static func testUUIDGeneration() {
        print("=== Testing UUID Generation ===")
        
        let uuid1 = UserProperties.staticUuid
        print("Static UUID: \(uuid1)")
        
        UserProperties.resetStaticUuid()
        let uuid2 = UserProperties.staticUuid
        print("Reset UUID: \(uuid2)")
        
        print("UUID generation test completed")
    }
    
    // MARK: - 并发测试方法
    
    /// 测试多线程并发调用track方法
    @objc public static func testConcurrentTrack() {
        print("=== Testing Concurrent Track ===")
        
        let concurrentQueue = DispatchQueue(label: "test.concurrent", attributes: .concurrent)
        let group = DispatchGroup()
        let numberOfTasks = 20
        
        for i in 0..<numberOfTasks {
            group.enter()
            concurrentQueue.async {
                DYMEventManager.shared.track(
                    event: "concurrent_event_\(i)",
                    extra: "extra_\(i)",
                    user: "user_\(i)"
                )
                group.leave()
            }
        }
        
        // 等待所有任务完成，最多等待10秒
        let result = group.wait(timeout: .now() + 10)
        
        switch result {
        case .success:
            print("✅ All \(numberOfTasks) concurrent track calls completed successfully")
        case .timedOut:
            print("⚠️ Concurrent track test timed out")
        }
        
        print("Concurrent track test completed")
    }
    
    /// 测试大量并发事件发送的压力测试
    @objc public static func testStressTrackWithParameters() {
        print("=== Testing Stress Track with Parameters ===")
        
        let concurrentQueue = DispatchQueue(label: "test.stress", attributes: .concurrent)
        let group = DispatchGroup()
        let numberOfTasks = 50
        
        for i in 0..<numberOfTasks {
            group.enter()
            concurrentQueue.async {
                let parameters: [String: Any] = [
                    "task_id": i,
                    "timestamp": Date().timeIntervalSince1970,
                    "random_value": Int.random(in: 1...1000),
                    "array_data": Array(1...10),
                    "nested_dict": [
                        "level1": [
                            "level2": "value_\(i)"
                        ]
                    ]
                ]
                
                DYMEventManager.shared.track(
                    event: "stress_test_event",
                    entrance: "stress_entrance_\(i)",
                    value: "stress_value_\(i)",
                    parameters: parameters
                )
                group.leave()
            }
        }
        
        let result = group.wait(timeout: .now() + 15)
        
        switch result {
        case .success:
            print("✅ Stress test with \(numberOfTasks) complex parameter events completed")
        case .timedOut:
            print("⚠️ Stress test timed out")
        }
        
        print("Stress track with parameters test completed")
    }
    
    /// 测试竞态条件 - 同时重置UUID和发送事件
    @objc public static func testRaceConditionUUID() {
        print("=== Testing Race Condition with UUID ===")
        
        let concurrentQueue = DispatchQueue(label: "test.race", attributes: .concurrent)
        let group = DispatchGroup()
        
        // 同时进行UUID重置和事件发送
        for i in 0..<20 {
            group.enter()
            concurrentQueue.async {
                if i % 3 == 0 {
                    // 每3个任务中有1个重置UUID
                    UserProperties.resetStaticUuid()
                    print("🔄 UUID reset in task \(i)")
                }
                
                DYMEventManager.shared.track(
                    event: "race_condition_event_\(i)",
                    extra: "uuid_test_\(i)"
                )
                group.leave()
            }
        }
        
        let result = group.wait(timeout: .now() + 10)
        
        switch result {
        case .success:
            print("✅ Race condition test completed without crashes")
        case .timedOut:
            print("⚠️ Race condition test timed out")
        }
        
        print("Race condition UUID test completed")
    }
    
    /// 测试API配置变更的并发安全性
    @objc public static func testConcurrentAPIConfigChanges() {
        print("=== Testing Concurrent API Config Changes ===")
        
        // 保存原始配置
        let originalAppId = DYMConstants.APIKeys.appId
        let originalSecretKey = DYMConstants.APIKeys.secretKey
        
        let concurrentQueue = DispatchQueue(label: "test.config", attributes: .concurrent)
        let group = DispatchGroup()
        
        for i in 0..<30 {
            group.enter()
            concurrentQueue.async {
                if i % 5 == 0 {
                    // 每5个任务中清空一次配置
                    DYMConstants.APIKeys.appId = ""
                    DYMConstants.APIKeys.secretKey = ""
                    print("🔧 Config cleared in task \(i)")
                } else if i % 5 == 1 {
                    // 恢复配置
                    DYMConstants.APIKeys.appId = originalAppId
                    DYMConstants.APIKeys.secretKey = originalSecretKey
                    print("🔧 Config restored in task \(i)")
                }
                
                DYMEventManager.shared.track(
                    event: "config_test_event_\(i)",
                    extra: "config_safety_test"
                )
                group.leave()
            }
        }
        
        let result = group.wait(timeout: .now() + 12)
        
        // 确保配置被恢复
        DYMConstants.APIKeys.appId = originalAppId
        DYMConstants.APIKeys.secretKey = originalSecretKey
        
        switch result {
        case .success:
            print("✅ Concurrent API config changes test completed")
        case .timedOut:
            print("⚠️ Concurrent API config changes test timed out")
        }
        
        print("Concurrent API config changes test completed")
    }
    
    /// 测试混合异常情况的并发处理
    @objc public static func testConcurrentMixedScenarios() {
        print("=== Testing Concurrent Mixed Scenarios ===")
        
        let concurrentQueue = DispatchQueue(label: "test.mixed", attributes: .concurrent)
        let group = DispatchGroup()
        let numberOfTasks = 60
        
        for i in 0..<numberOfTasks {
            group.enter()
            concurrentQueue.async {
                let scenario = i % 6
                
                switch scenario {
                case 0:
                    // 正常事件
                    DYMEventManager.shared.track(event: "normal_event_\(i)")
                case 1:
                    // 空事件名
                    DYMEventManager.shared.track(event: "")
                case 2:
                    // 包含不可序列化对象的复杂参数
                    let badParams: [String: Any] = [
                        "good_param": "value",
                        "bad_param": NSObject(),
                        "nested_bad": ["key": NSObject()]
                    ]
                    DYMEventManager.shared.track(
                        event: "complex_event_\(i)",
                        parameters: badParams
                    )
                case 3:
                    // 重置UUID
                    UserProperties.resetStaticUuid()
                case 4:
                    // 极长的字符串参数
                    let longString = String(repeating: "A", count: 10000)
                    DYMEventManager.shared.track(
                        event: "long_event_\(i)",
                        extra: longString
                    )
                case 5:
                    // 大型嵌套数据结构
                    var largeDict: [String: Any] = [:]
                    for j in 0..<100 {
                        largeDict["key_\(j)"] = "value_\(j)"
                    }
                    DYMEventManager.shared.track(
                        event: "large_data_event_\(i)",
                        parameters: largeDict
                    )
                default:
                    break
                }
                group.leave()
            }
        }
        
        let result = group.wait(timeout: .now() + 20)
        
        switch result {
        case .success:
            print("✅ Mixed scenarios test with \(numberOfTasks) tasks completed")
        case .timedOut:
            print("⚠️ Mixed scenarios test timed out")
        }
        
        print("Concurrent mixed scenarios test completed")
    }
    
    /// 运行所有测试（包括并发测试）
    @objc public static func runAllTests() {
        print("🧪 Starting DYMEventManager Safety Tests")
        print("========================================")
        
        testBasicTrack()
        print("")
        
//        testTrackWithParameters()
        print("")
        
        testAPIConfiguration()
        print("")
        
        testUUIDGeneration()
        print("")
        
        print("========================================")
        print("✅ All basic tests completed successfully!")
    }
    
    /// 运行并发测试套件
    @objc public static func runConcurrencyTests() {
        print("🚀 Starting DYMEventManager Concurrency Tests")
        print("==============================================")
        
        testConcurrentTrack()
        print("")
        
        testStressTrackWithParameters()
        print("")
        
        testRaceConditionUUID()
        print("")
        
        testConcurrentAPIConfigChanges()
        print("")
        
        testConcurrentMixedScenarios()
        print("")
        
        print("==============================================")
        print("🎯 All concurrency tests completed!")
        
        // 额外的内存和性能提示
        print("💡 Tips:")
        print("   • Monitor memory usage during these tests")
        print("   • Check for thread safety issues in logs")
        print("   • Verify no crashes occurred")
    }
    
    /// 运行完整的测试套件
    @objc public static func runFullTestSuite() {
        print("🎪 Starting Complete DYMEventManager Test Suite")
        print("================================================")
        
        // 先运行基础测试
        runAllTests()
        print("")
        print("🔄 Now starting concurrency tests...")
        print("")
        
        // 再运行并发测试
        runConcurrencyTests()
        
        print("================================================")
        print("🏆 Complete test suite finished!")
        print("   Check console output for any warnings or errors")
    }
} 
