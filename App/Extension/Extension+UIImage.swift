//
//  Extension+UIImage.swift
//  karashiru
//
//  Created by akidon0000 on 2024/10/04.
//

import UIKit

extension UIImage {
    func rotatedBy(degree: CGFloat) -> UIImage {
        let w = self.size.width
        let h = self.size.height
        
        //写し先を準備
        let s = CGSize(width: h, height: w)
        UIGraphicsBeginImageContext(s)
        let context = UIGraphicsGetCurrentContext()!
        //中心点
        context.translateBy(x: h / 2, y: w / 2)
        context.scaleBy(x: -1.0, y: 1.0)  // X軸方向に反転
        //Y軸を反転させる
        context.scaleBy(x: 1.0, y: -1.0)
        
        //回転させる
        let radian = -degree * CGFloat.pi / 180
        context.rotate(by: radian)
        
        //書き込み
        let rect = CGRect(x: -(h / 2), y: -(w / 2), width: h, height: w)
        context.draw(self.cgImage!, in: rect)
        
        let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return rotatedImage
    }
}
