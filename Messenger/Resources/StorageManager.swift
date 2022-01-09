//
//  StorageManager.swift
//  Messenger
//
//  Created by R on 02/06/1443 AH.
//  Copyright © 1443 R. All rights reserved.
//

import Foundation
import FirebaseStorage

final class StorageManager{
    static let shared = StorageManager()
    private let storage = Storage.storage().reference()
    public typealias uploudPicComplition = (Result<String,Error>)->Void
    //MARK: - uploudProfilPic func
    public func uploudProfilPic(with data:Data,filename:String,complition:@escaping uploudPicComplition){
        print("uploudProfilPic func")
        storage.child("\(filename)").putData(data, metadata: nil) { (metadata, err) in
            guard err == nil else {
                print("storageError.faildToUploud")
                complition(.failure(storageError.faildToUploud))
                return
            }
            self.storage.child("\(filename)").downloadURL { (url, err) in
                guard let url = url else  {
                    print("storageError.faildToDownloadURl")
                    complition(.failure(storageError.faildToDownloadURl))
                    return
                }
                let urltString = url.absoluteString
                print(urltString)
                complition(.success(urltString))
            }
        }
    }
    //MARK: - downloadURl func
    func downloadURl(path:String, complition:@escaping(Result<URL,Error>)->Void){
        print("downloadURl func")
        let refference = storage.child(path)
        refference.downloadURL { (url, err) in
            guard let url = url ,err == nil else {
                print("downloadURlfunc err ")
                complition(.failure(storageError.faildToDownloadURl))
                return
            }
            complition(.success(url))
        }
    }
}
//MARK: - storageError enum
public enum storageError:Error{
    case faildToUploud
    case faildToDownloadURl
    
}

