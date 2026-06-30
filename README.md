# Men's Tetris

A classic Tetris clone built with Godot 4. Supports both keyboard and on-screen touch controls.

## Gameplay

- Tetrominoes fall from the top — move and rotate them to fill complete rows
- Clearing lines scores points and increases the level
- Speed increases with each level
- Game over when a new piece can't spawn

### Scoring

| Lines cleared | Points |
|---------------|--------|
| 1 line | 100 × level |
| 2 lines | 200 × level |
| n lines | n × 100 × level |

## Controls

### Keyboard

| Key | Action |
|-----|--------|
| ← / → | Move left / right |
| ↓ | Soft drop |
| ↑ | Rotate |

### Touch (on-screen buttons)

Left · Right · Down · Rotate

## Development

Open the project in **Godot 4.x** and run `main.tscn`.

Board size: 10 × 20 cells at 32 px each.
