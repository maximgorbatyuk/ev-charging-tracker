//
//  DocumentPreviewView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 01.03.2026.
//

import SwiftUI
import PDFKit

struct DocumentPreviewView: SwiftUI.View {

    let document: CarDocument

    @Environment(\.dismiss) var dismiss

    var body: some SwiftUI.View {
        NavigationStack {
            Group {
                if let path = document.filePath {
                    let url = URL(fileURLWithPath: path)
                    if document.fileType.lowercased() == "pdf" {
                        PDFPreview(url: url)
                    } else {
                        ImagePreview(url: url)
                    }
                } else {
                    Text(L("File not found"))
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(document.displayTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Close")) { dismiss() }
                }

                if let path = document.filePath {
                    ToolbarItem(placement: .topBarTrailing) {
                        ShareLink(item: URL(fileURLWithPath: path))
                    }
                }
            }
        }
    }
}

struct PDFPreview: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.document = PDFDocument(url: url)
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {}
}

struct ImagePreview: SwiftUI.View {

    let url: URL

    @State private var scale: CGFloat = 1.0

    var body: some SwiftUI.View {
        if let image = UIImage(contentsOfFile: url.path) {
            ScrollView([.horizontal, .vertical]) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .gesture(
                        MagnifyGesture()
                            .onChanged { value in
                                scale = min(value.magnification, 5.0)
                            }
                            .onEnded { _ in
                                withAnimation {
                                    scale = max(1.0, min(scale, 5.0))
                                }
                            }
                    )
            }
        } else {
            Text(L("Unable to load image"))
                .foregroundColor(.secondary)
        }
    }
}
