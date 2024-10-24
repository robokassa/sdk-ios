import Foundation
import Compression

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

enum RequestError: Error {
    case invalidURL
    case networkError(Error)
    case jsonSerializationError(Error)
    case noData
    case invalidResponse
}

final class XMLParserDelegateImplementation: NSObject, XMLParserDelegate {
    var currentElement = ""
    var currentValue = ""
    
    private(set) var dictionary: [String: Any] = [:]
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        currentValue = ""
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentValue += string
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        dictionary[elementName] = currentValue
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        // Создание объекта из распарсенного словаря
        if let jsonData = try? JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted) {
            print("XML PARSER:\n" + String(data: jsonData, encoding: .utf8)!)
        }
    }
}

final class RequestManager {
    static let shared = RequestManager()

    private init() {}
    
    func request<T: Decodable>(to endpoint: Endpoint, type: T.Type) async throws -> T {
        do {
            let data = try await requestTo(endpoint: endpoint)
            
            if let object = try? Mapper().mapToObject(from: data, type: T.self) {
                return object
            } else {
                if let object = try? JSONSerialization.jsonObject(with: data) as? T {
                    return object
                } else {
                    throw MessagedError(message: "Could not parse any valid JSON either XML")
                }
            }
        } catch {
            throw error
        }
    }
    
    func requestToGetString(to endpoint: Endpoint) async throws -> String {
        do {
            let data = try await requestTo(endpoint: endpoint)
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            throw error
        }
    }
    
    func request(to endpoint: Endpoint) async throws -> [String: Any] {
        do {
            let data = try await requestTo(endpoint: endpoint)
            return xmlToObject(data: data)
        } catch {
            throw error
        }
    }
    
    private func xmlToObject(data: Data) -> [String: Any] {
        // Парсер для XML
        let parser = XMLParser(data: data)
        let delegate = XMLParserDelegateImplementation()
        parser.delegate = delegate
        
        if parser.parse() {
            return delegate.dictionary
        } else {
            print("Ошибка при парсинге XML.")
            return [:]
        }
    }

    private func requestTo(endpoint: Endpoint) async throws -> Data {
        guard let url = URL(string: endpoint.url) else {
            throw RequestError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
        if let stringBody = endpoint.stringBody {
            request.setValue(Constants.FORM_URL_ENCODED, forHTTPHeaderField: "Content-Type")
            request.httpBody = stringBody.data(using: .utf8)
        }
        
        Logger().log(request: request)

        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            print("-------- FAILED IN RESPONSE. STATUS CODE is \((response as? HTTPURLResponse)?.statusCode ?? 0)")
            throw RequestError.invalidResponse
        }
        
        Logger().log(response: httpResponse, data: data)

        return data
    }
}

final class Mapper {
    private let decoder: JSONDecoder

    init() {
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
    }
    
    func mapToObject<T>(from data: Data, type: T.Type) throws -> T where T : Decodable {
        do {
            return try decoder.decode(type, from: data)
        } catch DecodingError.dataCorrupted(let context) {
            print(context.debugDescription)
            throw MessagedError(message: "Mapping error! Reason: \(context.debugDescription)")
        } catch let DecodingError.keyNotFound(key, context) {
            let message = "\(key.stringValue) was not found, \(context.debugDescription)"
            print(message)
            throw MessagedError(message: "Mapping error! Reason: \(message)")
        } catch let DecodingError.typeMismatch(type, context) {
            let message = "\(type) was expected, \(context.debugDescription) | \(context.codingPath)"
            print(message)
            throw MessagedError(message: "Mapping error! Reason: \(message)")
        } catch let DecodingError.valueNotFound(type, context) {
            let message = "no value was found for \(type), \(context.debugDescription)"
            print(message)
            throw MessagedError(message: "Mapping error! Reason: \(message)")
        } catch {
            print("Unknown error")
            throw MessagedError(message: "Mapping error! Reason: UNKNOWN ERROR")
        }
    }
}

public struct MessagedError: LocalizedError {
    let message: String
    public var errorDescription: String? { message }
}
