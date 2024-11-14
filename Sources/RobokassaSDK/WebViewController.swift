#if canImport(UIKit)
import UIKit
#endif

import WebKit

final class WebViewController: UIViewController {
    
    // MARK: - Properties -
    
    private let container: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white.withAlphaComponent(0.6)
        
        return view
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        
        return imageView
    }()
        
    private var webView: WKWebView!
    private var timer: Timer?
    
    private var seconds = 60
    
    var isTesting: Bool = false
    
    var urlPath: String?
    var stringBody: String?
    var params: PaymentParams?
    
    var onSucccessHandler: ((String?) -> Void)?
    var onFailureHandler: ((String) -> Void)?
    var onDismissHandler: (() -> Void)?
    
    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences = preferences
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        config.websiteDataStore = .default()
        
        webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        
        if let path = Bundle.module.path(forResource: "ic_robokassa_loader", ofType: "png") {
            let image = UIImage(contentsOfFile: path)
            imageView.image = image
        }
        
        configureBackButton()
        embedSubviews()
        setSubviewsConstraints()
        loadWebView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        container.isHidden = false
        imageView.startRotationAnimation()
    }
    
    func loadWebView() {
        guard let urlPath, !urlPath.isEmpty, let url = URL(string: urlPath) else {
            return
        }
        
        var request = URLRequest(url: url)
        
        if let stringBody, !stringBody.isEmpty {
            request.httpMethod = HTTPMethod.post.rawValue
            request.setValue(Constants.FORM_URL_ENCODED, forHTTPHeaderField: "Content-Type")
            request.httpBody = stringBody.data(using: .utf8)
        } else {
            request.httpMethod = HTTPMethod.get.rawValue
        }
        
        webView.load(request)
    }

}

// MARK: - WebView Delegate -

extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        UIView.animate(withDuration: 0.5) {
            self.container.isHidden = true
        } completion: { finished in
            if finished {
                self.imageView.startRotationAnimation()
            }
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
           /*
            Проверка должна быть такой:
            - если УРЛ начинается с https://auth.robokassa.ru/Merchant/State/
            - ИЛИ содержит в себе "ipol.tech/"
            - ИЛИ содержит в себе "ipol.ru/"
            тогда мы считаем что платеж завершен.
            */
            if url.absoluteString.starts(with: "https://auth.robokassa.ru/Merchant/State/") ||
                url.absoluteString.contains("ipol.tech/") ||
                url.absoluteString.contains("ipol.ru/") {
                checkPaymentState()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                    if let timer = self.timer, timer.isValid == true {
                        self.startTimer()
                    }
                }
            }
        }
        decisionHandler(.allow)
    }
}

// MARK: - Privates -

fileprivate extension WebViewController {
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else {
                self?.invalidateTimer()
                return
            }
            
            if self.seconds > 0 {
                self.seconds -= 1
                
                if self.seconds % 2 == 0 {
                    checkPaymentState()
                }
            } else {
                invalidateTimer()
            }
        }
    }
    
    func checkPaymentState() {
        guard let params else { return }
        print(#function)
        Task { @MainActor in
            do {
                let result = try await RequestManager.shared.request(to: .checkPaymentStatus(params))
                
                if let value = result["Result"] as? String {
                    let codeType = PaymentResult(rawValue: value) ?? .notFound
                    
                    if codeType == .success {
                        invalidateTimer()
                        onSucccessHandler?(result["OpKey"] as? String)
                    } else {
                        onFailureHandler?("Result: " + value + ". Message: " + codeType.title)
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                        self.didTapBack()
                    }
                } else {
                    handleFailureState(result)
                    
                    if seconds < 1 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                            self.didTapBack()
                        }
                    }
                }
            } catch {
                invalidateTimer()
                onFailureHandler?(error.localizedDescription)
                print("In " + #filePath + ", method " + #function + " -->\nCatched an error: \(error.localizedDescription)")
            }
        }
    }
    
    func handleFailureState(_ result: [String: Any]) {
        do {
            let data = try JSONSerialization.data(withJSONObject: result, options: .prettyPrinted)
            let string = String(data: data, encoding: .utf8) ?? ""
            onFailureHandler?(string)
        } catch {
            onFailureHandler?("Could not parse any Data")
        }
    }
    
    func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Privates -

fileprivate extension WebViewController {
    func configureBackButton() {
        navigationItem.leftBarButtonItem = .init(
            image: .init(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(didTapBack)
        )
    }
    
    @objc func didTapBack() {
        if (navigationController?.viewControllers ?? []).count == 1 {
            navigationController?.dismiss(animated: true) { [weak self] in
                self?.onDismissHandler?()
            }
        } else {
            navigationController?.popViewController(animated: true)
            DispatchQueue.main.async {
                self.onDismissHandler?()
            }
        }
    }
}

// MARK: - Setup subviews -

fileprivate extension WebViewController {
    func embedSubviews() {
        view.addSubviews(webView, container)
        container.addSubview(imageView)
    }
    
    func setSubviewsConstraints() {
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leftAnchor.constraint(equalTo: view.leftAnchor),
            webView.rightAnchor.constraint(equalTo: view.rightAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: view.topAnchor),
            container.leftAnchor.constraint(equalTo: view.leftAnchor),
            container.rightAnchor.constraint(equalTo: view.rightAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 64.0),
            imageView.widthAnchor.constraint(equalToConstant: 64.0),
            imageView.topAnchor.constraint(greaterThanOrEqualTo: container.topAnchor),
            imageView.leftAnchor.constraint(greaterThanOrEqualTo: container.leftAnchor),
            imageView.rightAnchor.constraint(lessThanOrEqualTo: container.rightAnchor),
            imageView.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor)
        ])
    }
}
