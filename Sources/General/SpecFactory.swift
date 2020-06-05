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

    func makeTemplateSpec(url: URL) throws -> TemplateSpec {
        let specString = try String(contentsOf: url)
        let spec = try decoder.decode(TemplateSpec.self, from: specString)
        return spec
    }

    func makeGeneralSpec(url: URL) throws -> GeneralSpec {
        let specURL = url.appendingPathComponent("general.yml")
        let specString = try String(contentsOf: specURL)
        let spec = try decoder.decode(GeneralSpec.self, from: specString)
        return spec
    }
}
