#include "graph.h"

void AssignNodeColors(int screenWidth, int screenHeight) {
    Vector2 center = { screenWidth / 2.0f, screenHeight / 2.0f };
    float maxDist = sqrtf(powf(screenWidth / 2.0f, 2) + powf(screenHeight / 2.0f, 2));

    for (int i = 0; i < nodeCount; i++) {
        Vector2 dir = Vector2Subtract(graphNodes[i].position, center);
        float dist = Vector2Length(dir);

        // 1. Hue is determined by the angle (0 to 360 degrees)
        float hue = atan2f(dir.y, dir.x) * (180.0f / PI);
        if (hue < 0) hue += 360.0f;

        // 2. Saturation increases as nodes move away from the center
        float saturation = Clamp(dist / (maxDist * 0.5f), 0.4f, 0.8f);

        // 3. Brightness indicates PDF status
        float value = graphNodes[i].has_pdf ? 0.95f : 0.50f;

        graphNodes[i].color = ColorFromHSV(hue, saturation, value);
    }
}
