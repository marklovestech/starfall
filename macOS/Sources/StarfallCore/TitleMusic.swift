public enum TitleMusic {
    public struct Note: Equatable, Sendable {
        public let frequencyHz: Int
        public let durationMilliseconds: Int

        public init(frequencyHz: Int, durationMilliseconds: Int) {
            self.frequencyHz = frequencyHz
            self.durationMilliseconds = durationMilliseconds
        }
    }

    // TITLESNG.PAS, using the rounded frequencies and durations from NOISE.PAS.
    public static let notes: [Note] = [
        Note(frequencyHz: 329, durationMilliseconds: 200),
        Note(frequencyHz: 261, durationMilliseconds: 200),
        Note(frequencyHz: 329, durationMilliseconds: 200),
        Note(frequencyHz: 439, durationMilliseconds: 200),
        Note(frequencyHz: 329, durationMilliseconds: 200),
        Note(frequencyHz: 439, durationMilliseconds: 200),
        Note(frequencyHz: 522, durationMilliseconds: 200),
        Note(frequencyHz: 439, durationMilliseconds: 200),
        Note(frequencyHz: 522, durationMilliseconds: 200),
        Note(frequencyHz: 658, durationMilliseconds: 1_200),
    ]
}
