//
//  Utilities.swift
//  File Audit System
//
//  Created by Vishnu Kumar Sharma on 28/04/23.
//  Copyright © 2023 Vishnu Kumar Sharma. All rights reserved.
//

import Foundation
import Cocoa
import EndpointSecurity

func convertStringToken(_ stringToken: es_string_token_t)-> String {
    var string = ""
    if stringToken.data != nil && stringToken.length > 0 {
        string = String(cString: stringToken.data, encoding: .utf8) ?? ""
    }
    return string
}

func showCloseAlert(title: String, message: String, completion: (Bool) -> Void) {
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = message
    alert.alertStyle = NSAlert.Style.warning
    alert.addButton(withTitle: "OK")
    //alert.addButton(withTitle: "Cancel")
    completion(alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn)
}
