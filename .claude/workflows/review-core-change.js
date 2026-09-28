export const meta = {
  name: 'review-core-change',
  description: 'Adversarial review of a Chronicles (LegionCore 7.3.5) change: lens reviewers find bugs, one refuter per finding verifies them',
  whenToUse: 'Before building or restarting with a non-trivial core, script, party bot, shop or addon change. args: { ref: "<commit or range, e.g. 5ab0efd or HEAD~3..HEAD; empty = working tree>", intent: "<what the change should do>", lenses: ["crash", "logic", "money", "lua", ...] (optional) }',
  phases: [{ title: 'Review' }, { title: 'Verify' }],
}

const a = args || {}
const REF = a.ref ? `Run \`git show ${a.ref}\` (or \`git diff ${a.ref}\` for a range)` : 'Run `git diff` (the working tree)'
const CTX = `Repo C:/Users/Chr/Documents/GitHub/Chronicles (Chronicles: WoW Legion 7.3.5 build 26972 on LegionCore). ${REF} to see the change, then read the whole functions it touches and the core code they call. Intent of the change: ${a.intent || '(see the commit message)'}.
Live server 184.174.37.33 (ssh -o BatchMode=yes wow@184.174.37.33) is READ-ONLY for you: SELECT queries, reading files, DB2 files via ~/client_parts/wdc1.py. No builds, restarts or writes. Never print secrets (~/legion/etc/*.conf passwords, ~/.website_db, ~/discord-bot/.env). Do not edit files.
Known weak spots of this core: sessions, packet handlers, addon messages (OnPlayerChat) and party bot AI run on MAP threads, not the world thread (World::UpdateSessions skips sessions with a map), so shared statics need a mutex; past-the-end iterators (do/while that ++ before checking end, SelectRandomContainerElement on an empty container); Unit* kept across ticks or in lambdas after the unit is gone; work after the databases closed at shutdown; money paths (auth.account.donate) must check before delivering and charge with a guarded UPDATE.`

const ALL = {
  crash: 'Crashes and freezes: null/dangling pointers, past-the-end iterators, empty containers, thread safety (map threads vs world thread, shared statics), shutdown order, recursion, very slow loops on the map thread.',
  logic: 'Logic: does it do what the intent says in every case (states, edge cases, timers, retries, dead/offline/teleporting units, other maps, groups/raids), and does it break any existing behaviour of the code it touches?',
  money: 'Money and security: free items/tokens, double spend, charge without delivery, spoofed or forged client messages, checks done only on the client, overflow (use uint32/%u for balances), logs (donate_history, character_donate) the refund NPC relies on.',
  lua: 'Client addon Lua/XML: every API, template and function must exist in the 7.3.5 client with that signature (extracted FrameXML may be in the scratchpad under casc/fx; otherwise say what you could not check), nil access before server data arrives, uncached items, taint of protected actions, protocol conformance with the server side.',
  data: 'Data and SQL: every fix file has an undo file that restores the exact previous values, IDs checked against the live DB with SELECTs, DB2 IDs and field positions correct, nothing applied that should wait for a restart.',
}
const lenses = (a.lenses && a.lenses.length ? a.lenses : ['crash', 'logic']).filter(k => ALL[k])
if (!lenses.length) throw new Error('no known lens; use: ' + Object.keys(ALL).join(', '))
log(`Reviewing ${a.ref || 'the working tree'} with lenses: ${lenses.join(', ')}`)

const FIND = { type: 'object', properties: { findings: { type: 'array', items: { type: 'object', properties: {
  title: { type: 'string' }, location: { type: 'string' }, scenario: { type: 'string' }, severity: { type: 'string', description: 'high = can happen in normal play and hurts (crash, data/money loss); medium = rarer or milder; low = cosmetic or theoretical' }, fix: { type: 'string' } },
  required: ['title', 'location', 'scenario', 'severity', 'fix'] } } }, required: ['findings'] }
const VERDICT = { type: 'object', properties: { refuted: { type: 'boolean' }, reasoning: { type: 'string' }, corrected_fix: { type: 'string' } }, required: ['refuted', 'reasoning'] }

const results = await pipeline(lenses,
  lens => agent(`${CTX}\n\nREVIEW LENS: ${ALL[lens]}\nReport only concrete bugs with a scenario you traced through the actual code. An empty list is a fine answer.`, { label: `review:${lens}`, phase: 'Review', schema: FIND }),
  (r, lens) => parallel((r?.findings || []).filter(f => f.severity !== 'low').map(f => () =>
    agent(`${CTX}\n\nTry to REFUTE this finding by tracing the actual code (callers, guards, threads, data). Default to refuted=true unless every step holds.\n\n${JSON.stringify(f, null, 1)}\n\nIf it is real, give the smallest correct fix in corrected_fix (the root cause, in the shared function when several callers have it).`, { label: `verify:${lens}`, phase: 'Verify', schema: VERDICT })
      .then(v => ({ ...f, lens, verdict: v })))).then(vs => ({ lens, low: (r?.findings || []).filter(f => f.severity === 'low'), checked: vs.filter(Boolean) }))
)

const all = results.filter(Boolean)
const dropped = lenses.length - all.length
if (dropped) log(`${dropped} lens(es) returned nothing (agent error or skipped)`)
return {
  confirmed: all.flatMap(x => x.checked.filter(c => !c.verdict.refuted)),
  refuted: all.flatMap(x => x.checked.filter(c => c.verdict.refuted).map(c => c.title)),
  low_unverified: all.flatMap(x => x.low.map(l => ({ lens: x.lens, title: l.title, location: l.location, fix: l.fix }))),
}
