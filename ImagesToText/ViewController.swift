
import UIKit
import PhotosUI
import Vision

class ViewController: UIViewController {

    // MARK: - variables.

    private let fileHelper: FileHelper = .init()
    private let defaults = UserDefaults.standard
    private var images: [UIImage] = []
    private var textRecognitionRequest: VNRecognizeTextRequest?
    private let recognitionGroup: DispatchGroup = .init()
    private var recognizedTexts: [String] = []

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

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.addSubview(uploadImagesButton)
        view.addSubview(getTextButton)
        view.addSubview(loader)
        makeConstraints()
        createTextRecognitionRequest()
    }

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

    @objc private func getTextButtonActtion() {
        startLoader()
        startTextRecognition()
    }

    @objc private func openImagePicker() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 0
        config.filter = .any(of: [.images, .livePhotos])
        let pickerViewController = PHPickerViewController(configuration: config)
        pickerViewController.delegate = self
        present(pickerViewController, animated: true)
    }

    private func startTextRecognition() {
        if defaults[.isNewImagesUploaded] == false {
            saveTextsToFile()
        } else {
            images.forEach(performRecognitionRequestIfCan(on:))
        }
    }

    private func saveTextsToFile() {
        if defaults[.isNewImagesUploaded] == true {
            for imageStrings in recognizedTexts {
                fileHelper.saveTextToFile(textToAdd: imageStrings)
            }
            reset()
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
        recognizedTexts = []
        images = []
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

extension ViewController {
    private func createTextRecognitionRequest() {
        textRecognitionRequest = VNRecognizeTextRequest { [weak self] (request, error) in
            // Get the recognized text
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                self?.recognitionGroup.leave()
                return
            }
            let text = observations.compactMap({ $0.topCandidates(1).first?.string }).joined(separator: " ")
            self?.recognizedTexts.append(text)
            self?.recognitionGroup.leave()
        }

        textRecognitionRequest?.recognitionLevel = .accurate
    }

    private func performRecognitionRequestIfCan(on imageForRecognition: UIImage) {
        guard let image = imageForRecognition.cgImage, let textRecognitionRequest = textRecognitionRequest else { return }
        recognitionGroup.enter()
        // TODO: - синхронизировать порядок сохранения в файл
        Task {
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            try? handler.perform([textRecognitionRequest])
        }

        recognitionGroup.notify(queue: .main) { [weak self] in self?.saveTextsToFile() }
    }
}
