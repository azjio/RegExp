#RegExp = 0

Text$ = "11111"

If CreateRegularExpression(#RegExp, "%regexp%", %flags%)
	If ExamineRegularExpression(#RegExp, Text$)
		While NextRegularExpressionMatch(#RegExp)
			sResult$ + Str(RegularExpressionMatchPosition(#RegExp)) + " : " + Str(RegularExpressionMatchLength(#RegExp)) + " : " + RegularExpressionMatchString(#RegExp) + #CRLF$
		Wend
		Debug sResult$
	EndIf
Else
	ProcedureReturn RegularExpressionError()
EndIf
; IDE Options = PureBasic 5.72 (Windows - x86)
; CursorPosition = 2
; EnableAsm
; EnableXP
; DPIAware