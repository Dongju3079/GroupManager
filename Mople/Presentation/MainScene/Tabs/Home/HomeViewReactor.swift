//
//  ScheduleViewModel.swift
//  Group
//
//  Created by CatSlave on 9/3/24.
//

import UIKit
import ReactorKit

struct HomeViewAction {
    var presentCreateGroupView: (((() -> Void)?) -> Void)
    var presentCalendarView: (Date) -> Void
}

final class HomeViewReactor: Reactor {
    enum Action {
        case checkNotificationPermission
        case fetchRecentSchedule
        case createGroup
        case presentCalendaer
    }
    
    enum Mutation {
        case fetchRecentScehdule(schedules: [SimpleSchedule])
        case presentCalendar(date: Date)
        case presentCreateGroupView(completedAction: (() -> Void)?)
    }
    
    struct State {
        @Pulse var schedules: [SimpleSchedule] = []
        @Pulse var presentCompleted: Void?
    }
    
    private let fetchRecentScheduleImpl: FetchRecentSchedule
    private let homeViewAction: HomeViewAction
    
    var initialState: State = State()
    
    init(fetchRecentSchedule: FetchRecentSchedule,
         viewAction: HomeViewAction) {
        self.fetchRecentScheduleImpl = fetchRecentSchedule
        self.homeViewAction = viewAction
        action.onNext(.fetchRecentSchedule)
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .fetchRecentSchedule:
            fetchRecentSchedules()
        case .createGroup:
            presentCreateGroupView()
        case .presentCalendaer:
            presentNextEvent()
        case .checkNotificationPermission:
            checkNotificationPermission()
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        
        var newState = state
        
        switch mutation {
        case .fetchRecentScehdule(let schedules):
            newState.schedules = schedules.sorted(by: <)
        case .presentCalendar(let date):
            homeViewAction.presentCalendarView(date)
        case .presentCreateGroupView(let completedAction):
            homeViewAction.presentCreateGroupView(completedAction)
        }
        return newState
    }
    
    func handleError(state: State, err: Error) -> State {
        let newState = state
        
        // 에러 처리
        
        return newState
    }
}
    

extension HomeViewReactor {
    
    private func checkNotificationPermission() -> Observable<Mutation> {
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
        
        return Observable.empty()
    }
    
    private func fetchRecentSchedules() -> Observable<Mutation> {
        
        let fetchSchedules = fetchRecentScheduleImpl.fetchRecentSchedule()
            .asObservable()
            .map { Mutation.fetchRecentScehdule(schedules: $0) }
        
        return fetchSchedules
    }
    
    private func presentNextEvent() -> Observable<Mutation> {
        guard !currentState.schedules.isEmpty,
              let lastDate = currentState.schedules.last?.date else { return Observable.empty() }
        let startOfDay = DateManager.startOfDay(lastDate)
        return .just(.presentCalendar(date: startOfDay))
    }
    
    private func presentCreateGroupView() -> Observable<Mutation> {
        return .just(.presentCreateGroupView(completedAction: nil))
    }
}