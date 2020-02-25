//
//  ViewController.swift
//  DarkPawControl
//
//  Created by yobo on 2020/02/09.
//  Copyright © 2020 wonlab. All rights reserved.
//

import UIKit
import SwiftSocket
//import SwiftyZeroMQ
import SwiftWebSocket

@objcMembers
class ViewController: UIViewController {

    @IBOutlet weak var previewImgeView: UIImageView!
    
    private var controlClient: TCPClient?
    
    private var infoListener: TCPServer?
    
    private var imageListener: TCPServer?
    
    //private var subscriber: SwiftyZeroMQ.Socket?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        connect()
        //initImageListener()
    }

    private func connect() {
        controlClient = TCPClient(address: "192.168.1.67", port: 10223)
        
        switch controlClient?.connect(timeout: 10) {
        case .success:
            print("connected")
            initInfoListener()
            initImageListener()
        case .failure(let error):
            print("err:\(error.localizedDescription)")
        case .none:
            print("unknown err")
        }
        
    }
    
    private func initImageListener() {
        //DispatchQueue(label: "image.robot").async {
            let ws = WebSocket("ws://192.168.1.67:5555")
            
            //ws.allowSelfSignedSSL = true
            ws.event.open = {
                print("opened")
            }
            ws.event.message = { message in
                if let message = message as? [Byte] {
                    if let base64String = String(data: Data(message),encoding: .utf8) {
                        let dataDecoded = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters)!
                        DispatchQueue.main.async {
                            self.previewImgeView.image = UIImage(data: dataDecoded)
                        }
                    }
                }
            }
            //ws.delegate = self
            ws.open()
        //}
    }
    
    private func initInfoListener() {
        DispatchQueue(label: "info.robot").async {
            self.infoListener = TCPServer(address: "192.168.1.31", port: 2256)
            switch self.infoListener?.listen() {
            case .success:
                if let client = self.infoListener?.accept() {
                    defer { client.close() }
                    while true {
                        let response = client.read(1024, timeout: 0)
                        if let response = response {
                            if let infoStr = String(data:  Data(response),encoding: .utf8) {
                                print(infoStr)
                            }
                        }
                    }
                } else {
                    print("infoListener accept error")
                }
            case .failure(let error):
                print("infoListener err:\(error.localizedDescription)")
            case .none:
                print("infoListener unknown err")
           }
        }
    }
//
//    private func initImageListener() {
//        DispatchQueue(label: "image.robot").async {
//            do {
//                let context = try SwiftyZeroMQ.Context()
//                self.subscriber = try context.socket(.subscribe)
//                //try self.subscriber?.setSubscribe("")
//                try self.subscriber?.bind("tcp://127.0.0.1:5555")
//                while true {
//                    print("start get image")
//                    let result = try? self.subscriber?.recv(bufferLength: 1024 * 10, options: .none)
//
//                    //let result = try? self.subscriber?.recv(options: .none)
//                    //let result = try? self.subscriber?.recv()
//                    print("start check image")
//                    if let result = result {
//                        print("image data: \(result)")
//                    }
//                }
////                DispatchQueue.main.async {
////                    Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(ViewController.updateImage), userInfo: nil, repeats: true)
////                }
//                //while true {
//
//                //let result = try subscriber.recv
//
//                //}
//            } catch {
//                print("initImageListener err")
//            }
//        }
//    }
//
//    @objc private func updateImage() {
//        print("start get image")
//        let result = try? self.subscriber?.recv(bufferLength: 1024 * 100, options: .dontWait)
//        //let result = try? self.subscriber?.recv()
//        print("start check image")
//        if let result = result {
//            print("image data: \(result)")
//        }
//    }
    
//    private func initImageListener() {
//        DispatchQueue(label: "image.robot").async {
//            self.imageListener = TCPServer(address: "127.0.0.1", port: 5555)
//            switch self.imageListener?.listen() {
//            case .success:
//                print("imageListener accept start")
//                if let client = self.imageListener?.accept() {
//                    //defer { client.close() }
//                    //var data = [Byte]()
//                    while true {
//                        print("start read image")
//                        guard let data = client.read(1024 * 1000, timeout: 1) else {
//                            print("skip read image")
//                            continue
//                        }
//
//                        print("data not nil: \(data)")
//                        //data = data + tmp
//                        //if data.count <= 0 {
//                            print("divide data")
//                            if let base64String = String(data: Data(data),encoding: .utf8) {
//                                let dataDecoded = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters)!
//                                //data.removeAll()
//                                DispatchQueue.main.async {
//                                    self.previewImgeView.image = UIImage(data: dataDecoded)
//                                }
//                            } else {
//                                print("failed to base64String data")
//                                //data.removeAll()
//                            }
//                        //} else {
//                            print("recived data")
//                        //}
//                    }
//                } else {
//                    print("imageListener accept error")
//                }
//            case .failure(let error):
//                print("imageListener err:\(error.localizedDescription)")
//            case .none:
//                print("imageListener unknown err")
//           }
//        }
//    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        controlClient?.close()
        infoListener?.close()
        imageListener?.close()
    }
}

//extension ViewController: WebSocketDelegate {
//    func webSocketOpen() {
//        print("opened")
//    }
//
//    func webSocketClose(_ code: Int, reason: String, wasClean: Bool) {
//        print("closed")
//    }
//
//    func webSocketError(_ error: NSError) {
//        print("error")
//    }
//
//    @objc func webSocketMessageData(_ data: Data) {
//        print("message is data")
//    }
//
//    @objc func webSocketMessageText(_ text: String) {
//        print("message is text")
//    }
//}

