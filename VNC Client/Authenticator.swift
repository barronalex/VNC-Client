//
//  Authenticator.swift
//  VNC Client
//
//  Created by Alex Barron on 6/21/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import Foundation

class Authenticator
{
    private var inputStream: NSInputStream?
    private var outputStream: NSOutputStream?
    
    init(inputStream: NSInputStream?, outputStream: NSOutputStream?) {
        self.inputStream = inputStream
        self.outputStream = outputStream
    }
    
    func authenticate(password: String) {
        var buffer = StreamReader.readAllFromServer(inputStream)
        var authenticationType = buffer[3]
        println("\(authenticationType)")
        switch authenticationType {
        case 2:
            buffer.removeRange(0...3)
            replyWithPassword(buffer, password: password)
            break
        default:
            NSNotificationCenter.defaultCenter().postNotificationName(serverConnectionErrorNotificationKey, object: self)
            
            
            println("First char: \(buffer[9])")
            var reason = buffer[8...65]
            for index in reason {
                var char = CChar(index)
                println("\(char)")
            }
        }
        
    }
    
    func getAuthStatus() -> Bool {
        //either want to prompt to try a new password
        //or inform the user that we are connected!!!
        var buffer = StreamReader.readAllFromServer(inputStream)
        println("\(buffer[3])")
        var authstatus = buffer[3]
        switch authstatus {
        case 0:
            NSLog("Connected!")
            NSNotificationCenter.defaultCenter().postNotificationName(connectedNotificationKey, object: self)
            return true
        case 1:
            NSLog("Wrong Password!")
            NSNotificationCenter.defaultCenter().postNotificationName(wrongPasswordNotificationKey, object: self)
            inputStream!.close()
            outputStream!.close()
            return false
        case 2:
            NSLog("Too many attempts")
            inputStream!.close()
            outputStream!.close()
            return false
        default:
            return false
        }
    }
    
    private func encryptChallenge(var challenge: [UInt8], keyBytes: [UInt8]) -> [UInt8] {
        var challenge2 = challenge
        challenge.removeRange(8...15)
        challenge2.removeRange(0...7)
        var first8bytes = NSData(bytes: challenge, length: 8)
        var second8bytes = NSData(bytes: challenge2, length: 8)
        var key = NSData(bytes: keyBytes, length: keyBytes.count)
        println("Key: \(key)")
        println("First half: \(first8bytes)")
        println("Second half: \(second8bytes)")
        var firstHalfOfResult = DESEncryptor.encryptData(first8bytes, key: key)
        println("First Result: \(firstHalfOfResult)")
        var secondHalfOfResult = DESEncryptor.encryptData(second8bytes, key: key)
        println("Second Result: \(secondHalfOfResult)")
        var firstHalfResponse = [UInt8](count: 8, repeatedValue: 0)
        var secondHalfResponse = firstHalfResponse
        firstHalfOfResult.getBytes(&firstHalfResponse, length: 8)
        secondHalfOfResult.getBytes(&secondHalfResponse, length: 8)
        return firstHalfResponse + secondHalfResponse
    }
    
    private func flipPassword(password: String) -> [UInt8] {
        var passBytes = [UInt8](password.utf8)
        var flippedBytes = [UInt8](count: 8, repeatedValue: 0)
        //need a function which takes a UInt8 and flips the bits
        for i in 0...7 {
            if i < passBytes.count {
                var byte = passBytes[i]
                byte = (byte & 0xF0) >> 4 | (byte & 0x0F) << 4;
                byte = (byte & 0xCC) >> 2 | (byte & 0x33) << 2;
                byte = (byte & 0xAA) >> 1 | (byte & 0x55) << 1;
                flippedBytes[i] = byte
            }
            else {
                //null pad flipped key
                flippedBytes[i] = 0
            }
        }
        return flippedBytes
    }
    
    private func replyWithPassword(var challenge: [UInt8], password: String) {
        var keyBytes = flipPassword(password)
        var response = encryptChallenge(challenge, keyBytes: keyBytes)
        outputStream!.write(&response, maxLength: response.count)
    }
}
