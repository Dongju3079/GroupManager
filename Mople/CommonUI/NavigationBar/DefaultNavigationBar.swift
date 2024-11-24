//
//  CsutomNavigationBar.swift
//  Group
//
//  Created by CatSlave on 9/19/24.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

final class DefaultNavigationBar: UIView {
 
    enum ButtonType {
        case left
        case right
    }
    
    // MARK: - Variables
    var title: String? {
        didSet {
            titleLable.text = title
        }
    }
    
    // MARK: - Observable
    public var rightItemEvent: ControlEvent<Void> {
        return rightButton.rx.controlEvent(.touchUpInside)
    }
    
    public var leftItemEvent: ControlEvent<Void> {
        return leftButton.rx.controlEvent(.touchUpInside)
    }
    
    // MARK: - UI Components
    private let titleLable: UILabel = {
        let label = UILabel()
        label.font = FontStyle.Title2.bold
        label.textColor = ColorStyle.Gray._01
        label.textAlignment = .center
        return label
    }()
    
    private let rightButton: UIButton = {
        let btn = UIButton()
        btn.isHidden = true
        return btn
    }()

    private let leftButton: UIButton = {
        let btn = UIButton()
        btn.isHidden = true
        return btn
    }()
    
    private let rightButtonContainerView = UIView()
    
    private let leftButtonContainerView = UIView()
    
    private lazy var mainStackView: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [leftButtonContainerView, titleLable, rightButtonContainerView])
        sv.axis = .horizontal
        sv.distribution = .fill
        sv.alignment = .center
        return sv
    }()
    
    // MARK: - LifeCycle
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        addSubview(mainStackView)
        leftButtonContainerView.addSubview(leftButton)
        rightButtonContainerView.addSubview(rightButton)
        
        mainStackView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(20)
            make.verticalEdges.equalToSuperview()
        }
                
        leftButtonContainerView.snp.makeConstraints { make in
            make.width.equalTo(40)
        }
        
        rightButtonContainerView.snp.makeConstraints { make in
            make.width.equalTo(40)
        }
        
        leftButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        rightButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

// MARK: - Set Item
extension DefaultNavigationBar {
    
    public func setBarItem(type: ButtonType, image: UIImage) {
        switch type {
        case .left:
            leftButton.isHidden = false
            leftButton.setImage(image, for: .normal)
        case .right:
            rightButton.isHidden = false
            rightButton.setImage(image, for: .normal)
        }
    }

    public func hideBarItem(type: ButtonType, isHidden: Bool) {
        switch type {
        case .left:
            leftButton.isHidden = isHidden
        case .right:
            rightButton.isHidden = isHidden
        }
    }
}
