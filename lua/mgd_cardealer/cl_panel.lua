/*

* Copyright (c) 2026 Mikhail Abramov
*
* Author: Mikhail Abramov
* GitHub: https://github.com/MRTOkoN
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* ```
  https://www.apache.org/licenses/LICENSE-2.0
  ```
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.

*/



local PANEL = {}

AccessorFunc( PANEL, "m_HideButtons", "HideButtons" )

function PANEL:Init()
	self.Offset = 0
	self.Scroll = 0
	self.CanvasSize = 1
	self.BarSize = 1
	self.btnGrip = vgui.Create( "DScrollBarGrip", self )
    self.btnGrip.new = true
	self:SetSize( 5, 0 )
	self:SetHideButtons( false )
    self.new = true
end

function PANEL:SetEnabled( b )
	if ( not b ) then

		self.Offset = 0
		self:SetScroll( 0 )
		self.HasChanged = true

	end

	self:SetMouseInputEnabled( b )
	self:SetVisible( b )

	if ( self.Enabled ~= b ) then

		self:GetParent():InvalidateLayout()

		if ( self:GetParent().OnScrollbarAppear ) then
			self:GetParent():OnScrollbarAppear()
		end

	end

	self.Enabled = b
end

function PANEL:Value()
	return self.Pos
end

function PANEL:BarScale()
	if ( self.BarSize == 0 ) then return 1 end
	return self.BarSize / ( self.CanvasSize + self.BarSize )
end

function PANEL:SetUp( _barsize_, _canvassize_ )
	self.BarSize = _barsize_
	self.CanvasSize = math.max( _canvassize_ - _barsize_, 1 )
	self:SetEnabled( _canvassize_ > _barsize_ )
	self:InvalidateLayout()
end

function PANEL:OnMouseWheeled( dlta )
	if ( not self:IsVisible() ) then return false end
	return self:AddScroll( dlta * -2 )
end

local tScroll = 0
local newerT = 0
local length = 0.5
local ease = 0.25
local amount = 30

local function sign( num )
	return num > 0
end

local function getBiggerPos( signOld, signNew, old, new )
	if signOld ~= signNew then return new end
	if signNew then
			return math.max(old, new)
	else
			return math.min(old, new)
	end
end

function PANEL:AddScroll( dlta )
	self.Old_Pos = nil
	self.Old_Sign = nil

	local OldScroll = self:GetScroll()

	dlta = dlta * amount

	local anim = self:NewAnimation( length, 0, ease )
	anim.StartPos = OldScroll
	anim.TargetPos = OldScroll + dlta + tScroll
	tScroll = tScroll + dlta

	local ctime = RealTime()
	local doing_scroll = true
	newerT = ctime

	anim.Think = function( anim, pnl, fraction )
		local nowpos = Lerp( fraction, anim.StartPos, anim.TargetPos )
		if ctime == newerT then
				self:SetScroll( getBiggerPos( self.Old_Sign, sign(dlta), self.Old_Pos, nowpos ) )
				tScroll = tScroll - (tScroll * fraction)
		end
		if doing_scroll then
				self.Old_Sign = sign(dlta)
				self.Old_Pos = nowpos
		end
		if ctime ~= newerT then doing_scroll = false end
	end

	return math.Clamp( self:GetScroll() + tScroll, 0, self.CanvasSize ) ~= self:GetScroll()
end

function PANEL:SetScroll( scrll )
	if ( not self.Enabled ) then self.Scroll = 0 return end

	self.Scroll = math.Clamp( scrll, 0, self.CanvasSize )

	self:InvalidateLayout()

	local func = self:GetParent().OnVScroll
	if ( func ) then

		func( self:GetParent(), self:GetOffset() )

	else

		self:GetParent():InvalidateLayout()

	end
end

function PANEL:AnimateTo( scrll, length, delay, ease )
	local anim = self:NewAnimation( length, delay, ease )
	anim.StartPos = self.Scroll
	anim.TargetPos = scrll
	anim.Think = function( anim, pnl, fraction )

		pnl:SetScroll( Lerp( fraction, anim.StartPos, anim.TargetPos ) )

	end
end

function PANEL:GetScroll()
	if ( not self.Enabled ) then self.Scroll = 0 end
	return self.Scroll
end

function PANEL:GetOffset()
	if ( not self.Enabled ) then return 0 end
	return self.Scroll * -1
end

function PANEL:Think()
end

function PANEL:Paint( w, h )
	derma.SkinHook( "Paint", "VScrollBar", self, w, h )
	return true
end

function PANEL:OnMousePressed()
	local x, y = self:CursorPos()

	local PageSize = self.BarSize

	if ( y > self.btnGrip.y ) then
		self:SetScroll( self:GetScroll() + PageSize )
	else
		self:SetScroll( self:GetScroll() - PageSize )
	end
end

function PANEL:OnMouseReleased()

	self.Dragging = false
	self.DraggingCanvas = nil
	self:MouseCapture( false )

	self.btnGrip.Depressed = false

end

function PANEL:OnCursorMoved( x, y )
	if ( not self.Enabled ) then return end
	if ( not self.Dragging ) then return end

	local x, y = self:ScreenToLocal( 0, gui.MouseY() )

	y = y - self.HoldPos

	local BtnHeight = self:GetWide()
	if ( self:GetHideButtons() ) then BtnHeight = 0 end

	local TrackSize = self:GetTall() - BtnHeight * 2 - self.btnGrip:GetTall()

	y = y / TrackSize

	self:SetScroll( y * self.CanvasSize )
end

function PANEL:Grip()
	if ( not self.Enabled ) then return end
	if ( self.BarSize == 0 ) then return end

	self:MouseCapture( true )
	self.Dragging = true

	local x, y = self.btnGrip:ScreenToLocal( 0, gui.MouseY() )
	self.HoldPos = y

	self.btnGrip.Depressed = true
end

function PANEL:PerformLayout()
	local Wide = self:GetWide()
	local BtnHeight = Wide
	if ( self:GetHideButtons() ) then BtnHeight = 0 end
	local Scroll = self:GetScroll() / self.CanvasSize
	local BarSize = math.max( self:BarScale() * ( self:GetTall() - ( BtnHeight * 2 ) ), 10 )
	local Track = self:GetTall() - ( BtnHeight * 2 ) - BarSize
	Track = Track + 1

	Scroll = Scroll * Track

	self.btnGrip:SetPos( 0, BtnHeight + Scroll )
	self.btnGrip:SetSize( Wide, BarSize )
end

derma.DefineControl( "DVScrollBar2", "A Scrollbar", PANEL, "Panel" )

local PANEL = {}

AccessorFunc( PANEL, "Padding", "Padding" )
AccessorFunc( PANEL, "pnlCanvas", "Canvas" )

function PANEL:Init()
	self.pnlCanvas = vgui.Create( "Panel", self )
	self.pnlCanvas.OnMousePressed = function( self, code ) self:GetParent():OnMousePressed( code ) end
	self.pnlCanvas:SetMouseInputEnabled( true )
	self.pnlCanvas.PerformLayout = function( pnl )

		self:PerformLayoutInternal()
		self:InvalidateParent()

	end

	self.VBar = vgui.Create( "DVScrollBar2", self )
	self.VBar:Dock( RIGHT )

	self:SetPadding( 0 )
	self:SetMouseInputEnabled( true )

	self:SetPaintBackgroundEnabled( false )
	self:SetPaintBorderEnabled( false )
	self:SetPaintBackground( false )
end

function PANEL:AddItem( pnl )
	pnl:SetParent( self:GetCanvas() )
end

function PANEL:OnChildAdded( child )
	self:AddItem( child )
end

function PANEL:SizeToContents()
	self:SetSize( self.pnlCanvas:GetSize() )
end

function PANEL:GetVBar()
	return self.VBar
end

function PANEL:GetCanvas()
	return self.pnlCanvas
end

function PANEL:InnerWidth()
	return self:GetCanvas():GetWide()
end

function PANEL:Rebuild()
	self:GetCanvas():SizeToChildren( false, true )

	if ( self.m_bNoSizing && self:GetCanvas():GetTall() < self:GetTall() ) then
		self:GetCanvas():SetPos( 0, ( self:GetTall() - self:GetCanvas():GetTall() ) * 0.5 )
	end
end

function PANEL:OnMouseWheeled( dlta )
	return self.VBar:OnMouseWheeled( dlta )
end

function PANEL:OnVScroll( iOffset )
	self.pnlCanvas:SetPos( 0, iOffset )
end

function PANEL:ScrollToChild( panel )
	self:InvalidateLayout( true )

	local x, y = self.pnlCanvas:GetChildPosition( panel )
	local w, h = panel:GetSize()

	y = y + h * 0.5
	y = y - self:GetTall() * 0.5

	self.VBar:AnimateTo( y, 0.5, 0, 0.5 )
end

function PANEL:PerformLayoutInternal()
	local Tall = self.pnlCanvas:GetTall()
	local Wide = self:GetWide()
	local YPos = 0

	self:Rebuild()

	self.VBar:SetUp( self:GetTall(), self.pnlCanvas:GetTall() )
	YPos = self.VBar:GetOffset()

	if ( self.VBar.Enabled ) then Wide = Wide - self.VBar:GetWide() end

	self.pnlCanvas:SetPos( 0, YPos )
	self.pnlCanvas:SetWide( Wide )

	self:Rebuild()

	if ( Tall ~= self.pnlCanvas:GetTall() ) then
		self.VBar:SetScroll( self.VBar:GetScroll() )
	end
end

function PANEL:PerformLayout()

	self:PerformLayoutInternal()

end

function PANEL:Clear()

	return self.pnlCanvas:Clear()

end

derma.DefineControl( "DScrollPanel2", "", PANEL, "DPanel" )

MGD = MGD or {}
MGD.Cardealer = MGD.Cardealer or {}

function MGD.Cardealer.DermaQuery(strText, strTitle, ...)
    local Window = vgui.Create("DFrame")
    Window.new = true
    Window:SetTitle(strTitle or "Message Title (First Parameter)")
    Window:SetDraggable(false)
    Window:ShowCloseButton(false)
    Window:SetBackgroundBlur(true)
    Window:SetDrawOnTop(true)

    local InnerPanel = vgui.Create("DPanel", Window)
    InnerPanel:SetPaintBackground(false)
    local Text = vgui.Create("DLabel", InnerPanel)
    Text:SetText(strText or "Message Text (Second Parameter)")
    Text:SizeToContents()
    Text:SetContentAlignment(5)
    Text:SetTextColor(color_white)
    local ButtonPanel = vgui.Create("DPanel", Window)
    ButtonPanel:SetTall(30)
    ButtonPanel:SetPaintBackground(false)

    local NumOptions = 0
    local x = 5

    for k = 1, 8, 2 do
        local Text = select(k, ...)
        if Text == nil then break end
        local Func = select(k + 1, ...) or function() end
        local Button = vgui.Create("DButton", ButtonPanel)
        Button:SetText(Text)
        Button:SizeToContents()
        Button:SetTall(20)
        Button:SetWide(Button:GetWide() + 20)

        Button.DoClick = function()
            surface.PlaySound("btn2.wav")
            Window:Close()
            Func()
        end
        Button.OnCursorEntered = function(self)
            surface.PlaySound("btn.wav")
        end

        Button:SetPos(x, 5)

        if k == 1 then
            Button.Paint = function(self, w, h)
                surface.SetDrawColor(Color(208, 45, 124, 255))
                surface.DrawOutlinedRect(0, 0, w, h, 2)
            end
        else
            Button.Paint = function(self, w, h)
                surface.SetDrawColor(208, 45, 124, 255)
                surface.DrawRect(0, 0, w, h)
            end
        end

        x = x + Button:GetWide() + 5
        ButtonPanel:SetWide(x)
        NumOptions = NumOptions + 1
    end

    local w, h = Text:GetSize()
    w = math.max(w, ButtonPanel:GetWide())
    Window:SetSize(w + 50, h + 25 + 45 + 10)
    Window:Center()
    InnerPanel:StretchToParent(5, 25, 5, 45)
    Text:StretchToParent(5, 5, 5, 5)
    ButtonPanel:CenterHorizontal()
    ButtonPanel:AlignBottom(8)
    Window:MakePopup()
    Window:DoModal()

    if NumOptions == 0 then
        Window:Close()
        Error("Derma_Query: Created Query with no Options!?")

        return nil
    end

    return Window
end

function MGD.Cardealer.EnterTextPanel( strTitle, strText, strDefaultText, fnEnter, fnCancel, strButtonText, strButtonCancelText, numeric, strPlaceholderText )
    local Window = vgui.Create( "DFrame" )
    Window:SetTitle( strTitle or "Message Title (First Parameter)" )
    Window:SetDraggable( false )
    Window:ShowCloseButton( false )
    Window:SetBackgroundBlur( true )
    Window:Center()

    Window.Paint = function( self, w, h )
        draw.RoundedBox(3, 0, 0, w, h, Color(60, 60, 60))
        draw.RoundedBox(0, 0, 0, w, 26, Color(0,0,0,120))
    end

    local InnerPanel = vgui.Create( "DPanel", Window )
    InnerPanel:SetPaintBackground( false )

    local Text = vgui.Create( "DLabel", InnerPanel )
    Text:SetText( strText or "Message Text (Second Parameter)" )
    Text:SizeToContents()
    Text:SetContentAlignment( 5 )
    Text:SetTextColor( Color(231, 231, 231) )

    local TextEntry = vgui.Create( "DTextEntry", InnerPanel )
    TextEntry:SetText( strDefaultText or "" )
    TextEntry:SetNumeric(numeric or false)
    TextEntry:SetPlaceholderText( strPlaceholderText or '' )
    local submitted = false
    local function submit()
        if submitted then return end
        submitted = true
        Window:Close()
        fnEnter( TextEntry:GetValue() )
    end

    TextEntry.OnEnter = submit

    local ButtonPanel = vgui.Create( "DPanel", Window )
    ButtonPanel:SetTall( 30 )
    ButtonPanel:SetPaintBackground( false )

    local Button = vgui.Create( "DButton", ButtonPanel )
    Button:SetText( strButtonText or "Ok" )
    Button:SizeToContents()
    Button:SetTall( 20 )
    Button:SetWide( Button:GetWide() + 20 )
    Button:SetPos( 5, 5 )
    Button:SetTextColor(Color(231, 231, 231))
    Button.DoClick = submit

    Button.Paint = function( self, w, h )
        surface.SetDrawColor(208, 45, 124, 255)
        surface.DrawRect(0, 0, w, h)
    end

    local ButtonCancel = vgui.Create( "DButton", ButtonPanel )
    ButtonCancel:SetText( strButtonCancelText or "Cancel" )
    ButtonCancel:SizeToContents()
    ButtonCancel:SetTall( 20 )
    ButtonCancel:SetWide( Button:GetWide() + 20 )
    ButtonCancel:SetPos( 5, 5 )
    ButtonCancel:SetTextColor(Color(231, 231, 231))
    ButtonCancel.DoClick = function() Window:Close() if ( fnCancel ) then fnCancel( TextEntry:GetValue() ) end end
    ButtonCancel:MoveRightOf( Button, 5 )

    ButtonCancel.Paint = function( self, w, h )
        surface.SetDrawColor(Color(208, 45, 124, 255))
        surface.DrawOutlinedRect(0, 0, w, h, 2)
    end

    ButtonPanel:SetWide( Button:GetWide() + 5 + ButtonCancel:GetWide() + 10 )

    local w, h = Text:GetSize()
    w = math.max( w, 400 )

    Window:SetSize( w + 50, h + 25 + 75 + 10 )
    Window:Center()

    InnerPanel:StretchToParent( 5, 25, 5, 45 )

    Text:StretchToParent( 5, 5, 5, 35 )

    TextEntry:StretchToParent( 5, nil, 5, nil )
    TextEntry:AlignBottom( 5 )

    TextEntry:RequestFocus()
    TextEntry:SelectAllText( true )

    ButtonPanel:CenterHorizontal()
    ButtonPanel:AlignBottom( 8 )

    Window:MakePopup()
    Window:DoModal()

    return Window
end
