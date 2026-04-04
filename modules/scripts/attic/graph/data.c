#include "graph.h"

Node graphNodes[MAX_NODES];
Edge graphEdges[MAX_EDGES];
int nodeCount = 0;
int edgeCount = 0;

int findNodeIndex(const char* id) {
    if (!id) return -1;
    for (int i = 0; i < nodeCount; i++) if (strcmp(graphNodes[i].id, id) == 0) return i;
    return -1;
}

void initializeGraph(const char* filename, int screenWidth, int screenHeight) {
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

            graphNodes[nodeCount].labelTexture = renderLatex(graphNodes[nodeCount].label);
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
            int s_idx = findNodeIndex(srcObj->valuestring);
            int t_idx = findNodeIndex(tgtObj->valuestring);
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

    assignNodeColors();
    cJSON_Delete(json);
    UnloadFileText(jsonString);
}
