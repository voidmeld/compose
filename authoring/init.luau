--!strict

local Bake = require "@self/bake"
local Coverage = require "@self/coverage"
local Digest = require "@self/digest"
local LayoutSheet = require "@self/layout-sheet"
local ProjectTree = require "@self/project-tree"
local Set = require "@self/set"
local Validate = require "@self/validate"

export type Entry = Set.Entry
export type EntrySet = Set.EntrySet
export type SetOptions = Set.SetOptions

export type Rules = Validate.Rules
export type RefRule = Validate.RefRule
export type Violation = Validate.Violation

export type Coverage = Coverage.Coverage

export type AttributeValue = Bake.AttributeValue
export type MappingRow = Bake.MappingRow
export type AttributeMapping = Bake.AttributeMapping
export type PlannedAttribute = Bake.PlannedAttribute
export type AttributePlan = Bake.AttributePlan
export type RegistrySpec = Bake.RegistrySpec
export type DataValue = Bake.DataValue
export type DataRecord = Bake.DataRecord
export type DataSpec = Bake.DataSpec
export type LayoutPoint = LayoutSheet.Point
export type LayoutBounds = LayoutSheet.Bounds
export type LayoutSheetSpec = LayoutSheet.LayoutSheetSpec
export type LayoutTransform = LayoutSheet.LayoutTransform
export type LayoutSheet = LayoutSheet.LayoutSheet
export type Scalar = ProjectTree.Scalar
export type RojoValue = ProjectTree.RojoValue
export type Mount = ProjectTree.Mount
export type Variant = ProjectTree.Variant
export type Identity = ProjectTree.Identity
export type Target = ProjectTree.Target
export type Plan = ProjectTree.Plan
export type Document = ProjectTree.Document
export type Manifest = ProjectTree.Manifest
export type ManifestEntry = ProjectTree.ManifestEntry
export type ProjectTreeResult = ProjectTree.ProjectTree

return {
	set = Set.set,
	validate = Validate.validate,
	digest = Digest.digest,
	coverage = Coverage.coverage,
	projectTree = ProjectTree.projectTree,
	bake = {
		attributePlan = Bake.attributePlan,
		layoutSheet = LayoutSheet.layoutSheet,
		registryModule = Bake.registryModule,
		dataModule = Bake.dataModule,
	},
}
