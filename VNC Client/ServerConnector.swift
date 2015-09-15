//
//  ServerConnector.swift
//  VNC Client
//
//  Created by Alex Barron on 6/20/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import Foundation
import CoreFoundation

class ServerConnector: NSObject, NSStreamDelegate
{
    
    enum state {
        case ProtocolVersion
        case TryingPassword
        case ReceivingAuthenticationResponse
        case Initialisation
        case ReadingRequestHeader
        case ReadingRectHeader
        case ReadingPixelData
    }
    
    let updatePeriod = 2
    
    var firstCon = true
    
    private var currentState = state.ProtocolVersion
    
    var inputStream: NSInputStream?
    var outputStream: NSOutputStream?

    private let VNCport = 5900
    
    private var auther: Authenticator?
    private var fBP: FrameBufferProcessor?
    
    private var password = ""
    
    private let RFBProtocol = "RFB 003.003\n"
    
    func connect(hostIP: String, password: String) {
        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?
        let host: CFString = NSString(string: hostIP)
        let port: UInt32 = UInt32(self.VNCport)
        
        self.password = password
        
        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, host, port, &readStream, &writeStream)
        
        inputStream = readStream!.takeRetainedValue()
        outputStream = writeStream!.takeRetainedValue()
        
        if readStream == nil {
            println("No Read")
        }
        if writeStream == nil {
            println("No Write")
        }
        
        inputStream!.delegate = self
        outputStream!.delegate = self
        
        inputStream!.scheduleInRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        outputStream!.scheduleInRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        inputStream!.open()
        outputStream!.open()
        
        
    }
    
    private func decideProtocolVersion() {
        
        var buffer = StreamReader.readAllFromServer(inputStream)
        var output = NSString(bytes: &buffer, length: buffer.count, encoding: NSASCIIStringEncoding)
        if (output != ""){
            NSLog("server said: %@", output!)
        }
        //send server the decided protocol
        var protocolVersionMessage = [UInt8](RFBProtocol.utf8)
        //change to write all
        outputStream!.write(&protocolVersionMessage, maxLength: protocolVersionMessage.count)
    }
    
    func sendRequest() {
        fBP!.sendRequest()
    }
    
    func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent) {
        switch eventCode {
        case NSStreamEvent.OpenCompleted:
            NSLog("OpenCompleted")
            break
        case NSStreamEvent.ErrorOccurred:
            NSLog("ErrorOccurred")
            NSNotificationCenter.defaultCenter().postNotificationName(serverConnectionErrorNotificationKey, object: self)
            break
        case NSStreamEvent.HasBytesAvailable:
            NSLog("HasBytesAvailiable")
            switch currentState {
            case .ProtocolVersion:
                currentState = state.TryingPassword
                if (aStream == inputStream){
                    decideProtocolVersion()
                }
                break
            case .TryingPassword:
                currentState = state.ReceivingAuthenticationResponse
                auther = Authenticator(inputStream: inputStream, outputStream: outputStream)
                auther!.authenticate(password)
                break
            case .ReceivingAuthenticationResponse:
                if auther!.getAuthStatus() {
                    var confirm: [UInt8] = [1]
                    outputStream!.write(&confirm, maxLength: confirm.count)
                    currentState = state.Initialisation
                }
                break
            case .Initialisation:
                currentState = state.ReadingRequestHeader
                fBP = FrameBufferProcessor(inputStream: inputStream, outputStream: outputStream)
                fBP!.initialise()
                break
            case .ReadingRequestHeader:
                NSLog("ReadingRequestHeader")
                currentState = state.ReadingRectHeader
                fBP!.readHeader()
                break
            case .ReadingRectHeader:
                NSLog("ReadingRectHeader")
                fBP!.readRectHeader()
                currentState = state.ReadingPixelData
                
                break
            case .ReadingPixelData:
                NSLog("ReadingPixelData")
                if firstCon {
                    NSTimer.scheduledTimerWithTimeInterval(0.02, target: self, selector: "sendRequest", userInfo: nil, repeats: true)
                    firstCon = false
                }
                var result = fBP!.getPixelData()
                if  result == 1 {
                    NSLog("ReadingRectHeader")
                    currentState = state.ReadingRectHeader
                }
                else if result == 2 {
                    NSLog("ReadingRequestHeader")
                    currentState = state.ReadingRequestHeader
                }
                break
            }
            
        default: break
        }
    }
}