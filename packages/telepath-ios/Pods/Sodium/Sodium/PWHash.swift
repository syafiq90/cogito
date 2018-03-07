import Foundation
import libsodium

public class PWHash {
    public let SaltBytes = Int(crypto_pwhash_saltbytes())
    public let StrBytes = Int(crypto_pwhash_strbytes()) - (1 as Int)
    public let StrPrefix = String.init(validatingUTF8: crypto_pwhash_strprefix())
    public let OpsLimitInteractive = Int(crypto_pwhash_opslimit_interactive())
    public let OpsLimitModerate = Int(crypto_pwhash_opslimit_moderate())
    public let OpsLimitSensitive = Int(crypto_pwhash_opslimit_sensitive())
    public let MemLimitInteractive = Int(crypto_pwhash_memlimit_interactive())
    public let MemLimitModerate = Int(crypto_pwhash_memlimit_moderate())
    public let MemLimitSensitive = Int(crypto_pwhash_memlimit_sensitive())

    public enum Alg {
        case Default
        case Argon2I13
        case Argon2ID13
    }

    /**
     Generates an ASCII encoded string, which includes:

     - the result of the memory-hard, CPU-intensive Argon2 password hashing function applied to the password `passwd`
     - the automatically generated salt used for the previous computation
     - the other parameters required to verify the password, including the algorithm identifier, its version, opslimit and memlimit.

     The output string includes only ASCII characters and can be safely stored into SQL databases and other data stores. No extra information has to be stored in order to verify the password.

     - Parameter passwd: The password data to hash.
     - Parameter opsLimit: Represents a maximum amount of computations to perform. Raising this number will make the function require more CPU cycles to compute a key.
     - Parameter memLimit: The maximum amount of RAM that the function will use, in bytes.

     - Returns: The generated string.
     */
    public func str(passwd: Data, opsLimit: Int, memLimit: Int) -> String? {
        var output = Data(count: StrBytes)
        let result = output.withUnsafeMutableBytes { outputPtr in
            passwd.withUnsafeBytes { passwdPtr in
                crypto_pwhash_str(outputPtr,
                                  passwdPtr, CUnsignedLongLong(passwd.count),
                                  CUnsignedLongLong(opsLimit), size_t(memLimit))
            }
        }
        if result != 0 {
            return nil
        }
        return String(data: output, encoding: .utf8)
    }

    /**
     Verifies that the password str is a valid password verification string (as generated by `str(passwd: Data, opslimit: Int, memLimit: Int)` for `passwd`.

     - Parameter hash: The password hash string to verify.
     - Parameter passwd: The password data to verify.

     - Returns: `true` if the verification succeeds.
     */
    public func strVerify(hash: String, passwd: Data) -> Bool {
        guard let hashData = (hash + "\0").data(using: .utf8, allowLossyConversion: false) else {
            return false
        }
        return hashData.withUnsafeBytes { hashPtr in
            passwd.withUnsafeBytes { passwdPtr in
                crypto_pwhash_str_verify(
                    hashPtr, passwdPtr, CUnsignedLongLong(passwd.count)) == 0
            }
        }
    }

    /**
     Checks that a string previously hashed password matches the current algorithm and parameters

     - Parameter hash: The password hash string to check.
     - Parameter opsLimit: Represents a maximum amount of computations to perform. Raising this number will make the function require more CPU cycles to compute a key.
     - Parameter memLimit: The maximum amount of RAM that the function will use, in bytes.

     - Returns: `true` if the password hash should be updated.
     */
    public func strNeedsRehash(hash: String, opsLimit: Int, memLimit: Int) -> Bool {
        guard let hashData = (hash + "\0").data(using: .utf8, allowLossyConversion: false) else {
            return true
        }
        return hashData.withUnsafeBytes { hashPtr in
            crypto_pwhash_str_needs_rehash(
                hashPtr, CUnsignedLongLong(opsLimit), size_t(memLimit)) != 0
        }
    }

    /**
     Derives a key from a password and a salt using the Argon2 password hashing function.

     Keep in mind that in order to produce the same key from the same password, the same salt, and the same values for opslimit and memlimit have to be used. Therefore, these parameters have to be stored for each user.

     - Parameter outputLength: Desired length of the derived key.  Should be at least 16 (128 bits)
     - Parameter passwd: The password data to hash.
     - Parameter salt: Unpredicatable salt data.  Must have a fixed length of `SaltBytes`.
     - Parameter opsLimit: Represents a maximum amount of computations to perform. Raising this number will make the function require more CPU cycles to compute a key.
     - Parameter memLimit: The maximum amount of RAM that the function will use, in bytes.
     - Parameter alg: The algorithm identifier (`.Default`, `.Argon2I13`, `.Argon2ID13`).

     - Returns: The derived key data.
     */
    public func hash(outputLength: Int, passwd: Data, salt: Data, opsLimit: Int, memLimit: Int, alg: Alg = .Default) -> Data? {
        if salt.count != SaltBytes {
            return nil
        }
        var output = Data(count: outputLength)
        var algId: Int32
        switch alg {
        case .Default:
            algId = crypto_pwhash_alg_default()
        case .Argon2I13:
            algId = crypto_pwhash_alg_argon2i13()
        case .Argon2ID13:
            algId = crypto_pwhash_alg_argon2id13()
        }
        let result = passwd.withUnsafeBytes { passwdPtr in
            salt.withUnsafeBytes { saltPtr in
                output.withUnsafeMutableBytes { outputPtr in
                    crypto_pwhash(
                        outputPtr, CUnsignedLongLong(outputLength),
                        passwdPtr, CUnsignedLongLong(passwd.count),
                        saltPtr, CUnsignedLongLong(opsLimit),
                        size_t(memLimit), algId)
                }
            }
        }
        if result != 0 {
            return nil
        }
        return output
    }
}
