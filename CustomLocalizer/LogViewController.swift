//
//  LogViewController.swift
//  CustomLocalizer
//
//  Created by Jesus De Meyer on 7/19/17.
//  Copyright © 2017 Jesus De Meyer. All rights reserved.
//

import Cocoa

class LogViewController: NSViewController, NSOutlineViewDelegate, NSOutlineViewDataSource {
    var duplicates = [String: [String]]()
    fileprivate var duplicatesKeys = [String]()
    
    @IBOutlet weak var outlineView: NSOutlineView!
    @IBOutlet var logTextView: NSTextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.logTextView.string = self.generateLogFromDuplicates()
        
        self.outlineView.dataSource = self
        self.outlineView.delegate = self
    }
    
    fileprivate func generateLogFromDuplicates() -> String {
        var log = ""
        
        for (key, value) in duplicates {
            duplicatesKeys.append(key)
            
            log += "----- DUPLICATES FOR LOCALIZATION: \(key) -----\n"
            
            for duplicate in value {
                log += "Duplicate key: '\(duplicate)'\n"
                
                /*if savedValue == value {
                    log += "\(fileURL.lastPathComponent) has duplicate key: '\(key)'\n"
                } else {
                    log += "\(fileURL.lastPathComponent) has duplicate key: '\(key)' and differs from value: '\(savedValue)' != '\(value)'\n"
                }*/
            }
        }
    
        return log
    }
    
    @IBAction func handleOK(_ sender: Any) {
        self.dismiss(self)
    }
    
    func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        return !(item is String)
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return !(item is String)
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let key = item as? String {
            return duplicates[key]?.count ?? 0
        } else {
            return duplicatesKeys.count
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil {
            let key = duplicatesKeys[index]
            return duplicates[key] ?? []
        }
        
        return "HOla"
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let view = outlineView.make(withIdentifier: "name", owner: self) as? NSTableCellView
        
        if let textField = view?.textField {
            textField.stringValue = item as! String
        }
        
        return view
    }
}
