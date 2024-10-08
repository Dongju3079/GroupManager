//
//  DefaultLabel.swift
//  Group
//
//  Created by CatSlave on 8/20/24.
//

import UIKit

class BaseLabel: UILabel {
    
    var isOverlapCheck: Bool = false {
        didSet {
            let color: UIColor = isOverlapCheck ? .init(hexCode: "FF3B30") : .clear
            textColor = color
        }
    }
    
    private var padding: UIEdgeInsets
    
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: padding))
    }
    
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + padding.left + padding.right,
                      height: size.height + padding.bottom + padding.top)
    }
    
    init(backColor: UIColor? = nil,
         radius: CGFloat? = nil,
         padding: UIEdgeInsets = .zero,
         configure: UIConstructive? = nil) {
        self.padding = padding
        super.init(frame: .zero)
        
        setType(configure: configure)
        setBackground(color: backColor, radius: radius)
    }
    
    required init?(coder: NSCoder) {
        self.padding = .zero
        super.init(coder: coder)
    }
    
    public func setType(configure: UIConstructive?) {
        text = configure?.itemConfig.text
        font = configure?.itemConfig.font
        textColor = configure?.itemConfig.color
    }
}

// MARK: - 배경 적용하기
extension BaseLabel {
    func setBackground(color: UIColor?, radius: CGFloat?) {
        self.backgroundColor = color ?? .clear
        self.clipsToBounds = true
        self.layer.cornerRadius = radius ?? 0
    }
}

