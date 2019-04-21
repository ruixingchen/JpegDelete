//
//  ViewController.swift
//  jpgDelete
//
//  Created by ruixingchen on 16/10/2017.
//  Copyright © 2017 ruixingchen. All rights reserved.
//

import Cocoa

extension URL {
    enum Filestatus {
        case isFile
        case isDir
        case isNot
    }

    var fileStatus: Filestatus {
        get {
            let filestatus: Filestatus
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: self.path, isDirectory: &isDir) {
                if isDir.boolValue {
                    // file exists and is a directory
                    filestatus = .isDir
                }
                else {
                    // file exists and is not a directory
                    filestatus = .isFile
                }
            }
            else {
                // file does not exist
                filestatus = .isNot
            }
            return filestatus
        }
    }

    var fileName:String? {
        get {
            let lastPathComponent = self.lastPathComponent
            let lastDotIndex = lastPathComponent.lastIndex(of: ".")
            if lastDotIndex == nil {
                return lastPathComponent
            }
            let name = String(lastPathComponent[lastPathComponent.startIndex..<lastDotIndex!])
            return name
        }
    }

    var fileExtension:String {
        let exten = self.pathExtension
        return exten
    }

    var parentDirectory:URL {
        return self.deletingLastPathComponent()
    }

}

class HomeViewController: NSViewController, DragViewDelegate {

    @IBOutlet weak var subFolderCheckBox: NSButton!
    @IBOutlet weak var infoLabel: NSTextField!

    var numOfDeleted = 0
    var includeSubFolder:Bool = true

    var dragView:DragView {
        return self.view as! DragView
    }

    var enabledJpgFileExtensions:[String] = ["jpg", "jpeg"]
    var enabledRawFileExtensions:[String] = [
        "3fr", //Hasselblad
        "ari", //Arri_Alexa
        "arw", "srf", "sr2", //Sony
        "bay", //Casio
        "cri", //Cintel
        "crw", "cr2", //Canon
        "cap", "iiq", "eip", //Phase_One
        "dcs", "dcr", "drf", "k25", "kdc", //Kodak
        "dng", //Adobe
        "erf", //Epson
        "fff", //Imacon/Hasselblad raw
        "mef", //Mamiya
        "mdc", //Minolta, Agfa
        "mos", //Leaf
        "mrw", //Minolta, Konica Minolta
        "nef", "nrw", //Nikon
        "orf", //Olympus
        "pef", "ptx", //Pentax
        "pxn", //Logitech
        "R3D", //RED Digital Cinema
        "raf", //Fuji
        "raw", "rw2", //Panasonic
        "raw", "rwl", "dng", //Leica
        "rwz", //Rawzor
        "srw", //Samsung
        "x3f", //Sigma
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        dragView.dragDelegate = self
        //I dont want to rewrite the extension anymore
        for i in 0..<enabledRawFileExtensions.count {
            enabledRawFileExtensions[i] = enabledRawFileExtensions[i].lowercased()
        }
    }

    func dragView(dragView: DragView, draggingEnded sender: NSDraggingInfo) {
        guard let propertyList = sender.draggingPasteboard().propertyList(forType: NSPasteboard.PasteboardType.init("NSFilenamesPboardType")) as? NSArray,
            let path = propertyList[0] as? String
            else {
                print("can not get folder path dragged in")
                return
        }
        print("the folder dragged in:\(path)")

        let url:URL = URL(fileURLWithPath: path)
        if url.fileStatus != .isDir {
            infoLabel.stringValue = "wrong folder dragged in"
            return
        }

        infoLabel.stringValue = "deleting..."
        self.includeSubFolder = self.subFolderCheckBox.state == .on
        self.numOfDeleted = 0
        let startTime = Date().timeIntervalSince1970

        DispatchQueue.global().async {
            self.deleteInFolder(path: url)
            DispatchQueue.main.async {
                self.infoLabel.stringValue = "complete, \(self.numOfDeleted) jpeg pictures deleted in \(String.init(format: "%.4f", Date().timeIntervalSince1970-startTime))"
            }
        }

    }

    fileprivate func deleteInFolder(path:URL) {
        let fm = FileManager.default
        let contents:[URL] = try! fm.contentsOfDirectory(at: path, includingPropertiesForKeys: nil, options: [FileManager.DirectoryEnumerationOptions.skipsHiddenFiles, .skipsPackageDescendants])
        contents.forEach { (url) in

            switch url.fileStatus {
            case .isDir:
                if self.includeSubFolder {
                    deleteInFolder(path: url)
                }
            case .isFile:
                //file
                deletePicture(path: url, siblins: contents)
            default:
                break
            }
        }
    }

    fileprivate func deletePicture(path:URL, siblins:[URL]) {
        guard let fileName = path.fileName else {return}
        let exten = path.fileExtension

        if self.enabledJpgFileExtensions.contains(where: {$0.compare(exten, options: .caseInsensitive, range: nil, locale: nil) == .orderedSame}) {
            //this is a jpg file
            for i in siblins {
                if self.enabledRawFileExtensions.contains(where: {$0.lowercased() == i.fileExtension.lowercased()}) {
                    if let lowerFileName = i.fileName?.lowercased(), lowerFileName == fileName.lowercased() {
                        //this is the releted raw file, so the raw file exists
                        try! FileManager.default.trashItem(at: path, resultingItemURL: nil)
                        self.numOfDeleted += 1
                    }
                }

            }
        }
    }

}

