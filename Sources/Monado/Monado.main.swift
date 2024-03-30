//
//  File.swift
//  
//
//  Created by Colbyn Wadman on 3/28/24.
//

import Foundation

public struct Monado {
    public static func main() {
        let source1 = """
        Hello World!
        """
        let tape = Tape(from: source1)
        print("TAPE:", tape.split(prefix: "Hello")!)
    }
}
