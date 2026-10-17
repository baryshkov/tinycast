import SwiftUI

struct ScaledPaletteView: View {
    let core: AppCore
    var body: some View {
        let scale = core.settings.interfaceSize.scale
        let height = core.paletteCoordinator.paletteIsCollapsed ? Theme.Size.compactHeight : Theme.Size.panelHeight
        RootPaletteView()
            .frame(width: Theme.Size.panelWidth, height: height)
            .scaleEffect(scale, anchor: .topLeading)
            .frame(width: Theme.Size.panelWidth * scale, height: height * scale, alignment: .topLeading)
    }
}
