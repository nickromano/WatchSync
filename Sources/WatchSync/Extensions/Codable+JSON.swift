//
//  Codable+JSON.swift
//  WatchConnectivityExample
//
//  Created by Nicholas Romano on 3/15/18.
//  Copyright © 2018 Ten Minute Wait. All rights reserved.
//

import Foundation

extension Encodable {
  func toJSONData() throws -> Data {
    let encoder = JSONEncoder()
    return try encoder.encode(self)
  }

  func toJSONString() throws -> String {
    String(data: try toJSONData(), encoding: .utf8)!
  }
}

extension Decodable {
  static func fromJSONData(_ data: Data) throws -> Self {
    let decoder = JSONDecoder()
    return try decoder.decode(Self.self, from: data)
  }

  static func fromJSONString(_ string: String) throws -> Self {
    try fromJSONData(string.data(using: .utf8)!)
  }
}
