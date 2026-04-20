import Foundation

enum RefreshStyle: String, CaseIterable, Identifiable {
    case cartoon = "Cartoon"
    case watercolor = "Watercolor"
    case popArt = "Pop Art"
    case neon = "Neon"
    case vintage = "Vintage"
    case mogul = "Mogul"
    case noir = "Noir"
    case vogue = "Vogue"
    case streetIcon = "Street Icon"
    case rockstar = "Rockstar"
    case neonGuardian = "Neon Guardian"
    case gladiator = "Gladiator"
    case alpha = "Alpha"
    case ceo = "CEO"
    case founder = "Founder"
    case billionaire = "Billionaire"
    case minimal = "Minimal"
    case dj = "DJ"
    case athlete = "Athlete"
    case ink = "Ink"
    case nightlife = "Nightlife"
    case outlaw = "Outlaw"
    case commander = "Commander"
    case royal = "Royal"
    case studioGold = "Studio Gold"

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
        case .mogul:
            return "an ultra-premium cinematic portrait with quiet billionaire energy, dark studio lighting, luxury fashion styling, refined shadows, polished editorial realism, and powerful restrained elegance"
        case .noir:
            return "a black-and-white noir portrait with classic detective-film atmosphere, dramatic side lighting, deep shadows, subtle smoke, timeless mystery, and elegant cinematic contrast"
        case .vogue:
            return "a high-fashion luxury magazine portrait with couture editorial styling, dramatic studio lighting, refined composition, glossy premium finish, and iconic fashion energy"
        case .streetIcon:
            return "a cinematic urban fashion portrait with premium streetwear attitude, moody city-inspired lighting, sharp detail, confident expression, and polished editorial edge"
        case .rockstar:
            return "an electric cinematic music-icon portrait with stage-inspired lighting, dark moody atmosphere, subtle haze, rebellious energy, fashion-forward styling, and iconic presence"
        case .neonGuardian:
            return "a futuristic cinematic sci-fi portrait with sleek high-tech styling, neon edge lighting, dark atmospheric background, glossy editorial realism, and precise dramatic contrast"
        case .gladiator:
            return "an epic heroic portrait with legendary gladiator energy, bold dramatic lighting, mythic atmosphere, powerful presence, premium realism, and commanding cinematic intensity"
        case .alpha:
            return "an ultra-detailed front-facing luxury portrait with symmetrical composition, intense eyes, black background, dramatic studio lighting, minimal distractions, and dominant editorial power"
        case .ceo:
            return "a high-end modern executive portrait with tailored luxury styling, clean dramatic lighting, controlled shadows, premium editorial realism, confidence, authority, and polished boardroom energy"
        case .founder:
            return "a modern visionary founder portrait with minimalist luxury wardrobe, sleek contemporary atmosphere, clean dramatic lighting, calm intelligence, sharp focus, and refined premium editorial design energy"
        case .billionaire:
            return "a luxury cinematic portrait with elite modern wealth energy, penthouse-night mood, elegant reflections, premium fashion styling, dramatic lighting, serious expression, and glossy editorial realism"
        case .minimal:
            return "a restrained minimalist editorial portrait with monochrome or neutral styling, soft but dramatic studio lighting, dark seamless background, elegant shadows, quiet power, and timeless refinement"
        case .dj:
            return "a stylish nightlife portrait with world-class DJ energy, moody club atmosphere, controlled neon accents, subtle haze, glossy editorial finish, magnetic presence, and premium after-dark fashion styling"
        case .athlete:
            return "a powerful sports-editorial portrait with elite athlete energy, intense expression, premium athletic styling, dramatic lighting, strong posture, subtle performance atmosphere, and bold campaign realism"
        case .ink:
            return "an edgy underground creative portrait with gritty luxury mood, dramatic side lighting, textured atmosphere, rebellious artistic energy, fashion-forward styling, and sharp editorial realism"
        case .nightlife:
            return "a luxury after-hours portrait with dark upscale nightlife atmosphere, subtle reflections, elegant fashion styling, moody cinematic lighting, mysterious expression, and seductive premium editorial realism"
        case .outlaw:
            return "a refined western outlaw portrait with dusty cinematic atmosphere, rugged styling, moody sunset-inspired lighting, serious expression, filmic realism, and powerful mysterious presence"
        case .commander:
            return "a heroic commanding-leader portrait with bold dramatic lighting, disciplined posture, strong eye contact, premium editorial realism, deep contrast, and authoritative cinematic presence"
        case .royal:
            return "a regal luxury portrait with royal grandeur, elegant dramatic lighting, refined opulent styling, stately posture, rich cinematic atmosphere, and premium editorial realism without looking theatrical or costume-like"
        case .studioGold:
            return "a dark luxury studio portrait accented by warm gold light, polished reflections, premium fashion mood, deep shadows, elegant composition, sharp facial detail, and rich editorial glamour"
        }
    }
}
