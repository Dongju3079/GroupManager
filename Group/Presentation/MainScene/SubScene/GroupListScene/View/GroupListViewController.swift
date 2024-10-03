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

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = AppDesign.mainBackColor
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var groupListTableView = GroupListTableViewController(reactor: reactor!)
    
    private let borderView: UIView = {
        let view = UIView()
        view.layer.makeLine(width: 1)
        
        return view
    }()
    
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

    func setupUI() {
        self.view.addSubview(containerView)
        self.view.addSubview(borderView)
        
        self.containerView.addSubview(emptyView)

        containerView.snp.makeConstraints { make in
            make.top.equalTo(titleViewBottom)
            make.bottom.horizontalEdges.equalToSuperview()
        }
        
        emptyView.snp.makeConstraints { make in
            make.center.equalTo(self.view)
        }
        
        borderView.snp.makeConstraints { make in
            make.top.equalTo(titleViewBottom)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(1)
        }
    }
    
    private func addScheduleListCollectionView() {
        addChild(groupListTableView)
        containerView.addSubview(groupListTableView.view)
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
                vc.groupListTableView.view.isHidden = groupList.isEmpty
            })
            .disposed(by: disposeBag)
    }
}





