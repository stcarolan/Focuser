//
//  WriteToFile.swift
//  Attention Manager
//
//  Created by Shawn Carolan on 9/14/24.
//

import Foundation

func logTask(taskName: String, elapsedTime: Int) {
    
    // Get the current date, dateformatter, and set format
    let currentDate = Date()
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MM/dd/yy"

    let formattedDate = dateFormatter.string(from: currentDate)
    let logMessage = "\(taskName), \(elapsedTime), \(formattedDate)\n"
    
    // The file path where you want to save the log file
    let fileName = "log.txt"

//    if let desktopDirectory = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first {
    if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
        let fileURL = documentDirectory.appendingPathComponent(fileName)
        
        do {
            // Check if the file exists
            if FileManager.default.fileExists(atPath: fileURL.path) {
                // If the file exists, open it using FileHandle for writing
                if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
                    // Seek to the end of the file to append the content
                    fileHandle.seekToEndOfFile()
                    if let data = logMessage.data(using: .utf8) {
                        fileHandle.write(data)
                        print("Log message appended successfully to \(fileURL.path)")
                    }
                    // Close the file handle
                    fileHandle.closeFile()
                }
            } else {
                // If the file does not exist, create it and write the header and log message
                let header = "Task, Time, Date\n"
                let content = "\(header)\(logMessage)"
                try content.write(to: fileURL, atomically: true, encoding: .utf8)
                print("Log file created with header and log message written successfully to \(fileURL.path)")
            }
        } catch {
            print("Error logging task: \(error)")
        }
    }
}
