//
//  RegisterViewController.swift
//  Messenger
//
//  Created by R on 01/06/1443 AH.
//  Copyright © 1443 R. All rights reserved.
//

import UIKit
import FirebaseAuth
import JGProgressHUD


class RegisterViewController: UIViewController {
    
    let spinner = JGProgressHUD(style: .dark)
    //MARK:- outlet
    private let imgView:UIImageView = {
        let img = UIImageView()
        img.contentMode = .scaleAspectFit
        img.image = UIImage(systemName: "person.circle")
        img.layer.masksToBounds = true
        img.layer.borderWidth = 2
        img.layer.borderColor = UIColor.lightGray.cgColor
        img.tintColor = .lightGray
        return img
    }()
    private let scrollview:UIScrollView = {
        let scroll = UIScrollView()
        scroll.clipsToBounds = true
        return scroll
    }()
    private let firstNameTF:UITextField = {
        let tf = UITextField()
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.returnKeyType = .continue
        tf.layer.cornerRadius = 12
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor.lightGray.cgColor
        tf.placeholder = "First Name..."
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        tf.leftViewMode = .always
        tf.backgroundColor = .white
        return tf
    }()
    
    private let LastNameTF:UITextField = {
        let tf = UITextField()
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.returnKeyType = .continue
        tf.layer.cornerRadius = 12
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor.lightGray.cgColor
        tf.placeholder = "Last Name..."
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        tf.leftViewMode = .always
        tf.backgroundColor = .white
        return tf
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
        btn.setTitle("Register", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .systemGreen
        btn.layer.cornerRadius = 12
        btn.layer.masksToBounds = true
        btn.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return btn
    }()
    //MARK:-viewDidLoad func
    override func viewDidLoad() {
        super.viewDidLoad()
        imgView.isUserInteractionEnabled = true
        scrollview.isUserInteractionEnabled = true
        emailTF.delegate = self
        passwordTF.delegate = self
        btn.addTarget(self,
                      action: #selector(btntapped),
                      for: .touchUpInside)
        view.addSubview(scrollview)
        scrollview.addSubview(imgView)
        scrollview.addSubview(firstNameTF)
        scrollview.addSubview(LastNameTF)
        scrollview.addSubview(emailTF)
        scrollview.addSubview(passwordTF)
        scrollview.addSubview(btn)
        let gesture = UITapGestureRecognizer(target: self, action: #selector(imgTapped))
        gesture.numberOfTouchesRequired = 1
        gesture.numberOfTapsRequired = 1
        imgView.addGestureRecognizer(gesture)
        view.backgroundColor = .white
        title  = "Register"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(registerTapped))
    }
    //MARK:-imgTapped func
    @objc private func imgTapped(){
        print("imgTapped func")
        presenrPhotoActionSheet()
    }
    //MARK:-btntapped func
    @objc func btntapped(){
        print("btntapped func")
        emailTF.resignFirstResponder()
        passwordTF.resignFirstResponder()
        firstNameTF.resignFirstResponder()
        LastNameTF.resignFirstResponder()
        guard let firstName =  firstNameTF.text,!firstName.isEmpty,
            let lastName =  LastNameTF.text,!lastName.isEmpty,
            let email =  emailTF.text,!email.isEmpty,
            let password =  passwordTF.text,!password.isEmpty,password.count > 6 else{
                loginerrorr()
                return
        }
        //MARK:-spinner.show
        spinner.show(in: view)
        //MARK:-userExist
        DatabaseManager.shared.userExist(with: email) { [weak self] (exist) in
            guard !exist else{
                self?.loginerrorr(messege: "email already exist")
                return
            }
        //MARK:-spinner.dismiss
            DispatchQueue.main.async {
                self?.spinner.dismiss()
            }
            //MARK:-createUser Auth
            Auth.auth().createUser(withEmail: email, password: password) {(authh, err) in
                guard  authh != nil,err == nil else{
                    print("err createUser")
                    return
                }
                let chatUser = chatAppUser(firstName: firstName, lastName: lastName, email: email)
                //MARK:-insertUser Database
                DatabaseManager.shared.insertUser(with:chatUser ,complition: {success in
                    if success{
                        guard let img = self?.imgView.image ,
                            let data = img.pngData() else {
                                return
                        }
                        let fileName = chatUser.profilePicFileName
                        //MARK:-uploudProfilPic Storage
                        StorageManager.shared.uploudProfilPic(with: data,filename:fileName) { (result) in
                            switch result{
                            case .success(let downloadUrl):
                                UserDefaults.standard.set(downloadUrl, forKey: "Profile_img")
                                print("uploudProfilPic success ")
                                print(downloadUrl)
                            case .failure(let error):
                                print("uploudProfilPic err: \(error)")
                            }
                            
                        }
                    }
                })
                UserDefaults.standard.set(email, forKey: "email")
                UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")

                self?.navigationController?.dismiss(animated: true, completion: nil)
                
            }
        }
        
        
    }
    //MARK:-loginerrorr func
    func loginerrorr(messege:String = "write all information"){
        let alert = UIAlertController(title: "error",
                                      message:messege ,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "close", style: .cancel, handler: nil))
        self.present(alert,animated: true)
    }
    //MARK:-viewDidLayoutSubviews func
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollview.frame = view.bounds
        let size = scrollview.frame.width / 3
        
        imgView.frame = .init(x:  (scrollview.frame.width - size) / 2,
                              y: 20,
                              width: size,
                              height: size)
        imgView.layer.cornerRadius = imgView.width / 2
        
        firstNameTF.frame = .init(x:30,
                                  y: imgView.bottom + 10,
                                  width: scrollview.width - 60,
                                  height: 52)
        LastNameTF.frame = .init(x:30,
                                 y: firstNameTF.bottom + 10,
                                 width: scrollview.width - 60,
                                 height: 52)
        emailTF.frame = .init(x:30,
                              y: LastNameTF.bottom + 10,
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
    }
    //MARK:-registerTapped func
    @objc private func registerTapped(){
        let vc = RegisterViewController()
        vc.title = "Register"
        vc.view.backgroundColor = .white
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
}
//MARK:-extension:UITextFieldDelegate
extension RegisterViewController:UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTF{
            passwordTF.becomeFirstResponder()
        }else if textField == passwordTF{
            btntapped()
        }else if textField == firstNameTF{
            LastNameTF.becomeFirstResponder()
        }else if textField == LastNameTF{
            emailTF.becomeFirstResponder()
        }
        return true
    }
}
//MARK:-extension:UIImagePickerControllerDelegate,UINavigationControllerDelegate
extension RegisterViewController:UIImagePickerControllerDelegate,UINavigationControllerDelegate{
    func presenrPhotoActionSheet(){
        let actionSheet = UIAlertController(title: "Profile Picture",
                                            message: "How Would you like select a picture?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "close",
                                            style: .cancel,
                                            handler: nil))
        actionSheet.addAction(UIAlertAction(title: "Take a Photo",
                                            style: .default,
                                            handler: {[weak self]_ in
                                                self?.choosePhoto()
        }))
        actionSheet.addAction(UIAlertAction(title: "choose a Photo",
                                            style: .default,
                                            handler: {[weak self]_ in
                                                self?.takePhoto()
                                                
        }))
        present(actionSheet,animated: true)
        
        
    }
    func takePhoto(){
        let vc = UIImagePickerController()
        vc.delegate = self
        vc.sourceType = .camera
        vc.allowsEditing = true
        present(vc,animated: true)
    }
    func choosePhoto(){
        let vc = UIImagePickerController()
        vc.delegate = self
        vc.sourceType = .photoLibrary
        vc.allowsEditing = true
        present(vc,animated: true)
        
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let img = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {
            return
        }
        imgView.image = img
        picker.dismiss(animated: true, completion: nil)
        
    }
}
