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
  struct ResultData: Equatable {
    let candidates: [String]

    init(candidates: [String]) {
      var seen = Set(candidates)
      let aggregated = candidates + candidates.flatMap {
        Detector.matches(in: $0)
      }.filter {
        seen.insert($0).inserted
      }

      self.candidates = aggregated.filter { !$0.isEmpty }
    }

    var spacesJoined: String {
      candidates.joined(separator: " ")
    }

    var lineBreaksJoined: String {
      candidates.joined(separator: "\n")
    }

    var directlyJoined: String {
      candidates.joined()
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

          continuation.resume(returning: ResultData(candidates: candidates))
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
