//    Copyright (C) 2020 Parrot Drones SAS
//
//    Redistribution and use in source and binary forms, with or without
//    modification, are permitted provided that the following conditions
//    are met:
//    * Redistributions of source code must retain the above copyright
//      notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright
//      notice, this list of conditions and the following disclaimer in
//      the documentation and/or other materials provided with the
//      distribution.
//    * Neither the name of the Parrot Company nor the names
//      of its contributors may be used to endorse or promote products
//      derived from this software without specific prior written
//      permission.
//
//    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
//    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
//    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
//    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
//    PARROT COMPANY BE LIABLE FOR ANY DIRECT, INDIRECT,
//    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
//    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
//    OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
//    AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//    OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
//    OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
//    SUCH DAMAGE.


// MARK: - Public Enums
/// Stores constanst for URLRequest fields.
public enum RequestHeaderFields {
    public static let authorization: String = "Authorization"
    public static let contentType: String = "Content-Type"
    public static let xApiKey: String = "x-api-key"
    public static let appJson: String = "application/json"
    public static let appJsonUtf8: String = "application/json; charset=utf-8"
    public static let formUrlEncoded: String = "application/x-www-form-urlencoded"
    public static let callerId: String = "X-callerId"
}

// MARK: - Internal Enums
/// Constants for all external services.
enum ServicesConstants {
    /// ArcGIS license key.
    static let arcGisLicenseKey: String = "runtimelite,1000,rud8241485735,none,PM0RJAY3FL9BY7ZPM158"
    /// APC secret key.
    static let apcSecretKey: String = "g%2SW+m,cc9|eDQBgK:qTS2l=;[O~f@W"
    /// Academy secret key.
    static let academySecretKey: String = "cd7oG8K9h86oCya0u5C0H7mphOuu8LU91o1hBLiG"
    /// Caller Id for APC.
    static let xCallerId: String = "OpenFlight"
}

