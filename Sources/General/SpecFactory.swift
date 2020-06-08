//
//  Created by Artem Novichkov on 05.06.2020.
//

import Foundation
import Yams

final class SpecFactory {

    let decoder: YAMLDecoder
    let encoder: YAMLEncoder

    init(decoder: YAMLDecoder = .init(), encoder: YAMLEncoder = .init()) {
        self.decoder = decoder
        self.encoder = encoder
    }

    func makeSpec<Spec: Decodable>(url: URL) throws -> Spec {
        let specString = try String(contentsOf: url)
        return try decoder.decode(from: specString)
    }

    func makeData<Spec: Encodable>(spec: Spec) throws -> Data? {
        let specString = try encoder.encode(spec)
        return specString.data(using: .utf8)
    }
}
