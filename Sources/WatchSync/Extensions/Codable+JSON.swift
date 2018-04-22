//
//  Codable+JSON.swift
//  WatchConnectivityExample
//
//  Created by Nicholas Romano on 3/15/18.
//  Copyright © 2018 Ten Minute Wait. All rights reserved.
//

import Foundation

extension Encodable {
    func toJSONString() throws -> String {
        let encoder = JSONEncoder()
        let data = try encoder.encode(self)
        return String(data: data, encoding: .utf8)!
    }
}

extension Decodable {
    static func fromJSONString(_ string: String) throws -> Self {
        let decoder = JSONDecoder()
        return try decoder.decode(Self.self, from: string.data(using: .utf8)!)
    }
}
