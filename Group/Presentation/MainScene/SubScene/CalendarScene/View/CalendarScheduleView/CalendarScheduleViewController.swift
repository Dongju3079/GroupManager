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
import ReactorKit

final class CalendarScheduleViewController: BaseViewController, View {
    
    typealias Reactor = CalendarViewReactor
    
    var disposeBag = DisposeBag()
    
    // MARK: - Variables
    private let currentCalendar = DateManager.calendar
    private lazy var todayComponents = {
        var components = Date().getComponents()
        return components
    }()
    
    // MARK: - Observer
    private let scopeObserver: PublishSubject<Void> = .init()
    private let presentNextEvent: BehaviorRelay<Date?> = .init(value: nil)
    
    #warning("reactor외의 용도로 만드는 이유")
    // reactor는 제스처 업데이트와 같이 짧은 시간에 많은 값이 들어가는 경우 재진입 이슈 발생
    private let gestureObserver: PublishSubject<UIPanGestureRecognizer> = .init()
        
    // MARK: - UI Components
    private let headerContainerView: UIButton = {
        let btn = UIButton()
        btn.backgroundColor = AppDesign.Calendar.headerColor
        btn.clipsToBounds = true
        btn.layer.cornerRadius = 10
        return btn
    }()
    
    private let headerLabel: IconLabelView = {
        let label = IconLabelView(iconSize: 24,
                                  configure: AppDesign.Calendar.header,
                                  iconAligment: .right)
        label.isUserInteractionEnabled = false
        
        return label
    }()
    
    // 캘린더
    private let calendarContainer = UIView()
    
    private lazy var calendarView: CalendarViewController = {
        let calendarView = CalendarViewController(reactor: reactor!,
                                                  gestureObserver: gestureObserver)
        
        calendarView.view.layer.cornerRadius = 16
        calendarView.view.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        return calendarView
    }()
    
    // 스케쥴 리스트 테이블 뷰
    private let scheduleListContainer = UIView()
    
    private lazy var scheduleListTableView: ScheduleTableViewController = {
        
        let scheduleListTableView = ScheduleTableViewController(reactor: reactor!)
        return scheduleListTableView
    }()
    
    // 구분선
    private let borderView = UIView()
    
    // MARK: - Gesture
    private lazy var scopeGesture: UIPanGestureRecognizer = {
        [unowned self] in
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleScopeGesture(_:)))
        panGesture.delegate = self
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 2
        return panGesture
    }()
    
    // MARK: - LifeCycle
    init(title: String,
         reactor: CalendarViewReactor) {
        super.init(title: title)
        self.reactor = reactor
    }
     
     required init?(coder: NSCoder) {
         fatalError("init(coder:) has not been implemented")
     }
     
     override func viewDidLoad() {
         print(#function, #line)
         super.viewDidLoad()
         setupUI()
         setAction()
         setGesture()
     }
    
    override func viewWillDisappear(_ animated: Bool) {
        print(#function, #line)
        super.viewWillDisappear(animated)
        resetPresentDate()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        setupNavi()
        setLayout()
        setContainer()
        setHeaderDate()
    }
    
    private func setupNavi() {
        addRightButton(setImage: .calendar)
        addLeftButton(setImage: .close)
        hideLeftButton(isHidden: true)
    }
    
    private func setLayout() {
        self.view.addSubview(headerContainerView)
        self.view.addSubview(calendarContainer)
        self.view.addSubview(scheduleListContainer)
        self.view.addSubview(borderView)
                
        headerContainerView.addSubview(headerLabel)
        
        headerContainerView.snp.makeConstraints { make in
            make.top.equalTo(titleViewBottom)
            make.horizontalEdges.equalToSuperview().inset(24)
            make.height.equalTo(56)
        }
        
        headerLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        calendarContainer.snp.makeConstraints { make in
            make.top.equalTo(headerContainerView.snp.bottom).offset(16)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(360) 
        }
        
        borderView.snp.makeConstraints { make in
            make.top.equalTo(calendarContainer.snp.bottom)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(1)
        }
        
        scheduleListContainer.snp.makeConstraints { make in
            make.top.equalTo(borderView.snp.bottom)
            make.horizontalEdges.bottom.equalToSuperview()
        }
    }
    
    private func setContainer() {
        addCalendarView()
        addScheduleListView()
    }
    
    private func addCalendarView() {
        addChild(calendarView)
        calendarContainer.addSubview(calendarView.view)
        calendarView.didMove(toParent: self)
        calendarView.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func addScheduleListView() {
        addChild(scheduleListTableView)
        scheduleListContainer.addSubview(scheduleListTableView.view)
        scheduleListTableView.didMove(toParent: self)
        scheduleListTableView.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func setHeaderDate() {
        let today = reactor!.todayComponents
        setHeaderLabel(date: today)
    }
    
    // MARK: - Binding
    func bind(reactor: CalendarViewReactor) {
        inputBind(reactor)
        outputBind(reactor)
    }
    
    private func inputBind(_ reactor: Reactor) {
        reactor.pulse(\.$calendarHeight)
            .compactMap({ $0 })
            .observe(on: MainScheduler.instance)
            .subscribe(with: self, onNext: { vc, height in
                vc.updateCalendarView(height)
            })
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$scope)
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .subscribe(with: self, onNext: { vc, scope in
                vc.updateMainView(scope)
            })
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$changedPage)
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .subscribe(with: self, onNext: { vc, date in
                vc.setHeaderLabel(date: date)
            })
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$isLoading)
            .observe(on: MainScheduler.instance)
            .subscribe(with: self, onNext: { vc, isLoading in
                vc.animationIndicator(isLoading)
                vc.checkIsPresent(isLoading)
            })
            .disposed(by: disposeBag)
    }
    
    private func outputBind(_ reactor: Reactor) {
        
        self.scopeObserver
            .debounce(.milliseconds(100), scheduler: MainScheduler.instance)
            .observe(on: MainScheduler.instance)
            .map { Reactor.Action.requestScopeSwitch(type: .gesture) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        self.rightButtonObservable
            .observe(on: MainScheduler.instance)
            .map { Reactor.Action.requestScopeSwitch(type: .tap) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        self.leftButtonObservable
            .observe(on: MainScheduler.instance)
            .map { Reactor.Action.requestScopeSwitch(type: .tap) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        self.presentNextEvent
            .observe(on: MainScheduler.instance)
            .compactMap({ $0 })
            .map { Reactor.Action.requestNextEvent(lastRecentDate: $0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
    
    // MARK: - Action
    private func setAction() {
        headerContainerView.rx.controlEvent(.touchUpInside)
            .subscribe(with: self, onNext: { vc, _ in
                vc.presentDatePicker()
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Gesture Setup
    @objc private func handleScopeGesture(_ gesture: UIPanGestureRecognizer) {
        self.scopeObserver.onNext(())
        self.gestureObserver.onNext(gesture)
    }
    
    private func setGesture() {
        self.view.addGestureRecognizer(scopeGesture)
        self.scheduleListTableView.panGestureRequire(scopeGesture)
    }
}

extension CalendarScheduleViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let tableTop = scheduleListTableView.checkTop()
        let monthScope = reactor!.currentState.scope == .month
        print(#function, #line, "currentState Scope : \(reactor!.currentState.scope), or top : \(tableTop)" )
        let shouldBegin = tableTop || monthScope
        if shouldBegin {
            return shouldAllowScopeChangeGesture()
        }
        return shouldBegin
    }
    
    /// 스코프의 상태와 제스처의 방향에 따라서 스코프 변경여부 결정
    private func shouldAllowScopeChangeGesture() -> Bool {
        guard let scope = reactor!.currentState.scope else { return false }
        let velocity = self.scopeGesture.velocity(in: self.view)
        switch scope {
        case .month:
            return velocity.y < 0
        case .week:
            return velocity.y > 0
        }
    }
}

// MARK: - Date Picker
extension CalendarScheduleViewController {
    private func presentDatePicker() {
        let datePickView = DatePickViewController(reactor: reactor!)
        
        datePickView.modalPresentationStyle = .pageSheet
        
        if let sheet = datePickView.sheetPresentationController {
            sheet.detents = [ .medium() ]
        }
        
        self.present(datePickView, animated: true)
    }
}

// MARK: - UI Update
extension CalendarScheduleViewController {
    private func updateCalendarView(_ height: CGFloat) {
        UIView.animate(withDuration: 0.33) {
            self.calendarContainer.snp.updateConstraints { make in
                make.height.equalTo(height)
            }
            
            self.view.layoutIfNeeded()
        }
    }
    
    private func updateMainView(_ scope: ScopeType) {
        UIView.animate(withDuration: 0.33) {
            self.updateHeaderView(scope: scope)
            self.updateBackgroundColor(scope: scope)
            self.naviItemChange(scope: scope)
            self.hideScheduleListTableView(scope: scope)
            self.view.layoutIfNeeded()
        }
    }
    
    private func updateHeaderView(scope: ScopeType) {
        let height = scope == .month ? 56 : 0
        
        self.headerContainerView.snp.updateConstraints { make in
            make.height.equalTo(height)
        }
    }
    
    private func hideScheduleListTableView(scope: ScopeType) {
        scheduleListTableView.hideView(isHide: scope == .month)
    }
    
    #warning("참고")
    // 애니메이션 중에는 유저 액션이 차단되는데 이를 허용할 수 있는 옵션이 존재
    private func updateBackgroundColor(scope: ScopeType) {
        let views: [UIView] = [self.calendarContainer, self.scheduleListContainer, self.borderView]
        
        views.forEach {
            let color = scope == .month ? AppDesign.defaultWihte : AppDesign.mainBackColor
            $0.backgroundColor = color
        }
    }
    
    private func naviItemChange(scope: ScopeType) {
        let isScopeMonth = scope == .month
        
        hideRightButton(isHidden: !isScopeMonth)
        hideLeftButton(isHidden: isScopeMonth)
    }
    
    private func setHeaderLabel(date: DateComponents) {
        let year = date.year ?? 2024
        let monty = date.month ?? 1
        
        headerLabel.setText("\(year)년 \(monty)월")
    }
}

// MARK: - Home View에서 넘어왔을 때의 액션
extension CalendarScheduleViewController {
    
    /// 표시할 데이터가 있는 상태 : 홈뷰에서 표시한 이벤트 갯수 넘기기
    public func presentNextEvent(on lastRecentDate: Date) {
        self.presentNextEvent.accept(lastRecentDate)
    }
    
    /// 표시할 데이터가 없는 상태 : 로딩이 끝난 후 presentNextEvent count 다시 보내주기
    private func checkIsPresent(_ isLoading: Bool) {
        guard !isLoading,
              let recentEventCount = presentNextEvent.value else { return }
        presentNextEvent.accept(recentEventCount)
    }
    
    private func resetPresentDate() {
        guard presentNextEvent.value == nil else { return }
        presentNextEvent.accept(nil)
    }
}





