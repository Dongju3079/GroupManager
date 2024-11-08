//
//  ThumbnailView.swift
//  Group
//
//  Created by CatSlave on 9/22/24.
//

import UIKit
import SnapKit

// MARK: - ViewModel
struct ThumbnailViewModel {
    let name: String?
    let thumbnailPath: String?
    let memberCount: Int?
    let lastScheduleDate: Date?
}

extension ThumbnailViewModel {
    init(group: CommonGroup?,
         memberCount: Int? = nil,
         lastScheduleDate: Date? = nil) {
        self.name = group?.name
        self.thumbnailPath = group?.thumbnailPath
        self.memberCount = memberCount
        self.lastScheduleDate = lastScheduleDate
    }
}

// MARK: - View
final class ThumbnailTitleView: UIView {
    
    enum ViewType {
        case simple
        case detail
    }
    
    private var viewType: ViewType
    
    private let thumbnailView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    
    private let groupTitleLabel = BaseLabel()
    
    private lazy var memberCountView: IconLabelView = {
        let view = IconLabelView(iconSize: 20,
                                 configure: AppDesign.Group.member,
                                 contentSpacing: 4,
                                 titleTopPadding: 3)
        return view
    }()
    
    private let subButton: UIButton = {
        let btn = UIButton()
        btn.setImage(AppDesign.Group.arrow.itemConfig.image, for: .normal)
        return btn
    }()
    
    private lazy var groupInfoStackView: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [groupTitleLabel])
        sv.axis = .vertical
        sv.spacing = 4
        sv.distribution = .fill
        sv.alignment = .leading
        sv.setContentHuggingPriority(.init(1), for: .horizontal)
        return sv
    }()
    
    private lazy var mainStackView: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [thumbnailView, groupInfoStackView, subButton])
        sv.axis = .horizontal
        sv.spacing = 12
        sv.distribution = .fill
        sv.alignment = .center
        return sv
    }()
    
    
    init(type: ViewType) {
        self.viewType = type
        defer { setupUI() }
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(mainStackView)
        
        mainStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        infoConfigure()
    }
    
    private func infoConfigure() {
        switch viewType {
        case .simple:
            setThumbnail(size: 28, radius: 6)
            groupTitleLabel.setConfigure(configure: AppDesign.Schedule.group)
        case .detail:
            setThumbnail(size: 56, radius: 12)
            groupTitleLabel.setConfigure(configure: AppDesign.Group.title)
            makeDetail()
        }
    }
    
    private func setThumbnail(size: CGFloat, radius: CGFloat) {
        thumbnailView.snp.makeConstraints { make in
            make.size.equalTo(size)
        }
        thumbnailView.layer.cornerRadius = radius
    }
    
    
    public func configure(with viewModel: ThumbnailViewModel?) {
        guard let viewModel = viewModel else { return }
        
        loadImage(viewModel.thumbnailPath)
        groupTitleLabel.text = viewModel.name
        
        if viewType == .detail {
            setCountView(count: viewModel.memberCount ?? 0)
        }
    }

    private func loadImage(_ path: String?) {
        _ = thumbnailView.kfSetimage(path)
    }
}

extension ThumbnailTitleView {
    private func makeDetail() {
        groupInfoStackView.addArrangedSubview(memberCountView)
        
        memberCountView.snp.makeConstraints { make in
            make.height.equalTo(20)
        }
    }
    
    private func setCountView(count: Int) {
        memberCountView.setText("\(count) 명")
    }
}
