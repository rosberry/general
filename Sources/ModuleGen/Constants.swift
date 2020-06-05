//
//  Created by Artem Novichkov on 05.06.2020.
//

enum Constants {

    static let specFilename = "spec.yml"
    static let templatesFolderName = ".templates"
    static let commonTemplatesFolderName = "common"
    static let filesFolderName = "Code"
    static let spec = """
    files:
    - template: template.stencil
    """
    static let templateFilename = "template.stencil"
    static let template = "{{ name }}"
}