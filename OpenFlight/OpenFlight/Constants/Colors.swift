// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

#if os(OSX)
  import AppKit.NSColor
  public typealias Color = NSColor
#elseif os(iOS) || os(tvOS) || os(watchOS)
  import UIKit.UIColor
  public typealias Color = UIColor
#endif

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Colors

// swiftlint:disable identifier_name line_length type_body_length
public struct ColorName {
  public let rgbaValue: UInt32
  public var color: Color { return Color(named: self) }

  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#000000"></span>
  /// Alpha: 100% <br/> (0x000000ff)
  public static let black = ColorName(rgbaValue: 0x000000ff)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#000000"></span>
  /// Alpha: 40% <br/> (0x00000066)
  public static let black40 = ColorName(rgbaValue: 0x00000066)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#000000"></span>
  /// Alpha: 60% <br/> (0x00000099)
  public static let black60 = ColorName(rgbaValue: 0x00000099)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#000000"></span>
  /// Alpha: 80% <br/> (0x000000cc)
  public static let black80 = ColorName(rgbaValue: 0x000000cc)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#00b7ff"></span>
  /// Alpha: 100% <br/> (0x00b7ffff)
  public static let blueDodger = ColorName(rgbaValue: 0x00b7ffff)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#00b7ff"></span>
  /// Alpha: 50% <br/> (0x00b7ff80)
  public static let blueDodger50 = ColorName(rgbaValue: 0x00b7ff80)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#000000"></span>
  /// Alpha: 0% <br/> (0x00000000)
  public static let clear = ColorName(rgbaValue: 0x00000000)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#f8d000"></span>
  /// Alpha: 100% <br/> (0xf8d000ff)
  public static let gold = ColorName(rgbaValue: 0xf8d000ff)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#00a157"></span>
  /// Alpha: 100% <br/> (0x00a157ff)
  public static let greenHaze = ColorName(rgbaValue: 0x00a157ff)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#1a513d"></span>
  /// Alpha: 100% <br/> (0x1a513dff)
  public static let greenPea = ColorName(rgbaValue: 0x1a513dff)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#1a513d"></span>
  /// Alpha: 50% <br/> (0x1a513d80)
  public static let greenPea50 = ColorName(rgbaValue: 0x1a513d80)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#00ff8a"></span>
  /// Alpha: 100% <br/> (0x00ff8aff)
  public static let greenSpring = ColorName(rgbaValue: 0x00ff8aff)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#00ff8a"></span>
  /// Alpha: 20% <br/> (0x00ff8a33)
  public static let greenSpring20 = ColorName(rgbaValue: 0x00ff8a33)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#48494b"></span>
  /// Alpha: 100% <br/> (0x48494bff)
  public static let greyDark = ColorName(rgbaValue: 0x48494bff)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#48494b"></span>
  /// Alpha: 60% <br/> (0x48494b99)
  public static let greyDark60 = ColorName(rgbaValue: 0x48494b99)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#1a1c1e"></span>
  /// Alpha: 100% <br/> (0x1a1c1eff)
  public static let greyShark = ColorName(rgbaValue: 0x1a1c1eff)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#bebebe"></span>
  /// Alpha: 100% <br/> (0xbebebeff)
  public static let greySilver = ColorName(rgbaValue: 0xbebebeff)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#ff9900"></span>
  /// Alpha: 100% <br/> (0xff9900ff)
  public static let orangePeel = ColorName(rgbaValue: 0xff9900ff)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#ff9b00"></span>
  /// Alpha: 20% <br/> (0xff9b0033)
  public static let orangePeel20 = ColorName(rgbaValue: 0xff9b0033)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#ff9b00"></span>
  /// Alpha: 50% <br/> (0xff9b0080)
  public static let orangePeel50 = ColorName(rgbaValue: 0xff9b0080)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#ff1d45"></span>
  /// Alpha: 100% <br/> (0xff1d45ff)
  public static let redTorch = ColorName(rgbaValue: 0xff1d45ff)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#ff1d45"></span>
  /// Alpha: 25% <br/> (0xff1d4540)
  public static let redTorch25 = ColorName(rgbaValue: 0xff1d4540)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#ff1d45"></span>
  /// Alpha: 50% <br/> (0xff1d4580)
  public static let redTorch50 = ColorName(rgbaValue: 0xff1d4580)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#ffffff"></span>
  /// Alpha: 100% <br/> (0xffffffff)
  public static let white = ColorName(rgbaValue: 0xffffffff)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#ffffff"></span>
  /// Alpha: 9% <br/> (0xffffff19)
  public static let white10 = ColorName(rgbaValue: 0xffffff19)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#ffffff"></span>
  /// Alpha: 11% <br/> (0xffffff1e)
  public static let white12 = ColorName(rgbaValue: 0xffffff1e)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#ffffff"></span>
  /// Alpha: 20% <br/> (0xffffff33)
  public static let white20 = ColorName(rgbaValue: 0xffffff33)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#ffffff"></span>
  /// Alpha: 50% <br/> (0xffffff80)
  public static let white50 = ColorName(rgbaValue: 0xffffff80)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#ffffff"></span>
  /// Alpha: 80% <br/> (0xffffffcc)
  public static let white80 = ColorName(rgbaValue: 0xffffffcc)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#ffdc02"></span>
  /// Alpha: 100% <br/> (0xffdc02ff)
  public static let yellowSchoolBus = ColorName(rgbaValue: 0xffdc02ff)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#ffdc02"></span>
  /// Alpha: 20% <br/> (0xffdc0233)
  public static let yellowSchoolBus20 = ColorName(rgbaValue: 0xffdc0233)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#ffae00"></span>
  /// Alpha: 100% <br/> (0xffae00ff)
  public static let yellowSea = ColorName(rgbaValue: 0xffae00ff)
}
// swiftlint:enable identifier_name line_length type_body_length

// MARK: - Implementation Details

internal extension Color {
  convenience init(rgbaValue: UInt32) {
    let components = RGBAComponents(rgbaValue: rgbaValue).normalized
    self.init(red: components[0], green: components[1], blue: components[2], alpha: components[3])
  }
}

private struct RGBAComponents {
  let rgbaValue: UInt32

  private var shifts: [UInt32] {
    [
      rgbaValue >> 24, // red
      rgbaValue >> 16, // green
      rgbaValue >> 8,  // blue
      rgbaValue        // alpha
    ]
  }

  private var components: [CGFloat] {
    shifts.map {
      CGFloat($0 & 0xff)
    }
  }

  var normalized: [CGFloat] {
    components.map { $0 / 255.0 }
  }
}

public extension Color {
  convenience init(named color: ColorName) {
    self.init(rgbaValue: color.rgbaValue)
  }
}
