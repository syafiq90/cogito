//Copyright © 2017 Koninklijke Philips Nederland N.V. All rights reserved.

import Foundation

class TelepathChannelSpy: TelepathChannel {
    var receiveMessage: String?
    var receiveError: Error?
    var sentMessage: String?
    var sendError: Error?

    convenience init(id: String = "1234") {
        let url = URL(string: "http://example.com/telepath/connect#I=\(id)&E=abcd")!
        try! self.init(connectUrl: url)
    }

    override func receive(completion: @escaping (String?, Error?) -> Void) {
        completion(receiveMessage, receiveError)
    }

    override func send(message: String, completion: @escaping (Error?) -> Void) {
        sentMessage = message
        completion(sendError)
    }
}