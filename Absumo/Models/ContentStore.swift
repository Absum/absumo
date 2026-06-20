import Foundation
import Observation

/// Loads and holds the static course content decoded from the app bundle.
@Observable
final class ContentStore {
    private(set) var course: Course

    init() {
        course = ContentStore.load()
    }

    /// Flattened, ordered list of every lesson paired with its unit — drives the path UI.
    var path: [(unit: Unit, lesson: Lesson)] {
        course.units.flatMap { unit in unit.lessons.map { (unit, $0) } }
    }

    static func load() -> Course {
        guard let url = Bundle.main.url(forResource: "course_it", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("⚠️ course_it.json not found in bundle")
            return Course(language: "Italian", units: [])
        }
        do {
            return try JSONDecoder().decode(Course.self, from: data)
        } catch {
            print("⚠️ Failed to decode course content: \(error)")
            return Course(language: "Italian", units: [])
        }
    }
}
