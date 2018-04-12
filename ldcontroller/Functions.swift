//
//  Functions.swift
//  ldcontroller
//
//  Created by patrick on 2018/4/11.
//  Copyright © 2018 许程鹏. All rights reserved.
//

import Foundation
    
let applicationDocumentsDirectory: URL = {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
}()

