import Foundation

enum RefreshStyle: String, CaseIterable, Identifiable {
    case cartoon = "Cartoon"
    case watercolor = "Watercolor"
    case popArt = "Pop Art"
    case neon = "Neon"
    case vintage = "Vintage"

    var id: String { rawValue }

    var promptDescription: String {
        switch self {
        case .cartoon:
            return "a fun cartoon illustration style with bold outlines and bright colors"
        case .watercolor:
            return "a soft watercolor painting style with gentle color washes and organic textures"
        case .popArt:
            return "a bold pop art style inspired by Andy Warhol with vivid contrasting colors and halftone dots"
        case .neon:
            return "a vibrant neon glow style with dark background and electric neon-colored outlines and highlights"
        case .vintage:
            return "a warm vintage photograph style with sepia tones, film grain, and slightly faded colors"
        }
    }
}
