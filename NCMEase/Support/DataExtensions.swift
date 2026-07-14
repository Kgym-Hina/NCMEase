import Foundation

extension Data {
    mutating func xor(_ value: UInt8) {
        for index in indices { self[index] ^= value }
    }
}

extension FileHandle {
    func readExactly(_ count: Int) throws -> Data {
        guard count >= 0 else { throw NCMError.invalidHeader }
        var result = Data()
        result.reserveCapacity(count)

        while result.count < count {
            guard let chunk = try read(upToCount: count - result.count), !chunk.isEmpty else {
                throw NCMError.invalidHeader
            }
            result.append(chunk)
        }
        return result
    }

    func readLittleEndianUInt32() throws -> UInt32 {
        let data = try readExactly(4)
        return data.withUnsafeBytes { $0.loadUnaligned(as: UInt32.self).littleEndian }
    }
}
