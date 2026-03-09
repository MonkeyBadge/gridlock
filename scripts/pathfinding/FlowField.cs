using Godot;
using System.Collections.Generic;

/// <summary>
/// Computes a flow field via Dijkstra's algorithm from the exit cell outward.
/// All enemies read from the resulting direction array to know which way to move.
/// This is the performance-critical pathfinding layer (ADR-01, ADR-02).
/// </summary>
public partial class FlowField : GodotObject
{
    /// <summary>
    /// Incremented on each successful Compute() call.
    /// Enemies cache this version and re-read direction when it changes.
    /// </summary>
    public int Version { get; private set; } = 0;

    /// <summary>
    /// Compute the flow field for the given grid.
    /// Uses BFS/Dijkstra from exitCell outward through passable cells.
    /// Each cell's direction points toward the neighbor with the minimum distance to exit.
    /// </summary>
    /// <param name="width">Grid width in cells.</param>
    /// <param name="height">Grid height in cells.</param>
    /// <param name="passable">Flat boolean array (x + y*width). True = enemy can walk here.</param>
    /// <param name="exitCell">The grid coordinate of the exit cell.</param>
    /// <returns>
    /// Direction array (x + y*width). Each element is one of:
    ///   (1,0), (-1,0), (0,1), (0,-1) — the cardinal direction toward the exit.
    ///   (0,0) — this cell IS the exit, or is unreachable.
    /// </returns>
    public Godot.Collections.Array<Vector2I> Compute(
        int width,
        int height,
        Godot.Collections.Array<bool> passable,
        Vector2I exitCell)
    {
        int total = width * height;
        int[] dist = new int[total];
        Vector2I[] directions = new Vector2I[total];

        // Initialize distances to max and directions to zero
        for (int i = 0; i < total; i++)
        {
            dist[i] = int.MaxValue;
            directions[i] = Vector2I.Zero;
        }

        int exitIdx = exitCell.X + exitCell.Y * width;
        dist[exitIdx] = 0;

        var queue = new Queue<Vector2I>();
        queue.Enqueue(exitCell);

        // Four cardinal neighbor offsets (ADR-06: no diagonals)
        Vector2I[] offsets = new Vector2I[]
        {
            new Vector2I(1, 0),
            new Vector2I(-1, 0),
            new Vector2I(0, 1),
            new Vector2I(0, -1)
        };

        // BFS from exit outward
        while (queue.Count > 0)
        {
            Vector2I current = queue.Dequeue();
            int currentDist = dist[current.X + current.Y * width];

            foreach (var offset in offsets)
            {
                int nx = current.X + offset.X;
                int ny = current.Y + offset.Y;

                // Bounds check
                if (nx < 0 || nx >= width || ny < 0 || ny >= height)
                    continue;

                int neighborIdx = nx + ny * width;

                // Passability check
                if (!passable[neighborIdx])
                    continue;

                // Relax distance
                int newDist = currentDist + 1;
                if (dist[neighborIdx] > newDist)
                {
                    dist[neighborIdx] = newDist;
                    queue.Enqueue(new Vector2I(nx, ny));
                }
            }
        }

        // Assign directions: each reachable cell points toward the neighbor with minimum dist
        for (int y = 0; y < height; y++)
        {
            for (int x = 0; x < width; x++)
            {
                int cellIdx = x + y * width;

                // Unreachable cells and the exit itself keep direction (0,0)
                if (dist[cellIdx] == int.MaxValue)
                    continue;

                Vector2I cellPos = new Vector2I(x, y);
                if (cellPos == exitCell)
                    continue;

                // Find which neighbor has the minimum distance
                Vector2I bestDir = Vector2I.Zero;
                int bestDist = int.MaxValue;

                foreach (var offset in offsets)
                {
                    int nx = x + offset.X;
                    int ny = y + offset.Y;

                    if (nx < 0 || nx >= width || ny < 0 || ny >= height)
                        continue;

                    int neighborIdx = nx + ny * width;
                    if (dist[neighborIdx] < bestDist)
                    {
                        bestDist = dist[neighborIdx];
                        bestDir = offset;
                    }
                }

                directions[cellIdx] = bestDir;
            }
        }

        Version++;
        return new Godot.Collections.Array<Vector2I>(directions);
    }
}
