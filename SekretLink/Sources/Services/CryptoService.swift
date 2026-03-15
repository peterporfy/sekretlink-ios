import Foundation
import CommonCrypto

/// AES-256-CBC encryption/decryption compatible with crypto-js AES.encrypt/decrypt.
///
/// The web frontend (https://github.com/Ajnasz/sekret.link-ui) uses crypto-js which
/// produces OpenSSL-compatible output: Base64("Salted__" + 8-byte-salt + ciphertext).
/// Key and IV are derived from the password string using OpenSSL's EVP_BytesToKey
/// (MD5, 1 iteration).
final class CryptoService {

    enum CryptoError: Error {
        case randomGenerationFailed
        case invalidBase64
        case invalidFormat
        case encryptionFailed
        case decryptionFailed
        case invalidUTF8
    }

    // MARK: - Public API

    /// Generate a random 32-byte password encoded as a 64-character lowercase hex string.
    /// Matches the web frontend's `generatePassword()` + `encodeKey()`.
    func generatePassword() throws -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard status == errSecSuccess else { throw CryptoError.randomGenerationFailed }
        return bytes.map { String(format: "%02x", $0) }.joined()
    }

    /// Encrypt a plaintext string with the given password.
    /// Returns Base64-encoded OpenSSL Salted__ format.
    /// Matches: `AES.encrypt(data, password).toString()` in crypto-js.
    func encrypt(_ plaintext: String, password: String) throws -> String {
        guard let plaintextData = plaintext.data(using: .utf8) else {
            throw CryptoError.invalidUTF8
        }

        // Generate random 8-byte salt
        var salt = [UInt8](repeating: 0, count: 8)
        let saltStatus = SecRandomCopyBytes(kSecRandomDefault, salt.count, &salt)
        guard saltStatus == errSecSuccess else { throw CryptoError.randomGenerationFailed }

        let (key, iv) = evpBytesToKey(password: Data(password.utf8), salt: Data(salt))

        let ciphertext = try aesCBCEncrypt(data: plaintextData, key: key, iv: iv)

        // Build OpenSSL Salted__ format: "Salted__" + salt + ciphertext
        var output = Data()
        output.append(contentsOf: "Salted__".utf8)
        output.append(contentsOf: salt)
        output.append(ciphertext)

        return output.base64EncodedString()
    }

    /// Decrypt a Base64 OpenSSL Salted__ formatted ciphertext with the given password.
    /// Matches: `AES.decrypt(data, password).toString(enc.Utf8)` in crypto-js.
    func decrypt(_ ciphertext: String, password: String) throws -> String {
        guard let raw = Data(base64Encoded: ciphertext, options: .ignoreUnknownCharacters) else {
            throw CryptoError.invalidBase64
        }

        // Validate "Salted__" prefix (8 bytes) + salt (8 bytes) + ciphertext
        guard raw.count > 16 else { throw CryptoError.invalidFormat }

        let prefix = raw.prefix(8)
        guard String(bytes: prefix, encoding: .utf8) == "Salted__" else {
            throw CryptoError.invalidFormat
        }

        let salt = raw[8..<16]
        let encryptedData = raw[16...]

        let (key, iv) = evpBytesToKey(password: Data(password.utf8), salt: salt)

        let decryptedData = try aesCBCDecrypt(data: encryptedData, key: key, iv: iv)

        guard let plaintext = String(data: decryptedData, encoding: .utf8) else {
            throw CryptoError.invalidUTF8
        }

        return plaintext
    }

    // MARK: - Private

    /// OpenSSL-compatible EVP_BytesToKey key derivation (MD5, 1 iteration).
    /// Derives a 32-byte key and 16-byte IV from a password and salt.
    private func evpBytesToKey(password: Data, salt: Data) -> (key: Data, iv: Data) {
        // We need 48 bytes: 32 (key) + 16 (iv)
        // D1 = MD5(password + salt)         → 16 bytes
        // D2 = MD5(D1 + password + salt)    → 16 bytes
        // D3 = MD5(D2 + password + salt)    → 16 bytes
        // key = D1 + D2, iv = D3
        var d1 = md5(password + salt)
        var d2 = md5(d1 + password + salt)
        let d3 = md5(d2 + password + salt)

        var key = d1
        key.append(d2)
        let iv = d3

        return (key, iv)
    }

    private func md5(_ data: Data) -> Data {
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        data.withUnsafeBytes { ptr in
            _ = CC_MD5(ptr.baseAddress, CC_LONG(data.count), &digest)
        }
        return Data(digest)
    }

    private func aesCBCEncrypt(data: Data, key: Data, iv: Data) throws -> Data {
        let bufferSize = data.count + kCCBlockSizeAES128
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        var numBytesEncrypted = 0

        let status = key.withUnsafeBytes { keyPtr in
            iv.withUnsafeBytes { ivPtr in
                data.withUnsafeBytes { dataPtr in
                    CCCrypt(
                        CCOperation(kCCEncrypt),
                        CCAlgorithm(kCCAlgorithmAES),
                        CCOptions(kCCOptionPKCS7Padding),
                        keyPtr.baseAddress, key.count,
                        ivPtr.baseAddress,
                        dataPtr.baseAddress, data.count,
                        &buffer, bufferSize,
                        &numBytesEncrypted
                    )
                }
            }
        }

        guard status == kCCSuccess else { throw CryptoError.encryptionFailed }
        return Data(buffer.prefix(numBytesEncrypted))
    }

    private func aesCBCDecrypt(data: Data, key: Data, iv: Data) throws -> Data {
        let bufferSize = data.count + kCCBlockSizeAES128
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        var numBytesDecrypted = 0

        let dataArray = Array(data)
        let status = key.withUnsafeBytes { keyPtr in
            iv.withUnsafeBytes { ivPtr in
                dataArray.withUnsafeBytes { dataPtr in
                    CCCrypt(
                        CCOperation(kCCDecrypt),
                        CCAlgorithm(kCCAlgorithmAES),
                        CCOptions(kCCOptionPKCS7Padding),
                        keyPtr.baseAddress, key.count,
                        ivPtr.baseAddress,
                        dataPtr.baseAddress, dataArray.count,
                        &buffer, bufferSize,
                        &numBytesDecrypted
                    )
                }
            }
        }

        guard status == kCCSuccess else { throw CryptoError.decryptionFailed }
        return Data(buffer.prefix(numBytesDecrypted))
    }
}
