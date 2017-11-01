//Copyright © 2017 Koninklijke Philips Nederland N.V. All rights reserved.

import Foundation

class TelepathChannelSpy: TelepathChannel {
    var receiveMessage: String?
    var receiveError: Error?
    var sentMessage: String?
    var sendError: Error?

    convenience init() {
        let url = URL(string: "http://example.com/telepath/connect#I=1234&E=abcd")!
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
