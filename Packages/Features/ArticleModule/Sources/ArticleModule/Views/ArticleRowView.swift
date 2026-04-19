import SwiftUI

public struct ArticleRowView: View {
    let article: Article

    public init(article: Article) {
        self.article = article
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let imageURL = article.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle().fill(Color.secondary.opacity(0.2))
                }
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            Text(article.title)
                .font(.headline)
                .lineLimit(3)
            HStack {
                Text(article.sourceName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(article.publishedAt.prefix(10))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
