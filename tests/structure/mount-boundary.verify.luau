--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

type Row = { id: string }

local ROWS: { Row } = { { id = "a" }, { id = "b" } }

local function idOf(row: Row): string
	return row.id
end

local function refusalOf(body: () -> ()): Compose.Diagnostic
	local ok, err: unknown = pcall(body)
	if ok then
		error("expected a refusal, but the call returned normally", 2)
	end
	local parsed = Compose.parseDiagnostic(tostring(err))
	if parsed == nil then
		error(("expected a Compose diagnostic, got a raw error: %s"):format(tostring(err)), 2)
	end
	return parsed
end

describe("the mount boundary", function()
	it("names keyed when it is mounted as if it were a component", function()
		local world = Support.world()
		local Row = world.create "Row"
		local rows = Compose.cell(ROWS)

		local refusal = refusalOf(function()
			world.runtime.mount(
				(
						Compose.keyed {
							from = rows,
							key = idOf,
							render = function()
								return Row {}
							end,
						} :: unknown
					) :: Compose.Component,
				world.root
			)
		end)

		expect(refusal.code):toBe "structure/directive-needs-a-mount-point"
		expect(refusal.summary):toBe "keyed was called without a mount point"
		expect(refusal.fields.actual):toBe "nil nil"
		expect(refusal.fields.expected):toBe "a mount point, which the parent holding the directive supplies"
		expect(refusal.fields.contract):toBe(
			"a structural directive is a child, not a component: it is placed in a parent's children "
				.. "and handed a window on that parent's slot"
		)
		expect(refusal.fields.fix):toBe(
			"use keyed as a child inside a constructor call -- Frame { ... } -- and pass the component "
				.. "that returns that node to runtime.mount(component, target)"
		)
	end)

	it("names keyed when the directive is called with nothing at all", function()
		local world = Support.world()
		local Row = world.create "Row"
		local directive = Compose.keyed {
			from = Compose.cell(ROWS),
			key = idOf,
			render = function()
				return Row {}
			end,
		}

		expect(function()
			Support.owned(function(): unknown?
				directive((nil :: unknown) :: Compose.MountPoint)
				return nil
			end)
		end):toThrow "structure/directive-needs-a-mount-point"
	end)

	it("names the primitive when it is handed the parent node instead of a mount point", function()
		local world = Support.world()
		local Row = world.create "Row"
		local directive = Compose.keyed {
			from = Compose.cell(ROWS),
			key = idOf,
			render = function()
				return Row {}
			end,
		}

		local refusal = refusalOf(function()
			Support.owned(function(): unknown?
				directive((world.root :: unknown) :: Compose.MountPoint)
				return nil
			end)
		end)

		expect(refusal.code):toBe "structure/directive-needs-a-mount-point"
		expect(refusal.summary):toBe "keyed was called without a mount point"
	end)

	it("names every structural primitive mounted as if it were a component", function()
		local world = Support.world()
		local Row = world.create "Row"
		local rows = Compose.cell(ROWS)
		local function render()
			return Row {}
		end

		local cases: { { name: string, directive: Compose.Directive } } = {
			{ name = "keyed", directive = Compose.keyed { from = rows, key = idOf, render = render } },
			{ name = "indexes", directive = Compose.indexes(rows, render) },
			{ name = "fragment", directive = Compose.fragment(function()
				return { Row {} }
			end) },
			{
				name = "portal",
				directive = Compose.portal(world.root, function()
					return { Row {} }
				end),
			},
			{ name = "show", directive = Compose.show(Compose.cell(true), render) },
			{ name = "switch", directive = Compose.switch(Compose.cell "a", { a = render }) },
			{ name = "presence", directive = Compose.presence(Compose.cell(true), render) },
			{
				name = "MountBudget",
				directive = Compose.MountBudget {
					from = rows,
					key = idOf,
					render = render,
					mountsPerFrame = 1,
				},
			},
			{
				name = "OrderedCollection",
				directive = Compose.OrderedCollection { from = rows, key = idOf, render = render },
			},
			{
				name = "LayerStack",
				directive = Compose.LayerStack { from = rows, key = idOf, render = render },
			},
			{
				name = "SpatialCollection",
				directive = Compose.SpatialCollection {
					from = rows,
					key = idOf,
					render = render,
					position = function()
						return 0, 0, 0
					end,
					origin = Compose.cell({ x = 0, y = 0, z = 0 } :: Compose.SpatialCollectionPoint),
					tiers = { { name = "full", radius = 100 } },
				},
			},
		}

		for _, case in cases do
			local refusal = refusalOf(function()
				world.runtime.mount((case.directive :: unknown) :: Compose.Component, world.root)
			end)
			expect(refusal.code):toBe "structure/directive-needs-a-mount-point"
			expect(refusal.summary):toBe(("%s was called without a mount point"):format(case.name))
		end
	end)

	it("still mounts a directive written as a child", function()
		local world = Support.world()
		local Row = world.create "Row"

		local dispose, root = world.runtime.mount(function()
			return world.create "Frame" {
				Compose.keyed {
					from = Compose.cell(ROWS),
					key = idOf,
					render = function()
						return Row {}
					end,
				},
			}
		end, world.root)

		expect(#world.host.childrenOf(root)):toBe(2)
		dispose()
	end)
end)

describe("structural options that used to fail later", function()
	it("names a portal target that is not a node", function()
		local world = Support.world()
		local refusal = refusalOf(function()
			world.runtime.mount(function()
				return world.create "Frame" {
					Compose.portal(nil, function(): { Compose.Node }
						return {}
					end),
				}
			end, world.root)
		end)

		expect(refusal.code):toBe "mount/target-not-a-node"
		expect(refusal.summary):toBe "portal expects a host node to mount into"
		expect(refusal.fields.fix):toBe "pass the layer node itself, e.g. portal(screenLayer, function() ... end)"
	end)

	it("names a portal builder it cannot call", function()
		local world = Support.world()
		expect(function()
			world.runtime.mount(function()
				return world.create "Frame" {
					Compose.portal(world.root, ("not a function" :: unknown) :: () -> { Compose.Node }),
				}
			end, world.root)
		end):toThrow "structure/builder-not-a-function"
	end)

	it("names a fragment builder it cannot call", function()
		local world = Support.world()
		expect(function()
			world.runtime.mount(function()
				return world.create "Frame" {
					Compose.fragment(("not a function" :: unknown) :: () -> { Compose.Node }),
				}
			end, world.root)
		end):toThrow "structure/builder-not-a-function"
	end)

	it("names presence options that are not a table", function()
		local world = Support.world()
		local Row = world.create "Row"
		expect(function()
			world.runtime.mount(function()
				return world.create "Frame" {
					Compose.presence(Compose.cell(true), function()
						return Row {}
					end, ("on-exit" :: unknown) :: Compose.PresenceOptions),
				}
			end, world.root)
		end):toThrow "structure/options-not-a-table"
	end)

	it("names a presence option it does not have", function()
		local world = Support.world()
		local Row = world.create "Row"
		expect(function()
			world.runtime.mount(function()
				return world.create "Frame" {
					Compose.presence(Compose.cell(true), function()
						return Row {}
					end, ({ onExit = function() end } :: unknown) :: Compose.PresenceOptions),
				}
			end, world.root)
		end):toThrow "structure/unknown-option"
	end)

	it("names a presence exit it cannot call", function()
		local world = Support.world()
		local Row = world.create "Row"
		expect(function()
			world.runtime.mount(function()
				return world.create "Frame" {
					Compose.presence(Compose.cell(true), function()
						return Row {}
					end, { exit = ("fade" :: unknown) :: ({ Compose.Node }) -> Compose.Exiting }),
				}
			end, world.root)
		end):toThrow "structure/builder-not-a-function"
	end)

	it("names a status that is not a cell, on every collection that takes one", function()
		local world = Support.world()
		local Row = world.create "Row"
		local rows = Compose.cell(ROWS)
		local function render()
			return Row {}
		end

		local cases: { { name: string, build: () -> Compose.Directive } } = {
			{
				name = "MountBudget",
				build = function()
					return Compose.MountBudget {
						from = rows,
						key = idOf,
						render = render,
						mountsPerFrame = 1,
						status = ("not a cell" :: unknown) :: Compose.Cell<Compose.MountBudgetStatus>,
					}
				end,
			},
			{
				name = "OrderedCollection",
				build = function()
					return Compose.OrderedCollection {
						from = rows,
						key = idOf,
						render = render,
						status = ("not a cell" :: unknown) :: Compose.Cell<Compose.OrderedCollectionStatus>,
					}
				end,
			},
			{
				name = "SpatialCollection",
				build = function()
					return Compose.SpatialCollection {
						from = rows,
						key = idOf,
						render = render,
						position = function()
							return 0, 0, 0
						end,
						origin = Compose.cell({ x = 0, y = 0, z = 0 } :: Compose.SpatialCollectionPoint),
						tiers = { { name = "full", radius = 100 } },
						status = ("not a cell" :: unknown) :: Compose.Cell<Compose.SpatialCollectionStatus>,
					}
				end,
			},
		}

		for _, case in cases do
			local refusal = refusalOf(function()
				world.runtime.mount(function()
					return world.create "Frame" { case.build() }
				end, world.root)
			end)
			expect(refusal.code):toBe "structure/status-not-a-cell"
			expect(refusal.summary):toBe(("%s was given a status it cannot write to"):format(case.name))
			expect(refusal.fields.fix):toBe "create it once -- local status = Compose.cell(nil) -- and pass that cell"
		end
	end)

	it("names controls it cannot fill in", function()
		local world = Support.world()
		local Row = world.create "Row"
		local refusal = refusalOf(function()
			world.runtime.mount(function()
				return world.create "Frame" {
					Compose.OrderedCollection {
						from = Compose.cell(ROWS),
						key = idOf,
						render = function()
							return Row {}
						end,
						controls = ("not a table" :: unknown) :: Compose.OrderedCollectionControls<string>,
					},
				}
			end, world.root)
		end)

		expect(refusal.code):toBe "collection/controls-not-a-table"
		expect(refusal.summary):toBe "OrderedCollection cannot fill in these controls"
	end)
end)

return nil
