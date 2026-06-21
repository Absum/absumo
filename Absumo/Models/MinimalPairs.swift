import Foundation

/// A minimal pair: two Italian words differing by one sound the ear must learn
/// to distinguish (a geminate consonant, or stress). Each word has its own audio.
struct MinimalPair: Codable, Identifiable {
    let feature: String   // what's contrasted, e.g. "double consonant (nn)"
    let hint: String
    let a: PairWord
    let b: PairWord
    var id: String { a.file + "|" + b.file }
}

struct PairWord: Codable {
    let it: String
    let en: String
    let file: String      // bundled audio, e.g. "mp-nonno.wav"
}

enum MinimalPairs {
    private struct File: Decodable { let pairs: [MinimalPair] }

    static let all: [MinimalPair] = {
        guard let url = Bundle.main.url(forResource: "minimal_pairs_it", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(File.self, from: data)
        else { return [] }
        return file.pairs
    }()
}
