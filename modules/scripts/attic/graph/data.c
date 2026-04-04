#include "graph.h"
#include <sys/stat.h>
#include <unistd.h>

Node graphNodes[MAX_NODES];
Edge graphEdges[MAX_EDGES];
int nodeCount = 0;
int edgeCount = 0;

typedef struct { char latex[256]; Texture2D tex; } LatexCacheEntry;
LatexCacheEntry sessionCache[200];
int sessionCacheCount = 0;

void OpenNote(const char* id) {
    char command[2048];
    const char* home = getenv("HOME");
    if (!home) home = "";

    snprintf(command, sizeof(command),
        "/etc/profiles/per-user/zhao/bin/launcher \"%s/iCloud/Projects/_attic/notes/%s/%s.pdf\" &", home, id, id);
    system(command);
}

int FindNodeIndex(const char* id) {
    if (!id) return -1;
    for (int i = 0; i < nodeCount; i++) if (strcmp(graphNodes[i].id, id) == 0) return i;
    return -1;
}

unsigned int HashString(const char *str) {
    unsigned int hash = 5381;
    int c;
    while ((c = *str++)) hash = ((hash << 5) + hash) + c;
    return hash;
}

Texture2D RenderLatex(const char* latex) {
    for (int i = 0; i < sessionCacheCount; i++) {
        if (strcmp(sessionCache[i].latex, latex) == 0) return sessionCache[i].tex;
    }

    char cacheDir[512], pngPath[1024], cmd[2048];
    const char* home = getenv("HOME");
    if (!home) home = "/tmp";
    snprintf(cacheDir, sizeof(cacheDir), "%s/.cache/attic/math", home);
    system(TextFormat("mkdir -p %s", cacheDir));

    unsigned int h = HashString(latex);
    snprintf(pngPath, sizeof(pngPath), "%s/%u.png", cacheDir, h);

    if (access(pngPath, F_OK) != 0) {
        char texPath[1024], dviPath[1024];
        snprintf(texPath, sizeof(texPath), "/tmp/attic_%u.tex", h);
        snprintf(dviPath, sizeof(dviPath), "/tmp/attic_%u.dvi", h);

        FILE *f = fopen(texPath, "w");
        // Added xcolor and forced the text to match your COL_FG (#ABB2BF)
        fprintf(f, "\\documentclass[preview,border=2pt]{standalone}\n"
                   "\\usepackage{amsmath,amssymb,amsfonts,xcolor}\n"
                   "\\definecolor{atticfg}{HTML}{FFFFFF}\n"
                   "\\begin{document}\n"
                   "\\color{atticfg}\n"
                   "%s\n\\end{document}", latex);
        fclose(f);

        // Using dvipng is much faster than the PDF + Magick route
        // Increased -D (density) to 600 for sharper, larger renders
        snprintf(cmd, sizeof(cmd),
            "zsh -l -c \"latex -interaction=nonstopmode -output-directory=/tmp %s && "
            "dvipng -bg Transparent -D 600 -o %s /tmp/attic_%u.dvi\" > /dev/null 2>&1",
            texPath, pngPath, h);

        system(cmd);
        remove(texPath);
        remove(dviPath);
        remove(TextFormat("/tmp/attic_%u.log", h));
        remove(TextFormat("/tmp/attic_%u.aux", h));
    }

    if (access(pngPath, F_OK) == 0) {
        Image img = LoadImage(pngPath);
        Texture2D tex = LoadTextureFromImage(img);
        UnloadImage(img);

        // Save to session cache so we don't process this string again
        if (sessionCacheCount < 200) {
            strncpy(sessionCache[sessionCacheCount].latex, latex, 255);
            sessionCache[sessionCacheCount].tex = tex;
            sessionCacheCount++;
        }
        return tex;
    }
    return (Texture2D){0};
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
        cJSON* idObj = cJSON_GetObjectItemCaseSensitive(nodeItem, "id");
        cJSON* labelObj = cJSON_GetObjectItemCaseSensitive(nodeItem, "label");
        cJSON* hasPdfObj = cJSON_GetObjectItemCaseSensitive(nodeItem, "has_pdf");

        if (cJSON_IsString(idObj) && cJSON_IsString(labelObj)) {
            strncpy(graphNodes[nodeCount].id, idObj->valuestring, 31);
            strncpy(graphNodes[nodeCount].label, labelObj->valuestring, 255);

            graphNodes[nodeCount].labelTexture = RenderLatex(graphNodes[nodeCount].label);
            graphNodes[nodeCount].has_pdf = cJSON_IsTrue(hasPdfObj);

            float angle = (float)nodeCount * (2.0f * PI / 50.0f);
            graphNodes[nodeCount].position = (Vector2){ screenWidth/2.0f + cosf(angle)*50.0f, screenHeight/2.0f + sinf(angle)*50.0f };
            graphNodes[nodeCount].velocity = (Vector2){ 0, 0 };
            graphNodes[nodeCount].radius = 4.0f;
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

    int degrees[MAX_NODES] = {0};
    for (int i = 0; i < edgeCount; i++) {
        degrees[graphEdges[i].source_idx]++;
        degrees[graphEdges[i].target_idx]++;
    }

    for (int i = 0; i < nodeCount; i++) {
        float d = (float)degrees[i];
        graphNodes[i].radius = minNodeRadius + (maxNodeRadius - minNodeRadius) * (d / (d + 4.0f));
    }

    AssignNodeColors();
    cJSON_Delete(json); UnloadFileText(jsonString);
}
