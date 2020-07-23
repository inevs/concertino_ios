//
//  Library.swift
//  Concertino
//
//  Created by Adriano Brandao on 10/02/20.
//  Copyright © 2020 Open Opus. All rights reserved.
//

import SwiftUI

struct Library: View {
    @EnvironmentObject var AppState: AppState
    
    var body: some View {
        VStack {
            NavigationView {
                VStack {
                    Home()
                    Spacer()
                }
            }
            .padding(.top, UIDevice.current.hasNotch ? -50 : UIDevice.current.isLarge ? -95 : -105)
            .padding(.bottom, -8)
        }
        .clipped()
    }
}

struct Library_Previews: PreviewProvider {
    static var previews: some View {
        Library()
    }
}
