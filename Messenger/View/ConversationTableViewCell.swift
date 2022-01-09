//
//  ConversationTableViewCell.swift
//  Messenger
//
//  Created by R on 05/06/1443 AH.
//  Copyright © 1443 R. All rights reserved.
//

import UIKit
import SDWebImage

class ConversationTableViewCell: UITableViewCell {
    static let identifer = "ConversationTableViewCell"
    
    let userimageview:UIImageView = {
       let img = UIImageView()
        img.contentMode = .scaleAspectFill
        img.layer.cornerRadius = 50
        img.layer.masksToBounds = true
        return img
    }()
    
    let userNameLabel:UILabel = {
       let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 21, weight: .semibold)
         return lbl
    }()
    
    let userMessageLabel:UILabel = {
       let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 19, weight: .regular)
        lbl.numberOfLines = 0
         return lbl
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(userimageview)
        contentView.addSubview(userNameLabel)
        contentView.addSubview(userMessageLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        userimageview.frame = CGRect(x: 10,
                                     y: 10,
                                     width: 100,
                                     height: 100)
        
        userNameLabel.frame = CGRect(x: userimageview.right + 10,
                                     y: 10,
                                     width: contentView.width - 20 - userimageview.width,
                                     height: (contentView.height - 20) / 2)
        
        userMessageLabel.frame = CGRect(x: userimageview.right + 10,
                                        y: userNameLabel.bottom + 10,
                                        width: contentView.width - 20 - userimageview.width,
                                        height: (contentView.height - 20) / 2)
    }
    
    public func configure(with model:Conversation){
        userNameLabel.text = model.name
        userMessageLabel.text = model.latestMessage.text
        let path = "\(model.otherUserEmail)_profile_picture.png"
        StorageManager.shared.downloadURl(path: path) { [weak self](result) in
            switch result{
            case .success(let url):
                DispatchQueue.main.async {

                    self?.userimageview.sd_setImage(with: url, completed: nil)
                    }
            case .failure(let err):
                print("err to download\(err)")
            }
        }
    }

}
