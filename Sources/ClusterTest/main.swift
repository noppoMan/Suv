//
//  main.swift
//  Suv
//
//  Created by Yuki Takei on 6/12/16.
//
//

import Suv

if Cluster.isWorker {
    Process.onIPC { ev in
        if case .message(let message) = ev {
            var i = Int("\(message)")!
            i+=1
            Process.send(.message("\(i)"))
        }
    }
    Loop.defaultLoop.run()
}


