//
//  ChatViewController.swift
//  Messenger
//
//  Created by R on 02/06/1443 AH.
//  Copyright © 1443 R. All rights reserved.
//

import UIKit
import MessageKit
import JGProgressHUD
import InputBarAccessoryView
struct Message:MessageType {
    public var sender: SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKind
    
}
extension MessageKind{
    var messageKindString:String{
        switch self {
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributed_Text"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "linkPreview"
        case .custom(_):
            return "custom"
            
        }
    }
}

struct Sender:SenderType {
    public var photoURL: String
    public var senderId: String
    public var displayName: String
}

class ChatViewController: MessagesViewController {
    
    public static var dateFormatter:DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    public let otherUserEmail:String
    public let conversationID:String?

    public var isNewConversation = false
    
     let spinner = JGProgressHUD(style: .dark)
    let tableView :UITableView = {
       let tbl = UITableView()
        tbl.isHidden = true
        tbl.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tbl
    }()
    init(with email:String,id:String?){
        self.conversationID = id
        self.otherUserEmail = email
        super.init(nibName: nil, bundle: nil)

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let noConversationLbl :UILabel = {
       let lbl = UILabel()
        lbl.text = "No Result"
        lbl.textColor = .gray
        lbl.font = .systemFont(ofSize: 22,weight:.medium)
        lbl.textAlignment = .center
        lbl.isHidden = true
        return lbl
    }()
    
    private var messeges = [Message]()
    private var selfsender:Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String  else {
            return nil
        }
        let safeEmail = DatabaseManager.safeemail(email: email)
        return Sender(photoURL: "",
               senderId: safeEmail ,
               displayName: "hi")}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
        if let conversationID = conversationID {
            listenerForMessages(id: conversationID, shouldScrollToButton: true)

        }
    }
    private func listenerForMessages(id:String,shouldScrollToButton:Bool){
        DatabaseManager.shared.getAllMessagesForConversation(for: id) { [weak self](res) in
            switch res{
            case .success(let resmessage):
                guard !resmessage.isEmpty else {
                    print("empty messages")
                    return
                }
                self?.messeges = resmessage
                DispatchQueue.main.async {
                    if shouldScrollToButton{
                        self?.messagesCollectionView.scrollToLastItem()
                    }else{
                    self?.messagesCollectionView.reloadDataAndKeepOffset()

                    }
                }
                
            case .failure(let err):
                print("err get messages:  \(err)")
            }
        }
    }

}
extension ChatViewController:InputBarAccessoryViewDelegate{
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
            let selfsender = self.selfsender,
            let messageId = createMessageId() else{
                return
        }
        let message = Message(sender: selfsender, messageId: messageId, sentDate: Date(), kind: .text(text))
        if isNewConversation {
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, name: self.title ?? "user", firstMessage: message) {[weak self](success) in
                if success{
                    print("success")
                    self?.isNewConversation = false
                }else{
                    print("err")
                }
                guard let conversationID = self?.conversationID,
                    let name = self?.title
                    else {return}
                DatabaseManager.shared.sendMessages(to: conversationID,name: name,newMessage: message,compition: { (success) in
                    if success{
                        print("sendMessages")
                    }else{
                        print("sendMessages err")
                    }
                })
                
            }
            
        }else{
            
        }
    }
    private func createMessageId() -> String?{
        let datestring = ChatViewController.dateFormatter.string(from: Date())
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email")  as? String
         else {
            return nil
        }
        let safeCurrentUserEmail = DatabaseManager.safeemail(email: currentUserEmail)

        let newIdentifair = "\(otherUserEmail)_\(safeCurrentUserEmail )_\(datestring)"
        print("Create Message ID:\(newIdentifair)")
        return newIdentifair
        
        
    }
}
extension ChatViewController:MessagesDataSource,MessagesLayoutDelegate,MessagesDisplayDelegate{
    func currentSender() -> SenderType {
        if let sender = selfsender {
            return sender
        }
        fatalError("self sender is nil")
        return Sender(photoURL: "", senderId: "89", displayName: "")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messeges[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messeges.count
    }
    
    
}
