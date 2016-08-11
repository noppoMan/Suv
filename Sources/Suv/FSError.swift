//
//  FSError.swift
//  Suv
//
//  Created by Yuki Takei on 6/12/16.
//
//

public enum FSError: Error {
    case invalidPosition(Int)
    case fileDescriptorIsEmpty
    case alreadyOpend
}
