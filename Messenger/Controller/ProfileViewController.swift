//
//  ProfileViewController.swift
//  Messenger
//
//  Created by R on 01/06/1443 AH.
//  Copyright © 1443 R. All rights reserved.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit

class ProfileViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    let arr = ["Log Out"]
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = createTableViewHeader()

    }
    func createTableViewHeader() -> UIView? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        let safeemail = DatabaseManager.safeemail(email: email)
        let fileName = "\(safeemail)_profile_picture.png"
        print("fileName:" ,fileName)
        let path = fileName
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.width, height: 300))
        let imgview = UIImageView(frame: CGRect(x: (headerView.width - 150) / 2, y: (headerView.height - 150) / 2, width: 150, height: 150))
        headerView.backgroundColor = .link
        imgview.contentMode = .scaleAspectFill
        imgview.layer.borderColor = UIColor.white.cgColor
        imgview.layer.borderWidth = 3
        imgview.backgroundColor = .white
        imgview.layer.cornerRadius = imgview.width / 2 
        imgview.layer.masksToBounds = true
        headerView.addSubview(imgview)
        StorageManager.shared.downloadURl(path: path) {[weak self] (res) in
            switch res{
            case .success(let url):
                self?.downloadImg(img: imgview, url: url)
            case .failure(let err):
                print("er to get photo : \(err)")
            }
        }
        return headerView
        
        
    }
    func downloadImg(img:UIImageView,url:URL){
        URLSession.shared.dataTask(with: url) { (data, _, err) in
            guard let data = data ,err == nil else {
                return
            }
            let image = UIImage(data: data)
            DispatchQueue.main.async {
                img.image = image
            }
            
        }.resume()
    }


}

extension ProfileViewController:UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = arr[indexPath.row]
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = .red
        return cell
        
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //unhilight
        tableView.deselectRow(at: indexPath, animated: true)
        
        let alertsheet = UIAlertController(title: "",
                                           message: "",
                                           preferredStyle: .actionSheet)
        alertsheet.addAction(UIAlertAction(title: "Log Out",
                                           style: .destructive,
                                           handler: { [weak self](_) in
                                            guard let strongself = self else{return}
                                            FBSDKLoginKit.LoginManager().logOut()
                                            do{
                                                try Auth.auth().signOut()
                                                let vc =  LoginViewController()
                                                let nav = UINavigationController(rootViewController: vc)
                                                nav.modalPresentationStyle = .fullScreen
                                                strongself.present(nav, animated: true)
                                            }catch{
                                                print("feild Log Out")
                                            }
        }))
        alertsheet.addAction(UIAlertAction(title: "cancel",
                                           style: .cancel,
                                           handler: nil))
        present(alertsheet,animated: true)

    }
    
    
    
}
