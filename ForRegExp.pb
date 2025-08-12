;==================================================================
;
; Author:    ts-soft     
; Date:       March 5th, 2010
; Explain:
;     modified version from IBSoftware (CodeArchiv)
;     on vista and above check the Request for "User mode" or "Administrator mode" in compileroptions
;    (no virtualisation!)
;==================================================================
Procedure ForceDirectories(Dir.s)
	Static tmpDir.s, Init
	Protected result
	
	If Len(Dir) = 0
		ProcedureReturn #False
	Else
		If Not Init
			tmpDir = Dir
			Init   = #True
		EndIf
		If (Right(Dir, 1) = #PS$)
			Dir = Left(Dir, Len(Dir) - 1)
		EndIf
		If (Len(Dir) < 3) Or FileSize(Dir) = -2 Or GetPathPart(Dir) = Dir
			If FileSize(tmpDir) = -2
				result = #True
			EndIf
			tmpDir = ""
			Init = #False
			ProcedureReturn result
		EndIf
		ForceDirectories(GetPathPart(Dir))
		ProcedureReturn CreateDirectory(Dir)
	EndIf
EndProcedure


Procedure IsHex(*text)
	Protected flag = 1, *c.Character = *text

	If *c\c = 0
		ProcedureReturn 0
	EndIf

	Repeat
		If Not ((*c\c >= '0' And *c\c <= '9') Or (*c\c >= 'a' And *c\c <= 'f') Or (*c\c >= 'A' And *c\c <= 'F'))
			flag = 0
			Break
		EndIf
		*c + SizeOf(Character)
	Until Not *c\c

; 	Debug flag
	ProcedureReturn flag
EndProcedure

Procedure RGBtoBGR(c)
	ProcedureReturn RGB(Blue(c), Green(c), Red(c))
EndProcedure

; def если пустая строка или больше 6 или 5 или 4
; def в BGR, не RGB, то есть готовое для применения
; Color$ это RGB прочитанный из ini с последующим преобразованием в BGR
Procedure ColorValidate(Color$, def = 0)
	Protected tmp$, tmp2$, i
; 	Debug Color$
	i = Len(Color$)
	If i <= 6 And IsHex(@Color$)
		Select i
			Case 6
; 				def = Val("$" + Color$)
; 				RGBtoBGR2(@def)
				def = RGBtoBGR(Val("$" + Color$))
			Case 1
				def = Val("$" + LSet(Color$, 6, Color$))
			Case 2
				def = Val("$" + Color$ + Color$ + Color$)
			Case 3
; 				сразу переворачиваем в BGR
				For i = 3 To 1 Step -1
					tmp$ = Mid(Color$, i, 1)
					tmp2$ + tmp$ + tmp$
				Next
				def = Val("$" + tmp2$)
		EndSelect
	EndIf
; 	Debug Hex(def)
	ProcedureReturn def
EndProcedure



Structure ReplaceGr
  pos.i
  ngr.i
  group.s
EndStructure


; https://www.purebasic.fr/english/viewtopic.php?p=575871
Procedure RegexReplace2(RgEx, *Result.string, Replace0$, Escaped = 0)
	Protected i, CountGr, Pos, Offset = 1
	Protected Replace$
	Protected NewList item.s()
	Protected LenT, *Point
; 	Static RE2
; 	Static RE3
	Protected RE2
	Protected NewList ReplaceGr.ReplaceGr()

	CountGr = CountRegularExpressionGroups(RgEx)
	; ограничение групп, только обратные ссылки \1 .. \9
	If CountGr > 9
		CountGr = 9
	EndIf

	If ExamineRegularExpression(RgEx, *Result\s)

		; Поиск Esc-символов в поле замены регвыр (с учётом регистра)
		If Escaped
			Replace0$ = ReplaceString(Replace0$, "\r", #CR$)
			Replace0$ = ReplaceString(Replace0$, "\n", #LF$)
			Replace0$ = ReplaceString(Replace0$, "\t", #TAB$)
			Replace0$ = ReplaceString(Replace0$, "\f", #FF$)
		EndIf

		; Поиск ссылок на группы в поле замены регвыр
		RE2 = CreateRegularExpression(#PB_Any, "\\\d")
		If RE2
			If ExamineRegularExpression(RE2, Replace0$)
				While NextRegularExpressionMatch(RE2)
					If AddElement(ReplaceGr())
						ReplaceGr()\pos = RegularExpressionMatchPosition(RE2) ; позиция
						ReplaceGr()\ngr = ValD(Right(RegularExpressionMatchString(RE2), 1)) ; номер группы
						ReplaceGr()\group = RegularExpressionMatchString(RE2) ; текст группы
					EndIf
				Wend
			EndIf
			FreeRegularExpression(RE2) ; убрать строку при Static
		EndIf
		If Not ListSize(ReplaceGr())
			*Result\s = ReplaceRegularExpression(RgEx, *Result\s, Replace0$)
			ProcedureReturn
		EndIf
; 		Сортировка по позиции, чтобы делать замены с конца и не нарушались ранее найденные позиции
		SortStructuredList(ReplaceGr(), #PB_Sort_Descending, OffsetOf(ReplaceGr\pos), TypeOf(ReplaceGr\pos))

		While NextRegularExpressionMatch(RgEx)
			Pos = RegularExpressionMatchPosition(RgEx)
			Replace$ = Replace0$

			ForEach ReplaceGr()
				If ReplaceGr()\ngr
					Replace$ = ReplaceString(Replace$, ReplaceGr()\group, RegularExpressionGroup(RgEx, ReplaceGr()\ngr), #PB_String_CaseSensitive, ReplaceGr()\pos, 1)
				Else
					Replace$ = ReplaceString(Replace$, ReplaceGr()\group, RegularExpressionMatchString(RgEx), #PB_String_CaseSensitive, ReplaceGr()\pos, 1) ; обратная ссылка \0
				EndIf
			Next
			; item() = часть строки между началом и первым совпадением или между двумя совпадениями + результат подстановки групп

			If AddElement(item())
				item() = Mid(*Result\s, Offset, Pos - Offset) + Replace$
			EndIf
			Offset = Pos + RegularExpressionMatchLength(RgEx)
		Wend
		If AddElement(item())
			item() = Mid(*Result\s, Offset)
		EndIf

		; Формирования текстового списка
		; Debug "Count = " + Str(ListSize(item()))
; 		Count = ListSize(item())
		LenT = 0
		ForEach item()
			LenT + Len(item()) ; вычисляем длину данных для  вмещения частей текста
		Next

		*Result\s = Space(LenT) ; создаём строку забивая её пробелами
		*Point = @*Result\s	   ; Получаем адрес строки
		ForEach item()
			CopyMemoryString(item(), @*Point) ; копируем очередной путь в указатель
		Next
		; Конец => Формирования текстового списка

		FreeList(item()) ; удаляем список, хотя в функции наверно это не требуется
	EndIf
EndProcedure

CompilerIf #PB_Compiler_OS = #PB_OS_Windows
; ChrisR
; https://www.purebasic.fr/english/viewtopic.php?p=582960#p582960
Structure PropColors
  BackColor.i
  TextColor.i
EndStructure
Global NewMap PropColor.PropColors()

Procedure CheckOptionColor(Gadget, BackColor = #PB_Default, TextColor = #PB_Default)
  Protected None
  If Not(IsGadget(Gadget)) : ProcedureReturn : EndIf
  If GadgetType(Gadget) = #PB_GadgetType_CheckBox Or GadgetType(Gadget) = #PB_GadgetType_Option
    If BackColor = #PB_Default And TextColor = #PB_Default
      DeleteMapElement(PropColor(), Str(Gadget))
      ProcedureReturn
    EndIf
    If BackColor = #PB_Default
      If OSVersion() < #PB_OS_Windows_10
        BackColor = GetSysColor_(#COLOR_BTNFACE)
      Else
        BackColor = GetSysColor_(#COLOR_3DFACE)
      EndIf
    EndIf
    If TextColor = #PB_Default
      TextColor = GetSysColor_(#COLOR_BTNTEXT)
    EndIf
    PropColor(Str(Gadget))\BackColor = BackColor
    PropColor(Str(Gadget))\TextColor = TextColor
    SetWindowTheme_(GadgetID(Gadget), @None, @None)
  EndIf
EndProcedure

CompilerEndIf
; IDE Options = PureBasic 6.04 LTS (Linux - x64)
; CursorPosition = 34
; FirstLine = 26
; Folding = --
; EnableAsm
; EnableXP
; DPIAware