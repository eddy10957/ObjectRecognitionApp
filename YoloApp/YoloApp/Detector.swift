//
//  Detector.swift
//  YoloApp
//
//  Created by Edoardo Troianiello on 28/08/23.
//

import Foundation
import Vision
import AVFoundation
import UIKit
import SwiftUI

extension ViewController {
    
    func setupDetector() {
        let modelURL = Bundle.main.url(forResource: "YOLOv3TinyInt8LUT", withExtension: "mlmodelc")
    
        do {
            let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL!))
            let recognitions = VNCoreMLRequest(model: visionModel, completionHandler: detectionDidComplete)
            self.requests = [recognitions]
        } catch let error {
            print(error)
        }
    }
    
    func detectionDidComplete(request: VNRequest, error: Error?) {
        DispatchQueue.main.async(execute: {
            if let results = request.results {
                self.extractDetections(results)
            }
        })
    }
    
    func extractDetections(_ results: [VNObservation]) {
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        detectionLayer.sublayers = nil
        
        for observation in results where observation is VNRecognizedObjectObservation {
            guard let objectObservation = observation as? VNRecognizedObjectObservation else { continue }
            let topLabelObservation = objectObservation.labels[0]
            firstLabel = topLabelObservation.identifier
            firstConfidence = topLabelObservation.confidence
            // Transformations
            let objectBounds = VNImageRectForNormalizedRect(objectObservation.boundingBox, Int(screenRect.size.width), Int(screenRect.size.height))
            let transformedBounds = CGRect(x: objectBounds.minX, y: screenRect.size.height - objectBounds.maxY, width: objectBounds.maxX - objectBounds.minX, height: objectBounds.maxY - objectBounds.minY)
            let boxLayer = self.drawBoundingBox(transformedBounds)
            let labelLayer = self.drawLabels(transformedBounds, label: firstLabel,confidence: firstConfidence)
                self.detectionLayer.addSublayer(boxLayer)
                self.detectionLayer.addSublayer(labelLayer)
        }
        CATransaction.commit()
    }
    
    func setupLayers() {
        detectionLayer = CALayer()
        detectionLayer.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)
        self.detectionLayer.zPosition = 1
        self.view.layer.addSublayer(detectionLayer)
    }
    
    func updateLayers() {
        detectionLayer?.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)
    }
    
    func drawBoundingBox(_ bounds: CGRect) -> CALayer {
        let boxLayer = CALayer()
        boxLayer.frame = bounds
        boxLayer.borderWidth = 3.0
        boxLayer.borderColor = CGColor.init(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        boxLayer.cornerRadius = 4
        boxLayer.backgroundColor = UIColor.clear.cgColor
        boxLayer.opacity = 1.0
//        boxLayer.compositingFilter = "lightenBlendMode"

        return boxLayer
    }
    
    func drawLabels(_ bounds: CGRect, label: String, confidence: VNConfidence) -> CATextLayer {
        let textLayer = CATextLayer()
        
        // Format the string
        let font = UIFont.systemFont(ofSize: 30)
        let colour = UIColor.white
        
        // Place the labels
        textLayer.backgroundColor = CGColor.init(red: 1.0, green: 00, blue: 0.0, alpha: 1.0)
        let attribute = [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: colour] as [NSAttributedString.Key : Any]
        let formattedString = NSMutableAttributedString(string: String(format: "\(label) (%.2f)", confidence), attributes: attribute)
        let size = formattedString.size()
        textLayer.bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        textLayer.string = formattedString
        textLayer.position = CGPoint(x: bounds.minX+(size.width/2.0), y: bounds.maxY+18.0)

        return textLayer
    }

    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:]) // Create handler to perform request on the buffer

        do {
            try imageRequestHandler.perform(self.requests) // Schedules vision requests to be performed
        } catch {
            print(error)
        }
    }
}
