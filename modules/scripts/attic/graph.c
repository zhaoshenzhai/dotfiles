#include "raylib.h"
#include "cJSON.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>

#define MAX_NODES 2000
#define MAX_EDGES 5000

typedef struct Node {
    char id[32];
    char label[256];
    bool has_pdf;
    Vector2 position;
    Vector2 velocity;
    float radius;
    Color color;
} Node;

typedef struct Edge {
    int source_idx;
    int target_idx;
} Edge;

Node graphNodes[MAX_NODES];
int nodeCount = 0;

Edge graphEdges[MAX_EDGES];
int edgeCount = 0;

// Executes the launcher script in the background using the node's ID
void OpenNote(const char* id) {
    char command[1024];
    snprintf(command, sizeof(command), "launcher.sh \"%s\" &", id);
    printf("Executing: %s\n", command);
    system(command);
}

// Helper to resolve string IDs to array indices for edges
int FindNodeIndex(const char* id) {
    for (int i = 0; i < nodeCount; i++) {
        if (strcmp(graphNodes[i].id, id) == 0) return i;
    }
    return -1;
}

// Parses the graph.json file using cJSON
void LoadGraphData(const char* filename, int screenWidth, int screenHeight) {
    char* jsonString = LoadFileText(filename);
    if (jsonString == NULL) {
        printf("Failed to load %s\n", filename);
        return;
    }

    cJSON* json = cJSON_Parse(jsonString);
    if (json == NULL) {
        printf("Error parsing JSON\n");
        UnloadFileText(jsonString);
        return;
    }

    // 1. Parse Nodes
    cJSON* nodesArray = cJSON_GetObjectItemCaseSensitive(json, "nodes");
    cJSON* nodeItem = NULL;
    nodeCount = 0;

    cJSON_ArrayForEach(nodeItem, nodesArray) {
        if (nodeCount >= MAX_NODES) break;

        cJSON* id = cJSON_GetObjectItemCaseSensitive(nodeItem, "id");
        cJSON* label = cJSON_GetObjectItemCaseSensitive(nodeItem, "label");
        cJSON* has_pdf = cJSON_GetObjectItemCaseSensitive(nodeItem, "has_pdf");

        if (cJSON_IsString(id) && cJSON_IsString(label)) {
            strncpy(graphNodes[nodeCount].id, id->valuestring, 31);
            strncpy(graphNodes[nodeCount].label, label->valuestring, 255);

            graphNodes[nodeCount].has_pdf = cJSON_IsTrue(has_pdf);

            // Scatter nodes randomly to start
            graphNodes[nodeCount].position = (Vector2){
                (float)(rand() % screenWidth),
                (float)(rand() % screenHeight)
            };
            graphNodes[nodeCount].velocity = (Vector2){ 0, 0 };
            graphNodes[nodeCount].radius = 15.0f;
            graphNodes[nodeCount].color = graphNodes[nodeCount].has_pdf ? DARKBLUE : GRAY;

            nodeCount++;
        }
    }

    // 2. Parse Edges
    cJSON* edgesArray = cJSON_GetObjectItemCaseSensitive(json, "edges");
    cJSON* edgeItem = NULL;
    edgeCount = 0;

    cJSON_ArrayForEach(edgeItem, edgesArray) {
        if (edgeCount >= MAX_EDGES) break;

        cJSON* source = cJSON_GetObjectItemCaseSensitive(edgeItem, "source");
        cJSON* target = cJSON_GetObjectItemCaseSensitive(edgeItem, "target");

        if (cJSON_IsString(source) && cJSON_IsString(target)) {
            int s_idx = FindNodeIndex(source->valuestring);
            int t_idx = FindNodeIndex(target->valuestring);

            if (s_idx != -1 && t_idx != -1) {
                graphEdges[edgeCount].source_idx = s_idx;
                graphEdges[edgeCount].target_idx = t_idx;
                edgeCount++;
            }
        }
    }

    cJSON_Delete(json);
    UnloadFileText(jsonString);
}

// Basic Force-Directed Layout Algorithm (Fruchterman-Reingold inspired)
void UpdatePhysics(int screenWidth, int screenHeight) {
    float k = 80.0f;           // Ideal edge length (spring resting length)
    float repulsion = 3000.0f; // Force pushing nodes apart
    float damping = 0.85f;     // Friction to stop infinite oscillation
    float centerGravity = 0.05f; // Pulls everything toward the middle of the screen

    // 1. Calculate Repulsion (Every node pushes every other node away)
    for (int i = 0; i < nodeCount; i++) {
        for (int j = i + 1; j < nodeCount; j++) {
            Vector2 delta = {
                graphNodes[i].position.x - graphNodes[j].position.x,
                graphNodes[i].position.y - graphNodes[j].position.y
            };

            float distSq = delta.x * delta.x + delta.y * delta.y;
            if (distSq < 1.0f) distSq = 1.0f; // Prevent division by zero

            float force = repulsion / distSq;
            float dist = sqrtf(distSq);
            Vector2 dir = { delta.x / dist, delta.y / dist };

            graphNodes[i].velocity.x += dir.x * force;
            graphNodes[i].velocity.y += dir.y * force;
            graphNodes[j].velocity.x -= dir.x * force;
            graphNodes[j].velocity.y -= dir.y * force;
        }
    }

    // 2. Calculate Attraction (Edges act as springs pulling connected nodes together)
    for (int i = 0; i < edgeCount; i++) {
        int s = graphEdges[i].source_idx;
        int t = graphEdges[i].target_idx;

        Vector2 delta = {
            graphNodes[t].position.x - graphNodes[s].position.x,
            graphNodes[t].position.y - graphNodes[s].position.y
        };

        float distSq = delta.x * delta.x + delta.y * delta.y;
        float dist = sqrtf(distSq);
        if (dist < 1.0f) dist = 1.0f;

        // Hooke's Law variation
        float force = (dist - k) * 0.05f;
        Vector2 dir = { delta.x / dist, delta.y / dist };

        graphNodes[s].velocity.x += dir.x * force;
        graphNodes[s].velocity.y += dir.y * force;
        graphNodes[t].velocity.x -= dir.x * force;
        graphNodes[t].velocity.y -= dir.y * force;
    }

    // 3. Apply Forces, Gravity, and Damping
    Vector2 center = { screenWidth / 2.0f, screenHeight / 2.0f };
    for (int i = 0; i < nodeCount; i++) {
        // Center gravity prevents the graph from flying off-screen
        graphNodes[i].velocity.x += (center.x - graphNodes[i].position.x) * centerGravity;
        graphNodes[i].velocity.y += (center.y - graphNodes[i].position.y) * centerGravity;

        graphNodes[i].position.x += graphNodes[i].velocity.x;
        graphNodes[i].position.y += graphNodes[i].velocity.y;

        graphNodes[i].velocity.x *= damping;
        graphNodes[i].velocity.y *= damping;
    }
}

int main(void) {
    const int screenWidth = 1200;
    const int screenHeight = 800;

    SetConfigFlags(FLAG_WINDOW_RESIZABLE);
    InitWindow(screenWidth, screenHeight, "The Attic - Knowledge Graph");
    SetTargetFPS(60);

    LoadGraphData("graph.json", screenWidth, screenHeight);

    // To allow dragging the entire graph or nodes later
    int draggedNodeIndex = -1;

    while (!WindowShouldClose()) {
        int currentWidth = GetScreenWidth();
        int currentHeight = GetScreenHeight();

        // 1. Interaction
        Vector2 mousePos = GetMousePosition();

        if (IsMouseButtonPressed(MOUSE_BUTTON_LEFT)) {
            for (int i = 0; i < nodeCount; i++) {
                if (CheckCollisionPointCircle(mousePos, graphNodes[i].position, graphNodes[i].radius)) {
                    if (graphNodes[i].has_pdf) {
                        OpenNote(graphNodes[i].id);
                    }
                    draggedNodeIndex = i;
                    break;
                }
            }
        }

        if (IsMouseButtonReleased(MOUSE_BUTTON_LEFT)) {
            draggedNodeIndex = -1;
        }

        if (draggedNodeIndex != -1) {
            graphNodes[draggedNodeIndex].position = mousePos;
            graphNodes[draggedNodeIndex].velocity = (Vector2){0, 0};
        }

        // 2. Physics Step
        UpdatePhysics(currentWidth, currentHeight);

        // 3. Draw
        BeginDrawing();
            ClearBackground(RAYWHITE);

            // Draw Edges first so they render under the nodes
            for (int i = 0; i < edgeCount; i++) {
                int s = graphEdges[i].source_idx;
                int t = graphEdges[i].target_idx;
                DrawLineV(graphNodes[s].position, graphNodes[t].position, LIGHTGRAY);
            }

            // Draw Nodes
            for (int i = 0; i < nodeCount; i++) {
                DrawCircleV(graphNodes[i].position, graphNodes[i].radius, graphNodes[i].color);
                DrawCircleLines(graphNodes[i].position.x, graphNodes[i].position.y, graphNodes[i].radius, BLACK);

                // Draw Label
                int textWidth = MeasureText(graphNodes[i].label, 10);
                DrawText(graphNodes[i].label,
                         graphNodes[i].position.x - (textWidth / 2.0f),
                         graphNodes[i].position.y - graphNodes[i].radius - 15,
                         10, DARKGRAY);
            }

            DrawText(TextFormat("Nodes: %d | Edges: %d", nodeCount, edgeCount), 10, 10, 20, DARKGRAY);
        EndDrawing();
    }

    CloseWindow();
    return 0;
}
