import CommonCrypto
import Foundation

enum CommonCryptoAES {
    static func decryptECB(_ data: Data, key: Data) throws -> Data {
        var output = Data(count: data.count + kCCBlockSizeAES128)
        var outputLength = 0
        let outputCapacity = output.count
        let status = output.withUnsafeMutableBytes { outputBytes in
            data.withUnsafeBytes { inputBytes in
                key.withUnsafeBytes { keyBytes in
                    CCCrypt(CCOperation(kCCDecrypt), CCAlgorithm(kCCAlgorithmAES),
                            CCOptions(kCCOptionECBMode | kCCOptionPKCS7Padding),
                            keyBytes.baseAddress, key.count,
                            nil, inputBytes.baseAddress, data.count,
                            outputBytes.baseAddress, outputCapacity, &outputLength)
                }
            }
        }
        guard status == kCCSuccess else { throw NCMError.invalidMetadata }
        output.removeSubrange(outputLength..<output.count)
        return output
    }
}
