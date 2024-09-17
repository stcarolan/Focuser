import Foundation

class Logger {
    private let fileManager = FileManager.default
    private let logFileName = "McFocus.txt"
    
    private var logFileURL: URL? {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Unable to access Documents directory")
            return nil
        }
        return documentsDirectory.appendingPathComponent(logFileName)
    }
    
    func logTask(taskName: String, elapsedTime: Int) {
        guard let fileURL = logFileURL else {
            print("Unable to create log file URL")
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yy"
        let formattedDate = dateFormatter.string(from: Date())
        
        let logMessage = "\(taskName), \(elapsedTime), \(formattedDate)\n"
        
        do {
            if fileManager.fileExists(atPath: fileURL.path) {
                let fileHandle = try FileHandle(forWritingTo: fileURL)
                fileHandle.seekToEndOfFile()
                fileHandle.write(logMessage.data(using: .utf8)!)
                fileHandle.closeFile()
            } else {
                let header = "Task, Time, Date\n"
                let content = header + logMessage
                try content.write(to: fileURL, atomically: true, encoding: .utf8)
            }
            print("Log message written successfully to \(fileURL.path)")
        } catch {
            print("Error writing to log file: \(error)")
        }
    }
}
