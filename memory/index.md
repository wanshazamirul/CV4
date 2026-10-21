# Memory Index
*Fast recall layer. One line per durable item. Hot = recent, Warm = older, Cold = era summaries.*

## Hot (recent, last ~12)
| Tag | Date/time | Keypoint |
|-----|------|----------|
| `first-boot` | <YYYY-MM-DD HH:MM> | Companion initialized. |

## Warm (older, ~20 max)
| Tag | Date/time | Keypoint |
|-----|------|----------|

## Cold (era summaries)
- (compact old eras into one line each when Hot and Warm overflow)

---
*Maintained by the `save` ritual. Caps: hot 12, warm 20. Overflow rotates down, never deleted.*
