//
//  GoogleSheetsLogger.swift
//  Attention Manager
//
//  Created by Shawn Carolan on 9/11/24.
//

import GoogleSignIn
import GoogleAPIClientForREST_Sheets
import GTMAppAuth
import AppKit

class GoogleSheetsLogger {
    static let shared = GoogleSheetsLogger()
    private init() {}
    
    private var sheetsService: GTLRSheetsService?
    private let clientID = Config.googleClientID
    private let clientSecret = Config.googleClientSecret

    func authenticate(completion: @escaping (Bool) -> Void) {
        let signInConfig = GIDConfiguration(clientID: clientID)
        
        GIDSignIn.sharedInstance.signIn(
            withPresenting: NSApplication.shared.keyWindow!
        ) { signInResult, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let signInResult = signInResult else {
                print("No result returned")
                completion(false)
                return
            }
            
            // Check if we have the necessary scopes
            if !(signInResult.user.grantedScopes?.contains("https://www.googleapis.com/auth/spreadsheets") ?? false) {
                print("The user didn't grant the necessary scopes.")
                completion(false)
                return
            }

            let fetcherAuthorizer = signInResult.user.fetcherAuthorizer
            self.sheetsService = GTLRSheetsService()
            self.sheetsService?.authorizer = fetcherAuthorizer
            completion(true)            
        }
    }
    
    func logTask(taskName: String, elapsedTime: Int) {
        guard let sheetsService = sheetsService else {
            print("Not authenticated with Google Sheets")
            return
        }
        
        guard let spreadsheetId = UserDefaults.standard.string(forKey: "googleSheetURL")?.components(separatedBy: "/").last else {
            print("Invalid Google Sheet URL")
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let currentDateTime = dateFormatter.string(from: Date())
        
        let range = "Sheet1!A:C"
        let valueRange = GTLRSheets_ValueRange.init()
        valueRange.values = [[currentDateTime, taskName, String(elapsedTime)]]
        
        let query = GTLRSheetsQuery_SpreadsheetsValuesAppend.query(withObject: valueRange, spreadsheetId: spreadsheetId, range: range)
        query.valueInputOption = "USER_ENTERED"
        
        sheetsService.executeQuery(query) { (ticket, result, error) in
            if let error = error {
                print("Error appending to sheet: \(error.localizedDescription)")
            } else {
                print("Successfully logged task")
            }
        }
    }
}
