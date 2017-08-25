
	name = "Finder"
	menus = {}
	windows = {}
	version = "0.1"
	showHidden = false
	id = 0
	author = "nk2"
	
	init = function()
		local filemenuItems = {
    			OSMenuItem:new("New Window", function() 
    			newFinderWindow(OSFileSystem.HomePath) end,"N"),
    			OSMenuItem:new("Open", nil, "O"),
    			OSMenuItem:new("Go to Home", nil, "H")
	    	}
        menus = {
        	OSMenu:new(1, 1, "File", filemenuItems)
        }
	end
	
	newFinderWindow = function(path)
		local width = 48
		local height = 13
		local finderWindow = nil
		
		
		local placesLabel = OSListItem:new("Places", nil)
		placesLabel.TextColour = colours.lightGrey
		local placesListView = OSListView:new(1, 4, 15, 11, {
			placesLabel,
			OSListItem:new(" Applications", function() handleItem("/Applications/", finderWindow) end),
			OSListItem:new(" Home", function() handleItem(OSFileSystem.HomePath, finderWindow) end),
			OSListItem:new(" Documents", function() handleItem(OSFileSystem.HomePath.."Documents/", finderWindow) end),
		})

		local splitter = OSVSplitter:new(16, 3, height-2)
		
		local toolbar 
		if not OSDrawing.GetMode() then toolbar = OSBox:new(1,1, width, 2, colours.lightGrey)
			else toolbar = OSBox:new(1,1, width, 2, colours.black) end

		local buttonsSplitter = OSVSplitter:new(6, 1, 1)
		buttonsSplitter.BackgroundColourDark = colours.black
		
		local backButton = OSButton:new(3,1, "<", function() goBack(finderWindow) end)
		backButton.BackgroundColour = colours.white
		backButton.DisabledTextColour = colours.lightGrey
		backButton.DisabledBackgroundColour = colours.white
		
		local forwardButton = OSButton:new(7,1, ">", nil)
		forwardButton.BackgroundColour = colours.white
		forwardButton.DisabledTextColour = colours.lightGrey
		forwardButton.DisabledBackgroundColour = colours.white

		local pathbar = OSTextField:new(11,1,31, path, function() openDirectory( finderWindow.pathbar.text, finderWindow) end)
		
		local pathGo = OSButton:new(43,1, "Go", function() pathbar:submit() end)
		pathGo.BackgroundColour = colours.white
		pathGo.DisabledTextColour = colours.lightGrey
		pathGo.DisabledBackgroundColour = colours.white

		--TODO
		filesList = OSListView:new(17, 4, 32, 11, {})
		
		
		finderWindow = OSWindow:new(OSFileSystem.getName(path), {
			toolbar,
			backButton,
			buttonsSplitter,
			forwardButton,
			pathbar,
			pathGo,
			placesListView,
			filesList,
			splitter
			
		}, width, height, environment)
		
		finderWindow.minHeight = 10
		finderWindow.minWidth = 25
		finderWindow.toolbar = toolbar
		finderWindow.pathbar = pathbar
		finderWindow.pathGo = pathGo
		finderWindow.splitter = splitter
		finderWindow.backButton = backButton
		finderWindow.fileList = filesList
		finderWindow.placesListView = placesListView
		finderWindow.backHistory = {}
		finderWindow.forwardHistory = {}
		
		
		id = id + 1
		windows['finder'..id] = finderWindow
		openDirectory(path, finderWindow, false, false)
	end
	
	
	
	handleItem = function(path, window)
		if OSFileSystem.isDirectory(path) then
			-- add a slash if missing
			if string.sub(path, #path) ~= "/" then
				path = path .. "/"
			end
			openDirectory(path, window)
		else
			openFile(path)
		end
	end
	
	openFile = function(path)
		OSFileSystem.openFile(path)
	end
	
	openDirectory = function(path, window, addToHistory, update)
		addToHistory = addToHistory or true
		if OSFileSystem.exists(path) then
			window.title = OSFileSystem.getName(path)
			if addToHistory then
				--add the old path to history
				table.insert(window.backHistory, window.pathbar.text)
			end

			updateHistoryButtons(window)
			window.pathbar.text = path
		
			window.fileList.items = {}
			for _,file in  pairs(OSFileSystem.list(path)) do
				--check if the file has a full stop in front (hide it if showhidden is false)
				if not (string.sub(file,1,1) == ".") then
					table.insert(window.fileList.items, OSListItem:new(file, function() handleItem(path..file, window) end))
				end
			end
			
			-- if update then
			-- 	OSUpdate()
			-- end
		end
	end	
	
	updateHistoryButtons = function(window)
		window.backButton.enabled = #window.backHistory > 0
	end
	
	
	goBack = function(window)
		openDirectory(window.backHistory[#window.backHistory], window, false)
		table.remove(window.backHistory, # window.backHistory)
		updateHistoryButtons(window)
	end	
	
	windowShouldClose = function(window)
		return true
	end
	
	windowDidResize = function(window, _width, _height)
		if window == windows['about'] or window == windows['aboutSystem'] then
			return
		end
		window.toolbar.width = _width
		
		window.pathbar.width = _width - 17
		
		window.pathGo.x = window.pathbar.x + window.pathbar.width + 1
		window.splitter.height = _height-2
		window.fileList.height = _height-2
		window.fileList.width = _width - 17
		window.placesListView.height = _height - 2
	end
	
	
	