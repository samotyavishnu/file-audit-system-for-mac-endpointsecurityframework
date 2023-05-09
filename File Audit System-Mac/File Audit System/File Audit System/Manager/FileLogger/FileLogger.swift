//
//  FileLogger.swift
//  File Audit System
//
//  Created by Vishnu Kumar Sharma on 07/05/23.
//  Copyright © 2023 Vishnu Kumar Sharma. All rights reserved.
//

import Foundation

fileprivate let defaultLogFilePath = "/var/log/fileauditsystem.log"
fileprivate let dispatchQueue = DispatchQueue(label: "com.vishnu.fileauditsystem.file-logger")

final class FileLoggerContext {
    var logFileURL = URL(fileURLWithPath: "")
}

final class FileLogger {
    var context = FileLoggerContext()
    
    func logMessage(message: String) {
        if !FileLogger.logMessage(context: context, message: message) {
            
            printErrorMessage(message: "Failed to write to the log file")
            print("info: \(message)")
        }
    }
    
    func setConfiguration(newPath: String?) {
        dispatchQueue.sync {
            FileLogger.readConfiguration(context: &context, newPath: newPath)
        }
    }
    
    func getLogFileURL(completion: (URL?)-> Void) {
        dispatchQueue.sync {
            completion(context.logFileURL)
        }
    }
    
    private func printErrorMessage(message: String) {
        fputs("\(message)\n", stderr)
    }
    
    static func readConfiguration(context: inout FileLoggerContext, newPath: String?) {
        if let newPath = newPath {
            context.logFileURL = URL(fileURLWithPath: newPath)
        } else {
            context.logFileURL = URL(fileURLWithPath: defaultLogFilePath)
        }
    }
    
    static func generateLogMessage(message: String) -> String {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MMM-dd HH:mm:ss"
        
        let timestamp = dateFormatter.string(from: Date())
        let severity = "information"
        
        return String(format: "{ \"timestamp\": \"\(timestamp)\", \"type\": \"message\", \"severity\": \"\(severity)\", \"message\": \(message) }\n")
    }
    
    static func logMessage(context: FileLoggerContext, message: String) -> Bool {
        
        let message = FileLogger.generateLogMessage(message: message)
        
        var succeeded = false
        
        dispatchQueue.sync {
            if let fileHandle = try? FileHandle(forWritingTo: context.logFileURL) {
                fileHandle.seekToEndOfFile()
                let messageData = message.data(using: .utf8)!
                fileHandle.write(messageData)
                fileHandle.closeFile()
                succeeded = true
            } else {
                do {
                    try message.write(to: context.logFileURL, atomically: true, encoding: .utf8)
                    succeeded = true
                } catch {
                }
            }
        }
        return succeeded
    }
}
