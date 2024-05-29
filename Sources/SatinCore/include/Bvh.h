//
//  Bvh.h
//  Satin
//
//  Created by Reza Ali on 11/27/22.
//

#ifndef Bvh_h
#define Bvh_h

#import "Types.h"

#if defined(__cplusplus)
extern "C" {
#endif

BVH createBVHFromFloatData(const void *vertexData, int vertexStride, int vertexCount, const void *indexData, int indexCount, bool uint32,
                           bool useSAH);

BVH createBVHFromGeometryData(GeometryData geometry, bool useSAH);

void freeBVH(BVH bvh);

#if defined(__cplusplus)
}
#endif

#endif /* Bvh_h */
