//
//  AuditFile.swift
//  File Audit System
//
//  Created by Vishnu Kumar Sharma on 28/04/23.
//  Copyright © 2023 Vishnu Kumar Sharma. All rights reserved.
//

import Foundation
import Cocoa
import EndpointSecurity

class AuditFile {
    
    //#MARK: PROPERTIES
    var event: es_event_type_t?
    var timestamp: Date?
    var sourcePath: String?
    var destinationPath: String?
    var process: AuditProcess?
    
    //#MARK: METHODS
    
    init(message: es_message_t) {
        var auditToken: NSData?
        
        //set type
        self.event = message.event_type
        
        //set timestamp
        self.timestamp = Date()
        
        //init audit token
        auditToken = NSData(bytes: &message.process.pointee.audit_token, length: MemoryLayout.size(ofValue: audit_token_t()))
        
        //check cache for process
        // not found? create process obj...
        if let auditToken = auditToken {
            self.process = processCache.object(forKey: auditToken)
        }
        
        if self.process == nil {
            //create process
            self.process = AuditProcess(message: message)
        }
        
        if let process = self.process, let auditToken = auditToken {
            processCache.setObject(process, forKey: auditToken)
        }
        self.getPaths(message: message)
    }
    
    
    func getPaths(message: es_message_t) {
        //event specific logic
        switch (message.event_type) {
            //create
        case ES_EVENT_TYPE_NOTIFY_CREATE:
            
            //directory
            var directory: String?
            
            //file name
            var fileName: String?
            
            //existing file?
            // grab file path
            if ES_DESTINATION_TYPE_EXISTING_FILE == message.event.create.destination_type {
                //set path
                self.destinationPath = convertStringToken(message.event.create.destination.existing_file.pointee.path)
            }
            //new file
            // build file path from directory + name
            else {
                //extract directory
                directory = convertStringToken(message.event.create.destination.new_path.dir.pointee.path)
                
                //extact file name
                fileName = convertStringToken(message.event.create.destination.new_path.filename)
                
                //combine
                if let fileName = fileName {
                    self.destinationPath = (directory as? NSString)?.appendingPathComponent(fileName)
                }
            }
            
            //open
        case ES_EVENT_TYPE_NOTIFY_OPEN:
            
            //set path
            self.destinationPath = convertStringToken(message.event.open.file.pointee.path)
            
            //write
        case ES_EVENT_TYPE_NOTIFY_WRITE:
            
            //set path
            self.destinationPath = convertStringToken(message.event.write.target.pointee.path)
            
            //close
        case ES_EVENT_TYPE_NOTIFY_CLOSE:
            
            //set path
            self.destinationPath = convertStringToken(message.event.close.target.pointee.path)
            
            //link
        case ES_EVENT_TYPE_NOTIFY_LINK:
            
            //set (src) path
            self.sourcePath = convertStringToken(message.event.link.source.pointee.path)
            
            //set (dest) path
            // combine dest dir + dest file
            self.destinationPath = (convertStringToken(message.event.link.target_dir.pointee.path) as NSString).appendingPathComponent(convertStringToken(message.event.link.target_filename))
            
            //rename
        case ES_EVENT_TYPE_NOTIFY_RENAME:
            
            //set (src) path
            self.sourcePath = convertStringToken(message.event.rename.source.pointee.path)
            
            //existing file ('ES_DESTINATION_TYPE_EXISTING_FILE')
            if(ES_DESTINATION_TYPE_EXISTING_FILE == message.event.rename.destination_type)
            {
                //set (dest) file
                self.destinationPath = convertStringToken(message.event.rename.destination.existing_file.pointee.path)
            }
            //new path ('ES_DESTINATION_TYPE_NEW_PATH')
            else {
                //set (dest) path
                // combine dest dir + dest file
                self.destinationPath = (convertStringToken(message.event.rename.destination.new_path.dir.pointee.path) as NSString).appendingPathComponent(convertStringToken(message.event.rename.destination.new_path.filename))
            }
            
            //unlink
        case ES_EVENT_TYPE_NOTIFY_UNLINK:
            
            //set path
            self.destinationPath = convertStringToken(message.event.unlink.target.pointee.path)
        default:
            break
        }
    }
    
    
    func description()-> String {
        var eventName = ""
        let timestamp = String(describing: timestamp)
        let sourcePath = sourcePath ?? ""
        let destinationPath = destinationPath ?? ""
        let processDescription = process?.description() ?? ""
        let fileName = (destinationPath as NSString).lastPathComponent
        
        switch self.event {
            //create
        case ES_EVENT_TYPE_NOTIFY_CREATE:
            eventName = "ES_EVENT_TYPE_NOTIFY_CREATE"
            //open
        case ES_EVENT_TYPE_NOTIFY_OPEN:
            eventName = "ES_EVENT_TYPE_NOTIFY_OPEN"
            //write
        case ES_EVENT_TYPE_NOTIFY_WRITE:
            eventName = "ES_EVENT_TYPE_NOTIFY_WRITE"
            //close
        case ES_EVENT_TYPE_NOTIFY_CLOSE:
            eventName = "ES_EVENT_TYPE_NOTIFY_CLOSE"
            //rename
        case ES_EVENT_TYPE_NOTIFY_RENAME:
            eventName = "ES_EVENT_TYPE_NOTIFY_RENAME"
            //link
        case ES_EVENT_TYPE_NOTIFY_LINK:
            eventName = "ES_EVENT_TYPE_NOTIFY_LINK"
            //unlink
        case ES_EVENT_TYPE_NOTIFY_UNLINK:
            eventName = "ES_EVENT_TYPE_NOTIFY_UNLINK"
        default:
            break
        }
        
        return "{ \"event\": \"\(eventName)\", \"timestamp\":\"\(timestamp)\",\"file\":{ \"name\":\"\(fileName)\",\"source\":\"\(sourcePath)\",\"destination\":\"\(destinationPath)\",\"process\":\(processDescription)}}"
    }
    
    
}
