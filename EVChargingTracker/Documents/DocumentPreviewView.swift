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

    private let minZoomScale: CGFloat = 1.0
    private let maxZoomScale: CGFloat = 5.0

    @State private var currentZoomScale: CGFloat = 1.0
    @State private var baseZoomScale: CGFloat = 1.0

    var body: some SwiftUI.View {
        GeometryReader { geometry in
            if let image = UIImage(contentsOfFile: url.path) {
                ScrollView([.horizontal, .vertical]) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: geometry.size.width * currentZoomScale,
                            height: geometry.size.height * currentZoomScale
                        )
                        .frame(
                            minWidth: geometry.size.width,
                            minHeight: geometry.size.height
                        )
                }
                .scrollIndicators(.hidden)
                .contentShape(Rectangle())
                .gesture(
                    MagnifyGesture()
                        .onChanged { value in
                            let nextScale = baseZoomScale * value.magnification
                            currentZoomScale = max(minZoomScale, min(nextScale, maxZoomScale))
                        }
                        .onEnded { _ in
                            baseZoomScale = currentZoomScale
                        }
                )
                .simultaneousGesture(
                    TapGesture(count: 2)
                        .onEnded {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if currentZoomScale > minZoomScale {
                                    currentZoomScale = minZoomScale
                                } else {
                                    currentZoomScale = 2.0
                                }

                                baseZoomScale = currentZoomScale
                            }
                        }
                )
            } else {
                Text(L("Unable to load image"))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
