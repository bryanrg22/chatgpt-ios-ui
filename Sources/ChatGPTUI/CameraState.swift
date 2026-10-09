import Foundation
import Observation
public enum CameraFlash: String, Sendable, CaseIterable { case off, auto, on }
public enum CameraAction: Equatable, Sendable { case open, close, shutter, scan(Bool), flash(CameraFlash), flip }
/// Presentation-only camera state. Never requests a camera, records audio, or captures real pixels.
@MainActor @Observable public final class CameraPresentationState {
    public var isPresented = false
    public var optionsExpanded = false
    public var scanning = false
    public var flash: CameraFlash = .off
    public var frontFacing = false
    public var captures = 0
    /// The reference compact options control showed a blue hint. Its dismissal policy is host-owned.
    public var showsOptionsHint = true
    public init() {}
    public func open() {
        isPresented = true
        optionsExpanded = false
        scanning = false
        captures = 0
    }
    public func close() {
        isPresented = false
        optionsExpanded = false
        scanning = false
        captures = 0
    }
    public func cycleFlash() { flash = flash == .off ? .auto : flash == .auto ? .on : .off }
    public func beginScan() {
        scanning = true
        optionsExpanded = false
    }
    public func back() { if scanning { scanning = false } else { close() } }
}
