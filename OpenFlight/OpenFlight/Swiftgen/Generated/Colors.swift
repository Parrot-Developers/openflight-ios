// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

#if os(macOS)
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

  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#3b302a"></span>
  /// Alpha: 80% <br/> (0x3b302acc)
  public static let batteryProgressColor = ColorName(rgbaValue: 0x3b302acc)
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
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#171e25"></span>
  /// Alpha: 100% <br/> (0x171e25ff)
  public static let blackPearl = ColorName(rgbaValue: 0x171e25ff)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#00b7ff"></span>
  /// Alpha: 100% <br/> (0x00b7ffff)
  public static let blueDodger = ColorName(rgbaValue: 0x00b7ffff)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#00b7ff"></span>
  /// Alpha: 50% <br/> (0x00b7ff80)
  public static let blueDodger50 = ColorName(rgbaValue: 0x00b7ff80)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#146ed8"></span>
  /// Alpha: 100% <br/> (0x146ed8ff)
  public static let blueNavy = ColorName(rgbaValue: 0x146ed8ff)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#8a8a8a"></span>
  /// Alpha: 50% <br/> (0x8a8a8a80)
  public static let cellSelectionColor = ColorName(rgbaValue: 0x8a8a8a80)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#000000"></span>
  /// Alpha: 0% <br/> (0x00000000)
  public static let clear = ColorName(rgbaValue: 0x00000000)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#f0eee4"></span>
  /// Alpha: 100% <br/> (0xf0eee4ff)
  public static let defaultBgcolor = ColorName(rgbaValue: 0xf0eee4ff)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#27201c"></span>
  /// Alpha: 100% <br/> (0x27201cff)
  public static let defaultTextColor = ColorName(rgbaValue: 0x27201cff)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#27201c"></span>
  /// Alpha: 20% <br/> (0x27201c33)
  public static let defaultTextColor20 = ColorName(rgbaValue: 0x27201c33)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#27201c"></span>
  /// Alpha: 80% <br/> (0x27201ccc)
  public static let defaultTextColor80 = ColorName(rgbaValue: 0x27201ccc)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#c5c4c4"></span>
  /// Alpha: 100% <br/> (0xc5c4c4ff)
  public static let disabledBgcolor = ColorName(rgbaValue: 0xc5c4c4ff)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#e34f45"></span>
  /// Alpha: 30% <br/> (0xe34f454d)
  public static let disabledErrorColor = ColorName(rgbaValue: 0xe34f454d)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#34c175"></span>
  /// Alpha: 20% <br/> (0x34c17533)
  public static let disabledHighlightColor = ColorName(rgbaValue: 0x34c17533)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#27201c"></span>
  /// Alpha: 50% <br/> (0x27201c80)
  public static let disabledTextColor = ColorName(rgbaValue: 0x27201c80)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#6c6b6a"></span>
  /// Alpha: 100% <br/> (0x6c6b6aff)
  public static let disabledTextColor2 = ColorName(rgbaValue: 0x6c6b6aff)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#ff7145"></span>
  /// Alpha: 20% <br/> (0xff714533)
  public static let disabledWarningColor = ColorName(rgbaValue: 0xff714533)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#e34f45"></span>
  /// Alpha: 100% <br/> (0xe34f45ff)
  public static let errorColor = ColorName(rgbaValue: 0xe34f45ff)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#00ff8a"></span>
  /// Alpha: 100% <br/> (0x00ff8aff)
  public static let flightCompletedColor = ColorName(rgbaValue: 0x00ff8aff)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#00ff8a"></span>
  /// Alpha: 60% <br/> (0x00ff8a99)
  public static let flightCompletedColor60 = ColorName(rgbaValue: 0x00ff8a99)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#f8d000"></span>
  /// Alpha: 100% <br/> (0xf8d000ff)
  public static let gold = ColorName(rgbaValue: 0xf8d000ff)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#76c959"></span>
  /// Alpha: 100% <br/> (0x76c959ff)
  public static let green = ColorName(rgbaValue: 0x76c959ff)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#00ff8a"></span>
  /// Alpha: 100% <br/> (0x00ff8aff)
  public static let greenSpring = ColorName(rgbaValue: 0x00ff8aff)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#48494b"></span>
  /// Alpha: 100% <br/> (0x48494bff)
  public static let greyDark = ColorName(rgbaValue: 0x48494bff)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#48494b"></span>
  /// Alpha: 60% <br/> (0x48494b99)
  public static let greyDark60 = ColorName(rgbaValue: 0x48494b99)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#dfd8c7"></span>
  /// Alpha: 100% <br/> (0xdfd8c7ff)
  public static let greyLightReturn = ColorName(rgbaValue: 0xdfd8c7ff)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#1a1c1e"></span>
  /// Alpha: 100% <br/> (0x1a1c1eff)
  public static let greyShark = ColorName(rgbaValue: 0x1a1c1eff)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#bebebe"></span>
  /// Alpha: 100% <br/> (0xbebebeff)
  public static let greySilver = ColorName(rgbaValue: 0xbebebeff)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#34c175"></span>
  /// Alpha: 100% <br/> (0x34c175ff)
  public static let highlightColor = ColorName(rgbaValue: 0x34c175ff)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#ff9b00"></span>
  /// Alpha: 50% <br/> (0xff9b0080)
  public static let landingIndicatorColor = ColorName(rgbaValue: 0xff9b0080)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#72d8f9"></span>
  /// Alpha: 100% <br/> (0x72d8f9ff)
  public static let lightBlue = ColorName(rgbaValue: 0x72d8f9ff)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#2f2f2f"></span>
  /// Alpha: 100% <br/> (0x2f2f2fff)
  public static let nightRider = ColorName(rgbaValue: 0x2f2f2fff)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#2f2f2f"></span>
  /// Alpha: 80% <br/> (0x2f2f2fcc)
  public static let nightRider80 = ColorName(rgbaValue: 0x2f2f2fcc)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#f9a272"></span>
  /// Alpha: 100% <br/> (0xf9a272ff)
  public static let orange = ColorName(rgbaValue: 0xf9a272ff)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#f97292"></span>
  /// Alpha: 100% <br/> (0xf97292ff)
  public static let pink = ColorName(rgbaValue: 0xf97292ff)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#7d72f9"></span>
  /// Alpha: 100% <br/> (0x7d72f9ff)
  public static let purple = ColorName(rgbaValue: 0x7d72f9ff)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#5e5650"></span>
  /// Alpha: 100% <br/> (0x5e5650ff)
  public static let secondaryTextColor = ColorName(rgbaValue: 0x5e5650ff)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#b9b5ad"></span>
  /// Alpha: 100% <br/> (0xb9b5adff)
  public static let separator = ColorName(rgbaValue: 0xb9b5adff)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#713521"></span>
  /// Alpha: 100% <br/> (0x713521ff)
  public static let shadowColor = ColorName(rgbaValue: 0x713521ff)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#00ff8a"></span>
  /// Alpha: 20% <br/> (0x00ff8a33)
  public static let takeoffIndicatorColor = ColorName(rgbaValue: 0x00ff8a33)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#ff7145"></span>
  /// Alpha: 100% <br/> (0xff7145ff)
  public static let warningColor = ColorName(rgbaValue: 0xff7145ff)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#ff7145"></span>
  /// Alpha: 60% <br/> (0xff714599)
  public static let warningColor60 = ColorName(rgbaValue: 0xff714599)
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
  /// Alpha: 30% <br/> (0xffffff4d)
  public static let white30 = ColorName(rgbaValue: 0xffffff4d)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#ffffff"></span>
  /// Alpha: 50% <br/> (0xffffff80)
  public static let white50 = ColorName(rgbaValue: 0xffffff80)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#ffffff"></span>
  /// Alpha: 70% <br/> (0xffffffb3)
  public static let white70 = ColorName(rgbaValue: 0xffffffb3)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#ffffff"></span>
  /// Alpha: 80% <br/> (0xffffffcc)
  public static let white80 = ColorName(rgbaValue: 0xffffffcc)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#ffffff"></span>
  /// Alpha: 90% <br/> (0xffffffe6)
  public static let white90 = ColorName(rgbaValue: 0xffffffe6)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#dfd8c7"></span>
  /// Alpha: 100% <br/> (0xdfd8c7ff)
  public static let whiteAlbescent = ColorName(rgbaValue: 0xdfd8c7ff)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#f9db72"></span>
  /// Alpha: 100% <br/> (0xf9db72ff)
  public static let yellow = ColorName(rgbaValue: 0xf9db72ff)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#ffdc02"></span>
  /// Alpha: 100% <br/> (0xffdc02ff)
  public static let yellowSea = ColorName(rgbaValue: 0xffdc02ff)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#ffdc02"></span>
  /// Alpha: 30% <br/> (0xffdc024d)
  public static let yellowSea30 = ColorName(rgbaValue: 0xffdc024d)
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
