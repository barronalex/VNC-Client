//
//  ViewController.swift
//  VNC Client
//
//  Created by Alex Barron on 6/20/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import UIKit
import CoreGraphics

class ViewController: UIViewController {
    
    var servCon = ServerConnector()
    var firstCon = true

    @IBOutlet weak var desktopView: UIImageView!
    
    @IBOutlet weak var hostField: UITextField!
    @IBOutlet weak var passField: UITextField!
    @IBOutlet weak var connectButton: UIButton!
    
    let scrollViewSize = CGSize(width: 1680/3, height: 1050/2)
    
    private func addNotificationObservers() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "actOnConnection", name: connectedNotificationKey, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "actOnServerError", name: serverConnectionErrorNotificationKey, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "actOnWrongPassword", name: wrongPasswordNotificationKey, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "actOnPixelData:", name: pixelDataNotificationKey, object: nil)

    }
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBAction func connectToServer() {
        addNotificationObservers()
        servCon.connect(hostField.text, password: passField.text)
        var size = scrollViewSize
        scrollView.contentSize = size

    }
    
    func actOnConnection() {
        println("Connected!")
        
    }
    
    func actOnServerError() {
        println("Server Error")
    }
    
    func actOnWrongPassword() {
        println("Wrong Password")
    }
    
    func actOnPixelData(notification: NSNotification) {
        
        println("Pixel data arriving!")
        var dataMap: Dictionary<String,PixelRectangle> = notification.userInfo as! Dictionary<String,PixelRectangle>
        var pixelRect = dataMap["data"]
        
        desktopView.image = pixelRect!.image
        desktopView.setNeedsDisplay()
        
    }

    
}

