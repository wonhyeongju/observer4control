//
//  ViewController.swift
//  DarkPawControl
//
//  Created by yobo on 2020/02/09.
//  Copyright © 2020 wonlab. All rights reserved.
//

import UIKit
import SwiftSocket
import SwiftWebSocket

@objcMembers
class ViewController: UIViewController {

    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var previewImgeView: UIImageView!
    
    private var controlClient: TCPClient?
    
    private var infoListener: TCPServer?
    
    private var imageListener: WebSocket?
    
    private var moveEventFinished = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        connect()
    }
    
    @IBAction func moveForward(_ sender: Any) {
        if moveEventFinished {
            moveEventFinished = false
            let _ = controlClient?.send(data: Array("forward".utf8))
            delayMoveEventSetFinish()
        }
    }
    
    @IBAction func moveBackward(_ sender: Any) {
        if moveEventFinished {
            moveEventFinished = false
            let _ = controlClient?.send(data: Array("backward".utf8))
            delayMoveEventSetFinish()
        }
    }
    
    @IBAction func rotateLeft(_ sender: Any) {
        if moveEventFinished {
            moveEventFinished = false
            let _ = controlClient?.send(data: Array("left".utf8))
            delayMoveEventSetFinish()
        }
    }
    
    @IBAction func rotateRight(_ sender: Any) {
        if moveEventFinished {
            moveEventFinished = false
            let _ = controlClient?.send(data: Array("right".utf8))
            delayMoveEventSetFinish()
        }
    }
    
    @IBAction func moveEventStop(_ sender: Any) {
        let _ = controlClient?.send(data: Array("DS".utf8))
    }
    
    @IBAction func turnEventStop(_ sender: Any) {
        let _ = controlClient?.send(data: Array("TS".utf8))
    }
    
    private func delayMoveEventSetFinish() {
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            self.moveEventFinished = true
        }
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
        imageListener = WebSocket("ws://192.168.1.67:5555")
        imageListener?.event.open = {
            print("opened")
        }
        imageListener?.event.message = { message in
            if let message = message as? [Byte] {
                if let base64String = String(data: Data(message),encoding: .utf8) {
                    let dataDecoded = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters)!
                    DispatchQueue.main.async {
                        self.previewImgeView.image = UIImage(data: dataDecoded)
                    }
                }
            }
        }
        imageListener?.open()
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
                                let infoSet = infoStr.split(separator: " ")
                                DispatchQueue.main.async { [weak self] in
                                    self?.statusLabel?.text = "tmp: \(infoSet[0])%  cpu: \(infoSet[1])%  ram: \(infoSet[2])%"
                                }
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        controlClient?.close()
        infoListener?.close()
        imageListener?.close()
    }
}
