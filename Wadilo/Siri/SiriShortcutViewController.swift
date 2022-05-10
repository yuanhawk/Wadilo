//
//  SiriShortcutViewController.swift
//  Wadilo
//
//  Created by Tan Li Yuan on 8/5/22.
//

import UIKit
import Intents
import IntentsUI

class SiriShortcutViewController: UIViewController {
    var shortcut: ShortcutManager.Shortcut?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addSiriButton(to: view)
    }
    
    func addSiriButton(to view: UIView) {
        if #available(iOS 12.0, *) {
            let button = INUIAddVoiceShortcutButton(style: .whiteOutline)
            button.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(button)
            view.centerYAnchor.constraint(equalTo: button.centerYAnchor).isActive = true
            view.leadingAnchor.constraint(equalTo: button.leadingAnchor).isActive = true
            view.trailingAnchor.constraint(equalTo: button.trailingAnchor).isActive = true
            setupShortcut(to: button)
        }
    }
        
    func setupShortcut(to button: INUIAddVoiceShortcutButton?) {
        if let shortcut = shortcut {
            button?.shortcut = INShortcut(intent: shortcut.intent)
            button?.delegate = self
        }
    }
}

extension SiriShortcutViewController: INUIAddVoiceShortcutViewControllerDelegate {
    @available(iOS 12.0, *)
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    @available(iOS 12.0, *)
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

extension SiriShortcutViewController: INUIAddVoiceShortcutButtonDelegate {
    @available(iOS 12.0, *)
    func present(_ addVoiceShortcutViewController: INUIAddVoiceShortcutViewController, for addVoiceShortcutButton: INUIAddVoiceShortcutButton) {
        addVoiceShortcutViewController.delegate = self
        addVoiceShortcutViewController.modalPresentationStyle = .formSheet
        present(addVoiceShortcutViewController, animated: true, completion: nil)
    }
    @available(iOS 12.0, *)
    func present(_ editVoiceShortcutViewController: INUIEditVoiceShortcutViewController, for addVoiceShortcutButton: INUIAddVoiceShortcutButton) {
        editVoiceShortcutViewController.delegate = self
        editVoiceShortcutViewController.modalPresentationStyle = .formSheet
        present(editVoiceShortcutViewController, animated: true, completion: nil)
    }
}

extension SiriShortcutViewController: INUIEditVoiceShortcutViewControllerDelegate {
    @available(iOS 12.0, *)
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didUpdate voiceShortcut: INVoiceShortcut?, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    @available(iOS 12.0, *)
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
        controller.dismiss(animated: true, completion: nil)
    }
    @available(iOS 12.0, *)
    func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}
