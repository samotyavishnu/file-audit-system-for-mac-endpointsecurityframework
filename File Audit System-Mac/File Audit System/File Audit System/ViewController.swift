//
//  ViewController.swift
//  File Audit System
//
//  Created by Vishnu Kumar Sharma on 26/04/23.
//

import Cocoa
import EndpointSecurity


enum csOptions: UInt {case csNone, csStatic, csDynamic}

class ViewController: NSViewController {
    
    @IBOutlet weak var tableViewDirectories: NSTableView!
    @IBOutlet weak var btnAddFolder: NSButton!
    @IBOutlet weak var btnDeleteFolder: NSButton!
    @IBOutlet weak var pathControlLogger: NSPathControl!
    @IBOutlet weak var btnStartStopMonitoring: NSButton!
    
    
    
    private let fileAuditor = FileAuditor()
    private let logger = FileLogger()
    private var configDirectories: Set<String> = []
    private var lock = os_unfair_lock_s()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Do any additional setup after loading the view.
        //Config Logger path
        logger.setConfiguration(newPath: nil)
        logger.getLogFileURL(completion: { url in
            pathControlLogger.url = url
        })
        
        //Table view configuration
        tableViewDirectories.delegate = self
        tableViewDirectories.dataSource = self
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    
    @IBAction func clickedAddFolder(_ sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.canChooseFiles = false
        openPanel.beginSheetModal(for: self.view.window!, completionHandler: { response in
            if response == .OK {
                if let url = openPanel.url {
                    self.addNewPathToMonitor(path: url.path)
                    self.tableViewDirectories.reloadData()
                }
            }
        })
    }
    
    @IBAction func clickedDeleteFolder(_ sender: NSButton) {
        if tableViewDirectories.selectedRow >= 0 {
            if configDirectories.count > tableViewDirectories.selectedRow {
                let folderPath = Array(configDirectories)[tableViewDirectories.selectedRow]
                deleteConfiguredPathFromMonitor(path: folderPath)
                self.tableViewDirectories.reloadData()
                if configDirectories.count == 0 {
                    btnStartStopMonitoring.state = .off
                    stopMonitoring()
                    btnStartStopMonitoring.title = "Start Monitoring"
                    showCloseAlert(title: "File Monitoring!", message: "Please add at least one folder to monitor events.") { isOk in
                    }
                }
            }
        }
    }
    
    @IBAction func clickedPathControlLogger(_ sender: NSPathControl) {
        if let path = sender.url?.path {
            logger.setConfiguration(newPath: path)
        }
    }
    
    @IBAction func clickedStartStopMonitoring(_ sender: NSButton) {
        if sender.state == .on {
            if configDirectories.count == 0 {
                sender.state = .off
                stopMonitoring()
                btnStartStopMonitoring.title = "Start Monitoring"
                showCloseAlert(title: "File Monitoring!", message: "Please add at least one folder to monitor events.") { isOk in
                }
                return
            }
            startMonitoring()
            btnStartStopMonitoring.title = "Stop Monitoring"
        } else {
            stopMonitoring()
            btnStartStopMonitoring.title = "Start Monitoring"
        }
    }
    
    func startMonitoring() {
        let events = [ES_EVENT_TYPE_NOTIFY_CREATE, ES_EVENT_TYPE_NOTIFY_OPEN, ES_EVENT_TYPE_NOTIFY_WRITE, ES_EVENT_TYPE_NOTIFY_CLOSE, ES_EVENT_TYPE_NOTIFY_RENAME, ES_EVENT_TYPE_NOTIFY_LINK, ES_EVENT_TYPE_NOTIFY_UNLINK, ES_EVENT_TYPE_NOTIFY_EXEC, ES_EVENT_TYPE_NOTIFY_EXIT]
        
        fileAuditor.startMonitoring(events: events) { file in
            if let path = file.destinationPath, self.checkPathIsConfiguredToMonitor(path: path) {
                self.logger.logMessage(message: file.description())
                print(file.description())
            }
            //print(file.description())
        }
        //RunLoop.current.run()
        //withExtendedLifetime(fileAuditor) { RunLoop.main.run() }
    }
    
    func stopMonitoring() {
        fileAuditor.stopMonitoring()
    }
    
    func checkPathIsConfiguredToMonitor(path: String) -> Bool {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        
        return configDirectories.contains { dPath in
            return path.hasPrefix(dPath)
        }
    }
    
    func addNewPathToMonitor(path: String) {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        
        configDirectories.insert(path)
    }
    
    func deleteConfiguredPathFromMonitor(path: String) {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        
        configDirectories.remove(path)
    }
    
    
    
    
}


//UITableview delegate and datasource
extension ViewController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return configDirectories.count
    }
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "Row"), owner: self) as? NSTableCellView
        else {
            return nil
        }
        if configDirectories.count > row {
            let folderPath = Array(configDirectories)[row]
            cellView.textField?.stringValue = folderPath
        }
        return cellView
    }
}
