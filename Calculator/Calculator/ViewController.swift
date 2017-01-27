//
//  ViewController.swift
//  Calculator
//
//  Created by Wilko Zonnenberg on 15-09-16.
//  Copyright © 2016 Wilko Zonnenberg. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var display: UILabel!
    @IBOutlet weak var historyDisplay: UILabel!
    
    var userIsTyping = false
    
    var calculator = Calculator()
    
    
    @IBAction func appendDigit(sender: UIButton) {
        let digit = sender.currentTitle!
        if userIsTyping {
            switch digit {
            case "π":
                performOperation(operation: digit)
            default:
                setDisplay(displayText:display.text! + digit)
            }
        } else {
            switch digit {
            case "π":
                setDisplay(displayText:"\(Double.pi)")
            default:
                setDisplay(displayText:digit)
                userIsTyping = true
            }
        }
    }
    
    @IBAction func backspace() {
        if userIsTyping && (display.text?.characters.count)! > 1 {
            let displayString = display.text!
            display.text = String(displayString.characters.dropLast())
        } else {
            setDisplay(displayText:"0")
            userIsTyping = false
        }
    
    }
    
    @IBAction func enterPointButtonPressed() {
        if ((display.text?.range(of: ".")) == nil) {
            setDisplay(displayText:display.text! + ".")
        }
    }
    
    @IBAction func enter() {
        userIsTyping = false
        displayResult = calculator.pushOperand(operand: displayValue!)

    }
    
    var displayResult: Calculator.CalculatorResult? {
        get {
            if let displayValue = displayValue {
                return .Success(displayValue)
            }
            if display.text != nil {
                return .Failure(display.text!)
            }
            return .Failure("Error")
        }
        set {
            userIsTyping = false

            if newValue != nil {
                switch newValue! {
                case let .Success(displayValue):
                    display.text = "\(displayValue)"
                case let .Failure(error):
                    display.text = error
                }
            } else {
                display.text = "Error"
            }
        
            if !calculator.description.isEmpty{
                setHistoryDisplay()
            } else{
                historyDisplay.text = " "
            }

        }
    }
    
    func setHistoryDisplay(){
        historyDisplay.text = calculator.description.joined(separator: ", ")
    }
    
    func displayResult(result: Double){
        displayValue = result
        setDisplay(displayText:"= \(result)")
        setHistoryDisplay()
    }
    
    @IBAction func operate(sender: UIButton) {
        if userIsTyping {
            enter()
        }
        if let operation = sender.currentTitle  {
            performOperation(operation: operation)
        }
        
    }
    
    func performOperation(operation: String) {
        if let result = calculator.performOperation(symbol: operation) {
            displayResult = result
        } else {
            displayValue = 0
        }
    }
    
    @IBAction func clearCalculator() {
        if !(calculator.clear() != nil) {
            userIsTyping = false
            setDisplay(displayText:"0")
            historyDisplay.text = " "
        }
    }
    @IBAction func setMemory(_ sender: AnyObject) {
        userIsTyping = false
        if displayValue != nil {
            calculator.variableValues["M"] = displayValue!
        }
        displayResult = calculator.evaluateAndReportErrors()
    }
    
    @IBAction func getMemory(_ sender: UIButton) {
        if userIsTyping{ enter()}
        
        displayResult = calculator.pushOperand(symbol: sender.currentTitle!)

    }
    
    
    func setDisplay(displayText: String){
        display.text = displayText
    }
    
    var displayValue: Double?{
        get{
            let stringWithOnlyNumbers = display.text!.replacingOccurrences(of: "= ", with: "")
            return NumberFormatter().number(from: stringWithOnlyNumbers)!.doubleValue
 
        }
        set{
            setDisplay(displayText:"\(Converter.doubleToString(double: newValue!))")
            userIsTyping = false
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier  = segue.identifier{
            switch identifier {
            case "Graph Segue":
                if let vc = segue.destination as? GraphViewController{
                    vc.program = calculator.program
                    vc.graphLabel = calculator.description.last
                }
            default:
                break;
            }
        }
    }

}

