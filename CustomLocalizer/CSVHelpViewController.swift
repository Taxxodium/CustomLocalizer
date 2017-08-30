//
//  CSVHelpViewController.swift
//  CustomLocalizer
//
//  Created by Jesus De Meyer on 7/31/17.
//  Copyright © 2017 Jesus De Meyer. All rights reserved.
//

import Cocoa

class CSVHelpViewController: NSViewController {
    @IBOutlet var helpTextView: NSTextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let path = Bundle.main.path(forResource: "CSVHelp", ofType: "txt") {
            if let content = try? String(contentsOfFile: path) {
                helpTextView.string = content
            }
        }
        
        helpTextView.isEditable = false
    }
    
}
