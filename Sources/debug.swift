//
//  uv.swift
//  Suv
//
//  Created by Yuki Takei on 1/11/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

// should use preprosessor
let MODE_IS_DEBUG = false

func debug<T>(val: T){
    if(MODE_IS_DEBUG) {
        print(val)
    }
}
