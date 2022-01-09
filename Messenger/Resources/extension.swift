//
//  extension.swift
//  Messenger
//
//  Created by R on 01/06/1443 AH.
//  Copyright © 1443 R. All rights reserved.
//

import Foundation
import UIKit

extension UIView{
    public var width:CGFloat{
        return self.frame.size.width
    }
    public var height:CGFloat{
        return self.frame.size.height
    }
    public var top:CGFloat{
        return self.frame.origin.y
    }
    public var bottom:CGFloat{
        return self.frame.size.height + self.frame.origin.y
    }
    public var right:CGFloat{
        return self.frame.origin.x + self.frame.size.width
    }
}
