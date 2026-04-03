#include <raylib.h>
#include <raymath.h>
#define RAYGUI_IMPLEMENTATION
#include <raygui.h>
#include <cjson/cJSON.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>

#define MAX_NODES 10000
#define MAX_EDGES 20000

#define COL_BG       (Color){ 0x11, 0x11, 0x11, 102 }
#define COL_FG       (Color){ 0xab, 0xb2, 0xbf, 255 }
#define COL_BLUE     (Color){ 0x61, 0xaf, 0xef, 255 }
#define COL_GRAY     (Color){ 0x5c, 0x63, 0x70, 255 }

typedef struct Node { char id[32]; char label[256]; bool has_pdf; Vector2 position; Vector2 velocity; float radius; } Node;
typedef struct Edge { int source_idx; int target_idx; } Edge;

Node graphNodes[MAX_NODES];
Edge graphEdges[MAX_EDGES];
int nodeCount = 0;
int edgeCount = 0;

float k = 10.0f;
float repulsion = 1000.0f;
float damping = 0.8f;
float centerGravity = 0.004f;

bool showGui = false;
int framesCounter = 0;
const int guiWidth = 300;
const float innerRadius = 80.0f;
const float outerRadius = 250.0f;

void OpenNote(const char* id) {
    char command[1024];
    snprintf(command, sizeof(command), "launcher.sh \"%s\" &", id);
    system(command);
}

int FindNodeIndex(const char* id) {
    if (!id) return -1;
    for (int i = 0; i < nodeCount; i++) if (strcmp(graphNodes[i].id, id) == 0) return i;
    return -1;
}

void LoadGraphData(const char* filename, int screenWidth, int screenHeight) {
    char* jsonString = LoadFileText(filename);
    if (!jsonString) return;
    cJSON* json = cJSON_Parse(jsonString);
    if (!json) { UnloadFileText(jsonString); return; }

    cJSON* nodesArray = cJSON_GetObjectItemCaseSensitive(json, "nodes");
    cJSON* nodeItem = NULL;
    nodeCount = 0;
    cJSON_ArrayForEach(nodeItem, nodesArray) {
        if (nodeCount >= MAX_NODES) break;

        // --- SAFE PARSING ---
        cJSON* idObj = cJSON_GetObjectItemCaseSensitive(nodeItem, "id");
        cJSON* labelObj = cJSON_GetObjectItemCaseSensitive(nodeItem, "label");
        cJSON* hasPdfObj = cJSON_GetObjectItemCaseSensitive(nodeItem, "has_pdf");

        if (cJSON_IsString(idObj) && cJSON_IsString(labelObj)) {
            strncpy(graphNodes[nodeCount].id, idObj->valuestring, 31);
            strncpy(graphNodes[nodeCount].label, labelObj->valuestring, 255);
            graphNodes[nodeCount].has_pdf = cJSON_IsTrue(hasPdfObj);

            float angle = (float)nodeCount * (2.0f * PI / 50.0f);
            graphNodes[nodeCount].position = (Vector2){ screenWidth/2.0f + cosf(angle)*50.0f, screenHeight/2.0f + sinf(angle)*50.0f };
            graphNodes[nodeCount].velocity = (Vector2){ 0, 0 };
            graphNodes[nodeCount].radius = 8.0f;
            nodeCount++;
        }
    }

    cJSON* edgesArray = cJSON_GetObjectItemCaseSensitive(json, "edges");
    cJSON* edgeItem = NULL;
    edgeCount = 0;
    cJSON_ArrayForEach(edgeItem, edgesArray) {
        if (edgeCount >= MAX_EDGES) break;
        cJSON* srcObj = cJSON_GetObjectItemCaseSensitive(edgeItem, "source");
        cJSON* tgtObj = cJSON_GetObjectItemCaseSensitive(edgeItem, "target");

        if (cJSON_IsString(srcObj) && cJSON_IsString(tgtObj)) {
            int s_idx = FindNodeIndex(srcObj->valuestring);
            int t_idx = FindNodeIndex(tgtObj->valuestring);
            if (s_idx != -1 && t_idx != -1) {
                graphEdges[edgeCount].source_idx = s_idx;
                graphEdges[edgeCount].target_idx = t_idx;
                edgeCount++;
            }
        }
    }
    cJSON_Delete(json); UnloadFileText(jsonString);
}

void UpdatePhysics(int screenWidth, int screenHeight, int draggedIdx) {
    float curDamping = (framesCounter < 120) ? 0.50f : damping;
    for (int i = 0; i < nodeCount; i++) {
        for (int j = i + 1; j < nodeCount; j++) {
            Vector2 d = Vector2Subtract(graphNodes[i].position, graphNodes[j].position);
            float force = repulsion / fmaxf(1.0f, Vector2LengthSqr(d));
            Vector2 dir = Vector2Scale(Vector2Normalize(d), force);
            graphNodes[i].velocity = Vector2Add(graphNodes[i].velocity, dir);
            graphNodes[j].velocity = Vector2Subtract(graphNodes[j].velocity, dir);
        }
    }
    for (int i = 0; i < edgeCount; i++) {
        Node *s = &graphNodes[graphEdges[i].source_idx]; Node *t = &graphNodes[graphEdges[i].target_idx];
        Vector2 d = Vector2Subtract(t->position, s->position);
        Vector2 dir = Vector2Scale(Vector2Normalize(d), (Vector2Length(d) - k) * 0.05f);
        s->velocity = Vector2Add(s->velocity, dir); t->velocity = Vector2Subtract(t->velocity, dir);
    }
    float centerX = showGui ? (screenWidth + guiWidth) / 2.0f : screenWidth / 2.0f;
    Vector2 center = { centerX, screenHeight / 2.0f };
    for (int i = 0; i < nodeCount; i++) {
        if (i == draggedIdx) continue;
        Vector2 grav = Vector2Scale(Vector2Subtract(center, graphNodes[i].position), centerGravity);
        graphNodes[i].velocity = Vector2Add(graphNodes[i].velocity, grav);
        graphNodes[i].position = Vector2Add(graphNodes[i].position, graphNodes[i].velocity);
        graphNodes[i].velocity = Vector2Scale(graphNodes[i].velocity, curDamping);
    }
}

int main(void) {
    const int screenWidth = 1200;
    const int screenHeight = 840;

    SetConfigFlags(FLAG_WINDOW_RESIZABLE | FLAG_WINDOW_TRANSPARENT);
    InitWindow(screenWidth, screenHeight, "attic");
    SetWindowPosition(525, 250);
    SetTargetFPS(60);

    Camera2D camera = { .target = {screenWidth/2.0f, screenHeight/2.0f}, .offset = {screenWidth/2.0f, screenHeight/2.0f}, .zoom = 1.0f };
    char fontPath[512];
    snprintf(fontPath, sizeof(fontPath), "%s/Library/Fonts/Courier Prime.ttf", getenv("HOME"));
    Font font = LoadFontEx(fontPath, 32, 0, 250);

    LoadGraphData("graph.json", screenWidth, screenHeight);
    int draggedNodeIndex = -1; bool isPanning = false;

    while (!WindowShouldClose()) {
        framesCounter++;
        Vector2 mousePos = GetMousePosition();
        Vector2 worldMouse = GetScreenToWorld2D(mousePos, camera);

        if (IsKeyPressed(KEY_Q)) break;

        if (IsKeyPressed(KEY_TAB)) showGui = !showGui;
        float moveStep = 15.0f / camera.zoom;
        if (IsKeyDown(KEY_H)) camera.target.x -= moveStep; if (IsKeyDown(KEY_L)) camera.target.x += moveStep;
        if (IsKeyDown(KEY_K)) camera.target.y -= moveStep; if (IsKeyDown(KEY_J)) camera.target.y += moveStep;

        float wheel = GetMouseWheelMove();
        if (wheel != 0) { camera.target = worldMouse; camera.offset = mousePos; camera.zoom = fmaxf(0.1f, camera.zoom + wheel * 0.1f); }

        if (!(showGui && mousePos.x < guiWidth)) {
            if (IsMouseButtonPressed(MOUSE_BUTTON_LEFT)) {
                int hit = -1;
                for (int i = 0; i < nodeCount; i++) if (CheckCollisionPointCircle(worldMouse, graphNodes[i].position, graphNodes[i].radius)) { hit = i; break; }
                if (hit != -1) { if (graphNodes[hit].has_pdf) OpenNote(graphNodes[hit].id); draggedNodeIndex = hit; }
                else isPanning = true;
            }
            if (isPanning || IsMouseButtonDown(MOUSE_BUTTON_RIGHT)) camera.target = Vector2Subtract(camera.target, Vector2Scale(GetMouseDelta(), 1.0f / camera.zoom));
        }
        if (IsMouseButtonReleased(MOUSE_BUTTON_LEFT)) { draggedNodeIndex = -1; isPanning = false; }
        if (draggedNodeIndex != -1) {
            graphNodes[draggedNodeIndex].position = worldMouse;
            graphNodes[draggedNodeIndex].velocity = Vector2Scale(GetMouseDelta(), 1.0f / camera.zoom);
        }

        UpdatePhysics(GetScreenWidth(), GetScreenHeight(), draggedNodeIndex);

        BeginDrawing();
            ClearBackground(COL_BG);
            BeginMode2D(camera);
                for (int i = 0; i < edgeCount; i++) DrawLineV(graphNodes[graphEdges[i].source_idx].position, graphNodes[graphEdges[i].target_idx].position, COL_GRAY);
                for (int i = 0; i < nodeCount; i++) {
                    DrawCircleV(graphNodes[i].position, graphNodes[i].radius, graphNodes[i].has_pdf ? COL_BLUE : COL_GRAY);
                    float d = Vector2Distance(worldMouse, graphNodes[i].position);
                    char* txt = (d < innerRadius) ? graphNodes[i].label : (d < outerRadius ? graphNodes[i].id : NULL);
                    if (txt) {
                        Vector2 sz = MeasureTextEx(font, txt, 12, 1);
                        DrawTextEx(font, txt, (Vector2){graphNodes[i].position.x - sz.x/2, graphNodes[i].position.y - 23}, 12, 1, COL_FG);
                    }
                }
            EndMode2D();
            if (GuiButton((Rectangle){ 10, 10, 30, 30 }, "#141#")) showGui = !showGui;
            if (showGui) {
                DrawRectangle(0, 0, guiWidth, GetScreenHeight(), Fade(COL_BG, 0.95f));
                DrawLine(guiWidth, 0, guiWidth, GetScreenHeight(), COL_GRAY);
                GuiGroupBox((Rectangle){ 10, 50, guiWidth - 20, 220 }, "PHYSICS ENGINE");
                GuiSlider((Rectangle){ 120, 80, 160, 20 }, "Edge Length", TextFormat("%2.0f", k), &k, 2, 20);
                GuiSlider((Rectangle){ 120, 120, 160, 20 }, "Repulsion", TextFormat("%2.0f", repulsion), &repulsion, 500, 3000);
                GuiSlider((Rectangle){ 120, 200, 160, 20 }, "Gravity", TextFormat("%2.4f", centerGravity), &centerGravity, 0.0001f, 0.01f);
                if (GuiButton((Rectangle){ 20, 235, guiWidth - 40, 25 }, "Recenter")) {
                    for(int i=0; i<nodeCount; i++) graphNodes[i].position = (Vector2){(GetScreenWidth()+guiWidth)/2.0f, GetScreenHeight()/2.0f};
                    framesCounter = 0;
                }
            }
        EndDrawing();
    }
    UnloadFont(font); CloseWindow(); return 0;
}
