//
//  main.swift
//  Suv
//
//  Created by Yuki Takei on 2/13/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

#if os(Linux)
    import Glibc
    
    import XCTest
        
    XCTMain([
        CryptoTests()
    ])
#endif
