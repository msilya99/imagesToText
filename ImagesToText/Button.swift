import UIKit

final class Button: UIButton {

    init(title: String) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        setTitleColor(.black, for: .normal)
        backgroundColor = .white
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 4
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
