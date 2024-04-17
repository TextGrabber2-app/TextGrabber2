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
  struct ResultData {
    let candidates: [String]

    init(candidates: [String]) {
      var seen = Set(candidates)
      self.candidates = candidates + candidates.flatMap {
        Detector.matches(in: $0)
      }.filter {
        seen.insert($0).inserted
      }
    }

    var lineBreaksJoined: String {
      candidates.joined(separator: "\n")
    }

    var spacesJoined: String {
      candidates.joined(separator: " ")
    }
  }

  static func detect(image: CGImage) async -> ResultData {
    await withCheckedContinuation { continuation in
      let request = VNRecognizeTextRequest { request, error in
        let candidates = request.results?
          .compactMap { $0 as? VNRecognizedTextObservation }
          .compactMap { $0.topCandidates(1).first?.string }

        DispatchQueue.main.async {
          continuation.resume(returning: ResultData(candidates: candidates ?? []))
        }
      }

      // Prefer accuracy over speed
      request.recognitionLevel = .accurate
      request.usesLanguageCorrection = true
      request.automaticallyDetectsLanguage = true

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
