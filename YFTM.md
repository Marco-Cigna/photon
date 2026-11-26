# Photon for Yearn for the Mines

This branch (`yftm`) is the Photon build the Yearn for the Mines pack ships: Photon's
`v1.3-maintenance` line (the code behind `photon_v1.3b.zip`) plus fixes for the pack's
Minecraft 26.1.2 / Iris 1.11.4 / Voxy setup.

| Fix | Branch |
|---|---|
| Enchantment glint lit like a surface on 26.1+ (it washed held items out to a see-through purple and glowed at night) | `fix/glint-26.1` |
| Backport of upstream #609: translucent entity draws (glint, the A-10's nozzle glow, JEG cockpit screens) no longer vanish in front of Voxy LOD terrain | `fix/voxy-translucent-entities` |
| Entity shadows off by default and in the High profile (Ultra keeps them): with the JEG fleet in view they cost about 6 ms a frame on an RTX 3080 at 1440p (52 → 76 fps, 2026-11-26; remeasured with the JEG vehicle glass and glow drawing again: 46 → 82 fps, and 59 → 101 with JEG yftm.28's vehicle culling). Only players who never set the option themselves get the new default | `yftm` |

## Releasing

Merge or commit fixes into `yftm`, then tag and push:

```
git tag v1.3b-yftm.2
git push origin v1.3b-yftm.2
```

The `Release` workflow zips `shaders/` and `LICENSE` into **`photon-yftm.zip`** and publishes
it as a GitHub release. The asset keeps that name in every release on purpose: Iris saves a
pack's options as `<file name>.txt` and remembers the active pack by file name, so a new name
at each update would reset everyone's Photon settings and turn shaders off.
`shaders/yftm-version.txt` inside the zip says which release it is.

## In the pack

The pack manager follows GitHub releases for entries added from a repository link: paste
`https://github.com/Marco-Cigna/photon` on the Find tab, and **Update all** moves the entry to
each newer release. The manager needs its shader-pack patch for this (it originally took only
`.jar` assets into `mods/`); with it, a `.zip` asset goes to `shaderpacks/` as a client entry.

When switching the pack from Modrinth's `photon_v1.3b.zip` to `photon-yftm.zip`, each player
should copy `shaderpacks/photon_v1.3b.zip.txt` to `shaderpacks/photon-yftm.zip.txt` (their
options) and pick the new pack once in Iris, or set `shaderPack=photon-yftm.zip` in
`config/iris.properties`.

## Licence

Photon's licence allows redistributing modified copies free of charge, outside monetised
platforms such as Modrinth and CurseForge, with the licence included. Releases here are
GitHub-only and every zip contains `LICENSE`.
