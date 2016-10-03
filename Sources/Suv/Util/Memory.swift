//
//  Memory.swift
//  SwiftyLibuv
//
//  Created by Yuki Takei on 8/9/16.
//
//

extension UnsafeMutablePointer {
    func cast<T>(to type: UnsafePointer<T>.Type) -> UnsafePointer<T> {
        return unsafeBitCast(self, to: type)
    }
    
    func cast<T>(to type: UnsafeMutablePointer<T>.Type) -> UnsafeMutablePointer<T> {
        return unsafeBitCast(self, to: type)
    }
}

func dealloc(_ ponter: UnsafeMutableRawPointer, capacity: Int){
    ponter.deallocate(bytes: capacity, alignedTo: capacity)
}


func dealloc<T>(_ ponter: UnsafeMutablePointer<T>, capacity: Int? = nil){
    ponter.deinitialize()
    ponter.deallocate(capacity: capacity ?? MemoryLayout<T>.size)
}

final class Box<A> {
    let unbox: A
    init(_ value: A) { unbox = value }
}

func retainedRawPointer<A>(_ x: A) -> UnsafeMutableRawPointer {
    return Unmanaged.passRetained(Box(x)).toOpaque()
}

func unretainedRawPointer<A>(_ x: A) -> UnsafeMutableRawPointer {
    return Unmanaged.passUnretained(Box(x)).toOpaque()
}

//func releaseRetainedPointer<A>(_ x: A) {
//    Unmanaged.passUnretained(Box(x)).release()
//}

func releaseRawPointer<A>(_ x: UnsafeMutableRawPointer) -> A {
    return Unmanaged<Box<A>>.fromOpaque(x).takeRetainedValue().unbox
}

func unsafeFromRawPointer<A>(_ x: UnsafeMutableRawPointer) -> A {
    return Unmanaged<Box<A>>.fromOpaque(x).takeUnretainedValue().unbox
}
