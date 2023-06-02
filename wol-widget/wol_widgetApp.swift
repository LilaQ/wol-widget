//
//  wol_widgetApp.swift
//  wol-widget
//
//  Created by Jan Sallads on 01.06.23.
//

import SwiftUI

@main
struct wol_widgetApp: App {
    var body: some Scene {
        MenuBarExtra("", systemImage: "bolt.horizontal.circle", content: {
            SettingsMenu()
        }).menuBarExtraStyle(.window)
    }
}

struct SettingsMenu: View {
    @StateObject var networkManager: NetworkManager = NetworkManager()
    @State var mac: String = ""
    @State var name: String = ""
    @State var alertString: String? = nil
    let pasteboard = NSPasteboard.general
    
    var isValidMac: Bool {
        mac.contains(":") || mac.contains("-")
    }
    
    var nameAndMacEntered: Bool {
        isValidMac && !name.isEmpty
    }
    
    var body: some View {
        ZStack {
            VStack {
                
                if !networkManager.savedConnections.isEmpty {
                    HStack {
                        Text("Saved Connections")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Spacer()
                        HStack {
                            Text("All")
                                .bold()
                                .foregroundColor(.white)
                            Image(systemName: "arrowshape.right.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 14, height: 14)
                                .foregroundColor(.white)
                        }
                        .padding(5)
                        .background(RoundedRectangle(cornerRadius: 4).fill(.green))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            networkManager.wolAll()
                            self.alertString = "WOL sent to all favorites"
                        }
                    }
                    ForEach(networkManager.savedConnections) { connection in
                        HStack(alignment: .center) {
                            Image(systemName: "trash")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 14, height: 14)
                                .foregroundColor(.red)
                                .onTapGesture {
                                    withAnimation {
                                        networkManager.savedConnections.removeAll(where: { $0.id == connection.id })
                                    }
                                }
                            VStack(alignment: .leading) {
                                Text(connection.name)
                                Text(connection.macAddress)
                                    .foregroundColor(.gray)
                                    .font(.caption2)
                            }
                            Spacer()
                            Image(systemName: "arrowshape.right.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 14, height: 14)
                                .foregroundColor(.green)
                                .onTapGesture {
                                    networkManager.wol(connection.macAddress)
                                }
                                .padding(.trailing, 5)
                        }
                        .onTapGesture {
                            self.alertString = "\(connection.macAddress) copied to clipboard"
                            pasteboard.declareTypes([.string], owner: nil)
                            pasteboard.setString(connection.macAddress, forType: .string)
                        }
                        Divider()
                    }
                }
                
                Text("Add / Run Connection")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack(alignment: .bottom) {
                    VStack {
                        TextField("Mac", text: $mac)
                            .disabled(alertString != nil)
                        TextField("Name", text: $name)
                            .disabled(alertString != nil)
                    }
                    VStack {
                        Button("run") {
                            networkManager.wol(mac)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!isValidMac)
                        .opacity(isValidMac ? 1.0 : 0.5)
                        
                        Button("add") {
                            networkManager.savedConnections.append(Connection(name: name, macAddress: mac))
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!nameAndMacEntered)
                        .opacity(nameAndMacEntered ? 1.0 : 0.5)
                    }
                }
                
                Button("Quit") {
                    exit(1)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .padding(.top, 20)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            
            if let alert = alertString {
                Text(alert)
                    .padding(20)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white, lineWidth: 2.0))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.alertString = nil
                        }
                    }
            }
        }
        .animation(.easeInOut, value: alertString)
        .padding(20)
        .onChange(of: networkManager.showError) { _ in
            self.alertString = "Error while sending WOL!"
        }
        .onChange(of: networkManager.showSuccess) { _ in
            self.alertString = "WOL successfully sent!"
        }
    }
}

struct Connection: Codable, Identifiable {
    var id: String = UUID().uuidString
    let name: String
    let macAddress: String
}
