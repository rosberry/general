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

    func makeModuleGenSpec(url: URL) throws -> ModuleGenSpec {
        let specURL = url.appendingPathComponent("modulegen.yml")
        let specString = try String(contentsOf: specURL)
        let spec = try decoder.decode(ModuleGenSpec.self, from: specString)
        return spec
    }
}
