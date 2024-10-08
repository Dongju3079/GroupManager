//
//  GroupListSceneDIContainer.swift
//  Group
//
//  Created by CatSlave on 8/31/24.
//

import UIKit

final class GroupListSceneDIContainer: GroupListCoordinatorDependencies {
    
    let apiDataTransferService: DataTransferService

    init(apiDataTransferService: DataTransferService) {
        self.apiDataTransferService = apiDataTransferService
    }
    
    func makeGroupListFlowCoordinator(navigationController: UINavigationController) -> GroupListCoordinator {
        let flow = GroupListCoordinator(navigationController: navigationController,
                                        dependencies: self)
        return flow
    }
    
    func makeGroupListViewController() -> GroupListViewController {
        return GroupListViewController(title: "모임",
                                       reactor: makeGroupListViewReactor())
    }
    
    private func makeGroupListViewReactor() -> GroupListViewReactor {
        return GroupListViewReactor(fetchUseCase: FetchGroupListMock())
    }
}

