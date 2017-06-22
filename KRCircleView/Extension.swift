//
//  Extension.swift
//  KRCircleView
//
//  Created by Рамиз Кичибеков on 22.06.2017.
//  Copyright © 2017 Рамиз Кичибеков. All rights reserved.
//

extension KRCircleView {
    @discardableResult
    public func fromNib<T : KRCircleView>() -> T? {
        guard let view = Bundle.main.loadNibNamed(String(describing: type(of: self)), owner: self, options: nil)?.first as? T else {
            return nil
        }
        addSubview(view)
        view.layoutAttachAll(To: self)
        return view
    }
    
    private func layoutAttachAll(To view:UIView ) {
        translatesAutoresizingMaskIntoConstraints = false
        topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    }
}

extension Float {
    public func formatWithFractionDigits(_ fractionDigits: Int, customDecimalSeparator: String? = nil) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = fractionDigits
        numberFormatter.minimumFractionDigits = fractionDigits
        numberFormatter.decimalSeparator = customDecimalSeparator ?? numberFormatter.decimalSeparator
        
        return  numberFormatter.string(from: NSNumber(value: self)) ?? ""
    }
}

extension String {
    public func toFloat(_ localeIdentifier: String? = nil) -> Float {
        let locale = localeIdentifier != nil ?  Locale(identifier: localeIdentifier!) : Locale.current
        
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = locale
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.roundingMode = .down
        
        return numberFormatter.number(from: self)?.floatValue ?? 0
    }
    
    func sliderAttributeString(customDecimalSeparator: String? = nil) -> NSAttributedString {
        guard self != "" else { return NSAttributedString(string: "") }
        
        let locale = Locale.current
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = locale
        numberFormatter.decimalSeparator = customDecimalSeparator ?? numberFormatter.decimalSeparator
        
        let numberComponents = components(separatedBy: numberFormatter.decimalSeparator)
        
        let attributeString = NSMutableAttributedString()
        var integerStr = numberComponents[0]
        
        var decimalStr = ""
        if numberComponents.count > 1 {
            integerStr += numberFormatter.decimalSeparator
            decimalStr =  numberComponents[1]
        }
        
        let integer = NSMutableAttributedString(string: integerStr)
        let decimal = NSMutableAttributedString(string: decimalStr)
        
        integer.addAttributes([NSFontAttributeName: UIFont.systemFont(ofSize: 42)],
                              range: NSMakeRange(0, integer.length))
        decimal.addAttributes([NSFontAttributeName: UIFont.systemFont(ofSize: 42)],
                              range: NSMakeRange(0, decimal.length))
        
        
        attributeString.append(integer)
        attributeString.append(decimal)
        
        return attributeString
    }
}
