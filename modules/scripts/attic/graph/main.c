#include "graph.h"
#include <unistd.h>
#include <objc/objc.h>
#include <objc/message.h>
#include <objc/runtime.h>

Font font;
Camera2D camera;
Vector2 mousePos;
Vector2 worldMouse;

int framesCounter = 0;

const int screenWidth = 1171;
const int screenHeight = 839;
const int xPos = 262;
const int yPos = 125;
const int fps = 120;

const float innerRadius = 10.0f;
const float outerRadius = 30.0f;
const float minNodeRadius = 3.0f;
const float maxNodeRadius = 6.0f;
float labelScale = 1.6f;

void initializeWindow() {
    SetConfigFlags(FLAG_MSAA_4X_HINT | FLAG_WINDOW_RESIZABLE | FLAG_WINDOW_TRANSPARENT);
    InitWindow(screenWidth, screenHeight, "attic-graph");

    id window = (id)GetWindowHandle();
    if (window) {
        ((void (*)(id, SEL, bool))objc_msgSend)(window, sel_registerName("setTitlebarAppearsTransparent:"), true);
        ((void (*)(id, SEL, long))objc_msgSend)(window, sel_registerName("setTitleVisibility:"), 1);
        long style = ((long (*)(id, SEL))objc_msgSend)(window, sel_registerName("styleMask"));
        ((void (*)(id, SEL, long))objc_msgSend)(window, sel_registerName("setStyleMask:"), style | (1 << 15));

        id contentView = ((id (*)(id, SEL))objc_msgSend)(window, sel_registerName("contentView"));
        id superview = ((id (*)(id, SEL))objc_msgSend)(contentView, sel_registerName("superview"));

        struct CG_Point { double x; double y; };
        struct CG_Size { double width; double height; };
        struct NS_Rect { struct CG_Point origin; struct CG_Size size; };
        struct NS_Rect frame = { {0, 0}, {screenWidth, screenHeight} };

        id visualEffectView = ((id (*)(id, SEL))objc_msgSend)((id)objc_getClass("NSVisualEffectView"), sel_registerName("alloc"));
        visualEffectView = ((id (*)(id, SEL, struct NS_Rect))objc_msgSend)(visualEffectView, sel_registerName("initWithFrame:"), frame);

        ((void (*)(id, SEL, long))objc_msgSend)(visualEffectView, sel_registerName("setAutoresizingMask:"), 18);
        ((void (*)(id, SEL, long))objc_msgSend)(visualEffectView, sel_registerName("setMaterial:"), 13);
        ((void (*)(id, SEL, long))objc_msgSend)(visualEffectView, sel_registerName("setState:"), 1);
        ((void (*)(id, SEL, long))objc_msgSend)(visualEffectView, sel_registerName("setBlendingMode:"), 0);

        ((void (*)(id, SEL, id, long, id))objc_msgSend)(superview, sel_registerName("addSubview:positioned:relativeTo:"), visualEffectView, -1, contentView);
    }

    SetWindowPosition(xPos, yPos);
    SetTargetFPS(fps);

    font = LoadFontEx(FONT_PATH, 128, NULL, 255);
    SetTextureFilter(font.texture, TEXTURE_FILTER_BILINEAR);

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

void getInput(int *draggedNodeIndex, bool *isPanning, double *lastClickTime, int *lastClickedNode) {
    static bool isQuitting = false;
    if (IsKeyPressed(KEY_Q) && !isQuitting) {
        isQuitting = true;

        pid_t pid = fork();
        if (pid == 0) {
            freopen("/dev/null", "w", stdout);
            freopen("/dev/null", "w", stderr);
            execlp("aerospace", "aerospace", "close", "--quit-if-last-window", NULL);
            exit(1);
        }
    }

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
                if (graphNodes[hit].hasPdf) openNote(graphNodes[hit].id);
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

            if (graphNodes[i].hasLatexError || !graphNodes[i].hasPdf) {
                DrawRing(graphNodes[i].position, graphNodes[i].radius, graphNodes[i].radius + 2.0f, 0, 360, 36, RED);
                Vector2 exPos = { graphNodes[i].position.x + graphNodes[i].radius + 2.0f, graphNodes[i].position.y - 6.0f };
                DrawTextEx(font, "!", exPos, 14, 1, RED);
            }
            else if (graphNodes[i].labelTexture.id == 0) {
                DrawRing(graphNodes[i].position, graphNodes[i].radius, graphNodes[i].radius + 2.0f, 0, 360, 36, ORANGE);
                Vector2 exPos = { graphNodes[i].position.x + graphNodes[i].radius + 2.0f, graphNodes[i].position.y - 6.0f };
                DrawTextEx(font, "?", exPos, 14, 1, ORANGE);
            }
        }
    EndMode2D();

    for (int i = 0; i < nodeCount; i++) {
        float d = Vector2Distance(worldMouse, graphNodes[i].position);

        if (d >= outerRadius) continue;

        float t = Clamp((outerRadius - d) / (outerRadius - innerRadius), 0.0f, 1.0f);

        float alpha = t;
        if (alpha <= 0.0f) continue;

        float minScale = 0.5f;
        float sizeFactor = minScale + ((1.0f - minScale) * t);

        Vector2 screenPos = GetWorldToScreen2D(graphNodes[i].position, camera);

        float padX = 6.0f * labelScale * sizeFactor;
        float padY = 3.0f * labelScale * sizeFactor;

        Color fg = COL_FG;
        fg.a = (unsigned char)(alpha * 255.0f);
        Color bg = { 0x11, 0x11, 0x11, (unsigned char)(alpha * 204.0f) };

        Vector2 sz;
        float mathScale = 0.35f * labelScale * sizeFactor;
        float fontSize = 12.0f * labelScale * sizeFactor;

        if (graphNodes[i].labelTexture.id != 0) {
            sz = (Vector2){
                graphNodes[i].labelTexture.width * mathScale,
                graphNodes[i].labelTexture.height * mathScale
            };
        } else {
            sz = MeasureTextEx(font, graphNodes[i].label, fontSize, 1);
        }

        float txtX = screenPos.x - sz.x/2;

        float yOffset = 25.0f * labelScale * sizeFactor;
        float txtY = screenPos.y - yOffset;

        DrawRectangleRounded((Rectangle){ txtX - padX, txtY - padY, sz.x + 2*padX, sz.y + 2*padY }, 0.5f, 8, bg);

        if (graphNodes[i].labelTexture.id > 0) {
            DrawTextureEx(graphNodes[i].labelTexture, (Vector2){txtX, txtY}, 0, mathScale, fg);
        } else {
            DrawTextEx(font, graphNodes[i].label, (Vector2){txtX, txtY}, fontSize, 1, fg);
        }
    }

    EndDrawing();
}

void closeWindow() {
    freeGraphMemory();
    freeLabelsMemory();
    UnloadFont(font);
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
        if (framesCounter % 10 == 0) { processPendingTextures(); }

        getInput(&draggedNodeIndex, &isPanning, &lastClickTime, &lastClickedNode);
        updatePhysics(GetScreenWidth(), GetScreenHeight(), draggedNodeIndex);
        draw();
    }

    closeWindow();
    return 0;
}
