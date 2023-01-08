
import UIKit

extension UIImage {

    func getCroppedForCardGameCGImage() -> CGImage? {
        let cropRect = CGRect(
            x: 0,
            y: 250,
            width: size.width,
            height: size.height - 650
        ).integral

        return cgImage?.cropping(to: cropRect)
    }
}
