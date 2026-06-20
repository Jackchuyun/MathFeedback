import Foundation

enum SwiftDataStoreRecovery {
    static func backupAndRemoveDefaultStores() throws -> URL {
        let fileManager = FileManager.default
        let applicationSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let documents = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let backupFolder = documents.appendingPathComponent(
            "MathFeedback_Data_Recovery_\(formatter.string(from: .now))",
            isDirectory: true
        )
        try fileManager.createDirectory(at: backupFolder, withIntermediateDirectories: true)

        let storeFiles = try collectStoreFiles(in: applicationSupport, fileManager: fileManager)
        guard !storeFiles.isEmpty else { return backupFolder }

        for file in storeFiles {
            let destination = backupFolder.appendingPathComponent(file.lastPathComponent)
            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.removeItem(at: destination)
            }
            try fileManager.moveItem(at: file, to: destination)
        }

        return backupFolder
    }

    private static func collectStoreFiles(in folder: URL, fileManager: FileManager) throws -> [URL] {
        guard fileManager.fileExists(atPath: folder.path) else { return [] }

        let files = try fileManager.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )

        return files.filter { url in
            let name = url.lastPathComponent.lowercased()
            return name.hasSuffix(".store")
                || name.contains(".store-")
                || name.hasSuffix(".sqlite")
                || name.hasSuffix(".sqlite-shm")
                || name.hasSuffix(".sqlite-wal")
        }
    }
}
