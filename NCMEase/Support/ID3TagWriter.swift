import Foundation

struct ID3TagWriter {
    let metadata: NCMMetadata

    func makeTag() -> Data {
        var frames = Data()
        frames.append(textFrame("TIT2", metadata.musicName))
        frames.append(textFrame("TALB", metadata.album))
        frames.append(textFrame("TPE1", metadata.artist.map(\.name).joined(separator: ", ")))
        frames.append(textFrame("TLEN", String(metadata.duration)))
        if !metadata.cover.isEmpty {
            frames.append(pictureFrame(metadata.cover))
        }

        var tag = Data("ID3".utf8)
        tag.append(contentsOf: [4, 0, 0])
        tag.append(contentsOf: synchsafe(frames.count))
        tag.append(frames)
        return tag
    }

    private func textFrame(_ identifier: String, _ value: String) -> Data {
        var content = Data([3])
        content.append(contentsOf: value.data(using: .utf8) ?? Data())
        return frame(identifier, content)
    }

    private func pictureFrame(_ image: Data) -> Data {
        var content = Data([3])
        content.append(contentsOf: Data("image/jpeg".utf8))
        content.append(0)
        content.append(3)
        content.append(0)
        content.append(image)
        return frame("APIC", content)
    }

    private func frame(_ identifier: String, _ content: Data) -> Data {
        var result = Data(identifier.utf8)
        result.append(contentsOf: UInt32(content.count).bigEndianBytes)
        result.append(contentsOf: [0, 0])
        result.append(content)
        return result
    }

    private func synchsafe(_ value: Int) -> [UInt8] {
        [UInt8((value >> 21) & 0x7f), UInt8((value >> 14) & 0x7f), UInt8((value >> 7) & 0x7f), UInt8(value & 0x7f)]
    }
}

private extension UInt32 {
    var bigEndianBytes: [UInt8] {
        [UInt8((self >> 24) & 0xff), UInt8((self >> 16) & 0xff), UInt8((self >> 8) & 0xff), UInt8(self & 0xff)]
    }
}
