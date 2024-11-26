//
//  PoissonDiskSampler.mm
//  Satin
//
//  Created by Reza Ali on 11/9/24.
//

#include <malloc/_malloc.h>
#include <string.h>
#include <iostream>
#include <vector>
#include <cstdlib>
#include <ctime>

#include "PoissonDiskSampler.h"
#include "Rectangle.h"

using namespace std;

Points2D generatePoissonDiskSamples(Rectangle rect, float minDistance, float kMax) {
    const Rectangle bounds =
        (Rectangle) { .min = simd_min(rect.max, rect.min), .max = simd_max(rect.max, rect.min) };
    const simd_float2 size = bounds.max - bounds.min;

    const float width = size.x;
    const float height = size.y;

    const float cellSize = minDistance / sqrt(2.0);
    const int gridWidth = ceil(width / cellSize);
    const int gridHeight = ceil(height / cellSize);

    const simd_int2 gridSizeHalf = simd_make_int2(gridWidth / 2, gridHeight / 2);

    const int gridLength = gridWidth * gridHeight;

    const float radius = minDistance;
    const float twoPi = M_PI * 2.0;

    vector<simd_float2> activeList;
    activeList.reserve(gridLength);

    vector<simd_float2> samples;
    samples.reserve(gridLength);

    vector<int> grid(gridLength, -1);

    const simd_float2 initialSample =
        bounds.min + simd_make_float2(
                         static_cast<float>(rand()) / static_cast<float>(RAND_MAX / (width)),
                         static_cast<float>(rand()) / static_cast<float>(RAND_MAX / (height)));

    samples.emplace_back(initialSample);
    activeList.emplace_back(initialSample);

    const simd_int2 initialSampleGridPosition =
        gridSizeHalf + simd_make_int2(initialSample.x / cellSize, initialSample.y / cellSize);

    const uint32_t initialSampleGridIndex =
        initialSampleGridPosition.y * gridWidth + initialSampleGridPosition.x;

    grid[initialSampleGridIndex] = 0;

    const int angleMax = static_cast<float>(RAND_MAX / (twoPi));
    const int distanceMax = static_cast<float>(RAND_MAX / (radius));

    while (!activeList.empty()) {
        bool found = false;
        const int activeIndex = rand() % activeList.size();
        const simd_float2 activeSample = activeList[activeIndex];

        for (int k = 0; k < kMax; k++) {
            const float angle = static_cast<float>(rand()) / angleMax;
            const float distance = radius + static_cast<float>(rand()) / distanceMax;
            const simd_float2 candidate =
                activeSample + distance * simd_make_float2(cos(angle), sin(angle));

            if (rectangleContainsPoint(bounds, candidate)) {
                const simd_int2 candidateGridPosition =
                    gridSizeHalf + simd_make_int2(candidate.x / cellSize, candidate.y / cellSize);
                const uint32_t candidateGridIndex =
                    candidateGridPosition.y * gridWidth + candidateGridPosition.x;

                // Check surrounding cells in the grid

                int iMin = max(0, candidateGridPosition.x - 2);
                int iMax = min(gridWidth - 1, candidateGridPosition.x + 2);

                int jMin = max(0, candidateGridPosition.y - 2);
                int jMax = min(gridHeight - 1, candidateGridPosition.y + 2);

                bool valid = true;
                for (int i = iMin; i <= iMax; i++) {
                    if (!valid) { break; }
                    for (int j = jMin; j <= jMax; j++) {
                        const int sampleIndex = grid[j * gridWidth + i];
                        if (sampleIndex > -1) {
                            if (simd_distance(samples[sampleIndex], candidate) < minDistance) {
                                valid = false;
                                break;
                            }
                        }
                    }
                }

                if (valid) {
                    samples.emplace_back(candidate);
                    activeList.emplace_back(candidate);

                    grid[candidateGridIndex] = static_cast<int>(samples.size()) - 1;

                    found = true;
                    break;
                }
            }
        }

        if (!found) { activeList.erase(activeList.begin() + activeIndex); }
    }

    auto samplesSize = sizeof(simd_float2) * samples.size();

    Points2D points;

    points.count = static_cast<int>(samples.size());
    points.data = (simd_float2 *)malloc(samplesSize);

    memcpy(points.data, samples.data(), samplesSize);

    return points;
}
