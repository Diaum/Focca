import SwiftUI
import UIKit
import ImageIO

struct AnimatedGIFView: UIViewRepresentable {
    let name: String
    let duration: TimeInterval?
    
    init(name: String, duration: TimeInterval? = nil) {
        self.name = name
        self.duration = duration
    }
    
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.clipsToBounds = true
        
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        if let path = Bundle.main.path(forResource: name, ofType: "gif"),
           let data = NSData(contentsOfFile: path),
           let source = CGImageSourceCreateWithData(data, nil) {
            
            let count = CGImageSourceGetCount(source)
            var images: [UIImage] = []
            var totalDuration: TimeInterval = 0
            
            for i in 0..<count {
                if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                    let image = UIImage(cgImage: cgImage)
                    images.append(image)
                    
                    if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any],
                       let gifProperties = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any],
                       let delayTime = gifProperties[kCGImagePropertyGIFDelayTime as String] as? Double {
                        totalDuration += delayTime
                    }
                }
            }
            
            if !images.isEmpty {
                imageView.animationImages = images
                imageView.animationDuration = duration ?? totalDuration
                imageView.image = images.first
                imageView.startAnimating()
            }
        }
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Mantém a animação rodando
        if let imageView = uiView.subviews.first as? UIImageView,
           imageView.animationImages != nil,
           !imageView.isAnimating {
            imageView.startAnimating()
        }
    }
}

