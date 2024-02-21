//
//  Bvh.c
//  Satin
//
//  Created by Reza Ali on 11/27/22.
//

#include "Bvh.h"
#include "Bounds.h"
#include <float.h>
#include <malloc/_malloc.h>
#include <simd/simd.h>
#include <stdio.h>

// BVH Implementation is based on:
// https://jacco.ompf2.com/2022/04/13/how-to-build-a-bvh-part-1-basics/

typedef struct {
    Bounds aabb;
    int triCount;
} Bin;

Bin createBin() { return (Bin) { .aabb = createBounds(), .triCount = 0 }; }

bool isLeaf(BVHNode node) { return node.triCount > 0; }

float surfaceAreaBounds(Bounds *b)
{
    for (int i = 0; i < 3; i++) {
        if (b->min[i] == INFINITY || b->max[i] == -INFINITY) { return 0.0; }
    }

    const simd_float3 extents = b->max - b->min;
    return extents.x * extents.y + extents.y * extents.z + extents.z * extents.x;
}

float calculateNodeCost(BVHNode *node) { return node->triCount * surfaceAreaBounds(&node->aabb); }

#define BINS 8
#define BINSMINUSONE BINS - 1
#define MIN(a, b) (((a) < (b)) ? (a) : (b))
#define MAX(a, b) (((a) > (b)) ? (a) : (b))

float findBestSplitPlane(BVH *bvh, BVHNode *node, int *axis, float *splitPos)
{
    // split along longest axis to optimize generation speed
    const simd_float3 extent = node->aabb.max - node->aabb.min;
    int a = 0;
    if (extent.y > extent.x) a = 1;
    if (extent.z > extent[a]) a = 2;
    *axis = a;

    float bestCost = FLT_MAX;
    float boundsMin = INFINITY, boundsMax = -INFINITY;
    for (int i = 0; i < node->triCount; i++) {
        const uint32_t triID = bvh->triIDs[node->leftFirst + i];
        const float center = bvh->centroids[triID][a];
        boundsMin = simd_min(boundsMin, center);
        boundsMax = simd_max(boundsMax, center);
    }

    // populate the bins
    Bin bin[BINS] = { createBin(), createBin(), createBin(), createBin(), createBin(), createBin(), createBin(), createBin() };

    float scale = (float)BINS / (boundsMax - boundsMin);
    for (uint32_t i = 0; i < node->triCount; i++) {
        const uint32_t triID = bvh->triIDs[node->leftFirst + i];
        const TriangleIndices tri = bvh->triangles[triID];
        const int binID = MIN((bvh->centroids[triID][a] - boundsMin) * scale, BINSMINUSONE);

        bin[binID].triCount++;

        expandBoundsInPlace(&bin[binID].aabb, &bvh->positions[tri.i0]);
        expandBoundsInPlace(&bin[binID].aabb, &bvh->positions[tri.i1]);
        expandBoundsInPlace(&bin[binID].aabb, &bvh->positions[tri.i2]);
    }

    // gather data for the 7 planes between the 8 bins
    float leftArea[BINSMINUSONE], rightArea[BINSMINUSONE];
    int leftCount[BINSMINUSONE], rightCount[BINSMINUSONE];
    Bounds leftBox = createBounds(), rightBox = createBounds();

    int leftSum = 0, rightSum = 0;
    for (int i = 0; i < BINSMINUSONE; i++) {
        leftSum += bin[i].triCount;
        leftCount[i] = leftSum;
        mergeBoundsInPlace(&leftBox, &bin[i].aabb);
        leftArea[i] = surfaceAreaBounds(&leftBox);

        rightSum += bin[BINSMINUSONE - i].triCount;
        rightCount[BINSMINUSONE - 1 - i] = rightSum;
        mergeBoundsInPlace(&rightBox, &bin[BINSMINUSONE - i].aabb);
        rightArea[BINSMINUSONE - 1 - i] = surfaceAreaBounds(&rightBox);
    }

    // calculate SAH cost for the 7 planes
    scale = (boundsMax - boundsMin) / (float)BINS;
    for (int i = 0; i < BINSMINUSONE; i++) {
        const float planeCost = leftCount[i] * leftArea[i] + rightCount[i] * rightArea[i];
        if (planeCost < bestCost) {
            *splitPos = boundsMin + scale * (i + 1);
            bestCost = planeCost;
        }
    }
    return bestCost;
}

void updateBVHNodeBounds(BVH *bvh, uint32_t nodeIndex)
{
    BVHNode *node = &bvh->nodes[nodeIndex];
    node->aabb = createBounds();

    for (uint32_t first = node->leftFirst, i = 0; i < node->triCount; i++) {
        const uint32_t triID = bvh->triIDs[first + i];
        const TriangleIndices tri = bvh->triangles[triID];
        expandBoundsInPlace(&node->aabb, &bvh->positions[tri.i0]);
        expandBoundsInPlace(&node->aabb, &bvh->positions[tri.i1]);
        expandBoundsInPlace(&node->aabb, &bvh->positions[tri.i2]);
    }
}

void subdivideBVHNode(BVH *bvh, uint32_t nodeIndex)
{
    BVHNode *node = &bvh->nodes[nodeIndex];

    int axis = 0;
    float splitPos;

    if (bvh->useSAH) {
        // Surface Area Heuristic
        const float splitCost = findBestSplitPlane(bvh, node, &axis, &splitPos);
        const float noSplitCost = calculateNodeCost(node);
        if (splitCost >= noSplitCost) return;
    }
    else {
        // Midpoint Split
        if (node->triCount <= 2) return;
        const simd_float3 extent = node->aabb.max - node->aabb.min;
        if (extent.y > extent.x) axis = 1;
        if (extent.z > extent[axis]) axis = 2;
        splitPos = node->aabb.min[axis] + extent[axis] * 0.5;
    }

    int start = node->leftFirst;
    int end = start + node->triCount - 1;
    while (start <= end) {
        const uint32_t triID = bvh->triIDs[start];
        if (bvh->centroids[triID][axis] < splitPos) { start++; }
        else {
            const uint32_t first = bvh->triIDs[start];
            bvh->triIDs[start] = bvh->triIDs[end];
            bvh->triIDs[end] = first;
            end--;
        }
    }

    int leftCount = start - node->leftFirst;
    if (leftCount == 0 || leftCount == node->triCount) return;

    const int leftNodeIndex = bvh->nodesUsed++;
    const int rightNodeIndex = bvh->nodesUsed++;

    bvh->nodes[leftNodeIndex].leftFirst = node->leftFirst;
    bvh->nodes[leftNodeIndex].triCount = leftCount;

    bvh->nodes[rightNodeIndex].leftFirst = start;
    bvh->nodes[rightNodeIndex].triCount = node->triCount - leftCount;

    node->leftFirst = leftNodeIndex;
    node->triCount = 0;

    updateBVHNodeBounds(bvh, leftNodeIndex);
    updateBVHNodeBounds(bvh, rightNodeIndex);

    subdivideBVHNode(bvh, leftNodeIndex);
    subdivideBVHNode(bvh, rightNodeIndex);
}

BVH createBVHFromGeometryData(GeometryData geometry, bool useSAH)
{
    return createBVHFromFloatData(geometry.vertexData, sizeof(SatinVertex) / sizeof(float), geometry.vertexCount, geometry.indexData,
                                  geometry.indexCount * 3, true, useSAH);
}

BVH createBVHFromFloatData(const void *vertexData, int vertexStride, int vertexCount, const void *indexData, int indexCount, bool uint32,
                           bool useSAH)
{
    const bool hasTriangles = indexCount > 0;
    const uint32_t triCount = hasTriangles ? (indexCount / 3) : (vertexCount / 3);

    BVHNode *nodes = (BVHNode *)malloc(sizeof(BVHNode) * triCount * 2 - 1);
    simd_float3 *centroids = (simd_float3 *)malloc(sizeof(simd_float3) * triCount);
    simd_float3 *positions = (simd_float3 *)malloc(sizeof(simd_float3) * vertexCount);
    uint32_t *triIDs = (uint32_t *)malloc(sizeof(uint32_t) * triCount);
    TriangleIndices *triangles = (TriangleIndices *)malloc(sizeof(TriangleIndices) * triCount);
    Bounds aabb = createBounds();

    for (uint32_t i = 0; i < triCount; i++) {
        triIDs[i] = i;

        const uint32_t offset = i * 3;
        uint32_t i0 = offset;
        uint32_t i1 = offset + 1;
        uint32_t i2 = offset + 2;

        if (hasTriangles) {
            if (uint32) {
                uint32_t *indicies = (uint32_t *)indexData;
                i0 = indicies[i0];
                i1 = indicies[i1];
                i2 = indicies[i2];
            }
            else {
                uint16_t *indicies = (uint16_t *)indexData;
                i0 = indicies[i0];
                i1 = indicies[i1];
                i2 = indicies[i2];
            }
        }

        triangles[i] = (TriangleIndices) { i0, i1, i2 };

        const float *v0 = (float *)vertexData + (i0 * vertexStride);
        const float *v1 = (float *)vertexData + (i1 * vertexStride);
        const float *v2 = (float *)vertexData + (i2 * vertexStride);

        positions[i0] = simd_make_float3(*v0, *(v0 + 1), *(v0 + 2));
        positions[i1] = simd_make_float3(*v1, *(v1 + 1), *(v1 + 2));
        positions[i2] = simd_make_float3(*v2, *(v2 + 1), *(v2 + 2));

        expandBoundsInPlace(&aabb, &positions[i0]);
        expandBoundsInPlace(&aabb, &positions[i1]);
        expandBoundsInPlace(&aabb, &positions[i2]);

        centroids[i] = (positions[i0] + positions[i1] + positions[i2]) / 3.0;
    }

    BVH bvh = (BVH) { .nodes = nodes,
                      .centroids = centroids,
                      .positions = positions,
                      .triangles = triangles,
                      .triIDs = triIDs,
                      .nodesUsed = 0,
                      .useSAH = useSAH };

    if (triCount > 0) {
        bvh.nodesUsed++;
        BVHNode *root = &nodes[0];
        root->leftFirst = 0;
        root->triCount = triCount;
        root->aabb = aabb;
        subdivideBVHNode(&bvh, 0);
    }

    return bvh;
}

void freeBVH(BVH bvh)
{
    free(bvh.triIDs);
    free(bvh.nodes);
    free(bvh.centroids);
    free(bvh.positions);
    free(bvh.triangles);
}
