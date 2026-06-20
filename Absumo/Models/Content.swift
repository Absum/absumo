import Foundation

// MARK: - Course content model (static, decoded from bundled JSON)

struct Course: Decodable {
    let language: String
    let units: [Unit]
}

struct Unit: Decodable, Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let accent: String   // "verde" | "rosso" | "bianco"
    let lessons: [Lesson]
}

struct Lesson: Decodable, Identifiable {
    let id: String
    let title: String
    let icon: String     // SF Symbol name
    let exercises: [Exercise]
}

// MARK: - Polymorphic exercises

enum Exercise: Decodable, Identifiable {
    case multipleChoice(MultipleChoice)
    case wordBank(WordBank)
    case matchPairs(MatchPairs)

    var id: String {
        switch self {
        case .multipleChoice(let m): return m.id
        case .wordBank(let w): return w.id
        case .matchPairs(let p): return p.id
        }
    }

    private enum CodingKeys: String, CodingKey { case type }
    private enum Kind: String, Decodable { case multipleChoice, wordBank, matchPairs }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(Kind.self, forKey: .type) {
        case .multipleChoice: self = .multipleChoice(try MultipleChoice(from: decoder))
        case .wordBank:       self = .wordBank(try WordBank(from: decoder))
        case .matchPairs:     self = .matchPairs(try MatchPairs(from: decoder))
        }
    }
}

struct MultipleChoice: Decodable, Identifiable {
    var id = UUID().uuidString
    let prompt: String
    let italian: String?
    let options: [String]
    let answerIndex: Int

    private enum CodingKeys: String, CodingKey { case prompt, italian, options, answerIndex }
}

struct WordBank: Decodable, Identifiable {
    var id = UUID().uuidString
    let prompt: String        // English sentence to translate
    let answer: [String]      // correct Italian tokens, in order
    let distractors: [String]

    private enum CodingKeys: String, CodingKey { case prompt, answer, distractors }
}

struct MatchPairs: Decodable, Identifiable {
    var id = UUID().uuidString
    let prompt: String
    let pairs: [Pair]

    struct Pair: Decodable, Identifiable, Hashable {
        var id = UUID().uuidString
        let it: String
        let en: String

        private enum CodingKeys: String, CodingKey { case it, en }
    }

    private enum CodingKeys: String, CodingKey { case prompt, pairs }
}
