//
//  StreamError.swift
//  Slimane
//
//  Created by Yuki Takei on 8/12/16.
//
//

public enum StreamError: Error {
    case eof
    case noPendingCount
    case pendingTypeIsMismatched
}
