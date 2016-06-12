//
//  PendingType.swift
//  Suv
//
//  Created by Yuki Takei on 6/12/16.
//
//

import CLibUv

public enum PendingType {
    case TCP
    case UDP
    case Pipe
}

extension PendingType {
    var rawValue: uv_handle_type {
        switch self {
        case .TCP:
            return UV_TCP
        case .UDP:
            return UV_UDP
        default:
            return UV_STREAM
        }
    }
}
