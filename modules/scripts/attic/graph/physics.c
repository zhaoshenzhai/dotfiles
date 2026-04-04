#include "graph.h"

float k = 10.0f;
float repulsion = 1000.0f;
float centerGravity = 0.004f;
float damping = 0.8f;
int framesCounter = 0;

void UpdatePhysics(int screenWidth, int screenHeight, int draggedIdx) {
    float curDamping = (framesCounter < 120) ? 0.50f : damping;
    for (int i = 0; i < nodeCount; i++) {
        for (int j = i + 1; j < nodeCount; j++) {
            Vector2 d = Vector2Subtract(graphNodes[i].position, graphNodes[j].position);
            float force = repulsion / fmaxf(1.0f, Vector2LengthSqr(d));
            force = fminf(force, 50.0f);
            if (d.x != 0.0f || d.y != 0.0f) {
                Vector2 dir = Vector2Scale(Vector2Normalize(d), force);
                graphNodes[i].velocity = Vector2Add(graphNodes[i].velocity, dir);
                graphNodes[j].velocity = Vector2Subtract(graphNodes[j].velocity, dir);
            }
        }
    }
    for (int i = 0; i < edgeCount; i++) {
        Node *s = &graphNodes[graphEdges[i].source_idx]; Node *t = &graphNodes[graphEdges[i].target_idx];
        Vector2 d = Vector2Subtract(t->position, s->position);
        Vector2 dir = Vector2Scale(Vector2Normalize(d), (Vector2Length(d) - k) * 0.05f);
        s->velocity = Vector2Add(s->velocity, dir); t->velocity = Vector2Subtract(t->velocity, dir);
    }

    float centerX = screenWidth / 2.0f;
    Vector2 center = { centerX, screenHeight / 2.0f };
    for (int i = 0; i < nodeCount; i++) {
        if (i == draggedIdx) continue;
        Vector2 grav = Vector2Scale(Vector2Subtract(center, graphNodes[i].position), centerGravity);
        graphNodes[i].velocity = Vector2Add(graphNodes[i].velocity, grav);
        graphNodes[i].position = Vector2Add(graphNodes[i].position, graphNodes[i].velocity);
        graphNodes[i].velocity = Vector2Scale(graphNodes[i].velocity, curDamping);
    }
}
