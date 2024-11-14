import UIKit

public enum PaymentType {
    case simplePayment
    case holding
    case confirmHolding
    case cancelHolding
    case reccurentPayment
    case savedCard
    
    public var title: String {
        switch self {
        case .simplePayment: "Простая оплата"
        case .holding: "Холдирование"
        case .confirmHolding: "Подтвердить холдирование"
        case .cancelHolding: "Отменить холдирование"
        case .reccurentPayment: "Рекуррентная оплата"
        case .savedCard: "По сохраненной карте"
        }
    }
}

public final class Robokassa: NSObject {
    private let webView = WebViewController()
    
    private(set) var login: String
    private(set) var password: String
    private(set) var password2: String
    private(set) var isTesting: Bool
        
    public var onDimissHandler: (() -> Void)?
    public var onSuccessHandler: ((String?) -> Void)?
    public var onFailureHandler: ((String) -> Void)?
    
    public init(login: String, password: String, password2: String, isTesting: Bool = false) {
        self.login = login
        self.password = password
        self.password2 = password2
        self.isTesting = isTesting
        
        super.init()
        
        webView.isTesting = isTesting
        
        webView.onDismissHandler = { [weak self] in
            self?.onDimissHandler?()
        }
        webView.onSucccessHandler = { [weak self] token in
            self?.onSuccessHandler?(token)
        }
        webView.onFailureHandler = { [weak self] reason in
            self?.onFailureHandler?(reason)
        }
    }
    
    public func startSimplePayment(with params: PaymentParams) {
        fetchInvoice(with: params)
        pushWebView()
    }
    
    public func startHoldingPayment(with params: PaymentParams) {
        var params = params
        params.order.isHold = true
        fetchInvoice(with: params)
        pushWebView()
    }
    
    public func confirmHoldingPayment(with params: PaymentParams, completion: @escaping (Result<Bool, Error>) -> Void) {
        var params = params
        params.merchantLogin = login
        params.password1 = password
        params.password2 = password2
        params.order.isHold = true
        requestConfirmHoldingPayment(with: params, completion: completion)
    }
    
    public func confirmHoldingPayment(with params: PaymentParams) async throws -> Bool {
        var params = params
        params.merchantLogin = login
        params.password1 = password
        params.password2 = password2
        params.order.isHold = true
        
        return try await requestConfirmHoldingPayment(with: params)
    }
    
    public func cancelHoldingPayment(with params: PaymentParams, completion: @escaping (Result<Bool, Error>) -> Void) {
        var params = params
        params.merchantLogin = login
        params.password1 = password
        params.password2 = password2
        params.order.isHold = true
        requestHoldingPaymentCancellation(with: params, completion: completion)
    }
    
    public func cancelHoldingPayment(with params: PaymentParams) async throws -> Bool {
        var params = params
        params.merchantLogin = login
        params.password1 = password
        params.password2 = password2
        params.order.isHold = true
        
        return try await requestHoldingPaymentCancellation(with: params)
    }
    
    public func startDefaultReccurentPayment(with params: PaymentParams) {
        var params = params
        params.order.isRecurrent = true
        fetchInvoice(with: params)
        pushWebView()
    }
    
    public func startReccurentPayment(with params: PaymentParams, completion: @escaping (Result<Bool, Error>) -> Void) {
        var params = params
        params.merchantLogin = login
        params.password1 = password
        params.password2 = password2
        params.order.isRecurrent = true
        requestRecurrentPayment(with: params, completion: completion)
    }
    
    public func startReccurentPayment(with params: PaymentParams) async throws -> Bool {
        var params = params
        params.merchantLogin = login
        params.password1 = password
        params.password2 = password2
        params.order.isRecurrent = true
        
        return try await requestRecurrentPayment(with: params)
    }
    
    public func startPaymentBySavedCard(with params: PaymentParams) {
        var params = params
        params.merchantLogin = login
        params.password1 = password
        params.password2 = password2
        webView.urlPath = Constants.savedPayment
        webView.stringBody = params.payPostParams(isTest: isTesting)
        webView.params = params
        pushWebView()
    }
}

// MARK: - Privates -

fileprivate extension Robokassa {
    func fetchInvoice(with params: PaymentParams) {
        var params = params
        params.merchantLogin = login
        params.password1 = password
        params.password2 = password2
        
        Task { @MainActor in
            do {
                let result = try await RequestManager.shared.request(to: .getInvoice(params, isTesting), type: Invoice.self)
                webView.urlPath = Constants.simplePayment + result.invoiceID
                webView.params = params
                webView.loadWebView()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func requestConfirmHoldingPayment(with params: PaymentParams, completion: @escaping (Result<Bool, Error>) -> Void) {
        Task { @MainActor in
            do {
                let response = try await RequestManager.shared.request(to: .confirmHoldPayment(params), type: String.self)
                let result = response.lowercased().contains("true")
                completion(.success(result))
            } catch {
                print(error.localizedDescription)
                completion(.failure(error))
            }
        }
    }
    
    func requestConfirmHoldingPayment(with params: PaymentParams) async throws -> Bool {
        let response = try await RequestManager.shared.request(to: .confirmHoldPayment(params), type: String.self)
        return response.lowercased().contains("true")
    }
    
    func requestHoldingPaymentCancellation(with params: PaymentParams, completion: @escaping (Result<Bool, Error>) -> Void) {
        Task { @MainActor in
            do {
                let response = try await RequestManager.shared.request(to: .cancelHoldPayment(params), type: String.self)
                let isSuccess = response.lowercased().contains("true")
                
                if isSuccess {
                    completion(.success(isSuccess))
                } else {
                    completion(.failure(MessagedError(message: response)))
                }
            } catch {
                print(error.localizedDescription)
                completion(.failure(error))
            }
        }
    }
    
    func requestHoldingPaymentCancellation(with params: PaymentParams) async throws -> Bool {
        let response = try await RequestManager.shared.request(to: .cancelHoldPayment(params), type: String.self)
        let isSuccess = response.lowercased().contains("true")
        
        if isSuccess {
            return isSuccess
        } else {
            throw MessagedError(message: response)
        }
    }
    
    func requestRecurrentPayment(with params: PaymentParams, completion: @escaping (Result<Bool, Error>) -> Void) {
        Task { @MainActor in
            do {
                let response = try await RequestManager.shared.requestToGetString(to: .reccurentPayment(params))
                let isSuccess = response.lowercased().contains("ok")
                
                if isSuccess {
                    completion(.success(isSuccess))
                } else {
                    completion(.failure(MessagedError(message: response)))
                }
            } catch {
                print(error.localizedDescription)
                completion(.failure(error))
            }
        }
    }
    
    func requestRecurrentPayment(with params: PaymentParams) async throws -> Bool {
        let response = try await RequestManager.shared.requestToGetString(to: .reccurentPayment(params))
        let isSuccess = response.lowercased().contains("ok")
        
        if isSuccess {
            return isSuccess
        } else {
            throw MessagedError(message: response)
        }
    }
    
    func pushWebView() {
        if UIApplication.shared.topViewController()?.navigationController == nil {
            let navController = UINavigationController(rootViewController: webView)
            webView.modalTransitionStyle = .crossDissolve
            webView.modalPresentationStyle = .overFullScreen
            webView.isModalInPresentation = true
            UIApplication.shared.topViewController()?.present(navController, animated: true)
        } else {
            UIApplication.shared.topViewController()?.navigationController?.pushViewController(webView, animated: true)
        }
    }
}
