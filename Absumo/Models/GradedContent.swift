import Foundation
import SwiftData

/// A graded comprehensible-input item: a short Italian passage at a CEFR level,
/// with a per-surface-form glossary (so a conjugated word like "vado" can show
/// its meaning AND its dictionary form "andare"), the target high-frequency
/// words it reinforces, and an optional audio file (TTS, added in a later task).
struct GradedItem: Codable, Identifiable {
    let id: String
    let title: String
    let level: String          // "A1", "A2", …
    let order: Int             // position in the guided "Start here" track
    let text: String           // the Italian passage
    let translation: String    // full English translation (comprehension aid)
    let glossary: [Gloss]
    let audio: String?         // bundled audio filename, once TTS is wired

    /// Glossary keyed by surface form (as it appears in `text`).
    func gloss(for surface: String) -> Gloss? {
        let key = Gloss.normalize(surface)
        return glossary.first { Gloss.normalize($0.word) == key }
    }
}

/// One word as it appears in the text, linked to its dictionary form + meaning.
struct Gloss: Codable {
    let word: String     // surface form, e.g. "vado"
    let lemma: String    // dictionary form, e.g. "andare"
    let en: String       // meaning, e.g. "I go"

    /// Whether this surface is itself the dictionary form (no conjugation link).
    var isLemma: Bool { Gloss.normalize(word) == Gloss.normalize(lemma) }

    /// Lowercase and strip surrounding punctuation so tokens in the text match
    /// glossary keys (keeps internal apostrophes, e.g. "po'").
    static func normalize(_ s: String) -> String {
        s.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ".,!?;:\"«»()…"))
    }
}

/// Loads the bundled graded library. Mirrors ContentStore for the new model.
enum GradedLibrary {
    private struct File: Decodable { let items: [GradedItem] }

    static let all: [GradedItem] = {
        guard let url = Bundle.main.url(forResource: "graded_it", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(File.self, from: data)
        else { return [] }
        return file.items.sorted { $0.order < $1.order }
    }()

    static func item(_ id: String) -> GradedItem? { all.first { $0.id == id } }
}

/// Tracks which graded items the learner has read (for the guided track + Today).
@Model
final class ReadingProgress {
    @Attribute(.unique) var itemID: String
    var completed: Bool
    var lastOpened: Date

    init(itemID: String, completed: Bool = false, lastOpened: Date = .now) {
        self.itemID = itemID
        self.completed = completed
        self.lastOpened = lastOpened
    }
}
