local M = require("lualine.component"):extend()

function M:parse_git_status()
	if self.running then
		return
	end
	self.running = true

	vim.system(
		{ "git", "--no-pager", "--no-optional-locks", "status", "--porcelain" },
		{},
		vim.schedule_wrap(function(out)
			self.running = false

			if not out.stdout then
				return
			end

			local status_map = {}

			local lines = vim.split(out.stdout, "\n", { trimempty = true })
			for _, line in ipairs(lines) do
				line = vim.trim(line)
				line = vim.split(line, " ", { trimempty = true })[1]

				for _, status in ipairs(vim.split(line, "", { trimempty = true })) do
					status_map[status] = true
				end
			end

			local statuses = vim.tbl_keys(status_map)
			table.sort(statuses)

			self.prompt = vim.fn.join(statuses, "")
		end)
	)
end

function M:init(options)
	M.super.init(
		self,
		vim.tbl_deep_extend("force", {
			color = { fg = string.format("#%x", vim.api.nvim_get_hl(0, { name = "Error" }).fg) },
		}, options)
	)

	self.prompt = ""
	self.running = false

	self:parse_git_status()
	vim.api.nvim_create_autocmd({ "FocusGained", "BufWritePost", "DirChanged" }, {
		callback = function()
			self:parse_git_status()
		end,
	})
end

function M:update_status()
	return self.prompt
end

return M
