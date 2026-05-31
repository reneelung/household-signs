import SwiftUI
import MessageUI
import UIKit

struct MailComposeView: UIViewControllerRepresentable {
    let url: URL
    let groupName: String

    func makeUIViewController(context: Context) -> UIViewController {
        if MFMailComposeViewController.canSendMail() {
            let vc = MFMailComposeViewController()
            vc.mailComposeDelegate = context.coordinator
            vc.setSubject("Join \(groupName) on QuickFlip")
            vc.setMessageBody(
                """
                I'd like you to join my \(groupName) group on QuickFlip.

                Tap to join: \(url.absoluteString)

                QuickFlip is a shared-status app for things like the dishwasher, laundry, and door.
                """,
                isHTML: false
            )
            return vc
        } else {
            let subject = "Join \(groupName) on QuickFlip".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let body = "Tap to join: \(url.absoluteString)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            if let mailto = URL(string: "mailto:?subject=\(subject)&body=\(body)") {
                DispatchQueue.main.async {
                    UIApplication.shared.open(mailto)
                }
            }
            return UIViewController()
        }
    }

    func updateUIViewController(_ vc: UIViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            controller.dismiss(animated: true)
        }
    }
}
