//
//  Detector.swift
//  YoloApp
//
//  Created by Edoardo Troianiello on 28/08/23.
//

// Importa le librerie necessarie per la visione computerizzata e la manipolazione delle immagini.
import Foundation
import Vision
import AVFoundation
import UIKit
import SwiftUI

// Estende il ViewController per includere le funzioni del rilevatore.
extension ViewController {
    
    // Configura il modello del detector YOLOv3.
    func setupDetector() {
        // Ottiene l'URL del modello YOLOv3.
        let modelURL = Bundle.main.url(forResource: "YOLOv3TinyInt8LUT", withExtension: "mlmodelc")
    
        do {
            // Carica il modello YOLOv3 come modello Vision.
            let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL!))
            // Crea una richiesta per effettuare riconoscimenti con il modello Vision.
            let recognitions = VNCoreMLRequest(model: visionModel, completionHandler: detectionDidComplete)
            self.requests = [recognitions]
        } catch let error {
            print(error)
        }
    }
    
    // Viene chiamata quando la richiesta di riconoscimento è completata.
    func detectionDidComplete(request: VNRequest, error: Error?) {
        DispatchQueue.main.async(execute: {
            // Estrae i risultati dalla richiesta.
            if let results = request.results {
                self.extractDetections(results)
            }
        })
    }
    
    // Estrae i dettagli rilevati e li visualizza nel layer di rilevamento.
    func extractDetections(_ results: [VNObservation]) {
        // Inizia una nuova transazione per il layer di rilevamento.
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        detectionLayer.sublayers = nil

        // Itera attraverso ogni osservazione per disegnare bounding box e etichette.
        for observation in results where observation is VNRecognizedObjectObservation {
            guard let objectObservation = observation as? VNRecognizedObjectObservation else { continue }
            
            // Estrae le informazioni più pertinenti dall'osservazione.
            let topLabelObservation = objectObservation.labels[0]
            firstLabel = topLabelObservation.identifier
            firstConfidence = topLabelObservation.confidence
            
            // Trasforma le coordinate per adattarle allo schermo.
            let objectBounds = VNImageRectForNormalizedRect(objectObservation.boundingBox, Int(screenRect.size.width), Int(screenRect.size.height))
            let transformedBounds = CGRect(x: objectBounds.minX, y: screenRect.size.height - objectBounds.maxY, width: objectBounds.maxX - objectBounds.minX, height: objectBounds.maxY - objectBounds.minY)
            
            // Disegna la bounding box e le etichette.
            let boxLayer = self.drawBoundingBox(transformedBounds)
            let labelLayer = self.drawLabels(transformedBounds, label: firstLabel, confidence: firstConfidence)
            
            self.detectionLayer.addSublayer(boxLayer)
            self.detectionLayer.addSublayer(labelLayer)
        }
        // Conclude la transazione per il layer di rilevamento.
        CATransaction.commit()
    }
    
    // Imposta i layer per le bounding box e le etichette.
    func setupLayers() {
        detectionLayer = CALayer()
        // Imposta le dimensioni del layer di rilevamento.
        detectionLayer.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)
        // Imposta la posizione Z del layer.
        self.detectionLayer.zPosition = 1
        // Aggiunge il layer di rilevamento al layer principale della vista.
        self.view.layer.addSublayer(detectionLayer)
    }
    
    // Aggiorna le dimensioni del layer di rilevamento.
    func updateLayers() {
        detectionLayer?.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)
    }
    
    // Disegna una bounding box attorno all'oggetto rilevato.
    func drawBoundingBox(_ bounds: CGRect) -> CALayer {
        let boxLayer = CALayer()
        boxLayer.frame = bounds
        // Configura lo stile della bounding box.
        boxLayer.borderWidth = 3.0
        boxLayer.borderColor = CGColor.init(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        boxLayer.cornerRadius = 4
        boxLayer.backgroundColor = UIColor.clear.cgColor
        boxLayer.opacity = 1.0
        return boxLayer
    }
    
    // Crea le etichette contenenti il nome dell'oggetto e la confidenza della rilevazione.
    func drawLabels(_ bounds: CGRect, label: String, confidence: VNConfidence) -> CATextLayer {
        let textLayer = CATextLayer()
        // Formatta il testo con la font e il colore appropriati.
        let font = UIFont.systemFont(ofSize: 30)
        let colour = UIColor.white
        // Configura le proprietà del layer di testo.
        textLayer.backgroundColor = CGColor.init(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        let attribute = [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: colour] as [NSAttributedString.Key : Any]
        let formattedString = NSMutableAttributedString(string: String(format: "\(label) (%.2f)", confidence), attributes: attribute)
        let size = formattedString.size()
        textLayer.bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        textLayer.string = formattedString
        // Posiziona il layer di testo sopra la bounding box.
        textLayer.position = CGPoint(x: bounds.minX+(size.width/2.0), y: bounds.maxY+18.0)
        return textLayer
    }
    
    // Funzione per gestire l'output della cattura video e avviare l'inferenza.
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do {
            // Effettua la richiesta di inferenza sul buffer di immagine.
            try imageRequestHandler.perform(self.requests)
        } catch {
            print(error)
        }
    }
}
