//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import Foundation

public protocol HasSpecFactory {
    var specFactory: SpecFactory { get }
}

public protocol SpecFactory {
    func makeSpec<Spec: Decodable>(url: URL) throws -> Spec
    func makeData<Spec: Encodable>(spec: Spec) throws -> Data?
}
