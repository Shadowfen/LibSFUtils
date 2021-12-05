-- LibSFUtils is already defined in prior loaded file
local sfutil = LibSFUtils


-- -------------------------------------------------------

-- These are simple helper functions to extend LibMsgWin-1.0 (and therefore
-- require LibMsgWin-1.0 to be loaded as a dependency in your manifest (.txt) file!).

-- Create a message window that has a title and a close button that works
function sfutil.CreateMsgWin(name, title, width, height, visible)
	if LibMsgWin then
		local win = LibMsgWin:CreateMsgWindow(name, title)
		if width and height then
			win.SetDimensions(width, height)
		end
		----- CLOSE BUTTON -----
		msgWinCloseButton = WINDOW_MANAGER:CreateControl(name.."Close", win, CT_BUTTON)
		msgWinCloseButton:SetDimensions(40,40)
		msgWinCloseButton:SetAnchor(TOPRIGHT, win, TOPRIGHT,0,20)

		msgWinCloseButton:SetNormalTexture("EsoUI/Art/Buttons/closebutton_up.dds")
		msgWinCloseButton:SetPressedTexture("EsoUI/Art/Buttons/closebutton_down.dds")
		msgWinCloseButton:SetMouseOverTexture("EsoUI/Art/Buttons/closebutton_mouseover.dds")
		msgWinCloseButton:SetDisabledTexture("EsoUI/Art/Buttons/closebutton_disabled.dds")
		msgWinCloseButton:SetHandler("OnClicked",function(self, but)
			win:SetHidden(true)
		end)
		
		if visible == true then
			win:SetHidden(false)
		else
			win:SetHidden(true)
		end
		return win
	else
		return nil
	end
end

-- show a hidden window
function sfutil.ShowMsgWin(win)
	if win then win:SetHidden(false) end
end

-- hide a visible window
function sfutil.HideMsgWin(win)
	if win then win:SetHidden(true) end
end

-- toggle a window between visible and hidden
function sfutil.toggleWindow(win)
	if win then
		if win:IsControlHidden() then
			win:SetHidden(false)
		else
			win:SetHidden(true)
		end
	end
end
