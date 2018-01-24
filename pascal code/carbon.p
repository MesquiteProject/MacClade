{
Unit: Carbon
Purpose: This unit holds the two program globals and the carbon compatibility
	functions
Author: Michael Shopsin, shopsinm@panix.com
Date: 02/27/99-11/21/00
Description:  To support carbon and pre-carbon code in one program I wrote these
  accessor functions.  They also wrap some annoying carbon functions in easier to
  call procedures/functions.  Some of this code is also for typed function pointers
  since the old UPP code assumed that UPPs were transparent to @myProc which is not
  true under MacOS X.  There are also a few utilities that seemed to be logical 
  extensions of carbon calls.
Thanks to:
	Quinn ³The Eskimo!² for PascalSillyBalls
	Eric Schlegel for numerious other things, especially myGetWindowStructureRgn
}

unit Carbon;

interface

	uses
		MacTypes, MixedMode, MacWindows, QuickdrawText, Dialogs, Scrap,
		Quickdraw, Menus, Controls, LowMem, AppleEvents, Navigation;
	
{sample compiler directives mix and match for best effect}
{$IFC UNDEFINED TARGET_CARBON}
{$SETC TARGET_CARBON := FALSE}
{$ENDC}

{this is for units that may be used with other non-Carbon projects}

{non-Carbon code}
{$IFC NOT TARGET_CARBON}
{$ENDC}

{Carbon only code}
{$IFC TARGET_CARBON}
{$ENDC}

{non-Carbon and Carbon code that is equivilent but different}
{$IFC NOT TARGET_CARBON}
{$ELSEC}
{$ENDC}

{Constant, defined because they're missing from Carbon}
const
	kAEShowPreferences = 'pref';
		
{Misc utils}
	function myGetMenuBarHeight: integer;
	function myGetScreenBits: BitMap;
	function myGetRgnBBox(theRgn: RgnHandle): Rect;
	procedure myCopyBits(theSrcPort: CGrafPtr; theDestPort: CGrafPtr; var theSrcRect: Rect; var theDestRect: Rect);
	function myGetLtGray: Pattern;
	function myGetGray: Pattern;

{Proc utils}
	function myNewAEEventHandler(theProc: AEEventHandlerProcPtr): AEEventHandlerUPP;
	function myNewNavEvent(theProc: NavEventProcPtr): NavEventUPP;
	function myNewControlAction(theProc: ControlActionProcPtr): ControlActionUPP;
	function myNewUserItem(theProc: UserItemProcPtr): UserItemUPP;
	function myNewModalFilter(theProc: ModalFilterProcPtr): ModalFilterUPP;
	procedure myDisposeControlAction(theProc: ControlActionProcPtr);
	procedure myDisposeFilter(theFilterUPP: ModalFilterUPP);
	procedure myDisposeUserItem(theUserItemUPP: UserItemUPP);
	
{GrafPort utils}
	function myGetVisRgn(thePort: CGrafPtr): RgnHandle;
	function myGetPortRect(thePort: CGrafPtr): Rect;
	
{Window utils}
	function myGetWindowRect(theWindow: WindowPtr): Rect;
	function myWindowVisable(theWindow: WindowPtr): Boolean;
	procedure myGetNextWindow(var theWindow: WindowPtr);
	function myGetNextWindowF(theWindow: WindowPtr): WindowPtr;
	procedure myGetPort(var theWindow: WindowPtr);
	procedure mySetPort(theWindow: WindowPtr);
	function myGetWindowPort(theWindow: WindowPtr): CGrafPtr;
	function myGrowWindow(theWindow: WindowPtr; thePoint: Point; var theRect: Rect): longint;
	procedure myDragWindow(theWindow: WindowPtr; thePoint: Point; var theRect: Rect);
	function myGetWindowStructureRgn(theWindow: WindowPtr): RgnHandle;
	function myGetWindowStructureRect(theWindow: WindowPtr): Rect;
	
	
{Dialog utils}
	function myGetDialogRect(theDialog: DialogPtr): Rect;
	procedure myGetDPort(var theDialog: DialogPtr);
	procedure mySetDPort(theDialog: DialogPtr);
	function myGetDialogPort(var theDialog: DialogPtr): CGrafPtr;
	function myDialogToWindow(theDialog: DialogPtr): WindowPtr;
	function myWindowToDialog(theWindow: WindowPtr): DialogPtr;
	
{Cursor utils}
	procedure mySetCursorToArrow;
	procedure mySetCursorToWatch;
	procedure mySetCursorToCrosshair;
	
{Menu utils}
	procedure myEnableItem(theMenu: MenuHandle; theItem: integer);
	procedure myDisableItem(theMenu: MenuHandle; theItem: integer);
	function myGetEnableDisable(theMenu: MenuHandle; theItem: integer): boolean;
	function myCountMItems(theMenu: MenuHandle): integer;
	
{Control utils}
	function myGetControlRect(theControl: ControlHandle): Rect;
	function myGetControlOwner(theControl: ControlHandle): WindowPtr;
	
{Scrap (Clipboard) utils}
	function myKillScrap: OSErr;
	function myPutScrap(thePublic: boolean; theCount: SInt32; theFlavorType: ScrapFlavorType; theBuffer: UNIV Ptr): OSErr;
	function myGetScrap(theDestination: Handle; theFlavorType: ScrapFlavorType; var theOffset: SInt32): longint;

{Toolutils utils}	
	function myLoWord(theLong: longint): integer;
	function myHiWord(theLong: longint): integer;
	
implementation

{this compiler directive provides a cute little divider line in popup menu}
{$PRAGMAC Mark -}

{$IFC NOT TARGET_CARBON}
	function myGetMenuBarHeight: integer;
	begin
		myGetMenuBarHeight := LMGetMBarHeight;
	end;
{$ELSEC}
	function myGetMenuBarHeight: integer;
	begin
		myGetMenuBarHeight := GetMBarHeight;
	end;
{$ENDC}

{$IFC NOT TARGET_CARBON}
	function myGetScreenBits: BitMap;
	begin
		myGetScreenBits := qd.screenBits;
	end;
{$ELSEC}
	function myGetScreenBits: BitMap;
		var
			myBitMap: BitMap;
			myBitMapPtr: BitMapPtr;
	begin
		myBitMapPtr := GetQDGlobalsScreenBits(myBitMap);
		myGetScreenBits := myBitMap;
	end;
{$ENDC}

{$IFC NOT TARGET_CARBON}
	function myGetRgnBBox(theRgn: RgnHandle): Rect;
	begin
		myGetRgnBBox := theRgn^^.rgnBBox;
	end;
{$ELSEC}
	function myGetRgnBBox(theRgn: RgnHandle): Rect;
		var
			myRect: Rect;
			myRectPtr: RectPtr;
	begin
		myRectPtr := GetRegionBounds(theRgn, myRect);
		myGetRgnBBox := myRect;
	end;
{$ENDC}

{$IFC NOT TARGET_CARBON}
	procedure myCopyBits(theSrcPort: CGrafPtr; theDestPort: CGrafPtr; var theSrcRect: Rect; var theDestRect: Rect);
	begin
		CopyBits(GrafPtr(theSrcPort)^.portBits, GrafPtr(theDestPort)^.portBits, theSrcRect, theDestRect, srcCopy, nil);
	end;
{$ELSEC}
	procedure myCopyBits(theSrcPort: CGrafPtr; theDestPort: CGrafPtr; var theSrcRect: Rect; var theDestRect: Rect);
	begin
		CopyBits(BitMapPtr(GetPortPixMap(theSrcPort)^)^, BitMapPtr(GetPortPixMap(theDestPort)^)^, theSrcRect, theDestRect, srcCopy, nil);
	end;
{$ENDC}

{$IFC NOT TARGET_CARBON}
	function myGetQDPattern(thePat: integer): Pattern;
	begin
		case thePat of
			1:
				myGetQDPattern := qd.dkGray;
			2:
				myGetQDPattern := qd.ltGray;
			3:
				myGetQDPattern := qd.gray;
			4:
				myGetQDPattern := qd.black;
			5:
				myGetQDPattern := qd.white;
		end;
	end;
{$ELSEC}
	function myGetQDPattern(thePat: integer): Pattern;
		var
			myPat: Pattern;
			myPatPtr: PatternPtr;
	begin
		case thePat of
			1:
				myPatPtr := GetQDGlobalsDarkGray(myPat);
			2:
				myPatPtr := GetQDGlobalsLightGray(myPat);
			3:
				myPatPtr := GetQDGlobalsGray(myPat);
			4:
				myPatPtr := GetQDGlobalsBlack(myPat);
			5:
				myPatPtr := GetQDGlobalsWhite(myPat);
		end;
		myGetQDPattern := myPat;
	end;
{$ENDC}

	function myGetLtGray: Pattern;
	begin
		myGetLtGray := myGetQDPattern(2);
	end;
	
	function myGetGray: Pattern;
	begin
		myGetGray := myGetQDPattern(3);
	end;

{$PRAGMAC MARK -}

{$IFC NOT TARGET_CARBON}
	function myNewAEEventHandler(theProc: AEEventHandlerProcPtr): AEEventHandlerUPP;
	begin
		return {NewAEEventHandlerProc}NewAEEventHandlerUPP(theProc);
	end;
{$ELSEC}
	function myNewAEEventHandler(theProc: AEEventHandlerProcPtr): AEEventHandlerUPP;
	begin
		return NewAEEventHandlerUPP(theProc);
	end;
{$ENDC}

{$IFC NOT TARGET_CARBON}
	function myNewNavEvent(theProc: NavEventProcPtr): NavEventUPP;
	begin
		return NewRoutineDescriptor(theProc,(kPascalStackBased + $10*kNoByteCode + $40* kFourByteCode + $100* kFourByteCode + $400* kFourByteCode),GetCurrentISA);
	end;
{$ELSEC}
	function myNewNavEvent(theProc: NavEventProcPtr): NavEventUPP;
	begin
		return NewNavEventUPP(theProc);
	end;
{$ENDC}

{$IFC NOT TARGET_CARBON}
	function myNewControlAction(theProc: ControlActionProcPtr): ControlActionUPP;
	begin
		return {NewControlActionProc}NewControlActionUPP(theProc);
	end;
{$ELSEC}
	function myNewControlAction(theProc: ControlActionProcPtr): ControlActionUPP;
	begin
		return NewControlActionUPP(theProc);
	end;
{$ENDC}

{$IFC NOT TARGET_CARBON}
	function myNewUserItem(theProc:UserItemProcPtr): UserItemUPP;
	begin
		return {NewUserItemProc}NewUserItemUPP(theProc);
	end;
{$ELSEC}
	function myNewUserItem(theProc:UserItemProcPtr): UserItemUPP;
	begin
		return NewUserItemUPP(theProc);
	end;
{$ENDC}

{$IFC NOT TARGET_CARBON}
	function myNewModalFilter(theProc: ModalFilterProcPtr): ModalFilterUPP;
	begin
		return {NewModalFilterProc}NewModalFilterUPP(theProc);
	end;
{$ELSEC}
	function myNewModalFilter(theProc: ModalFilterProcPtr): ModalFilterUPP;
	begin
		return NewModalFilterUPP(theProc);
	end;
{$ENDC}

{$IFC NOT TARGET_CARBON}
	procedure myDisposeControlAction(theProc: ControlActionProcPtr);
	begin
		DisposeRoutineDescriptor(UniversalProcPtr(theProc));
	end;
{$ELSEC}
	procedure myDisposeControlAction(theProc: ControlActionProcPtr);
	begin
		DisposeControlActionUPP(theProc);
	end;
{$ENDC}

{$IFC NOT TARGET_CARBON}
	procedure myDisposeFilter(theFilterUPP: ModalFilterUPP);
	begin
		DisposeRoutineDescriptor(UniversalProcPtr(theFilterUPP));
	end;
{$ELSEC}
	procedure myDisposeFilter(theFilterUPP: ModalFilterUPP);
	begin
		DisposeModalFilterUPP(theFilterUPP);
	end;
{$ENDC}

{$IFC NOT TARGET_CARBON}
	procedure myDisposeUserItem(theUserItemUPP: UserItemUPP);
	begin
		DisposeRoutineDescriptor(UniversalProcPtr(theUserItemUPP));
	end;
{$ELSEC}
	procedure myDisposeUserItem(theUserItemUPP: UserItemUPP);
	begin
		DisposeUserItemUPP(theUserItemUPP);
	end;
{$ENDC}

{$PRAGMAC MARK -}

{$IFC NOT TARGET_CARBON}
	function myGetVisRgn(thePort: CGrafPtr): RgnHandle;
	begin
		myGetVisRgn := thePort^.visRgn;
	end;
{$ELSEC}
	function myGetVisRgn(thePort: CGrafPtr): RgnHandle;
		var
			myRgn: RgnHandle;
	begin
		myRgn := NewRgn;
		myRgn := GetPortVisibleRegion(thePort, myRgn);
		myGetVisRgn := myRgn;
	end;
{$ENDC}

{$IFC NOT TARGET_CARBON}
	function myGetPortRect(thePort: CGrafPtr): Rect;
	begin
		return thePort^.portRect;
	end;
{$ELSEC}
	function myGetPortRect(thePort: CGrafPtr): Rect;
		var
			myRectPtr: RectPtr;
			myRect: Rect;
	begin
		myRectPtr := GetPortBounds(thePort, myRect);
		return myRect;
	end;
{$ENDC}

{$PRAGMAC MARK -}

{$IFC NOT TARGET_CARBON}
	function myGetWindowRect(theWindow: WindowPtr): Rect;
	begin
		return theWindow^.portRect;
	end;
{$ELSEC}
	function myGetWindowRect(theWindow: WindowPtr): Rect;
		var
			myRectPtr: RectPtr;
			myRect: Rect;
	begin
		myRectPtr := GetWindowPortBounds(theWindow, myRect);
		return myRect;
	end;
{$ENDC}

{$IFC NOT TARGET_CARBON}
	function myWindowVisable(theWindow: WindowPtr): Boolean;
	begin
		myWindowVisable := WindowPeek(theWindow)^.visible;
	end;
{$ELSEC}
	function myWindowVisable(theWindow: WindowPtr): Boolean;
	begin
		myWindowVisable := IsWindowVisible(theWindow);
	end;
{$ENDC}

{$IFC NOT TARGET_CARBON}
	procedure myGetNextWindow(var theWindow: WindowPtr);
	begin
		WindowPeek(theWindow) := WindowPeek(theWindow)^.nextWindow;
	end;
{$ELSEC}
	procedure myGetNextWindow(var theWindow: WindowPtr);
	begin
		theWindow := GetNextWindow(theWindow);
	end;
{$ENDC}
	
{$IFC NOT TARGET_CARBON}
	function myGetNextWindowF(theWindow: WindowPtr): WindowPtr;
	begin
		WindowPeek(myGetNextWindowF) := WindowPeek(theWindow)^.nextWindow;
	end;
{$ELSEC}
	function myGetNextWindowF(theWindow: WindowPtr): WindowPtr;
	begin
		myGetNextWindowF := GetNextWindow(theWindow);
	end;
{$ENDC}

{$IFC NOT TARGET_CARBON}
	function myGetWindowStructureRgn(theWindow: WindowPtr): RgnHandle;
	begin
		myGetWindowStructureRgn := WindowPeek(theWindow)^.strucRgn;
	end;
{$ELSEC}
	function myGetWindowStructureRgn(theWindow: WindowPtr): RgnHandle;
		var
			myRgn: RgnHandle;
			myErr: OSErr;
	begin
		myRgn := NewRgn;
		myErr := GetWindowRegion(theWindow, kWindowStructureRgn, myRgn);
		myGetWindowStructureRgn := myRgn;
	end;
{$ENDC}

{$IFC NOT TARGET_CARBON}
	function myGetWindowStructureRect(theWindow: WindowPtr): Rect;
	begin
		myGetWindowStructureRect := WindowPeek(theWindow)^.strucRgn^^.rgnBBox;
	end;
{$ELSEC}
	function myGetWindowStructureRect(theWindow: WindowPtr): Rect;
		var
			myRgn: RgnHandle;
	begin
		myRgn := myGetWindowStructureRgn(theWindow);
		myGetWindowStructureRect := myGetRgnBBox(myRgn);
		DisposeRgn(myRgn);
	end;
{$ENDC}

{$PRAGMAC Mark -}

{$IFC NOT TARGET_CARBON}
	procedure myGetPort(var theWindow: WindowPtr);
	begin
		GetPort(theWindow);
	end;
{$ELSEC}
	procedure myGetPort(var theWindow: WindowPtr);
		var
			myPort: CGrafPtr;
	begin
		GetPort(GrafPtr(myPort));
		theWindow := GetWindowFromPort(myPort);
	end;
{$ENDC}

{$IFC NOT TARGET_CARBON}
	procedure mySetPort(theWindow: WindowPtr);
	begin
		SetPort(theWindow);
	end;
{$ELSEC}
	procedure mySetPort(theWindow: WindowPtr);
	begin
		SetPortWindowPort(theWindow);
	end;
{$ENDC}

{$IFC NOT TARGET_CARBON}
	function myGetWindowPort(theWindow: WindowPtr): CGrafPtr;
	begin
		myGetWindowPort := CGrafPtr(theWindow);
	end;
{$ELSEC}
	function myGetWindowPort(theWindow: WindowPtr): CGrafPtr;
	begin
		myGetWindowPort := GetWindowPort(theWindow);
	end;
{$ENDC}

	function myGrowWindow(theWindow: WindowPtr; thePoint: Point; var theRect: Rect): longint;
		var
			myRect: RectPtr;
	begin
		myRect := @theRect;
		myGrowWindow := GrowWindow(theWindow, thePoint, myRect);
	end;

	procedure myDragWindow(theWindow: WindowPtr; thePoint: Point; var theRect: Rect);
		var
			myRect: RectPtr;
	begin
		myRect := @theRect;
		DragWindow(theWindow, thePoint, myRect);
	end;

{$PRAGMAC MARK -}

{$IFC NOT TARGET_CARBON}
	function myGetDialogRect(theDialog: DialogPtr): Rect;
	begin
		myGetDialogRect := theDialog^.portRect;
	end;
{$ELSEC}
	function myGetDialogRect(theDialog: DialogPtr): Rect;
	begin
		myGetDialogRect := myGetPortRect(GetDialogPort(theDialog));
	end;
{$ENDC}

{$IFC NOT TARGET_CARBON}
	procedure myGetDPort(var theDialog: DialogPtr);
	begin
		GetPort(theDialog);
	end;
{$ELSEC}
	procedure myGetDPort(var theDialog: DialogPtr);
		var
			myPort: CGrafPtr;
	begin
		GetPort(GrafPtr(myPort));
		theDialog := GetDialogFromWindow(GetWindowFromPort(myPort));
	end;
{$ENDC}

{$IFC NOT TARGET_CARBON}
	procedure mySetDPort(theDialog: DialogPtr);
	begin
		SetPort(theDialog);
	end;
{$ELSEC}
	procedure mySetDPort(theDialog: DialogPtr);
	begin
		SetPortDialogPort(theDialog);
	end;
{$ENDC}

{$IFC NOT TARGET_CARBON}
	function myGetDialogPort(var theDialog: DialogPtr): CGrafPtr;
	begin
		myGetDialogPort := CGrafPtr(theDialog);
	end;
{$ELSEC}
	function myGetDialogPort(var theDialog: DialogPtr): CGrafPtr;
	begin
		myGetDialogPort := GetDialogPort(theDialog);
	end;
{$ENDC}

{$IFC NOT TARGET_CARBON}
	function myDialogToWindow(theDialog: DialogPtr): WindowPtr;
	begin
		myDialogToWindow := theDialog;
	end;
{$ELSEC}
	function myDialogToWindow(theDialog: DialogPtr): WindowPtr;
	begin
		myDialogToWindow := GetDialogWindow(theDialog);
	end;
{$ENDC}

{$IFC NOT TARGET_CARBON}
	function myWindowToDialog(theWindow: WindowPtr): DialogPtr;
	begin
		myWindowToDialog := theWindow;
	end;
{$ELSEC}
	function myWindowToDialog(theWindow: WindowPtr): DialogPtr;
	begin
		myWindowToDialog := GetDialogFromWindow(theWindow);
	end;
{$ENDC}

{$PRAGMAC Mark -}

{$IFC NOT TARGET_CARBON}
	procedure mySetCursorToArrow;
	begin
		SetCursor(qd.arrow);
	end;
{$ELSEC}
	procedure mySetCursorToArrow;
		var
			myCursor: Cursor;
	begin
		SetCursor(GetQDGlobalsArrow(myCursor)^);
	end;
{$ENDC}

	procedure mySetCursorToWatch;
	begin
		SetCursor(GetCursor(watchCursor)^^);
	end;
	
	procedure mySetCursorToCrosshair;
	begin
		SetCursor(GetCursor(crossCursor)^^);
	end;

{$PRAGMAC Mark -}

{$IFC NOT TARGET_CARBON}
	procedure myEnableItem(theMenu: MenuHandle; theItem: integer);
	begin
		EnableItem(theMenu, theItem);
	end;
{$ELSEC}
	procedure myEnableItem(theMenu: MenuHandle; theItem: integer);
	begin
		EnableMenuItem(theMenu, theItem);
	end;
{$ENDC}
	
{$IFC NOT TARGET_CARBON}
	procedure myDisableItem(theMenu: MenuHandle; theItem: integer);
	begin
		DisableItem(theMenu, theItem);
	end;
{$ELSEC}
	procedure myDisableItem(theMenu: MenuHandle; theItem: integer);
	begin
		DisableMenuItem(theMenu, theItem);
	end;
{$ENDC}

{$IFC NOT TARGET_CARBON}
	function myGetEnableDisable(theMenu: MenuHandle; theItem: integer): boolean;
		type
			EnabledDisabled = packed array [1..32] of boolean;
		var
			myEnabledDisabled: EnabledDisabled;
	begin
		longint(myEnabledDisabled) := theMenu^^.enableFlags;
		{Under pre 8.5 menu items > 32 are always enabled}
		if theItem > 32 then
			myGetEnableDisable := true
		else
			myGetEnableDisable := myEnabledDisabled[theItem];
	end;
{$ELSEC}
	function myGetEnableDisable(theMenu: MenuHandle; theItem: integer): boolean;
	begin
		myGetEnableDisable := IsMenuItemEnabled(theMenu, theItem);
	end;
{$ENDC}

{$IFC NOT TARGET_CARBON}
	function myCountMItems(theMenu: MenuHandle): integer;
	begin
		myCountMItems := CountMItems(theMenu);
	end;
{$ELSEC}
	function myCountMItems(theMenu: MenuHandle): integer;
	begin
		myCountMItems := CountMenuItems(theMenu);
	end;
{$ENDC}

{$PRAGMAC Mark -}

{$IFC NOT TARGET_CARBON}
	function myGetControlRect(theControl: ControlHandle): Rect;
	begin
		myGetControlRect := theControl^^.contrlrect;
	end;
{$ELSEC}
	function myGetControlRect(theControl: ControlHandle): Rect;
		var
			myRect: Rect;
			myRectPtr: RectPtr;
	begin
		myRectPtr := GetControlBounds(theControl, myRect);
		myGetControlRect := myRect;
	end;
{$ENDC}

{$IFC NOT TARGET_CARBON}
	function myGetControlOwner(theControl: ControlHandle): WindowPtr;
	begin
		myGetControlOwner := theControl^^.contrlOwner;
	end;
{$ELSEC}
	function myGetControlOwner(theControl: ControlHandle): WindowPtr;
	begin
		myGetControlOwner := GetControlOwner(theControl);
	end;
{$ENDC}

{$PRAGMAC Mark -}

{$IFC NOT TARGET_CARBON}
	function myKillScrap: OSErr;
	begin
		myKillScrap := ZeroScrap;
	end;
{$ELSEC}
	function myKillScrap: OSErr;
	begin
		myKillScrap := ClearCurrentScrap;
	end;
{$ENDC}

{$IFC NOT TARGET_CARBON}
	function myPutScrap(thePublic: boolean; theCount: SInt32; theFlavorType: ScrapFlavorType; theBuffer: UNIV Ptr): OSErr;
	begin
		myPutScrap := PutScrap(theCount, theFlavorType, theBuffer);
	end;
{$ELSEC}	
	function myPutScrap(thePublic: boolean; theCount: SInt32; theFlavorType: ScrapFlavorType; theBuffer: UNIV Ptr): OSErr;
		var
			myFlavorFlags: ScrapFlavorFlags;
			myScrapRef: ScrapRef;
			myErr: OSErr;
	begin
		if thePublic then
			myFlavorFlags := kScrapFlavorMaskNone
		else	
			myFlavorFlags := kScrapFlavorMaskSenderOnly;
		myErr := GetCurrentScrap(myScrapRef);
		if myErr = noErr then
			myErr := PutScrapFlavor(myScrapRef, theFlavorType, myFlavorFlags, theCount, theBuffer);
		myPutScrap := myErr;
	end;
{$ENDC}

{$IFC NOT TARGET_CARBON}
	function myGetScrap(theDestination: Handle; theFlavorType: ScrapFlavorType; var theOffset: SInt32): longint;
	begin
		myGetScrap := GetScrap(theDestination, theFlavorType, theOffset);
	end;
{$ELSEC}
	function myGetScrap(theDestination: Handle; theFlavorType: ScrapFlavorType; var theOffset: SInt32): longint;
		var
			myScrapRef: ScrapRef;
			myErr: OSErr;
			mySize: Size;
			myFlavorFlags: flavorFlags;
	begin
		myGetScrap := 0;
		myErr := GetCurrentScrap(myScrapRef);
		{this sepeates the two calls for size and data internally}
		if myErr = noErr then
			if theDestination = nil then
				begin
				{get scrap size}
					myErr := GetScrapFlavorFlags(myScrapRef, theFlavorType, myFlavorFlags);
					if myErr = noErr then
					{if there is data of this flavor, otherwise we would wait forever}
						begin
							myErr := GetScrapFlavorSize(myScrapRef, theFlavorType, mySize);
							if myErr = noErr then
								myGetScrap := mySize;
						end;
				end
			else
				begin
				{get scrap}
					HLock(theDestination);
					myGetScrap := GetScrapFlavorData(myScrapRef, theFlavorType, theOffset, theDestination^);
					HUnlock(theDestination);
				end;
	end;
{$ENDC}

{$PRAGMAC Mark -}
{for some reason HiWord and LoWord were not compiled into Carbon though they
are supported.  So I wrote pascal equivalents to the functions and use them 
in all my code.
}
	function myLoWord(theLong: longint): integer;
		type
			my2Int = packed array [1..2] of integer;
	begin
		myLoWord := my2Int(theLong)[2];
	end;
	
	function myHiWord(theLong: longint): integer;
		type
			my2Int = packed array [1..2] of integer;
	begin
		myHiWord := my2Int(theLong)[1];
	end;

end.