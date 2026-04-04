#pragma once
#include <raylib.h>
#include <raymath.h>
#include <cjson/cJSON.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include <math.h>

#ifndef FONT_PATH_MAIN
#define FONT_PATH_MAIN "default_fallback.ttf"
#endif

#ifndef FONT_PATH_ID
#define FONT_PATH_ID "default_fallback.ttf"
#endif

extern Font fontMain;
extern Font fontID;

#define MAX_NODES 10000
#define MAX_EDGES 20000

#define COL_BG   (Color){ 0x00, 0x00, 0x00,   0 }
#define COL_FG   (Color){ 0xab, 0xb2, 0xbf, 255 }
#define COL_BLUE (Color){ 0x61, 0xaf, 0xef, 255 }
#define COL_GRAY (Color){ 0x5c, 0x63, 0x70, 255 }

typedef struct Node {
    char id[32];
    char label[256];
    bool has_pdf;
    Vector2 position;
    Vector2 velocity;
    float radius;
    float hue;
    Color color;
    Texture2D labelTexture;
} Node;
typedef struct Edge { int source_idx; int target_idx; } Edge;

extern Node graphNodes[MAX_NODES];
extern Edge graphEdges[MAX_EDGES];
extern int nodeCount;
extern int edgeCount;

extern float k;
extern float repulsion;
extern float centerGravity;
extern float damping;

extern int framesCounter;

extern const float innerRadius;
extern const float outerRadius;
extern float minNodeRadius;
extern float maxNodeRadius;

void OpenNote(const char* id);
int FindNodeIndex(const char* id);
void LoadGraphData(const char* filename, int screenWidth, int screenHeight);
void UpdatePhysics(int screenWidth, int screenHeight, int draggedIdx);
void AssignNodeColors(void);
Texture2D RenderLatex(const char* latex);
