//
//  RunMode.swift
//  SwiftyLibuv
//
//  Created by Yuki Takei on 6/12/16.
//
//

import CLibUv

/**
 Mode used to run the loop with uv_run()
 */
public enum RunMode {
    case runDefault
    case runOnce
    case runNoWait
}

extension RunMode {
    init(mode: uv_run_mode) {
        switch mode {
        case UV_RUN_ONCE: self = .runOnce
        case UV_RUN_NOWAIT: self = .runNoWait
        default: self = .runDefault
        }
    }
    
    public var rawValue: uv_run_mode {
        switch self {
        case .runOnce: return UV_RUN_ONCE
        case .runNoWait: return UV_RUN_NOWAIT
        default: return UV_RUN_DEFAULT
        }
    }
}
