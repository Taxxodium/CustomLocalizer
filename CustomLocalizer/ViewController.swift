//
//  ViewController.swift
//  CustomLocalizer
//
//  Created by Jesus De Meyer on 7/6/17.
//  Copyright © 2017 Jesus De Meyer. All rights reserved.
//

import Cocoa
import CSV

fileprivate enum Type: Int {
    case csv
    case project
}

class ViewController: NSViewController, LanguagesPickerViewControllerDelegate {

    @IBOutlet weak var isUIButton: NSButton!
    @IBOutlet weak var isKeyed: NSButton!
    
    var urlToCSV: URL!
    var urlToProject: URL!
    
    var stringsInfo = [String: [String]]()
    
    var filteredLanguages = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: -
    
    @IBAction func selectCSV(_ sender: Any) {
        self.chooseFilesOfType(.csv)
    }

    @IBAction func selectFiles(_ sender: Any) {
        
        self.chooseFilesOfType(.project)
    }
    
    // MARK: -
    
    @IBAction func localizeFiles(_ sender: Any) {
        if !self.updateStringsFromCSV() {
            return
        }
        
        self.performSegue(withIdentifier: "showLanguages", sender: nil)
    }
    
    // MARK: -
    
    @IBAction func detectDuplicates(_ sender: Any) {
        if self.urlToProject == nil {
            self.showAlert(title: "Project folder not selected", message: "Please select the folder for your project")
            return
        }
        
        let lprojURLs = self.findLocalizedProjectURLs(fromURL: self.urlToProject)
       
        if lprojURLs.count == 0 {
            print("Project has no localizations!")
            return
        }
        
        guard let stringsRegEx = try? NSRegularExpression(pattern: "\"([^\"]*)\"\\s*=\\s*\"([^\"]*)\";", options: []) else {
            print("Incorrect regular expression")
            return
        }
        
        var duplicatesPerLanguage = [String: Array<String>]()
        
        var log = ""
        
        // go over all lproj folders, which contain the .strings files
        for lprojURL in lprojURLs {
            var duplicateKeys = [String]()
            let stringsFileURLs = self.getStringsFileURLs(fromLocalizationURL: lprojURL)
            
            log += "----- DETECTING DUPLICATES ON: \(lprojURL.lastPathComponent) -----\n"
            
            // go over all the strings files in the lproj file
            for fileURL in stringsFileURLs {
                guard let fileContents = try? String(contentsOf: fileURL, encoding: .utf8) else {
                    print("Could not get file contents of file: \(fileURL.lastPathComponent)")
                    continue
                }
                
                var stringsInfo = [String: String]()
                
                let fileContentsRange = NSMakeRange(0, fileContents.distance(from: fileContents.startIndex, to: fileContents.endIndex))
                
                let matches = stringsRegEx.matches(in: fileContents, options: [], range: fileContentsRange)
                
                for match in matches {
                    if match.numberOfRanges <= 2 {
                        continue
                    }

                    let keyRange = match.rangeAt(1)
                    let valueRange = match.rangeAt(2)
                    
                    let key = (fileContents as NSString).substring(with: keyRange)
                    let value = (fileContents as NSString).substring(with: valueRange)
                    
                    if let savedValue = stringsInfo[key] {
                        if savedValue == value {
                            log += "\(fileURL.lastPathComponent) has duplicate key: '\(key)'\n"
                        } else {
                            log += "\(fileURL.lastPathComponent) has duplicate key: '\(key)' and differs from value: '\(savedValue)' != '\(value)'\n"
                        }
                        duplicateKeys.append(savedValue)
                    } else {
                        stringsInfo[key] = value
                    }
                }
            }
            
            if !duplicateKeys.isEmpty {
                let languageCode = lprojURL.deletingPathExtension().lastPathComponent
                duplicatesPerLanguage[languageCode] = duplicateKeys
            }
        }
        
        self.performSegue(withIdentifier: "showLog", sender: duplicatesPerLanguage)
    }
    
    // MARK: -
    
    @IBAction func extractStrings(_ sender: Any) {
        if self.urlToProject == nil {
            self.showAlert(title: "Project folder not selected", message: "Please select the folder for your project")
            return
        }
        
        var log = ""
        
        // Extract strings from source code (.m and .h)
        
        log += "----- STRINGS FROM SOURCE CODE ------\n"
        log += "\n"
        
        guard let objcStringsRegEx = try? NSRegularExpression(pattern: "@\"(?:[^\"\\\\]|\\\\.)*\"", options: []) else {
            print("Incorrect regular expression")
            return
        }
        
        let fileManager = FileManager.default
        
        guard let fileEnum = fileManager.enumerator(at: self.urlToProject, includingPropertiesForKeys: nil) else {
            return
        }
        
        while let fileURL = fileEnum.nextObject() as? URL {
            if !["m", "h"].contains(fileURL.pathExtension) {
                continue
            }
            
            guard let fileContents = try? String(contentsOf: fileURL) else {
                continue
            }
            
            let matches = objcStringsRegEx.matches(in: fileContents, options: [], range: NSMakeRange(0, fileContents.distance(from: fileContents.startIndex, to: fileContents.endIndex)))
            
            if matches.count == 0 {
                continue
            }
            
            log += "----- IN FILE: \(fileURL.lastPathComponent) -----\n"
            
            for match in matches {
                let string = (fileContents as NSString).substring(with: match.range)
                log += "\(string)\n"
            }
            
            log += "\n"
        }
        
        // Extract strings from .strings files
        
        let lprojURLs = self.findLocalizedProjectURLs(fromURL: self.urlToProject)
        
        if lprojURLs.count == 0 {
            print("Project has no localizations!")
            return
        }
        
        log += "----- STRINGS FROM UI ------\n"
        log += "\n"
        
        guard let stringsRegEx = try? NSRegularExpression(pattern: "\"([^\"]*)\"\\s*=\\s*\"([^\"]*)\";", options: []) else {
            print("Incorrect regular expression")
            return
        }
        
        // go over all lproj folders, which contain the .strings files
        for lprojURL in lprojURLs {
            if !lprojURL.lastPathComponent.hasPrefix("en") {
                continue
            }
            
            let stringsFileURLs = self.getStringsFileURLs(fromLocalizationURL: lprojURL)
            
            //log += "----- IN FILE: \(lprojURL.lastPathComponent) -----\n"
            
            // go over all the strings files in the lproj file
            for fileURL in stringsFileURLs {
                guard let fileContents = try? String(contentsOf: fileURL, encoding: .utf8) else {
                    continue
                }
                
                log += "----- IN FILE: \(lprojURL.lastPathComponent)/\(fileURL.lastPathComponent) -----\n"
                
                let fileContentsRange = NSMakeRange(0, fileContents.distance(from: fileContents.startIndex, to: fileContents.endIndex))
                
                let matches = stringsRegEx.matches(in: fileContents, options: [], range: fileContentsRange)
                
                for match in matches {
                    if match.numberOfRanges <= 2 {
                        continue
                    }
                    
                    //let keyRange = match.rangeAt(1)
                    let valueRange = match.rangeAt(2)
                    
                    //let key = (fileContents as NSString).substring(with: keyRange)
                    let value = (fileContents as NSString).substring(with: valueRange)
                    
                    log += "\(value)\n"
                }
            }
            
            log += "\n"
        }
        
        print(log)
    }
    
    // MARK: -
    
    @IBAction func preflight(_ sender: Any) {
        if !self.updateStringsFromCSV() {
            return
        }
        
        let lprojURLs = self.findLocalizedProjectURLs(fromURL: self.urlToProject)
        
        if lprojURLs.count == 0 {
            print("Project has no localizations!")
            return
        }
        
        guard let stringsRegEx = try? NSRegularExpression(pattern: "\"([^\"]*)\"\\s*=\\s*\"([^\"]*)\";", options: []) else {
            print("Incorrect regular expression")
            return
        }
        
        var unmatchedKeys = [String]()
        
        // go over all lproj folders, which contain the .strings files
        for lprojURL in lprojURLs {
            if !lprojURL.lastPathComponent.hasPrefix("en") {
                continue
            }
            
            let fileURL = lprojURL.appendingPathComponent("Localizable.strings")
            
            guard let fileContents = try? String(contentsOf: fileURL, encoding: .utf8) else {
                continue
            }
            
            let fileContentsRange = NSMakeRange(0, fileContents.distance(from: fileContents.startIndex, to: fileContents.endIndex))
            
            let keysInCSV = self.stringsInfo["en"]!
            var currentKeys = [String]()
            
            let matches = stringsRegEx.matches(in: fileContents, options: [], range: fileContentsRange)
            
            for match in matches {
                if match.numberOfRanges <= 2 {
                    continue
                }
                
                let keyRange = match.rangeAt(1)
                //let valueRange = match.rangeAt(2)
                
                let key = (fileContents as NSString).substring(with: keyRange)
                //let value = (fileContents as NSString).substring(with: valueRange)
                
                currentKeys.append(key)
            }
            
            for key in keysInCSV {
                if !currentKeys.contains(key) {
                    unmatchedKeys.append(key)
                }
            }
        }
        
        var c = ""
        
        c += "THE FOLLOWING KEYS WERE NOT FOUND IN Localizable.strings FILE:\n\n"
        
        c += unmatchedKeys.joined(separator: "\n")
        
        self.performSegue(withIdentifier: "showConsole", sender: c)
    }
    
    
    // MARK: -
    
    fileprivate func updateStringsFromCSV() -> Bool {
        if self.urlToProject == nil {
            self.showAlert(title: "Project folder not selected", message: "Please select the folder for your project")
            return false
        }
        
        if self.urlToCSV == nil {
            self.showAlert(title: NSLocalizedString("CSV file not selected!", comment: ""), message: NSLocalizedString("Please select the CSV file containing the strings to be localized!", comment: ""))
            return false
        }
        
        guard let csvStream = InputStream(url: self.urlToCSV) else {
            self.showAlert(title: "Could not read the CSV file", message: "Please make sure the CSV file  is in the correct format.")
            return false
        }
        
        guard let csv = try? CSVReader(stream: csvStream, hasHeaderRow: true) else {
            self.showAlert(title: "Could not read the CSV file", message: "Please make sure the CSV file  is in the correct format.")
            return false
        }
        
        guard let csvHeaders = csv.headerRow else {
            self.showAlert(title: "Wrong format for CSV", message: "Please make sure the CSV file is in the correct format.")
            return false
        }
        
        self.stringsInfo.removeAll()
        
        while let csvRow = csv.next() {
            for (index, value) in csvRow.enumerated() {
                var stringValues = [String]()
                let key = csvHeaders[index]//.lowercased()
                
                if key.isEmpty {
                    continue
                }
                
                if let list = self.stringsInfo[key] {
                    stringValues.append(contentsOf: list)
                }
                
                stringValues.append(value)
                
                self.stringsInfo[key] = stringValues
            }
        }
        
        return true
    }
    
    // MARK: -
    
    fileprivate func localizeStringsForUI(rootURL: URL) {
        guard let englishStrings = self.stringsInfo["en"] else {
            return
        }
        
        let UIToEnglishKeyDictionary = self.getUIToEnglishKeysDictionary(fromURL: rootURL)
        
        for (languageCode, languageStrings) in self.stringsInfo {
            if ["en", "Base"].contains(languageCode) {
                continue
            }
            
            if !self.filteredLanguages.contains(languageCode) {
                continue
            }
            
            let locDirectory = self.getLocalizedProjectURL(fromURL: rootURL, languageCode: languageCode)
            
            let fileManager = FileManager.default
            
            let locDirectoryEnumerator = fileManager.enumerator(atPath: locDirectory.path)
            
            while let file = locDirectoryEnumerator?.nextObject() as? String {
                if file == "Localizable.strings" {
                    continue
                }
                
                let fileURL = locDirectory.appendingPathComponent(file)
                
                if let contents = try? String(contentsOf: fileURL) {
                    var newContents = contents
                    
                    do {
                        let regEx = try NSRegularExpression(pattern: "\"([^\"]*)\" = \"([^\"]*)\";", options: [])
                        
                        let matches = regEx.matches(in: contents, options: [], range: NSMakeRange(0, contents.distance(from: contents.startIndex, to: contents.endIndex)))
                        
                        for match in matches {
                            if match.numberOfRanges > 2 {
                                let keyRange = match.rangeAt(1)
                                let valueRange = match.rangeAt(2)
                                
                                let key = (contents as NSString).substring(with: keyRange)
                                let value = (contents as NSString).substring(with: valueRange)
                                
                                let oldLine = "\"\(key)\" = \"\(value)\";"
                                
                                if let englishKeyValue = UIToEnglishKeyDictionary[key] {
                                    for (index, s) in englishStrings.enumerated() {
                                        let cleanS = s.replacingOccurrences(of: "\"", with: "\\\"")
                                        
                                        if cleanS == englishKeyValue {
                                            let newLine = "\"\(key)\" = \"\(languageStrings[index])\";"
                                            
                                            newContents = (newContents as NSString).replacingOccurrences(of: oldLine, with: newLine)
                                        }
                                    }
                                }
                            }
                        }
                        
                        if let data = newContents.data(using: .utf8) {
                            let urlToWrite = fileURL
                            
                            do {
                                try data.write(to: urlToWrite, options: .atomic)
                            } catch let error {
                                print("Could not write file: \(error)")
                            }
                        }
                    } catch let error {
                        print("Error: \(error)")
                    }
                }
            }
        }
        
    }
    
    fileprivate func getUIToEnglishKeysDictionary(fromURL: URL) -> [String: String] {
        var result = [String: String]()
        
        let englishLocDirectory = self.getLocalizedProjectURL(fromURL: fromURL, languageCode: "en")
        
        let fileManager = FileManager.default
        
        if let fileEnumerator = fileManager.enumerator(atPath: englishLocDirectory.path) {
            while let file = fileEnumerator.nextObject() as? String {
                if file == "Localizable.strings" {
                    continue
                }
                
                let fileURL = englishLocDirectory.appendingPathComponent(file)
                
                if let contents = try? String(contentsOf: fileURL) {
                    do {
                        let regEx = try NSRegularExpression(pattern: "\"([^\"]*)\" = \"([^\"]*)\";", options: [])
                        
                        let matches = regEx.matches(in: contents, options: [], range: NSMakeRange(0, contents.distance(from: contents.startIndex, to: contents.endIndex)))
                        
                        for match in matches {
                            if match.numberOfRanges >= 2 {
                                let keyRange = match.rangeAt(1)
                                let valueRange = match.rangeAt(2)
                                
                                let key = (contents as NSString).substring(with: keyRange)
                                let value = (contents as NSString).substring(with: valueRange)
                                
                                if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    continue
                                }
                                
                                result[key] = value
                            }
                        }
                    } catch let error {
                        print("Error: \(error)!")
                    }
                    
                }
            }
        }
        
        return result
    }
    
    // MARK: -
    
    fileprivate func localizeStrings(rootURL: URL) {
        let isKeyed = self.isKeyed.state == NSOnState
        
        if isKeyed {
            guard let stringsRegEx = try? NSRegularExpression(pattern: "\"([^\"]*)\"\\s*=\\s*\"([^\"]*)\";", options: []) else {
                print("Incorrect regular expression")
                return
            }
            
            guard let keysValues = self.stringsInfo["key"] else {
                print("No key column found")
                return
            }
            
            for (languageCode, strings) in self.stringsInfo {
                if languageCode == "key" {
                    continue
                }
                
                if !self.filteredLanguages.contains(languageCode) {
                    continue
                }
                
                let fileContents = self.getContentsOfLocalizableStringsFile(fromURL: rootURL, languageCode: languageCode)
                var newFileContents = fileContents
                
                let fileContentsRange = NSMakeRange(0, fileContents.distance(from: fileContents.startIndex, to: fileContents.endIndex))
                
                let matches = stringsRegEx.matches(in: fileContents, options: [], range: fileContentsRange)
                
                for match in matches {
                    if match.numberOfRanges <= 2 {
                        continue
                    }
                    
                    let fullRange = match.rangeAt(0)
                    let keyRange = match.rangeAt(1)
                    //let valueRange = match.rangeAt(2)
                    
                    let full = (fileContents as NSString).substring(with: fullRange)
                    let key = (fileContents as NSString).substring(with: keyRange)
                    //let value = (fileContents as NSString).substring(with: valueRange)
                    
                    for (index, k) in keysValues.enumerated() {
                        if k == key {
                            let newValue = strings[index]
                        
                            if !newValue.isEmpty {
                                let range = (newFileContents as NSString).range(of: full)
                                
                                if range.location != NSNotFound {
                                    newFileContents = (newFileContents as NSString).replacingCharacters(in: range, with: "\"\(key)\" = \"\(newValue)\";")
                                }
                            }
                            
                            break
                        }
                    }
                }
                
                if let data = newFileContents.data(using: .utf8) {
                    let urlToWrite = self.getURLToLocalizableStrigsFile(fromURL: rootURL, languageCode: languageCode)
                    
                    do {
                        try data.write(to: urlToWrite, options: .atomic)
                    } catch let error {
                        print("Could not write file: \(error)")
                    }
                }
            }
        } else {
            for (languageCode, languageStrings) in self.stringsInfo {
                if !self.filteredLanguages.contains(languageCode) {
                    continue
                }
                
                let stringsFileContents = self.getContentsOfLocalizableStringsFile(fromURL: rootURL, languageCode: languageCode)
                
                if let newStringsFile = self.updateLocalizableStringsFile(content: stringsFileContents, languages: languageStrings) {
                    if let data = newStringsFile.data(using: .utf8) {
                        let urlToWrite = self.getURLToLocalizableStrigsFile(fromURL: rootURL, languageCode: languageCode)
                        
                        do {
                            try data.write(to: urlToWrite, options: .atomic)
                        } catch let error {
                            print("Could not write file: \(error)")
                        }
                    }
                }
            }
        }
    }

    // MARK: -
    
    fileprivate func getContentsOfLocalizableStringsFile(fromURL: URL, languageCode: String) -> String {
        var result = ""
        
        let url = self.getURLToLocalizableStrigsFile(fromURL: fromURL, languageCode: languageCode)
        
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: url.path) {
            if let contents = try? String(contentsOf: url) {
                result = contents
            }
        }
        
        return result
    }
    
    fileprivate func updateLocalizableStringsFile(content: String, languages: [String]) -> String? {
        guard let englishStrings = self.stringsInfo["en"] else {
            print("Could not find english strings")
            return nil
        }
        
        var contents = content
        var header = ""
        
        // find the header
        if let headerRange = content.range(of: "\\/\\*[^\\*]*\\*\\/", options: .regularExpression, range: nil, locale: nil) {
            header = content.substring(with: headerRange)
            contents = content.substring(from: headerRange.upperBound)
        }
        
        var newBlock = ""
        var allOK = true
        
        newBlock += "\n// new localizations\n\n"
        
        for (stringsIndex, stringsValue) in languages.enumerated() {
            if stringsIndex > englishStrings.count {
                print("strings out of bounds!")
                allOK = false
                break // we should not get here but just in case
            }
            
            let englishStringValue = englishStrings[stringsIndex]
            
            var value1 = englishStringValue
            var value2 = stringsValue
            
            value1 = value1.replacingOccurrences(of: "\"", with: "\\\"")
            //value1 = value1.replacingOccurrences(of: "\'", with: "\\\'")
            
            value2 = value2.replacingOccurrences(of: "\"", with: "\\\"")
            //value2 = value2.replacingOccurrences(of: "\'", with: "\\\'")
            
            newBlock += "\"\(value1)\" = \"\(value2)\";\n"
        }
        
        if allOK {
            var newContents = ""
            
            if !header.isEmpty {
                newContents += "\(header)\n"
            }
            
            newContents += "\(newBlock)\n"
            newContents += "\(contents)\n"
            
            return newContents
        }
        
        return nil
    }
    
    // MARK: -
    
    fileprivate func findLocalizedProjectURLs(fromURL: URL) -> [URL] {
        var urls = [URL]()
        
        let fileManager = FileManager.default
        let resourceKeys: Set<URLResourceKey> = [.nameKey, .isDirectoryKey]
        
        guard let directoryEnumerator = fileManager.enumerator(at: fromURL, includingPropertiesForKeys: Array(resourceKeys), options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants], errorHandler: nil) else {
            print("Could not create enumerator")
            return urls
        }
        
        for case let fileURL as URL in directoryEnumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: resourceKeys) else {
                continue
            }
            
            if let name = resourceValues.name, name.hasSuffix(".lproj") {
                urls.append(fileURL)
            }
        }
        
        return urls
    }
    
    fileprivate func getStringsFileURLs(fromLocalizationURL url: URL, ignoreLocalizableStrings: Bool = false) -> [URL] {
        var urls = [URL]()
        
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: nil) else {
            print("Could not create enumerator for \(url.lastPathComponent)")
            return urls
        }
        
        while let stringsURL = enumerator.nextObject() as? URL {
            if !stringsURL.lastPathComponent.hasSuffix(".strings") {
                continue
            }
            
            if ignoreLocalizableStrings && stringsURL.lastPathComponent == "Localizable.strings" {
                continue
            }
            
            urls.append(stringsURL)
        }
        
        return urls
    }
    
    // MARK: -
    
    fileprivate func getURLToLocalizableStrigsFile(fromURL: URL, languageCode: String) -> URL {
        return fromURL.appendingPathComponent("\(languageCode.lowercased()).lproj/Localizable.strings")
    }
    
    fileprivate func getLocalizedProjectURL(fromURL: URL, languageCode: String) -> URL {
        return fromURL.appendingPathComponent("\(languageCode.lowercased()).lproj")
    }
    
    // MARK: -
    
    fileprivate func chooseFilesOfType(_ type: Type) {
        let openPanel = NSOpenPanel()
        
        openPanel.allowsMultipleSelection = false
        openPanel.canCreateDirectories = false
        
        switch type {
        case .csv:
            openPanel.allowedFileTypes = ["csv", "CSV"]
            openPanel.canChooseFiles = true
            openPanel.canChooseDirectories = false
        case .project:
            openPanel.canChooseFiles = false
            openPanel.canChooseDirectories = true
        }
        
        let result = openPanel.runModal()
        
        if result == NSFileHandlingPanelOKButton {
            if let url = openPanel.urls.first {
                switch type {
                case .csv:
                    self.urlToCSV = url
                case .project:
                    self.urlToProject = url
                }
            }
        }
    }
    
    // MARK: -
    
    fileprivate func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title.isEmpty ? "An error occured" : title
        alert.informativeText = message
        alert.runModal()
    }
    
    // MARK: -
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else {
            return
        }
        
        switch identifier {
        case "showLog":
            let controller = segue.destinationController as! LogViewController
            
            controller.duplicates = sender as! [String: [String]]
        case "showLanguages":
            let controller = segue.destinationController as! LanguagesPickerViewController
            
            controller.delegate = self
            controller.languages = self.findLocalizedProjectURLs(fromURL: self.urlToProject).map {
                $0.lastPathComponent
            }.sorted {
                return $0 < $1
            }
        case "showConsole":
            let controller = segue.destinationController as! ConsoleViewController
            
            controller.contents = sender as? String
        default:
            break
        }
    }
    
    // MARK: -
    
    func languagesPickerViewController(controller: LanguagesPickerViewController, didSelectLanguages languages: [String]) {
        
        self.filteredLanguages = languages.map { $0.components(separatedBy: ".").first! }
        
        if self.isUIButton.state == NSOnState {
            self.localizeStringsForUI(rootURL: self.urlToProject)
        } else {
            self.localizeStrings(rootURL: self.urlToProject)
        }
    }
}

