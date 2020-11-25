//
//  ViewController.swift
//  WhatFlower
//
//  Created by Denis Aleksandrov on 11/23/20.
//

import UIKit
import CoreML
import Vision

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    let imagePicker = UIImagePickerController()
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .camera
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userPickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            guard let ciImage = CIImage(image: userPickedImage) else {
                fatalError(#function + ": Cannot convert UI image to CI image from UIImagePickerController for further processing")
            }
            imageView.image = userPickedImage
            imagePicker.dismiss(animated: true, completion: nil)
            detect(image: ciImage)
        }
    }
    
    func detect(image: CIImage) {
        guard let fcModel = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError(#function + ": Cannot import FlowerClassifier().model into VNCoreMLModel")
        }
        
        let request = VNCoreMLRequest(model: fcModel) { (vnRequest, error) in
            let classification = vnRequest.results?.first as? VNClassificationObservation
            self.navigationItem.title = classification?.identifier.capitalized
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        do {
            try handler.perform([request])
        } catch {
            fatalError(#function + ": VNImageRequestHandler couldn't perform VNCoreMLRequest \n Error: \(error)")
        }
    }
    
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
    
}

