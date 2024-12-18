//
//  CreateGroupMock.swift
//  Group
//
//  Created by CatSlave on 11/19/24.
//

import UIKit
import RxSwift

final class CreateGroupMock: CreateGroup {
    func createGroup(title: String, image: UIImage?) -> RxSwift.Single<Void> {
        return Observable.just(())
            .delay(.seconds(2), scheduler: MainScheduler.instance)
            .asSingle()
    }
}
