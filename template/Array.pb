#RegExp = 0

NewList MyList.s()
Text$ = "11111"

If CreateRegularExpression(#RegExp, "%regexp%", %flags%)
	If ExamineRegularExpression(#RegExp, Text$)
		While NextRegularExpressionMatch(#RegExp)
			If AddElement(MyList())
				MyList() = RegularExpressionMatchString(#RegExp)
			EndIf
		Wend
	EndIf
Else
	Debug RegularExpressionError()
EndIf

ForEach MyList()
	Debug MyList()
Next

; IDE Options = PureBasic 5.72 (Windows - x86)
; CursorPosition = 6
; EnableAsm
; EnableXP
; DPIAware