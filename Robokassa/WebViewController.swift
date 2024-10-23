import UIKit
import WebKit

final class WebViewController: UIViewController {
    
    // MARK: - Properties -
        
    private var webView: WKWebView!
    private var timer: Timer?
    
    private var seconds = 60
    
    private(set) var invoiceId: String
    private(set) var params: PaymentParams
    private(set) var isTesting: Bool
    
    var onSucccessHandler: (() -> Void)?
    var onFailureHandler: ((String) -> Void)?
    var onDismissHandler: (() -> Void)?
    
    // MARK: - Init -
    
    init(invoiceId: String, params: PaymentParams, isTesting: Bool = false) {
        self.invoiceId = invoiceId
        self.params = params
        self.isTesting = isTesting
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
        
        configureBackButton()
        embedSubviews()
        setSubviewsConstraints()
        loadWebView()
    }

}

// MARK: - WebView Delegate -

extension WebViewController: WKNavigationDelegate {
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
    func loadWebView() {
        if let url = URL(string: Constants.simplePayment + invoiceId) {
            var request = URLRequest(url: url)
            request.httpMethod = HTTPMethod.post.rawValue
            request.setValue(Constants.FORM_URL_ENCODED, forHTTPHeaderField: "Content-Type")
            webView.load(request)
        }
    }
    
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
        print(#function)
        Task { @MainActor in
            do {
                let result = try await RequestManager.shared.request(to: .checkPaymentStatus(params))
                
                if let value = result["Result"] as? String {
                    let codeType = PaymentResult(rawValue: value) ?? .notFound
                    
                    if codeType == .success {
                        invalidateTimer()
                        onSucccessHandler?()
                    } else {
                        onFailureHandler?(codeType.title)
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
        view.addSubview(webView)
    }
    
    func setSubviewsConstraints() {
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leftAnchor.constraint(equalTo: view.leftAnchor),
            webView.rightAnchor.constraint(equalTo: view.rightAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
