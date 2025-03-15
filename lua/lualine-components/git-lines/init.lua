local lualine_require = require("lualine_require")
local modules = lualine_require.lazy_require({
	utils = "lualine.utils.utils",
})

local M = require("lualine.component"):extend()

local function format_number(num)
	if num >= 1000 then
		num = num / 1000

		local dotIndex = string.find(num, ".", 1, true)

		if dotIndex ~= nil then
			num = string.sub(num, 1, dotIndex + 1)
		else
			num = num .. ".0"
		end

		num = num .. "K"
	end

	return num
end

function M:parse_git_diff()
	if self.running then
		return
	end
	self.running = true

	vim.system(
		{
			"git",
			"--no-pager",
			"--no-optional-locks",
			"diff",
			"--shortstat",
			"--no-color",
			unpack(self.options.diff_args),
		},
		{},
		vim.schedule_wrap(function(out)
			self.running = false
			if not out.stdout then
				return
			end

			local files_changed, added, removed = out.stdout:match(".-(%d+)%D+(%d+)%D*(%d*)")

			if removed == "" then
				removed = nil
			end
			files_changed = tonumber(files_changed or 0)
			added = tonumber(added or 0)
			removed = tonumber(removed or 0)

			self.data = {
				files_changed = files_changed,
				added = added,
				removed = removed,
			}
		end)
	)
end

function M:init(options)
	M.super.init(
		self,
		vim.tbl_deep_extend("force", {
			diff_args = {},
			diff_color = {
				files_changed = {
					fg = "None",
				},
				added = {
					fg = modules.utils.extract_color_from_hllist(
						"fg",
						{ "LuaLineDiffAdd", "GitSignsAdd", "GitGutterAdd", "DiffAdded", "DiffAdd" },
						"#90ee90"
					),
				},
				removed = {
					fg = modules.utils.extract_color_from_hllist(
						"fg",
						{ "LuaLineDiffDelete", "GitSignsDelete", "GitGutterDelete", "DiffRemoved", "DiffDelete" },
						"#ff0038"
					),
				},
			},
		}, options)
	)

	for k, v in pairs(self.options.diff_color) do
		self.options.diff_color[k] = self:create_hl(v, k)
	end

	self.data = {
		files_changed = 0,
		added = 0,
		removed = 0,
	}
	self.running = false

	self:parse_git_diff()
	vim.api.nvim_create_autocmd({ "FocusGained", "BufWritePost", "DirChanged", "BufReadPost" }, {
		callback = function()
			self:parse_git_diff()
		end,
	})
end

function M:update_status()
	if self.data.files_changed == 0 then
		return ""
	end

	local files_changed = format_number(self.data.files_changed)
	local added = format_number(self.data.added)
	local removed = format_number(self.data.removed)

	local result = string.format(
		"%s%s%s",
		self:format_hl(self.options.diff_color.files_changed) .. "(" .. files_changed .. ")" .. " ",
		self:format_hl(self.options.diff_color.added) .. "+" .. added,
		self:format_hl(self.options.diff_color.removed) .. "-" .. removed
	)

	return result
end

return M
