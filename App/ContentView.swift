import SwiftUI

struct ContentView: View {
    @ObservedObject private var viewModel = CameraLaunchViewModel()
    
    var body: some View {
        VStack(alignment: .center) {
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.5))
                    .padding()
                Text("P h o t o")
                    .font(.system(size: 30))
                    .bold()
                    .foregroundColor(Color.white)
                if viewModel.imageData.count > 0, let uiImage = UIImage(data: viewModel.imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding()
                }
            }
            Button {
                viewModel.isLaunchedCamera.toggle()
            } label: {
                Text("カメラ起動")
            }
        }
        .fullScreenCover(isPresented: $viewModel.isLaunchedCamera) {
            Imagepicker(show: $viewModel.isLaunchedCamera,
                        image: $viewModel.imageData)
        }
    }
}

class CameraLaunchViewModel: ObservableObject {
    @Published var isLaunchedCamera = false
    @Published var imageData = Data(capacity: 0)
}

struct Imagepicker : UIViewControllerRepresentable {
    @Binding var show: Bool
    @Binding var image: Data
    
    func makeCoordinator() -> Imagepicker.Coodinator {
        return Imagepicker.Coordinator(parent: self)
    }
      
    func makeUIViewController(context: UIViewControllerRepresentableContext<Imagepicker>) -> UIImagePickerController {
        let controller = UIImagePickerController()
        controller.sourceType = .camera
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController,
                                context: UIViewControllerRepresentableContext<Imagepicker>) {
    }
    
    class Coodinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent : Imagepicker
        
        init(parent : Imagepicker){
            self.parent = parent
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            self.parent.show.toggle()
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            
            guard let image = info[.originalImage] as? UIImage else {
                return
            }
            guard let data = getCorrectOrientationUIImage(uiImage: image).jpegData(compressionQuality: 1.0) else {
                return
            }
            self.parent.image = data
            self.parent.show.toggle()
        }
        
        private func getCorrectOrientationUIImage(uiImage:UIImage) -> UIImage {
            var editedImage = UIImage()
            let ciContext = CIContext(options: nil)
            
            switch uiImage.imageOrientation {
            case .left:
                guard let orientedCIImage = CIImage(image: uiImage)?.oriented(.left),
                      let cgImage = ciContext.createCGImage(orientedCIImage, from: orientedCIImage.extent) else {
                    return uiImage
                }
                editedImage = UIImage(cgImage: cgImage)
            case .down:
                guard let orientedCIImage = CIImage(image: uiImage)?.oriented(.down),
                      let cgImage = ciContext.createCGImage(orientedCIImage, from: orientedCIImage.extent) else {
                    return uiImage
                }
                editedImage = UIImage(cgImage: cgImage)
            case .right:
                guard let orientedCIImage = CIImage(image: uiImage)?.oriented(.right),
                      let cgImage = ciContext.createCGImage(orientedCIImage, from: orientedCIImage.extent) else {
                    return uiImage
                }
                editedImage = UIImage(cgImage: cgImage)
            default:
                editedImage = uiImage
            }
            
            return editedImage
        }
    }
}


#Preview {
    ContentView()
}
