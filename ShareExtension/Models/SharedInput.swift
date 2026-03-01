//
//  SharedInput.swift
//  ShareExtension
//
//  Created by Maxim Gorbatyuk on 01.03.2026.
//

import Foundation

enum SharedInputKind {
    case link
    case text
}

struct SharedInput {
    let kind: SharedInputKind
    var url: URL?
    var text: String?
    var suggestedTitle: String?
}
