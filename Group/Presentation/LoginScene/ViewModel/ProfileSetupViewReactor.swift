//
//  ProfileSetupViewModel.swift
//  Group
//
//  Created by CatSlave on 8/25/24.
//

import UIKit
import ReactorKit
import RxSwift
import RxRelay

struct ProfileSetupAction {
    var completed: () -> Void
}

enum ProfileSetupFacingError: Error {
    case noTokenError
    case completedError
    case networkError
    case serverError
    case errRespon(message: String?)
    case parsingError
    case unknownError(err: Error)
    case retryEnter
    
    var info: String {
        switch self {
        case .noTokenError:
            "Apple ID 정보를 확인하고\n다시 시도해 주세요"
        case .completedError:
            "중복 확인에 실패했습니다.\n잠시 후 다시 시도해 주세요."
        case .unknownError(_):
            "알 수 없는 오류가 발생했습니다.\n잠시 후 다시 시도해 주세요."
        case .networkError:
            "네트워크 연결을 확인해주세요."
        case .serverError:
            "서버에 문제가 발생했습니다.\n잠시 후 다시 시도해 주세요."
        case .parsingError:
            "데이터에 문제가 발생했습니다.\n앱을 최신 버전으로 업데이트해 주세요."
        case .retryEnter:
            "입력 정보를 확인해주세요."
        case .errRespon(let message):
            message ?? "요청에 실패했습니다.\n잠시 후 다시 시도해 주세요."
        }
    }
}



final class ProfileSetupViewReactor: Reactor {

    enum Action {
        case getRandomNickname
        case checkNickname(name: String, tag: Int)
        case setProfile(profile: Profile, tag: Int)
    }
    
    enum Mutation {
        case setLoading(isLoad: Bool)
        case getRandomNickname(name: String?)
        case nameCheck(isOverlap: Bool?)
        case madeProfile
        case catchError(err: Error)
        case setButtonLoading(isLoad: Bool, tag: Int)
    }
    
    struct State {
        @Pulse var randomName: String?
        @Pulse var nameOverlap: Bool?
        @Pulse var errorMessage: String?
        @Pulse var madeProfile: Void?
        @Pulse var isLoading: Bool?
        @Pulse var buttonLoading: (status: Bool, tag: Int)?
    }
    
    private let profileSetupUseCase: ProfileSetup
    private let completedAction: ProfileSetupAction
    
    var initialState: State = State()
    
    init(profileSetupUseCase: ProfileSetup,
         completedAction: ProfileSetupAction) {
        self.profileSetupUseCase = profileSetupUseCase
        self.completedAction = completedAction
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        
        if let isLoading = currentState.buttonLoading {
            guard !isLoading.status else { return Observable.empty() }
        }

        switch action {
        case .getRandomNickname:
            return getRandomNickname()
        case .checkNickname(let name, let tag):
            return overlapCheck(name: name, tag: tag)
        case .setProfile(let profile, let tag) :
            return makeProfile(profile, tag: tag)
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        
        var newState = state
        
        switch mutation {
        case .setLoading(let isLoad):
            newState.isLoading = isLoad
        case .setButtonLoading(let isLoad, let type):
            newState.buttonLoading = (isLoad, type)
        case .getRandomNickname(let name):
            newState.randomName = name
        case .nameCheck(let isOverlap):
            newState.nameOverlap = isOverlap
        case .catchError(err: let err):
            newState = handleError(state: newState, err: err)
        case .madeProfile:
            completedAction.completed()
        }
        
        return newState
    }
    
    func handleError(state: State, err: Error) -> State {
        var newState = state

        switch err {
        case let err as DataTransferError:
            let dataError = mapDataErrorToFacingError(err: err)
            newState.errorMessage = dataError.info
        case let err as TokenError:
            let tokenError = mapTokenErrorToFacingError(err: err)
            newState.errorMessage = tokenError.info
        case let err as ProfileSetupFacingError:
            newState.errorMessage = err.info
        default:
            newState.errorMessage = ProfileSetupFacingError.unknownError(err: err).info
        }
        return newState
    }
}

extension ProfileSetupViewReactor {
    private func mapTokenErrorToFacingError(err : TokenError) -> ProfileSetupFacingError {
        return .noTokenError
    }
    
    private func mapDataErrorToFacingError(err : DataTransferError) -> ProfileSetupFacingError {
        switch err {
        case .parsing(_): .parsingError
        case .noResponse: .completedError
        case .networkFailure(_): .networkError
        case .resolvedNetworkFailure(let err):
            switch err {
            case let err as ServerError:
                mapServerErrorToFacingError(err: err)
            default:
                    .unknownError(err: err)
            }
        }
    }
    
    private func mapServerErrorToFacingError(err: ServerError) -> ProfileSetupFacingError {
        switch err {
        case .httpRespon(_):
            return .serverError
        case .errRespon(let message):
            return .errRespon(message: message)
        }
    }
}

extension ProfileSetupViewReactor {
    
    private func getRandomNickname() -> Observable<Mutation> {
        let loadStart = Observable.just(Mutation.setLoading(isLoad: true))
        
        let randomName = profileSetupUseCase.getRandomNickname()
            .asObservable()
            .map { Mutation.getRandomNickname(name: $0) }
        
        let loadEnd = Observable.just(Mutation.setLoading(isLoad: false))
            
        return Observable.concat([loadStart,
                                  randomName,
                                  loadEnd])
    }
    
    private func overlapCheck(name: String, tag: Int) -> Observable<Mutation> {
        
        let loadingOn = Observable.just(Mutation.setButtonLoading(isLoad: true, tag: tag))
                
        let nameOverlap = profileSetupUseCase.checkNickName(name: name)
            .asObservable()
            .map { Mutation.nameCheck(isOverlap: $0)}
            .catch { Observable.just(Mutation.catchError(err: $0)) }
        
        let loadingOff = Observable.just(Mutation.setButtonLoading(isLoad: false, tag: tag))
            
        return Observable.concat([loadingOn,
                                  nameOverlap,
                                  loadingOff])
    }
    
    private func makeProfile(_ profile: Profile, tag: Int) -> Observable<Mutation> {
        guard let nickname = profile.name else { return .empty() }
  
        let image = profile.image?.jpegData(compressionQuality: 0.5) ?? getDefaultImageData()
        
        let loadingOn = Observable.just(Mutation.setButtonLoading(isLoad: true, tag: tag))
        
        let makeProfile = profileSetupUseCase.makeProfile(image: image, nickName: nickname)
            .asObservable()
            .map({ _ in Mutation.madeProfile })
            .catch { Observable.just(Mutation.catchError(err: $0)) }
        
        let loadingOff = Observable.just(Mutation.setButtonLoading(isLoad: false, tag: tag))
            
        return Observable.concat([loadingOn,
                                  makeProfile,
                                  loadingOff])
    }
}

extension ProfileSetupViewReactor {
    private func getDefaultImageData() -> Data {
        guard let image = AppDesign.Profile.defaultImage,
              let imageData = image.jpegData(compressionQuality: 0.5) else { return Data() }
        
        return imageData
    }
}
