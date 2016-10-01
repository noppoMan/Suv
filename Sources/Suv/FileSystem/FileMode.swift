#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

public enum FileMode {
    case read
    case createWrite
    case truncateWrite
    case appendWrite
    case readWrite
    case createReadWrite
    case truncateReadWrite
    case appendReadWrite
}

extension FileMode {
    var value: Int32 {
        switch self {
        case .read: return O_RDONLY
        case .createWrite: return (O_WRONLY | O_CREAT | O_EXCL)
        case .truncateWrite: return (O_WRONLY | O_CREAT | O_TRUNC)
        case .appendWrite: return (O_WRONLY | O_CREAT | O_APPEND)
        case .readWrite: return (O_RDWR)
        case .createReadWrite: return (O_RDWR | O_CREAT | O_EXCL)
        case .truncateReadWrite: return (O_RDWR | O_CREAT | O_TRUNC)
        case .appendReadWrite: return (O_RDWR | O_CREAT | O_APPEND)
        }
    }
}

extension FileMode {
    public var defaultPermission: Int32 {
        switch(self) {
        case .read:
            return 0
        case .readWrite:
            return 0
        case .createWrite:
            return 0o666
        case .truncateWrite:
            return 0o666
        case .createReadWrite:
            return 0o666
        case .appendWrite:
            return 0o666
        case .truncateReadWrite:
            return 0o666
        case .appendReadWrite:
            return 0o666
        }
    }
}
