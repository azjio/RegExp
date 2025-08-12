#RegExp = 0
If CreateRegularExpression(#RegExp, "%regexp%", %flags%)
	If MatchRegularExpression(#RegExp, Text$)
		Debug "Yes"
	EndIf
EndIf

; IDE Options = PureBasic 5.72 (Windows - x86)
; CursorPosition = 1
; EnableAsm
; EnableXP
; DPIAware