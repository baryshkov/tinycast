import SwiftUI

struct FileSearchPreview: View {

    let result: FileSearchResult?

    var body: some View {
        if let result {
            VStack(alignment: .leading, spacing: 0) {
                // Sized before the block below it, which then scrolls in whatever is left.
                FileSearchPreviewStage(result: result)
                    .aspectRatio(Theme.Size.previewAspectRatio, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .layoutPriority(1)
                ScrollView {
                    FileSearchInfoSection(result: result)
                }
            }
            .padding(.horizontal, Theme.Spacing.xl)
        } else {
            Color.clear
        }
    }
}

/// The file itself. One surface, held across selections: QuickLook renders a swap in about 8 ms.
private struct FileSearchPreviewStage: View {

    @Environment(PaletteState.self) private var palette
    let result: FileSearchResult

    private var card: RoundedRectangle {
        RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
    }

    var body: some View {
        stage
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, Theme.Spacing.xl)
    }

    /// Unmounting is the teardown: an ordered-out panel keeps its tree.
    @ViewBuilder private var stage: some View {
        if result.isDirectory {
            Image(systemName: "folder")
                .font(.system(.largeTitle))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.tertiary)
        } else if palette.isVisible {
            FileSearchSurface(url: result.url)
                .clipShape(card)
                .overlay(card.strokeBorder(Theme.Colors.cardStroke, lineWidth: 1))
        } else {
            Color.clear
        }
    }
}

/// The "Information" block; every disk read is gathered once, off the main actor.
private struct FileSearchInfoSection: View {

    let result: FileSearchResult
    @State private var details = Details()

    private struct Details: Equatable, Sendable {
        var typeName: String?
        var bytes: Int?
        var created: Date?
        var modified: Date?
    }

    private struct InfoRow: Identifiable {
        let label: String
        let value: String
        var id: String { label }
    }

    /// Relative day plus the time; shared, `DateFormatter` being expensive to build.
    @MainActor private static let stampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Information")
                .font(Theme.Typography.sectionHeader)
                .foregroundStyle(.secondary)
            VStack(spacing: 0) {
                let rows = self.rows
                ForEach(rows) { row in
                    if row.id != rows.first?.id { Divider() }
                    HStack(spacing: Theme.Spacing.sm) {
                        Text(row.label).foregroundStyle(.secondary)
                        Spacer(minLength: Theme.Spacing.lg)
                        Text(row.value).lineLimit(1).truncationMode(.middle)
                    }
                    .font(Theme.Typography.keyCap)
                    .padding(.vertical, Theme.Spacing.xs)
                }
            }
        }
        .padding(.vertical, Theme.Spacing.md)
        .task(id: result.id) { await loadDetails() }
    }

    private var rows: [InfoRow] {
        var rows = [
            InfoRow(label: "Name", value: result.name),
            InfoRow(label: "Where", value: result.parentPath),
            InfoRow(
                label: "Type",
                value: details.typeName ?? (result.isDirectory ? "Folder" : "File"))
        ]
        if let bytes = details.bytes {
            rows.append(
                InfoRow(label: "Size", value: Int64(bytes).formatted(.byteCount(style: .file))))
        }
        if let created = details.created {
            rows.append(InfoRow(label: "Created", value: Self.stampFormatter.string(from: created)))
        }
        if let modified = details.modified {
            rows.append(
                InfoRow(label: "Modified", value: Self.stampFormatter.string(from: modified)))
        }
        return rows
    }

    /// The type database spells a folder "folder"; the Type row reads like Finder's Kind.
    private nonisolated static func sentenceCased(_ name: String) -> String {
        name.prefix(1).localizedUppercase + name.dropFirst()
    }

    private func loadDetails() async {
        // Cleared first: the previous file's size must not sit under this one's name.
        details = Details()
        let url = result.url
        let isDirectory = result.isDirectory
        details = await Task.detached(priority: .userInitiated) {
            let values = try? url.resourceValues(forKeys: [
                .contentTypeKey, .fileSizeKey, .creationDateKey, .contentModificationDateKey
            ])
            return Details(
                typeName: values?.contentType?.localizedDescription.map(Self.sentenceCased),
                // A folder's own record is a few bytes, which is never what the row means.
                bytes: isDirectory ? nil : values?.fileSize,
                created: values?.creationDate,
                modified: values?.contentModificationDate)
        }.value
    }
}
