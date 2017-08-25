--OSWindow--

	__index = OSEntity

	objtype = "OSWindow"
	title = ""
	entities = {}
	environment = nil
	dragX = 0 --for getting the relative postion of the window when dragging
	canMaximise = true
	canMinimise = true
	isMinimised = false
	canClose = true
	hasFrame = true

	BackgroundColour = colours.white
	BackgroundColourDark = colours.grey

	FrameColour = colours.lightGrey
	FrameColourDark = colours.grey

	FrameTextColour = colours.black
	FrameTextColourDark = colours.white

	FocusFrameColour = colours.lightGrey
	FocusFrameColourDark = colours.black

	ButtonTextColour = colours.white
	CloseColour = colours.red
	MinimiseColour = colours.orange
	MaximiseColour = colours.lime

	HandleCharacter = "%"
	HandleColour = colours.lightGrey
	HandleColourDark = colours.white
	HandleBackgroundColour = colours.white
	HandleBackgroundColourDark = colours.grey

	minWidth = 10
	minHeight = 5
	minimiseDockItem = nil

	close = function(self)
		--first check whether the application is ok with the close (or the checking function is not set)
		if self.canClose then
			if self.environment.windowShouldClose == nil or self.environment.windowShouldClose(self) then
				term.setTextColour(colours.white)
			--remove the window from the window list
			local i = 0
			for _,window in pairs(self.environment.windows) do
				i = i + 1
				if window == self then
					--remove the entity
					self.environment.windows[_]=nil
					OSServices.compactArray(self.environment.windows)
					if self.environment.windowDidClose then
						self.environment.windowDidClose(self)
					end
					OSUpdate()
					break
					end
				end
			end
		end
	end

	minimise = function(self)
		if not self.isMinimised then
			self.isMinimised = true
			OSCurrentWindow = nil
			OSSelectedEntity = nil
			self.minimiseDockItem = OSDockItem:newMinimise(self)
			OSDock:add(self.minimiseDockItem)
			OSUpdate()
		end
	end

	restore = function(self)
		if self.isMinimised then
			OSDock:remove(self.minimiseDockItem)
			self.minimiseItem = nil
			self.isMinimised = false
			OSCurrentWindow = self
			OSUpdate()
		end
	end

	maximise = function(self)
		self.x = 1
		self.y = 2
		self:resize(OSServices.availableScreenSize())
	end

	resize = function(self, w, h)
		if not self.canMaximise then
			return
		end
		if w <= self.minWidth then
			w = self.minWidth
		end

		if h <= self.minHeight then
			h = self.minHeight
		end

		self.width = w
		self.height = h
		if self.environment.windowDidResize then
			self.environment.windowDidResize(self, w, h - 1)
		end
		OSUpdate()
	end

	action = function(self, x, y, arg)
		--if the y of the click was 0 (the window frame) do special actions
		if y == 0 then
			if x == 1 then --close button
				self:close()
			elseif x == 2 and self.canMinimise then --minimise button
				self:minimise()
		
			elseif x == 3 and self.canMaximise then --maximise button
				self:maximise()
			else --main bar
				self.dragX = x - 1

				OSWindowDragTimer = os.startTimer(OSEvents.dragTimeout)
			end
			elseif x == self.width and y == self.height - 1 then
				OSWindowResizeTimer = os.startTimer(OSEvents.dragTimeout)
			else -- it was in the window content
				for _,entity in pairs(self.entities) do
				if OSEvents.pointOverlapsRect({x = x, y = y}, entity)  then 
					if OSEvents.clickEntity(entity, x, y, arg) then
						OSUpdate()
						return
					end
				end
			end
		end
		OSUpdate()
	end

	Draw = function(self, darkMode)
		if self.isMinimised then
			return
		end

		OSDrawing.setOffset(self.x, self.y + 1) -- 1 is added to the y offset because of the title bar

		if self.hasFrame then
			--draw the title bar
			local frameColour = OSWindow.FocusFrameColour
			if darkMode then frameColour = OSWindow.FocusFrameColourDark end
			if not self == OSCurrentWindow then
				frameColour = OSWindow.FrameColour
				if darkMode then frameColour = OSWindow.FrameColourDark end
			end

			OSDrawing.DrawBlankArea(1, 0, self.width, 1, frameColour)

			--draw the title bar buttons
			if self.canClose then OSDrawing.DrawCharacters(1, 0, "\7", OSWindow.CloseColour, frameColour) end
			if self.canMinimise then OSDrawing.DrawCharacters(2, 0, "\7", OSWindow.MinimiseColour, frameColour) end
			if self.canMaximise then OSDrawing.DrawCharacters(3, 0, "\7", OSWindow.MaximiseColour, frameColour) end

			--draw the title
			local titleX = math.max(math.ceil((self.width / 2) - (#self.title / 2)), 0)
			if not darkMode then OSDrawing.DrawCharacters(titleX, 0, self.title, OSWindow.FrameTextColour, OSWindow.FocusFrameColour) 
				else OSDrawing.DrawCharacters(titleX, 0, self.title, OSWindow.FrameTextColourDark, OSWindow.FocusFrameColourDark) end 

		end

--drawingShouldBeOnTop

		--draw the window background
		if not darkMode then OSDrawing.DrawBlankArea(1, 1, self.width, self.height - 1, OSWindow.BackgroundColour)
				else OSDrawing.DrawBlankArea(1, 1, self.width, self.height - 1, OSWindow.BackgroundColourDark) end

		--draw the shadow
		OSDrawing.DrawShadow(1, 0, self.width, self.height)

		--draw the controls
		for _,entity in pairs(self.entities) do
			if entity.drawingShouldBeOnTop == nil then entity:Draw(darkMode) end
		end

		for _,entity in pairs(self.entities) do
			if entity.drawingShouldBeOnTop ~= nil then entity:Draw(darkMode) end
		end

		if self.canMaximise then
			--draw the drag handle
			if not darkMode then OSDrawing.DrawCharacters(self.width, self.height-1, self.HandleCharacter, OSWindow.HandleColour, OSWindow.HandleBackgroundColour)
				else OSDrawing.DrawCharacters(self.width, self.height-1, self.HandleCharacter, OSWindow.HandleColourDark, OSWindow.HandleBackgroundColourDark) end
		end
	end

	new = function(self, _title, _entities, _width, _height, _environment)
		local new = {}    -- the new instance
		setmetatable( new, {__index = OSWindow} )
		new.title = _title
		new.entities = _entities
		new.width = _width
		new.height = _height + 1 --for the menu bar
		local w, h = OSServices.availableScreenSize()
		new.x = math.ceil((w - _width) / 2)
		new.y = math.ceil((h - _height) / 2) + 1
		new.id = OSInterfaceServices.generateID()
		new.environment = _environment
		OSCurrentWindow = new
		return new
	end