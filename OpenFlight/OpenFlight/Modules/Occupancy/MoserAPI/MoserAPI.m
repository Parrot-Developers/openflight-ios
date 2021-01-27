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

#import "MoserAPI.h"
#ifdef BUILDFRAMEWORK
#import <OpenFlight/OpenFlight-Swift.h>
#else
#import <OpenFlight-Swift.h>
#endif

#include <SdkCore/SdkCore.h>
#import <OpenFlightCore/OpenFlightCore.h>

@interface MoserAPI ()

@property (nonatomic, strong) LibMoserApiBridge *libMoser;

@end

@implementation MoserAPI

/**
  Singleton instance
 */
+ (id)sharedMoserAPI {
    static MoserAPI *sharedMoserAPI = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMoserAPI = [[self alloc] init];
    });
    return sharedMoserAPI;
}

-(instancetype)init {
    self.libMoser = [[LibMoserApiBridge alloc] init];
    return self;
}

-(void)dealloc {
    self.libMoser = NULL;
}

/**
 Update MoserAPI mframe from a pdraw frame

 @param mbuf_frame media video buffer frame to use to update mframe
 */
-(int) updateMoserFrame:(void *)mbuf_frame {
    const uint8_t *mbuf_frame_it;
    size_t mbuf_frame_plan_len;
    size_t plane_stride;

    int res = skdCoreGetPlaneFromRawFrame(mbuf_frame,
                                          (const void **) &mbuf_frame_it,
                                          &mbuf_frame_plan_len,
                                          &plane_stride);
    if(res < 0)
        return EXIT_FAILURE;

    float *mframe_it = self.libMoser->disparityframe;

    size_t width = MOSER_DM_W;
    size_t height = MOSER_DM_H;
    size_t shiftStride = plane_stride - width;

    for (size_t y = 0; y < height; y++) {
        for (size_t x = 0; x < width; x++, mbuf_frame_it++, mframe_it++) {
            // set to NA value if too far
            if (*mbuf_frame_it > MOSER_DISPARITY_MAX) {
                *mframe_it = -1; // NA
            } else {
                // divide by 2.f for Q7.1 conversion
                *mframe_it = (*mbuf_frame_it) >> 1;
            }
        }
        // shift unused pixels
        mbuf_frame_it += shiftStride;
    }

    skdCoreReleasePlane(mbuf_frame, (const void **) &mbuf_frame_it);

    return EXIT_SUCCESS;
}

/**
 update moser occupancy grid using a pdraw frame for the love quaternion and droneorigin and MoserAPI mframe as disparity map
 @param quaternion love quaternion
 @param origin drone position
 */
-(int) updateGridQuaternion:(float *)quat
          origin:(float[3])origin
     timestampNs:(const uint64_t)timestampNs {

    return [_libMoser updateFromDisparityFrameWithQuaternion:quat origin:origin timestampNs:timestampNs];
}

/**
Update a given storage instance using the last moser occupancy grid generated

@param storage storage to update
*/
-(void)updateStorage:(OBJCVoxelStorageCore *)storage {
    simd_int3 point;
    simd_float3 sOrigin = [_libMoser getOrigin];

    [storage startTransactionAt:sOrigin];
    for (point[0] = 0; point[0] < MOSER_OG_H; point[0]++){
        for (point[1] = 0; point[1] < MOSER_OG_V; point[1]++) {
            for (point[2] = 0; point[2] < MOSER_OG_H; point[2]++) {
                if ([_libMoser isVoxel:point]) {
                    [storage addPoint:point];
                }
            }
        }
    }
    [storage endTransaction];
}

/**
 Process a frame with libmoser to generate its associate occupancy grid

 @param frame mbuf_frame to process
 @param quaternion love quaternion
 @param origin drone position
 @return EXIT_SUCCESS if successful, otherwise SUCCESS_FAILURE
 */
-(int)processFrame:(void *)frame
        quaternion:(void *)quat
            origin:(void *)origin
       timestampNs:(const uint64_t)timestampNs {
    int res = 0;

    if (frame == NULL) {
        return EXIT_FAILURE;
    }

    res = [self updateMoserFrame:frame];
    if (res == EXIT_FAILURE) {
        return -errno;
    }

    res = [self updateGridQuaternion:quat origin:origin timestampNs:timestampNs];
    if (res == EXIT_FAILURE) {
        return -errno;
    }

    return EXIT_SUCCESS;
}

@end
