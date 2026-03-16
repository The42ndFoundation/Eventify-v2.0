//
//  Localization.swift
//  Eventify
//
//  Copyright © 2026 The42nd Foundation. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//

import Foundation

// MARK: - Localization Helper
extension String {
    /// 获取本地化字符串
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    /// 获取带参数的本地化字符串
    func localized(with arguments: CVarArg...) -> String {
        return String(format: NSLocalizedString(self, comment: ""), arguments: arguments)
    }
}

// MARK: - Localization Keys
struct L10n {
    
    // MARK: - App
    struct App {
        static var title: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? "Eventify" : "Eventify"
        }
        static var subtitle: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? "智能日历助手" : "Smart Calendar Assistant"
        }
        static var description: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? 
            "输入课程表文字或简单事件描述，本地解析器将自动识别并添加到日历" : 
            "Enter timetable text or simple event descriptions, local parser will automatically identify and add to calendar"
        }
    }
    
    // MARK: - Input
    struct Input {
        static var title: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? "时间安排描述" : "Schedule Description"
        }
        static var placeholder: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? 
            "例如：COMP 1234 - Mo 10:00AM-12:00PM\nRoom 101\n01/09/2025 - 15/12/2025\n\n或：游泳 9.13 2:00-4:00" : 
            "e.g.: COMP 1234 - Mo 10:00AM-12:00PM\nRoom 101\n01/09/2025 - 15/12/2025\n\nor: Swimming 9.13 2:00-4:00"
        }
    }
    
    // MARK: - Image
    struct Image {
        static var title: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? "或上传截图" : "or Upload Screenshot"
        }
        static var button: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? "选择图片" : "Select Image"
        }
        static var selected: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? "已选择图片" : "Image Selected"
        }
        static var ready: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? "图片已准备" : "Image Ready"
        }
        static var instruction: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? "点击解析按钮开始识别" : "Click parse button to start recognition"
        }
        static var delete: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? "删除" : "Delete"
        }
    }
    
    // MARK: - Parse
    struct Parse {
        static var button: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? "开始解析" : "Start Parsing"
        }
        static var loading: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? "智能解析中..." : "Smart Parsing..."
        }
    }
    
    // MARK: - Errors
    struct Error {
        static var noInput: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? "请输入文字描述或选择一张图片" : "Please enter text description or select an image"
        }
        static var imageProcessing: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? "无法处理图片数据" : "Unable to process image data"
        }
        static var noEvents: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? "未能从输入中识别到任何事件" : "No events identified from input"
        }
        static var unsupportedFormat: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? "不支持的文本格式，请使用标准课程表格式或简单事件格式" : "Unsupported text format, please use standard timetable format or simple event format"
        }
        static var imageNotSupported: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? "本地版本不支持图片识别，请使用文字描述" : "Local version does not support image recognition, please use text description"
        }
        
        static func parseFailed(_ message: String) -> String {
            let format = Locale.current.language.languageCode?.identifier == "zh" ? "解析失败：%@" : "Parse failed: %@"
            return String(format: format, message)
        }
        
        static func loadImageFailed(_ message: String) -> String {
            let format = Locale.current.language.languageCode?.identifier == "zh" ? "加载图片失败：%@" : "Failed to load image: %@"
            return String(format: format, message)
        }
    }
    
    // MARK: - Confirm
    struct Confirm {
        static var title: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? "确认事件" : "Confirm Events"
        }
        static var cancel: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? "取消" : "Cancel"
        }
        static var save: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? "添加到日历" : "Add to Calendar"
        }
        static var warnings: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? "解析警告" : "Parse Warnings"
        }
        static var events: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? "事件" : "Events"
        }
        static var addEvent: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? "添加事件" : "Add Event"
        }
        static var saveToCalendar: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? "保存到日历" : "Save to Calendar"
        }
        static var saving: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? "保存中..." : "Saving..."
        }
        static var aiReparse: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? "AI重新识别" : "AI Re-identify"
        }
        static var aiReparsing: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? "AI识别中..." : "AI Identifying..."
        }
        static func aiReparseFailed(_ message: String) -> String {
            let format = Locale.current.language.languageCode?.identifier == "zh" ? "AI解析失败：%@" : "AI parsing failed: %@"
            return String(format: format, message)
        }
        static var aiNoEvents: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? "AI未能识别到任何事件" : "AI failed to identify any events"
        }
    }
    
    // MARK: - Event
    struct Event {
        static var title: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? "事件标题" : "Event Title"
        }
        static var allDay: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? "全天事件" : "All Day Event"
        }
        static var startTime: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? "开始时间" : "Start Time"
        }
        static var endTime: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? "结束时间" : "End Time"
        }
        static var location: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? "地点（可选）" : "Location (Optional)"
        }
        static var notes: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? "备注（可选）" : "Notes (Optional)"
        }
        static var delete: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? "删除事件" : "Delete Event"
        }
        static var newEvent: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? "新事件" : "New Event"
        }
        static var unknownLocation: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? "未知地点" : "Unknown Location"
        }
    }
    
    // MARK: - Calendar
    struct Calendar {
        static func success(_ count: Int) -> String {
            let format = Locale.current.language.languageCode?.identifier == "zh" ? "✅ 成功添加 %d 个事件到日历" : "✅ Successfully added %d events to calendar"
            return String(format: format, count)
        }
        
        static func failed(_ message: String) -> String {
            let format = Locale.current.language.languageCode?.identifier == "zh" ? "❌ 添加失败：%@" : "❌ Failed to add: %@"
            return String(format: format, message)
        }
        
        static var accessDenied: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? "需要日历访问权限才能添加事件。请在设置中允许应用访问日历。" : "Calendar access permission required to add events. Please allow calendar access in Settings."
        }
        static var noCalendar: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? "未找到可用日历" : "No available calendar found"
        }
        static var invalidDate: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? "事件时间范围无效" : "Invalid event time range"
        }
        
        static func saveFailed(_ message: String) -> String {
            let format = Locale.current.language.languageCode?.identifier == "zh" ? "保存失败：%@" : "Save failed: %@"
            return String(format: format, message)
        }
    }
    
    // MARK: - Permission
    struct Permission {
        static var calendar: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? "此应用需要访问日历以添加事件" : "This app needs access to calendar to add events"
        }
        static var photo: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? "此应用需要访问相册以选择图片" : "This app needs access to photo library to select images"
        }
    }
    
    // MARK: - Result
    struct Result {
        static var title: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? "操作结果" : "Operation Result"
        }
        static var confirm: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? "确定" : "OK"
        }
    }
    
    // MARK: - General
    struct General {
        static var retry: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? "重试" : "Retry"
        }
        static var deleteConfirm: String {
            return Locale.current.language.languageCode?.identifier == "zh" ? "确定要删除这个事件吗？" : "Are you sure you want to delete this event?"
        }
    }
}