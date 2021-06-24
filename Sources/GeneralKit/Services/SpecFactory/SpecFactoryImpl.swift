//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import Foundation
import Yams

public final class SpecFactoryImpl: SpecFactory {

    let decoder: YAMLDecoder
    let encoder: YAMLEncoder

    public init(decoder: YAMLDecoder = .init(), encoder: YAMLEncoder = .init()) {
        self.decoder = decoder
        self.encoder = encoder
    }

    public func makeSpec<Spec: Decodable>(url: URL) throws -> Spec {
        let specString = try String(contentsOf: url)
        return try decoder.decode(from: specString)
    }

    public func makeData<Spec: Encodable>(spec: Spec) throws -> Data? {
        let specString = try encoder.encode(spec)
        return specString.data(using: .utf8)
    }
}
