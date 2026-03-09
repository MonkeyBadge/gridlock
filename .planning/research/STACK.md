# Stack Research

> Researched: 2026-03-09
> Project: 3D Maze-Builder Tower Defense — Steam Early Access target (2025–2026)
> Developer profile: Solo/small team indie

---

## Recommended Engine: Godot 4

Godot 4 (currently 4.3.x stable, with 4.4 in RC as of early 2026) is the clear choice
for this project. The reasoning is specific to the game's constraints, not general
preference:

- **Cost**: Completely free and open-source (MIT license). No revenue share, no runtime
  fee surprises (Unity's 2023 Runtime Fee debacle is a cautionary tale). For an indie
  team targeting Early Access with uncertain revenue, zero licensing cost is a real
  advantage.
- **3D is production-ready**: Godot 4 rewrote its renderer from scratch (Vulkan-based,
  with a Forward+ and Mobile renderer). It handles the visual fidelity needed for a
  stylized 3D TD game. Not AAA-tier, but entirely sufficient.
- **NavigationServer3D is built-in and multithreaded**: This is the single most important
  technical point for this game. Dynamic navmesh baking with async rebaking, obstacle
  avoidance, and NavigationAgent3D nodes exist out of the box. Crucially, navigation
  queries can run off the main thread in Godot 4.
- **GDScript + C# + GDExtension**: Fast iteration with GDScript for game logic, with
  C# (via .NET 8) or GDExtension (C++) available for performance-critical pathfinding
  code.
- **Steamworks integration**: The GodotSteam plugin (mature, actively maintained,
  open-source) provides full Steamworks SDK access. Used by dozens of shipped Steam
  games.
- **Small team fit**: Scene/node architecture scales well for small teams. No asset store
  dependency means the codebase stays coherent. Editor is lightweight.
- **Community momentum**: After Unity's 2023 missteps, a significant wave of indie
  developers migrated to Godot. Documentation, tutorials, and community support for Godot
  4 have improved dramatically through 2024–2025.

---

## Engine Comparison

| Engine         | Pros                                                                                                                                   | Cons                                                                                                                                                                      | Verdict                                                              |
|----------------|----------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------|
| **Godot 4**    | Free/MIT; mature NavigationServer3D with async rebaking; GDScript for fast iteration + C#/.NET 8 for perf; GodotSteam plugin; lightweight editor; no revenue share | 3D tooling less mature than Unity/UE5; smaller asset marketplace; GDScript has no JIT (hot paths need C# or GDExtension); some rough edges in 3D animation tooling        | **Recommended.** Best fit for indie budget, dynamic pathfinding needs, and Steam target. |
| **Unity 6**    | Massive ecosystem; DOTS/ECS for extreme entity performance; strong Asset Store; excellent documentation; widespread tutorial coverage   | Runtime Fee history creates trust deficit; subscription costs for Pro features; DOTS has steep learning curve; Unity 6 still stabilizing post-restructuring (2024 layoffs) | **Avoid.** Licensing risk, cost, and DOTS complexity outweigh the ecosystem benefits for a small team. |
| **Unreal 5**   | Nanite/Lumen for stunning visuals; robust NavMesh + RecastNavigation; Blueprint + C++; Epic MegaGrants available                       | 5% gross revenue royalty above $1M; massive engine footprint (100GB+); C++ compile times brutal for solo dev; overkill for stylized indie TD; steep onboarding curve      | **Avoid for this project.** Engineering overhead and royalty terms are not indie-friendly at Early Access scale. |

### Why not Unity specifically

Unity's Runtime Fee announcement (later partially reversed) demonstrated that the pricing
model can change retroactively. For a game that may have many installs but uncertain
revenue (Early Access is volatile), the per-install fee model — even if currently paused —
represents ongoing business risk. Unity 6 (formerly Unity 2023 LTS) is more stable than
Unity 5.x cycles, but trust has been damaged. More practically: Unity's equivalent of
Godot's NavigationServer requires either the expensive AI Navigation package or DOTS
NavMesh, both of which add complexity that a small team should avoid.

### Why not Unreal specifically

Unreal 5 is genuinely excellent for 3D. The obstacle is engineering cost, not capability.
A solo developer will spend disproportionate time fighting the C++ toolchain, shader
compilation, and Blueprint-to-C++ integration rather than building the game. The 5%
royalty only applies above $1M gross, which sounds fine, but Early Access games should be
designed with every cost structure in mind. Godot achieves 90% of what this game needs
at a fraction of the operational complexity.

---

## Language

**Recommendation: GDScript for gameplay logic + C# (.NET 8) for pathfinding and
performance-critical systems.**

### GDScript (primary)
- Python-like syntax, tightly integrated with Godot's scene/node model
- No compilation step — edit and run immediately, critical for fast iteration on game
  feel (tower placement, enemy behavior, wave logic, roguelite runs)
- Sufficient performance for: UI, game state, tower/enemy definitions, status effects,
  boss scripting, meta progression
- Version: GDScript as implemented in Godot 4.3+

### C# (.NET 8) (for hot paths)
- Use for: the pathfinding layer, enemy tick logic if running 200+ enemies, any system
  that profiles as a bottleneck
- Full .NET 8 support in Godot 4.2+. Compiled, JIT-optimized, significantly faster than
  GDScript for tight loops
- Can call into GDScript nodes and vice versa — not a wall between the two
- Tradeoff: requires .NET SDK setup; export builds are slightly larger
- Version: .NET 8 (LTS, supported through Nov 2026); avoid .NET 9 for now (non-LTS)

### GDExtension (C++) — use only if necessary
- Maximum performance, equivalent to engine internals
- Only warranted if C# pathfinding still cannot meet frame budget with 500+ enemies
  simultaneously rerouting. This is unlikely for a stylized indie TD
- Adds significant build complexity — cross-platform compilation, GDExtension API
  surface changes between Godot minor versions

### What NOT to use for language
- **Rust via GDExtension**: Technically possible (gdext crate), but the ecosystem is
  immature for game development at this scale. Not worth the friction for an indie team.
- **Pure GDScript for everything**: Viable for prototyping, but will hit a wall once
  you have 150+ enemies recalculating paths on tower placement. Profile first, then
  migrate hot paths to C#.

---

## Pathfinding Approach

**Recommendation: Godot 4 NavigationServer3D for navmesh + custom A* grid layer
(using Godot's AStar3D class) for tower-as-wall logic, with async rebaking.**

This game's pathfinding is the most technically demanding aspect of the design. Towers
ARE the maze walls — meaning the navigation graph changes every time a tower is placed,
and every living enemy must re-route. This requires a specific architecture:

### Layer 1: Grid-based A* (primary pathing logic)

Because towers are placed on a discrete grid and physically block paths, the most
reliable approach is a **custom grid graph** on top of Godot's `AStar3D` class:

- Represent the play field as a 2D grid of nodes (even though the game is 3D). Each
  cell is either passable or blocked.
- When a tower is placed, mark that cell blocked and call `astar.set_point_disabled(id, true)`.
- Re-run pathfinding from each enemy's current position to the goal. With a well-implemented
  A* and a grid of ~50x50 (2500 nodes), a single path query takes microseconds. 200 enemies
  querying simultaneously is well within a single frame budget if done in C#.
- `AStar3D` is Godot's built-in, C++-implemented A* class. It is fast and pathfinding
  queries can be issued from any thread in Godot 4.

**Key optimization — path invalidation rather than full recalc:**
- Tag each enemy with the tower-placement epoch when their path was calculated
- On tower placement, increment a global epoch counter
- Enemies check their epoch each frame; only recalculate if stale
- Stagger recalculations across frames using a queue (e.g., recalc 20 enemies per frame
  rather than all 200 at once)

### Layer 2: Godot NavigationServer3D (secondary, for 3D avoidance)

Use NavigationServer3D and `NavigationAgent3D` for:
- Local obstacle avoidance between enemies (so they don't stack on the same cell)
- Smooth 3D movement along the A* path (the A* path gives waypoints; NavigationAgent
  smooths the movement)
- Async navmesh rebaking when towers are placed (use `NavigationServer3D.bake_from_source_geometry_data_async()`)

Do NOT rely on NavigationServer3D alone for the tower-blocking logic — navmesh rebaking
has latency (even async). The AStar3D grid approach is deterministic and immediate.

### Specific implementation notes

```
# Godot 4 C# pseudocode for the pathfinding architecture

// AStarGrid2D (Godot 4.1+) — even better than AStar3D for pure grid games
// Godot 4.1 introduced AStarGrid2D which handles rectangular grids natively
// Use this instead of manually building AStar3D node graphs

var grid = new AStarGrid2D();
grid.Region = new Rect2I(0, 0, mapWidth, mapHeight);
grid.CellSize = new Vector2(cellSize, cellSize);
grid.DefaultComputeHeuristic = AStarGrid2D.Heuristic.Manhattan;
grid.DiagonalMode = AStarGrid2D.DiagonalModeEnum.Never; // TD games rarely want diagonal
grid.Update();

// On tower placement:
grid.SetPointSolid(towerCell, true);
// Notify all enemies to recalculate (via epoch or signal)
```

`AStarGrid2D` (Godot 4.1+) is the correct tool here — it handles rectangular grids
natively without manual node graph construction, supports solid-cell marking, and is
implemented in C++ (fast even from GDScript, extremely fast from C#).

### What NOT to use for pathfinding
- **Unity DOTS NavMesh**: Only relevant if you chose Unity; mentioned because it's
  sometimes cited as the "right" answer for many-agent pathfinding. True for Unity, but
  not applicable here.
- **Full navmesh-only approach**: Navmesh rebaking cannot be instant. For a game where
  tower placement must immediately affect pathing, a grid A* layer is mandatory.
- **Flowfield pathfinding**: Excellent for RTSes with uniform movement costs and massive
  unit counts (1000+). For a TD with 50-300 enemies on a discrete grid, it is
  over-engineered. A* per-enemy is simpler and sufficient.
- **Dijkstra from goal**: Some TD implementations pre-compute a Dijkstra map from the
  goal outward (every cell gets a cost-to-goal value). This is efficient for updates
  (O(cells) per tower placement, O(1) per enemy step), and worth considering if enemy
  counts exceed 500. Note it for future optimization.

---

## Design Tools

### 3D Asset Creation

| Tool | Purpose | Cost | Notes |
|------|---------|------|-------|
| **Blender 4.x** | Primary 3D modeling, UV unwrapping, rigging, animation | Free (GPL) | Industry standard for indie. Excellent Godot export via `.glb` (GLTF 2.0). Avoid `.fbx` where possible — `.glb` is Godot's native format. Version 4.2+ has solid USD pipeline if needed later. |
| **Blender** (same) | Sculpting for hero assets / boss models | Free | Sculpt mode is capable for organic shapes. Use Multires modifier. |
| **Blockbench** | Low-poly / voxel-adjacent tower and enemy models | Free | Excellent for the chunky stylized aesthetic common in TD games. Exports `.glb` directly. Lower barrier than full Blender workflow for towers/props. |

### Texturing / Materials

| Tool | Purpose | Cost |
|------|---------|------|
| **Krita** | Texture painting, 2D concept art, UI elements | Free |
| **Materialize** (by Bounding Box Software) | Generates normal/roughness/AO maps from diffuse textures | Free | Useful for quick PBR material creation from hand-painted textures. |
| **Substance 3D Painter** | High-quality PBR texturing | $19.99/mo (Creative Cloud) | Skip for early development. Only worthwhile if visual quality becomes a differentiator. |

### Level / Map Design

| Tool | Purpose | Cost |
|------|---------|------|
| **Godot Editor (built-in)** | Map layout, scene composition, CSG for rapid prototyping | Free | Use CSG (Constructive Solid Geometry) meshes in Godot for rapid level blockout before committing to Blender meshes. |
| **Godot Terrain3D plugin** | If the game has terrain-based maps | Free (MIT, on GitHub) | Community plugin; actively maintained as of 2025. Not needed if maps are flat grid-based. |
| **Tiled Map Editor** | Grid layout planning / wave design visualization | Free | Even for 3D games, Tiled is useful for designing the 2D grid logic that drives A* pathing. Export as JSON, parse in Godot. |

### UI Design

| Tool | Purpose | Cost |
|------|---------|------|
| **Figma** (free tier) | UI mockups, icon design, HUD layout planning | Free (up to 3 projects) | Design UI flows before building them in Godot. The free tier is sufficient for an indie project. |
| **Godot Theme Editor (built-in)** | Implementing UI themes in engine | Free | Godot 4's Control node theming is powerful. Design in Figma, implement in Godot. |
| **Inkscape** | Vector icons, UI elements | Free | SVG export; Godot can import SVG for UI icons at runtime (scalable). |

### Version Control / Project Management

| Tool | Purpose | Cost |
|------|---------|------|
| **Git + GitHub/GitLab** | Source control | Free (for private repos with limits) | Use `.gitattributes` for LFS on binary assets (textures, audio). |
| **Git LFS** | Large file storage for 3D assets | Free tier (1GB), then paid | Essential once asset sizes grow. |

---

## Performance Tooling

### In-Engine Profiling (Godot 4)

| Tool | Purpose |
|------|---------|
| **Godot Debugger — Profiler tab** | Built-in frame profiler. Shows time per function call, script vs. engine time breakdown. First stop for any performance investigation. Use the "Profiler" tab in the bottom panel during play-in-editor. |
| **Godot Debugger — Monitor tab** | Real-time graphs for: physics time, render time, draw calls, navigation queries, memory. Pin "Navigation Map Updates" to watch rebake cost on tower placement. |
| **Godot Debugger — Visual Profiler** | GPU-side profiling. Shows render passes, shader time. Use when draw call count or shader complexity is suspected. Available in Godot 4.2+. |
| **`Performance` singleton (code)** | `Performance.get_monitor(Performance.TIME_FPS)` etc. Use to emit custom in-game overlays during playtesting. |
| **`print_fps` + custom overlay** | Quick in-game frame counter. Wire to a Label node during development. |

### External Profiling

| Tool | Purpose |
|------|---------|
| **RenderDoc** | GPU frame capture and analysis. Free. Works with Godot 4's Vulkan renderer. Use when GPU is the bottleneck — inspect draw calls, texture sampling, overdraw. |
| **Tracy Profiler** | CPU-side, low-overhead sampling profiler. Free and open-source. Godot 4 has optional Tracy integration (compile with `use_tracy=yes`). Useful for profiling C# pathfinding code at sub-millisecond granularity. |
| **Visual Studio / Rider profiler** | For C# code specifically. JetBrains Rider's profiler (bundled with Rider) is excellent for identifying hot paths in the pathfinding layer. |
| **Windows Performance Analyzer (WPA)** | ETW-based system profiler on Windows. Useful for identifying OS-level bottlenecks (thread scheduling, memory allocation). |

### TD-Specific Optimization Patterns

**Enemy systems:**
- Use a custom `EnemyManager` singleton rather than letting each enemy be a fully
  autonomous scene. The manager ticks all enemies in a single C# loop — avoids per-node
  overhead of Godot's `_Process` virtual dispatch.
- Object pooling: pre-allocate enemy instances at wave start, recycle on death. Avoid
  `queue_free()` / `Instantiate()` mid-wave for enemies. Godot 4 has lower instantiation
  cost than Godot 3, but pooling is still the right pattern at scale.
- Separate enemy visual update rate from logic update rate. Logic can run at 20Hz;
  visuals (position interpolation, animation) run at full frame rate.

**Pathfinding:**
- Profile the A* recalculation cost before optimizing. On a 64x64 grid in C#,
  AStarGrid2D path queries typically complete in <0.1ms. For 200 enemies, even sequential
  recalculation is ~20ms — one frame at 60fps. Staggering across frames buys headroom.
- Cache path results. If two enemies are at the same grid cell, they share a path.
- Use `AStarGrid2D.GetPointPath()` (returns `Vector2[]`) and convert to world coordinates
  in one pass.

**Rendering:**
- Keep draw calls low. Use MultiMeshInstance3D for enemies — render 200 enemies as a
  single draw call with per-instance transform/color data. This is the single biggest
  rendering win for TD games.
- Use LOD (Level of Detail) on enemy meshes. Godot 4 has `VisibilityNotifier3D` and
  GeometryInstance LOD properties.
- Static towers: mark tower meshes as static and let Godot bake them into an occlusion
  culling structure. Use `ReflectionProbe` sparingly.

**Status effects (Frost/Poison/Burn):**
- Represent status as a bitmask on each enemy struct, not as child nodes. Avoid
  `add_child(status_effect_scene)` — use shader parameters or `MultiMesh` instance
  colors to drive VFX.
- A single `StatusEffectManager` singleton ticks all active effects; enemies register/
  unregister. Avoids distributed `_Process` overhead.

---

## What NOT to Use

| Technology | Reason to Avoid |
|-----------|-----------------|
| **Unity** (any version) | Runtime Fee trust deficit; DOTS complexity for small team; subscription costs; Unity 6 still stabilizing. Ecosystem advantages don't outweigh risks for this project. |
| **Unreal Engine 5** | Engineering overhead too high for solo/small team; C++ compile times; 5% royalty; Blueprints alone insufficient for complex pathfinding; engine footprint excessive. |
| **Godot 3.x** | Legacy; lacks multithreaded NavigationServer, lacks AStarGrid2D, lacks Vulkan renderer, lacks .NET 8 support. Do not start a new project on Godot 3. |
| **GameMaker** | 2D-first engine. 3D support exists but is marginal and not well-documented for complex use cases. Wrong tool for a 3D game. |
| **Defold** | 2D-first; small community; limited 3D ecosystem. |
| **Flowfield pathfinding** (for this game) | Overkill for sub-300 enemy counts on a discrete grid. Adds complexity without proportionate benefit. Revisit only if profiling shows A* as a bottleneck above 500 enemies. |
| **Substance 3D Painter** (early dev) | Cost not justified until art style is locked and visual quality is a differentiator. Use Krita + Materialize first. |
| **Photon / Mirror networking** | This is a single-player game. Do not add multiplayer infrastructure unless the design explicitly requires it. |
| **Pure GDScript for pathfinding** | Will hit performance limits. Use C# (AStarGrid2D) for the pathfinding layer from the start — migration later is painful. |
| **Godot's NavigationServer alone (no grid A*)** | Navmesh rebaking has inherent latency; cannot guarantee immediate path updates on tower placement. Grid A* must be the primary layer. |
| **.fbx format for 3D assets** | Use `.glb` (GLTF 2.0) for all Godot imports. `.fbx` is proprietary, has importer quirks, and lacks features of modern GLTF. Blender 4.x exports clean `.glb`. |
| **C++ GDExtension (from day one)** | Adds cross-platform build complexity and slower iteration. Start with GDScript + C#. Only reach for GDExtension if C# profiling proves insufficient — which is unlikely. |

---

## Confidence

| Recommendation | Confidence | Reasoning |
|---------------|------------|-----------|
| **Godot 4 as engine** | High | Strong fit on all specific axes: dynamic pathfinding (AStarGrid2D, async NavigationServer3D), cost (MIT), Steam integration (GodotSteam), small team ergonomics. The main risk is 3D tooling maturity vs. Unity — but for a stylized TD, Godot 4.3's renderer is more than capable. |
| **GDScript + C# split** | High | Well-established pattern in the Godot 4 community. .NET 8 support is stable in Godot 4.2+. The split is appropriate to the performance profile of this game. |
| **AStarGrid2D for pathfinding** | High | Directly matches the game's discrete grid constraint. It is purpose-built for this use case, C++-implemented, and thread-safe in Godot 4. The epoch-based staggered recalculation pattern is proven in shipped TD games. |
| **Blender 4.x for 3D assets** | High | Industry consensus for indie 3D. GLTF pipeline to Godot is mature and well-documented. No real alternative at this price point. |
| **Blockbench for tower/enemy models** | Medium | Excellent for stylized/low-poly aesthetics common in indie TD. Depends on target art style — if the game aims for high-fidelity organic models, Blender is the only tool. |
| **Figma for UI mockups** | High | Best-in-class for UI design at any price. Free tier is sufficient. |
| **Godot Debugger + RenderDoc + Tracy** | High | This is the standard profiling stack for Godot 4 + Vulkan. Tracy integration is compile-flag optional but extremely powerful for C# hot path analysis. |
| **MultiMeshInstance3D for enemies** | High | This is the documented, benchmarked approach for rendering many instances in Godot. Not a speculation — it is the correct tool for this use case. |
| **Avoiding flowfields** | Medium | Correct for current design (sub-300 enemies, discrete grid). If design shifts toward 1000+ enemies with complex movement costs, flowfields become worth revisiting. |
| **Avoiding Unity/UE5** | High | The cost and complexity arguments are concrete and specific to this project's profile. Both engines are excellent at scale; neither is the right fit for an indie solo/small team TD on a Steam Early Access budget. |

---

## Version Reference (as of early 2026)

| Software | Recommended Version |
|----------|-------------------|
| Godot Engine | 4.3.x stable (or 4.4 stable when released) |
| .NET / C# | .NET 8 LTS |
| GodotSteam plugin | Latest release targeting Godot 4.x (check godotsteam.com) |
| Blender | 4.2 LTS or 4.3+ |
| Blockbench | Latest stable |
| Figma | Web (free tier) |
| RenderDoc | Latest stable |
| Tracy Profiler | Latest stable (v0.10+) |
| Tiled Map Editor | 1.10+ |

---

*Research based on engine documentation, community reports, and shipped game analysis
as of early 2026. Engine version numbers should be verified at release time.*
