//
//  CalendarViewController.swift
//  Group
//
//  Created by CatSlave on 9/13/24.
//

import UIKit
import RxSwift
import RxCocoa
import RxRelay
import ReactorKit
import FSCalendar

enum ScopeType {
    case week
    case month
}

private enum ScopeUpdateType {
    case buttonTap
    case calendarScopeChange
}

final class CalendarViewController: UIViewController, View {
        
    typealias Reactor = CalendarViewReactor
    
    var disposeBag = DisposeBag()
    
    // MARK: - Variables
    private let currentCalendar = DateManager.calendar
    private var eventDateComponents: [DateComponents] = []
    
    // MARK: - Observable
    private let heightObserver: PublishRelay<CGFloat> = .init()
    private let scopeObserver: PublishRelay<ScopeType> = .init()
    private let pageObserver: PublishRelay<DateComponents> = .init()
    private let dateSelectionObserver: PublishRelay<DateComponents> = .init()
    private let focusDateInWeekObserver: PublishRelay<DateComponents> = .init()
    
    // MARK: - UI Components
    private let calendar: FSCalendar = {
        let calendar = FSCalendar()
        calendar.scrollDirection = .horizontal
        calendar.adjustsBoundingRectWhenChangingMonths = true
        calendar.placeholderType = .fillHeadTail
        calendar.headerHeight = 0
        calendar.rowHeight = 60
        calendar.collectionViewLayout.sectionInsets = .init(top: 5, left: 24, bottom: 5, right: 24)
        calendar.locale = Locale(identifier: "ko_KR")
        return calendar
    }()
    
    private let weekContainerView = UIView()
    
    // MARK: - LifeCycle
    init(reactor: CalendarViewReactor) {
        defer { self.reactor = reactor }
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setCalendar()
        setupUI()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        self.view.backgroundColor = AppDesign.defaultWihte
        self.view.addSubview(calendar)
        
        calendar.addSubview(weekContainerView)
        weekContainerView.addSubview(calendar.calendarWeekdayView)
        
        calendar.snp.makeConstraints { make in
            let calendarMaxHeight = calendar.weekdayHeight + (calendar.rowHeight * 6)
            make.top.horizontalEdges.equalToSuperview()
            make.height.equalTo(calendarMaxHeight)
        }
        
        weekContainerView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.horizontalEdges.equalToSuperview().inset(24)
            make.height.equalTo(36)
        }

        calendar.calendarWeekdayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func setCalendar() {
        setCalendarAppearance()
        calendar.delegate = self
        calendar.dataSource = self
        calendar.register(CustomCalendarCell.self, forCellReuseIdentifier: "CustomCell")
    }
    
    private func setCalendarAppearance() {
        calendar.appearance.weekdayTextColor = UIColor(hexCode: "999999")
        calendar.appearance.titleTodayColor = .black
        calendar.appearance.titleSelectionColor = .black
        calendar.appearance.todayColor = .clear
        calendar.appearance.selectionColor = .clear
        calendar.appearance.titleWeekendColor = .systemRed
    }
    
    // MARK: - Binding
    func bind(reactor: CalendarViewReactor) {
        inputBind(reactor)
        outputBind(reactor)
    }
    
    private func outputBind(_ reactor: Reactor) {
        heightObserver
            .observe(on: MainScheduler.instance)
            .map { Reactor.Action.calendarHeightChanged(height: $0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        scopeObserver
            .observe(on: MainScheduler.instance)
            .map { Reactor.Action.scopeChanged(scope: $0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        pageObserver
            .observe(on: MainScheduler.instance)
            .map { Reactor.Action.pageChanged(page: $0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        dateSelectionObserver
            .observe(on: MainScheduler.instance)
            .map { Reactor.Action.dateSelected(date: $0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        focusDateInWeekObserver
            .observe(on: MainScheduler.instance)
            .map { Reactor.Action.focusDateInWeekView(date: $0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
    
    private func inputBind(_ reactor: Reactor) {
        
        reactor.pulse(\.$switchScope)
            .skip(1)
            .observe(on: MainScheduler.instance)
            .subscribe(with: self, onNext: { vc, _ in
                vc.switchScope(updateType: .buttonTap)
            })
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$eventDates)
            .observe(on: MainScheduler.instance)
            .subscribe(with: self, onNext: { vc, events in
                vc.updateEvents(with: events)
            })
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$switchPage)
            .observe(on: MainScheduler.instance)
            .compactMap({ $0 })
            .subscribe(with: self, onNext: { vc, dateComponents in
                vc.moveToPage(dateComponents: dateComponents)
            })
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$tableViewDate)
            .observe(on: MainScheduler.instance)
            .debounce(.milliseconds(10), scheduler: MainScheduler.instance)
            .pairwise()
            .filter({ $0 != $1 })
            .compactMap({ Optional(tuple: $0) })
            .subscribe(with: self, onNext: { vc, datePair  in
                vc.moveToCurrentDate(datePair)
            })
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$focusDateInWeekView)
            .observe(on: MainScheduler.instance)
            .compactMap({ $0 })
            .subscribe(with: self, onNext: { vc, date in
                vc.dateSelectionObserver.accept(date)
                vc.moveToFoucsDate(date)
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - DataSource
extension CalendarViewController: FSCalendarDataSource {
    func calendar(_ calendar: FSCalendar, cellFor date: Date, at position: FSCalendarMonthPosition) -> FSCalendarCell {
        let cell = calendar.dequeueReusableCell(withIdentifier: "CustomCell", for: date, at: position) as! CustomCalendarCell
        cell.updateCell(containsEvent: checkContainsEvent(date),
                        isSelected: checkSelected(date),
                        isToday: checkToday(date))
        return cell
    }
}

// MARK: - Delegate
extension CalendarViewController: FSCalendarDelegate {
    
    func minimumDate(for calendar: FSCalendar) -> Date {
        var components = reactor!.todayComponents
        components.month = 1
        components.day = 1
        let date = DateManager.convertDate(components) ?? Date()
        return currentCalendar.date(byAdding: .year, value: -10, to: date) ?? Date()
    }

    func maximumDate(for calendar: FSCalendar) -> Date {
        var components = reactor!.todayComponents
        components.month = 12
        components.day = 31
        let date = DateManager.convertDate(components) ?? Date()
        return currentCalendar.date(byAdding: .year, value: 10, to: date) ?? Date()
    }
    
    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
        let updateComponents = DateManager.convertDateComponents(calendar.currentPage)
        pageObserver.accept(updateComponents)
    }
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        updateFocus(on: date, with: monthPosition)
        updateCell(date, isSelected: true)
    }
    
    func calendar(_ calendar: FSCalendar, didDeselect date: Date, at monthPosition: FSCalendarMonthPosition) {
        updateCell(date, isSelected: false)
    }
    
    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        let maxHeight = calendar.rowHeight * 6
        let currentScope: ScopeType = calendar.scope == .month ? .month : .week
        let resultHeight = calendar.scope == .month ? maxHeight : bounds.height
        self.scopeObserver.accept(currentScope)
        self.heightObserver.accept(resultHeight)
    }
}

// MARK: - 셀 선택 시 액션
extension CalendarViewController {
    
    private func updateFocus(on date: Date, with position: FSCalendarMonthPosition) {
        switch calendar.scope {
        case .month:
            changeMonth(on: date, with: position)
        case .week:
            notifySelectedDate(on: date)
        @unknown default:
            break
        }
    }
    
    private func changeMonth(on date: Date, with monthPosition: FSCalendarMonthPosition) {
        guard calendar.scope == .month else { return }
        switch monthPosition {
        case .current:
            switchScope(updateType: .calendarScopeChange)
        case .next, .previous:
            let dateComponents = DateManager.convertDateComponents(date)
            self.moveToPage(dateComponents: dateComponents, animated: true)
        default:
            break
        }
    }
    
    /// 스케줄 테이블 반영
    private func notifySelectedDate(on date: Date) {
        let date = DateManager.convertDateComponents(date)
        dateSelectionObserver.accept(date)
    }
}

// MARK: - 스코프 업데이트
extension CalendarViewController {
    /// scope에 맞춰서 표시할 데이터 동기화
    /// month : week에서 previous, current, next 날짜 클릭에 따라서 calenar가 맞는 날짜를 표시해줌
    private func switchScope(updateType: ScopeUpdateType) {
        switch calendar.scope {
        case .month:
            updateWhenMonthScope(updateType)
        case .week:
            updateWhenWeekScope()
        @unknown default:
            break
        }
    }
    
    /// 주간에서 월갑으로 변경할 때 DatePicker, MainHeaderLabel 반영을 위해서 pageObserver에 값 보내기
    private func updateWhenWeekScope() {
        calendar.setScope(.month, animated: true)
        pageObserver.accept(currentPageDate())
    }
    
    /// 월간에서 주간으로 변경될 때 표시할 값 계산
    private func updateWhenMonthScope(_ updateType: ScopeUpdateType) {
        switch updateType {
            case .buttonTap:
            let pageDate = currentPageFirstEventDate() ?? currentPageDate()
            focusDateInWeekObserver.accept(pageDate)
        case .calendarScopeChange:
            guard let selectedDate = selectedDate() else { return }
            focusDateInWeekObserver.accept(selectedDate)
        }
    }
}

// MARK: - 셀 업데이트
extension CalendarViewController {
    /// 이벤트 업데이트
    /// - Parameter dateComponents: 서버로부터 받아온 DateComponents
    private func updateEvents(with dateComponents: [DateComponents]) {
        self.eventDateComponents = dateComponents
        calendar.reloadData()
    }

    /// 선택 여부에 따라서 셀 컬러 변경
    /// - Parameters:
    ///   - date: 선택된 날짜
    ///   - isSelected: 선택된 셀 or 선택됐던 셀
    private func updateCell(_ date: Date, isSelected: Bool) {
        guard let cell = calendar.cell(for: date, at: .current) as? CustomCalendarCell else { return }
        cell.updateCell(containsEvent: checkContainsEvent(date),
                        isSelected: isSelected,
                        isToday: checkToday(date))
    }
    
    /// 일정이 있는 날인지 체크
    private func checkContainsEvent(_ date: Date) -> Bool {
        let dateComponent = DateManager.convertDateComponents(date)
        return eventDateComponents.contains { $0 == dateComponent }
    }
    
    /// 셀 그릴 때 선택된 셀 구분
    /// - Parameter date: 그릴려고 하는 날짜
    private func checkSelected(_ date: Date) -> Bool {
        guard let selectedDate = calendar.selectedDate else { return false }
        return selectedDate == date
    }
    
    /// 선택된 셀이 오늘인지 확인
    /// - Parameter date: 선택된 날짜
    private func checkToday(_ date: Date) -> Bool {
        let targetComponents = DateManager.convertDateComponents(date)
        return targetComponents == reactor!.todayComponents
    }
}

// MARK: - 특정 위치로 이동
extension CalendarViewController {
    private func moveToPage(dateComponents: DateComponents, animated: Bool = false) {
        guard let date = DateManager.convertDate(dateComponents) else { return }
        self.calendar.setCurrentPage(date, animated: animated)
    }
    
    private func moveToCurrentDate(_ datePair: (DateComponents, DateComponents)) {
        guard let previousDate = DateManager.convertDate(datePair.0),
              let currentDate = DateManager.convertDate(datePair.1) else { return }
        
        guard let focusDate = currentCalendar.date(from: datePair.1) else { return }
        calendar.select(focusDate, scrollToDate: false)
        
        if DateManager.isSameWeek(previousDate, currentDate) {
            calendar.reloadData()
        } else {
            moveToPage(dateComponents: datePair.1, animated: true)
        }
    }
    
    private func moveToFoucsDate(_ date: DateComponents) {
        guard let focusDate = DateManager.convertDate(date) else { return }
        calendar.select(focusDate, scrollToDate: false)
        calendar.setScope(.week, animated: true)
    }
    
    private func scrollToPage(direction: Int) {
        var currentPage = calendar.currentPage.getComponents()
        guard let month = currentPage.month else { return }
        currentPage.month = month + direction
        moveToPage(dateComponents: currentPage, animated: true)
    }
}

// MARK: - Helper
extension CalendarViewController {

//    /// 현재 캘린더 뷰에서 선택된 날짜가 있는지 체크
//    private func hasSelectedDateInCurrentView() -> Bool {
//        guard let selectedDate = calendar.selectedDate else { return false }
//        let activeDates = activeDates()
//        return activeDates.contains { $0 == selectedDate }
//    }
    
    /// 현재 달력에서 Active 상태인 [Date] 가져오기
    private func activeDates() -> [Date] {
        return calendar.visibleCells().compactMap { cell in
            calendar.date(for: cell).flatMap { date in
                return calendar.cell(for: date, at: .current) != nil ? date : nil
            }
        }
    }
    
    /// 선택된 날짜 Components
    private func selectedDate() -> DateComponents? {
        guard let selectedDate = calendar.selectedDate else { return nil }
        let components = DateManager.convertDateComponents(selectedDate)
        return components
    }
    
    /// 현재 페이지에서 첫번째 이벤트
    private func currentPageFirstEventDate() -> DateComponents? {
        let currentPageDetes = activeDates()
            .map { DateManager.convertDateComponents($0) }
        
        let currentEvents = eventDateComponents.filter { event in
            currentPageDetes.contains { $0 == event }
        }

        return currentEvents.first
    }
    
    /// 현재 달력의 첫번째 날짜
    private func currentPageDate() -> DateComponents {
        return calendar.currentPage.getComponents()
    }
}




