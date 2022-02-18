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
import simd

protocol VoxelStorage {

    subscript(key: Point) -> ChunkStorage? { get }

    func add(point: simd_int3)
    func startTransaction(at position: simd_float3)
    func endTransaction()
    func getSetOfUpdatedChunks(fromQuery query: inout UInt) -> Set<Point>
    func convertWorldPosition(_ position: simd_float3) -> (chunkKey: Point, voxelKey: Point)
    func allChunksKeys() -> Set<Point>
}

public class WorldData {

    /// chunks
    private var chunks = [Point: ChunkStorage]()
    /// queue to lock competitive threads
    private var chunksAccessQueue: DispatchQueue

    /// subscript to handle chunks in a thread-secure way
    public subscript(point: Point) -> ChunkStorage? {
        get {
            var returnValue: ChunkStorage?
            self.chunksAccessQueue.sync {
                returnValue = chunks[point]
            }
            return returnValue
        }
        set(newValue) {
            chunksAccessQueue.async(flags: .barrier) {
                self.chunks[point] = newValue
            }
        }
    }

    /// return all points from every chunks
    func allChunksKeys() -> Set<Point> {
        var returnSet: Set<Point>?
        self.chunksAccessQueue.sync {
            returnSet = Set(chunks.keys)
        }
        return returnSet ?? Set<Point>()
    }

    /// remove every chunks
    func removeAll() {
        chunksAccessQueue.async(flags: .barrier) {
            self.chunks = [Point: ChunkStorage]()
        }
    }

    init (queue: DispatchQueue? = nil) {
        self.chunksAccessQueue = queue ?? DispatchQueue(label: "WorldData.chunksAccessQueue", attributes: .concurrent)
    }
}

@objc(OBJCVoxelStorageCore)
open class VoxelStorageCore: NSObject, VoxelStorage {

    /// actual grid position
    private(set) var gridOrigin: simd_float3?
    /// offset between first and last grid
    public var gridOffset = Point.zero

    /// history of chunk transactions
    private var transactionHistory: TransactionHistory<Point>
    /// chunks to handle during a transaction
    public var transactionChunks = [Point: ChunkStorage]()
    /// actual grid contents
    public var worldData: WorldData
    /// SceneKit grid center
    public var center: simd_float3

    /// queue to lock competitive threads
    private var worldAccessQueue = DispatchQueue(label: "world.subscript.queue", attributes: .concurrent)

    // MARK: - Initialization

    init(size: Point) {
        center = simd_float3(x: Float(size.x - 1) / 2, y: Float(size.y - 1) / 2, z: Float(size.z - 1) / 2)
        self.transactionHistory = TransactionHistory(max: Occupancy.Storage.maximumChunkQueries, queue: worldAccessQueue)
        worldData = WorldData(queue: worldAccessQueue)
        transactionChunks.reserveCapacity(100)
    }

    /// subscript to get chunks from `worldData`
    @inlinable
    public subscript(key: Point) -> ChunkStorage? {
        return worldData[key]
    }

    public func convertWorldPosition(_ position: simd_float3) -> (chunkKey: Point, voxelKey: Point) {

        let positionInVoxels = position // 1 voxel = 1 unit
        let chunkSizeFloat = Float(Occupancy.Storage.chunkSize)
        let chunkPosition = simd_float3(
            x: (positionInVoxels.x / chunkSizeFloat).rounded(.down),
            y: (positionInVoxels.y / chunkSizeFloat).rounded(.down),
            z: (positionInVoxels.z / chunkSizeFloat).rounded(.down)
        )
        let positionInChunk = positionInVoxels // - (chunkPosition * chunkSizeFloat) //  1 voxel = 1 unit
        let retChunkPoint = Point(chunkPosition)
        let retVoxelPoint = Point(positionInChunk)
        return (retChunkPoint, retVoxelPoint)
    }

    /// Prepare the storage to handle a transaction
    ///
    /// - Parameters:
    ///     - position: moser occupancy grid origin
    @objc(startTransactionAt:)
    public func startTransaction(at position: simd_float3) {
        if let droneOrigin = gridOrigin {
            // calculate the offset between first and last grid position
            // NED - SceneKit
            // east - x
            // down - y
            // north - z
            gridOffset = Point(
                x: Int32((Float32(droneOrigin.y - position.y) / Occupancy.voxelRealSize).rounded()),
                y: Int32((Float32(droneOrigin.z - position.z) / Occupancy.voxelRealSize).rounded()),
                z: Int32((Float32(position.x - droneOrigin.x) / Occupancy.voxelRealSize).rounded())
            )
        } else {
            gridOrigin = position
        }

        transactionChunks.removeAll()
    }

    /// add a point to `transactionChunks`
    ///
    /// - Parameters:
    ///     - point: point to add
    @inlinable
    @objc(addPoint:)
    public func add(point: simd_int3) {
        // shift point using grid offset
        let shiftedPoint = point &+ gridOffset
        let chunkPoint = shiftedPoint / Occupancy.Storage.chunkSize
        var chunkToUpdate = transactionChunks[chunkPoint]
        if chunkToUpdate == nil {
            chunkToUpdate =  ChunkStorage()
            transactionChunks[chunkPoint] = chunkToUpdate
        }
        // swiftlint:disable force_unwrapping
        chunkToUpdate!.setPoint(shiftedPoint)
        // swiftlint:enable force_unwrapping
    }

    public func allChunksKeys() -> Set<Point> {
        return worldData.allChunksKeys()
    }

    /// Setup the storage to handle the finished transaction
    @objc(endTransaction)
    public func endTransaction() {

        let allChunksKeysInTransaction = Set(transactionChunks.keys)
        var updatedChunks = Set<Point>()
        transactionChunks.forEach { key, value in
            if worldData[key] == nil || value != worldData[key] {
                worldData[key] = value
                updatedChunks.insert(key)
            }
        }

        // remove from the world all chunks that are not present in the transaction
        let chunksToRemove = worldData.allChunksKeys().subtracting(allChunksKeysInTransaction)
        chunksToRemove.forEach { worldData[$0] = nil }

        // we add this "remove list" in the updated chunks list
        updatedChunks.formUnion(chunksToRemove)

        // save the complete list (new chunks + removed chunks) in the transaction history
        transactionHistory.addInHisto(elt: updatedChunks)
    }

    func getSetOfUpdatedChunks(fromQuery query: inout UInt) -> Set<ChunkKey> {
        let askedQuery = query
        if let updatedChunksKeys = transactionHistory.getElts(query: &query) {
            return updatedChunksKeys
        } else {
            // nil was returned by transactionHistory
            // 2 cases :
            //   - the queryNumber was too old
            //   - or the query number in is not yet known

            // if the queryNumber was too old
            if askedQuery < query {
                // we give all the world
                return worldData.allChunksKeys()
            } else {
                // the query number is for a future version
                // we return an empty set
                return Set<ChunkKey>()
            }
        }
    }
}
