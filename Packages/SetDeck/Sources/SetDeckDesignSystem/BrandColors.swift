//
//  BrandColors.swift
//  SetDeckDesignSystem
//
//  The brand palette, defined in code (the app's asset catalog isn't visible to package
//  modules). Values match the original Assets.xcassets colorsets exactly. Available both
//  as `Color.greenStart` members and in `.foregroundStyle(.greenStart)` positions.
//

import SwiftUI

extension Color {
    public static let greenStart = Color(red: 0x65 / 255, green: 0xDA / 255, blue: 0x92 / 255)
    public static let greenEnd = Color(red: 0x22 / 255, green: 0x52 / 255, blue: 0x1F / 255)
    public static let blueStart = Color(red: 0x66 / 255, green: 0xAC / 255, blue: 0xF3 / 255)
    public static let blueEnd = Color(red: 0x11 / 255, green: 0x30 / 255, blue: 0x54 / 255)
    public static let purpleStart = Color(red: 0xB2 / 255, green: 0x60 / 255, blue: 0xEA / 255)
    public static let purpleEnd = Color(red: 0x8C / 255, green: 0x26 / 255, blue: 0x8F / 255)
    public static let orangeStart = Color(red: 0xED / 255, green: 0x9C / 255, blue: 0x4E / 255)
    public static let orangeEnd = Color(red: 0x8F / 255, green: 0x2F / 255, blue: 0x15 / 255)
}

extension ShapeStyle where Self == Color {
    public static var greenStart: Color { Color.greenStart }
    public static var greenEnd: Color { Color.greenEnd }
    public static var blueStart: Color { Color.blueStart }
    public static var blueEnd: Color { Color.blueEnd }
    public static var purpleStart: Color { Color.purpleStart }
    public static var purpleEnd: Color { Color.purpleEnd }
    public static var orangeStart: Color { Color.orangeStart }
    public static var orangeEnd: Color { Color.orangeEnd }
}
