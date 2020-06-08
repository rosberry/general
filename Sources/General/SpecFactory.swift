//
//  Created by Artem Novichkov on 05.06.2020.
//

import Foundation
import Yams

final class SpecFactory {

    let decoder: YAMLDecoder

    init(decoder: YAMLDecoder) {
        self.decoder = decoder
    }

    func makeSpec<Spec: Decodable>(url: URL) throws -> Spec {
        let specString = try String(contentsOf: url)
        return try decoder.decode(from: specString)
    }
}
