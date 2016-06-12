//
//  main.swift
//  Suv
//
//  Created by Yuki Takei on 6/12/16.
//
//

import Suv

if Cluster.isWorker {
    Process.on { ev in
        if case .Message(let message) = ev {
            var i = Int("\(message)")!
            i+=1
            Process.send(.Message("\(i)"))
        }
    }
    Loop.defaultLoop.run()
}


