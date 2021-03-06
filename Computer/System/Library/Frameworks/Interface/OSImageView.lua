--OSImageView--

	__index = OSControl
	objtype = "OSImageView"

	image = nil

	new = function(self, _x, _y, _path)
		local new = {}    -- the new instance
		setmetatable( new, {__index = OSImageView} )
		new.x = _x
		new.y = _y
		new.image = paintutils.loadImage(_path)
		return new
	end

	Draw = function(self)
		OSDrawing.DrawImage(self.x, self.y, self.image)
	end