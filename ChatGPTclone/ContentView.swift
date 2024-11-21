//
//  ContentView.swift
//  ChatGPTclone
//
//  Created by Алексей Зарицький on 16/03/2024.
// export OPENAI_API_KEY='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'

import SwiftUI
import Combine

struct ContentView: View {
    @State private var chatMessages: [ChatMessage] = []
    @State private var messageText: String = ""
    
    private let openAIService = OpenAIService()
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        VStack {
            ScrollView(showsIndicators: false) {
                LazyVStack {
                    ForEach(chatMessages, id: \.id) { message in
                        messageView(message: message)
                    }
                }
            }
            HStack {
                TextField("Enter a message", text: $messageText)
                    .padding(15)
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 1)
                    )
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.white)
                        .padding(10)
                }
                .background(Color.black)
                .cornerRadius(15)
                .padding(.leading, -55)
            }
            .padding()
        }
    }
    
    func messageView(message: ChatMessage) -> some View {
        HStack {
            if message.sender == .me { Spacer() }
            Text(message.content)
                .foregroundColor(message.sender == .me ? .white : .black)
                .padding()
                .background(message.sender == .me ? .black : .gray.opacity(0.5))
                .cornerRadius(15)
            if message.sender == .gpt { Spacer() }
        }
        .padding(.horizontal)
    }
    
    func sendMessage() {
        let myMessage = ChatMessage(id: UUID().uuidString, content: messageText, dateCreated: Date(), sender: .me)
        DispatchQueue.main.async {
            self.chatMessages.append(myMessage)
        }
        
        openAIService.sendMessage(message: messageText).sink(receiveCompletion: { completion in
            DispatchQueue.main.async {
                if case let .failure(error) = completion {
                    print("Failed with error: \(error)")
                    // Update the UI to show a more user-friendly error message
                    let userFriendlyError = (error as NSError).domain == "" && (error as NSError).code == 0
                        ? "We've hit our usage limit for now, please try again later."
                        : error.localizedDescription
                    self.chatMessages.append(ChatMessage(id: UUID().uuidString, content: userFriendlyError, dateCreated: Date(), sender: .system))
                }
            }
        }, receiveValue: { response in
            DispatchQueue.main.async {
                guard let textResponse = response.choices.first?.text.trimmingCharacters(in: .whitespacesAndNewlines.union(.init(charactersIn: "\""))) else {
                    return
                }
                let gptMessage = ChatMessage(id: UUID().uuidString, content: textResponse, dateCreated: Date(), sender: .gpt)
                self.chatMessages.append(gptMessage)
            }
        }).store(in: &cancellables)
        
        messageText = ""
    }


}

struct ChatMessage: Identifiable {
    let id: String
    let content: String
    let dateCreated: Date
    let sender: MessageSender
}

enum MessageSender {
    case me
    case gpt
    case system // Ensure this case is added
}


#Preview {
    ContentView()
}


extension ChatMessage {
    static let sampleMessages = [
        ChatMessage(id: UUID().uuidString, content: "SampleMEssage From me", dateCreated: Date(), sender: .me),
        ChatMessage(id: UUID().uuidString, content: "SampleMEssage From gpt", dateCreated: Date(), sender: .gpt),
        ChatMessage(id: UUID().uuidString, content: "SampleMEssage From me", dateCreated: Date(), sender: .me),
            ChatMessage(id: UUID().uuidString, content: "SampleMEssage From gpt", dateCreated: Date(), sender: .gpt)
    ]
}
