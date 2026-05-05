import Foundation
import CryptoKit

public final class PinningDelegate: NSObject, URLSessionDelegate, Sendable {

    // ASN.1 SPKI headers — must prepend to raw key bytes before hashing
    // so the result matches: openssl x509 -pubkey | openssl pkey -pubin -outform DER | sha256
    private static let rsa2048Header = Data([
        0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09,
        0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01,
        0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0f, 0x00
    ])
    private static let rsa4096Header = Data([
        0x30, 0x82, 0x02, 0x22, 0x30, 0x0d, 0x06, 0x09,
        0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01,
        0x01, 0x05, 0x00, 0x03, 0x82, 0x02, 0x0f, 0x00
    ])
    private static let ecP256Header = Data([
        0x30, 0x59, 0x30, 0x13, 0x06, 0x07, 0x2a, 0x86,
        0x48, 0xce, 0x3d, 0x02, 0x01, 0x06, 0x08, 0x2a,
        0x86, 0x48, 0xce, 0x3d, 0x03, 0x01, 0x07, 0x03,
        0x42, 0x00
    ])

    private let pinnedHashes: Set<String>
    private let pinnedHost: String

    public init(
        pinnedHashes: Set<String> = PinningConfig.pinnedHashes,
        pinnedHost: String = PinningConfig.pinnedHost
    ) {
        self.pinnedHashes = pinnedHashes
        self.pinnedHost = pinnedHost
    }

    public func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard
            challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
            challenge.protectionSpace.host == pinnedHost,
            let serverTrust = challenge.protectionSpace.serverTrust
        else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        var trustError: CFError?
        guard SecTrustEvaluateWithError(serverTrust, &trustError) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        guard
            let certChain = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate],
            let leafCert = certChain.first,
            let publicKey = SecCertificateCopyKey(leafCert),
            let spkiData = spkiData(for: publicKey)
        else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        let hashBase64 = Data(SHA256.hash(data: spkiData)).base64EncodedString()

        if pinnedHashes.contains(hashBase64) {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }

    private func spkiData(for publicKey: SecKey) -> Data? {
        guard let keyData = SecKeyCopyExternalRepresentation(publicKey, nil) as Data? else { return nil }
        let attrs = SecKeyCopyAttributes(publicKey) as? [String: Any]
        let keyType = attrs?[kSecAttrKeyType as String] as? String
        let keySize = attrs?[kSecAttrKeySizeInBits as String] as? Int

        let rsaType = kSecAttrKeyTypeRSA as String
        let ecType  = kSecAttrKeyTypeEC as String

        let header: Data
        switch (keyType, keySize) {
        case (rsaType, 2048): header = Self.rsa2048Header
        case (rsaType, 4096): header = Self.rsa4096Header
        case (ecType, 256):  header = Self.ecP256Header
        default: return nil
        }
        return header + keyData
    }
}
