import Foundation

struct NCMMetadata: Decodable {
    let album: String
    let artist: [NCMArtist]
    let format: String
    let duration: Int
    let musicName: String
    let cover: Data

    private enum CodingKeys: String, CodingKey {
        case album, artist, format, duration, musicName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        album = try container.decodeIfPresent(String.self, forKey: .album) ?? ""
        artist = try container.decodeIfPresent([NCMArtist].self, forKey: .artist) ?? []
        format = try container.decodeIfPresent(String.self, forKey: .format) ?? "mp3"
        duration = try container.decodeIfPresent(Int.self, forKey: .duration) ?? 0
        musicName = try container.decodeIfPresent(String.self, forKey: .musicName) ?? ""
        cover = Data()
    }

    init(album: String, artist: [NCMArtist], format: String, duration: Int, musicName: String, cover: Data) {
        self.album = album
        self.artist = artist
        self.format = format
        self.duration = duration
        self.musicName = musicName
        self.cover = cover
    }
}

struct NCMArtist: Decodable {
    let name: String

    init(from decoder: Decoder) throws {
        var values = try decoder.unkeyedContainer()
        name = try values.decode(String.self)
    }
}

enum NCMError: LocalizedError {
    case invalidHeader
    case invalidKey
    case invalidMetadata
    case invalidCover
    case invalidFormat
    case unableToCreateOutput

    var errorDescription: String? {
        switch self {
        case .invalidHeader: return "Invalid NCM file header"
        case .invalidKey: return "Unable to decrypt NCM audio key"
        case .invalidMetadata: return "Unable to decrypt NCM metadata"
        case .invalidCover: return "Invalid NCM cover data"
        case .invalidFormat: return "Unsupported NCM format"
        case .unableToCreateOutput: return "Unable to create output file"
        }
    }
}

final class NCMDecoder {
    private static let coreKey = Data("hzHRAmso5kInbaxW".utf8)
    private static let metaKey = Data("#14ljk_!\\]&0U<'(".utf8)
    private static let keyMask: UInt8 = 0x64
    private static let metaMask: UInt8 = 0x63

    let metadata: NCMMetadata
    private let input: FileHandle
    private var keyBox: [UInt8]
    private var keyIndex: UInt8 = 0

    init(url: URL) throws {
        input = try FileHandle(forReadingFrom: url)
        guard try input.read(upToCount: 8) == Data("CTENFDAM".utf8) else { throw NCMError.invalidHeader }
        _ = try input.read(upToCount: 2)

        let keyLength = try input.readLittleEndianUInt32()
        var encryptedKey = try input.readExactly(Int(keyLength))
        encryptedKey.xor(Self.keyMask)
        let decryptedKey = try CommonCryptoAES.decryptECB(encryptedKey, key: Self.coreKey)
        guard decryptedKey.count > 17, decryptedKey.prefix(17) == Data("neteasecloudmusic".utf8) else {
            throw NCMError.invalidKey
        }
        keyBox = Self.buildKeyBox(Array(decryptedKey.dropFirst(17)))

        let metaLength = try input.readLittleEndianUInt32()
        var encryptedMeta = try input.readExactly(Int(metaLength))
        encryptedMeta.xor(Self.metaMask)
        guard encryptedMeta.count > 22, encryptedMeta.prefix(22) == Data("163 key(Don't modify):".utf8),
              let base64 = Data(base64Encoded: encryptedMeta.dropFirst(22)) else {
            throw NCMError.invalidMetadata
        }

        let decryptedMeta: Data
        do {
            decryptedMeta = try CommonCryptoAES.decryptECB(base64, key: Self.metaKey)
        } catch {
            throw NCMError.invalidMetadata
        }
        guard decryptedMeta.count > 6, decryptedMeta.prefix(6) == Data("music:".utf8) else {
            throw NCMError.invalidMetadata
        }

        let decodedMetadata: NCMMetadata
        do {
            decodedMetadata = try JSONDecoder().decode(NCMMetadata.self, from: decryptedMeta.dropFirst(6))
        } catch {
            throw NCMError.invalidMetadata
        }

        _ = try input.readExactly(5)
        let coverFrameLength = try input.readLittleEndianUInt32()
        let coverLength = try input.readLittleEndianUInt32()
        guard coverLength <= coverFrameLength else { throw NCMError.invalidCover }
        let cover = try input.readExactly(Int(coverLength))
        if coverFrameLength > coverLength {
            _ = try input.readExactly(Int(coverFrameLength - coverLength))
        }
        metadata = NCMMetadata(album: decodedMetadata.album, artist: decodedMetadata.artist,
                               format: decodedMetadata.format, duration: decodedMetadata.duration,
                               musicName: decodedMetadata.musicName, cover: cover)
    }

    func writeDecryptedAudio(to url: URL) throws -> URL {
        FileManager.default.createFile(atPath: url.path, contents: nil)
        guard let output = try? FileHandle(forWritingTo: url) else { throw NCMError.unableToCreateOutput }
        defer {
            try? output.close()
            try? input.close()
        }

        try output.write(contentsOf: ID3TagWriter(metadata: metadata).makeTag())
        while let chunk = try input.read(upToCount: 1024 * 1024), !chunk.isEmpty {
            var decrypted = chunk
            for index in decrypted.indices {
                decrypted[index] ^= nextKeyByte()
            }
            try output.write(contentsOf: decrypted)
        }
        return url
    }

    private func nextKeyByte() -> UInt8 {
        keyIndex &+= 1
        let first = keyBox[Int(keyIndex)]
        let second = keyBox[Int(first &+ keyIndex)]
        return keyBox[Int(first &+ second)]
    }

    private static func buildKeyBox(_ keyData: [UInt8]) -> [UInt8] {
        var box = Array(0...255).map(UInt8.init)
        var last: UInt8 = 0
        var offset = 0
        for index in 0..<256 {
            let value = box[index] &+ last &+ keyData[offset]
            offset = (offset + 1) % keyData.count
            box.swapAt(index, Int(value))
            last = value
        }
        return box
    }
}
