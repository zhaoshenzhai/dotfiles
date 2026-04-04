#include "graph.h"

Node *graphNodes = NULL;
Edge *graphEdges = NULL;

int nodeCount = 0;
int nodeCapacity = 0;
int edgeCount = 0;
int edgeCapacity = 0;

int *pendingNodes = NULL;
int pendingCount = 0;
int pendingCapacity = 0;

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
        if (nodeCount >= nodeCapacity) {
            nodeCapacity = nodeCapacity == 0 ? 128 : nodeCapacity * 2;
            graphNodes = realloc(graphNodes, nodeCapacity * sizeof(Node));
            if (!graphNodes) { fprintf(stderr, "Out of memory\n"); exit(1); }
        }

        cJSON* idObj = cJSON_GetObjectItemCaseSensitive(nodeItem, "id");
        cJSON* labelObj = cJSON_GetObjectItemCaseSensitive(nodeItem, "label");
        cJSON* hasPdfObj = cJSON_GetObjectItemCaseSensitive(nodeItem, "hasPdf");

        if (cJSON_IsString(idObj) && cJSON_IsString(labelObj)) {
            strncpy(graphNodes[nodeCount].id, idObj->valuestring, 31);
            strncpy(graphNodes[nodeCount].label, labelObj->valuestring, 255);

            graphNodes[nodeCount].hasLatexError = false;
            graphNodes[nodeCount].hasPdf = cJSON_IsTrue(hasPdfObj);
            graphNodes[nodeCount].labelTexture = renderLatex(graphNodes[nodeCount].label, &graphNodes[nodeCount].hasLatexError);

            if (graphNodes[nodeCount].labelTexture.id == 0 && !graphNodes[nodeCount].hasLatexError) {
                if (pendingCount >= pendingCapacity) {
                    pendingCapacity = pendingCapacity == 0 ? 128 : pendingCapacity * 2;
                    pendingNodes = realloc(pendingNodes, pendingCapacity * sizeof(int));
                }
                pendingNodes[pendingCount++] = nodeCount;
            }

            float angle = (float)nodeCount * (2.0f * PI / 50.0f);
            graphNodes[nodeCount].position = (Vector2){ screenWidth/2.0f + cosf(angle)*50.0f, screenHeight/2.0f + sinf(angle)*50.0f };
            graphNodes[nodeCount].velocity = (Vector2){ 0, 0 };
            nodeCount++;
        }
    }

    cJSON* edgesArray = cJSON_GetObjectItemCaseSensitive(json, "edges");
    cJSON* edgeItem = NULL;
    edgeCount = 0;

    cJSON_ArrayForEach(edgeItem, edgesArray) {
        if (edgeCount >= edgeCapacity) {
            edgeCapacity = edgeCapacity == 0 ? 256 : edgeCapacity * 2;
            graphEdges = realloc(graphEdges, edgeCapacity * sizeof(Edge));
            if (!graphEdges) { fprintf(stderr, "Out of memory\n"); exit(1); }
        }

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

    int *degrees = calloc(nodeCount, sizeof(int));
    if (!degrees) { fprintf(stderr, "Out of memory\n"); exit(1); }

    for (int i = 0; i < edgeCount; i++) {
        degrees[graphEdges[i].source_idx]++;
        degrees[graphEdges[i].target_idx]++;
    }

    for (int i = 0; i < nodeCount; i++) {
        float d = (float)degrees[i];
        graphNodes[i].radius = minNodeRadius + (maxNodeRadius - minNodeRadius) * (d / (d + ((minNodeRadius + maxNodeRadius) / 2)));
    }

    free(degrees);
    assignNodeColors();
    cJSON_Delete(json);
    UnloadFileText(jsonString);
}

void processPendingTextures(void) {
    if (pendingCount == 0) return;

    for (int i = 0; i < pendingCount; ) {
        int idx = pendingNodes[i];

        graphNodes[idx].labelTexture = renderLatex(graphNodes[idx].label, &graphNodes[idx].hasLatexError);

        if (graphNodes[idx].labelTexture.id != 0 || graphNodes[idx].hasLatexError) {
            pendingNodes[i] = pendingNodes[pendingCount - 1];
            pendingCount--;
        } else {
            i++;
        }
    }
}

void freeGraphMemory(void) {
    if (graphNodes) free(graphNodes);
    if (graphEdges) free(graphEdges);
    if (pendingNodes) free(pendingNodes);

    graphNodes = NULL;
    graphEdges = NULL;
    pendingNodes = NULL;

    nodeCount = nodeCapacity = 0;
    edgeCount = edgeCapacity = 0;
    pendingCount = pendingCapacity = 0;
}
