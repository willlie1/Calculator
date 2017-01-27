//
//  GraphView.swift
//  Calculator
//
//  Created by Wilko Zonnenberg on 14-11-16.
//  Copyright © 2016 Wilko Zonnenberg. All rights reserved.
//

import UIKit

protocol GraphingViewDataSource: class {
    func graphPlot(_ sender: GraphView) -> [(x: Double, y: Double)]?
}

class GraphView: UIView {
    weak var dataSource: GraphingViewDataSource?
    
    @IBInspectable var color: UIColor = UIColor.blue { didSet { setNeedsDisplay() } }
    @IBInspectable var lineColor: UIColor = UIColor.red  { didSet { setNeedsDisplay() } }
    @IBInspectable var scale: CGFloat = 1.0                     { didSet { setNeedsDisplay() } }
    @IBInspectable var graphOrigin: CGPoint?                    { didSet { setNeedsDisplay() } }
    
    let unitPoints: CGFloat = 50.0
    
    var minX: CGFloat{
        get{
            let minXBound = -(bounds.width - (bounds.width - graphCenter.x))
            return minXBound / (unitPoints * scale)
        }
    }
    
    var minY: CGFloat {
        get{
            let minYBound = -(bounds.height - graphCenter.y)
            return minYBound / (unitPoints * scale)
        }
    }
    var maxX: CGFloat {
        get{
            let maxXBound = bounds.width - graphCenter.x
            return maxXBound / (unitPoints * scale)
        }
    }
    
    var maxY: CGFloat {
        get{
            let maxYBound = bounds.height - (bounds.height - graphCenter.y)
            return maxYBound / (unitPoints * scale)
        }
    }
    var availablePixelsInXAxis: Double {
        get{
            return Double(bounds.width * contentScaleFactor)
        }
    }
    
    var graphCenter: CGPoint {
        get{
            if graphOrigin == nil {
                return convert(center, from: superview)
            }
            return convert(graphOrigin!, from: superview)
        }
    }
    
    typealias PropertyList = [String: String]
    var scaleAndOrigin: PropertyList {
        get {
            let origin = (graphOrigin != nil) ? graphOrigin! : center
            return [
                "scale": "\(scale)",
                "originX": "\(origin.x)",
                "originY": "\(origin.y)"
            ]
        }
        set {
            if let scale = newValue["scale"], let graphOriginX = newValue["originX"], let graphOriginY = newValue["originY"] {
                if let scale = NumberFormatter().number(from: scale) {
                    self.scale = CGFloat(scale)
                }
                if let graphOriginX = NumberFormatter().number(from: graphOriginX), let graphOriginY = NumberFormatter().number(from: graphOriginY) {
                    self.graphOrigin = CGPoint(x: CGFloat(graphOriginX), y: CGFloat(graphOriginY))
                }                
            }
        }
    }
    
    
    func translatePlot(plot: (x: Double, y: Double)) -> CGPoint {
        let translatedX = CGFloat(plot.x) * unitPoints * scale + graphCenter.x
        let translatedY = CGFloat(-plot.y) * unitPoints * scale + graphCenter.y
        return CGPoint(x: translatedX, y: translatedY)
    }
    
    override func draw(_ rect: CGRect) {
        let axes = AxesDrawer(color: color, contentScaleFactor: scale)
        axes.drawAxesInRect(bounds: bounds, origin: graphCenter, pointsPerUnit: unitPoints*scale)
        
        let bezierPath = UIBezierPath()
        
        if var plots = dataSource?.graphPlot(self) {
            if plots.first != nil{
                bezierPath.move(to: translatePlot(plot: (x: plots.first!.x, y: plots.first!.y)))
                plots.removeFirst()
                for plot in plots {
                    bezierPath.addLine(to: translatePlot(plot: (x: plot.x, y: plot.y)))
                }
            }
        }
        
        lineColor.set()
        bezierPath.stroke()
        
    }

}
