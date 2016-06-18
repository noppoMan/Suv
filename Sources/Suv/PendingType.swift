//
//  PendingType.swift
//  Suv
//
//  Created by Yuki Takei on 6/12/16.
//
//

import CLibUv

public enum PendingType {
    case tcp
    case udp
    case pipe
}

extension PendingType {
    var rawValue: uv_handle_type {
        switch self {
        case .tcp:
            return UV_TCP
        case .udp:
            return UV_UDP
        default:
            return UV_STREAM
        }
    }
}
