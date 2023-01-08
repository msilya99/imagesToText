
import UIKit
import PhotosUI
import Vision

class ViewController: UIViewController {

    // MARK: - variables.

    private let fileHelper: FileHelper = .init()
    private let defaults = UserDefaults.standard
    private let recognisedTexts: IsolatedArray<String> = .init()
    private var images: [CGImage] = []
    private var textRecognitionRequest: VNRecognizeTextRequest?

    // MARK: - gui varaibles.

    private lazy var uploadImagesButton: Button = {
        let button = Button(title: "Upload images")
        button.addTarget(self, action: #selector(openImagePicker), for: .touchUpInside)
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

    // MARK: - lifecycle.

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.addSubview(uploadImagesButton)
        view.addSubview(getTextButton)
        view.addSubview(loader)
        makeConstraints()
        createTextRecognitionRequest()
    }

    // MARK: - constraints.

    private func makeConstraints() {
        NSLayoutConstraint.activate([
            loader.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            loader.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            uploadImagesButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            uploadImagesButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 24),
            uploadImagesButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -24),
            uploadImagesButton.heightAnchor.constraint(equalToConstant: 60),

            getTextButton.topAnchor.constraint(equalTo: uploadImagesButton.bottomAnchor, constant: 32),
            getTextButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 24),
            getTextButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -24),
            getTextButton.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor),
            getTextButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    // MARK: - button actions

    @objc private func getTextButtonActtion() {
        startLoader()
        defaults[.isNewImagesUploaded] == false
        ? saveTextsToFile()
        : performRequestsInfNeeded()
    }

    @objc private func openImagePicker() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 0
        config.filter = .any(of: [.images, .livePhotos])
        let pickerViewController = PHPickerViewController(configuration: config)
        pickerViewController.delegate = self
        present(pickerViewController, animated: true)
    }

    // MARK: - saving text to file

    private func saveTextsToFile() {
        if defaults[.isNewImagesUploaded] == true {
            Task {
                for imageStrings in await recognisedTexts.values {
                    fileHelper.saveTextToFile(textToAdd: imageStrings)
                }
                reset()
            }
        }

        fileHelper.export()
        defaults[.isContentExist] = true
        defaults[.isNewImagesUploaded] = false
        stopLoader()
    }

    // MARK: - loader actions

    private func startLoader() {
        loader.startAnimating()
        getTextButton.isEnabled = false
        uploadImagesButton.isEnabled = false
    }

    private func stopLoader() {
        loader.stopAnimating()
        getTextButton.isEnabled = true
        uploadImagesButton.isEnabled = true
    }

    private func reset() {
        Task { await recognisedTexts.clear() }
        images = []
    }
}

// MARK: - Uploading images from picker.
extension ViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        Task {
            startLoader()
            for result in results {
                guard let image = try? await getImageFromResult(result),
                      let croppedImage = image.getCroppedForCardGameCGImage() else { continue }
                images.append(croppedImage)
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

// MARK: - Text recognition.
extension ViewController {
    private func createTextRecognitionRequest() {
        textRecognitionRequest = VNRecognizeTextRequest { [weak self] (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                self?.performRequestsInfNeeded()
                return
            }

            let text = observations.compactMap({ $0.topCandidates(1).first?.string }).joined(separator: "\n")
            Task {
                await self?.recognisedTexts.add(text)
                self?.performRequestsInfNeeded()
            }
        }

        textRecognitionRequest?.recognitionLevel = .accurate
    }

    private func performRecognitionRequestIfCan(on imageForRecognition: CGImage) {
        guard let textRecognitionRequest = textRecognitionRequest else { return }
        Task {
            let handler = VNImageRequestHandler(cgImage: imageForRecognition, options: [:])
            try? handler.perform([textRecognitionRequest])
        }
    }

    private func performRequestsInfNeeded() {
        Task {
            images.first != nil
            ? performRecognitionRequestIfCan(on: images.removeFirst())
            : saveTextsToFile()
        }
    }
}
