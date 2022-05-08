import Intents
import UIKit
import IntentsUI
/**
 This sample code is available under the MIT license.
 */

@available(iOS 12.0, *)
public final class ShortcutManager {

    /**
     This enum specifies the different intents available in our app and their various properties for the `INIntent`.
     Replace this with your own shortcuts.
     */
    public enum Shortcut {
        case test

        var defaultsKey: String {
            switch self {
            case .test: return "Test command"
            }
        }

        var intent: INIntent {
            let intent: INIntent
            switch self {
            case .test: intent = VoiceAssistantIntent()
            }

            print("Running")
            intent.suggestedInvocationPhrase = suggestedInvocationPhrase

            return intent
        }

        var suggestedInvocationPhrase: String? {
            switch self {
            case .test: return "Test command"
            }
        }
    }

    // MARK: Properties
    /// A shared shortcut manager.
    public static let shared = ShortcutManager()

    /// Keeps a list of `INUIAddVoiceShortcutViewControllerDelegate` proxy objects.
    private var delegates: [String: DelegateProxy] = [:]

    // MARK: API
    /**
     Displays a `INUIAddVoiceShortcutViewController` or `INUIEditVoiceShortcutViewController` for the given shortcut.
     - Parameter shortcut: The shortcut to show add voice view controller for.
     - Parameter viewController: The view controller in which the add/edit voice view controller should be presented.
     - Parameter delegate: A delegate listening for actions in the presented system view controller.
     */
    public func showShortcutsPhraseViewController(
        for shortcut: Shortcut,
        in viewController: UIViewController,
        delegate: ShortcutManagerDelegate
    ) {
        let delegateProxy = DelegateProxy(delegate: delegate) { [weak self] in
            self?.delegates[shortcut.defaultsKey] = nil
        }
        delegates[shortcut.defaultsKey] = delegateProxy
        loadShortcut(for: shortcut) { recordedVoiceShortcut in
            if let recordedVoiceShortcut = recordedVoiceShortcut {
                let editController = INUIEditVoiceShortcutViewController(voiceShortcut: recordedVoiceShortcut)
                editController.delegate = delegateProxy
                viewController.present(editController, animated: true, completion: nil)
            } else {
                if let shortcut = INShortcut(intent: shortcut.intent) {
                    let shortcutViewController = INUIAddVoiceShortcutViewController(shortcut: shortcut)
                    shortcutViewController.delegate = delegateProxy
                    viewController.present(shortcutViewController, animated: true, completion: nil)
                }
            }
        }
    }

    /**
     Returns the recorded phrase for the given shortcut.
     - Parameter shortcut: The shortcut to fetch a phrase for.
     - Parameter callback: A function called with the recorded phrase, if any.
     - Parameter phrase: The recorded phrase.
     */
    public func recordedPhrase(for shortcut: Shortcut, callback: @escaping (_ phrase: String?) -> Void) {
        loadShortcut(for: shortcut) { callback($0.map { $0.invocationPhrase }) }
    }

    // MARK: Internal API
    /// Load specific shortcut. Result is cached in `UserDefaults` as a `UUID` reference.
    private func loadShortcut(for shortcut: Shortcut, callback: @escaping (INVoiceShortcut?) -> Void) {
        loadStoredShortcut(with: shortcut.defaultsKey) { [weak self] recordedVoiceShortcut in
            if let recordedVoiceShortcut = recordedVoiceShortcut {
                DispatchQueue.main.async { callback(recordedVoiceShortcut) }
            } else {
                let intentType = type(of: shortcut.intent)
                self?.findSpecificShortcut(of: intentType, with: shortcut.defaultsKey) { recordedVoiceShortcut in
                    DispatchQueue.main.async { callback(recordedVoiceShortcut) }
                }
            }
        }
    }

    /**
     Checks the system for a specific shortcut recording.
     - Parameter key: The key for which the UUID of the requested shortcut is stored by.
     - Parameter callback: A function that is handed any found voice shortcut.
     - Parameter shortcut: The found `INVoiceShortcut` if any.
     */
    private func loadStoredShortcut(with key: String, callback: @escaping (_ shortcut: INVoiceShortcut?) -> Void) {
        if let shortcutID = UserDefaults.standard.string(forKey: key).flatMap(UUID.init(uuidString:)) {
            INVoiceShortcutCenter.shared.getVoiceShortcut(with: shortcutID) { shortcut, _ in
                callback(shortcut)
                if shortcut == nil {
                    UserDefaults.standard.removeObject(forKey: key)
                }
            }
        } else {
            callback(nil)
        }
    }

    /**
     Queries the system for a shortcut of a speific intent type.
     - Parameter type: The type of the `INIntent` to find a recorded shortcut for.
     - Parameter key: The key to use when storing the UUID of any found shortcut.
     - Parameter callback: A function called with the result of the query.
     - Parameter shortcut: The found shortcut if any.
     */
    private func findSpecificShortcut<A>(
        of type: A.Type,
        with key: String,
        callback: @escaping (_ shortcut: INVoiceShortcut?) -> Void
        ) where A: INIntent {
        func isRequestedIntent<A>(_ type: A.Type) -> (INVoiceShortcut) -> Bool {
            return { voiceShortcut in voiceShortcut.shortcut.intent is A }
        }

        INVoiceShortcutCenter.shared.getAllVoiceShortcuts { shortcuts, _ in
            if let shortcut = shortcuts?.first(where: isRequestedIntent(type)) {
                UserDefaults.standard.set(shortcut.identifier.uuidString, forKey: key)
                callback(shortcut)
            } else {
                callback(nil)
            }
        }
    }

}

// MARK: - Shortcut Defintition
/**
 A little wrapepr type that just pulls out the recorded prhase for a `INVoiceShortcut`.
 */
public struct ShortcutDefinition {
    public let recordedPhrase: String

    @available(iOS 12.0, *)
    init(shortcut: INVoiceShortcut) {
        self.recordedPhrase = shortcut.invocationPhrase
    }
}

// MARK: - ShortcutManagerDelegate
/// Defines the protocol for an object that listens for events in the presented system view controllers for adding or
/// editing a recorded phrase.
public protocol ShortcutManagerDelegate: AnyObject {
    func voiceShortcutViewControllerDidCancel()
    func voiceShortcutViewControllerDidFinish(with voiceShortcut: ShortcutDefinition)
    func voiceShortcutViewControllerDidDeleteShortcut()
    func voiceShortcutViewControllerFailed(with error: Error?)
}

// MARK: - DelegateProxy
/**
 An internal class used to consolidate the add and edit delegate protocols into one.
 */
@available(iOS 12.0, *)
private class DelegateProxy: NSObject, INUIAddVoiceShortcutViewControllerDelegate,
INUIEditVoiceShortcutViewControllerDelegate {

    weak var delegate: ShortcutManagerDelegate?
    let doneCallback: () -> Void

    init(delegate: ShortcutManagerDelegate, doneCallback: @escaping () -> Void) {
        self.delegate = delegate
        self.doneCallback = doneCallback
    }

    // MARK: Add
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        delegate?.voiceShortcutViewControllerDidCancel()
        doneCallback()
    }

    func addVoiceShortcutViewController(
        _ controller: INUIAddVoiceShortcutViewController,
        didFinishWith voiceShortcut: INVoiceShortcut?,
        error: Error?
        ) {
        if let shortcut = voiceShortcut.map(ShortcutDefinition.init) {
            delegate?.voiceShortcutViewControllerDidFinish(with: shortcut)
        } else {
            delegate?.voiceShortcutViewControllerFailed(with: error)
        }
        doneCallback()
    }

    // MARK: Edit
    func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
        delegate?.voiceShortcutViewControllerDidCancel()
        doneCallback()
    }

    func editVoiceShortcutViewController(
        _ controller: INUIEditVoiceShortcutViewController,
        didUpdate voiceShortcut: INVoiceShortcut?,
        error: Error?
        ) {
        if let shortcut = voiceShortcut.map(ShortcutDefinition.init) {
            delegate?.voiceShortcutViewControllerDidFinish(with: shortcut)
        } else {
            delegate?.voiceShortcutViewControllerFailed(with: error)
        }
        doneCallback()
    }

    func editVoiceShortcutViewController(
        _ controller: INUIEditVoiceShortcutViewController,
        didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID
        ) {
        delegate?.voiceShortcutViewControllerDidDeleteShortcut()
        doneCallback()
    }
}
