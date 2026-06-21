import Foundation

/// A short, contextual grammar note. Surfaced in the reader when one of its
/// `triggers` (glossary lemmas) appears in the passage, or the item is listed
/// in `items`. Comprehension aid — never a quiz.
struct GrammarNote: Codable, Identifiable {
    let id: String
    let title: String
    let body: String
    let triggers: [String]
    let items: [String]
}

enum GrammarNotes {
    private struct File: Decodable { let notes: [GrammarNote] }

    static let all: [GrammarNote] = {
        guard let url = Bundle.main.url(forResource: "grammar_notes_it", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(File.self, from: data)
        else { return [] }
        return file.notes
    }()

    /// Notes relevant to a graded item: any note whose trigger lemma appears in
    /// the item's glossary, or that explicitly lists the item.
    static func relevant(for item: GradedItem) -> [GrammarNote] {
        let lemmas = Set(item.glossary.map { $0.lemma.lowercased() })
        return all.filter { note in
            note.items.contains(item.id) || note.triggers.contains(where: { lemmas.contains($0) })
        }
    }
}
