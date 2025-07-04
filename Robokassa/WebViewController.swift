import UIKit
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
    
    var onSuccessHandler: ((String?) -> Void)?
    var onFailureHandler: ((String) -> Void)?
    var onDismissHandler: (() -> Void)?
    
    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        //
        let contentController = WKUserContentController()
        //

        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true

        let config = WKWebViewConfiguration()
        let handler = ScriptMessageHandler()
        config.defaultWebpagePreferences = preferences
        //
        config.userContentController = contentController
        config.userContentController.add(handler, name: "openSafari")
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        config.websiteDataStore = .default()

        webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.uiDelegate = self

        if let bundle = Bundle(identifier: "org.cocoapods.RobokassaSDK") {
            if let path = bundle.path(forResource: "ic_robokassa_loader", ofType: "png") {
                let image = UIImage(contentsOfFile: path)
                imageView.image = image
            } else {
                print("Resource not found")
            }
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

//    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
//        if let url = navigationAction.request.url {
//            /*
//             Проверка должна быть такой:
//             - если URL начинается с https://auth.robokassa.ru/Merchant/State/
//             - для тестовых платежей с тестовыми вводными, проверяем содержит ли URL 'robokassa.ru/payment/success'
//             тогда мы считаем что платеж завершен.
//             */
//            if url.absoluteString.starts(with: "https://auth.robokassa.ru/Merchant/State/") ||
//                url.absoluteString.contains("robokassa.ru/payment/success") {
//                checkPaymentState()
//
//                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
//                    if let timer = self.timer, timer.isValid == true {
//                        self.startTimer()
//                    }
//                }
//            }
//        }
//        decisionHandler(.allow)
//    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void) {

        if let url = navigationAction.request.url {
            print("Запрос на: \(url.absoluteString), метод: \(navigationAction.request.httpMethod ?? "GET")")

            if url.absoluteString.starts(with: "https://www.tinkoff.ru/tpay/") ||
                url.absoluteString.starts(with: "sberpay://") ||
                url.absoluteString.starts(with: "https://auth.robokassa.ru/Merchant/State?") ||
                url.absoluteString.starts(with: "https://pay.yandex.ru/web/payment?order_token=") ||
                url.absoluteString.contains("ipol.tech/") ||
                url.absoluteString.contains("ipol.ru/") {
                handleRedirect(url: url)
                decisionHandler(.allow)
                return
            } else if url.absoluteString.starts(with: "intent://scan/#Intent;scheme=robokassa://open;") {
                didTapBack()
                if let onFailureHandler = onFailureHandler {
                    onFailureHandler("Платеж прошел ранее")
                }
            }

            if url.scheme == "http" || url.scheme == "https" {
                decisionHandler(.allow)
            }
            else {
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    decisionHandler(.cancel)
                } else {
                    if let handler = onFailureHandler {
                        handler("No app to open URL: \(url.absoluteString)")
                    }
                    decisionHandler(.cancel)
                }
            }
        } else if navigationAction.navigationType == .other  {
            if let url = navigationAction.request.url {
                // Открывается ссылка в Safari
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                decisionHandler(.cancel) // Отменяется загрузка в WebView
            } else {
                decisionHandler(.allow)
            }
        }
        else {
            print("URL is nil in decidePolicyFor")
            decisionHandler(.allow)
        }
    }

    func showNotInstalledAlert(for scheme: String) {
        let alert = UIAlertController(
            title: "Приложение не найдено",
            message: "Для открытия этой ссылки требуется приложение, поддерживающее схему: \(scheme).",
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "paymentResult", let data = message.body as? [String: Any] {
            print("Получено через JavaScript: \(data)")
            if let status = data["status"] as? String {
                if status == "success" {
                    print("Платёж успешен")
                    if let handler = onSuccessHandler {
                        handler(nil)
                    }
                } else if status == "fail" {
                    print("Платёж не удался")
                    if let handler = onFailureHandler {
                        handler("Payment fail")
                    }
                }
            }
            // Проверка редиректа из данных
            if let redirectTo = data["redirectTo"] as? [String: Any],
               let urlString = redirectTo["url"] as? String,
               let url = URL(string: urlString) {
                handleRedirect(url: url)
            }
        }
    }

    func webViewDidFinishLoad(_ webView: WKWebView) {
        let script = WKUserScript(source: """
                window.addEventListener('load', function() {
                    setInterval(function() {
                        var status = document.querySelector('meta[name="payment-status"]')?.content;
                        var redirectTo = window.redirectTo || document.querySelector('meta[name="redirect-to"]')?.content;
                        if (status || redirectTo) {
                            window.webkit.messageHandlers.paymentResult.postMessage({
                                status: status,
                                redirectTo: redirectTo ? JSON.parse(redirectTo) : null
                            });
                        }
                    }, 1000);
                });
            """, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        webView.configuration.userContentController.addUserScript(script)
    }

    private func handleDeepLink(_ url: URL) {
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
           let status = components.queryItems?.first(where: { $0.name == "status" })?.value {
            print("Deep link: \(url.absoluteString), статус: \(status)")
            if status == "success" {
                if let handler = onSuccessHandler {
                    handler(nil)
                }
            } else if status == "fail" {
                if let handler = onFailureHandler {
                    handler("Payment failed")
                }
            }
        }
    }

    private func handleRedirect(url: URL) {
        print("Попытка редиректа на: \(url.absoluteString)")
        if url.scheme == "sberpay" {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: { success in
                    if success {
                        print("Успешно открыто приложение SberPay")
                    } else {
                        print("Не удалось открыть SberPay")
                        if let handler = self.onFailureHandler {
                            handler("SberPay app not found")
                        }
                    }
                })
            } else {
                print("SberPay не установлено")
                if let handler = onFailureHandler {
                    handler("SberPay app not found")
                }
            }
        } else if url.scheme == "https" {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: { success in
                    if success {
                        print("Успешно открыто \(url.absoluteString)")
                    } else {
                        print("Не удалось открыть \(url.absoluteString)")
                    }
                })
            }
            self.didTapBack()
        }
    }
}

extension WebViewController: WKUIDelegate {
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {

        if let url = navigationAction.request.url,
           url.scheme != "http" && url.scheme != "https" {
            print("🔗 [WKUIDelegate] Перехват popup для: \(url.absoluteString)")
        }

        let popupWebView = WKWebView(frame: webView.bounds, configuration: configuration)
        popupWebView.navigationDelegate = self
        popupWebView.uiDelegate = self
        webView.addSubview(popupWebView)

        if navigationAction.targetFrame == nil {
            popupWebView.load(navigationAction.request)
        }
        return popupWebView

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
        ServiceCheckPaymentStatus.shared.checkPaymentStatus()
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
