#include "graph.h"
#include <objc/objc.h>
#include <objc/message.h>
#include <objc/runtime.h>

Font fontMain;
Font fontID;
Camera2D camera;
Vector2 mousePos;
Vector2 worldMouse;

int framesCounter = 0;

const int screenWidth = 1171;
const int screenHeight = 839;
const int xPos = 262;
const int yPos = 125;
const int fps = 120;

const float innerRadius = 20.0f;
const float outerRadius = 40.0f;
const float minNodeRadius = 4.0f;
const float maxNodeRadius = 8.0f;

void initializeWindow() {
    SetConfigFlags(FLAG_MSAA_4X_HINT | FLAG_WINDOW_RESIZABLE | FLAG_WINDOW_TRANSPARENT);
    InitWindow(screenWidth, screenHeight, "attic");

    id window = (id)GetWindowHandle();
    if (window) {
        ((void (*)(id, SEL, bool))objc_msgSend)(window, sel_registerName("setTitlebarAppearsTransparent:"), true);
        ((void (*)(id, SEL, long))objc_msgSend)(window, sel_registerName("setTitleVisibility:"), 1);
        long style = ((long (*)(id, SEL))objc_msgSend)(window, sel_registerName("styleMask"));
        ((void (*)(id, SEL, long))objc_msgSend)(window, sel_registerName("setStyleMask:"), style | (1 << 15));
    }

    SetWindowPosition(xPos, yPos);
    SetTargetFPS(fps);

    fontMain = LoadFontEx(FONT_PATH_MAIN, 128, NULL, 255);
    fontID = LoadFontEx(FONT_PATH_ID, 128, NULL, 255);

    SetTextureFilter(fontMain.texture, TEXTURE_FILTER_BILINEAR);
    SetTextureFilter(fontID.texture, TEXTURE_FILTER_BILINEAR);

    camera = (Camera2D){ .target = {screenWidth/2.0f, screenHeight/2.0f}, .offset = {screenWidth/2.0f, screenHeight/2.0f}, .zoom = 1.0f };
}

void openNote(const char* id) {
    char command[2048];
    const char* home = getenv("HOME");
    if (!home) home = "";

    snprintf(command, sizeof(command),
        "/etc/profiles/per-user/zhao/bin/launcher \"%s/iCloud/Projects/_attic/notes/%s/%s.pdf\" &", home, id, id);
    system(command);
}

bool getInput(int *draggedNodeIndex, bool *isPanning, double *lastClickTime, int *lastClickedNode) {
    if (IsKeyPressed(KEY_Q)) return false;

    // Camera movement
    float moveStep = 15.0f / camera.zoom;
    if (IsKeyDown(KEY_H) && !IsKeyDown(KEY_LEFT_CONTROL)) camera.target.x -= moveStep;
    if (IsKeyDown(KEY_L) && !IsKeyDown(KEY_LEFT_CONTROL)) camera.target.x += moveStep;
    if (IsKeyDown(KEY_K) && !IsKeyDown(KEY_LEFT_CONTROL)) camera.target.y -= moveStep;
    if (IsKeyDown(KEY_J) && !IsKeyDown(KEY_LEFT_CONTROL)) camera.target.y += moveStep;

    // Zoom and repulsion control
    if (IsKeyDown(KEY_LEFT_CONTROL) || IsKeyDown(KEY_RIGHT_CONTROL)) {
        float zoomStep = 0.1f;
        float repulsionStep = 50.0f;

        if (IsKeyDown(KEY_J)) camera.zoom = Clamp(camera.zoom - zoomStep, 0.5f, 5.0f);
        if (IsKeyDown(KEY_K)) camera.zoom = Clamp(camera.zoom + zoomStep, 0.5f, 5.0f);
        if (IsKeyDown(KEY_H)) repulsion = Clamp(repulsion - repulsionStep, 500.0f, 3000.0f);
        if (IsKeyDown(KEY_L)) repulsion = Clamp(repulsion + repulsionStep, 500.0f, 3000.0f);
    }

    // Touchpad control
    mousePos = GetMousePosition();
    worldMouse = GetScreenToWorld2D(mousePos, camera);
    float wheel = GetMouseWheelMove();
    if (wheel != 0) {
        camera.target = worldMouse;
        camera.offset = mousePos;
        camera.zoom = Clamp(camera.zoom + wheel * 0.1f, 0.5f, 5.0f);
    }

    // Get click information
    if (IsMouseButtonPressed(MOUSE_BUTTON_LEFT)) {
        int hit = -1;
        for (int i = 0; i < nodeCount; i++) {
            if (CheckCollisionPointCircle(worldMouse, graphNodes[i].position, graphNodes[i].radius)) {
                hit = i; break;
            }
        }

        if (hit != -1) {
            if (hit == *lastClickedNode && (GetTime() - *lastClickTime) < 0.3) {
                if (graphNodes[hit].has_pdf) openNote(graphNodes[hit].id);
                *lastClickTime = 0.0;
            } else {
                *lastClickedNode = hit;
                *lastClickTime = GetTime();
            }
            *draggedNodeIndex = hit;
        }
        else {
            *isPanning = true;
            *lastClickedNode = -1;
        }
    }

    // Update camera based on click
    if (*isPanning || IsMouseButtonDown(MOUSE_BUTTON_RIGHT)) {
        camera.target = Vector2Subtract(camera.target, Vector2Scale(GetMouseDelta(), 1.0f / camera.zoom));
    }

    // Release click
    if (IsMouseButtonReleased(MOUSE_BUTTON_LEFT)) { *draggedNodeIndex = -1; *isPanning = false; }
    if (*draggedNodeIndex != -1) {
        graphNodes[*draggedNodeIndex].position = worldMouse;
        graphNodes[*draggedNodeIndex].velocity = Vector2Scale(GetMouseDelta(), 1.0f / camera.zoom);
    }

    return true;
}

void draw() {
    BeginDrawing();
    ClearBackground(COL_BG);
    BeginMode2D(camera);

    for (int i = 0; i < edgeCount; i++) {
        DrawLineV(graphNodes[graphEdges[i].source_idx].position, graphNodes[graphEdges[i].target_idx].position, COL_GRAY);
    }

    for (int i = 0; i < nodeCount; i++) {
        DrawCircleV(graphNodes[i].position, graphNodes[i].radius, graphNodes[i].color);
    }

    for (int i = 0; i < nodeCount; i++) {
        float d = Vector2Distance(worldMouse, graphNodes[i].position);
        float fadeWidth = 15.0f;
        float idAlpha = 0.0f;
        float labelAlpha = 0.0f;

        if (d < outerRadius && d > innerRadius) {
            idAlpha = Clamp((outerRadius - d) / fadeWidth, 0.0f, 1.0f);
        } else if (d <= innerRadius) {
            labelAlpha = Clamp((innerRadius - d) / fadeWidth, 0.0f, 1.0f);
            idAlpha = 1.0f - labelAlpha;
        }

        float padX = 6.0f;
        float padY = 3.0f;

        if (idAlpha > 0.0f) {
            Color fg = COL_FG;
            fg.a = (unsigned char)(idAlpha * 255.0f * 0.6f);
            Color bg = { 0x11, 0x11, 0x11, (unsigned char)(idAlpha * 204.0f * 0.6f) };

            Vector2 sz = MeasureTextEx(fontID, graphNodes[i].id, 10, 1);
            float txtX = graphNodes[i].position.x - sz.x/2;
            float txtY = graphNodes[i].position.y - 22;

            DrawRectangleRounded((Rectangle){ txtX - padX, txtY - padY, sz.x + 2*padX, sz.y + 2*padY }, 0.5f, 8, bg);
            DrawTextEx(fontID, graphNodes[i].id, (Vector2){txtX, txtY}, 10, 1, fg);
        }

        if (labelAlpha > 0.0f) {
            Color fg = COL_FG;
            fg.a = (unsigned char)(labelAlpha * 255.0f);
            Color bg = { 0x11, 0x11, 0x11, (unsigned char)(labelAlpha * 204.0f) };

            Vector2 sz;
            float mathScale = 0.2f;

            if (graphNodes[i].labelTexture.id != 0) {
                sz = (Vector2){
                    graphNodes[i].labelTexture.width * mathScale,
                    graphNodes[i].labelTexture.height * mathScale
                };
            } else {
                sz = MeasureTextEx(fontMain, graphNodes[i].label, 12, 1);
            }

            float txtX = graphNodes[i].position.x - sz.x/2;
            float txtY = graphNodes[i].position.y - 25;

            DrawRectangleRounded((Rectangle){ txtX - padX, txtY - padY, sz.x + 2*padX, sz.y + 2*padY }, 0.5f, 8, bg);

            if (graphNodes[i].labelTexture.id > 0) {
                DrawTextureEx(graphNodes[i].labelTexture, (Vector2){txtX, txtY}, 0, mathScale, fg);
            } else {
                DrawTextEx(fontMain, graphNodes[i].label, (Vector2){txtX, txtY}, 12, 1, fg);
            }
        }
    }

    EndMode2D();
    EndDrawing();
}

void closeWindow() {
    UnloadFont(fontMain);
    UnloadFont(fontID);
    CloseWindow();
}

int main(void) {
    initializeWindow();
    initializeLabels();
    initializeGraph("graph.json", screenWidth, screenHeight);

    int draggedNodeIndex = -1;
    bool isPanning = false;
    double lastClickTime = 0.0;
    int lastClickedNode = -1;

    while (!WindowShouldClose()) {
        framesCounter++;

        if (framesCounter % 30 == 0) {
            for (int i = 0; i < nodeCount; i++) {
                if (graphNodes[i].labelTexture.id == 0) {
                    graphNodes[i].labelTexture = renderLatex(graphNodes[i].label);
                }
            }
        }

        if (!getInput(&draggedNodeIndex, &isPanning, &lastClickTime, &lastClickedNode)) { break; }
        updatePhysics(GetScreenWidth(), GetScreenHeight(), draggedNodeIndex);
        draw();
    }

    closeWindow();
    return 0;
}
