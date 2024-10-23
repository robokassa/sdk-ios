import UIKit

final class Button: UIButton {
    private let activityIndicator: UIActivityIndicatorView = {
        let activity = UIActivityIndicatorView(style: .medium)
        activity.translatesAutoresizingMaskIntoConstraints = false
        activity.hidesWhenStopped = true
        activity.stopAnimating()
        
        return activity
    }()
    
    override var isEnabled: Bool {
        didSet {
            backgroundColor = isEnabled ? .systemBlue : .lightGray
        }
    }
    
    var isLoading = false {
        didSet {
            isEnabled = !isLoading
            isLoading ? activityIndicator.startAnimating() : activityIndicator.stopAnimating()
        }
    }
    
    var cornerRadius: CGFloat = 16.0
    
    init() {
        super.init(frame: .zero)
        
        setupSubviews()
        clipsToBounds = true
        backgroundColor = .systemBlue
        setTitleColor(.white, for: .normal)
        setTitleColor(.white, for: .disabled)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = cornerRadius
    }
}

fileprivate extension Button {
    func setupSubviews() {
        addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }
}
