#include "graph.h"

float k = 10.0f;
float repulsion = 1000.0f;
float centerGravity = 0.004f;
float damping = 0.6f;

void updatePhysics(int screenWidth, int screenHeight, int draggedIdx) {
    const float maxDist = 300.0f;
    const float maxDistSqr = maxDist * maxDist;

    // 1. Node Repulsion (O(N^2) optimized)
    for (int i = 0; i < nodeCount; i++) {
        for (int j = i + 1; j < nodeCount; j++) {
            // AABB Quick Reject (Avoids expensive multiplication if too far)
            float dx = graphNodes[i].position.x - graphNodes[j].position.x;
            if (fabsf(dx) > maxDist) continue;

            float dy = graphNodes[i].position.y - graphNodes[j].position.y;
            if (fabsf(dy) > maxDist) continue;

            float distSqr = (dx * dx) + (dy * dy);
            if (distSqr > maxDistSqr || distSqr == 0.0f) continue;

            float force = repulsion / distSqr;
            force = fminf(force, 50.0f);

            // Manual normalization and scaling (faster than Vector2Normalize)
            float dist = sqrtf(distSqr);
            float forceOverDist = force / dist;

            float dirX = dx * forceOverDist;
            float dirY = dy * forceOverDist;

            graphNodes[i].velocity.x += dirX;
            graphNodes[i].velocity.y += dirY;
            graphNodes[j].velocity.x -= dirX;
            graphNodes[j].velocity.y -= dirY;
        }
    }

    // 2. Edge Attraction (Springs)
    for (int i = 0; i < edgeCount; i++) {
        Node *s = &graphNodes[graphEdges[i].source_idx];
        Node *t = &graphNodes[graphEdges[i].target_idx];

        float dx = t->position.x - s->position.x;
        float dy = t->position.y - s->position.y;
        float dist = sqrtf(dx * dx + dy * dy);

        if (dist == 0.0f) continue;

        float force = (dist - k) * 0.05f;
        float forceOverDist = force / dist;

        float dirX = dx * forceOverDist;
        float dirY = dy * forceOverDist;

        s->velocity.x += dirX;
        s->velocity.y += dirY;
        t->velocity.x -= dirX;
        t->velocity.y -= dirY;
    }

    // 3. Center Gravity & Integration
    float centerX = screenWidth / 2.0f;
    float centerY = screenHeight / 2.0f;

    for (int i = 0; i < nodeCount; i++) {
        if (i == draggedIdx) continue;

        float gravX = (centerX - graphNodes[i].position.x) * centerGravity;
        float gravY = (centerY - graphNodes[i].position.y) * centerGravity;

        graphNodes[i].velocity.x += gravX;
        graphNodes[i].velocity.y += gravY;

        graphNodes[i].position.x += graphNodes[i].velocity.x;
        graphNodes[i].position.y += graphNodes[i].velocity.y;

        graphNodes[i].velocity.x *= damping;
        graphNodes[i].velocity.y *= damping;
    }
}
