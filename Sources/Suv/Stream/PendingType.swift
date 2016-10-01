//
//  PendingType.swift
//  SwiftyLibuv
//
//  Created by Yuki Takei on 6/12/16.
//
//

import CLibUv

public enum PendingType {
    case tcp
    case udp
    case namedPipe
    case stream
    case tty
}

extension PendingType {
    var rawValue: uv_handle_type {
        switch self {
        case .tcp:
            return UV_TCP
        case .udp:
            return UV_UDP
        case .namedPipe:
            return UV_NAMED_PIPE
        case .stream:
            return UV_STREAM
        case .tty:
            return UV_TTY
        }
    }
}

