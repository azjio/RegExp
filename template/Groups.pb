#RegExp = 0

Text$ = "11111"

If CreateRegularExpression(#RegExp, "%regexp%", %flags%)
	Groups = CountRegularExpressionGroups(#RegExp)
	If Not Groups
		ProcedureReturn 0
	EndIf
	If ExamineRegularExpression(#RegExp, Text$)
		While NextRegularExpressionMatch(#RegExp)
			For i = 1 To Groups
				sResult$ + RegularExpressionGroup(#RegExp, i) + #CRLF$
			Next
		Wend
		Debug sResult$
	EndIf
Else
	ProcedureReturn RegularExpressionError()
EndIf
; IDE Options = PureBasic 5.72 (Windows - x86)
; CursorPosition = 16
; EnableAsm
; EnableXP
; DPIAware