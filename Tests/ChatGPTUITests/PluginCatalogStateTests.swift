import Testing
@testable import ChatGPTUI

@Suite struct PluginCatalogStateTests {
    @Test func permissionOverrideAndResetAreLocalAndPerPlugin() {
        var catalog = PluginCatalogPresentationState()
        #expect(catalog.permission(for: "gmail") == .lowRisk)
        catalog.setPermission(.ask, for: "gmail")
        #expect(catalog.permission(for: "gmail") == .ask)
        #expect(catalog.permission(for: "drive") == .lowRisk)
        catalog.resetPermission(for: "gmail")
        #expect(catalog.permission(for: "gmail") == .lowRisk)
        #expect(catalog.permissionOverrides["gmail"] == nil)
    }
    @Test func selectingDefaultRemovesRedundantOverride() {
        var catalog = PluginCatalogPresentationState()
        catalog.setPermission(.all, for: "gmail")
        catalog.setPermission(.lowRisk, for: "gmail")
        #expect(catalog.permissionOverrides.isEmpty)
    }
    @Test func sampleAccountDeduplicatesAndDisconnectRemainsEmpty() {
        var catalog = PluginCatalogPresentationState()
        let duplicate = catalog.addSampleAccount(" ALEX@example.com ", for: "gmail")
        let invalid = catalog.addSampleAccount("invalid", for: "gmail")
        let added = catalog.addSampleAccount(" alex.work@example.com ", for: "gmail")
        #expect(!duplicate); #expect(!invalid); #expect(added)
        #expect(catalog.connectedAccounts(for: "gmail") == ["alex@example.com", "alex.work@example.com"])
        catalog.removeAccount("alex@example.com", for: "gmail")
        catalog.removeAccount("alex.work@example.com", for: "gmail")
        #expect(catalog.connectedAccounts(for: "gmail").isEmpty)
    }
    @Test func installAppearsInAvailableCatalogAndRemovalClearsLocalOverrides() {
        var catalog = PluginCatalogPresentationState()
        catalog.install("desktop")
        #expect(PluginFixture.all.filter { catalog.installedIDs.contains($0.id) }.contains { $0.id == "desktop" })
        catalog.setPermission(.read, for: "desktop")
        catalog.uninstall("desktop")
        #expect(!catalog.installedIDs.contains("desktop"))
        #expect(catalog.permissionOverrides["desktop"] == nil)
        #expect(catalog.connectedAccounts(for: "desktop").isEmpty)
    }
}
