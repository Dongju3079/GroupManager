//
//  BaseViewController.swift
//  Group
//
//  Created by CatSlave on 9/9/24.
//

import UIKit
import SnapKit

class BaseViewController: UIViewController {
    
    private let titleLable: BaseLabel = {
        let label = BaseLabel(configure: AppDesign.Main.NaviView)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var mainStackView: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [titleLable])
        sv.axis = .horizontal
        sv.distribution = .fill
        sv.alignment = .fill
        return sv
    }()
    
    public let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = AppDesign.mainBackColor
        view.clipsToBounds = true
        return view
    }()

    init(title: String?) {
        super.init(nibName: nil, bundle: nil)
        self.titleLable.setText(text: title)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.view.backgroundColor = .white
        self.view.addSubview(mainStackView)
        self.view.addSubview(contentView)
        
        mainStackView.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(self.view.safeAreaLayoutGuide)
            make.height.equalTo(56)
        }
        
        contentView.snp.makeConstraints { make in
            make.top.equalTo(mainStackView.snp.bottom)
            make.horizontalEdges.bottom.equalToSuperview()
        }
    }
}