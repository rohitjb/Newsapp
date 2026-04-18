import Foundation
import CryptoKit

public final class PinningDelegate: NSObject, URLSessionDelegate, Sendable {

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
            let serverTrust = challenge.protectionSpace.serverTrust,
            let certChain = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate],
            let leafCert = certChain.first,
            let publicKey = SecCertificateCopyKey(leafCert),
            let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) as Data?
        else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        var trustError: CFError?
        guard SecTrustEvaluateWithError(serverTrust, &trustError) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        let hash = SHA256.hash(data: publicKeyData)
        let hashBase64 = Data(hash).base64EncodedString()

        if pinnedHashes.contains(hashBase64) {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
