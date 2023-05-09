//
//  FileAuditor.swift
//  File Audit System
//
//  Created by Vishnu Kumar Sharma on 28/04/23.
//  Copyright © 2023 Vishnu Kumar Sharma. All rights reserved.
//

import Foundation
import Cocoa
import EndpointSecurity

class FileAuditor {
    
    //endpoint client
    private var endpointClient: OpaquePointer?
    
    init() {
    }
    
    deinit {
        stopMonitoring()
    }
    
    func startMonitoring(events: [es_event_type_t], callback: @escaping AuditFileCallback) {
        
        let dispatchQueue = DispatchQueue(label: "esclient", qos: .default)
        dispatchQueue.sync {
            
            let result: es_new_client_result_t = es_new_client(&endpointClient) { client, message in
                let file = AuditFile(message: message.pointee)
                //invoke user callback
                callback(file)
            }
            
            //error?
            switch result {
            case ES_NEW_CLIENT_RESULT_ERR_TOO_MANY_CLIENTS:
                print("[ES CLIENT ERROR] There are too many Endpoint Security clients!")
            case ES_NEW_CLIENT_RESULT_ERR_NOT_ENTITLED:
                print("[ES CLIENT ERROR] Failed to create new Endpoint Security client! The endpoint security entitlement is required.")
            case ES_NEW_CLIENT_RESULT_ERR_NOT_PERMITTED:
                print("[ES CLIENT ERROR] Lacking TCC permissions!")
            case ES_NEW_CLIENT_RESULT_ERR_NOT_PRIVILEGED:
                print("[ES CLIENT ERROR] Caller is not running as root!")
            case ES_NEW_CLIENT_RESULT_ERR_INTERNAL:
                print("[ES CLIENT ERROR] Error communicating with ES!")
            case ES_NEW_CLIENT_RESULT_ERR_INVALID_ARGUMENT:
                print("[ES CLIENT ERROR] Incorrect arguments creating a new ES client!")
            case ES_NEW_CLIENT_RESULT_SUCCESS:
                print("[ES CLIENT SUCCESS] We successfully created a new Endpoint Security client!")
            default:
                print("An unknown error occured while creating a new Endpoint Security client!")
            }
            
            // Validate that we have a valid reference to a client
            if endpointClient == nil {
                print("[ES CLIENT ERROR] After atempting to make a new ES client we failed.")
                exit(EXIT_FAILURE)
            }
            
            //clear cache
            if let endpointClient = endpointClient {
                if(ES_CLEAR_CACHE_RESULT_SUCCESS != es_clear_cache(endpointClient)) {
                    //err msg
                    print("ERROR: es_clear_cache() failed")
                }
            }
            
            //mute self
            if let endpointClient = endpointClient {
                if let arg0 = ProcessInfo.processInfo.arguments.first, let cString = (arg0 as NSString).utf8String {
                    debugPrint(arg0)
                    if #available(macOS 12.0, *) {
                        es_mute_path(endpointClient, cString, ES_MUTE_PATH_TYPE_LITERAL)
                    } else {
                        // Fallback on earlier versions
                        es_mute_path_literal(endpointClient, cString)
                    }
                    
                }
            }
            
            // MARK: - Event subscriptions
            // Reference: https://developer.apple.com/documentation/endpointsecurity/3228854-es_subscribe
            if let endpointClient = endpointClient {
                if es_subscribe(endpointClient, events, UInt32(events.count)) != ES_RETURN_SUCCESS {
                    print("[ES CLIENT ERROR] Failed to subscribe to core events! \(result.rawValue)")
                    es_delete_client(endpointClient)
                    exit(EXIT_FAILURE)
                }
            }
        }
        
    }
    
    
    
    func stopMonitoring() {
        //unsubscribe & delete
        if let _endpointClient = endpointClient {
            //unsubscribe
            if(ES_RETURN_SUCCESS != es_unsubscribe_all(_endpointClient)) {
                //err msg
                print("ERROR: es_unsubscribe_all() failed")
            }
            
            //delete
            if(ES_RETURN_SUCCESS != es_delete_client(_endpointClient)) {
                //err msg
                print("ERROR: es_delete_client() failed")
            }
            
            //unset
            endpointClient = nil
        }
    }
    
    
    
}
