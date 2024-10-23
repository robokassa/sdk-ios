#if canImport(UIKit)
import UIKit
#endif


public struct ViewParams: Codable {
    /// Цвет фона тулбара на странице оплаты.
    /// Указывается в формате Color Hex, например, #000000 для черного цвета.
    public var toolbarBgColor: String?
    
    /// Цвет текста тулбара на странице оплаты.
    /// Указывается в формате Color Hex, например, #cccccc для серого цвета.
    public var toolbarTextColor: String?
    
    /// Значение заголовка в тулбаре на странице оплаты. Максимальная длина — 30 символов.
    public var toolbarText: String?
    
    /// Этот параметр показывает, отображать или нет тулбар на странице оплаты.
    public var hasToolbar: Bool = true
    
    public init(toolbarBgColor: String? = nil, toolbarTextColor: String? = nil, toolbarText: String? = nil, hasToolbar: Bool) {
        self.toolbarBgColor = toolbarBgColor
        self.toolbarTextColor = toolbarTextColor
        self.toolbarText = toolbarText
        self.hasToolbar = hasToolbar
    }
}
