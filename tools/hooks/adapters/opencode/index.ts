// CV4 behavior spine - opencode adapter.
// Thin plugin: every decision stays in tools/hooks/dispatch.py.
// Fail-open: any error is swallowed; the session continues on the manual.
import { Plugin } from "@opencode/plugin"
import { spawn } from "node:child_process"
import { appendFileSync } from "node:fs"

const CV4_HOME = "__CV4_HOME__"
const DISPATCH = `${CV4_HOME}/tools/hooks/dispatch.sh`
const DEBUG = process.env.CV4_DEBUG === "1"

function debug(line: string) {
  if (!DEBUG) return
  try { appendFileSync("/tmp/opencode/cv4-plugin.log", `${new Date().toISOString()} ${line}\n`) } catch { /* ignore */ }
}

type Result = Record<string, any>

function run(event: string, payload: Result): Promise<Result> {
  return new Promise((resolve) => {
    let settled = false
    const finish = (value: Result) => {
      if (settled) return
      settled = true
      resolve(value)
    }
    try {
      const child = spawn("bash", [DISPATCH, "opencode", event], {
        stdio: ["pipe", "pipe", "ignore"],
      })
      let output = ""
      const timer = setTimeout(() => {
        try { child.kill() } catch { /* ignore */ }
        finish({})
      }, 8000)
      child.stdout.on("data", (chunk) => { output += String(chunk) })
      child.on("error", () => { clearTimeout(timer); finish({}) })
      child.on("close", () => {
        clearTimeout(timer)
        try {
          finish(output.trim() ? JSON.parse(output) : {})
        } catch {
          finish({})
        }
      })
      child.stdin.write(JSON.stringify(payload))
      child.stdin.end()
    } catch {
      finish({})
    }
  })
}

export default Plugin.define({
  id: "cv4-hooks",
  async setup(ctx: any) {
    const seen = new Set<string>()
    let lastSession = ""

    const sidOf = (event: any): string => {
      const sid = String(event?.sessionID || event?.session?.id || lastSession || "unknown")
      if (sid !== "unknown") lastSession = sid
      return sid
    }

    // Prompt admission: inject the ritual/recall block before the model sees it.
    await ctx.session.hook("prompt", async (event: any) => {
      const text = String(event?.prompt?.text || "")
      const sid = sidOf(event)
      debug(`prompt sid=${sid} chars=${text.length}`)
      const out = await run("prompt", { session_id: sid, prompt: text })
      debug(`prompt out keys=${Object.keys(out || {}).join(",")}`)
      if (out?.prompt_context) {
        event.prompt.text = `${text}\n\n${out.prompt_context}`
      }
    })

    // First model call of a session: inject the boot brief into the system context.
    await ctx.session.hook("context", async (event: any) => {
      const sid = sidOf(event)
      const system: any = (event as any).system
      debug(`context sid=${sid} seen=${seen.has(sid)} system=${typeof system} array=${Array.isArray(system)} len=${system?.length ?? "?"}`)
      if (!sid || seen.has(sid)) return
      seen.add(sid)
      const out = await run("session-start", {
        session_id: sid,
        source: "startup",
        cwd: String(ctx?.location?.directory || ""),
      })
      debug(`context out keys=${Object.keys(out || {}).join(",")} ctx=${String(out?.context || "").length}`)
      if (out?.context) {
        event.system.push({ type: "text", text: String(out.context) })
        debug(`context pushed len=${String(out.context).length}`)
      }
    })

    // Tool gate: block the first edit after a bug prompt until recall is acknowledged.
    await ctx.tool.hook("execute.before", async (event: any) => {
      const out = await run("pre-tool", {
        session_id: sidOf(event),
        tool_name: String(event?.tool || ""),
        tool_input: event?.input || {},
      })
      if (out?.block) throw new Error(String(out.reason || "CV4 recall gate"))
    })

    // Tool tracking: activity feed for the checkpoint.
    await ctx.tool.hook("execute.after", async (event: any) => {
      await run("post-tool", {
        session_id: sidOf(event),
        tool_name: String(event?.tool || ""),
        tool_input: event?.input || {},
        status: String(event?.status || ""),
      })
    })

    // Lifecycle events: turn end, session end, compaction.
    const controller = new AbortController()
    void (async () => {
      try {
        for await (const ev of ctx.event.subscribe({ signal: controller.signal })) {
          const sid = String((ev as any)?.properties?.sessionID || "")
          if (!sid) continue
          const type = String((ev as any)?.type || "")
          if (type === "session.idle") {
            await run("stop", { session_id: sid, stop_hook_active: false })
          } else if (type === "session.deleted") {
            await run("session-end", { session_id: sid, reason: "other" })
            seen.delete(sid)
          } else if (type === "session.compacted") {
            await run("pre-compact", { session_id: sid, trigger: "auto" })
          }
        }
      } catch {
        // aborted or unavailable: the manual path stays
      }
    })()

    return () => controller.abort()
  },
})
