import Foundation

public struct Receipt: Codable {
    /// Система налогообложения. Необязательное поле, если у организации имеется только один тип налогообложения.
    /// (Данный параметр обязательно задается в личном кабинете магазина).
    public let sno: TaxSystem?
    
    /// Массив данных о позициях чека.
    public let items: [ReceiptItem]
    
    public init(sno: TaxSystem? = nil, items: [ReceiptItem]) {
        self.sno = sno
        self.items = items
    }
}

// Assuming PaymentMethod, PaymentObject, and Tax are already defined in your Swift code
public struct ReceiptItem: Codable {
    /**
     * Обязательное поле. Наименование товара. Строка, максимальная длина 128 символа.
     * Если в наименовании товара Вы используете специальные символы, например кавычки,
     * то их обязательно необходимо экранировать.
     */
    public let name: String
    
    /**
     * Обязательное поле. Полная сумма в рублях за итоговое количество данного товара с учетом всех возможных скидок,
     * бонусов и специальных цен. Десятичное положительное число: целая часть не более 8 знаков,
     * дробная часть не более 2 знаков.
     */
    public let sum: Double
    
    /** Обязательное поле. Количество товаров. */
    public let quantity: Int
    
    /**
     * Необязательное поле. Полная сумма в рублях за единицу товара с учетом всех возможных скидок,
     * бонусов и специальных цен. Десятичное положительное число: целая часть не более 8 знаков,
     * дробная часть не более 2 знаков. Параметр можно передавать вместо параметра sum.При передаче
     * параметра общая сумма товарных позиций рассчитывается по формуле (cost*quantity)=sum.
     */
    public let cost: Double?
    
    /**
     * Маркировка товара, передаётся в том виде, как она напечатана на упаковке товара.
     * Параметр является обязательным только для тех магазинов, которые продают товары подлежащие обязательной маркировке.
     * Код маркировки расположен на упаковке товара, рядом со штрих-кодом или в виде QR-кода.
     */
    public let nomenclatureCode: String?
    
    /**
     * Признак способа расчёта. Этот параметр необязательный. Если этот параметр не передан клиентом,
     * то в чеке будет указано значение параметра по умолчанию из Личного кабинета.
     */
    public let paymentMethod: PaymentMethod?
    
    /**
     * Признак предмета расчёта. Этот параметр необязательный. Если этот параметр не передан клиентом,
     * то в чеке будет указано значение параметра по умолчанию из Личного кабинета.
     */
    public let paymentObject: PaymentObject?
    
    /**
     * Обязательное поле. Это поле устанавливает налоговую ставку в ККТ.
     * Определяется для каждого вида товара по отдельности, но за все единицы конкретного товара вместе.
     */
    public let tax: Tax?
    
    public init(
        name: String,
        sum: Double,
        quantity: Int,
        cost: Double? = nil,
        nomenclatureCode: String? = nil,
        paymentMethod: PaymentMethod? = nil,
        paymentObject: PaymentObject? = nil,
        tax: Tax? = nil
    ) {
        self.name = name
        self.sum = sum
        self.quantity = quantity
        self.cost = cost
        self.nomenclatureCode = nomenclatureCode
        self.paymentMethod = paymentMethod
        self.paymentObject = paymentObject
        self.tax = tax
    }
}

public enum TaxSystem: String, Codable {
    /** Общая СН. */
    case OSN = "osn"
    
    /** Упрощенная СН (доходы). */
    case USN_INCOME = "usn_income"
    
    /** Упрощенная СН (доходы минус расходы). */
    case USN_INCOME_OUTCOME = "usn_income_outcome"
    
    /** Единый сельскохозяйственный налог. */
    case ESN = "esn"
    
    /** Патентная СН. */
    case PATENT = "patent"
}

public enum Tax: String, Codable {
    /** Без НДС. */
    case NONE = "none"
    
    /** НДС по ставке 0%. */
    case VAT_0 = "vat0"
    
    /** НДС чека по ставке 10%. */
    case VAT_10 = "vat10"
    
    /** НДС чека по расчетной ставке 10/110. */
    case VAT_110 = "vat110"
    
    /** НДС чека по ставке 20%. */
    case VAT_20 = "vat20"
    
    /** НДС чека по расчетной ставке 20/120. */
    case VAT_120 = "vat120"
}
