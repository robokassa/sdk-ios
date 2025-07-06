
import WebKit

@MainActor
class ScriptMessageHandler: NSObject, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        // Отладка входных данных
        print("Получено сообщение: \(message.name), тело: \(String(describing: message.body))")

        guard message.name == "openSafari" else {
            print("Игнорируем сообщение с именем: \(message.name)")
            return
        }

        guard let urlString = message.body as? String,
              let url = URL(string: urlString) else {
            print("Некорректный URL или тело сообщения: \(String(describing: message.body))")
            return
        }

        do {
            try openURL(url)
            print("URL успешно открыт: \(url)")
        } catch {
            print("Ошибка при открытии URL: \(error.localizedDescription)")
        }
    }

    private func openURL(_ url: URL) throws {
        guard UIApplication.shared.canOpenURL(url) else {
            throw URLError(.badURL)
        }
        try UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
