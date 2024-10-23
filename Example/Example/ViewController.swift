import UIKit
import RobokassaSDK

final class ViewController: UIViewController {
    
    // MARK: - Lifecycle -
    
    private let vStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.spacing = 8.0
        
        return stack
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "ic-logo")
        
        return imageView
    }()
    
    private let textField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.backgroundColor = .clear
        textField.borderStyle = .roundedRect
        textField.placeholder = "Введите..."
        textField.keyboardType = .numberPad
        
        return textField
    }()
    
    private let simplePaymentButton: Button = {
        let button = Button()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(RobokassaSDK.PaymentType.simplePayment.title, for: .normal)
        
        return button
    }()
    
    private let holdingButton: Button = {
        let button = Button()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(RobokassaSDK.PaymentType.holding.title, for: .normal)
        
        return button
    }()
    
    private let confirmHoldingButton: Button = {
        let button = Button()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(RobokassaSDK.PaymentType.confirmHolding.title, for: .normal)
        
        return button
    }()
    
    private let cancelHoldingButton: Button = {
        let button = Button()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(RobokassaSDK.PaymentType.cancelHolding.title, for: .normal)
        
        return button
    }()
    
    private let reccurentPaymentButton: Button = {
        let button = Button()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(RobokassaSDK.PaymentType.reccurentPayment.title, for: .normal)
        
        return button
    }()
    
    private let robokassa = Robokassa(
        login: "",          // идентификатор (логин) магазина
        password: "",       // пароль для подписи запросов к сервису
        password2: "",      // пароль для подписи запросов к сервису
        isTesting: false    // true для указание тестовых запросов. Также если true, то и пароли должны быть тестовыми.
    )
    
    private let storage = Storage()
    
    private let buttonHeight: CGFloat = 48.0
    
    private var selectedPaymentType: RobokassaSDK.PaymentType?
    
    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.titleView = imageView
        view.backgroundColor = .secondarySystemBackground
        setupActions()
        setupSubviews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        simplePaymentButton.isLoading = false
        holdingButton.isLoading = false
        reccurentPaymentButton.isLoading = false
    }

}

// MARK: - Actions -

fileprivate extension ViewController {
    func setupActions() {
        textField.addAction(.init(handler: { action in
            if let text = (action.sender as? UITextField)?.text {
                print(text)
            }
        }), for: .editingChanged)
        
        simplePaymentButton.addAction(.init(handler: { [weak self] _ in
            self?.simplePaymentButton.isLoading = true
            self?.selectedPaymentType = .simplePayment
            self?.routeToWebView(with: .simplePayment)
        }), for: .touchUpInside)
        
        holdingButton.addAction(.init(handler: { [weak self] _ in
            self?.holdingButton.isLoading = true
            self?.selectedPaymentType = .holding
            self?.routeToWebView(with: .holding)
        }), for: .touchUpInside)
        
        confirmHoldingButton.addAction(.init(handler: { [weak self] _ in
            self?.confirmHoldingButton.isLoading = true
            self?.selectedPaymentType = .confirmHolding
            self?.didTapConfirmHolding()
        }), for: .touchUpInside)
        
        cancelHoldingButton.addAction(.init(handler: { [weak self] _ in
            self?.cancelHoldingButton.isLoading = true
            self?.selectedPaymentType = .cancelHolding
            self?.didTapCancelHolding()
        }), for: .touchUpInside)
        
        reccurentPaymentButton.addAction(.init(handler: { [weak self] _ in
            self?.selectedPaymentType = .reccurentPayment
            self?.didTapRecurrent()
        }), for: .touchUpInside)
        
        robokassa.onDimissHandler = {
            print("ROBOKASSA SDK DISMISSED")
        }
        robokassa.onSuccessHandler = { [weak self] in
            if let type = self?.selectedPaymentType {
                if type == .reccurentPayment {
                    if let id = Int(self?.textField.text ?? ""), self?.storage.previoudOrderId == nil {
                        self?.storage.previoudOrderId = id
                    }
                }
            }
            
            self?.presentResult(title: "Success", message: "Successfully finished payment")
        }
        robokassa.onFailureHandler = { [weak self] reason in
            self?.presentResult(title: "Failure", message: reason)
        }
    }
    
    func routeToWebView(with type: RobokassaSDK.PaymentType) {
        switch type {
        case .simplePayment:
            robokassa.startSimplePayment(with: createParams())
        case .holding:
            robokassa.startHoldingPayment(with: createParams())
        case .reccurentPayment:
            robokassa.startDefaultReccurentPayment(with: createParams())
        default:
            break
        }
    }
}

// MARK: - Privates -

fileprivate extension ViewController {
    func didTapConfirmHolding() {
        robokassa.confirmHoldingPayment(with: createParams()) { [weak self] result in
            self?.confirmHoldingButton.isLoading = false
            
            switch result {
            case let .success(response):
                print("SUCCESSFULLY CONFIRMED HOLDING PAYMENT. Response: \(response)")
            case let .failure(error):
                print(error.localizedDescription)
            }
        }
    }
    
    func didTapCancelHolding() {
        robokassa.cancelHoldingPayment(with: createParams()) { [weak self] result in
            self?.cancelHoldingButton.isLoading = false
            
            switch result {
            case let .success(response):
                print("SUCCESSFULLY CANCELLED HOLDING PAYMENT. Response: \(response)")
            case let .failure(error):
                print(error.localizedDescription)
            }
        }
    }
    
    func didTapRecurrent() {
        if let previousOrderId = storage.previoudOrderId {
            var params = createParams()
            params.order.previousInvoiceId = previousOrderId
            robokassa.startReccurentPayment(with: params) { result in
                switch result {
                case let .success(response):
                    print("SUCCESSFULLY FINISHED RECURRENT PAYMENT. Response: \(response)")
                case let .failure(error):
                    print(error.localizedDescription)
                }
            }
        } else {
            routeToWebView(with: .reccurentPayment)
        }
    }
    
    func createParams() -> RobokassaSDK.PaymentParams {
        RobokassaSDK.PaymentParams(
            order: RobokassaSDK.OrderParams(
                invoiceId: Int(textField.text ?? "") ?? 0,              // Номер инвойса
                orderSum: 1.0,                                          // Сумма платежа
                description: "Тестовый  платеж",                        // Описание платежа
                expirationDate: Date().dateByAdding(.day, value: 1),
                receipt: .init(
                    items: [
                        .init(
                            name: "",       // Наименование товара
                            sum: 1.0,       // Сумма товара
                            quantity: 1,    // Кол-во
                            paymentMethod: .fullPayment,
                            tax: .NONE
                        )
                    ]
                )
            ),
            customer: .init(
                culture: .ru, email: "john@doe.com"), // Введите свой e-mail
            view: .init(toolbarText: "Простая оплата", hasToolbar: true)
        )
    }
    
    func presentResult(title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Закрыть", style: .cancel)
        alert.addAction(cancel)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) {
            alert.dismiss(animated: true)
        }
        
        navigationController?.present(alert, animated: true)
    }
}

// MARK: - Setup subviews -

fileprivate extension ViewController {
    func setupSubviews() {
        embedSubviews()
        setSubviewsConstraints()
    }
    
    func embedSubviews() {
        view.addSubview(vStack)
        
        vStack.addArrangedSubview(textField)
        vStack.addArrangedSubview(simplePaymentButton)
        vStack.addArrangedSubview(holdingButton)
        vStack.addArrangedSubview(confirmHoldingButton)
        vStack.addArrangedSubview(cancelHoldingButton)
        vStack.addArrangedSubview(reccurentPaymentButton)
        vStack.setCustomSpacing(32.0, after: textField)
    }
    
    func setSubviewsConstraints() {
        NSLayoutConstraint.activate([
            vStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32.0),
            vStack.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 32.0),
            vStack.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -32.0),
            vStack.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32.0)
        ])
        
        NSLayoutConstraint.activate([
            textField.heightAnchor.constraint(equalToConstant: buttonHeight),
            simplePaymentButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            holdingButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            reccurentPaymentButton.heightAnchor.constraint(equalToConstant: buttonHeight)
        ])
    }
}
