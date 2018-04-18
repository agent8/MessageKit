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
    
    let button: UIButton = {
        let button = RoundButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.clipsToBounds = true
        button.backgroundColor = .white
        button.setImage(EdoTintImage("arrow-down-icon"), for: .normal)
        button.imageView?.tintColor = .lightGray
        button.layer.borderWidth = 0.5
        button.layer.borderColor = UIColor.lightGray.cgColor
        return button
    }()

    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let unreadBadgeCount: BadgeCountLabel = {
        let label = BadgeCountLabel()
        label.font = UIFont.staticBoldExtraSmall()
        label.textAlignment = .center
        label.isHidden = true
        label.textColor = COLOR_TEXT_WHITE
        label.backgroundColor = COLOR_TEXT_HIGHLIGHTED
        label.layer.cornerRadius = 5
        label.clipsToBounds = true
        label.textInsets = UIEdgeInsetsMake(2, 4, 2, 4)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = false
        return label
    }()
    
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
        
        let buttonWidth: CGFloat = 40
        containerView.addConstraintsForDimensions([button], height: buttonWidth, width: buttonWidth)
        
        NSLayoutConstraint.activate([
            button.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            button.leftAnchor.constraint(equalTo: containerView.leftAnchor),
            button.rightAnchor.constraint(equalTo: containerView.rightAnchor),
            unreadBadgeCount.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            unreadBadgeCount.centerYAnchor.constraint(equalTo: button.topAnchor),
            containerView.topAnchor.constraint(equalTo: unreadBadgeCount.topAnchor)
        ])
    }
}

extension BadgeCountLabel {
    override var text: String? {
        didSet {
            if let text = text, !text.isEmpty { // show
                if !isHidden {
                    return
                }
                UIView.transition(with: self,
                                  duration: 0.15,
                                  options: .transitionCrossDissolve,
                                  animations: {
                    self.isHidden = false
                })
            } else { // hide
                if isHidden {
                    return
                }
                UIView.transition(with: self,
                                  duration: 0.25,
                                  options: .transitionCrossDissolve,
                                  animations: {
                    self.isHidden = true
                })
            }
        }
    }
    
    override var attributedText: NSAttributedString? {
        didSet {
            if let text = attributedText, !text.string.isEmpty {
                if !isHidden {
                    return
                }
                UIView.transition(with: self,
                                  duration: 0.15,
                                  options: .transitionCrossDissolve,
                                  animations: {
                    self.isHidden = false
                })
            } else {
                if isHidden {
                    return
                }
                UIView.transition(with: self,
                                  duration: 0.25,
                                  options: .transitionCrossDissolve,
                                  animations: {
                    self.isHidden = true
                })
            }
        }
    }
}
