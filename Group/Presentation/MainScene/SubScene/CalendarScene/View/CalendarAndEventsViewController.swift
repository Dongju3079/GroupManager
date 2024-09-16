//
//  CalendarViewController.swift
//  Group
//
//  Created by CatSlave on 8/31/24.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class CalendarAndEventsViewController: BaseViewController {
    
//    var testObservable = obser
    
    var disposeBag = DisposeBag()
    
    private lazy var panGesture = UIPanGestureRecognizer(target: self.calendarView.calendar, action: #selector(self.calendarView.calendar.handleScopeGesture(_:)))
    
    private let calendarContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = AppDesign.mainBackColor
        return view
    }()
    
    private let calendarView: CalendarViewController = {
        let calendarView = CalendarViewController()
        calendarView.view.layer.cornerRadius = 16
        calendarView.view.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        return calendarView
    }()
    
    private let emptyView: UIView = {
        let view = UIView()
        view.backgroundColor = AppDesign.mainBackColor
        return view
    }()
    
    private let testBtn: UIButton = {
        let btn = UIButton()
        btn.setTitle("테스트", for: .normal)
        btn.backgroundColor = .green
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        addScheduleListCollectionView()
        addRightButton(setImage: UIImage(named: "Calendar")!)
        setAction()
        setupCalendarObserver()
        setGesture()
    }

    private func setupUI() {
        self.view.addSubview(calendarContainerView)
        self.view.addSubview(emptyView)
        
        let height = calendarView.calendarMaxHeight
        
        calendarContainerView.snp.makeConstraints { make in
            make.top.equalTo(titleViewBottom)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(height)
        }
        
        emptyView.snp.makeConstraints { make in
            make.top.equalTo(calendarContainerView.snp.bottom)
            make.horizontalEdges.bottom.equalToSuperview()
        }
    }
    
    private func addScheduleListCollectionView() {
        addChild(calendarView)
        calendarContainerView.addSubview(calendarView.view)
        calendarView.didMove(toParent: self)
        calendarView.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func setupCalendarObserver() {
        self.calendarView.heightObservable
            .skip(1)
            .subscribe(with: self, onNext: { vc, height in
                vc.updateCalendarView(height)
            })
            .disposed(by: disposeBag)
    }
    
    private func updateCalendarView(_ height: CGFloat) {
        UIView.animate(withDuration: 0.33) {
            self.calendarContainerView.snp.updateConstraints { make in
                make.height.equalTo(height)
            }
            self.view.layoutIfNeeded()
        }
    }

    private func setAction() {
        self.rightButton.rx.controlEvent(.touchUpInside)
            .subscribe(with: self, onNext: { vc, _ in
                vc.calendarView.changeScope()
            })
            .disposed(by: disposeBag)
    }
    
    #warning("제스처 방식 기록 필요")
    private func setGesture() {
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 2
        panGesture.delegate = self
        self.view.addGestureRecognizer(panGesture)
    }
}

extension CalendarAndEventsViewController: UIGestureRecognizerDelegate {
    // 구현하지 않아도 제스처는 정상 동작, 하단 테이블뷰의 위치에 따라서 조건을 추가할것이라면 아래 메서드 사용해야함
//    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
//        let shouldBegin = self.tableView.contentOffset.y <= -self.tableView.contentInset.top
//        if shouldBegin {
//            let velocity = self.panGesture.velocity(in: self.view)
//            switch self.calendarView.calendar.scope {
//            case .month:
//                return velocity.y < 0
//            case .week:
//                return velocity.y > 0
//            }
//        }
//        return shouldBegin
//    }
}

//#if canImport(SwiftUI) && DEBUG
//import SwiftUI
//
//@available(iOS 13, *)
//struct CalendarAndEventsViewController_Preview: PreviewProvider {
//    static var previews: some View {
//        CalendarAndEventsViewController(title: "일정관리").showPreview()
//    }
//}
//#endif


