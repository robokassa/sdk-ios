import Foundation

final class Logger {
    func log(request: URLRequest) {
        var value = "---------- REQUEST START ----------\n"
        
        if let url = request.url?.absoluteString {
            value += "---> Requesting to URL: \(url)\n"
        }
        
        if let method = request.httpMethod {
            value += "---> METHOD: \(method)\n"
        }
        
        if let body = request.httpBody {
            let stringBody = String(data: body, encoding: .utf8)!
            
            do {
                if let json = try JSONSerialization.jsonObject(with: body) as? [String: Any] {
                    let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
                    let string = String(data: data, encoding: .utf8)!
                    value += "---> Body Data: \(string)\n"
                } else {
                    value += "---> Body Data: \(stringBody)\n"
                }
            } catch {
                value += "---> Body Data: \(stringBody)\n"
            }
        }
        
        value += "---------- REQUEST FINISH ----------\n"
        print(value)
    }
    
    func log(response: HTTPURLResponse, data: Data) {
        var value = "---------- RESPONSE START ----------\n"
        
        if let url = response.url?.absoluteString {
            value += "---> Requesting to URL: \(url)\n"
        }
        
        value += "---> Status Code: \(response.statusCode)\n"
        
        let stringBody = String(data: data, encoding: .utf8)!
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let bodyData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
                let string = String(data: bodyData, encoding: .utf8)!
                value += "---> Body Data: \(string)\n"
            } else {
                value += "---> Body Data: \(stringBody)\n"
            }
        } catch {
            value += "---> Body Data: \(stringBody)\n"
        }
        
        value += "---------- RESPONSE FINISH ----------\n"
    }
}
