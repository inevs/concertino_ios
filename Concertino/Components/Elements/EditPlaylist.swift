//
//  EditPlaylist.swift
//  Concertino
//
//  Created by Adriano Brandao on 26/03/20.
//  Copyright © 2020 Open Opus. All rights reserved.
//

import SwiftUI

struct EditPlaylistButtons: View {
    @Binding var deletePlaylist: Bool
    @Binding var selectedRecordings: [Recording]
    @Binding var editPlaylistName: String
    @State var isLoading = false
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var settingStore: SettingStore
    var playlistId: String
    var playlistName: String

    var body: some View {
        HStack {
            Button(action: {
                self.presentationMode.wrappedValue.dismiss()
            }, label: {
                Text("Cancel")
                    .foregroundColor(Color.lightRed)
                    .font(.custom("Barlow-Regular", size: 14))
            })
            
            Spacer()
            
            Button(action: {
                if self.deletePlaylist {
                    self.isLoading = true
                    APIpost("\(AppConstants.concBackend)/dyn/playlist/delete/", parameters: ["id": self.settingStore.userId, "auth": authGen(userId: self.settingStore.userId, userAuth: self.settingStore.userAuth) ?? "", "pid": self.playlistId]) { results in
                    
                        print(String(decoding: results, as: UTF8.self))
                        if let playlistRecording: PlaylistRecording = safeJSON(results) {
                            DispatchQueue.main.async {
                                self.isLoading = false
                                self.presentationMode.wrappedValue.dismiss()
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                                self.settingStore.playlists = playlistRecording.list
                                UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController?.showToast(message: "Deleted!", image: "checked", text: nil)
                            }
                        }
                    }
                } else if self.selectedRecordings.count > 0 || (self.editPlaylistName != "" && self.editPlaylistName != self.playlistName) {
                    self.isLoading = true
                    APIpost("\(AppConstants.concBackend)/dyn/playlist/edit/", parameters: ["id": self.settingStore.userId, "auth": authGen(userId: self.settingStore.userId, userAuth: self.settingStore.userAuth) ?? "", "pid": self.playlistId, "rid": (self.selectedRecordings.count > 0 ? self.selectedRecordings.map({$0.id}).joined(separator:",") : ""), "name": (self.editPlaylistName != "" && self.editPlaylistName != self.playlistName ? self.editPlaylistName : "")]) { results in
                    
                        print(String(decoding: results, as: UTF8.self))
                        if let playlistRecording: PlaylistRecording = safeJSON(results) {
                            DispatchQueue.main.async {
                                self.isLoading = false
                                self.presentationMode.wrappedValue.dismiss()
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                                self.settingStore.playlists = playlistRecording.list
                                UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController?.showToast(message: "Edited!", image: "checked", text: nil)
                            }
                        }
                    }
                }
                else {
                    self.presentationMode.wrappedValue.dismiss()
                }
            }, label: {
                if self.isLoading {
                    ActivityIndicator(isAnimating: true)
                        .configure { $0.color = Color.lightRed.uiColor(); $0.style = .medium }
                } else {
                    Text("Done")
                        .foregroundColor(Color.lightRed)
                        .font(.custom("Barlow-SemiBold", size: 14))
                }
            })
        }
    }
}

struct EditPlaylist: View {
    @State var editPlaylistName = ""
    @State var deletePlaylist = false
    @State var selectedRecordings = [Recording]()
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var settingStore: SettingStore
    var playlistId: String
    var playlistName: String
    var recordings: [Recording]
    
    var body: some View {
        VStack(alignment: .leading) {
            //if !UIDevice.current.is14 {
                EditPlaylistButtons(deletePlaylist: self.$deletePlaylist, selectedRecordings: self.$selectedRecordings, editPlaylistName: self.$editPlaylistName, playlistId: self.playlistId, playlistName: self.playlistName)
                    .padding(.bottom, 26)
            //}
            
            Text("Rename playlist".uppercased())
                .font(.custom("Nunito-ExtraBold", size: 13))
                .foregroundColor(Color.lightRed)
            Text("Change the name of this playlist")
                .font(.custom("Barlow-Regular", size: 16))
                .padding(.bottom, 4)
            
            TextField(self.playlistName, text: $editPlaylistName)
                .textFieldStyle(EditFieldStyle())
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .foregroundColor(.black)
                )
            
            Text("Delete playlist".uppercased())
                .font(.custom("Nunito-ExtraBold", size: 13))
                .foregroundColor(Color.lightRed)
                .padding(.top, 26)
            HStack {
                Toggle(isOn: $deletePlaylist) {
                    Text("Permanently remove this playlist")
                    .font(.custom("Barlow-Regular", size: 16))
                }
                .padding(.bottom, 4)
                .padding(.top, -16)
            }
            
            Text("Remove recordings".uppercased())
                .font(.custom("Nunito-ExtraBold", size: 13))
                .foregroundColor(Color.lightRed)
                .padding(.top, 26)
            Text("Remove selected recordings from this playlist")
                .font(.custom("Barlow-Regular", size: 16))
                .padding(.bottom, 4)
            
            ScrollView(showsIndicators: false) {
                ForEach(self.recordings, id: \.id) { recording in
                    RecordingRemover(recording: recording, playlistId: self.playlistId, selectedRecordings: self.$selectedRecordings)
                }
            }
            .gesture(DragGesture().onChanged{_ in self.endEditing(true) })
            
            Spacer()
            
            /*
            Group {
                
                
                if UIDevice.current.is14 {
                    EditPlaylistButtons(deletePlaylist: self.$deletePlaylist, selectedRecordings: self.$selectedRecordings, editPlaylistName: self.$editPlaylistName, playlistId: self.playlistId, playlistName: self.playlistName)
                        .padding(.top, 26)
                }
            }
            */
        }
        .padding(30)
        .onAppear(perform: {
            self.editPlaylistName = self.playlistName
        })
    }
}

struct EditPlaylist_Previews: PreviewProvider {
    static var previews: some View {
        EmptyView()
    }
}
