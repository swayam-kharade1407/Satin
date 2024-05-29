//
//  Triangulator.h
//  Satin
//
//  Created by Reza Ali on 7/5/20.
//

#ifndef Triangulator_h
#define Triangulator_h

#import "Types.h"

#if defined(__cplusplus)
extern "C" {
#endif

// triangulates multiple paths
int triangulate(simd_float2 **paths, int *lengths, int count, TriangleData *gData);

// triangulates one counter clockwise path
int triangulatePath(simd_float2 *points, int length, TriangleData *gData);

int extrudePaths(simd_float2 **paths, int *lengths, int count, GeometryData *gData);

#if defined(__cplusplus)
}
#endif

#endif /* Triangulator_h */
