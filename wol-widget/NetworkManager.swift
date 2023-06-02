//
//  NetworkManager.swift
//  wol-widget
//
//  Created by Jan Sallads on 01.06.23.
//

import Foundation
import Network

class NetworkManager: ObservableObject {
    
    @Published var interfaces: [NWInterface] = []
    var savedConnections: [Connection] {
        get {
            if let data = UserDefaults.standard.data(forKey: "savedConnections"),
               let decoded = try? PropertyListDecoder().decode([Connection].self, from: data) {
                return decoded
            }
            return []
        }
        set {
            if let encoded = try? PropertyListEncoder().encode(newValue) {
                UserDefaults.standard.setValue(encoded, forKey: "savedConnections")
                objectWillChange.send()
            }
        }
    }
    @Published var showSuccess: Bool = false
    @Published var showError: Bool = false
    
    init() {
        discover()
    }
    
    func discover() {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.interfaces = path.availableInterfaces
            }
            print(self.interfaces.count)
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
        monitor.start(queue: .global())
    }
    
    func wol(_ macAddress: String) {
        var payload: [UInt8] = [
            0xff, 0xff, 0xff, 0xff, 0xff, 0xff
        ]
        
        //  sanitize macAddress
        let sanMacAddress = macAddress.replacing("-", with: ":")
        
        //  fill up payload
        for _ in 1...16 {
            payload.append(contentsOf: sanMacAddress.split(separator: ":").map({ dataByte in
                UInt8(dataByte, radix: 16) ?? 0x00
            }))
        }
        
        //  send payload
        let payloadData = payload.withUnsafeBufferPointer({ Data(buffer: $0) })
        let nConn = NWConnection(host: .ipv4(.broadcast), port: .init(integerLiteral: 9), using: .udp)
        nConn.send(content: payloadData, completion: .contentProcessed({ err in
            if let err = err {
                print("Error: \(err.localizedDescription)")
                DispatchQueue.main.async {
                    self.showError = true
                }
            } else {
                print("Packet successfully sent")
                DispatchQueue.main.async {
                    self.showSuccess = true
                }
            }
        }))
        nConn.start(queue: .global())
    }
    
    func wolAll() {
        self.savedConnections.forEach({ wol($0.macAddress) })
    }
}
