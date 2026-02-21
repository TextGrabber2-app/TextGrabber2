//
//  Recognizer.swift
//  TextGrabber2
//
//  Created by cyan on 2024/3/21.
//

import AppKit
@preconcurrency import Vision

/**
 https://developer.apple.com/documentation/vision/recognizing_text_in_images
 */
enum Recognizer {
  struct Candidate: Equatable, Hashable {
    enum Kind {
      case text
      case phoneNumber
      case link
    }

    let text: String
    let kind: Kind

    init(text: String, kind: Kind = .text) {
      self.text = text
      self.kind = kind
    }

    var icon: String {
      switch kind {
      case .text: return Icons.textAlignLeft
      case .phoneNumber: return Icons.phone
      case .link: return Icons.link
      }
    }
  }

  struct ResultData: Equatable {
    let candidates: [Candidate]

    init(candidates: [Candidate]) {
      let aggregated = candidates + (candidates.flatMap {
        Detector.matches(in: $0.text)
      })

      var seen = [String: Int]()
      var result = [Candidate]()

      for candidate in aggregated {
        guard !candidate.text.isEmpty else { continue }
        if let index = seen[candidate.text] {
          if result[index].kind == .text && candidate.kind != .text {
            result[index] = candidate
          }
        } else {
          seen[candidate.text] = result.count
          result.append(candidate)
        }
      }

      self.candidates = result
    }

    var lineBreaksJoined: String {
      candidates.map(\.text).joined(separator: "\n")
    }

    var spacesJoined: String {
      candidates.map(\.text).joined(separator: " ")
    }

    var directlyJoined: String {
      candidates.map(\.text).joined()
    }
  }

  static func detect(image: CGImage?, level: VNRequestTextRecognitionLevel) async -> ResultData? {
    guard let image else {
      return ResultData(candidates: [])
    }

    return await withCheckedContinuation { continuation in
      let request = VNRecognizeTextRequest { request, error in
        let candidates = request.results?
          .compactMap { $0 as? VNRecognizedTextObservation }
          .compactMap { $0.topCandidates(1).first?.string }

        DispatchQueue.main.async {
          guard error == nil, let candidates else {
            return continuation.resume(returning: nil)
          }

          continuation.resume(returning: ResultData(candidates: candidates.map { .init(text: $0) }))
        }
      }

      request.recognitionLevel = level
      request.usesLanguageCorrection = level == .accurate
      request.automaticallyDetectsLanguage = level == .accurate

      DispatchQueue.global(qos: .userInitiated).async {
        do {
          try VNImageRequestHandler(cgImage: image).perform([request])
        } catch {
          Logger.log(.error, "\(error)")
        }
      }
    }
  }
}
