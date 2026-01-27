import SwiftUI

struct SetupSectionCard<Content: View>: View {
    let title: String
    let titleFont: Font
    let content: Content

    init(_ title: String, titleFont: Font = .headline, @ViewBuilder content: () -> Content) {
        self.title = title
        self.titleFont = titleFont
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(titleFont)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 16) {
                content
            }
            .padding(20)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }
}
