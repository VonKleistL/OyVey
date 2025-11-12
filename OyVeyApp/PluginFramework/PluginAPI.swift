import Foundation

public protocol PluginAPI {
    var identifier: String { get }
    var displayName: String { get }
    func onLoad()
    func onUnload()
}
