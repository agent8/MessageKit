//
//  ScrollToBottomButtonView.swift
//  Email
//
//  Created by Clarence Chee on 17/4/18.
//  Copyright © 2018 Easilydo. All rights reserved.
//

import Foundation

open class ScrollToBottomButtonView: UIView {
    
    private class RoundButton: UIButton {
        override func layoutSubviews() {
            super.layoutSubviews()
            layer.cornerRadius = frame.height / 2
        }
    }
    
    lazy var button: UIButton = {
        let button = RoundButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.clipsToBounds = true
        button.backgroundColor = EdoColor.dynamic.cardBackground
        button.setImage(EdoTintImage("arrow-down-icon"), for: .normal)
        button.imageView?.tintColor = EdoColor.dynamic.gray
        button.layer.borderWidth = 0.5
        button.layer.borderColor = EdoColor.dynamic.gray.cgColor
        return button
    }()

    private lazy var containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var unreadBadgeCount: UIButton = {
        let button = RoundButton(type: .custom)
        button.backgroundColor = EdoColor.dynamic.brandBlue
        button.setTitle("", for: .normal)
        button.setTitleColor(EdoColor.dynamic.white, for: .normal)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = .staticBoldExtraSmall()
        button.isUserInteractionEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        button.titleEdgeInsets = .zero
        button.imageEdgeInsets = .zero
        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 3, bottom: 2, right: 3)
        return button
    }()
    
    public func setUnreadText(_ text: String, animated: Bool = true) {
        let animationDuration = animated ? 0.15 : 0
        if text.isEmpty {
            UIView.transition(with: unreadBadgeCount,
                              duration: animationDuration,
                              options: .transitionCrossDissolve,
                              animations: { [weak self] in
                self?.unreadBadgeCount.isHidden = true
            }) { [weak self] _ in
                self?.unreadBadgeCount.setTitle("", for: .normal)
            }
        } else {
            UIView.transition(with: unreadBadgeCount,
                              duration: animationDuration,
                              options: .transitionCrossDissolve,
                              animations: { [weak self] in
                self?.unreadBadgeCount.setTitle(text, for: .normal)
                self?.unreadBadgeCount.isHidden = false
            })
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupSubviews()
        setupConstraints()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubviews() {
        addSubview(containerView)
        containerView.addSubview(button)
        containerView.addSubview(unreadBadgeCount)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.leftAnchor.constraint(equalTo: leftAnchor),
            containerView.rightAnchor.constraint(equalTo: rightAnchor)
        ])
        
        NSLayoutConstraint.activate([
            button.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            button.leftAnchor.constraint(equalTo: containerView.leftAnchor),
            button.rightAnchor.constraint(equalTo: containerView.rightAnchor),
            button.widthAnchor.constraint(equalTo: button.heightAnchor),
            button.heightAnchor.constraint(equalToConstant: 40),
            unreadBadgeCount.widthAnchor.constraint(greaterThanOrEqualTo: unreadBadgeCount.heightAnchor),
            unreadBadgeCount.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            unreadBadgeCount.centerYAnchor.constraint(equalTo: button.topAnchor),
            containerView.topAnchor.constraint(equalTo: unreadBadgeCount.topAnchor)
        ])
    }
}

