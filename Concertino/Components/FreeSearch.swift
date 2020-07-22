//
//  ComposerWorkSearch.swift
//  Concertino
//
//  Created by Adriano Brandao on 01/02/20.
//  Copyright © 2020 Open Opus. All rights reserved.
//

import SwiftUI

struct FreeSearch: View {
    @EnvironmentObject var settingStore: SettingStore
    @EnvironmentObject var AppState: AppState
    @EnvironmentObject var omnisearch: OmnisearchString
    @EnvironmentObject var search: WorkSearch
    @EnvironmentObject var playState: PlayState
    @EnvironmentObject var radioState: RadioState
    @State private var composers = [Composer]()
    @State private var works = [Work]()
    @State private var recordings = [Recording]()
    @State private var offset = 0
    @State private var loading = true
    @State private var canPaginate = true
    @State private var paginating = false
    @State private var nextSource = "omnisearch"
    
    init() {
        UITableView.appearance().backgroundColor = .clear
        UITableViewCell.appearance().backgroundColor = .clear
    }
    
    func loadMoreData() {
        paginating = true
        
        getStoreFront() { countryCode in
            APIget(AppConstants.concBackend+"/\(self.nextSource)/\(countryCode ?? "us")/\(self.omnisearch.searchstring)/\(self.offset).json") { results in
                let omniData: Omnisearch = parseJSON(results)
                
                DispatchQueue.main.async {
                    if let recordings = omniData.recordings {
                        
                        for rec in recordings {
                            if !self.recordings.contains(rec) {
                                self.recordings.append(rec)
                            }
                        }
                        
                        if let next = omniData.next {
                            self.offset = next
                        } else if self.nextSource == "omnisearch" {
                            self.offset = 0
                            self.nextSource = "freesearch"
                        } else {
                            self.canPaginate = false
                        }
                        
                        self.paginating = false
                    } else {
                        self.paginating = false
                        
                        if self.nextSource == "omnisearch" {
                            self.offset = 0
                            self.nextSource = "freesearch"
                        } else {
                            self.canPaginate = false
                        }
                    }
                }
            }
        }
    }
    
    func loadData() {
        nextSource = "omnisearch"
        loading = true
        offset = 0
        canPaginate = true
        
        if self.omnisearch.searchstring.count > 3 {
            getStoreFront() { countryCode in
                APIget(AppConstants.concBackend+"/omnisearch/\(countryCode ?? "us")/\(self.omnisearch.searchstring)/\(self.offset).json") { results in
                    let omniData: Omnisearch = parseJSON(results)
                    
                    DispatchQueue.main.async {
                        if let recordings = omniData.recordings {
                            if let next = omniData.next {
                                self.offset = next
                            } else if self.nextSource == "omnisearch" {
                                self.nextSource = "freesearch"
                            }
                            
                            self.recordings.removeAll()
                            self.recordings = recordings
                            self.loading = false
                        } else {
                            APIget(AppConstants.concBackend+"/freesearch/\(countryCode ?? "us")/\(self.omnisearch.searchstring)/\(self.offset).json") { results in
                                let omniData: Omnisearch = parseJSON(results)
                                
                                if let recordings = omniData.recordings {
                                    self.nextSource = "freesearch"
                                    
                                    if let next = omniData.next {
                                        self.offset = next
                                    } else {
                                        self.canPaginate = false
                                    }
                                    
                                    self.recordings.removeAll()
                                    self.recordings = recordings
                                    self.loading = false
                                } else {
                                    self.recordings = [Recording]()
                                }
                                
                                if let composers = omniData.composers {
                                    self.composers.removeAll()
                                    self.composers = composers
                                    self.loading = false
                                } else {
                                    self.composers = [Composer]()
                                }
                                
                                if let works = omniData.works {
                                    self.works.removeAll()
                                    self.works = works
                                    self.loading = false
                                } else {
                                    self.works = [Work]()
                                }
                            }
                        }
                        
                        if let composers = omniData.composers {
                            self.composers.removeAll()
                            self.composers = composers
                            self.loading = false
                        } else {
                            self.composers = [Composer]()
                        }
                        
                        if let works = omniData.works {
                            self.works.removeAll()
                            self.works = works
                            self.loading = false
                        } else {
                            self.works = [Work]()
                        }
                    }
                }
            }
        }
        else {
            DispatchQueue.main.async {
                self.recordings = [Recording]()
                self.works = [Work]()
                self.composers = [Composer]()
                self.loading = false
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            if self.omnisearch.searchstring != "" {
                if self.loading {
                    HStack {
                        Spacer()
                        ActivityIndicator(isAnimating: true)
                        .configure { $0.color = .white; $0.style = .large }
                        Spacer()
                    }
                    .padding(40)
                }
                else {
                    if self.composers.count == 0 && self.works.count == 0 && self.recordings.count == 0 {
                        ErrorMessage(msg: (self.omnisearch.searchstring.count > 3 ? "No matches for: \(self.omnisearch.searchstring)" : "Search term too short"))
                    } else {
                        List {
                            Group {
                                if self.composers.count > 0 {
                                    Section(header:
                                        Text("Composers")
                                            .font(.custom("Barlow-SemiBold", size: 13))
                                            .foregroundColor(Color(hex: 0xFE365E))
                                    ){
                                        ForEach(self.composers, id: \.id) { composer in
                                            Group {
                                                NavigationLink(destination: ComposerDetail(composer: composer).environmentObject(self.settingStore).environmentObject(self.AppState).environmentObject(self.search)) {
                                                    ComposerRow(composer: composer)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                            Group {
                                if self.works.count > 0 {
                                    Section(header:
                                        Text("Works")
                                            .font(.custom("Barlow-SemiBold", size: 13))
                                            .foregroundColor(Color(hex: 0xFE365E))
                                    ){
                                        ForEach(self.works, id: \.id) { work in
                                            NavigationLink(destination: WorkDetail(work: work, composer: work.composer!).environmentObject(self.settingStore)) {
                                                WorkSearchRow(work: work, composer: work.composer!)
                                                    .padding(.top, 6)
                                                    .padding(.bottom, 6)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            Group {
                                if self.recordings.count > 0 {
                                    Section(header:
                                        Text("Recordings")
                                            .font(.custom("Barlow-SemiBold", size: 13))
                                            .foregroundColor(Color(hex: 0xFE365E))
                                    ){
                                        ForEach(self.recordings, id: \.id) { recording in
                                            Group {
                                                if !recording.isCompilation || !self.settingStore.hideIncomplete {
                                                    NavigationLink(destination: RecordingDetail(workId: recording.work!.id, recordingId: recording.apple_albumid, recordingSet: recording.set, isSheet: false).environmentObject(self.settingStore).environmentObject(self.AppState).environmentObject(self.playState).environmentObject(self.radioState), label: {
                                                        RecordingRow(recording: recording)
                                                    })
                                                }
                                            }
                                        }
                                        
                                        if canPaginate {
                                            HStack {
                                                Spacer()
                                                if self.paginating {
                                                    ActivityIndicator(isAnimating: true)
                                                        .configure { $0.color = .white; $0.style = .large }
                                                }
                                                Spacer()
                                            }
                                            .padding(40)
                                            .onAppear() {
                                                self.loadMoreData()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .listStyle(GroupedListStyle())
                        .gesture(DragGesture().onChanged{_ in self.endEditing(true) })
                    }
                }
            }
        }
        .onReceive(omnisearch.objectWillChange, perform: loadData)
        .onAppear(perform: {
            self.endEditing(true)
        })
        .frame(maxWidth: .infinity)
    }
}

struct FreeSearch_Previews: PreviewProvider {
    static var previews: some View {
        EmptyView()
    }
}

