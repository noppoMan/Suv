//
//  Result.swift
//  Suv
//
//  Created by Yuki Takei on 2/18/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

/**
 Either enum for retruning processing Result
 */
public enum Result {
    /**
     Will be called when processing is succeeded
    */
    case Success
    
    /**
     Will be called when processing is failed
     */
    case Error(ErrorType)
}

/**
 Either enum for retruning processing Result with Generic value
 */
public enum GenericResult<T> {
    /**
     Will be called when processing is succeeded
     */
    case Success(T)
    
    /**
     Will be called when processing is failed
     */
    case Error(ErrorType)
}