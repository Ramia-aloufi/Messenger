//
//  NewConversationViewController.swift
//  Messenger
//
//  Created by R on 01/06/1443 AH.
//  Copyright © 1443 R. All rights reserved.
//

import UIKit
import JGProgressHUD
class NewConversationViewController: UIViewController {
    
    let spinner = JGProgressHUD(style: .dark)
    
    private var users = [[String:String]]()
    private var results = [[String:String]]()
    public var completion:(([String:String])->(Void))?
    private var hasfetched = false
    
    private let searchBar:UISearchBar = {
        let bar = UISearchBar()
        bar.placeholder = "search for users"
        return bar
    }()
    
    let tableView :UITableView = {
       let tbl = UITableView()
        tbl.isHidden = true
        tbl.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
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
        view.addSubview(tableView)
        view.addSubview(noConversationLbl)
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        navigationController?.navigationBar.topItem?.titleView = searchBar
        view.backgroundColor = .white
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "cancel",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(cancelTapped))
        searchBar.becomeFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        noConversationLbl.frame = CGRect(x: view.width / 4, y: (view.height - 200) / 2, width: view.width / 2, height: 200)
    }
    
    @objc func cancelTapped(){
        dismiss(animated: true, completion: nil)
    }
    
}
extension NewConversationViewController:UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = results[indexPath.row]["name"]
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
      //  let targetUser = users[indexPath.row]
        let targetUser = results[indexPath.row]

        dismiss(animated: true) {[weak self] in
            self?.completion?(targetUser)
        }
    }
}

extension NewConversationViewController:UISearchBarDelegate{
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
                guard let text = searchBar.text,!text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        searchBar.becomeFirstResponder()
        results.removeAll()
        spinner.show(in: view )
        self.searchUser(query: text)
    }
    
    func searchUser(query:String){
        if hasfetched{
            filterUser(with: query)
        }else{
            DatabaseManager.shared.getAllUsers { [weak self](res) in
                switch res {
                case .success(let user):
                    self?.hasfetched = true
                    self?.users = user
                    self?.filterUser(with: query)
                case .failure(let err):
                    print("err to getAllUsers: ",err)
                }
            }
        }
        print("users:\(users)")
    }
    
    func filterUser(with term:String){
        guard hasfetched else {
            return
        }
        self.spinner.dismiss()
        let result:[[String:String]] = self.users.filter({
            guard let name = $0["name"]?.lowercased() else {
                return false
            }
            return name.hasPrefix(term.lowercased())
        })
        self.results = result
        print("results:\(results)")

        UpdateUI()
    }
    func UpdateUI(){
        if results.isEmpty{
            self.noConversationLbl.isHidden = false
            self.tableView.isHidden = true
        }else{
            self.noConversationLbl.isHidden = true
            self.tableView.isHidden = false
            self.tableView.reloadData()
        }
    }
}
