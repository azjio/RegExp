#RegExp = 0
If CreateRegularExpression(#RegExp, "%regexp%",  %flags%)
	Text$ = ReplaceRegularExpression(#RegExp, Text$, "%replace%")
EndIf

; IDE Options = PureBasic 5.72 (Windows - x86)
; CursorPosition = 1
; EnableAsm
; EnableXP
; DPIAware