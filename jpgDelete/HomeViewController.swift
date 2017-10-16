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

    var jpgFileExtensions:[String] = ["jpg","JPG","jpeg","JPEG"]
    var rawFileExtensions:[String] = [
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

    var dragView:DragView {
        return self.view as! DragView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        dragView.dragDelegate = self
        //I dont want to rewrite the extension anymore
        for i in 0..<rawFileExtensions.count {
            rawFileExtensions[i] = rawFileExtensions[i].lowercased()
        }
    }

    func dragView(dragView: DragView, draggingEnded sender: NSDraggingInfo) {
        guard let propertyList = sender.draggingPasteboard().propertyList(forType: NSPasteboard.PasteboardType.init("NSFilenamesPboardType")) as? NSArray,
            let path = propertyList[0] as? String
            else {
                print("can not get folder path")
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
        if fm.fileExists(atPath: path.path, isDirectory: &isDirectory) {
            if !isDirectory.boolValue {
                print("ERROR - the path is not a directory")
                return
            }
            guard let contents = try? fm.contentsOfDirectory(at: path, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) else {
                print("ERROR - get contents of path failed, path:\(path)")
                return
            }
            print("content num:\(contents.count)")
            var subDirectory:ObjCBool = false
            for content in contents {

                if !fm.fileExists(atPath: content.path, isDirectory: &subDirectory) {
                    if jpgFileExtensions.contains(content.pathExtension.lowercased()) {
                        //the jpg file may be deleted just ago, ignore this error
                        continue
                    }else{
                        print("ERROR - the path does not exist, content:\(content)")
                        continue
                    }
                }
                if includeSubfolder && subDirectory.boolValue {
                    deleteJpeg(path: content)
                }else{
                    //delete jpg if needed
                    self.deleteJpegIfNeeded(filePath: content)
                }
            }
        }else{
            print("ERROR - the path not exists")
        }
    }

    func deleteJpegIfNeeded(filePath:URL){
        if !rawFileExtensions.contains(filePath.pathExtension.lowercased()) {
            return
        }
        for jpgFileExtension in jpgFileExtensions {
            let jpgFilePath = filePath.deletingPathExtension().appendingPathExtension(jpgFileExtension)
            var isDirectory:ObjCBool = false
            if !FileManager.default.fileExists(atPath: jpgFilePath.path, isDirectory: &isDirectory) {
                continue
            }
            if !isDirectory.boolValue {
                print("delete \(jpgFilePath)")
                numOfDeleted += 1
                try? FileManager.default.trashItem(at: jpgFilePath, resultingItemURL: nil)
            }
        }
    }


}

