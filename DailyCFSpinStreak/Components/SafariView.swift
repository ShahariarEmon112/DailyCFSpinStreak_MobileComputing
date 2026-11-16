//
//  SafariView.swift
//  DailyCFSpinStreak
//
//  Shows a web page INSIDE the app (SFSafariViewController), so the user can
//  read the problem statement without leaving the app — the solve timer keeps
//  running because the app does not go to the background.
//
//  SFSafariViewController is a UIKit view controller. UIViewControllerRepresentable
//  is the bridge that lets SwiftUI display a UIKit view controller.
//

import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    // Called once to create the UIKit controller.
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    // Called when SwiftUI state changes; nothing to update here.
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
