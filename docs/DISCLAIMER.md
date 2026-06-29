# Disclaimer

## TL;DR

**This script violates Roblox's Terms of Service. Use it on an alt account on a private server. The authors are not responsible for bans, ToS strikes, or any consequence.**

---

## What this script does

This is a Lua script that runs inside the Roblox client via a third-party mobile executor (Delta, Codex, Fluxus, etc.). It:

- Reads the game's in-memory state (player positions, health, teams, item drops, beds)
- Fires the game's network remotes to perform actions (attack, collect items, buy from shop, break beds)
- Modifies the local player's properties (WalkSpeed, JumpPower, CanCollide, PlatformStand)
- Draws 2D overlays on top of the game (ESP boxes, tracers, text labels)

It does **NOT**:
- Inject DLLs into the Roblox process
- Read process memory from outside (the `external-reference/` folder has a Python project that does — kept for educational comparison only)
- Modify server-side state directly (everything goes through the game's own remotes)
- Steal accounts, credentials, or personal data
- Spread to other users

## Risks

1. **Account ban.** Roblox actively bans accounts using cheats. Use an alt.
2. **Executor malware.** Delta, Codex, and Fluxus are third-party apps. Download them only from their official websites. The script itself is open source — audit it before running.
3. **Server-side anti-cheat.** Even with executor-level bypass of Byfron/Hyperion, the server can detect impossible actions (e.g. collecting items you're nowhere near). The script includes anti-cheat-friendliness (spawn guards, rate limits) but is not bulletproof.
4. **Game updates break remotes.** Easy.gg updates Bedwars regularly. When they do, controller paths may shift and remote extraction may fail. The Spy feature helps discover new remotes.
5. **Executor function availability.** The script requires `debug.getupvalue`, `debug.getconstants`, `debug.getproto`, `hookmetamethod`, `getrawmetatable`, `Drawing.new`, `writefile`/`readfile`, and `game:HttpGet`. All UNC-standard, but verify your executor supports them.

## Responsible use

If you choose to use this script:

- **Use an alt account.** Never your main.
- **Use a private server.** Don't ruin public matches for other players.
- **Don't stream or record.** Clip-sharing gets accounts flagged faster.
- **Audit the code.** This is open source under MIT. Read it before running.
- **Report bugs, not players.** If the script breaks, open a GitHub issue. Don't harass other players.

## Educational intent

This project exists to teach:

- How external Roblox tooling works (Knit, Flamework, remote extraction)
- How to build a premium mobile UI in Luau (custom library, no Rayfield dep)
- How game anti-cheat interacts with client-side tools
- The difference between external memory cheats (Python + pymem) and in-process Lua scripts

It is not designed to give anyone a competitive advantage in public matches.

## Legal

Roblox Corporation's Terms of Service prohibit modifying the client, using third-party executors, and gaining unfair advantages. By using this script, you accept the risk of account termination.

The authors of this script:
- Do not distribute executors
- Do not sell access to this script
- Do not provide support for bypassing anti-cheat
- Are not affiliated with Roblox Corporation, Easy.gg, Delta, Codex, or any executor project

## License

MIT — see [`LICENSE`](../LICENSE). You are free to fork, modify, and redistribute. The authors take no responsibility for how you use it.
