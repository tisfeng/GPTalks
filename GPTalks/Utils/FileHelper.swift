//
//  FileHelper.swift
//  GPTalks
//
//  Created by Zabir Raihan on 24/07/2024.
//

import Foundation
import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import QuickLook

struct FileHelper {
    static func deleteFile(at path: String) {
        do {
            #if os(macOS)
            if let fileURL = URL(string: path) {
                try Foundation.FileManager.default.removeItem(at: fileURL)
            }
            #else
            let documentsDirectory = try Foundation.FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let fileURL = documentsDirectory.appendingPathComponent(path)
            try Foundation.FileManager.default.removeItem(at: fileURL)
            #endif
        } catch {
            print("Error deleting file: \(error.localizedDescription)")
        }
    }
    
    static func createTemporaryURL(for typedData: TypedData) -> URL? {
        let tempDirectoryURL = FileManager.default.temporaryDirectory
        let fileName = typedData.fileName + "." + typedData.fileExtension
//        let fileExtension = typedData.fileType.preferredFilenameExtension ?? typedData.fileExtension
//        let fileURL = tempDirectoryURL.appendingPathComponent(fileName).appendingPathExtension(fileExtension)
        let fileURL = tempDirectoryURL.appendingPathComponent(fileName)

        do {
            try typedData.data.write(to: fileURL)
            return fileURL
        } catch {
            print("Error creating temporary file: \(error)")
            return nil
        }
    }
}


extension View {
    @ViewBuilder
    func multipleFileImporter(isPresented: Binding<Bool>, supportedFileTypes: [UTType], onDataAppend: @escaping (TypedData) -> Void) -> some View {
        self.fileImporter(
            isPresented: isPresented,
            allowedContentTypes: supportedFileTypes,
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                DispatchQueue.global(qos: .userInitiated).async {
                    for url in urls {
                        autoreleasepool {
                            if let data = try? Data(contentsOf: url) {
                                let fileType = UTType(filenameExtension: url.pathExtension) ?? .data
                                let fileName = url.deletingPathExtension().lastPathComponent
                                let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
                                let fileSize = (attributes?[.size] as? Int ?? 0).formatFileSize()
                                let fileExtension = url.pathExtension.lowercased()
                                
                                let typedData = TypedData(
                                    data: data,
                                    fileType: fileType,
                                    fileName: fileName,
                                    fileSize: fileSize,
                                    fileExtension: fileExtension
                                )
                                
                                DispatchQueue.main.async {
                                    onDataAppend(typedData)
                                }
                            }
                        }
                    }
                }
            case .failure(let error):
                print("File selection error: \(error.localizedDescription)")
            }
        }
    }
}

