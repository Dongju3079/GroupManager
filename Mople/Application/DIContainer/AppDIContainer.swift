//
//  AppDIContainer.swift
//  Group
//
//  Created by CatSlave on 8/20/24.
//

import Foundation

final class AppDIContainer {
    
    // MARK: - 앱 서비스
    lazy var appConfiguration = AppConfiguration()
    
    lazy var appNetworkService: AppNetWorkService = {
        
        let config = ApiDataNetworkConfig(baseURL: URL(string: appConfiguration.apiBaseURL))
        
        let apiDataNetwork = DefaultNetworkService(config: config)
        
        let transferService = DefaultDataTransferService(with: apiDataNetwork)
        
        return DefaultAppNetWorkService(dataTransferService: transferService)
    }()
}

// MARK: - Make DIContainer
extension AppDIContainer {
    
    // MARK: - 로그인 플로우
    func makeLoginSceneDIContainer() -> LoginSceneDIContainer {
        return LoginSceneDIContainer(appNetworkService: appNetworkService)
    }
    
    // MARK: - 메인 플로우
    func makeMainSceneDIContainer() -> MainSceneDIContainer {
        return MainSceneDIContainer(appNetworkService: appNetworkService)
    }
}


