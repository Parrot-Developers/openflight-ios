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
#if !PICTOR_EXTENDED

import UIKit

extension PictorUserServiceImpl: PictorUserServiceAccount {
    func create(creationInfo: PictorUserServiceCreationInfo,
                completion: @escaping (PictorUserServiceError?) -> Void) {
        fatalError("Must Override \(#function)")
    }

    func login(authenticationInfo: PictorUserServiceAuthenticationInfo,
               completion: @escaping (PictorUserServiceError?, Bool) -> Void) {
        fatalError("Must Override \(#function)")
    }

    func refresh(completion: @escaping (PictorUserServiceError?) -> Void) {
        refreshAnonymousToken(completion: completion)
    }

    func updateAvatar(_ data: Data,
                      completion: @escaping (PictorUserServiceError?) -> Void) {
        fatalError("Must Override \(#function)")
    }

    func deleteAvatar(completion: @escaping (PictorUserServiceError?) -> Void) {
        fatalError("Must Override \(#function)")
    }

    func updateUser(userInfo: PictorUserServiceUserInfo,
                    completion: @escaping (PictorUserServiceError?) -> Void) {
        fatalError("Must Override \(#function)")
    }

    func checkUserExists(from email: String, completion: @escaping (Bool?, PictorUserServiceError?) -> Void) {
        fatalError("Must Override \(#function)")
    }

    func deleteUser(completion: @escaping (PictorUserServiceError?) -> Void) {
        fatalError("Must Override \(#function)")
    }

    func deleteUserCloudData(completion: @escaping (PictorUserServiceError?) -> Void) {
        fatalError("Must Override \(#function)")
    }

    func updateToPrivateMode(completion: @escaping (PictorUserServiceError?) -> Void) {
        fatalError("Must Override \(#function)")
    }

    func updateToSharingMode(completion: @escaping (PictorUserServiceError?) -> Void) {
        fatalError("Must Override \(#function)")
    }

    func resetForgottenPassword(with email: String, completion: @escaping (PictorUserServiceError?) -> Void) {
        fatalError("Must Override \(#function)")
    }

    func logout(completion: @escaping () -> Void) {
        fatalError("Must Override \(#function)")
    }
}

extension PictorUserServiceImpl: PictorUserServiceAppleAccount {
    func appleCreate(creationInfo: PictorUserServiceAppleCreationInfo,
                     completion: @escaping (_ error: PictorUserServiceError?, _ isLogged: Bool) -> Void) {
        fatalError("Must Override \(#function)")
    }

    func appleLogin(authenticationInfo: PictorUserServiceAppleAuthenticationInfo,
                    completion: @escaping (_ error: PictorUserServiceError?, _ isLogged: Bool) -> Void) {
        fatalError("Must Override \(#function)")
    }
}

extension PictorUserServiceImpl: PictorUserServiceGoogleAccount {
    func googleCreate(creationInfo: PictorUserServiceCreationInfo,
                      completion: @escaping (_ error: PictorUserServiceError?, _ isLogged: Bool) -> Void) {
        fatalError("Must Override \(#function)")
    }

    func googleLogin(authenticationInfo: PictorUserServiceGoogleAuthenticationInfo,
                     completion: @escaping (_ error: PictorUserServiceError?, _ isLogged: Bool) -> Void) {
        fatalError("Must Override \(#function)")
    }
}

#endif
