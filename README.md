# Absumo 🇮🇹

A native iOS app for learning **Italian** — a Duolingo-style lessons app with a
playful, futuristic design built on the Italian tricolore (neon emerald · luminous
white · coral red).

> **Absumo** — a playful invented Italian verb (*io absumo, tu absumi…*, "I'm
> absorbing Italian"), built from the Latin *absum* ("I am away") behind Absum
> Corporation. The brand: from *absum* (absent) to fluent.

## Stack

- **SwiftUI** (iOS 18+) — declarative UI, `MeshGradient`, `TimelineView` animation
- **SwiftData** — local-first persistence (XP, streaks, lesson progress)
- **XcodeGen** — the `.xcodeproj` is generated from `project.yml` (not committed)
- Content is data-driven: lessons live in `Absumo/Resources/course_it.json`

## Project layout

```
Absumo/
  App/            AbsumoApp (entry) · RootView
  DesignSystem/   Palette · MeshBackground · Components · Haptics
  Models/         Content (Codable) · ContentStore · Persistence (SwiftData)
  Features/
    Home/         HomePathView · StatsHeader · PathNode
    Lesson/       LessonView · ExerciseScaffold · ResultsView
      Exercises/  MultipleChoiceView · WordBankView · MatchPairsView
  Resources/      course_it.json · Assets.xcassets
```

## Run it

```sh
brew install xcodegen          # one-time, if not installed
xcodegen generate              # regenerate Absumo.xcodeproj after adding files
open Absumo.xcodeproj          # then ⌘R in Xcode
```

Or build/run on a simulator from the command line:

```sh
xcodebuild -project Absumo.xcodeproj -scheme Absumo \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  CODE_SIGNING_ALLOWED=NO build
```

> Re-run `xcodegen generate` whenever you add or remove source files — the project
> is derived from `project.yml`.

## Implemented

- Animated tricolore mesh-gradient background
- Learning path with locked / current / completed lesson nodes
- Three exercise types: multiple choice, word-bank translation, match pairs
- Check → feedback → continue flow with haptics
- XP, streak, and lesson-completion tracking persisted via SwiftData
- Celebratory results screen

## Roadmap

- Audio (native-speaker playback + TTS via `AVSpeechSynthesizer`)
- Spaced-repetition review sessions
- More A1 content units
- Claude-powered conversation tutor
- iCloud sync (SwiftData + CloudKit)
