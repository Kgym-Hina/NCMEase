import Foundation

struct NCMConverter {
    func convert(_ inputURL: URL) throws -> URL {
        let decoder = try NCMDecoder(url: inputURL)
        let outputURL = inputURL
            .deletingPathExtension()
            .appendingPathExtension(decoder.metadata.format.isEmpty ? "mp3" : decoder.metadata.format)

        return try decoder.writeDecryptedAudio(to: outputURL)
    }
}
