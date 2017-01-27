//
//  Calculator.swift
//  Calculator
//
//  Created by Wilko Zonnenberg on 19-09-16.
//  Copyright © 2016 Wilko Zonnenberg. All rights reserved.
//

import Foundation

class Calculator {
    
    enum CalculatorResult {
        case Success(Double)
        case Failure(String)
    }

    
    enum Op: CustomDebugStringConvertible {
        case Operand(Double)
        case Variable(String)
        case Constant(String, Double)
        case UnaryOperation(String, (Double) -> Double)
        case BinaryOperation(String, (Double, Double) -> Double)
        
        var description: String{
            get {
                switch self {
                case .Operand(let operand):
                    let intValue = Int(operand)
                    if Double(intValue) == operand {
                        return "\(intValue)"
                    } else {
                        return "\(operand)"
                    }
                case .BinaryOperation(let symbol, _):
                    return symbol
                case .UnaryOperation(let symbol, _):
                    return symbol
                case .Variable(let symbol):
                    return "\(symbol)"
                case .Constant(let symbol, _):
                    return "\(symbol)"

                }
            }
        }
        
        var precedence: Int {
            switch self {
                case .Operand(_), .Variable(_), .Constant(_, _), .UnaryOperation(_, _):
                    return Int.max
                case .BinaryOperation(_, _):
                    return Int.min
            }
        }
        
        var debugDescription: String{
            get {
                switch self {
                case .Operand(let operand):
                    return "\(operand)"
                case .BinaryOperation(let symbol, _):
                    return symbol
                case .UnaryOperation(let symbol, _):
                    return symbol
                default:
                    return ""
                }
            }
        }
    }
    
    
    private var opStack = [Op]()
    private var error: String?
    var variableValues = [String:Double]()
    
    private var knownOps = [String:Op]()
    
    init() {
        knownOps["×"] = Op.BinaryOperation("×", *)
        knownOps["÷"] = Op.BinaryOperation("÷") { $1 / $0 }
        knownOps["+"] = Op.BinaryOperation("+", +)
        knownOps["-"] = Op.BinaryOperation("-") { $1 - $0 }
        knownOps["√"] = Op.UnaryOperation("√", sqrt)
        knownOps["Sin"] = Op.UnaryOperation("Sin", sin)
        knownOps["Cos"] = Op.UnaryOperation("Cos", cos)
        knownOps["ᐩ/-"] = Op.UnaryOperation("ᐩ/-") {$0 * -1}
        knownOps["π"] = Op.Constant("π", Double.pi)
    }
    
    typealias PropertyList = AnyObject
    var program: PropertyList {
        get{
            var returnValue = Array<String>()
            for op in opStack {
                returnValue.append(op.description)
            }
            return returnValue as Calculator.PropertyList
        }
        set{
            if let opSymbols = newValue as? Array<String> {
                var newOpStack = [Op]()
                for opSymbol in opSymbols{
                    if let op = knownOps[opSymbol]{
                        newOpStack.append(op)
                    } else if let operand = NumberFormatter().number(from: opSymbol)?.doubleValue{
                        newOpStack.append(.Operand(operand))
                    }else{
                        newOpStack.append(.Variable(opSymbol))
                    }
                }
                opStack = newOpStack
            }
        }
    }
    
    
    func evaluate(ops: [Op]) -> (result: Double?, remainingOps: [Op]) {
        if !ops.isEmpty {
            var remainingOps = ops
            let op = remainingOps.removeLast()
            switch op {
            case .Variable(let symbol):
                if let variableValue = variableValues[symbol] {
                    return (variableValue, remainingOps)
                } else {
                    error = "\(symbol) is not set."
                    return (nil, remainingOps)
                }
            case .Operand(let operand):
                return (operand, remainingOps)
            case .UnaryOperation(_, let operation):
                let operandEvaluation = evaluate(ops: remainingOps)
                if let operand = operandEvaluation.result {
                    return (operation(operand), operandEvaluation.remainingOps)
                } else{
                    error = "Unary operand missing."
                }
            case .BinaryOperation(_, let operation):
                let op1Evaluation = evaluate(ops: remainingOps)
                if let operand1 = op1Evaluation.result{
                    remainingOps.removeLast()
                    let op2Evaluation = evaluate(ops: remainingOps)
                    if let operand2 = op2Evaluation.result {
                        return (operation(operand1, operand2), op2Evaluation.remainingOps)
                    }else{
                        error = "Binary operand missing."
                    }
                }else{
                    error = "Binary operand missing."
                }
            case .Constant(_, let constant):
                return (constant, remainingOps)
            }
        }
        
        return (nil, ops)
    }
    
    func evaluate() -> Double? {
        let (result, _) = evaluate(ops: opStack)
//        print("\(opStack) = \(result) with \(remainder) left over")
        return result
        
    }
    
    func lastOpIsNotAnOperation() -> Bool {
        var ops = opStack
        switch ops.removeLast() {
        case .Operand( _):
            return true;
        case .Variable(_):
            return true;
        default:
            return false;
        }
    }
    
    func pushOperand(operand: Double) -> CalculatorResult?{
        opStack.append(Op.Operand(operand))
        return evaluateAndReportErrors()
    }
    
    func performOperation(symbol: String) -> CalculatorResult? {
        if let operation = knownOps[symbol] {
            opStack.append(operation)
        }
        return evaluateAndReportErrors()
    }
    
    
    func pushOperand(symbol: String) -> CalculatorResult? {
        opStack.append(Op.Variable(symbol))
        return evaluateAndReportErrors()
    }
    
    func pushConstant(symbol: String) -> CalculatorResult? {
        if let constant = knownOps[symbol] {
            opStack.append(constant)
        }
        return evaluateAndReportErrors()
    }
    
    func evaluateAndReportErrors() -> CalculatorResult {
        if let result = evaluate() {
            if result.isNaN {
                return CalculatorResult.Failure("Insert a Number")
            } else if result.isInfinite {
                return CalculatorResult.Failure("Infinite value")
            } else {
                return CalculatorResult.Success(result)
            }
        } else {
            if let returnError = error {
                return CalculatorResult.Failure(returnError)
            } else {
                return CalculatorResult.Failure("Error")
            }
        }
    }
    
    func getHistoryString() -> String {
        var history = opStack
        var historyString = ""
        while history.count > 0 {
            let operand = history.removeFirst()
            var operandString = "\(operand)"
            if let number = Double(operandString){
               operandString = " \(Converter.doubleToString(double: number))"
            }
            historyString = historyString + operandString
        }
        return historyString
    }
    
    var description: [String] {
        let (descriptionArray, _) = getDescription(currentDescription: [String](), ops: opStack)
        return descriptionArray
    }
    
    private func getDescription(currentDescription: [String], ops: [Op]) -> (description: [String], remainingOps: [Op]) {
        var description = currentDescription
        if !ops.isEmpty {
            var remainingOps = ops
            let op = remainingOps.removeFirst()
            switch op {
            case .Operand(_), .Variable(_), .Constant(_, _):
                description.append(op.description)
                return getDescription(currentDescription: description, ops: remainingOps)
            case .UnaryOperation(let symbol, _):
                if !description.isEmpty {
                    let unaryOperand = description.removeLast()
                    description.append(symbol + "(\(unaryOperand))")
                    return getDescription(currentDescription: description, ops: remainingOps)
                }
            case .BinaryOperation(let symbol, _):
                if !description.isEmpty {
                    let binaryOperandLast = description.removeLast()
                    if !description.isEmpty {
                        let binaryOperandFirst = description.removeLast()
                        if op.description == remainingOps.first?.description || op.precedence == remainingOps.first?.precedence {
                            description.append("(\(binaryOperandFirst)" + symbol + "\(binaryOperandLast))")
                        } else {
                            description.append("\(binaryOperandFirst)" + symbol + "\(binaryOperandLast)")
                        }
                        return getDescription(currentDescription: description, ops: remainingOps)
                    } else {
                        description.append("?" + symbol + "\(binaryOperandLast)")
                        return getDescription(currentDescription: description, ops: remainingOps)
                    }
                } else {
                    description.append("/??" + symbol + "??\\")
                    return getDescription(currentDescription: description, ops: remainingOps)
                }
            }
        }
        return (description, ops)
    }
    
    
    func clear() -> Double?{
        opStack.removeAll()
//        memoryValue = nil
        return evaluate()
    }
}
