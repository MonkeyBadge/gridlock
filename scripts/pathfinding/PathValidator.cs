using Godot;
using System.Collections.Generic;

/// <summary>
/// Validates tower placement via BFS flood-fill from the exit outward.
/// Checks that all spawn points remain reachable from the exit
/// after a tentative tower placement (without modifying the real grid).
/// This is the pre-check described in ADR-04.
/// </summary>
public partial class PathValidator : GodotObject
{
    /// <summary>
    /// Check whether placing a tower at tentativeBlockCell would still leave
    /// all spawn positions reachable from the exit.
    /// </summary>
    /// <param name="width">Grid width in cells.</param>
    /// <param name="height">Grid height in cells.</param>
    /// <param name="passable">Flat boolean array (x + y*width). Current passable state.</param>
    /// <param name="spawnPositions">All spawn points that must remain reachable.</param>
    /// <param name="exitCell">The exit cell (BFS starts here).</param>
    /// <param name="tentativeBlockCell">The cell the player wants to place a tower on.</param>
    /// <returns>True if all spawns are still reachable; false if placement would block a path.</returns>
    public bool IsPathValid(
        int width,
        int height,
        Godot.Collections.Array<bool> passable,
        Godot.Collections.Array<Vector2I> spawnPositions,
        Vector2I exitCell,
        Vector2I tentativeBlockCell)
    {
        // Immediate rejection: cannot block spawn or exit cells
        foreach (var spawn in spawnPositions)
        {
            if (tentativeBlockCell == spawn)
                return false;
        }
        if (tentativeBlockCell == exitCell)
            return false;

        // Build a local copy of the passable array with tentative block applied
        bool[] tempPassable = new bool[width * height];
        for (int i = 0; i < passable.Count; i++)
            tempPassable[i] = passable[i];

        tempPassable[tentativeBlockCell.X + tentativeBlockCell.Y * width] = false;

        // BFS flood-fill from the exit outward
        bool[] visited = new bool[width * height];
        var queue = new Queue<Vector2I>();

        int exitIdx = exitCell.X + exitCell.Y * width;
        visited[exitIdx] = true;
        queue.Enqueue(exitCell);

        // Four cardinal neighbor offsets (ADR-06: no diagonals)
        Vector2I[] offsets = new Vector2I[]
        {
            new Vector2I(1, 0),
            new Vector2I(-1, 0),
            new Vector2I(0, 1),
            new Vector2I(0, -1)
        };

        while (queue.Count > 0)
        {
            Vector2I current = queue.Dequeue();

            foreach (var offset in offsets)
            {
                int nx = current.X + offset.X;
                int ny = current.Y + offset.Y;

                if (nx < 0 || nx >= width || ny < 0 || ny >= height)
                    continue;

                int neighborIdx = nx + ny * width;
                if (visited[neighborIdx] || !tempPassable[neighborIdx])
                    continue;

                visited[neighborIdx] = true;
                queue.Enqueue(new Vector2I(nx, ny));
            }
        }

        // All spawn positions must have been visited (reachable from exit)
        foreach (var spawn in spawnPositions)
        {
            int spawnIdx = spawn.X + spawn.Y * width;
            if (!visited[spawnIdx])
                return false;
        }

        return true;
    }
}
