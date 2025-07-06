import UIKit

public final class ServiceCheckPaymentStatus {
    public static let shared = ServiceCheckPaymentStatus()

    private init() {}

    private(set) var params: PaymentParams?

    public var onSuccessHandler: ((String?) -> Void)?
    public var onFailureHandler: ((String) -> Void)?
    public var onDismissHandler: (() -> Void)?

    public func checkPaymentStatus() {
        print(#function)
        if let params = loadBodyStringForCheckStatusUrl(){
            Task { @MainActor in
                do {
                    let result = try await RequestManager.shared.requestForCheckStatus(to: params)

                    if let resultState = RequestManager.shared.getStateCode(from: result, "Result") {

                        if resultState == "0" {

                            if let stateCode = RequestManager.shared.getStateCode(from: result, "State") {
                                let codeType = PaymentState(rawValue: stateCode) ?? .notFound

                                if codeType == .paymentSuccess {
                                    onSuccessHandler?(codeType.title)
                                } else {
                                    onFailureHandler?("Result: \(stateCode). Message: \(codeType.title)")
                                }
                            }
                        } else {
                            let codeType = PaymentResult(rawValue: resultState) ?? .notFound
                            onFailureHandler?("Оплата по этому invoiceID еще не выполнена Result: \(codeType). Message: \(codeType.title)")
                        }
                    } else {
                        handleFailureState(result)
                    }
                } catch {
                    onFailureHandler?(error.localizedDescription)
                    print("In \(#filePath), method \(#function) -->\nCatched an error: \(error.localizedDescription)")
                }
            }
        } else {
            onFailureHandler?("Параметры платежа не найдены")
        }
    }

    // MARK: - запрос сгенерированного окончания ссылки
    func loadBodyStringForCheckStatusUrl (key: String = "app.body.string.for.check.status.url") -> String? {
        let value = UserDefaults.standard.string(forKey: key)
            if value == nil {
                print("Данные по ключу \(key) не найдены в UserDefaults")
            }
        return value
    }

    // MARK: - запрос статуса
    func requestPaymentStatus() {
        print(#function)
        let url = URL(string: Constants.checkPayment)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        if let params {
            let bodyString = params.checkPaymentParams
            request.httpBody = bodyString.data(using: .utf8)
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

    func loadPaymentParams(key: String = "PaymentParams") -> PaymentParams? {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            print("⚠️ Данные не найдены в UserDefaults для ключа: \(key)")
            return nil
        }
        do {
            let decoder = JSONDecoder()
            let params = try decoder.decode(PaymentParams.self, from: data)
            print("🔍 Данные загружены из UserDefaults: \(params)")
            return params
        } catch {
            print("❌ Ошибка загрузки: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - сохранение параметров для создания запроса статуса
    func saveBodyStringForCheckStatusUrl(_ params: PaymentParams,
                                         key: String = "app.body.string.for.check.status.url") {
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.set(params.checkPaymentParams, forKey: key)
    }

    func updateHasShownSuccessPayment(key: String = "app.has.shown.success.payment") {
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.set(false, forKey: key)
    }

    func updateCurrentInvoiceId(_ paymentId: Int?, key: String = "app.current.invoice.id") {
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.set(paymentId, forKey: key)
    }
}

