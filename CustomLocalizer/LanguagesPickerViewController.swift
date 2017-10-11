//
//  LanguagesPickerViewController.swift
//  CustomLocalizer
//
//  Created by Jesus De Meyer on 10/10/17.
//  Copyright © 2017 Jesus De Meyer. All rights reserved.
//

import Cocoa

protocol LanguagesPickerViewControllerDelegate {
    func languagesPickerViewController(controller: LanguagesPickerViewController, didSelectLanguages languages: [String])
}

class LanguagesPickerViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {

    @IBOutlet weak var tableView: NSTableView!
    
    var delegate: LanguagesPickerViewControllerDelegate?
    
    var languages = [String]() {
        didSet {
            self.selectedLanguages = languages
        }
    }
    
    private var selectedLanguages = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func handleOK(_ sender: Any) {
        self.dismiss(self)
        
        self.delegate?.languagesPickerViewController(controller: self, didSelectLanguages: selectedLanguages)
    }
    
    @IBAction func handleCancel(_ sender: Any) {
        self.dismiss(self)
    }
    
    @IBAction func handleCheckbox(_ sender: NSButton) {
        if sender.state == NSOnState {
            selectedLanguages.append(sender.title)
        } else {
            if let index = self.selectedLanguages.index(of: sender.title) {
                selectedLanguages.remove(at: index)
            }
        }
    }
    
    // MARK: -
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return languages.count
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let view = tableView.make(withIdentifier: "LanguageCell", owner: self) as? NSTableRowView
        
        let lang = self.languages[row]
        
        if let button = view?.viewWithTag(100) as? NSButton {
            button.title = lang
        }
        
        return view
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let view = tableView.make(withIdentifier: "LanguageCell", owner: self)
        
        let lang = self.languages[row]
        
        if let button = view?.viewWithTag(100) as? NSButton {
            button.title = lang
        }
        
        return view
    }
    
}
