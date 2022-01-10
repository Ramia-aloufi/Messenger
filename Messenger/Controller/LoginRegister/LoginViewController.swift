//
//  LoginViewController.swift
//  Messenger
//
//  Created by R on 01/06/1443 AH.
//  Copyright © 1443 R. All rights reserved.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import JGProgressHUD

class LoginViewController: UIViewController {
    
    let spinner = JGProgressHUD(style: .dark)

    private let imgView:UIImageView = {
        let img = UIImageView()
        img.contentMode = .scaleAspectFit
        img.image = UIImage(named: "Logo")
        return img
    }()
    
    private let scrollview:UIScrollView = {
        let scroll = UIScrollView()
        scroll.clipsToBounds = true
        return scroll
    }()
    
    private let emailTF:UITextField = {
        let tf = UITextField()
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.returnKeyType = .continue
        tf.layer.cornerRadius = 12
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor.lightGray.cgColor
        tf.placeholder = "Email Address..."
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        tf.leftViewMode = .always
        tf.backgroundColor = .white
        return tf
    }()
    
    private let passwordTF:UITextField = {
        let tf = UITextField()
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.returnKeyType = .done
        tf.layer.cornerRadius = 12
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor.lightGray.cgColor
        tf.placeholder = "Password..."
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        tf.leftViewMode = .always
        tf.isSecureTextEntry = true
        tf.backgroundColor = .white
        return tf
    }()
    
    private let btn:UIButton = {
       let btn = UIButton()
        btn.setTitle("Log in", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .link
        btn.layer.cornerRadius = 12
        btn.layer.masksToBounds = true
        btn.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return btn
    }()
    
    private let loginButton:FBLoginButton = {
        let btn = FBLoginButton()
        btn.permissions = ["public_profile", "email"]
        btn.layer.cornerRadius = 12
        btn.layer.masksToBounds = true
        btn.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return btn
    }()


    override func viewDidLoad() {
        super.viewDidLoad()
         if let token = AccessToken.current, !token.isExpired {
            // User is logged in, do work such as go to next view controller. }
            
        }
        loginButton.delegate = self
        emailTF.delegate = self
        passwordTF.delegate = self
        btn.addTarget(self,
                      action: #selector(btntapped),
                      for: .touchUpInside)
        view.addSubview(scrollview)
        scrollview.addSubview(imgView)
        scrollview.addSubview(emailTF)
        scrollview.addSubview(passwordTF)
        scrollview.addSubview(btn)
        scrollview.addSubview(loginButton)
        
        view.backgroundColor = .white
        title  = "Log in"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(registerTapped))
    }
    @objc func btntapped(){
        emailTF.resignFirstResponder()
        passwordTF.resignFirstResponder()

        guard let email =  emailTF.text,!email.isEmpty,
            let password =  passwordTF.text,!password.isEmpty,password.count > 6 else{
                loginerrorr()
                return
        }
        spinner.show(in: view)
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self](authh, err) in
            guard let selfstrong = self else {
                return
            }
            DispatchQueue.main.async {
                selfstrong.spinner.dismiss()
            }
            guard let res = authh,err == nil else{
                print("err")
                return
            }
            let safeEmail = DatabaseManager.safeemail(email: email)
            DatabaseManager.shared.getdataFor(for: safeEmail) {(res) in
                switch res{
                case .success(let data):
                    guard let userdata = data as? [String:Any] ,
                    let first_name = userdata["firstName"] as? String,
                    let last_name = userdata["lastName"] as? String else {
                        return
                    }
                    UserDefaults.standard.set("\(first_name) \(last_name)", forKey: "name")

                    
                case .failure(let err):
                    print("err to getdataFor\(err)")
                }
            }
            let user = res.user
            UserDefaults.standard.set(email, forKey: "email")

            print(user)
            selfstrong.navigationController?.dismiss(animated: true, completion: nil)

            
        }
    }
    
    func loginerrorr(){
        let alert = UIAlertController(title: "error",
                                      message: "write all information",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "close", style: .cancel, handler: nil))
        self.present(alert,animated: true)
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollview.frame = view.bounds
        let size = scrollview.frame.width / 3
        
        imgView.frame = .init(x:  (scrollview.frame.width - size) / 2,
                              y: 20,
                              width: size,
                              height: size)
        emailTF.frame = .init(x:30,
                              y: imgView.bottom + 10,
                              width: scrollview.width - 60,
                              height: 52)
        passwordTF.frame = .init(x:30,
                                 y: emailTF.bottom + 10,
                                 width: scrollview.width - 60,
                                 height: 52)
        btn.frame = .init(x:30,
                                 y: passwordTF.bottom + 20,
                                 width: scrollview.width - 60,
                                 height: 52)
//        loginButton.center = scrollview.center
//        loginButton.frame.origin.y = btn.bottom + 20
        loginButton.frame = .init(x:30,
                                 y: btn.bottom + 20,
                                 width: scrollview.width - 60,
                                 height: 52)

    }
    
    @objc private func registerTapped(){
        let vc = RegisterViewController()
        vc.title = "Register"
        vc.view.backgroundColor = .white
        navigationController?.pushViewController(vc, animated: true)
    }


}

extension LoginViewController:UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTF{
            passwordTF.becomeFirstResponder()
        }else if textField == passwordTF{
            btntapped()
        }
        return true
    }
}

extension LoginViewController:LoginButtonDelegate{
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        
    }

    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        guard let token = result?.token?.tokenString else {
            print("tokin")
            return
        }
        let facebookrequest = FBSDKLoginKit.GraphRequest(graphPath: "me",
                                                         parameters: ["fields" : "email,firt_name,last_name,picture.type(large)"],
                                                         tokenString: token,
                                                         version: nil,
                                                         httpMethod: .get)
        facebookrequest.start(completion: { (_, res, err) in

            guard let result = res as? [String:Any] ,
                err == nil else {
                print("facebookrequest err")
                return
            }
            print(result)
//            return
            guard let firstName = result["first_name"] as? String,
                 let lastName = result["last_name"] as? String,
                let pic = result["picture"] as? [String:Any],
                let data = pic["data"] as? [String:Any],
                let picUrl = data["url"] as? String,
                let email = result["email"]as? String else{
                    print("err")
                    return
            }
            UserDefaults.standard.set(email, forKey: "email")
            UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")


//             let nameComponent = userName.components(separatedBy: " ")
//            guard nameComponent.count == 2 else {
//                return
//            }
//            let firstName = nameComponent[0]
//            let lastName = nameComponent[1]

            DatabaseManager.shared.userExist(with: email) { (exist) in
                if !exist{
                    let chatUser = chatAppUser(firstName: firstName, lastName: lastName, email: email)
                    DatabaseManager.shared.insertUser(with: chatAppUser(firstName: firstName,lastName: lastName,email: email), complition: {success in
                        if success{
                            guard let url = URL(string: picUrl) else {
                                return
                            }
                            print("download ")
                            URLSession.shared.dataTask(with: url) { (data, _, _) in
                                guard let data = data else {
                                    print("err data ")

                                    return
                                }
                                print("success data ")

                                let fileName = chatUser.profilePicFileName
                                StorageManager.shared.uploudProfilPic(with: data,filename:fileName) { (result) in
                                    switch result{
                                    case .success(let downloadUrl):
                                        UserDefaults.standard.set(downloadUrl, forKey: "Profile_img")
                                        print(downloadUrl)
                                    case .failure(let error):
                                        print("uploudProfilPic: \(error)")
                                    }
                                                                        
                                }
                            }.resume()
                            
                        }
                        
                    })
                }
            }
            let cridential = FacebookAuthProvider.credential(withAccessToken: token)
            Auth.auth().signIn(with: cridential) {[weak self] (authres, err) in
               guard let selfstrong = self else {
                   return
               }
                guard authres != nil ,err == nil else {
                    print("res facebook Login")
                    return
                }
                selfstrong.navigationController?.dismiss(animated: true, completion: nil)
                print("success")
            }
        })
    }
    
}


