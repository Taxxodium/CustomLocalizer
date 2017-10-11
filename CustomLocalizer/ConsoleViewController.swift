//
//  ConsoleViewController.swift
//  CustomLocalizer
//
//  Created by Jesus De Meyer on 10/11/17.
//  Copyright © 2017 Jesus De Meyer. All rights reserved.
//

import Cocoa

class ConsoleViewController: NSViewController {
    var contents: String?
    
    @IBOutlet var textView: NSTextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        textView.string = contents
    }
    
    @IBAction func handleOK(_ sender: Any) {
        self.dismiss(nil)
    }
}
