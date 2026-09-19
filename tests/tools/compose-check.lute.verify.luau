--!strict

local Test = require "../harness"
local fs = require "@std/fs"
local process = require "@lute/process"
local readableRules = require "../../tools/lib/readable-rules"
local consumerRules = require "../../tools/lib/consumer-rules"
local Author = require "../../authoring"

local describe, it, expect = Test.describe, Test.it, Test.expect

local STAGE = "build/compose-check-spec"

local function stage(files: { [string]: string })
	process.run { "rm", "-rf", STAGE }
	process.run { "mkdir", "-p", STAGE }
	for name, contents in files do
		local full = STAGE .. "/" .. name
		local directory = string.match(full, "^(.*)/[^/]+$")
		if directory ~= nil then
			process.run { "mkdir", "-p", directory }
		end
		fs.writeStringToFile(full, contents)
	end
end

local function run_at(root: string): (boolean, string)
	local result = process.run { "lute", "run", "tools/compose-check.luau", "--root", root }
	return result.ok, result.stdout .. result.stderr
end

local function run(extra: { string }?): (boolean, string)
	local argv = { "lute", "run", "tools/compose-check.luau", "--root", STAGE }
	if extra ~= nil then
		for _, argument in extra do
			table.insert(argv, argument)
		end
	end
	local result = process.run(argv)
	return result.ok, result.stdout .. result.stderr
end

local function fingerprint(root: string): string
	local result = process.run { "sh", "-c", ("find %s -type f | sort | xargs shasum"):format(root) }
	return result.stdout
end

local function generatedRegistrySource(): string
	return Author.bake.registryModule {
		name = "PropRegistry",
		set = Author.set {
			name = "props",
			idKey = "id",
			entries = { { id = "torch", model = "TorchA" } },
		},
		mapping = {
			{ field = "id", attribute = "PropId" },
			{ field = "model", attribute = "PropModel" },
		},
	}
end

describe("compose-check", function()
	it("accepts ordinary calls whose argument is named scope", function()
		stage {
			["screen.luau"] = [[
local scope = {}
local refused = Generate.isRefusal(scope)
return json.serialize(scope), refused
]],
		}
		local ok, output = run()
		process.run { "rm", "-rf", STAGE }
		expect(ok):toBe(true)
		expect(output):toContain "nothing found"
	end)

	it("reports an invalid cell destructuring with a code and a fix, and exits non-zero", function()
		stage { ["screen.luau"] = "local health, setter = Compose.cell(0)\n" }
		local ok, output = run()
		process.run { "rm", "-rf", STAGE }
		expect(ok):toBe(false)
		expect(output):toContain "CMP016"
		expect(output):toContain "certain"
		expect(output):toContain "Compose.cell(x)"
		expect(output):toContain "screen.luau:1"
	end)

	it("marks the heuristic rule as likely and does not fail on it alone", function()
		stage { ["screen.luau"] = "local label = title(use)\n" }
		local ok, output = run()
		process.run { "rm", "-rf", STAGE }
		expect(ok):toBe(true)
		expect(output):toContain "CMP011"
		expect(output):toContain "likely"
		expect(output):toContain "false positive"
	end)

	it("does not report a reactive body called with the reader", function()
		stage { ["screen.luau"] = "local rows = render(use)\nlocal value = source(use)\n" }
		local ok, output = run()
		process.run { "rm", "-rf", STAGE }
		expect(ok):toBe(true)
		expect(output):toContain "nothing found"
	end)

	it("reports every occurrence, not just the first", function()
		stage {
			["screen.luau"] = "local a, setA = Compose.cell(0)\nlocal b, setB = Compose.cell(0)\n",
		}
		local ok, output = run()
		process.run { "rm", "-rf", STAGE }
		expect(ok):toBe(false)
		expect(output):toContain "screen.luau:1"
		expect(output):toContain "screen.luau:2"
	end)

	it("skips a vendored copy of Compose", function()
		stage { ["vendor/compose/thing.luau"] = "local value, setter = Compose.cell(0)\n" }
		local ok, output = run()
		process.run { "rm", "-rf", STAGE }
		expect(ok):toBe(true)
		expect(output):toContain "nothing found"
	end)

	it("writes JSON with the same findings", function()
		stage { ["screen.luau"] = "local value, setter = Compose.cell(0)\n" }
		local report = "build/compose-check-spec.json"
		local ok = run { "--json", report }
		local contents = fs.readFileToString(report)
		process.run { "rm", "-rf", STAGE }
		process.run { "rm", "-f", report }
		expect(ok):toBe(false)
		expect(contents):toContain '"schemaVersion": 1'
		expect(contents):toContain '"code": "CMP016"'
		expect(contents):toContain '"confidence": "certain"'
		expect(contents):toContain '"line": 1'
	end)

	it("filters to one code", function()
		stage { ["screen.luau"] = "title(use)\nlocal value, setter = Compose.cell(0)\n" }
		local _, output = run { "--code", "CMP016" }
		process.run { "rm", "-rf", STAGE }
		expect(output):toContain "CMP016"
		expect(string.find(output, "CMP011", 1, true) == nil):toBe(true)
	end)

	it("requires option tables for structure through documented aliases", function()
		stage {
			["screen.luau"] = [[
local C = require(Packages.compose.core)
local keyed = C.keyed
local ordered = C.OrderedCollection
keyed(players, Row, keyOf)
ordered(items, Row)
]],
		}
		local ok, output = run()
		process.run { "rm", "-rf", STAGE }
		expect(ok):toBe(false)
		expect(output):toContain "CMP017"
		expect(output):toContain "screen.luau:4"
		expect(output):toContain "screen.luau:5"
	end)

	it("rejects unknown keyed and ordered option fields", function()
		stage {
			["screen.luau"] = [[
local keyed = Compose.keyed
local ordered = Compose.OrderedCollection
local a = keyed { from = rows, keyOf = id, render = Row }
local b = ordered { from = rows, magic = 2, render = Row }
]],
		}
		local ok, output = run()
		process.run { "rm", "-rf", STAGE }
		expect(ok):toBe(false)
		expect(output):toContain "CMP018"
		expect(output):toContain "keyOf"
		expect(output):toContain "magic"
	end)

	it("rejects unknown options on every high-level composition primitive", function()
		stage {
			["screen.luau"] = [[
Compose.OrderedCollection { from = rows, render = Row, magic = true }
Compose.LayerStack { from = layers, render = Layer, retain = "all" }
Compose.MountBudget { from = work, mountsPerFrame = 2, render = Item, defer = true }
Compose.createFocusScope { from = actions, select = keyOf }
Compose.createPool { create = make, destroy = drop, capacity = 4 }
]],
		}
		local ok, output = run()
		process.run { "rm", "-rf", STAGE }
		expect(ok):toBe(false)
		expect(output):toContain "magic"
		expect(output):toContain "retain"
		expect(output):toContain "defer"
		expect(output):toContain "select"
		expect(output):toContain "capacity"
	end)

	it("accepts canonical high-level composition forms", function()
		stage {
			["screen.luau"] = [[
local OrderedCollection = Compose.OrderedCollection
OrderedCollection { from = rows, key = keyOf, render = Row }
Compose.LayerStack { from = layers, key = keyOf, retention = "all", render = Layer }
Compose.MountBudget { from = work, key = keyOf, priority = priorityOf, mountsPerFrame = 2, render = Item }
Compose.createFocusScope { from = actions, key = keyOf, disabled = disabled, position = positionOf, wrap = true }
Compose.createPool { create = make, reset = reset, destroy = drop, maxRetained = 4 }
]],
		}
		local ok, output = run()
		process.run { "rm", "-rf", STAGE }
		expect(ok):toBe(true)
		expect(output):toContain "nothing found"
	end)

	it("rejects missing required high-level options", function()
		stage {
			["screen.luau"] = [[
Compose.MountBudget { from = work, render = Item }
Compose.createPool { create = make, destroy = drop }
]],
		}
		local ok, output = run()
		process.run { "rm", "-rf", STAGE }
		expect(ok):toBe(false)
		expect(output):toContain "CMP025"
		expect(output):toContain "mountsPerFrame"
		expect(output):toContain "maxRetained"
	end)

	it("reads options past an if-expression in an option body", function()
		stage {
			["screen.luau"] = [[
Compose.keyed {
	from = function(use)
		local root = readSource(use, getRoot)
		return if root ~= nil then { root } else {}
	end,
	key = function(root)
		return root
	end,
	render = function(rootCell)
		local mode = if big then "Frame" else "TextLabel"
		return create(mode) { Name = "BodyMount" }
	end,
}
]],
		}
		local ok, output = run()
		process.run { "rm", "-rf", STAGE }
		expect(ok):toBe(true)
		expect(output):toContain "nothing found"
	end)

	it("keeps a component body intact past nested statement ifs and generic-type annotations", function()
		stage {
			["screen.luau"] = [[
local function Screen(runtime, Compose, props)
	if props.ready then
		if props.visible then
			prime()
		end
	end
	local latest: Source<Fired?>
	if props.fired ~= nil then
		latest = props.fired
	end
	local count = Compose.cell(0)
	return count
end
return Screen
]],
		}
		local ok, output = run()
		process.run { "rm", "-rf", STAGE }
		expect(ok):toBe(true)
		expect(output):toContain "nothing found"
	end)

	it("still reports a module-scope cell after an else-nested if closes", function()
		stage {
			["screen.luau"] = [[
local function Screen(runtime, Compose, props)
	if props.ready then
		return props.value
	else
		if props.fallback then
			return 0
		end
	end
	return 1
end
local tally = Compose.cell(0)
return { Screen = Screen, tally = tally }
]],
		}
		local _, output = run()
		process.run { "rm", "-rf", STAGE }
		expect(output):toContain "CMP030"
	end)

	it("recognises tooling by the scanned path including the root", function()
		stage {
			["lute/shared/sets.luau"] = 'local Author = require("@root/vendor/compose-authoring/authoring")\n',
		}
		local ok, output = run_at(STAGE .. "/lute")
		process.run { "rm", "-rf", STAGE }
		expect(ok):toBe(true)
		expect(output):toContain "nothing found"
	end)

	it("rejects imports through internal Compose modules", function()
		stage {
			["screen.luau"] = "local Cell = require(Packages.compose.core.reactive.cell)\n",
		}
		local ok, output = run()
		process.run { "rm", "-rf", STAGE }
		expect(ok):toBe(false)
		expect(output):toContain "CMP019"
		expect(output):toContain "documented package entry point"
	end)

	it("rejects the authoring package required from runtime code", function()
		stage {
			["screen.luau"] = 'local Author = require(Packages["compose-authoring"])\n',
		}
		local ok, output = run()
		process.run { "rm", "-rf", STAGE }
		expect(ok):toBe(false)
		expect(output):toContain "CMP032"
		expect(output):toContain "certain"
		expect(output):toContain "screen.luau:1"
	end)

	it("does not reject the authoring package required from a build tool", function()
		stage {
			["tools/generate.luau"] = 'local Author = require(Packages["compose-authoring"])\n',
		}
		local ok, output = run()
		process.run { "rm", "-rf", STAGE }
		expect(ok):toBe(true)
		expect(output):toContain "nothing found"
	end)

	it("does not reject the authoring package required from a spec", function()
		stage {
			["generate.spec.luau"] = 'local Author = require(Packages["compose-authoring"])\n',
		}
		local ok, output = run()
		process.run { "rm", "-rf", STAGE }
		expect(ok):toBe(true)
		expect(output):toContain "nothing found"
	end)

	it("does not reject the authoring package required from a Verify specification", function()
		stage {
			["generate.verify.luau"] = 'local Author = require(Packages["compose-authoring"])\n',
			["engine.roblox.verify.luau"] = 'local Author = require(Packages["compose-authoring"])\n',
		}
		local ok, output = run()
		process.run { "rm", "-rf", STAGE }
		expect(ok):toBe(true)
		expect(output):toContain "nothing found"
	end)

	it("marks re-owned nested mount disposers as likely", function()
		stage {
			["screen.luau"] = [[
local cleanup = Compose.cleanup
cleanup(runtime.mount(App, target))
owner.own(runtime.mountFragment(Roots, target))
]],
		}
		local ok, output = run()
		process.run { "rm", "-rf", STAGE }
		expect(ok):toBe(true)
		expect(output):toContain "CMP020"
		expect(output):toContain "likely"
	end)

	it("finds callback children and uncalled directive aliases", function()
		stage {
			["screen.luau"] = [[
local create = runtime.create
local Frame = create "Frame"
local show = Compose.show
Frame {
    function() return Child {} end,
    show,
}
]],
		}
		local ok, output = run()
		process.run { "rm", "-rf", STAGE }
		expect(ok):toBe(false)
		expect(output):toContain "CMP022"
		expect(output):toContain "CMP023"
	end)

	for _, constructor in
		{
			"Host.Frame",
			'Host.Frame "Panel"',
			"runtime.constructors.Frame",
			'runtime.constructors.Frame "Panel"',
			"Cached",
			'Cached "Panel"',
		}
	do
		it("checks callback children and directives in " .. constructor, function()
			stage {
				["screen.luau"] = "local Host = runtime.constructors\nlocal Cached = Host.Frame\nlocal show = Compose.show\n"
					.. constructor
					.. " { function() return Child {} end, show }\n",
			}
			local ok, output = run()
			process.run { "rm", "-rf", STAGE }
			expect(ok):toBe(false)
			expect(output):toContain "CMP022"
			expect(output):toContain "CMP023"
		end)
	end

	for _, declaration in { "return function(Host: any)", "local function Panel(Host: any)" } do
		it("checks injected constructors in " .. declaration, function()
			local source = declaration
				.. "\nlocal Frame = Host.Frame\nreturn Frame { function() return Child {} end, Compose.show }\nend\n"
			local findings = consumerRules.scan(source, "screen.luau")
			expect(#findings):toBe(2)
			expect(findings[1].code):toBe "CMP022"
			expect(findings[2].code):toBe "CMP023"
		end)

		it("accepts injected node children and called directives in " .. declaration, function()
			local source = declaration
				.. ' return Host.Frame "Panel" { Host.TextLabel { Text = "Hello" }, Compose.show { when = visible, render = Child } } end'
			expect(consumerRules.scan(source, "screen.luau")):toEqual {}
		end)
	end

	it("accepts namespace constructors with node children and called directives", function()
		stage {
			["screen.luau"] = [[
local Host = runtime.constructors
local show = Compose.show
return Host.Frame "Panel" {
    Host.TextLabel { Text = "Hello" },
    runtime.constructors.Frame { Name = "Child" },
    show { when = visible, render = Child },
}
]],
		}
		local ok, output = run()
		process.run { "rm", "-rf", STAGE }
		expect(ok):toBe(true)
		expect(output):toContain "nothing found"
	end)

	it("preserves masking offsets and findings through long literals and indexed expressions", function()
		local source = "local payload = [==[\n"
			.. string.rep("0123456789abcdef", 1024)
			.. "\nCompose.keyed {}\n]==]\n"
			.. "--[=[ Compose.keyed {} ]=]\n"
			.. 'local value = rows[index]\nlocal escaped = "a\\"b"\n'
			.. "local Host = runtime.constructors\nHost.Frame { Compose.show }\n"
		local masked = consumerRules.mask(source)
		expect(#masked):toBe(#source)
		local findings = consumerRules.scan(source, "screen.luau", masked)
		expect(findings):toEqual(consumerRules.scan(source, "screen.luau"))
		expect(#findings):toBe(1)
		expect(findings[1].code):toBe "CMP023"
		expect(string.sub(source, findings[1].offset)):toContain "Compose.show"
	end)

	it("suggests direct bindings for identity wrappers without failing", function()
		stage {
			["screen.luau"] = "local node = Label { Text = function(use) return use(title) end }\n",
		}
		local ok, output = run()
		process.run { "rm", "-rf", STAGE }
		expect(ok):toBe(true)
		expect(output):toContain "CMP024"
		expect(output):toContain "Property = value"
	end)

	it("does not suggest an invalid direct binding for a generic collection source", function()
		stage {
			["screen.luau"] = [[
keyed {
    from = function(use)
        return use(alerts)
    end,
    render = AlertRow,
}
]],
		}
		local ok, output = run()
		process.run { "rm", "-rf", STAGE }
		expect(ok):toBe(true)
		expect(output):toContain "nothing found"
	end)

	it("flags colon-called runtime operations and directives returned from mount", function()
		stage {
			["screen.luau"] = [[
local keyed = Compose.keyed
local dispose = runtime:mountFragment(Roots, target)
runtime.mount(function()
    return keyed { from = rows, key = keyOf, render = Row }
end, target)
]],
		}
		local ok, output = run()
		process.run { "rm", "-rf", STAGE }
		expect(ok):toBe(true)
		expect(output):toContain "CMP026"
		expect(output):toContain "CMP027"
		expect(output):toContain "likely"
	end)

	it("rejects dot-called runtime controls as certain", function()
		stage {
			["screen.luau"] = [[
local runtime = ComposeRoblox.createRuntime(host)
local rt = Compose.createRuntime(host)
runtime.watch(function(use)
    print(use(hp))
end)
rt.settle()
]],
		}
		local ok, output = run()
		process.run { "rm", "-rf", STAGE }
		expect(ok):toBe(false)
		expect(output):toContain "CMP028"
		expect(output):toContain "certain"
		expect(output):toContain "runtime:watch(...)"
		expect(output):toContain "rt:settle(...)"
	end)

	it("leaves module-table watch and colon-called runtime controls alone", function()
		stage {
			["screen.luau"] = [[
local watch = Compose.watch
Compose.watch(function(use)
    print(use(hp))
end)
runtime:watch(function(use)
    print(use(hp))
end)
runtime:batch(function()
    step()
end)
runtime:settle()
]],
		}
		local ok, output = run()
		process.run { "rm", "-rf", STAGE }
		expect(ok):toBe(true)
		expect(output):toContain "nothing found"
	end)

	it("marks a peek inside a reactive body as likely", function()
		stage {
			["screen.luau"] = [[
local function Screen()
    Compose.watch(function(use)
        label.Text = tostring(health:peek())
    end)
    local total = Compose.formula(function(use)
        return score:peek() + use(bonus)
    end)
    return total
end
]],
		}
		local ok, output = run()
		process.run { "rm", "-rf", STAGE }
		expect(ok):toBe(true)
		expect(output):toContain "CMP029"
		expect(output):toContain "likely"
		expect(output):toContain "use(value)"
	end)

	it("still reports the legal write-own-cell peek, as likely with its caveat", function()
		stage {
			["screen.luau"] = [[
local function accumulate()
    Compose.watch(function(use)
        totalCell:set(totalCell:peek() + use(delta))
    end)
end
]],
		}
		local ok, output = run()
		process.run { "rm", "-rf", STAGE }
		expect(ok):toBe(true)
		expect(output):toContain "CMP029"
		expect(output):toContain "writing a cell this same watch"
	end)

	it("does not report a peek outside a reactive body", function()
		stage {
			["screen.luau"] = [[
local function report()
    return health:peek()
end
]],
		}
		local ok, output = run()
		process.run { "rm", "-rf", STAGE }
		expect(ok):toBe(true)
		expect(output):toContain "nothing found"
	end)

	it("marks reactive state created at module scope as likely", function()
		stage {
			["screen.luau"] = [[
local count = Compose.cell(0)
local doubled = Compose.formula(function(use)
    return use(count) * 2
end)
]],
		}
		local ok, output = run()
		process.run { "rm", "-rf", STAGE }
		expect(ok):toBe(true)
		expect(output):toContain "CMP030"
		expect(output):toContain "likely"
		expect(output):toContain "module scope"
	end)

	it("does not report a shared cell at module scope, which is the sanctioned form", function()
		stage {
			["screen.luau"] = [[
local C = require(Packages.compose.core)
local presses = Compose.sharedCell(0)
local anchor = C.sharedCell "north"
return { presses = presses, anchor = anchor }
]],
		}
		local ok, output = run()
		process.run { "rm", "-rf", STAGE }
		expect(ok):toBe(true)
		expect(output):toContain "nothing found"
	end)

	it("still reports a plain module-scope cell next to a shared one, and names the fix", function()
		stage {
			["screen.luau"] = [[
local presses = Compose.sharedCell(0)
local tally = Compose.cell(0)
return { presses = presses, tally = tally }
]],
		}
		local ok, output = run()
		process.run { "rm", "-rf", STAGE }
		expect(ok):toBe(true)
		expect(output):toContain "CMP030"
		expect(output):toContain "screen.luau:2"
		expect(string.find(output, "screen.luau:1", 1, true) == nil):toBe(true)
		expect(output):toContain "Compose.sharedCell"
	end)

	it("does not report reactive state created inside a mount body", function()
		stage {
			["screen.luau"] = [[
runtime.mount(function()
    local count = Compose.cell(0)
    local caption = Compose.formula(function(use)
        return ("%d items"):format(use(count))
    end)
    return Frame { Text = caption }
end, target)
]],
		}
		local ok, output = run()
		process.run { "rm", "-rf", STAGE }
		expect(ok):toBe(true)
		expect(output):toContain "nothing found"
	end)

	it("suggests formula for a cell written from a watch in the same scope", function()
		stage {
			["screen.luau"] = [[
local function Screen()
    local doubled = Compose.cell(0)
    Compose.watch(function(use)
        doubled:set(use(count) * 2)
    end)
end
]],
		}
		local ok, output = run()
		process.run { "rm", "-rf", STAGE }
		expect(ok):toBe(true)
		expect(output):toContain "CMP031"
		expect(output):toContain "likely"
		expect(output):toContain "formula(function(use)"
	end)

	it("accepts the canonical accumulator form", function()
		stage {
			["screen.luau"] = [[
local accumulator = Compose.accumulator
local function Hud()
    local timings = accumulator {
        from = castFired,
        reduce = function(previous, event)
            return withCast(previous, event)
        end,
        initial = {},
    }
    local sticky = Compose.accumulator {
        from = progression,
        reduce = function(previous, level)
            return if level > previous.level then { level = level, at = now() } else previous
        end,
        initial = { level = 0, at = 0 },
        equals = sameReveal,
    }
    return timings, sticky
end
]],
		}
		local ok, output = run()
		process.run { "rm", "-rf", STAGE }
		expect(ok):toBe(true)
		expect(output):toContain "nothing found"
	end)

	it("rejects unknown and missing accumulator options", function()
		stage {
			["screen.luau"] = [[
local function Hud()
    return Compose.accumulator { from = castFired, reducer = merge }
end
]],
		}
		local ok, output = run()
		process.run { "rm", "-rf", STAGE }
		expect(ok):toBe(false)
		expect(output):toContain "CMP018"
		expect(output):toContain "reducer"
		expect(output):toContain "CMP025"
		expect(output):toContain "reduce"
	end)

	it("still reports the hand-rolled event merge the accumulator replaces", function()
		stage {
			["screen.luau"] = [[
local function Hud()
    local timings = Compose.cell({})
    Compose.watch(function(use)
        timings:set(merge(timings:peek(), use(castFired)))
    end)
    return timings
end
]],
		}
		local ok, output = run()
		process.run { "rm", "-rf", STAGE }
		expect(ok):toBe(true)
		expect(output):toContain "CMP031"
		expect(output):toContain "CMP029"
		expect(output):toContain "Compose.accumulator"
	end)

	it("leaves unrelated and cross-scope cells and watches alone", function()
		stage {
			["screen.luau"] = [[
local function a()
    local left = Compose.cell(0)
    Compose.watch(function(use)
        print(use(right))
    end)
    return left
end
local function b()
    return Compose.cell(0)
end
local function c(speed)
    Compose.watch(function(use)
        speed:set(use(target))
    end)
end
]],
		}
		local ok, output = run()
		process.run { "rm", "-rf", STAGE }
		expect(ok):toBe(true)
		expect(output):toContain "nothing found"
	end)

	it("leaves canonical aliased structure and public imports alone", function()
		stage {
			["screen.luau"] = [[
local C = require(Packages.compose.core)
local Roblox = require(Packages.compose.roblox)
local keyed = C.keyed
local ordered = C.OrderedCollection
local show = C.show
local Frame = Roblox.create "Frame"
local a = keyed {
    from = rows,
    key = function(row) return row.id end,
    render = function(row)
        if row.visible then
            for _, child in row.children do
                consume(child, row)
            end
        end
        return Row { row }
    end,
}
local b = ordered { from = rows, key = keyOf, render = Row }
local c = Frame { Text = title, show(visible, function() return Child {} end) }
]],
		}
		local ok, output = run()
		process.run { "rm", "-rf", STAGE }
		expect(ok):toBe(true)
		expect(output):toContain "nothing found"
	end)

	it("does not inspect strings, comments, dependencies, or worktrees", function()
		stage {
			["screen.luau"] = [====[
local prose = [==[local value, setter = Compose.cell(0) keyed(rows, Row)]==]
-- local value, setter = Compose.cell(0)
--[=[owner.own(runtime.mount(App, target))]=]
return prose
]====],
			["Packages/dependency.luau"] = "local value, setter = Compose.cell(0)\n",
			[".worktrees/candidate.luau"] = "local value, setter = Compose.cell(0)\n",
		}
		local ok, output = run()
		process.run { "rm", "-rf", STAGE }
		expect(ok):toBe(true)
		expect(output):toContain "nothing found"
	end)

	it("does not suggest a direct binding when the body transforms it", function()
		stage {
			["screen.luau"] = "local node = Label { Text = function(use) return format(use(title)) end }\n",
		}
		local ok, output = run()
		process.run { "rm", "-rf", STAGE }
		expect(ok):toBe(true)
		expect(output):toContain "nothing found"
	end)

	it("stays silent on a pristine generated registry module", function()
		stage { ["generated/prop-registry.luau"] = generatedRegistrySource() }
		local ok, output = run()
		process.run { "rm", "-rf", STAGE }
		expect(ok):toBe(true)
		expect(output):toContain "nothing found"
	end)

	it("flags a generated registry module hand-edited after baking", function()
		local tampered = string.gsub(generatedRegistrySource(), '"TorchA"', '"TorchB"', 1)
		stage { ["generated/prop-registry.luau"] = tampered }
		local ok, output = run()
		process.run { "rm", "-rf", STAGE }
		expect(ok):toBe(true)
		expect(output):toContain "CMP033"
		expect(output):toContain "likely"
		expect(output):toContain "generated/prop-registry.luau:5"
	end)

	it("never modifies the tree it is pointed at", function()
		stage {
			["screen.luau"] = "Compose.cell(0)\nlocal x = name(scope)\n",
			["nested/other.luau"] = "local value, setter = Compose.cell(0)\n",
		}
		local before = fingerprint(STAGE)
		run()
		run { "--code", "CMP016" }
		local after = fingerprint(STAGE)
		process.run { "rm", "-rf", STAGE }
		expect(#before > 0):toBe(true)
		expect(after):toBe(before)
	end)

	it("says so rather than raising when the root does not exist", function()
		local result = process.run {
			"lute",
			"run",
			"tools/compose-check.luau",
			"--root",
			"build/compose-check-nowhere",
		}
		expect(result.ok):toBe(false)
		expect(result.stdout .. result.stderr):toContain "no such directory"
	end)

	it("assigns a diagnostic code to each readable contract rule", function()
		expect(#readableRules.rules > 0):toBe(true)
		for _, rule in readableRules.rules do
			expect(string.match(rule.code, "^CMP%d%d%d$")):toBe(rule.code)
		end
	end)
end)

return nil
