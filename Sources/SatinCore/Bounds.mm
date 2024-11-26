//
//  Bounds.c
//  Satin
//
//  Created by Reza Ali on 11/30/20.
//
#include <stdio.h>
#include <simd/simd.h>

#include "Bounds.h"

Bounds createBounds(void) {
    return (Bounds) { .min = { INFINITY, INFINITY, INFINITY },
                      .max = { -INFINITY, -INFINITY, -INFINITY } };
}

inline bool isBoundsInfinite(const Bounds &a) {
    return a.min.x == INFINITY || a.min.y == INFINITY || a.min.z == INFINITY ||
           a.max.x == -INFINITY || a.max.y == -INFINITY || a.max.z == -INFINITY;
}

Bounds computeBoundsFromFloatData(const void *data, int stride, int count) {
    if (count > 0) {
        Bounds result = createBounds();
        for (int i = 0; i < count; i++) {
            const float *ptr = (float *)data + i * stride;
            result = expandBounds(result, simd_make_float3(*ptr, *(ptr + 1), *(ptr + 2)));
        }
        return result;
    }
    return createBounds();
}

Bounds computeBoundsFromVertices(const SatinVertex *vertices, int count) {
    if (count > 0) {
        Bounds result = createBounds();
        for (int i = 0; i < count; i++) {
            result = expandBounds(result, vertices[i].position.xyz);
        }
        return result;
    }
    return createBounds();
}

Bounds computeBoundsFromVerticesAndTransform(
    const SatinVertex *vertices, int count, simd_float4x4 transform) {
    if (count > 0) {
        Bounds result = createBounds();
        for (int i = 0; i < count; i++) {
            result = expandBounds(
                result, simd_mul(transform, simd_make_float4(vertices[i].position, 1.0)).xyz);
        }
        return result;
    }
    return createBounds();
}

Bounds mergeBounds(Bounds a, Bounds b) {
    simd_float3 min = a.min, max = a.max;
    for (int i = 0; i < 3; i++) {
        if (b.min[i] != INFINITY) { min[i] = simd_min(a.min[i], b.min[i]); }
        if (b.max[i] != -INFINITY) { max[i] = simd_max(a.max[i], b.max[i]); }
    }
    return (Bounds) { .min = min, .max = max };
}

Bounds expandBounds(Bounds bounds, simd_float3 pt) {
    return (Bounds) { .min = simd_min(bounds.min, pt), .max = simd_max(bounds.max, pt) };
}

Bounds transformBounds(Bounds a, simd_float4x4 transform) {
    if (isBoundsInfinite(a)) { return a; }

    Bounds result = createBounds();
    for (int i = 0; i < 8; ++i) {
        result = expandBounds(result, simd_mul(transform, boundsCorner(a, i)).xyz);
    }
    return result;
}

simd_float4 boundsCorner(Bounds a, int index) {
    return simd_make_float4(
        index & 1 ? a.min.x : a.max.x,
        index & 2 ? a.min.y : a.max.y,
        index & 4 ? a.min.z : a.max.z,
        1.0);
}

bool isPointInsideBounds(simd_float3 pt, Bounds b) {
    if (pt.x <= b.min.x) { return false; }
    if (pt.x >= b.max.x) { return false; }
    if (pt.y <= b.min.y) { return false; }
    if (pt.y >= b.max.y) { return false; }
    if (pt.z <= b.min.z) { return false; }
    if (pt.z >= b.max.z) { return false; }
    return true;
}

bool isPointInsideOrOnBounds(simd_float3 pt, Bounds b) {
    if (pt.x < b.min.x) { return false; }
    if (pt.x > b.max.x) { return false; }
    if (pt.y < b.min.y) { return false; }
    if (pt.y > b.max.y) { return false; }
    if (pt.z < b.min.z) { return false; }
    if (pt.z > b.max.z) { return false; }
    return true;
}

bool boundsIntersectsBounds(Bounds a, Bounds b) {
    return (a.min.x <= b.max.x && a.max.x >= b.min.x) &&
           (a.min.y <= b.max.y && a.max.y >= b.min.y) && (a.min.z <= b.max.z && a.max.z >= b.min.z);
}

bool boundsContainsBounds(Bounds a, Bounds b) {
    return (a.min.x <= b.max.x && b.max.x <= a.max.x) &&
           (a.min.y <= b.max.y && b.max.y <= a.max.y) && (a.min.z <= b.max.z && b.max.z <= a.max.z);
}

void mergeBoundsInPlace(Bounds *a, const Bounds *b) {
    for (int i = 0; i < 3; i++) {
        if (b->min[i] != INFINITY) { a->min[i] = simd_min(a->min[i], b->min[i]); }
        if (b->max[i] != -INFINITY) { a->max[i] = simd_max(a->max[i], b->max[i]); }
    }
}

void expandBoundsInPlace(Bounds *bounds, const simd_float3 *pt) {
    bounds->min = simd_min(bounds->min, *pt);
    bounds->max = simd_max(bounds->max, *pt);
}
