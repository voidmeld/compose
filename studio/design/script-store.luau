--!strict

export type Store = {
	read: () -> string,
	write: (expected: string, generated: string) -> boolean,
	watch: (changed: () -> ()) -> () -> (),
}

return function(target: ModuleScript): Store
	local ScriptEditorService = game:GetService "ScriptEditorService"
	return {
		read = function(): string
			return ScriptEditorService:GetEditorSource(target)
		end,
		write = function(expected: string, generated: string): boolean
			if ScriptEditorService:GetEditorSource(target) ~= expected then
				return false
			end
			local ok = pcall(function()
				ScriptEditorService:UpdateSourceAsync(target, function(current: string): string?
					return if current == expected then generated else nil
				end)
			end)
			return ok and ScriptEditorService:GetEditorSource(target) == generated
		end,
		watch = function(changed: () -> ()): () -> ()
			local connections = {
				target:GetPropertyChangedSignal("Source"):Connect(changed),
				ScriptEditorService.TextDocumentDidChange:Connect(function(document: ScriptDocument)
					if document:GetScript() == target then
						changed()
					end
				end),
			}
			return function()
				for _, connection in connections do
					connection:Disconnect()
				end
			end
		end,
	}
end
