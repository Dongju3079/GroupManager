//
//  DynamicDatePickerView.swift
//  Mople
//
//  Created by CatSlave on 12/7/24.
//

import UIKit

final class DynamicDatePickerView: DefaultPickerView {
        
    // MARK: - Variables
    private let today = DateManager.today
    private let todayComponents = DateManager.todayComponents
    public lazy var selectedDate = todayComponents
    
    private lazy var years: [Int] = []
    
    private lazy var months: [Int] = []
    
    private lazy var dates: [Int] = []
    
    // MARK: - LifeCycle
    override init(title: String?) {
        print(#function, #line, "LifeCycle Test DatePickerView Created" )
        super.init(title: title)
        initialSetup()
    }
    
    deinit {
        print(#function, #line, "LifeCycle Test DatePickerView Created" )
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initialSetup() {
        self.setDelegate(delegate: self)
        self.defaultDateSeting(on: today)
    }
}

// MARK: - 기본 날짜 값 설정
extension DynamicDatePickerView {
    
    /// date로 값으로 피커뷰 Row를 설정
    private func defaultDateSeting(on date: Date) {
        settingYears()
        settingMonths(on: date)
        settingDates(on: date)
    }
    
    /// 현재 년부터 10년뒤까지만 표시
    private func settingYears() {
        let startYear = todayComponents.year ?? 2025
        let endYear = startYear + 10
        years = Array(startYear...endYear)
    }
    
    /// 현재 월로부터 12월까지 표시
    private func settingMonths(on date: Date) {
        let toCompoents = DateManager.toDateComponents(date)
        months = Array((toCompoents.month ?? 1)...12)
    }
    
    /// 현재 일로부터 마지막날까지 표시
    private func settingDates(on date: Date) {
        let dateComponents = DateManager.toDateComponents(date)
        let daysCountOfMonth = DateManager.getDaysCountInCurrentMonth(on: dateComponents)
        let toCompoents = DateManager.toDateComponents(date)
        dates = Array((toCompoents.day ?? 1)...daysCountOfMonth)
    }
}

// MARK: - 선택 값 업데이트
extension DynamicDatePickerView {
    
    /// 선택할 값 셋팅
    public func setSelectedDate(on dateComponents: DateComponents? = nil) {
        self.selectDate(dateComponents ?? selectedDate)
    }
    
    /// 들어온 값이 있는 날짜인지 체크 후 Row 변경
    private func selectDate(_ dateComponents: DateComponents) {
        let dateIndex = getDateIndex(on: dateComponents)
        
        updateSelectedDate(yearIndex: dateIndex.year,
                        monthIndex: dateIndex.month,
                        dayIndex: dateIndex.day)
        
        setRow(yearIndex: dateIndex.year,
               monthIndex: dateIndex.month,
               dayIndex: dateIndex.day)
    }
    
    /// 들어온 값이 선택할 수 있는 값인지 체크 후 Index return
    private func getDateIndex(on dateComponents: DateComponents) -> (year: Int, month: Int, day: Int) {
        guard let year = dateComponents.year,
              let month = dateComponents.month,
              let day = dateComponents.day else { return (0, 0, 0)}
        
        let yearIndex = self.years.firstIndex(of: year) ?? 0
        let monthIndex = self.months.firstIndex(of: month) ?? 0
        let dateIndex = self.dates.firstIndex(of: day) ?? 0
        
        return (yearIndex, monthIndex, dateIndex)
    }
    
    /// Index를 받아서 업데이트
    private func updateSelectedDate(yearIndex: Int, monthIndex: Int, dayIndex: Int) {
        selectedDate.year = years[safe: yearIndex]
        selectedDate.month = months[safe: monthIndex]
        selectedDate.day = dates[safe: dayIndex]
    }
    
    /// 업데이트된 날짜에 마지막 날짜를 계산 후 selectedDate 업데이트
    private func updateSelectedDay() {
        let daysCountOfMonth = DateManager.getDaysCountInCurrentMonth(on: selectedDate)
        self.dates = Array(1...daysCountOfMonth)
        
        if !self.dates.contains(where: { $0 == self.selectedDate.day }) {
            self.selectedDate.day = self.dates.last
        }
    }
    
    /// 피커뷰에서 과거날짜는 보여주지 않기에 과거 날짜인 경우 교정 (월 기준)
    private func isValidFutureDate() -> Bool {
        let date = DateManager.toDate(selectedDate) ?? today
        let months = DateManager.numberOfMonthBetween(date)
        if months < 0 {
            selectedDate.year = todayComponents.year
            selectedDate.month = todayComponents.month
        }
        return months > 0
    }
    
    /// 년도 피커 조작 시 년도 아래로 업데이트
    private func updateMonth(isFuture: Bool) {
        let isCurrentYear = todayComponents.year == selectedDate.year
        self.months = !isCurrentYear && isFuture ? Array(1...12) : Array((todayComponents.month ?? 1)...12)
        updateDay(isFuture: isFuture)
    }
    
    /// 월 피커 조작 시 월 아래로 업데이트
    private func updateDay(isFuture: Bool) {
        guard !isFuture else { return }
        dates.removeAll { $0 < self.todayComponents.day ?? 1 }
    }
}

// MARK: - 피커뷰 업데이트
extension DynamicDatePickerView {
    
    enum ReloadRange {
        case month
        case day
    }
    
    /// 범위에 맞춰서 피커뷰 리로드
    private func reloadComponents(range: ReloadRange) {
        if case range = .month {
            self.pickerView.reloadComponent(1)
        }
        self.pickerView.reloadComponent(2)
        setSelectedDate()
    }
    
    /// 로우 업데이트
    private func setRow(yearIndex: Int, monthIndex: Int, dayIndex: Int) {
        self.selectRow(row: yearIndex, inComponent: 0, animated: false)
        self.selectRow(row: monthIndex, inComponent: 1, animated: false)
        self.selectRow(row: dayIndex, inComponent: 2, animated: false)
    }
    
    /// 년도 피커뷰 조작 시 날짜 유효성을 거친 후 업데이트
    private func moveToYearComponents(on selectedYear: Int) {
        selectedDate.year = selectedYear
        let isFuture = self.isValidFutureDate()
        updateSelectedDay()
        updateMonth(isFuture: isFuture)
        reloadComponents(range: .month)
    }
    
    /// 월 피커뷰 조작 시 날짜 유효성을 거친 후 업데이트
    private func moveToMonthComponents(on selectedMonth: Int) {
        selectedDate.month = selectedMonth
        let isFuture = self.isValidFutureDate()
        updateSelectedDay()
        updateDay(isFuture: isFuture)
        reloadComponents(range: .day)
    }
}

// MARK: - Delegate
extension DynamicDatePickerView: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 3
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch component {
        case 0: years.count
        case 1: months.count
        case 2: dates.count
        default: 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int,
                    reusing view: UIView?) -> UIView {
        
        let label = self.dequeuePickerLabel(reusing: view)
        
        switch component {
        case 0: label.text = "\(years[row]) 년"
        case 1: label.text = "\(months[row]) 월"
        case 2: label.text = "\(dates[row]) 일"
        default: break
        }
        
        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch component {
        case 0:
            let selectedYear = years[row]
            guard selectedYear != self.selectedDate.year else { return }
            self.moveToYearComponents(on: selectedYear)
        case 1:
            let selectedMonth = months[row]
            guard selectedMonth != self.selectedDate.month else { return }
            self.moveToMonthComponents(on: selectedMonth)
        case 2:
            self.selectedDate.day = dates[row]
        default:
            break
        }
        
        print(#function, #line, "Path : # 1209 : \(selectedDate) ")
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 35
    }
}
