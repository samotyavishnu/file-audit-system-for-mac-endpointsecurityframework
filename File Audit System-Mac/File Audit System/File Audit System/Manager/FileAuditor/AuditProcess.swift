//
//  AuditProcess.swift
//  File Audit System
//
//  Created by Vishnu Kumar Sharma on 28/04/23.
//  Copyright © 2023 Vishnu Kumar Sharma. All rights reserved.
//

import Foundation
import Cocoa
import EndpointSecurity

class AuditProcess {
    
    //#MARK: PROPERTIES
    
    var timestamp: Date?
    var event: es_event_type_t?
    var pid: pid_t?
    var ppid: pid_t?
    var rpid: pid_t?
    var uid: uid_t?
    var name: String?
    var path: String?
    var signingID: String?
    var teamID: String?
    
    
    init(message: es_message_t) {
        //process from msg
        var process: UnsafeMutablePointer<es_process_t>?
        
        //set start time
        self.timestamp = Date()
        
        //set type
        self.event = message.event_type
        
        switch message.event_type {
            //exec
        case ES_EVENT_TYPE_AUTH_EXEC:
            break
        case ES_EVENT_TYPE_NOTIFY_EXEC:
            //set process (target)
            process = message.event.exec.target
        case ES_EVENT_TYPE_NOTIFY_FORK:
            //set process (child)
            process = message.event.fork.child
        case ES_EVENT_TYPE_NOTIFY_EXIT:
            //set process
            process = message.process
        default:
            //set process
            process = message.process
        }
        
        //init pid
        if let auditToken = process?.pointee.audit_token {
            self.pid = audit_token_to_pid(auditToken)
        }
        
        //init ppid
        self.ppid = process?.pointee.ppid
        
        //init rpid
        if message.version >= 4, let auditToken = process?.pointee.responsible_audit_token {
            self.rpid = audit_token_to_pid(auditToken)
        }
        
        //init uuid
        if let auditToken = process?.pointee.audit_token {
            self.uid = audit_token_to_euid(auditToken)
        }
        
        //init path
        if let path = process?.pointee.executable.pointee.path {
            self.path = String(cString: path.data, encoding: .utf8)
        }
        
        //now generate name
        self.name = getName()
        
        //convert/add signing id
        if let signingID = process?.pointee.signing_id {
            self.signingID = convertStringToken(signingID)
        }
        
        //convert/add team id
        if let teamID = process?.pointee.team_id {
            self.teamID = convertStringToken(teamID)
        }
    }
    
    func getName()-> String {
        var name: String = ""
        if let path = path as? NSString {
            let appPath = ((path.deletingLastPathComponent as NSString).deletingLastPathComponent as NSString).deletingLastPathComponent
            if appPath.hasSuffix(".app") {
                if let bundle = Bundle(path: appPath) {
                    if bundle.executablePath == (path as String) {
                        name = bundle.infoDictionary?[kCFBundleNameKey as String] as? String ?? ""
                    }
                }
            }
        }
        if name == "" {
            name = (self.path as? NSString)?.lastPathComponent ?? ""
        }
        return name
    }
    
    func description()-> String {
        let pid = String(describing: pid)
        let ppid = String(describing: ppid)
        let rpid = String(describing: rpid)
        let uid = String(describing: uid)
        let name = name ?? ""
        let path = path ?? ""
        let signingID = signingID ?? ""
        let teamID = teamID ?? ""
        
        return "{ \"pid\":\"\(pid)\",\"ppid\":\"\(ppid)\",\"rpid\":\"\(rpid)\",\"uid\":\"\(uid)\",\"name\":\"\(name)\",\"path\":\"\(path)\",\"signingID\":\"\(signingID)\",\"teamID\":\"\(teamID)\"}"
    }
    
    
}
