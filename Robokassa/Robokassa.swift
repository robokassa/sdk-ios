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
        let modifiedParams = params.set(isHolding: true)
        fetchInvoice(with: modifiedParams)
        pushWebView()
    }
    
    public func confirmHoldingPayment(with params: PaymentParams, completion: @escaping (Result<Bool, Error>) -> Void) {
        let modifiedParams = params
            .set(login: login, pass1: password, pass2: password2)
            .set(isHolding: true)
        requestConfirmHoldingPayment(with: modifiedParams, completion: completion)
    }
    
    public func confirmHoldingPayment(with params: PaymentParams) async throws -> Bool {
        let modifiedParams = params
            .set(login: login, pass1: password, pass2: password2)
            .set(isHolding: true)
        
        return try await requestConfirmHoldingPayment(with: modifiedParams)
    }
    
    public func cancelHoldingPayment(with params: PaymentParams, completion: @escaping (Result<Bool, Error>) -> Void) {
        let modifiedParams = params
            .set(login: login, pass1: password, pass2: password2)
            .set(isHolding: true)
        requestHoldingPaymentCancellation(with: modifiedParams, completion: completion)
    }
    
    public func cancelHoldingPayment(with params: PaymentParams) async throws -> Bool {
        let modifiedParams = params
            .set(login: login, pass1: password, pass2: password2)
            .set(isHolding: true)
        
        return try await requestHoldingPaymentCancellation(with: modifiedParams)
    }
    
    public func startDefaultReccurentPayment(with params: PaymentParams) {
        let modifiedParams = params.set(isRecurrent: true)
        fetchInvoice(with: modifiedParams)
        pushWebView()
    }
    
    public func startReccurentPayment(with params: PaymentParams, completion: @escaping (Result<Bool, Error>) -> Void) {
        let modifiedParams = params
            .set(login: login, pass1: password, pass2: password2)
            .set(isRecurrent: true)
        requestRecurrentPayment(with: modifiedParams, completion: completion)
    }
    
    public func startReccurentPayment(with params: PaymentParams) async throws -> Bool {
        let modifiedParams = params
            .set(login: login, pass1: password, pass2: password2)
            .set(isRecurrent: true)
        
        return try await requestRecurrentPayment(with: modifiedParams)
    }
    
    public func startPaymentBySavedCard(with params: PaymentParams) {

        ServiceCheckPaymentStatus.shared.saveBodyStringForCheckStatusUrl(params)
        ServiceCheckPaymentStatus.shared.updateHasShownSuccessPayment()
        ServiceCheckPaymentStatus.shared.updateCurrentInvoiceId(params.order.invoiceId)

        let modifiedParams = params.set(login: login, pass1: password, pass2: password2)
        webView.urlPath = Constants.savedPayment
        webView.stringBody = modifiedParams.payPostParams(isTest: isTesting)
        webView.params = modifiedParams
        pushWebView()
        
        DispatchQueue.main.async {
            self.webView.loadWebView()
        }
    }
}

// MARK: - Privates -

fileprivate extension Robokassa {
    func fetchInvoice(with params: PaymentParams) {
        let modifiedParams = params.set(login: login, pass1: password, pass2: password2)
        
        Task { @MainActor [modifiedParams] in
            do {
                let result = try await RequestManager.shared.request(to: .getInvoice(modifiedParams, isTesting), type: Invoice.self)
                webView.urlPath = Constants.simplePayment + result.invoiceID
                webView.params = modifiedParams
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
