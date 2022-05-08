//
//  ContentView.swift
//  Wadilo
//
//  Created by Tan Li Yuan on 8/5/22.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        SiriButtonView(shortcut: ShortcutManager.Shortcut.test)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
