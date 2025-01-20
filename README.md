# Robokassa SDK iOS

## Минимальные требования:
iOS 14.0

## Желательно также:
- использовать Xcode не ниже 15-версии
- использовать обновленную версию iOS SDK


## Способы установки:

**Pod**:

pod 'RobokassaSDK', :git => 'https://github.com/robokassa/sdk-ios.git', :tag => '1.0.0'

**SPM**:

https://github.com/robokassa/sdk-ios.git


### SDK позволяет интегрировать прием платежей через сервис Robokassa в мобильное приложение iOS. Библиотека написана на языке Swift.

### Требования к проекту:
Для работы Robokassa SDK необходимо: iOS версии 14.0 и выше.

### Подключение SDK:

**Общая информация**

Для работы с SDK вам понадобятся:

- MerchantLogin - идентификатор (логин) магазина
- Password #1 – пароль для подписи запросов к сервису
- Password #2 – пароль для подписи запросов к сервису
  
Внимание! Формирование подписи в SDK реализовано через алгоритм хеширования MD5.

Данные можно найти в личном кабинете (ЛК) Robokassa.
В корне репозитория собран проект состоящий из библиотеки (Robokassa.xcodeproj - для работы с Cocoapods) и демо приложение (Example), которое показывает пример интеграции SDK:

![screens of example project](https://github.com/robokassa/sdk-ios/blob/main/screens.png)

**Подключение зависимостей**

Для подключения библиотеки в ваш проект, вы можете:

- Установить СДК с помощью Cocoapods. Для этого создайте 'podfile' (для этого введите в терминале команду: pod init), если нет. Если же есть, то впишите туда:

pod 'RobokassaSDK', :git => 'https://github.com/robokassa/sdk-ios.git', :tag => '1.0.0'

- Установить СДК с помощью SPM (Swift Package Manager). Для этого подключите в самом проекте следующим URL (Project -> Package dependencies):

https://github.com/robokassa/sdk-ios.git

*Выберите пункт 'branch' - 'main' в 'Dependency rule'*
 
- Либо скачать и подключить SDK. Добавьте его в ваш проект и подключите зависимость в настройках проекта.

И затем, импортируйте СДК в вашем файле:
**import RobokassaSDK**

## Проведение платежей

Библиотека использует стандартную платежную форму Robokassa в виде WebView, что упрощает интеграцию и не требует реализации собственных платежных форм и серверных решений. Процесс платежа состоит из 2-х этапов: вызова платежного окна Robokassa с заданными параметрами и затем, если требуется, осуществления дополнительного запроса к сервису Robokassa для необходимого действия - отмены или подтверждения отложенного платежя или проведения повторной оплаты.

### Вызов платежного окна

Чтобы настроить платежное окно для проведения платежа, требуется:
Создать объект PaymentParams, который включает в себя:
- данные о заказе OrderParams
- данные о покупателе CustomerParams
- данные о внешнем виде страницы оплаты ViewParams

```swift
let paymentParams = RobokassaSDK.PaymentParams(
    order: RobokassaSDK.OrderParams(                            // данные заказа
        invoiceId: 12345,                                       // номер заказа в системе продавца
        orderSum: 1.0,                                          // сумма заказа
        description: "Test simple pay",                         // описание, показываемое покупателю в платежном окне
        expirationDate: Date().dateByAdding(.day, value: 1),    // дата, до окончания которой, можно будет оплатить
        receipt: .init(                                         // объект фискального чека
            items: [
                .init(
                    name: "Ботинки детские",
                    sum: 1.0,
                    quantity: 1,
                    paymentMethod: .fullPayment,
                    tax: .NONE
                )
            ]
        )
    ),
    customer: .init(                                            // данные покупателя
        culture: .ru,                                           // язык интерфейса
        email: "john@doe.com"                                   // электронная почта покупателя для отправки уведомлений об оплате
    ),
    view: .init(
        toolbarText: "Простая оплата",                          // заголовок окна оплаты
        hasToolbar: true                                        // заголовок окна показывать/не показывать
    )
)
```

### Инициализация самого SDK

Чтобы инициализировать Robokassa SDK, нужно выполнить следующее:

- Логин: идентификатор магазина
- Пароль №1
- Пароль №2
- Опционально можно указать true/false в качестве тестового запроса

Также мы имеем из данного объекта, 3 захвата значений:
- onDismissHandler, который сработает в моменте закрытия WebView
- onSuccessHandler, который сообщает, что платеж выполнен успешно
- onFailureHandler, который сообщает, что платеж НЕ выполнился и вернулась ошибка. Этот захват значений имеет в себе String с причиной ошибки

```swift
let robokassa = Robokassa(
    login: MERCHANT_LOGIN,      // логин
    password: PASSWORD_1,       // пароль№1, если isTesting: true, то необходимо передать тестовый_пароль№1
    password2: PASSWORD_2,      // пароль№2, если isTesting: true, то необходимо передать тестовый_пароль№2
    isTesting: false            // определяет тестовый ли будет платеж
)

robokassa.onDimissHandler = {
    print("Robokassa SDK finished its job")
}
robokassa.onSuccessHandler = { OpKey in
    // OpKey - идентификатор (токен) для проведения последующих платежей с помощью сохраненной карты
    // MARK: захватываемое значение OpKey является опциональным и возможно сюда может прийти nil, что в свою очередь перезапишет старое значение в локальном хранилище, а OpKey вы можете хранить только у себя. Для этого советуем прописать условие, чтобы не перезаписать успешно сохраненную рабочую копию OpKey.  
    print("Success: " + "Successfully finished payment")
}
robokassa.onFailureHandler = { reason in
    print("Failure: " + reason)
}
```
    
### После создания параметров и инициализации СДК, можно будет вызвать один из нескольких методов СДК:

- *Данный метод открывает WebView. Отвечает за простую оплату*
```swift
robokassa.startSimplePayment(with: paymentParams)
```

- *Данный метод открывает WebView. Отвечает за холдирование средств*
```swift
robokassa.startHoldingPayment(with: paymentParams)
```

- *Данный метод не открывает WebView и подтверждает холдированную оплату*

```swift
robokassa.confirmHoldingPayment(with: paymentParams) { [weak self] result in
    switch result {
    case let .success(isSuccess):
        print("SUCCESSFULLY CONFIRMED HOLDING PAYMENT. Is success: \(isSuccess)")
    case let .failure(error):
        print(error.localizedDescription)
    }
}
```

- *Данный метод не открывает WebView и отменяет холдированную оплату*
```swift
robokassa.cancelHoldingPayment(with: paymentParams) { [weak self] result in
    switch result {
    case let .success(isSucess):
        print("SUCCESSFULLY CANCELLED HOLDING PAYMENT. Is success: \(isSucess)")
    case let .failure(error):
        print(error.localizedDescription)
    }
}
```

- *Рекуррентная оплата. Подразумевает с собой небольшую логику, где если есть masterID (сохраненный ID на клиентской стороне, означает - ID, с помощью которого можно проводить рекуррентную оплату без ввода данных для платежа)*
```swift
if let previousOrderId = storage.previoudOrderId { // previoudOrderId: Int
    paymentParams.order.previousInvoiceId = previousOrderId
    
    robokassa.startReccurentPayment(with: paymentParams) { result in
        switch result {
        case let .success(isSuccess):
            print("SUCCESSFULLY FINISHED RECURRENT PAYMENT. Is success: \(isSuccess)")
        case let .failure(error):
            print(error.localizedDescription)
        }
    }
} else {
    robokassa.startDefaultReccurentPayment(with: paymentParams)
}
```

- *Оплата по сохраненной карте. Подразумевает с собой возможность проведения последующих платежей с помощью сохраненной карты. Нужно лишь ввести CVV и СМС-код для подтверждения оплаты. OpKey - идентификатор оплаты по карте, полученный после оплаты, например, после проведения простой оплаты, в onSuccessHandler можно захватить OpKey и сохранить в локальном хранилище для дальнейшего использования*
```swift
guard let opKey, !opKey.isEmpty else { return }

paymentParams.order.token = opKey
robokassa.startPaymentBySavedCard(with: params)
```
