//
//  GroupCreateViewReactor.swift
//  Group
//
//  Created by CatSlave on 11/18/24.
//

import UIKit
import ReactorKit

struct CreateGroupAction {
    var completed: (() -> Void)?
}

final class GroupCreateViewReactor: Reactor {
    
    enum Action {
        case setGroup(group: (title: String?, image: UIImage?))
    }
    
    enum Mutation {
        case madeGroup
        case notifyMessage(message: String?)
        case setLoading(isLoad: Bool)
    }
    
    struct State {
        @Pulse var message: String?
        @Pulse var isLoading: Bool = false
    }
    
    var initialState: State = State()
    
    private let createGroupImpl: CreateGroup
    private let createGroupAction: CreateGroupAction
    
    init(createGroupImpl: CreateGroup, createGroupAction: CreateGroupAction) {
        self.createGroupImpl = createGroupImpl
        self.createGroupAction = createGroupAction
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .setGroup(let group):
            self.createGroup(title: group.title, image: group.image)
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        
        var newState = state
        
        switch mutation {
        case .madeGroup:
            createGroupAction.completed?()
        case .notifyMessage(let message):
            newState.message = message
        case .setLoading(let isLoad):
            newState.isLoading = isLoad
        }
        
        return newState
    }
}

extension GroupCreateViewReactor {
    private func createGroup(title: String?, image: UIImage?) -> Observable<Mutation> {
        let validCheck = titleValidCheck(title: title)
        
        guard validCheck.valid else {
            return .just(.notifyMessage(message: validCheck.message))
        }
    
        let loadStart = Observable.just(Mutation.setLoading(isLoad: true))
        
        #warning("오류 발생 시 문제 해결")
        let makeGroup = createGroupImpl.createGroup(title: title!, image: image)
            .asObservable()
            .map { _ in Mutation.madeGroup }
            .catch { err in .just(.notifyMessage(message: "오류 발생")) }
        
        let loadEnd = Observable.just(Mutation.setLoading(isLoad: false))
            
        return Observable.concat([loadStart,
                                  makeGroup,
                                  loadEnd])
    }
    
    private func titleValidCheck(title: String?) -> (valid: Bool, message: String) {
        let valid = GroupTitleValidator.validator(title)
        
        switch valid {
        case .success:
            return (true, valid.info)
        default:
            return (false, valid.info)
        }
    }
}

