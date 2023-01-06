import UIKit

final class FileHelper {
    private let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first

    func saveTextToFile(fileName: String = AppConstants.fileName,
                        textToAdd: String) {
        guard let documentsURL = documentsURL else { return }
        let filePath = documentsURL.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: filePath.path) {
            appendTextToFile(text: textToAdd, filePath: filePath)
        } else {
            try? textToAdd.write(to: filePath, atomically: true, encoding: .utf8)
        }
    }

    private func appendTextToFile(text: String, filePath: URL) {
        guard let file = try? FileHandle(forWritingTo: filePath),
              let text = text.data(using: .utf8),
              let devider = "\n_________________________________\n \n".data(using: .utf8) else { return }

        file.seekToEndOfFile()
        file.write(devider)
        file.write(text)
        file.closeFile()
    }

    func export(paths: [String] = [AppConstants.fileName]) {
        guard let topController = RouteHelper.sh.navController?.topViewController else { return }
        let files = paths.compactMap { [weak self] path in self?.documentsURL?.appendingPathComponent(path) }
        let vc = UIActivityViewController(activityItems: files, applicationActivities: nil)
        vc.isModalInPresentation = true
        vc.popoverPresentationController?.sourceView = topController.view
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        topController.present(vc, animated: true, completion: nil)
    }

    func removeFile(name: String = AppConstants.fileName) {
        guard let documentsURL = documentsURL else { return }
        let filePath = documentsURL.appendingPathComponent(name)
        try? FileManager.default.removeItem(at: filePath)
        UserDefaults.standard[.isNewImagesUploaded] = true
    }
}
