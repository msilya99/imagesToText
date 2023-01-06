
import UIKit
import PhotosUI

class ViewController: UIViewController {

    // MARK: - variables.

    private let fileHelper: FileHelper = .init()
    private let defaults = UserDefaults.standard
    private var images: [UIImage] = []
    private var group = DispatchGroup()

    private lazy var startScanningButton: Button = {
        let button = Button(title: "Upload images")
        button.addTarget(self, action: #selector(startScanningAction), for: .touchUpInside)
        return button
    }()

    private lazy var getTextButton: UIButton = {
        let button = Button(title: "Get text file")
        button.isHidden = !defaults[.isContentExist, default: false]
        button.addTarget(self, action: #selector(getTextButtonActtion), for: .touchUpInside)
        return button
    }()

    private lazy var loader: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .large)
        view.color = UIColor.red
        view.translatesAutoresizingMaskIntoConstraints = false
        view.transform = CGAffineTransform(scaleX: 3, y: 3)
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.addSubview(startScanningButton)
        view.addSubview(getTextButton)
        view.addSubview(loader)
        makeConstraints()
    }

    private func makeConstraints() {
        NSLayoutConstraint.activate([
            loader.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            loader.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            startScanningButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            startScanningButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 24),
            startScanningButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -24),
            startScanningButton.heightAnchor.constraint(equalToConstant: 60),

            getTextButton.topAnchor.constraint(equalTo: startScanningButton.bottomAnchor, constant: 32),
            getTextButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 24),
            getTextButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -24),
            getTextButton.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor),
            getTextButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    @objc private func startScanningAction() {
        images = []
        openImagePicker()
    }

    @objc private func getTextButtonActtion() {
        startLoader()
        let lotOfStrings = ["One", "Two", "Three", "Four", "Five"]
        saveTextsToFile(lotOfStrings)
    }

    private func openImagePicker() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 0
        config.filter = .any(of: [.images, .livePhotos])
        let pickerViewController = PHPickerViewController(configuration: config)
        pickerViewController.delegate = self
        present(pickerViewController, animated: true)
    }

    private func saveTextsToFile(_ texts: [String]) {
        Task {
            if defaults[.isNewImagesUploaded] == true {
                for imageStrings in texts { await fileHelper.saveTextToFile(textToAdd: imageStrings) }
            }

            fileHelper.export()
            defaults[.isContentExist] = true
            defaults[.isNewImagesUploaded] = false
            stopLoader()
        }
    }

    // MARK: - loader actions

    private func startLoader() {
        loader.startAnimating()
        getTextButton.isEnabled = false
        startScanningButton.isEnabled = false
    }

    private func stopLoader() {
        loader.stopAnimating()
        getTextButton.isEnabled = true
        startScanningButton.isEnabled = true
    }
}

extension ViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        Task {
            startLoader()
            for result in results {
                guard let image = try? await getImageFromResult(result) else { continue }
                images.append(image)
            }

            if !images.isEmpty {
                fileHelper.removeFile()
                getTextButton.isHidden = false
            }
            
            stopLoader()
        }

        dismiss(animated: true, completion: nil)
    }

    private func getImageFromResult(_ result: PHPickerResult) async throws -> UIImage {
        return try await withCheckedThrowingContinuation({ continuation in
            result.itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                guard let image = image as? UIImage else {
                    continuation.resume(throwing: error ?? NSError(domain: "Something wrong with continuation",
                                                                   code: 100500))
                    return
                }

                continuation.resume(returning: image)
            }
        })
    }
}
