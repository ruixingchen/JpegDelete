//
//  DragView.swift
//  jpgDelete
//
//  Created by ruixingchen on 16/10/2017.
//  Copyright © 2017 ruixingchen. All rights reserved.
//

import Cocoa

protocol DragViewDelegate:class {
    func dragView(dragView:DragView, draggingEnded sender:NSDraggingInfo)
}

class DragView: NSView {

    weak var dragDelegate:DragViewDelegate?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerDrag()
    }

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        registerDrag()
    }

    fileprivate func registerDrag(){
        self.registerForDraggedTypes([NSPasteboard.PasteboardType.URL, NSPasteboard.PasteboardType.fileURL])
    }

    override func draggingEnded(_ sender: NSDraggingInfo) {
        self.dragDelegate?.dragView(dragView: self, draggingEnded: sender)
    }
}
