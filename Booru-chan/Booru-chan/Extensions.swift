
//
//  Extensions.swift
//  Booru-chan
//
//  Created by Ushio on 2016-05-03.
//

import Cocoa

extension NSTokenField {

    var tokens: [String] {
        switch tokenStyle {
            case .none:
                return self.stringValue.components(separatedBy: " ");
            default:
                return self.stringValue.components(separatedBy: ",");
        }
    }

    func addToken(_ token : String) {
        switch tokenStyle {
            case .none:
                self.stringValue += " \(token)";
                return;
            default:
                self.stringValue += ",\(token)";
                return;
        }
    }
}

extension FileManager {
    func createFolder(at path: String) {
        func createFolder(at path: String) {
            if !self.fileExists(atPath: path) {
                do {
                    try self.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil);
                }
                catch let error as NSError {
                    print("FileManager: Error creating folder at \(path), \(error.description)");
                }
            }
        }
    }
}
