#import "graph.h"

void assignNodeColors(void) {
    bool *visited = calloc(nodeCount, sizeof(bool));
    int *queue = malloc(nodeCount * sizeof(int));

    if (!visited || !queue) { fprintf(stderr, "Out of memory\n"); exit(1); }

    for (int i = 0; i < nodeCount; i++) {
        if (visited[i]) continue;

        float baseHue = (float)(rand() % 360);
        int head = 0, tail = 0;

        queue[tail++] = i;
        visited[i] = true;
        graphNodes[i].hue = baseHue;

        while (head < tail) {
            int u = queue[head++];

            for (int e = 0; e < edgeCount; e++) {
                int v = -1;
                if (graphEdges[e].source_idx == u) v = graphEdges[e].target_idx;
                else if (graphEdges[e].target_idx == u) v = graphEdges[e].source_idx;

                if (v != -1 && !visited[v]) {
                    visited[v] = true;
                    graphNodes[v].hue = fmodf(graphNodes[u].hue + 10.0f, 360.0f);
                    queue[tail++] = v;
                }
            }
        }
    }

    for (int i = 0; i < nodeCount; i++) { graphNodes[i].color = ColorFromHSV(graphNodes[i].hue, 0.7f, 1.0f); }

    free(visited);
    free(queue);
}
