--!strict

export type Point = { X: number, Y: number }
export type Insets = { left: number, top: number, right: number, bottom: number }
export type Rect = { x: number, y: number, width: number, height: number }
export type Input = "touch" | "mouse" | "gamepad" | "VR"
export type Profile = {
	id: string,
	name: string,
	size: Point,
	aspect: number,
	guiInset: Insets,
	topbar: Rect,
	notch: Insets,
	safeArea: Insets,
	inputMode: Input,
	textScale: number,
	tenFoot: boolean,
	fieldOfView: number,
	verifyId: string?,
	orientation: string?,
}

local function insets(left: number, top: number, right: number, bottom: number): Insets
	return table.freeze { left = left, top = top, right = right, bottom = bottom }
end

local function profile(
	id: string,
	name: string,
	width: number,
	height: number,
	input: Input,
	textScale: number,
	verifyId: string?,
	orientation: string?,
	notch: Insets?,
	safe: Insets?
): Profile
	return table.freeze {
		id = id,
		name = name,
		size = table.freeze { X = width, Y = height },
		aspect = width / height,
		guiInset = insets(0, 58, 0, 0),
		topbar = table.freeze { x = 164, y = 0, width = width - 164, height = 58 },
		notch = notch or insets(0, 0, 0, 0),
		safeArea = safe or insets(0, 58, 0, 0),
		inputMode = input,
		textScale = textScale,
		tenFoot = id == "tv",
		fieldOfView = if input == "VR" then 90 else 50,
		verifyId = verifyId,
		orientation = orientation,
	}
end

local profiles: { Profile } = {
	profile("phone-portrait", "Phone portrait", 389, 762, "touch", 1, "iphone_14", "Portrait", insets(0, 47, 0, 34)),
	profile(
		"phone-landscape",
		"Phone landscape",
		749,
		389,
		"touch",
		1,
		"iphone_14",
		"LandscapeLeft",
		insets(47, 0, 47, 0)
	),
	profile("tablet-portrait", "Tablet portrait", 820, 1180, "touch", 1),
	profile("tablet-landscape", "Tablet landscape", 1180, 820, "touch", 1),
	profile("monitor", "Monitor", 1919, 1080, "mouse", 1, "hd_1080"),
	profile("ultrawide", "Ultrawide monitor", 3439, 1440, "mouse", 1),
	profile("tv", "TV · 10-foot", 1919, 1080, "gamepad", 1.3, "xbox", nil, nil, insets(96, 112, 96, 54)),
	profile("vr", "VR headset", 2064, 2208, "VR", 1.15),
}

local capturedHandheld = profile("generic_handheld_720", "Handheld", 1279, 720, "gamepad", 1, "generic_handheld_720")

local function get(id: string): Profile
	for _, device in profiles do
		if device.id == id or device.name == id or (device.verifyId == id and device.orientation ~= "Portrait") then
			return device
		end
	end
	assert(id == capturedHandheld.id, "Unknown Design device: " .. id)
	return capturedHandheld
end

local function area(device: Profile, mode: string): Rect
	if mode == "TopbarSafeInsets" then
		return table.clone(device.topbar)
	end
	local inset = if mode == "None"
		then insets(-device.notch.left, -device.notch.top, -device.notch.right, -device.notch.bottom)
		elseif mode == "DeviceSafeInsets" then insets(0, 0, 0, 0)
		elseif mode == "SafeArea" then device.safeArea
		else device.guiInset
	return {
		x = inset.left,
		y = inset.top,
		width = device.size.X - inset.left - inset.right,
		height = device.size.Y - inset.top - inset.bottom,
	}
end

local function custom(name: string, size: Point): Profile
	assert(size.X > 0 and size.Y > 0, "Design device resolution must be positive")
	return profile(name, name, size.X, size.Y, "mouse", 1)
end

return table.freeze { all = table.freeze(profiles), get = get, area = area, custom = custom }
