//    Copyright (C) 2019 Parrot Drones SAS
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

import Foundation

class TransactionHistory<Storable: Hashable> {

    let histoMax: UInt
    private var store = [UInt: Set<Storable>]()
    private var transactionNumber = UInt(0)
    private var firstTransaction: UInt {
        if transactionNumber > histoMax {
            return transactionNumber - (histoMax - 1)
        } else {
            return 1
        }
    }
    private var accessQueue: DispatchQueue

    func addInHisto(elt: Set<Storable>) {
        accessQueue.async(flags: .barrier) {
            self.transactionNumber += 1
            self.store[self.transactionNumber] = elt
            if self.store.count > self.histoMax {
                self.store[self.firstTransaction - 1] = nil
            }
        }
    }

    init (max: UInt, queue: DispatchQueue? = nil) {
        self.histoMax = max > 0 ? max : 1
        self.accessQueue = queue ?? DispatchQueue(label: "TransactionHistory.accessQueue", attributes: .concurrent)
    }

    func getElts(query: inout UInt) -> Set<Storable>? {
        var returnSet: Set<Storable>?
        accessQueue.sync {

            // if the query if for a future version -> do nothing
            if query <= transactionNumber {
                // the query is <= transaction number
                // return a union of the last queries
                if transactionNumber > 0 && (firstTransaction...transactionNumber).contains(query) {
                    var tmpSet = Set<Storable>()
                    for transacion in (query...transactionNumber) {
                        tmpSet.formUnion(store[transacion] ?? Set<Storable>())
                    }
                    returnSet = tmpSet
                }
                // update the latest transaction number in the query (for the next query)
                query = transactionNumber + 1
            }
        }
        return returnSet
    }
}
