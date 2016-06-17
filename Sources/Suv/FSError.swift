//
//  FSError.swift
//  Suv
//
//  Created by Yuki Takei on 6/12/16.
//
//

public enum FSError: ErrorProtocol {
    case InvalidPosition(Int)
    case FileDescriptorIsEmpty
    case AlreadyOpend
}
