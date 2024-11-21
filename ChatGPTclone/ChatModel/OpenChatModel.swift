//
//  OpenChatModel.swift
//  ChatGPTclone
//
//  Created by Алексей Зарицький on 16/03/2024.
//
import Foundation
import Alamofire
import Combine

class OpenAIService {
    let baseUrl = "https://api.openai.com/v1/chat/completions"
    
    func sendMessage(message: String) -> AnyPublisher<OpenAICompletionsResponse, Error> {
        // Update to use a supported model, e.g., "text-davinci-004"
        let body = OpenAICompletionsBody(model: "text-babbage-002", prompt: message, temperature: 0.7, max_tokens: 500)

        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(Constants.openAIAPIKey)"
        ]
        
        return Future { [weak self] promise in
            guard let urlString = self?.baseUrl, let url = URL(string: urlString) else { return }
            AF.request(url, method: .post, parameters: body, encoder: .json, headers: headers)
                .responseJSON { response in
                    if let errorResponse = response.value as? [String: Any], let error = errorResponse["error"] as? [String: Any] {
                        print("API Error:", error)
                        let decoder = JSONDecoder()
                        if let errorData = try? JSONSerialization.data(withJSONObject: error, options: []),
                           let decodedError = try? decoder.decode(OpenAIErrorMessage.self, from: errorData) {
                            promise(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: decodedError.message])))
                        }
                        return
                    }
                }

                .responseDecodable(of: OpenAICompletionsResponse.self) { response in
                    switch response.result {
                    case .success(let result):
                        promise(.success(result))
                    case .failure(let error):
                        promise(.failure(error))
                    }
                }
        }
        .eraseToAnyPublisher()
    }
}


struct OpenAICompletionsBody: Encodable {
    let model: String
    let prompt: String
    let temperature: Float?
    let max_tokens: Int
}

struct OpenAICompletionsResponse: Decodable {
    let id: String? // Make 'id' optional if it can be absent
    let choices: [OpenAICompetionsChoice]
}


struct OpenAIError: Decodable {
    let error: OpenAIErrorMessage
}

struct OpenAIErrorMessage: Decodable {
    let code: String
    let message: String
    let param: String?
    let type: String
}


struct OpenAICompetionsChoice: Decodable {
    let text: String
}
