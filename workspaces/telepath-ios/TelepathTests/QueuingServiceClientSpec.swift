import Quick
import Nimble
import Mockingjay
@testable import Telepath

class QueuingServiceClientSpec: QuickSpec {
    override func spec() {
        let baseUrl = URL(string: "https://queueing.exampe.com")!
        let queueId = "a_queue_id"
        let message = "a message".data(using: .utf8)!
        let encodedMessage = message.base64urlEncodedString().data(using: .utf8)!

        var queuing: QueuingServiceClient!

        beforeEach {
            queuing = QueuingServiceClient(url: baseUrl)
        }

        it("implements QueuingService protocol") {
            expect(queuing as QueuingService).toNot(beNil())
        }

        it("can send a message") {
            self.stub(http(.post, uri: "\(baseUrl)/\(queueId)")) { request in
                expect(Data(reading: request.httpBodyStream!)) == encodedMessage
                return http(200)(request)
            }
            waitUntil { done in
                queuing.send(queueId: queueId, message: message) { error in
                    expect(error).to(beNil())
                    done()
                }
            }
        }

        it("calls back on the main thread after sending") {
            self.stub(http(.post, uri: "\(baseUrl)/\(queueId)"), http(200))
            waitUntil { done in
                queuing.send(queueId: queueId, message: message) { _ in
                    expect(Thread.isMainThread).to(beTrue())
                    done()
                }
            }
        }

        describe("send errors") {
            it("returns error when connection fails") {
                let someError = NSError(domain: "", code: 0, userInfo: nil)
                self.stub(http(.post, uri: "\(baseUrl)/\(queueId)"), failure(someError))
                waitUntil { done in
                    queuing.send(queueId: queueId, message: message) { error in
                        expect(error).toNot(beNil())
                        done()
                    }
                }
            }

            it("returns error when http post was unsuccessfull") {
                self.stub(http(.post, uri: "\(baseUrl)/\(queueId)"), http(500))
                waitUntil { done in
                    queuing.send(queueId: queueId, message: message) { error in
                        expect(error).toNot(beNil())
                        done()
                    }
                }
            }
        }

        it("can receive a message") {
            self.stub(
                http(.get, uri: "\(baseUrl)/\(queueId)"),
                http(200, headers: nil, download: .content(encodedMessage))
            )
            waitUntil { done in
                queuing.receive(queueId: queueId) { receivedMessage, error in
                    expect(error).to(beNil())
                    expect(receivedMessage) == message
                    done()
                }
            }
        }

        it("returns nil when there is no message waiting") {
            self.stub(http(.get, uri: "\(baseUrl)/\(queueId)"), http(204))
            waitUntil { done in
                queuing.receive(queueId: queueId) { receivedMessage, error in
                    expect(error).to(beNil())
                    expect(receivedMessage).to(beNil())
                    done()
                }
            }
        }

        it("calls back on the main thread after receiving") {
            self.stub(http(.get, uri: "\(baseUrl)/\(queueId)"), http(204))
            waitUntil { done in
                queuing.receive(queueId: queueId) { _, _ in
                    expect(Thread.isMainThread).to(beTrue())
                    done()
                }
            }
        }

        describe("receive errors") {
            func expectErrorWhileReceiving(done: @escaping () -> Void) {
                queuing.receive(queueId: queueId) { _, error in
                    expect(error).toNot(beNil())
                    done()
                }
            }

            it("returns error when connection fails") {
                let someError = NSError(domain: "", code: 0, userInfo: nil)
                self.stub(http(.get, uri: "\(baseUrl)/\(queueId)"), failure(someError))
                waitUntil { done in
                    expectErrorWhileReceiving(done: done)
                }
            }

            it("returns error when http get was unsuccessfull") {
                self.stub(http(.get, uri: "\(baseUrl)/\(queueId)"), http(500))
                waitUntil { done in
                    expectErrorWhileReceiving(done: done)
                }
            }

            it("returns error when message is not in base64url format") {
                let invalidData = "not base64!".data(using: .utf8)!
                self.stub(
                    http(.get, uri: "\(baseUrl)/\(queueId)"),
                    http(200, headers: nil, download: .content(invalidData))
                )
                waitUntil { done in
                    expectErrorWhileReceiving(done: done)
                }
            }

            it("returns error when message is not a string in utf8 format") {
                let invalidData = "not utf8 😅!".data(using: .utf16)!
                self.stub(
                    http(.get, uri: "\(baseUrl)/\(queueId)"),
                    http(200, headers: nil, download: .content(invalidData))
                )
                waitUntil { done in
                    expectErrorWhileReceiving(done: done)
                }
            }
        }
    }
}

extension Data {
    init(reading input: InputStream) {
        self.init()
        input.open()
        var buffer = [UInt8](repeating: 0, count: 4096)
        while input.hasBytesAvailable {
            let amount = input.read(&buffer, maxLength: buffer.count)
            self.append(buffer, count: amount)
        }
        input.close()
    }
}
