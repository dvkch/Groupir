//
//  UserDefaults+SY.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 22/10/2021.
//

import Foundation

extension UserDefaults {
    
    func codableValue<T: Decodable>(_ type: T.Type, for key: String) -> T? {
        guard let data = self.data(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(type, from: data)
        }
        catch {
            Logger.e(.codable, "Couldn't decode value for key '\(key)': \(error)")
            return nil
        }
    }
    
    func setCodable<T: Encodable>(_ value: T?, for key: String) {
        guard let value = value else {
            removeObject(forKey: key)
            return
        }
        
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(value)
            set(data, forKey: key)
        }
        catch {
            Logger.e(.codable, "Couldn't encode value for key '\(key)': \(error)")
        }
    }
}
