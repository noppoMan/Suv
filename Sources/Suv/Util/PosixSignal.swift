//
//  PosixSignal.swift
//  Suv
//
//  Created by Yuki Takei on 8/10/16.
//
//

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

public enum PosixSignal {
    case abrt
    case alrm
    case bus
    case chld
    case cont
    case fpe
    case hup
    case ill
    case int
    case kill
    case pipe
    #if os(Linux)
    case poll
    #endif
    case prof
    case quit
    case segv
    case stop
    case sys
    case term
    case trap
    case tstp
    case ttin
    case ttou
    case usr1
    case usr2
    case urg
    case vtalrm
    case xcup
    case xfsz
}

extension PosixSignal {
    public var value: Int32 {
        #if os(Linux)
            if case .poll = self {
                return SIGPOLL
            }
        #endif
        switch self {
        case .abrt:
            return SIGABRT
        case .alrm:
            return SIGALRM
        case .bus:
            return SIGBUS
        case .chld:
            return SIGCHLD
        case .cont:
            return SIGCONT
        case .fpe:
            return SIGFPE
        case .hup:
            return SIGHUP
        case .ill:
            return SIGILL
        case .int:
            return SIGINT
        case .kill:
            return SIGKILL
        case .pipe:
            return SIGPIPE
        case .prof:
            return SIGPROF
        case .quit:
            return SIGQUIT
        case .segv:
            return SIGSEGV
        case .stop:
            return SIGSTOP
        case .sys:
            return SIGSYS
        case .term:
            return SIGTERM
        case .trap:
            return SIGTRAP
        case .tstp:
            return SIGTSTP
        case .ttin:
            return SIGTTIN
        case .ttou:
            return SIGTTOU
        case .usr1:
            return SIGUSR1
        case .usr2:
            return SIGUSR2
        case .urg:
            return SIGURG
        case .vtalrm:
            return SIGVTALRM
        case .xcup:
            return SIGXCPU
        case .xfsz:
            return SIGXFSZ
        default:
            fatalError("Never be executed")
        }
    }
}
