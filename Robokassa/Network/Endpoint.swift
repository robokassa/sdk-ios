import Foundation

enum Endpoint {
    case getInvoice(PaymentParams, Bool)
    case confirmHoldPayment(PaymentParams)
    case cancelHoldPayment(PaymentParams)
    case reccurentPayment(PaymentParams)
    case checkPaymentStatus(PaymentParams)
    
    var url: String {
        return switch self {
        case .getInvoice: Constants.main
        case .confirmHoldPayment: Constants.holdingConfirm
        case .cancelHoldPayment: Constants.holdingCancel
        case .reccurentPayment: Constants.recurringPayment
        case .checkPaymentStatus: Constants.checkPayment
        }
    }
    
    var method: HTTPMethod {
        .post
    }
    
    var stringBody: String? {
        switch self {
        case let .getInvoice(params, isTest):
            return params.payPostParams(isTest: isTest)
        case let .confirmHoldPayment(params):
            return params.confirmHoldingParams
        case let .cancelHoldPayment(params):
            return params.cancelHoldingParams
        case let .reccurentPayment(params):
            return params.recurrentPostParams
        case let .checkPaymentStatus(params):
            return params.checkPaymentParams
        }
    }
}
