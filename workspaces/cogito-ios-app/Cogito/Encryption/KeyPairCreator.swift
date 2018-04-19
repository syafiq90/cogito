//  Copyright © 2018 Koninklijke Philips Nederland N.V. All rights reserved.

import Foundation
import Security

struct KeyPairCreator: KeyPairCreatorType {
    func create(tag: String) {
        let accessFlags = SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                                          kSecAttrAccessibleAfterFirstUnlock,
                                                          .userPresence,
                                                          nil)!
        let parameters: [String:Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits as String: 2048,
            kSecAttrApplicationTag as String: tag.data(using: .utf8)!,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: true,
                kSecAttrCanEncrypt as String: true,
                kSecAttrCanDecrypt as String: true,
                kSecAttrAccessControl as String: accessFlags
            ]
        ]
        var error: Unmanaged<CFError>?
        SecKeyCreateRandomKey(parameters as CFDictionary, &error)

    }
}

protocol KeyPairCreatorType {
    func create(tag: String)
}
