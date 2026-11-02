--!strict

local Records = require "./lib/records"

export type Finding = {
	code: string,
	confidence: string,
	path: string,
	line: number,
	excerpt: string,
	why: string,
	fix: string,
	caveat: string?,
}

export type Disposition = {
	code: string,
	consumerId: string,
	reactiveBodyName: string,
	reason: string,
}

local function bodyNameOf(finding: Finding): string
	local name = string.match(finding.excerpt, "^[:%.]?%s*([%a_][%w_]*)%s*%(")
	return if name ~= nil then name else ""
end

local function keyOf(finding: Finding): string
	return ("%s\0%s\0%s"):format(finding.code, finding.path, bodyNameOf(finding))
end

local function keyOfDisposition(disposition: Disposition): string
	return ("%s\0%s\0%s"):format(disposition.code, disposition.consumerId, disposition.reactiveBodyName)
end

type FindingIdentity = { code: string, path: string, excerpt: string }

local function findingsOf(document: unknown): { FindingIdentity }
	local record = Records.read(document)
	if record == nil or record.schemaVersion ~= 1 then
		error("dispositions: the compose-check report is malformed", 0)
	end
	local findings = Records.read(record.findings)
	if findings == nil then
		error("dispositions: the compose-check report is malformed", 0)
	end
	local read: { FindingIdentity } = {}
	for _, finding in findings do
		local fields = Records.read(finding)
		if fields == nil then
			error("dispositions: a compose-check finding is malformed", 0)
		end
		local code, path, excerpt = fields.code, fields.path, fields.excerpt
		if type(code) ~= "string" or type(path) ~= "string" or type(excerpt) ~= "string" then
			error("dispositions: a compose-check finding is malformed", 0)
		end
		table.insert(read, { code = code, path = path, excerpt = excerpt })
	end
	return read
end

local function validate(dispositions: { Disposition })
	for index, disposition in dispositions do
		if
			type(disposition) ~= "table"
			or type(disposition.code) ~= "string"
			or type(disposition.consumerId) ~= "string"
			or type(disposition.reactiveBodyName) ~= "string"
			or disposition.reason == nil
			or disposition.reason == ""
		then
			error(("dispositions: entry %d is not a complete disposition"):format(index), 0)
		end
	end
end

local function apply(findings: { Finding }, dispositions: { Disposition }): ({ Finding }, { Disposition })
	validate(dispositions)

	local available: { [string]: { number } } = {}
	for index, disposition in dispositions do
		local key = keyOfDisposition(disposition)
		local bucket = available[key]
		if bucket == nil then
			available[key] = { index }
		else
			table.insert(bucket, index)
		end
	end

	local spent: { [number]: true } = {}
	local remaining: { Finding } = {}
	for _, finding in findings do
		local bucket = available[keyOf(finding)]
		local matched = false
		if bucket ~= nil then
			for _, index in bucket do
				if not spent[index] then
					spent[index] = true
					matched = true
					break
				end
			end
		end
		if not matched then
			table.insert(remaining, finding)
		end
	end

	local stale: { Disposition } = {}
	for index, disposition in dispositions do
		if not spent[index] then
			table.insert(stale, disposition)
		end
	end

	return remaining, stale
end

local function describe(disposition: Disposition): string
	return ("%s %s/%s -- %s"):format(
		disposition.code,
		disposition.consumerId,
		disposition.reactiveBodyName,
		disposition.reason
	)
end

return {
	apply = apply,
	bodyNameOf = bodyNameOf,
	describe = describe,
	findings = findingsOf,
	keyOf = keyOf,
}
