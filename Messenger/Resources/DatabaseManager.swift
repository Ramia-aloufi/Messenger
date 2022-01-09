//
//  DatabaseManager.swift
//  Messenger
//
//  Created by R on 02/06/1443 AH.
//  Copyright © 1443 R. All rights reserved.
//

import Foundation
import FirebaseDatabase
//MARK: - DatabaseManager
final class DatabaseManager{
    static let shared = DatabaseManager()
    private let database = Database.database().reference()
    
    static func safeemail(email:String)->String{
        var editEmail = email.replacingOccurrences(of: ".", with: "-")
        editEmail = editEmail.replacingOccurrences(of: "@", with: "-")
        return editEmail
    }
    
    
    //}
    //extension DatabaseManager{
    //MARK: - userExist func
    public func userExist(with email:String,completion:@escaping((Bool)->Void)){
        var editEmail = email.replacingOccurrences(of: ".", with: "-")
        editEmail = editEmail.replacingOccurrences(of: "@", with: "-")
        
        database.child(editEmail).observeSingleEvent(of: .value) { snapshoot in
            guard  snapshoot.value as? String != nil else {
                completion(false)
                return
            }
            completion(true)
        }
        
    }
    //MARK: - insertUser func
    /// insert new user to database
    public func insertUser(with user:chatAppUser,complition:@escaping(Bool)->Void){
        database.child(user.safeEmail).setValue([
            "firstName":user.firstName,
            "lastName":user.lastName
        ]) { (err, _) in
            guard err == nil else{
                complition(false)
                print("err insert new user to database")
                return
            }
            
            self.database.child("users").observeSingleEvent(of: .value) { (snapshoot) in
                if var userCollection = snapshoot.value as? [[String:String]]{
                    let newCollection =
                        [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.safeEmail
                    ]
                    userCollection.append(newCollection)
                    self.database.child("users").setValue(userCollection) { (err, _) in
                        guard err == nil else {
                            print("err setValue")
                            complition(false)
                            return
                        }
                        complition(true)
                    }
                }else{
                    let newCollection:[[String:String]] = [
                        [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.safeEmail
                        ]
                    ]
                    self.database.child("users").setValue(newCollection) { (err, _) in
                        guard err == nil else {
                            print("err setValue")
                            complition(false)
                            return
                        }
                        complition(true)
                        
                    }
                }
            }
            
        }
        
    }
    public func getAllUsers(completion:@escaping(Result<[[String:String]],Error>)->Void){
        database.child("users").observeSingleEvent(of: .value) { (snapshoot) in
            guard let value = snapshoot.value as? [[String:String]] else{
                completion(.failure(DataBaseError.feildToFetch))
                return
            }
            completion(.success(value ))
            
        }
    }
    
}

extension DatabaseManager{
    //MARK: - createNewConversation
    public func createNewConversation(with otherUserEmail:String,name:String,firstMessage:Message,complition:@escaping(Bool)->Void){
        
        guard let currentEmail = UserDefaults.standard.value(forKey: "email"),
        let CurrentName = UserDefaults.standard.value(forKey: "name") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeemail(email: currentEmail as! String)
        let ref = database.child(("\(safeEmail)"))
        ref.observeSingleEvent(of: .value) { [weak self](snapshoot) in
            guard var userNode = snapshoot.value as? [String:Any] else{
                complition(false)
                print("User not found")
                return
            }
            var message = ""
            switch firstMessage.kind{
                
            case .text(let messegeText):
                message = messegeText
                break
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            let conversationID = "conversation_\(firstMessage.messageId)"
            let messageData = firstMessage.sentDate
            let datastring = ChatViewController.dateFormatter.string(from: messageData)
            let newConversation:[String : Any] = [
                "id":conversationID,
                "other_user_email":otherUserEmail,
                "name":name,
                "latest_message":[
                    "date":datastring,
                    "latest_message":message,
                    "is_read":false
                ]
            ]
            
            let recipient_newConversation:[String : Any] = [
                "id":conversationID,
                "other_user_email":safeEmail,
                "name":CurrentName,
                "latest_message":[
                    "date":datastring,
                    "latest_message":message,
                    "is_read":false
                ]
            ]
            

            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) {[weak self] (snapshoot) in
                if var conversations = snapshoot.value as? [[String:Any]]{
                    conversations.append(recipient_newConversation)
                    self?.database.child("\(otherUserEmail)/conversations").setValue(conversationID)

                }else{
                    self?.database.child("\(otherUserEmail)/conversations").setValue(recipient_newConversation)
                }
                
            }
            
            if var conversation = userNode["conversation"] as? [[String:Any]]{
                conversation.append(newConversation)
                userNode["conversation"] = conversation
                ref.setValue(userNode) { [weak self](err, _) in
                    guard err==nil else {
                        complition(false)
                        return
                    }
                    self?.finishCreateConversation(name: name, conversationID: conversationID, firstmessage: firstMessage, completion: complition)
                   // complition(true)
                }
            }else{
                userNode["conversation"] = [
                    newConversation
                ]
                ref.setValue(userNode) { [weak self](err, _) in
                    guard err==nil else {
                        complition(false)
                        return
                    }
                   // complition(true)
                    self?.finishCreateConversation(name: name, conversationID: conversationID, firstmessage: firstMessage, completion: complition)
                }
                
            }
            
        }
        
    }

    //MARK: - finishCreateConversation

    private func finishCreateConversation(name:String,conversationID:String,firstmessage:Message,completion:@escaping(Bool)->Void){
       
        let messageData = firstmessage.sentDate
        let datastring = ChatViewController.dateFormatter.string(from: messageData)
        
        var message = ""
        switch firstmessage.kind{
        case .text(let messegeText):
            message = messegeText
            break
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        guard let myEmail = UserDefaults.standard.value(forKey: "email") else {
            completion(false)
            return
        }
        let currentUserEmail = DatabaseManager.safeemail(email: myEmail as! String)
        
        
        let collectionMessages:[String:Any] = [
            "id":firstmessage.messageId,
            "type":firstmessage.kind.messageKindString,
            "content":message,
            "date":datastring,
            "sender_email":currentUserEmail,
            "is_read":false,
            "name":name
        ]
        
        let value:[String:Any] = [
        "messages":[
            collectionMessages
        ]
        ]
        database.child("\(conversationID)").setValue(value) { (err, _) in
            guard err==nil else {
                completion(false)
                return
            }
            completion(true)
        }
        
    }
    //MARK: - getAllConversation
    public func getAllConversation(for email:String,complition:@escaping (Result<[Conversation],Error>)->Void){
        
        database.child("\(email)/conversation").observe(.value) { (snapshoot) in
            guard let value = snapshoot.value as? [[String:Any]] else {
                complition(.failure(DataBaseError.feildToFetch))
                return
            }
            let conversation:[Conversation] = value.compactMap { (dictionary) in
                print(dictionary)
                guard let conversationID = dictionary["id"] as? String,
                    let name = dictionary["name"] as? String,
                    let otherUseremail = dictionary["other_user_email"] as? String,
                    let latesrMessage = dictionary["latest_message"] as? [String:Any],
                    let date = latesrMessage["date"] as? String,
                    let message = latesrMessage["latest_message"] as? String,
                    let isRead = latesrMessage["is_read"] as? Bool
                else{
                    print("err conversation")
                    return nil
                }
                let latestMessageObject = LatestMessage(date: date, text: message, isRead: isRead)
                return Conversation(id: conversationID,
                                    name: name ,
                                    otherUserEmail: otherUseremail,
                                    latestMessage: latestMessageObject)
            }
            complition(.success(conversation))
            print("conversation:\(conversation)")

        }
        
    }
    public func getAllMessagesForConversation(for id:String,compition:@escaping (Result<[Message],Error>)->Void){
        
        
        database.child("\(id)/messages").observe(.value) { (snapshoot) in
            guard let value = snapshoot.value as? [[String:Any]] else {
                compition(.failure(DataBaseError.feildToFetch))
                return
            }
            let messages:[Message] = value.compactMap { (dictionary) in
                print(dictionary)
                guard let content = dictionary["content"] as? String,
                    let name = dictionary["name"] as? String,
                    let datestring = dictionary["date"] as? String,
                    let date = ChatViewController.dateFormatter.date(from: datestring),
                    let message_id = dictionary["id"] as? String,
                    let is_read = dictionary["is_read"] as? Bool,
                    let sender_email = dictionary["sender_email"] as? String,
                    let type = dictionary["type"] as? String
                else{
                    print("err conversation")
                    return nil
                }
                let sender = Sender(photoURL: "", senderId: sender_email, displayName: name)
                return Message(sender: sender, messageId: message_id, sentDate: date, kind: .text(content))
            }
            compition(.success(messages))
            print("conversation:\(messages)")

        }
        
    }
    public func sendMessages(to conversation:String,name:String,newMessage:Message,compition:@escaping (Bool)->Void){
        self.database.child("\(conversation)/messages").observeSingleEvent(of: .value) { [weak self](snapshoot) in
            guard var currentmessages = snapshoot.value as? [[String:Any]] else {
                compition(false)
                return
            }
            let messageData = newMessage .sentDate
            let datastring = ChatViewController.dateFormatter.string(from: messageData)
            
            var message = ""
            switch newMessage.kind{
            case .text(let messegeText):
                message = messegeText
                break
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            guard let myEmail = UserDefaults.standard.value(forKey: "email") else {
                compition(false)
                return
            }
            let currentUserEmail = DatabaseManager.safeemail(email: myEmail as! String)
            
            
            let newMessageEntry:[String:Any] = [
                "id":newMessage.messageId,
                "type":newMessage.kind.messageKindString,
                "content":message,
                "date":datastring,
                "sender_email":currentUserEmail,
                "is_read":false,
                "name":name
            ]
            currentmessages.append(newMessageEntry)
            self?.database.child("\(conversation)/messages").setValue(currentmessages) { (err, _) in
                guard err==nil else {
                    compition(false)
                    return
                }
                compition(true)
            }


        }
        
    }
}
//MARK: - chatAppUser struct
struct chatAppUser {
    let firstName:String
    let lastName:String
    let email:String
    
    var safeEmail:String{
        var editEmail = email.replacingOccurrences(of: ".", with: "-")
        editEmail = editEmail.replacingOccurrences(of: "@", with: "-")
        return editEmail
    }
    var profilePicFileName:String{
        return"\(safeEmail)_profile_picture.png"
    }
}
//MARK: - DataBaseError func
public enum DataBaseError:Error{
    case feildToFetch
}

extension DatabaseManager{
    public func getdataFor(for path:String,complition:@escaping (Result<Any,Error>)->Void){
        self.database.child(path).observeSingleEvent(of: .value) { (snapshoot) in
            guard let value = snapshoot.value else{
                complition(.failure(DataBaseError.feildToFetch))
                return
            }
            complition(.success(value))
        }
    }
}
