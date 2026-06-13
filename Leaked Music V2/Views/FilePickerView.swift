import SwiftUI
import UniformTypeIdentifiers

struct FilePickerView: UIViewControllerRepresentable {
    @Binding var fileURLs: [URL]
    var allowsMultipleSelection: Bool = false
    var onPicked: ([URL]) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: FilePickerView

        init(_ parent: FilePickerView) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.fileURLs = urls
            parent.onPicked(urls)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            controller.dismiss(animated: true)
        }
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // Define standard UTTypes
        let standardTypes: [UTType] = [
            UTType.mp3,
            UTType.mpeg4Audio,
            UTType.wav,
            UTType.aiff
        ]
        
        // Define custom UTTypes using file extensions and filter out nil values
        let customTypes: [UTType] = [
            UTType(filenameExtension: "aifc"),
            UTType(filenameExtension: "flac"),
            UTType(filenameExtension: "ogg")
        ].compactMap { $0 }
        
        // Combine standard and custom UTTypes
        let supportedTypes: [UTType] = standardTypes + customTypes
        
        // Optional: Print supported UTTypes for debugging
        print("Supported UTTypes: \(supportedTypes.map { $0.identifier })")
        
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        picker.allowsMultipleSelection = allowsMultipleSelection
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) { }
}
