import Foundation


/// Lighting behavior requested by a foreground application or selected manually.
public enum AmbientMode: String, Codable, CaseIterable {
    case work
    case game
    case cinema
}

public struct AmbientAppRules: Codable {
    public var byBundleID: [String: AmbientMode]

    public init(byBundleID: [String: AmbientMode] = [:]) {
        self.byBundleID = byBundleID
    }

    public func mode(for bundleID: String?) -> AmbientMode {
        guard let bundleID else { return .work }
        return byBundleID[bundleID] ?? .work
    }
}

/// Resolves context changes without owning a timer or sending commands to the lamp.
/// Callers supply monotonic seconds and advance at the current deadline.
public struct AmbientContext {
    private struct Pending {
        let mode: AmbientMode
        let deadline: TimeInterval
    }

    public private(set) var active: AmbientMode
    public private(set) var isAutomatic: Bool
    public var deadline: TimeInterval? { pending?.deadline }
    private var pending: Pending?

    public init(active: AmbientMode = .work, isAutomatic: Bool = false) {
        self.active = active
        self.isAutomatic = isAutomatic
    }

    public mutating func observe(_ mode: AmbientMode, at now: TimeInterval) {
        guard isAutomatic else { return }
        guard mode != active else {
            pending = nil
            return
        }
        guard pending?.mode != mode else { return }

        let delay: TimeInterval = mode == .work ? 5 : 2
        pending = Pending(mode: mode, deadline: now + delay)
    }

    @discardableResult
    public mutating func advance(at now: TimeInterval) -> AmbientMode? {
        guard let pending, now >= pending.deadline else { return nil }
        self.pending = nil
        active = pending.mode
        return active
    }

    public mutating func selectManually(_ mode: AmbientMode) {
        isAutomatic = false
        pending = nil
        active = mode
    }

    public mutating func resumeAutomatic(with mode: AmbientMode, at now: TimeInterval) {
        isAutomatic = true
        pending = nil
        observe(mode, at: now)
    }
}
