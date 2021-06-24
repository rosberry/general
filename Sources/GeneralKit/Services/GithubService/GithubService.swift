//
//  Copyright © 2021 Rosberry. All rights reserved.
//

public protocol HasGithubService {
    var githubService: GithubService { get }
}

public protocol GithubService {

    func getGitRepoPath(repo: String) throws -> String
    func downloadFiles(at repo: String, filesHandler: ([FileInfo]) throws -> Void) throws

    @discardableResult
    func downloadFiles(at repo: String, to destination: String) throws -> [FileInfo]
}
