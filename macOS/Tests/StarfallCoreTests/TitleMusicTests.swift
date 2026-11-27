import Foundation
import StarfallCore
import Testing

@Test func titleMusicMatchesPascalScore() throws {
    let score = String(decoding: try fixture("source/TITLESNG.PAS"), as: UTF8.self).lowercased()
    let noise = String(decoding: try fixture("source/NOISE.PAS"), as: UTF8.self).lowercased()
    let base = try #require(noise.firstMatch(of: /frequency:=(\d+\.\d+);/))
    let interval = try #require(noise.firstMatch(of: /frequency:=frequency\*(\d+\.\d+);/))
    let c0 = try #require(Double(base.1))
    let semitone = try #require(Double(interval.1))

    let expected = try score.matches(of: /play\((\d+),([a-z]+),([a-z_+]+)\);/).map { call in
        let octave = try #require(Double(call.1))
        let pitch = try Regex("\\b\(call.2):(\\d+)", as: (Substring, Substring).self)
        let mapping = try #require(noise.firstMatch(of: pitch))
        let note = try #require(Double(mapping.1))
        let duration = try call.3.split(separator: "+").reduce(0) { sum, term in
            let constant = try Regex("\\b\(term)\\s*=\\s*(\\d+);", as: (Substring, Substring).self)
            let match = try #require(noise.firstMatch(of: constant))
            return sum + (try #require(Int(match.1)))
        }
        let frequency = Int((c0 * pow(2, octave) * pow(semitone, note - 1)).rounded())
        return TitleMusic.Note(frequencyHz: frequency, durationMilliseconds: duration)
    }

    #expect(expected.count == 10)
    #expect(TitleMusic.notes == expected)
}
