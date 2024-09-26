//
//  SimpleScheduleView.swift
//  Group
//
//  Created by CatSlave on 9/23/24.
//

import UIKit
import SnapKit

// MARK: - ViewModel
struct SimpleScheduleViewModel {
    let group: Group?
    let title: String?
    let place: String?
    let participantCount: Int?
    let weather: WeatherInfo?
    
    var participantCountString: String? {
        guard let participantCount = participantCount else { return nil }
        
        return "\(participantCount)명 참여"
    }
}

final class SimpleScheduleView : UIView {

    private lazy var thumbnailView: ThumbnailTitleView = {
        let view = ThumbnailTitleView(type: .simple)
        return view
    }()
    
    private let titleLabel = BaseLabel(configure: AppDesign.Schedule.smallTitle)
    
    private let countInfoLabel = IconLabelView(iconSize: 18,
                                                configure: AppDesign.Schedule.count,
                                                contentSpacing: 4)
                      
    private let weatherView = WeatherView()
    
    private lazy var subStackView: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [titleLabel, countInfoLabel])
        sv.axis = .vertical
        sv.spacing = 4
        sv.alignment = .fill
        sv.distribution = .fill
        return sv
    }()
    
    private lazy var mainStackView: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [thumbnailView, subStackView, weatherView])
        sv.axis = .vertical
        sv.spacing = 16
        sv.alignment = .fill
        sv.distribution = .fill
        return sv
    }()
    
    init() {
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.backgroundColor = AppDesign.defaultWihte
        self.addSubview(mainStackView)
        
        mainStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
        
        thumbnailView.snp.makeConstraints { make in
            make.height.equalTo(28)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.height.equalTo(25)
        }
        
        countInfoLabel.snp.makeConstraints { make in
            make.height.equalTo(18)
        }
        
        weatherView.snp.makeConstraints { make in
            make.height.equalTo(56)
        }
    }
    
    public func configure(_ viewModel: ScheduleViewModel) {
        
        self.titleLabel.text = viewModel.title
        
        self.countInfoLabel.setText(viewModel.participantCountString)
        
        self.thumbnailView.configure(with: ThumbnailViewModel(group: viewModel.group))
        self.weatherView.configure(with: viewModel.weather)
    }
}