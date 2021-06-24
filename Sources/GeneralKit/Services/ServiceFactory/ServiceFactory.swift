//
//  Copyright © 2021 Rosberry. All rights reserved.
//

// swiftlint:disable:next identifier_name
public var Services: ServiceFactory = .init()

public class ServiceFactory: HasGithubService,
                             HasFileHelper,
                             HasSetupService,
                             HasCompletionsService,
                             HasShell,
                             HasHelpParser,
                             HasConfigFactory,
                             HasSpecFactory,
                             HasUpgradeService,
                             HasPluginService {

    public lazy var pluginService: PluginService = PluginServiceImpl()
    public lazy var githubService: GithubService = GithubServiceImpl(dependencies: self)
    public lazy var fileHelper: FileHelper = FileHelperImpl()
    public lazy var setupService: SetupService = SetupServiceImpl(dependencies: self)
    public lazy var completionsService: CompletionsService = CompletionsServiceImpl(dependencies: self)
    public lazy var shell: Shell = ShellImpl()
    public lazy var upgradeService: UpgradeService = UpgradeServiceImpl(dependencies: self)
    public lazy var helpParser: HelpParser = HelpParserImpl(dependencies: self)
    public lazy var configFactory: ConfigFactory = ConfigFactoryImpl()
    public lazy var specFactory: SpecFactory = SpecFactoryImpl()
}
