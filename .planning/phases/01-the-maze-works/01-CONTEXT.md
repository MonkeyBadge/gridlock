# Phase 1: The Maze Works - Context

**Gathered:** 2026-03-09
**Status:** Ready for planning

<domain>
## Phase Boundary

A player can place towers on a 3D grid map, watch enemies pathfind through the maze they build, and lose lives when enemies reach the exit — with waves launching on a timer or on demand. No damage or combat yet. This phase is the playable foundation: grid, pathfinding, enemy movement, wave modes, and HUD.

</domain>

<decisions>
## Implementation Decisions

### Camera & Navigation
- Default angle: top-down with tilt, approximately 60° from vertical (always reads as 3D)
- Player can tilt the camera further or flatten it toward top-down
- Pan only — no horizontal orbit around the map
- 3 defined zoom levels: Overview (full map), Standard (default play), Detail (close-up)
- Zoom transitions are smooth/animated, not instant snapping
- Pan controls: both edge-scrolling/WASD and click-and-drag supported
- Hard stop at map edges — camera does not float past boundaries
- Quick camera reset button: one key snaps back to default angle and position
- During combat: free-roam camera, player can also click an enemy or tower to follow it
- Boss auto-pan (camera slides to boss spawn on entry): optional toggle in settings — off by default handled in Phase 5

### Tower Placement Feel
- Tower selection: HUD panel + keyboard hotkeys (both supported)
- Ghost preview: translucent tower model follows cursor on the grid
  - Green ghost = valid placement
  - Red ghost = invalid placement
- Towers can be placed anytime — during waves and between waves
- Enemies re-route immediately when a tower is placed mid-wave
- Invalid placement feedback: ghost turns red + small toast message ("Path blocked — enemies must have a route")
- No confirmation step — single click places the tower

### Path Visualization
- Style: glowing directional arrows on the ground along the enemy route
- Toggleable: on by default, player can hide for a cleaner view
- Path updates instantly (no animation) when a tower is placed or removed
- Path always shows the current shortest valid route from spawn to exit

### Wave HUD & Controls
- Layout: top bar (lives, wave counter, gold, countdown timer) + bottom panel (tower selection)
- Always-visible info: lives remaining, current wave / total waves, gold/resources, wave timer countdown
- Send Wave button (Player-Triggered mode): visible on screen + Spacebar shortcut both work
- Send Wave button placement: prominent but not center-obscuring — player should never miss it

### Claude's Discretion
- Exact visual styling of the grid (cell size, line color, opacity)
- HUD typography, color palette, and icon design
- Exact zoom level distances and pan speed values
- Error toast animation style and duration
- Arrow animation style for path visualization (speed, glow intensity)

</decisions>

<specifics>
## Specific Ideas

- "Top-down with tilt" feel — grid must always read as 3D, even at the flattest player-accessible angle
- Ghost preview colors (green/red) must be immediately readable — primary way players understand valid vs invalid placement
- Path arrows should feel alive — animated flow toward the exit, not static

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- None yet — greenfield project

### Established Patterns
- Engine: Godot 4, GDScript for gameplay logic, C# for pathfinding layer
- Pathfinding: Flow field (Dijkstra from exit outward) — one shared direction map all enemies read from
- Path validation on tower placement: BFS flood-fill pre-check (cheaper than A*, runs only on player action)
- Enemy rendering: MultiMeshInstance3D for draw-call efficiency at high enemy counts

### Integration Points
- All subsequent phases build on the grid and flow-field system established here
- Tower panel (bottom HUD) will be expanded in Phase 2 with damage/upgrade UI
- Camera system will be referenced in Phase 5 for boss auto-pan toggle

</code_context>

<deferred>
## Deferred Ideas

- None — discussion stayed within Phase 1 scope

</deferred>

---

*Phase: 01-the-maze-works*
*Context gathered: 2026-03-09*
