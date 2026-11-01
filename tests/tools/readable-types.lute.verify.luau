--!strict

local fs = require "@std/fs"
local json = require "@std/json"
local path = require "@std/path"
local process = require "@lute/process"
local Checks = require "../../.lute/dependencies/verify/src/checks"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

describe("host node types", function()
	it("accepts opaque tables and native objects and rejects non-node values", function()
		local source = path.format(process.cwd()) .. "/src/core"
		Checks.temporaryDirectory.run(Checks.temporaryDirectory.root(), "compose-node-types", function(root)
			fs.writeStringToFile(
				root .. "/.luaurc",
				json.serialize {
					languageMode = "strict",
					aliases = { subject = source },
				}
			)
			local definitions = root .. "/native.d.luau"
			fs.writeStringToFile(
				definitions,
				[[declare extern type NativeNode with
	Name: string
end
declare nativeNode: NativeNode
]]
			)
			local valid = root .. "/valid.luau"
			fs.writeStringToFile(
				valid,
				[[--!strict
local Compose = require "@subject"
local native: Compose.Node = nativeNode
local tableNode: Compose.Node = {}
local child: Compose.Child = nativeNode
local function decorate(runtime: Compose.Runtime, properties: { [number]: Compose.Child?, Name: string? }): Compose.Node
	return runtime.decorate(nativeNode, properties)
end
local function mount(runtime: Compose.Runtime, nodes: {NativeNode})
	return runtime.mountFragment(function() return nodes end, nativeNode)
end
local function optional(runtime: Compose.Runtime, node: NativeNode?)
	return runtime.mountFragment(function() return {node, nativeNode} end, nativeNode)
end
local function fragment(nodes: {NativeNode})
	return Compose.fragment(function() return nodes end)
end
local function portal(nodes: {NativeNode})
	return Compose.portal(nativeNode, function() return nodes end)
end
return native, tableNode, child, decorate, mount, optional, fragment, portal
]]
			)
			local accepted = process.run {
				"luau-lsp",
				"analyze",
				"--flag:LuauSolverV2=true",
				"--definitions=" .. definitions,
				valid,
			}
			expect(accepted.ok):toBe(true)
			local invalid = root .. "/invalid.luau"
			fs.writeStringToFile(
				invalid,
				[[--!strict
local Compose = require "@subject"
local numberNode: Compose.Node = 4
local functionNode: Compose.Node = function() end
local nilNode: Compose.Node = nil
local function inspect(node: Compose.Node): string
	return node.Name
end
local function invalidProperties(runtime: Compose.Runtime)
	return runtime.decorate(nativeNode, 4)
end
local function invalidFragment(runtime: Compose.Runtime)
	return runtime.mountFragment(function() return {42} end, nativeNode)
end
local function invalidDirective()
	return Compose.fragment(function() return {42} end)
end
local function invalidPortal()
	return Compose.portal(nativeNode, function() return {42} end)
end
return numberNode, functionNode, nilNode, inspect, invalidProperties, invalidFragment, invalidDirective, invalidPortal
]]
			)
			local rejected = process.run {
				"luau-lsp",
				"analyze",
				"--flag:LuauSolverV2=true",
				"--definitions=" .. definitions,
				invalid,
			}
			expect(rejected.ok):toBe(false)
			local diagnostics = rejected.stdout .. rejected.stderr
			for _, line in { 3, 4, 5, 7, 10, 13, 16, 19 } do
				expect(diagnostics):toContain(`invalid.luau({line},`)
			end
			return 0
		end)
	end)
end)

describe("readable value types", function()
	it("preserves readable and shared-resource covariance and rejects nullable narrowing", function()
		local source = path.format(process.cwd()) .. "/src/core"
		Checks.temporaryDirectory.run(Checks.temporaryDirectory.root(), "compose-readable-types", function(root)
			fs.writeStringToFile(
				root .. "/.luaurc",
				json.serialize {
					languageMode = "strict",
					aliases = { subject = source },
				}
			)
			local valid = root .. "/valid.luau"
			fs.writeStringToFile(
				root .. "/bridge.luau",
				[[--!strict
local Compose = require "@subject"
export type Module = typeof(Compose)
return {}
]]
			)
			fs.writeStringToFile(
				valid,
				[[--!strict
local Compose = require "@subject"
local Bridge = require "./bridge"
local function widen(value: Compose.Value<string>): Compose.ReadOnlyValue<string?>
	return value
end
local function widenReadable(value: Compose.ReadOnlyValue<string>): Compose.ReadOnlyValue<string?>
	return value
end
local function read(value: Compose.Value<number>): number
	return value:peek()
end
local function widenShared(value: Compose.AcquireSharedResource<Compose.Value<string>>): Compose.AcquireSharedResource<Compose.ReadOnlyValue<string>>
	return value
end
local function acquire(value: Compose.AcquireSharedResource<string>): string
	local owned = value()
	local detached, release = value.detached()
	release()
	return owned .. detached
end
local function createShared(compose: Bridge.Module): Compose.AcquireSharedResource<Compose.ReadOnlyValue<boolean>>
	return compose.createSharedResource(function(): (Compose.ReadOnlyValue<boolean>, (() -> ())?)
		return compose.formula(function(): boolean return true end), nil
	end)
end
return widen, widenReadable, read, widenShared, acquire, createShared
]]
			)
			local accepted = process.run { "luau-lsp", "analyze", "--flag:LuauSolverV2=true", valid }
			expect(accepted.ok):toBe(true)
			local invalid = root .. "/invalid.luau"
			fs.writeStringToFile(
				invalid,
				[[--!strict
local Compose = require "@subject"
local function narrow(value: Compose.Value<string?>): Compose.ReadOnlyValue<string>
	return value
end
local function narrowReadable(value: Compose.ReadOnlyValue<string?>): Compose.ReadOnlyValue<string>
	return value
end
local function narrowShared(value: Compose.AcquireSharedResource<Compose.ReadOnlyValue<string?>>): Compose.AcquireSharedResource<Compose.ReadOnlyValue<string>>
	return value
end
local function privateState(value: Compose.AcquireSharedResource<string>): number
	return value.state.references
end
return narrow, narrowReadable, narrowShared, privateState
]]
			)
			local rejected = process.run { "luau-lsp", "analyze", "--flag:LuauSolverV2=true", invalid }
			expect(rejected.ok):toBe(false)
			expect(rejected.stdout .. rejected.stderr):toContain "invalid.luau(4,9): TypeError"
			expect(rejected.stdout .. rejected.stderr):toContain "invalid.luau(7,9): TypeError"
			expect(rejected.stdout .. rejected.stderr):toContain "invalid.luau(10,9): TypeError"
			expect(rejected.stdout .. rejected.stderr):toContain "invalid.luau(13,9): TypeError"
			return 0
		end)
	end)
end)

describe("Roblox engine types", function()
	it("accepts a supplied engine with narrower callbacks and extra signal capabilities", function()
		local source = path.format(process.cwd()) .. "/src/roblox"
		Checks.temporaryDirectory.run(Checks.temporaryDirectory.root(), "compose-engine-types", function(root)
			fs.writeStringToFile(
				root .. "/.luaurc",
				json.serialize { languageMode = "strict", aliases = { subject = source } }
			)
			local file = root .. "/engine.luau"
			fs.writeStringToFile(
				file,
				[[--!strict
local Roblox = require "@subject"
type EmittingSignal = Roblox.Signal<number> & { Fire: (number) -> () }
local function supplied(
	new: (string) -> never,
	heartbeat: EmittingSignal,
	propertyChanged: (unknown, string) -> Roblox.Signal<()>
): Roblox.Engine
	local engine = {
		new = new,
		heartbeat = heartbeat,
		propertyChanged = propertyChanged,
		clock = function(): number return 0 end,
		typeName = function(_value: unknown): string return "Instance" end,
		destroy = function(_value: unknown) end,
		datatypes = {},
	}
	return engine
end
return supplied
]]
			)
			local checked = process.run { "luau-lsp", "analyze", "--flag:LuauSolverV2=true", file }
			expect(checked.ok):toBe(true)
			return 0
		end)
	end)
end)

return nil
