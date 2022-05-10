//
//  ShortcutButtonView.swift
//  Wadilo
//
//  Created by Tan Li Yuan on 8/5/22.
//

import SwiftUI

struct SiriButtonView: UIViewControllerRepresentable {
    var shortcut: ShortcutManager.Shortcut
    
    func makeUIViewController(context: Context) -> SiriShortcutViewController {
        let controller = SiriShortcutViewController()
        controller.shortcut = shortcut
        return controller
    }

    func updateUIViewController(_ uiViewController: SiriShortcutViewController, context: Context) {
        
    }
}
