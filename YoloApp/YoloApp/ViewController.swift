import UIKit
import SwiftUI
import AVFoundation
import Vision


class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var permissionGranted = false // Flag for permission
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private var previewLayer = AVCaptureVideoPreviewLayer()
    var screenRect: CGRect! = nil // For view dimensions
    
    // Detector
    private var videoOutput = AVCaptureVideoDataOutput()
    var requests = [VNRequest]()
    var detectionLayer: CALayer! = nil
    var firstLabel: String = ""
    var firstConfidence: Float = 0.0
      
    
    override func viewDidLoad() {
        checkPermission()
        
        sessionQueue.async { [unowned self] in
            guard permissionGranted else { return }
            self.setupCaptureSession()
            
            self.setupLayers()
            self.setupDetector()
            
            self.captureSession.startRunning()

        }
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateLayers()
    }

    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        screenRect = UIScreen.main.bounds
        self.previewLayer.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)

        switch UIDevice.current.orientation {
            // Home button on top
            case UIDeviceOrientation.portraitUpsideDown:
                self.previewLayer.connection?.videoOrientation = .portraitUpsideDown
             
            // Home button on right
            case UIDeviceOrientation.landscapeLeft:
                self.previewLayer.connection?.videoOrientation = .landscapeRight
            
            // Home button on left
            case UIDeviceOrientation.landscapeRight:
                self.previewLayer.connection?.videoOrientation = .landscapeLeft
             
            // Home button at bottom
            case UIDeviceOrientation.portrait:
                self.previewLayer.connection?.videoOrientation = .portrait
                
            default:
                break
            }
        
        // Detector
        updateLayers()
    }
    
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            // Permission has been granted before
            case .authorized:
                permissionGranted = true
                
            // Permission has not been requested yet
            case .notDetermined:
                requestPermission()
                    
            default:
                permissionGranted = false
            }
    }
    
    func requestPermission() {
        // La coda delle sessioni viene sospesa in attesa della risposta dell'utente alla richiesta di autorizzazione.
        sessionQueue.suspend()
        
        // Si effettua la richiesta per ottenere l'accesso alla fotocamera.
        AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
            // Se l'autorizzazione viene concessa, la variabile 'permissionGranted' viene impostata di conseguenza.
            self.permissionGranted = granted
            
            // La coda delle sessioni viene ripresa.
            self.sessionQueue.resume()
        }
    }

    func setupCaptureSession() {
        // Si tenta di utilizzare la fotocamera posteriore.
        guard let videoDevice = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) else { return }
        
        // Si tenta di creare un nuovo input da videoDevice.
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }
        
        // Si verifica se l'input può essere aggiunto alla sessione di cattura.
        guard captureSession.canAddInput(videoDeviceInput) else { return }
        
        // L'input viene aggiunto alla sessione di cattura.
        captureSession.addInput(videoDeviceInput)
        
        // Si configurano le dimensioni dello schermo per il layer di anteprima.
        screenRect = UIScreen.main.bounds
        
        // Si configura il layer di anteprima video.
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill // Viene impostato per riempire lo schermo mantenendo le proporzioni.
        previewLayer.connection?.videoOrientation = .portrait
        previewLayer.zPosition = 0
        
        // Si configura il rilevatore di oggetti in tempo reale.
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sampleBufferQueue"))
        captureSession.addOutput(videoOutput)
        
        // L'orientamento del video viene impostato in modalità portrait.
        videoOutput.connection(with: .video)?.videoOrientation = .portrait
        
        // Gli aggiornamenti all'interfaccia utente vengono eseguiti sulla coda principale.
        DispatchQueue.main.async {
            // Il layer di anteprima viene aggiunto alla vista.
            self.view.layer.addSublayer(self.previewLayer)
        }
    }

}

struct HostedViewController: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        return ViewController()
        }

        func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        }
}
