//
//  GroupViewController.swift
//  Group
//
//  Created by CatSlave on 8/31/24.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import ReactorKit

class GroupListViewController: BaseViewController, View {
    
    typealias Reactor = GroupListViewReactor
    
    var disposeBag = DisposeBag()

    private let emptyView: BaseEmptyView = {
        let view = BaseEmptyView(configure: AppDesign.Group.empty)
        return view
    }()
    
    private let maskingView: UIView = {
        let view = UIView()
        view.backgroundColor = AppDesign.mainBackColor
        return view
    }()
    
    private let tableContainerView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var groupListTableView = GroupListTableViewController(reactor: reactor!)
    
    init(title: String?,
         reactor: GroupListViewReactor) {
        super.init(title: title)
        self.reactor = reactor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        addScheduleListCollectionView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.maskingView.addMasking()
    }
    
    func setupUI() {
        self.view.addSubview(tableContainerView)
        self.view.addSubview(emptyView)
        self.view.addSubview(maskingView)

        maskingView.snp.makeConstraints { make in
            make.top.equalTo(titleViewBottom)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(15)
        }

        tableContainerView.snp.makeConstraints { make in
            make.top.equalTo(titleViewBottom)
            make.bottom.horizontalEdges.equalToSuperview()
        }
        
        emptyView.snp.makeConstraints { make in
            make.center.equalTo(self.view)
        }
    }
    
    private func addScheduleListCollectionView() {
        addChild(groupListTableView)
        tableContainerView.addSubview(groupListTableView.view)
        groupListTableView.didMove(toParent: self)
        groupListTableView.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func bind(reactor: GroupListViewReactor) {
        reactor.pulse(\.$groupList)
            .asDriver(onErrorJustReturn: [])
            .drive(with: self, onNext: { vc, groupList in
                vc.emptyView.isHidden = !groupList.isEmpty
                vc.tableContainerView.isHidden = groupList.isEmpty
            })
            .disposed(by: disposeBag)
    }
}

extension UIView {
    func addMasking() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            AppDesign.mainBackColor.cgColor,
            UIColor.clear.cgColor
        ]

        gradientLayer.frame = self.bounds
        
        self.layer.mask = gradientLayer
    }
}
