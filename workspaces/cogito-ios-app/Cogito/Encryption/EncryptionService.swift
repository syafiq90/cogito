// Copyright © 2018 Koninklijke Philips Nederland N.V. All rights reserved.

import Foundation
import ReSwift

struct EncryptionService: TelepathService {
    let store: Store<AppState>
    var keyPairCreator: KeyPairCreatorType = KeyPairCreator()
    var publicKeyLoader: ((String) -> PublicKey?)!

    init(store: Store<AppState>) {
        self.store = store
        self.publicKeyLoader = loadPublicKeyFromKeychain
    }

    func onRequest(_ request: JsonRpcRequest, on channel: TelepathChannel) {
        if let identity = store.state.telepath.channels[channel] {
            switch request.method {
            case "createEncryptionKeyPair":
                createKeyPair(request: request, identity: identity, channel: channel)
            case "getEncryptionPublicKey":
                requestPublicKey(request: request, identity: identity, channel: channel)
            default:
                break
            }
        }
    }

    private func createKeyPair(request: JsonRpcRequest, identity: Identity, channel: TelepathChannel) {
        let tag = UUID().uuidString
        keyPairCreator.create(tag: tag)
        store.dispatch(DiamondActions.CreateEncryptionKeyPair(identity: identity, tag: tag))
        store.dispatch(TelepathActions.Send(id: request.id, result: tag, on: channel))
    }

    private func requestPublicKey(request: JsonRpcRequest, identity: Identity, channel: TelepathChannel) {
        guard let tag = request.params["tag"].string else {
            store.dispatch(TelepathActions.Send(id: request.id, error: EncryptionError.tagMissing, on: channel))
            return
        }

        guard identity.encryptionKeyPairs.contains(tag), let publicKey = publicKeyLoader!(tag) else {
            store.dispatch(TelepathActions.Send(id: request.id, error: EncryptionError.keyNotFound, on: channel))
            return
        }

        store.dispatch(TelepathActions.Send(id: request.id, result: publicKey, on: channel))
    }

    private func loadPublicKeyFromKeychain(tag: String) -> PublicKey? {
        assert(false, "to be implemented")
        return nil
    }

    typealias PublicKey = Data
}