
//  Converter.swift
//  Calculator
//
//  Created by Wilko Zonnenberg on 14-11-16.
//  Copyright © 2016 Wilko Zonnenberg. All rights reserved.
//

import UIKit;

class GraphViewController: UIViewController, GraphingViewDataSource {
    fileprivate struct Constants {
        static let ScaleAndOrigin = "scaleAndOrigin"
    }
    @IBOutlet weak var statsButton: UIBarButtonItem!
    
    @IBOutlet weak var graphView: GraphView! {
        didSet {
            graphView.dataSource = self
            if let scaleAndOrigin = userDefaults.object(forKey: Constants.ScaleAndOrigin) as? [String: String] {
                graphView.scaleAndOrigin = scaleAndOrigin
            }
        }
    }
    
    var stats : String = ""
    
    func setStats(){
        stats  = "minimum-X: \(graphView.minX)\n"
        stats += "maximum-X: \(graphView.maxX)\n"
        stats += "minimum-Y: \(graphView.minY)\n"
        stats += "maximum-Y: \(graphView.maxY)"
    }
    
    @IBAction func statsButtonPressed(_ sender: UIBarButtonItem) {
        setStats()
//        let size = stats.sizeThatFits(CGSize.init(width: CGFloat(MAXFLOAT), height: CGFloat(MAXFLOAT)))
        let message = UIAlertView.init(title: nil, message: stats, delegate: nil, cancelButtonTitle: "Ok")
        message.show()
    }
    
    
    var graphLabel: String? {
        didSet {
            title = graphLabel
        }
    }
    
    var program: AnyObject?

    let userDefaults = UserDefaults.standard
    
    func graphPlot(_ sender: GraphView) -> [(x: Double, y: Double)]? {
        let minDegree = Double(sender.minX) * (180 / M_PI)
        let maxDegree = Double(sender.maxX) * (180 / M_PI)
        
        var plots = [(x: Double, y: Double)]()
        let calculator = Calculator()
        
        if let program = program {
            calculator.program = program
            
            plots = createPlots(calculator: calculator, plotsArray: plots, minDegree: minDegree, maxDegree: maxDegree, availablePixels: sender.availablePixelsInXAxis)
            
        }
        
        return plots
    }
    
    func createPlots(calculator : Calculator, plotsArray : [(x: Double, y: Double)], minDegree : Double, maxDegree : Double, availablePixels : Double) -> [(x: Double, y: Double)]{
        var plots = plotsArray
        let loopIncrementSize = (maxDegree - minDegree) / availablePixels
        var i = minDegree;
        while ( i <= maxDegree){
            calculator.variableValues["M"] = Double(i) * (M_PI / 180)
            let evaluationResult = calculator.evaluateAndReportErrors()
            switch evaluationResult {
            case let .Success(y):
                if y.isNormal || y.isZero {
                    plots.append((x: calculator.variableValues["M"]!, y: y))
                }
            default: break
            }
            i = i + loopIncrementSize;
        }
        return plots
    }
    
    @IBAction func zoomGraph(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .changed {
            graphView.scale *= gesture.scale
            
            // save the scale
            saveScaleAndOrigin()
            gesture.scale = 1
        }
    }
    
    @IBAction func moveGraph(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .ended: fallthrough
        case .changed:
            let translation = gesture.translation(in: graphView)

            if graphView.graphOrigin == nil {
                graphView.graphOrigin = CGPoint(x: graphView.center.x + translation.x, y: graphView.center.y + translation.y)
            } else {
                graphView.graphOrigin = CGPoint(x: graphView.graphOrigin!.x + translation.x, y: graphView.graphOrigin!.y + translation.y)
            }
            
            saveScaleAndOrigin()
            
            gesture.setTranslation(CGPoint.zero, in: graphView)
        default: break
        }
    }
    
    @IBAction func moveOrigin(_ gesture: UITapGestureRecognizer) {
        switch gesture.state {
        case .ended:
            graphView.graphOrigin = gesture.location(in: view)
            saveScaleAndOrigin()
        default: break
        }
    }
    
    fileprivate func saveScaleAndOrigin() {
        userDefaults.set(graphView.scaleAndOrigin, forKey: Constants.ScaleAndOrigin)
        userDefaults.synchronize()
    }
    

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        var x: CGFloat = 0
        var y: CGFloat = 0
        if let graphOrigin = graphView.graphOrigin {
            x = graphView.center.x - graphOrigin.x
            y = graphView.center.y - graphOrigin.y
        }
        
        let widthBeforeRotation = graphView.bounds.width
        let heightBeforeRotation = graphView.bounds.height
        
        coordinator.animate(alongsideTransition: nil) { context in
            
            let widthAfterRotation = self.graphView.bounds.width
            let heightAfterRotation = self.graphView.bounds.height
            
            let widthChangeRatio = widthAfterRotation / widthBeforeRotation
            let heightChangeRatio = heightAfterRotation / heightBeforeRotation

            self.graphView.graphOrigin = CGPoint(
                x: self.graphView.center.x - (x * widthChangeRatio),
                y: self.graphView.center.y - (y * heightChangeRatio)
            )
        }
    }
}
