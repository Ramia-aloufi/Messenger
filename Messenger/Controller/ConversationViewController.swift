//
//  ViewController.swift
//  Messenger
//
//  Created by R on 01/06/1443 AH.
//  Copyright © 1443 R. All rights reserved.
//

import UIKit
import FirebaseAuth
import JGProgressHUD
struct Conversation {
    let id:String
    let name:String
    let otherUserEmail:String
    let latestMessage:LatestMessage
}
struct LatestMessage {
    let date:String
    let text:String
    let isRead:Bool
    
}
class ConversationViewController: UIViewController {
     let spinner = JGProgressHUD(style: .dark)
    private var conversations = [Conversation]()
    let tableView :UITableView = {
       let tbl = UITableView()
        tbl.isHidden = true
        tbl.register(ConversationTableViewCell.self, forCellReuseIdentifier: ConversationTableViewCell.identifer)
        return tbl
    }()
    
    let noConversationLbl :UILabel = {
       let lbl = UILabel()
        lbl.text = "No Conversation"
        lbl.textColor = .gray
        lbl.font = .systemFont(ofSize: 22,weight:.medium)
        lbl.textAlignment = .center
        lbl.isHidden = true
        return lbl
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose,
                                                            target: self,
                                                            action: #selector(composeTapped))
        view.addSubview(tableView)
        view.addSubview(noConversationLbl)
        fetchConversation()
        
        tableView.delegate = self
        tableView.dataSource = self
        title = "Conversation"
        startListiningForConversation()
    }
    
    private func startListiningForConversation(){
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        print("startListiningForConversation:Email:\(email)")
        let safeEmail = DatabaseManager.safeemail(email: email)
        print("startListiningForConversation:safeEmail:\(safeEmail)")

        DatabaseManager.shared.getAllConversation(for: safeEmail) {[weak self] (res) in
            switch res{
            case .success(let conversation):
                guard !conversation.isEmpty  else {
                    return
                }
                self?.conversations = conversation
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
                print("conversations:\(String(describing: self?.conversations))")
            case .failure(let err):
                print("feild to get conversation\(err)")
            }
        }
    }
    @objc func composeTapped(){
        let vc = NewConversationViewController()
        let nav = UINavigationController(rootViewController: vc)
        vc.completion = {[weak self]result in
            print(result)
            self?.createNewConversation(result: result)
            
        }
        present(nav,animated: true)
    }
    
    private func createNewConversation(result:[String:String]){
        guard let name = result["name"]
            ,let email = result["email"] else {
            return
        }
        let vc = ChatViewController(with: email,id: nil)
        vc.title = name
        vc.isNewConversation = true
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    private func fetchConversation(){
        tableView.isHidden = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        validate()
        
    }
    
    private func validate(){
        if Auth.auth().currentUser == nil{
            let vc =  LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false)
        }
    }
}

extension ConversationViewController:UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = conversations[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifer, for: indexPath) as! ConversationTableViewCell
        cell.configure(with: model)
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = conversations[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = ChatViewController(with: model.otherUserEmail,id: model.id)
        vc.title = model.name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
}


