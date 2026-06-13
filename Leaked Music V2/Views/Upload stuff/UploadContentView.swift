import SwiftUI

struct UploadContentView: View {
    @StateObject var viewModel = UploadViewModel()

    var body: some View {
        NavigationStack { //  <----  REPLACE NavigationView WITH NavigationStack
            ArtistSelectionView(viewModel: viewModel)
                .navigationTitle("Upload Music")
                .alert(item: $viewModel.errorMessage) { error in
                    Alert(title: Text("Upload Error"),
                          message: Text(error.message),
                          dismissButton: .default(Text("OK")))
                }
                .toast(message: $viewModel.toastMessage)
        }
    }
}
