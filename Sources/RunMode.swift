//
//  RunModel.swift
//  Suv
//
//  Created by Yuki Takei on 1/13/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import CLibUv

/**
 Mode used to run the loop with uv_run()
 */
public enum RunMode {
    case Default
    case Once
    case NoWait
}

extension RunMode {
    init(mode: uv_run_mode) {
        switch mode {
        case UV_RUN_ONCE: self = .Once
        case UV_RUN_NOWAIT: self = .NoWait
        default: self = .Default
        }
    }
    
    public var rawValue: uv_run_mode {
        switch self {
        case .Once: return UV_RUN_ONCE
        case .NoWait: return UV_RUN_NOWAIT
        default: return UV_RUN_DEFAULT
        }
    }
}
