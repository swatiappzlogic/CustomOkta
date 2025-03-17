//
//  WebSocketManager.swift
//  WinkApp
//
//  Created by MacBook on 28/11/24.
//

import UIKit
import Foundation
import Network

// Define the Message struct
struct Message: Codable {
    let type: String
    let description: String
}

// WebSocketManager Class
class WebSocketManager: NSObject, URLSessionDelegate {
    
    // Singleton instance for the manager
    static let shared = WebSocketManager()
    
    // WebSocket Task
    private var webSocketTask: URLSessionWebSocketTask?
    
    // URLSession instance to handle WebSocket connections
    private var urlSession: URLSession!
    
    // Delegate to inform about connection and message events
    var delegate: WebSocketManagerDelegate?
    
    // Private initializer to restrict instantiation
    private override init() {
        super.init()
        let configuration = URLSessionConfiguration.default
        urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }
    
    func sendData(_ data: Data) {
            webSocketTask?.send(.data(data)) { error in
                if let error = error {
                    print("Error sending data: \(error)")
                }
            }
        }
        
    func sendDataChunks(imageData: Data) {
           let chunkSize = 1024 // 1KB chunks
           let numberOfChunks = (imageData.count + chunkSize - 1) / chunkSize
           
           for i in 0..<numberOfChunks {
               let start = i * chunkSize
               let end = min((i + 1) * chunkSize, imageData.count)
               let chunk = imageData.subdata(in: start..<end)
               
               // Send the chunk as Data
               sendData(chunk)
               print("Sent chunk \(i + 1) of \(numberOfChunks)")
           }
       }
    
    func sendBase64Chunks(base64String: String) {
        let chunkSize = 1024 // 1KB chunks
        let numberOfChunks = (base64String.count + chunkSize - 1) / chunkSize

        for i in 0..<numberOfChunks {
            // Calculate the start and end indices for the chunk
            let start = base64String.index(base64String.startIndex, offsetBy: i * chunkSize)
            let end = base64String.index(start, offsetBy: min(chunkSize, base64String.count - i * chunkSize))

            // Slice the string using the range
            let chunk = base64String[start..<end]

            // Send each chunk as a message
            sendMessage(String(chunk))
            print("Sent chunk \(i + 1) of \(numberOfChunks)")
        }
    }

    
    // Connect to WebSocket server
    func connect(to url: String) {
        guard let url = URL(string: url) else {
            print("Invalid URL.")
            return
        }
        
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        
        // Notify delegate that the WebSocket has connected
        delegate?.webSocketDidConnect(self)
        
        // Start receiving messages
        receiveMessage()
    }
    
    // Send a message to the WebSocket server
    func sendMessage(_ message: String) {
        let message = URLSessionWebSocketTask.Message.string(message)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("Error sending message: \(error)")
            }
        }
    }
    
    // Disconnect from the WebSocket server
    func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
    }
    
    // Receive messages from the WebSocket server
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let string):
                    print("Received string message: \(string)")
                    self?.handleMessage(string)
                case .data(let data):
                    print("Received data message: \(data)")
                    self?.handleMessageData(data)
                @unknown default:
                    break
                }
                
                // Continue listening for the next message
                self?.receiveMessage()
                
            case .failure(let error):
                print("Error receiving message: \(error)")
                self?.delegate?.webSocket(self!, didFailToReceiveMessageWithError: error)
            }
        }
    }
    
    // Handle string messages (parse them into Message struct)
    private func handleMessage(_ string: String) {
        if let data = string.data(using: .utf8), let message = decodeMessage(data: data) {
            handleDecodedMessage(message)
        } else {
            print("Failed to decode string message.")
        }
    }
    
    // Handle data messages (parse them into Message struct)
    private func handleMessageData(_ data: Data) {
        if let message = decodeMessage(data: data) {
            handleDecodedMessage(message)
        } else {
            print("Failed to decode data message.")
        }
    }
    
    // Decode the data into a Message object
    private func decodeMessage(data: Data) -> Message? {
        do {
            let decodedMessage = try JSONDecoder().decode(Message.self, from: data)
            return decodedMessage
        } catch {
            print("Failed to decode data: \(error)")
            return nil
        }
    }
    
    // Handle different message types after decoding
    private func handleDecodedMessage(_ message: Message) {
        
        switch message.type {
            
        case "sync-message":
            print("Sync message received: \(message.description)")
            delegate?.webSocket(self, didReceiveSyncMessage: message)
        case "debug":
            print("Debug message received: \(message.description)")
            delegate?.webSocket(self, didReceiveDebugMessage: message)
        case "oAuthRequestId":
            print("oAuthRequestId: \(message.description)")
            delegate?.webSocket(self, didReceiveoAuthRequestIdMessage: message)
        case "existing-account":
            print("existing-account: \(message.description)")
            delegate?.webSocket(self, didReceiveExistingaccountMessage: message)
        case "token":
            print("token: \(message.description)")
            delegate?.webSocket(self, didReceiveTokenMessage: message)
        default:
            print("Unknown message type: \(message.type)")
            delegate?.webSocket(self, didReceiveUnknownMessage: message)
        }
    }
}

// MARK: - WebSocketManagerDelegate Protocol

protocol WebSocketManagerDelegate: AnyObject {
    func webSocket(_ manager: WebSocketManager, didReceiveMessage message: String)
    func webSocket(_ manager: WebSocketManager, didReceiveData data: Data)
    func webSocket(_ manager: WebSocketManager, didFailToReceiveMessageWithError error: Error)
    func webSocketDidConnect(_ manager: WebSocketManager)
    func webSocketDidDisconnect(_ manager: WebSocketManager, error: Error?)
    
    // New delegate methods for different message types
    func webSocket(_ manager: WebSocketManager, didReceiveDebugMessage message: Message)
    func webSocket(_ manager: WebSocketManager, didReceiveSyncMessage message: Message)
    func webSocket(_ manager: WebSocketManager, didReceiveoAuthRequestIdMessage message: Message)
    func webSocket(_ manager: WebSocketManager, didReceiveExistingaccountMessage message: Message)
    func webSocket(_ manager: WebSocketManager, didReceiveTokenMessage message: Message)
    func webSocket(_ manager: WebSocketManager, didReceiveUnknownMessage message: Message)
}
