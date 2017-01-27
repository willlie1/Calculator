//
//  Converter.swift
//  Calculator
//
//  Created by Wilko Zonnenberg on 19-09-16.
//  Copyright © 2016 Wilko Zonnenberg. All rights reserved.
//

import Foundation

class Converter {
    
    static func doubleToString (double : Double) -> String{
        return (double.truncatingRemainder(dividingBy: 1)  == 0 ? String(format: "%.0f", double) : String(double))
    }
}
