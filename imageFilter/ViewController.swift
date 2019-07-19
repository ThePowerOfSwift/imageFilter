//
//  ViewController.swift
//  imageFilter
//
//  Created by Irving Huang on 2019/6/28.
//  Copyright © 2019 Irving Huang. All rights reserved.
//

import UIKit
import Metal
import MetalKit

let fileName = "2.jpg"

class ViewController: UIViewController {

    @IBOutlet weak var vImage: UIImageView!
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        
        ///目前只能吃jpg的圖片，png之類的檔案可能會掛掉
        let image = UIImage(named: fileName)!
        let imageResult = image.convertToBW()
        vImage.image = imageResult
        imageResult?.saveToDisk()
    }
}

extension UIImage {
    func saveToDisk() {
        let manager = FileManager.default
        let urlForDocument = manager.urls(for: .documentDirectory, in:.userDomainMask)
        let url = urlForDocument[0] as URL
        print(url.path)

        let data = self.jpegData(compressionQuality: 1.0)

        let path = url.path + "/Mod_" + fileName
        let createSuccess = manager.createFile(atPath: path ,contents:data,attributes:nil)
        print("檔案建立結果: \(createSuccess)")
    }
    
    func convertToBW() -> UIImage? {
        
        ///進行遮罩把不算太黑的顏色都蓋成透明
        let imageWithoutBrown = masklightToMidRangeBrown(inputImage: self)!
//        return imageWithoutBrown
        
        ///進行對比等等的調整使其只剩下黑白兩色
        if let imageConvertBlackWhite = getScannedImage(inputImage: imageWithoutBrown) {
            return imageConvertBlackWhite
        }

        return self
    }
    
    private func masklightToMidRangeBrown(inputImage: UIImage) -> UIImage? {
        let myColorMaskedImage = inputImage.cgImage?.copy(maskingColorComponents: [100, 180,  100, 180, 20, 180])!  //[100, 180,  100, 180, 20, 180] //[124, 255,  68, 222, 0, 165]
        let context = CIContext()
        let temp = convertCGImageToCIImage(cgImage: myColorMaskedImage!)
        if let cgimg = context.createCGImage(temp, from: temp.extent) {
            return UIImage(cgImage: cgimg)
        }
        return nil
    }
    
    private func convertCGImageToCIImage(cgImage:CGImage) -> CIImage{
        return CIImage.init(cgImage: cgImage)
    }
    
    private func getScannedImage(inputImage: UIImage) -> UIImage? {
        

        let context: CIContext
        
        /// metal only can be used on REAL device
        if let device = MTLCreateSystemDefaultDevice() {
            context = CIContext(mtlDevice: device)
        }
        else {
            context = CIContext()
        }
        
        let filter = CIFilter(name: "CIColorControls")
        let coreImage = CIImage(image: inputImage)
        
        filter?.setValue(coreImage, forKey: kCIInputImageKey)
        //Key value are changable according to your need.

        filter?.setValue(7, forKey: kCIInputContrastKey)
        filter?.setValue(0, forKey: kCIInputSaturationKey)
        filter?.setValue(1.2, forKey: kCIInputBrightnessKey)
        
        
        if let outputImage = filter?.value(forKey: kCIOutputImageKey) as? CIImage {
            let output = context.createCGImage(outputImage, from: outputImage.extent)
            return UIImage(cgImage: output!)
        }
        return nil
    }
    
}
/*主要參考資料
 https://stackoverflow.com/questions/46397367/how-to-adjust-a-color-image-like-a-scanned-image
 https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/dq_images/dq_images.html#//apple_ref/doc/uid/TP30001066-CH212-CJBJCJCE
*/
/*其他參考資料
http://www.hangge.com/blog/cache/detail_1496.html
http://landcareweb.com/questions/17766/ru-he-zai-uiimageshang-shi-yi-chong-yan-se-tou-ming
*/
