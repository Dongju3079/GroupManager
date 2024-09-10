//
//  HomeSceneDIContainer.swift
//  Group
//
//  Created by CatSlave on 8/31/24.
//

import UIKit

final class HomeSceneDIContainer: HomeCoordinatorDependencies {
    
    let apiDataTransferService: DataTransferService

    init(apiDataTransferService: DataTransferService) {
        self.apiDataTransferService = apiDataTransferService
    }
    
    func makeHomeFlowCoordinator(navigationController: UINavigationController) -> HomeCoordinator {
        let flow = HomeCoordinator(navigationController: navigationController,
                                        dependencies: self)
        return flow
    }
    
    func makeHomeViewController(action: LogOutAction) -> HomeViewController {
        return HomeViewController(reactor: makeHomeViewReactor(action))
    }
    
    private func makeHomeViewReactor(_ action: LogOutAction) -> ScheduleViewReactor {
        return ScheduleViewReactor(fetchUseCase: fetchRecentScheduleMock(),
                                   logOutAction: action)
    }
}