#pragma once
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include <math.h>
#include <raylib.h>
#include <raymath.h>
#include <cjson/cJSON.h>

#define COL_BG   (Color){ 0x00, 0x00, 0x00,   0 }
#define COL_FG   (Color){ 0xff, 0xff, 0xff, 255 }
#define COL_GRAY (Color){ 0x5c, 0x63, 0x70, 255 }

typedef struct Node {
    char id[32]; char label[256]; bool hasPdf; bool hasLatexError;
    Vector2 position; Vector2 velocity; float radius;
    float hue; Color color; Texture2D labelTexture;
} Node;
typedef struct Edge { int source_idx; int target_idx; } Edge;

extern Node *graphNodes;
extern Edge *graphEdges;
extern int nodeCount;
extern int nodeCapacity;
extern int edgeCount;
extern int edgeCapacity;

extern Camera2D camera;
extern Font fontMain;
extern Font fontID;
extern float labelScale;

extern float k;
extern float repulsion;
extern float centerGravity;
extern float damping;

extern const float innerRadius;
extern const float outerRadius;
extern const float minNodeRadius;
extern const float maxNodeRadius;

void updatePhysics(int screenWidth, int screenHeight, int draggedIdx);

void openNote(const char* id);
int findNodeIndex(const char* id);
void initializeGraph(const char* filename, int screenWidth, int screenHeight);
void processPendingTextures(void);
void freeGraphMemory(void);

void initializeLabels(void);
Texture2D renderLatex(const char* latex, bool* has_error);
void freeLabelsMemory(void);

void assignNodeColors(void);
