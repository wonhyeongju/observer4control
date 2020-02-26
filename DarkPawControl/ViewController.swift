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

    @IBOutlet weak var previewImgeView: UIImageView!
    
    private var controlClient: TCPClient?
    
    private var infoListener: TCPServer?
    
    private var imageListener: WebSocket?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        connect()
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        controlClient?.close()
        infoListener?.close()
        imageListener?.close()
    }
}
