//
//  ViewController.swift
//  WhatFlower
//
//  Created by Denis Aleksandrov on 11/23/20.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    let imagePicker = UIImagePickerController()
    @IBOutlet weak var descriptionLabel: UILabel!
    
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
            
            // Using imageView.sd_setImage(with: URL) inside requestInfoFromWikipedia(flowerName:) instead of
            //imageView.image = userPickedImage
            
            imagePicker.dismiss(animated: true, completion: nil)
            detect(image: ciImage)
        }
    }
    
    func detect(image: CIImage) {
        guard let fcModel = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError(#function + ": Cannot import FlowerClassifier().model into VNCoreMLModel")
        }
        
        let request = VNCoreMLRequest(model: fcModel) { (vnRequest, error) in
            guard let classification = vnRequest.results?.first as? VNClassificationObservation else {
                fatalError(#function + ": Could not classify image.")
            }
            self.navigationItem.title = classification.identifier.capitalized
            self.requestInfoFromWikipedia(flowerName: classification.identifier)
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
    
    func requestInfoFromWikipedia(flowerName: String) {
        let wikiParameters : [String:String] = [
            "format":       "json",
            "action":       "query",
            "prop":         "extracts|pageimages",
            "exintro":      "",
            "explaintext":  "",
            "titles":       flowerName,
            "indexpageids": "",
            "redirects":    "1",
            "pithumbsize":  "500"
        ]
        
        Alamofire.request(wikipediaURl, method: .get, parameters: wikiParameters).responseJSON { (response) in
            if response.result.isSuccess {
                print(#function + ": \(response)")
                let flowerJSON: JSON = JSON(response.result.value!)
                let pageID = flowerJSON["query"]["pageids"][0].stringValue
                let flowerDescription = flowerJSON["query"]["pages"][pageID]["extract"].stringValue
                self.descriptionLabel.text = flowerDescription
                let flowerImageURL = flowerJSON["query"]["pages"][pageID]["thumbnail"]["source"].stringValue
                self.imageView.sd_setImage(with: URL(string: flowerImageURL))
            }
        }
    }
    
}

