//
//  ViewController.swift
//  jpgDelete
//
//  Created by ruixingchen on 16/10/2017.
//  Copyright © 2017 ruixingchen. All rights reserved.
//

import Cocoa

class HomeViewController: NSViewController, DragViewDelegate {

    @IBOutlet weak var subFolderCheckBox: NSButton!
    @IBOutlet weak var infoLabel: NSTextField!
    @IBOutlet weak var indicator: NSProgressIndicator!

    var dragView:DragView {
        return self.view as! DragView
    }

    var enabledJpgFileExtensions:[String] = ["jpg", "JPG", "jpeg", "JPEG"]
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

    var includeSubfolder:Bool = true

    var numOfDeleted:Int = 0
    var startTime:TimeInterval = 0

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

        infoLabel.stringValue = "deleting..."
        indicator.isHidden = false
        indicator.startAnimation(nil)
        includeSubfolder = subFolderCheckBox.state == NSControl.StateValue.on
        numOfDeleted = 0
        startTime = Date().timeIntervalSince1970

        let url = URL.init(fileURLWithPath: path)
        DispatchQueue.global().async {
            self.deleteJpeg(path: url)
            DispatchQueue.main.async {
                self.infoLabel.stringValue = "complete, \(self.numOfDeleted) pictures deleted in \(String.init(format: "%.4f", Date().timeIntervalSince1970-self.startTime))"
                self.indicator.stopAnimation(nil)
                self.indicator.isHidden = true
            }
        }
    }

    fileprivate func deleteJpeg(path:URL){
        let fm = FileManager.default
        var isDirectory:ObjCBool = false

        if !fm.fileExists(atPath: path.path, isDirectory: &isDirectory) {
            print("ERROR - the path to delete does not exist")
            return
        }
        if isDirectory.boolValue {
            guard let contents = try? fm.contentsOfDirectory(at: path, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles) else {
                print("can not enumerate content of \(path.path)")
                return
            }
            for content in contents {
                deleteJpeg(path: content)
            }
        }else {
            //it is a file
            let rawFileExtension = path.pathExtension
            if !self.enabledRawFileExtensions.contains(rawFileExtension.lowercased()) {
                return
            }
            for i in self.enabledJpgFileExtensions {
                let jpgFilePath = path.deletingPathExtension().appendingPathExtension(i)
                var jpgFilePathIsDirectory:ObjCBool = false
                if !fm.fileExists(atPath: jpgFilePath.path, isDirectory: &jpgFilePathIsDirectory) {
                    return
                }
                if jpgFilePathIsDirectory.boolValue {
                    return
                }
                try? fm.trashItem(at: jpgFilePath, resultingItemURL: nil)
                numOfDeleted += 1
            }

        }

    }
}

