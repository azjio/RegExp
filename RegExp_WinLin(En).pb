;- TOP

EnableExplicit

; Определяет язык ОС
Define UserIntLang
Define ForceLangSel

CompilerSelect #PB_Compiler_OS
	CompilerCase #PB_OS_Windows
		Global *Lang
		If OpenLibrary(0, "kernel32.dll")
			*Lang = GetFunction(0, "GetUserDefaultUILanguage")
			If *Lang And CallFunctionFast(*Lang) = 1049 ; ru
				UserIntLang = 1
			EndIf
			CloseLibrary(0)
		EndIf
	CompilerCase #PB_OS_Linux
		If ExamineEnvironmentVariables()
			While NextEnvironmentVariable()
				If Left(EnvironmentVariableName(), 4) = "LANG" And Left(EnvironmentVariableValue(), 2) = "ru"
					; LANG=ru_RU.UTF-8
					; LANGUAGE=ru
					UserIntLang = 1
					Break
				EndIf
			Wend
		EndIf
CompilerEndSelect

#CountStrLang = 53
Global Dim Lng.s(#CountStrLang)
Lng(1) = "Scintilla.dll not found"
Lng(2) = "There is no text to process"
Lng(3) = "Found"
Lng(4) = "Not found."
Lng(5) = "There are no groups, separate the groups with parentheses in a regular expression"
Lng(6) = "Regular expression test"
Lng(7) = "Regular expressions for searching"
Lng(8) = "Replacement text"
Lng(9) = "Text to be processed and result"
Lng(10) = "Open file for processing"
Lng(11) = "Clear all fields"
Lng(12) = "Add/replace to library"
Lng(13) = "Remove item from library"
Lng(14) = "Metacharacters menu"
Lng(15) = "Move text up"
Lng(16) = "Show range"
Lng(17) = "Reference"
Lng(18) = "Start"
Lng(19) = "On top"
Lng(20) = "do not update"
Lng(21) = "Do not update processing text when inserting templates"
Lng(22) = "(?s) full stop"
Lng(23) = "(?x) ignore spaces and comments."
Lng(24) = "(?m) multiline text (^...$)"
Lng(25) = "Any of CR, LF, and CRLF"
Lng(26) = "(?i) Ignore case"
Lng(27) = "The point also includes LF"
Lng(28) = "The line separator can be any of these characters"
Lng(29) = "Search"
Lng(30) = "Replacement"
Lng(31) = "Array"
Lng(32) = "Groups"
Lng(33) = "Step by step"
Lng(34) = "Until the first match"
Lng(35) = "Replace all occurrences"
Lng(36) = "All complete occurrences"
Lng(37) = "What's in parentheses"
Lng(38) = "More position and length"
Lng(39) = "Support for groups \1...\9"
Lng(40) = "With markings"
Lng(41) = "Marks the beginning, useful for multi-line"
Lng(42) = "Input data is empty"
Lng(43) = "Template file not found"
Lng(44) = "Name"
Lng(45) = "Enter the name of the item"
Lng(46) = "Re-record?"
Lng(47) = "Paragraph "
Lng(48) = "already exists, should I overwrite it?"
Lng(49) = "Delete?"
Lng(50) = "Delete: "
Lng(51) = "Found: "
Lng(52) = "Range Test"
Lng(53) = "Code on clipboard"

EnableExplicit
UseGIFImageDecoder()

; хотел восмеричные получать в функции TestRange()
; ImportC ""
;     sprintf(*str, format.p-utf8, Param1=0, Param2=0, Param3=0, Param4=0, Param5=0, Param6=0)
; EndImport

CompilerIf #PB_Compiler_OS = #PB_OS_Linux
	UseBriefLZPacker()
CompilerEndIf

XIncludeFile "ForRegExp.pb"

Structure SciRegExp
	re.s
	id.i
	len.i
	*mem
EndStructure

Global NewList regex.SciRegExp()

#q$ = Chr(34)

;- ● Global
Global *mem
Global Error_Procedure = 0
Global NewList RecentUsed.s()
; Global MenuMax = -1
Global Cur_idx = -2
; Global flgHSave = 0
Global flgSelChange
Global hCmbSq = -99
Global tmp


Define tmp$
Define i, idx
Define eMenu, sResult$
Global maxfreq.q, TimeOldDiff.q

CompilerIf #PB_Compiler_OS = #PB_OS_Windows
	QueryPerformanceFrequency_(@maxfreq)
	; Debug maxfreq
	maxfreq / 1000000
CompilerEndIf

Global TextLength
#SCFIND_CXX11REGEX = $00800000


Enumeration Window
	#Window
	#WinRange
EndEnumeration

Enumeration Menu
	#HistoryMenu
	#LibMenu
	#MetaMenu
	#HotMenu
EndEnumeration

;- ● Enumeration
; Порядок имеет значение для цветовой окраски гаджетов (для Windows)
; #Opt_Search - #Ch_NotUpd - подсветка чекбоксов
; #HL_help - #t3 - подсветка надписей
; #FiedReplace - #Splitter - подсветка полей
; #HL_help - #TimeNew - подсветка шрифта
Enumeration Gadget
	#Opt_Search
	#Opt_Replace
	#Opt_Array
	#Opt_Group
	#Opt_Step
	#Ch_s
	#Ch_x
	#Ch_m
	#Ch_CRLF
	#Ch_i
	#Ch_reg2
	#Ch_markup
	#Ch_Esc
	#Ch_OnTop
	#Ch_NotUpd
	#HL_help
	#t1
	#t2
	#t3

	#FiedReplace
	#Ed_Sourse
	#Ed_Destination
	#LV
	#TimeOld
	#TimeNew
	#Splitter
	#btnMenu
	#btnMeta
	#btnUp
	#btnRange
	#btnStart
	#btnCopy
	#SciGadget
	#btnOpen
	#btnLib
	#btnClear
	#btnAddToLib
	#btnDel
	#LvTest
	#cmbSq
	#btnUpdRng
	#StatusBar
; 	#btnSaveLib
EndEnumeration

;- ● Declare
; Declare.s RegexReplace2(RgEx, *Result.string, Replace0$, Once = 0)
DeclareDLL SciNotification(Gadget, *scinotify.SCNotification)
; Declare Color2(*regex, regexLength, n)
Declare.s GetScintillaGadgetText()
Declare CopyCode2Clipboard()
Declare FindLIbFile()
Declare Fill_fields()
Declare AddToLib()
Declare AddLast()
Declare ExitProg()
Declare StartRE()
Declare TestRange()
Declare SizeWinRange()
Declare SizeWindow()
Declare RangeCheck(value, min, max)
Declare DeleteElemLib()
Declare ReadFileToEdit(FilePath$)
Declare SetSample(FilePath$)
Declare SetExeRegExpToLV(Text$)



; Функции
;-┌─Procedure─┐

; В массив
Procedure.s ExtractRE(sRE1$, *s.String, FlagsRE, Label)
	Protected rex_id, NbFound, i, Gsub$ = Chr($25AC)
	Protected Len, *Point, Result.String
	If *s\s = ""
		Error_Procedure = 1
		ProcedureReturn Lng(2)
	EndIf
	rex_id = CreateRegularExpression(#PB_Any, sRE1$, FlagsRE)
	If rex_id
		Protected Dim asResult$(0)
		NbFound = ExtractRegularExpression(rex_id, *s\s, asResult$())
		; Вычислим размер необходимой памяти.
; 		А почему внедрили этот код?
; 		А потому что при 100 000 элементов ожидание было 11 минут.
		For i = 0 To NbFound - 1
			Len + Len(asResult$(i))
			If Label
				Len + Len(Str(i))
			EndIf
		Next
		Len + (NbFound * 2) ; +#CRLF$
		If Label
			Len + (NbFound * 3) ; +Gsub$ + Space + Space
		EndIf
		; конец: Вычислим размер необходимой памяти
		Result\s = Space(Len)
		*Point = @Result\s
		For i = 0 To NbFound - 1
			If Label
; 				sResult$ + Gsub$ + " " + Str(i) + " " + asResult$(i) + #CRLF$
				CopyMemoryString(Gsub$ + " ", @*Point)
				CopyMemoryString(Str(i) + " ", @*Point)
				CopyMemoryString(asResult$(i) + #CRLF$, @*Point)
			Else
; 				sResult$ + asResult$(i) + #CRLF$
				CopyMemoryString(asResult$(i) + #CRLF$, @*Point)
; 				CopyMemoryString(#CRLF$, @*Point)
			EndIf
		Next

; 		старый код конкатенакции
; 		For i = 0 To NbFound - 1
; 			If Label
; 				sResult$ + Gsub$ + " " + Str(i) + " " + asResult$(i) + #CRLF$
; 			Else
; 				sResult$ + asResult$(i) + #CRLF$
; 			EndIf
; 		Next
		FreeRegularExpression(rex_id)
	Else
		Error_Procedure = 1
		ProcedureReturn RegularExpressionError()
	EndIf
	ProcedureReturn Result\s
EndProcedure

; Поиск
Procedure.s SearchRE(sRE1$, *s.string, FlagsRE)
	Protected rex_id, sResult$
	If *s\s = ""
		Error_Procedure = 1
		ProcedureReturn Lng(2)
	EndIf
	rex_id = CreateRegularExpression(#PB_Any, sRE1$, FlagsRE)
	If rex_id
		If MatchRegularExpression(rex_id, *s\s)
			sResult$ = Lng(3)
		Else
			sResult$ = Lng(4)
		EndIf
		FreeRegularExpression(rex_id)
	Else
		Error_Procedure = 1
		ProcedureReturn RegularExpressionError()
	EndIf
	ProcedureReturn sResult$
EndProcedure

; Пошаговый
Procedure.s StepRE(sRE1$, *s.string, FlagsRE, Label)
	Protected rex_id, Gsub$ = Chr($25AC), i
	Protected Len, *Point, Result.String
	Protected NewList FindList.s()
	If *s\s = ""
		Error_Procedure = 1
		ProcedureReturn Lng(2)
	EndIf
	rex_id = CreateRegularExpression(#PB_Any, sRE1$, FlagsRE)
	If rex_id
		If ExamineRegularExpression(rex_id, *s\s)
			While NextRegularExpressionMatch(rex_id)
				AddElement(FindList())
				If Label
					i + 1
					FindList() = Gsub$ + " " + Str(i) + " " + Gsub$ + " " + Str(RegularExpressionMatchPosition(rex_id)) + " : " + Str(RegularExpressionMatchLength(rex_id)) + " : " + RegularExpressionMatchString(rex_id) + #CRLF$
				Else
					FindList() = Str(RegularExpressionMatchPosition(rex_id)) + " : " + Str(RegularExpressionMatchLength(rex_id)) + " : " + RegularExpressionMatchString(rex_id) + #CRLF$
				EndIf
			Wend
		EndIf
		FreeRegularExpression(rex_id)
	Else
		Error_Procedure = 1
		ProcedureReturn RegularExpressionError()
	EndIf
	
	
	; Вычислим размер необходимой памяти.
	; А почему внедрили этот код?
	; А потому что при 100 000 элементов ожидание было 11 минут. При 5000 найденых элементов скорость в 2 раза выше.
	ForEach FindList()
		Len + Len(FindList())
	Next
	; конец: Вычислим размер необходимой памяти
	Result\s = Space(Len)
	*Point = @Result\s
	ForEach FindList()
		CopyMemoryString(FindList(), @*Point)
	Next
	
	
	; 	SetClipboardText(Result\s)
	ProcedureReturn Result\s
EndProcedure

; Группы
Procedure.s GroupsRE(sRE1$, *s.string, FlagsRE, Label)
	Protected rex_id, Groups, i, d, Groot$, Gsub$ = Chr($25AC)
	Protected Len, *Point, Result.String
	Protected NewList FindList.s()
	If *s\s = ""
		Error_Procedure = 1
		ProcedureReturn Lng(2)
	EndIf
	rex_id = CreateRegularExpression(#PB_Any, sRE1$, FlagsRE)
	If rex_id
		Groups = CountRegularExpressionGroups(rex_id)
		If Not Groups
			Error_Procedure = 1
			ProcedureReturn Lng(5)
		EndIf
		If Label
			Groot$ = LSet("" , 10, Gsub$)
		EndIf
		If ExamineRegularExpression(rex_id, *s\s)
			While NextRegularExpressionMatch(rex_id)
				If Label
					d + 1
					AddElement(FindList())
					FindList() = Str(d) + " " + Groot$ + #CRLF$
				EndIf
				For i = 1 To Groups
					AddElement(FindList())
					If Label
						FindList() = Gsub$ + Gsub$ + " " + Str(i) + " " + Gsub$ + " " + RegularExpressionGroup(rex_id, i) + #CRLF$
					Else
						FindList() = RegularExpressionGroup(rex_id, i) + #CRLF$
					EndIf
				Next
			Wend
		EndIf
		FreeRegularExpression(rex_id)
	Else
		Error_Procedure = 1
		ProcedureReturn RegularExpressionError()
	EndIf
	
	
	; Вычислим размер необходимой памяти.
	; А почему внедрили этот код?
	; А потому что при 100 000 элементов ожидание было 11 минут. При 5000 найденых элементов скорость в 2 раза выше.
	ForEach FindList()
		Len + Len(FindList())
	Next
	; конец: Вычислим размер необходимой памяти
	Result\s = Space(Len)
	*Point = @Result\s
	ForEach FindList()
		CopyMemoryString(FindList(), @*Point)
	Next
	
	
	ProcedureReturn Result\s
EndProcedure

; Замена
Procedure.s ReplaceRE(sRE1$, *s.string, sRP2$, FlagsRE)
	Protected rex_id, ESC
	If *s\s = ""
		Error_Procedure = 1
		ProcedureReturn Lng(2)
	EndIf

	rex_id = CreateRegularExpression(#PB_Any, sRE1$, FlagsRE)
	If rex_id
		ESC = GetGadgetState(#Ch_Esc) & #PB_Checkbox_Checked
		If GetGadgetState(#Ch_reg2) & #PB_Checkbox_Checked Or ESC
			RegexReplace2(rex_id, *s, sRP2$, ESC)
			ProcedureReturn *s\s
		Else
			ProcedureReturn ReplaceRegularExpression(rex_id, *s\s, sRP2$)
		EndIf
		FreeRegularExpression(rex_id)
	Else
		Error_Procedure = 1
		ProcedureReturn RegularExpressionError()
	EndIf
EndProcedure

Procedure SetProgParam()
	Protected CountP, tmp$, i
	CountP = CountProgramParameters()
	For i = 0 To CountP - 1
		tmp$ = ProgramParameter(i)
		Select Left(tmp$, 3)
			Case "-l:"
				SetSample(Mid(tmp$, 4))
			Case "-i:"
				SetGadgetState(#LV, Val(Mid(tmp$, 4)))
				Fill_fields()
			Case "-nu"
				SetGadgetState(#Ch_NotUpd, 1)
			Default
				ReadFileToEdit(tmp$)
		EndSelect
	Next
EndProcedure
;-└───End───┘


;- ● Global ini$
Global ini$
Global isINI = 0
Global PathConfig$

Global mn1

Global maxhistor = 30
Global SciHeight = 28
Global lastlib$ = ""
Global w3, h3

CompilerSelect #PB_Compiler_OS
	CompilerCase #PB_OS_Windows
		Global SciFont$ = "Consolas"
		Global Font$ = "Arial"
	CompilerCase #PB_OS_Linux
		Global SciFont$ = "DejaVuSansMono"
		Global Font$ = "NotoSans"
CompilerEndSelect
Global *Font

Global w = 930
Global h = 508
Global topmost = 0
Global copysel = 0
Define mn3, mn2, mn4

Define iniMenu$
Define SciFontSize = 16
Define fontsize = 11
; BGR
Define background = $3f3f3f
Define color_default = $aaaaaa
Global clrTime1 = $D7D7FF
Global clrTime2 = $CCFFD2
Define select_bg = $ffffff
Define select_fnt = $a0a0a0
Define caret = $ffffff
Define re_Repeat = $71AE71
Define re_SqBrackets = $FF8000
Define re_RndBrackets = $8080FF
Define re_AnyText = $DE97D9
Define re_Meta = $72C0C4
Define re_Borders = $FF66F6
Define re_ChrH = $DE97D9
Define re_RndBrackets2 = $8888FF
Define StyleColor$ = "style1"
Define typeBF = 0
Define ColorGui = 0
Define ColorGadget = 0
Define ColorGadgetFont = 0



;- ini
PathConfig$ = GetPathPart(ProgramFilename())
If FileSize(PathConfig$ + "RegExpPB.ini") = -1
	CompilerSelect #PB_Compiler_OS
		CompilerCase #PB_OS_Windows
			PathConfig$ = GetHomeDirectory() + "AppData\Roaming\RegExpPB\"
		CompilerCase #PB_OS_Linux
			PathConfig$ = GetHomeDirectory() + ".config/RegExpPB/"
			If FileSize(PathConfig$) = -1 And FileSize("/usr/share/azjio/RegExpPB/config-archive-BriefLZ.blz") > 0
				#Archive = 0
				If OpenPack(#Archive, "/usr/share/azjio/RegExpPB/config-archive-BriefLZ.blz")
					If ExaminePack(#Archive)
						While NextPackEntry(#Archive)
							If UncompressPackFile(#Archive, PathConfig$ + PackEntryName(#Archive), PackEntryName(#Archive)) = -1 And ForceDirectories(GetPathPart(PathConfig$ + PackEntryName(#Archive)))
								UncompressPackFile(#Archive, PathConfig$ + PackEntryName(#Archive), PackEntryName(#Archive))
							EndIf
						Wend
					EndIf
					ClosePack(#Archive)
				EndIf
			EndIf
; 		CompilerCase #PB_OS_MacOS
; 			PathConfig$ = GetHomeDirectory() + "Library/Application Support/RegExpPB/"
	CompilerEndSelect
EndIf
ini$ = PathConfig$ + "RegExpPB.ini"
iniMenu$ = PathConfig$ + "Menu.ini"


If FileSize(ini$) > -1 And OpenPreferences(ini$)
	isINI = 1

	PreferenceGroup("Set")
	h = ReadPreferenceInteger("height", h)
	RangeCheck(w, 500, 1500)
	w = ReadPreferenceInteger("width", w)
	RangeCheck(w, 650, 2000)
	SciFontSize = ReadPreferenceInteger("scifontsize", SciFontSize)
	RangeCheck(SciFontSize, 6, 60)
	fontsize = ReadPreferenceInteger("fontsize", fontsize)
	RangeCheck(fontsize, 6, 60)
	topmost = ReadPreferenceInteger("topmost", topmost)
	copysel = ReadPreferenceInteger("copysel", copysel)
	SciHeight = ReadPreferenceInteger("sciheight", SciHeight)
	SciHeight = RangeCheck(SciHeight, 20, 300)
	maxhistor = ReadPreferenceInteger("maxhistor", maxhistor)
	RangeCheck(maxhistor, 2, 200)
	StyleColor$ = ReadPreferenceString("style", StyleColor$)
	lastlib$ = ReadPreferenceString("lastlib", lastlib$)
	SciFont$ = ReadPreferenceString("scifont", SciFont$)
	Font$ = ReadPreferenceString("font", Font$)
	ForceLangSel = ReadPreferenceInteger("ForceLangSel", ForceLangSel)

	PreferenceGroup(StyleColor$)
	CompilerIf #PB_Compiler_OS = #PB_OS_Windows
		ColorGui = ColorValidate(ReadPreferenceString("gui", ""), ColorGui)
		ColorGadget = ColorValidate(ReadPreferenceString("gadget", ""), ColorGadget)
		ColorGadgetFont = ColorValidate(ReadPreferenceString("gadgetfont", ""), ColorGadgetFont)
	CompilerEndIf
	typeBF = ReadPreferenceInteger("type", typeBF)
	background = ColorValidate(ReadPreferenceString("background", ""), background)
	color_default = ColorValidate(ReadPreferenceString("default", ""), color_default)
	clrTime1 = ColorValidate(ReadPreferenceString("timered", ""), clrTime1)
	clrTime2 = ColorValidate(ReadPreferenceString("timegrn", ""), clrTime2)
	select_bg = ColorValidate(ReadPreferenceString("select_bg", ""), select_bg)
	select_fnt = ColorValidate(ReadPreferenceString("select_fnt", ""), select_fnt)
	caret = ColorValidate(ReadPreferenceString("caret", ""), caret)
	re_Repeat = ColorValidate(ReadPreferenceString("re_Repeat", ""), re_Repeat)
	re_SqBrackets = ColorValidate(ReadPreferenceString("re_SqBrackets", ""), re_SqBrackets)
	re_RndBrackets = ColorValidate(ReadPreferenceString("re_RndBrackets", ""), re_RndBrackets)
	re_RndBrackets2 = ColorValidate(ReadPreferenceString("re_RndBrackets2", ""), re_RndBrackets2)
	re_AnyText = ColorValidate(ReadPreferenceString("re_AnyText", ""), re_AnyText)
	re_Meta = ColorValidate(ReadPreferenceString("re_Meta", ""), re_Meta)
	re_Borders = ColorValidate(ReadPreferenceString("re_Borders", ""), re_Borders)
	re_ChrH = ColorValidate(ReadPreferenceString("re_ChrH", ""), re_ChrH)

	ClosePreferences()
EndIf

; Здесь нужно прочитать флаг из ini-файла определяющий принудительный язык, где
; 0 - автоматически
; -1 - принудительно первый
; 1 - принудительно второй
; Тем самым будучи в России можно выбрать англ язык или будучи в союзных республиках выбрать русский язык
If ForceLangSel = 1
	UserIntLang = 0
ElseIf ForceLangSel = 2
	UserIntLang = 1
EndIf

Procedure SetLangTxt(PathLang$)
	Protected file_id, Format, i, tmp$
	
	file_id = ReadFile(#PB_Any, PathLang$) 
	If file_id ; Если удалось открыть дескриптор файла, то
		Format = ReadStringFormat(file_id) ;  перемещаем указатель после метки BOM
		i=0
		While Eof(file_id) = 0        ; Цикл, пока не будет достигнут конец файла. (Eof = 'Конец файла')
			tmp$ =  ReadString(file_id, Format) ; читаем строку
								  ; If Left(tmp$, 1) = ";"
								  ; Continue
								  ; EndIf
; 			tmp$ = ReplaceString(tmp$ , #CR$ , "") ; коррекция если в Windows
			tmp$ = RTrim(tmp$ , #CR$) ; коррекция если в Windows
			If Asc(tmp$) And Asc(tmp$) <> ';'
				i+1
				If i > #CountStrLang ; массив Lng() уже задан, но если строк больше нужного, то не разрешаем лишнее
					Break
				EndIf
; 				Lng(i) = UnescapeString(tmp$) ; позволяет в строке иметь экранированные метасимволы, \n \t и т.д.
				Lng(i) = ReplaceString(tmp$, "\n", #LF$) ; В ini-файле проблема только с переносами, поэтому заменяем только \n
			Else
				Continue
			EndIf
		Wend
		CloseFile(file_id)
	EndIf
	; Else
	; SaveFile_Buff(PathLang$, ?LangFile, ?LangFileend - ?LangFile)
EndProcedure

; Если языковой файл существует, то использует его
If FileSize(PathConfig$ + "Lang.txt") > 100
	UserIntLang = 0
	SetLangTxt(PathConfig$ + "Lang.txt")
EndIf

If UserIntLang
	Lng(1) = "Не найден файл Scintilla.dll"
	Lng(2) = "Отсутствует текст для обработки"
	Lng(3) = "Найдено"
	Lng(4) = "Не найдено."
	Lng(5) = "Нет групп, выделите группы скобками в регулярном выражении"
	Lng(6) = "Тест регулярных выражений"
	Lng(7) = "Регулярное выражения для поиска"
	Lng(8) = "Текст замены"
	Lng(9) = "Текст для обработки и результат"
	Lng(10) = "Открыть файл для обработки"
	Lng(11) = "Очистить все поля"
	Lng(12) = "Добавить/заменить в библиотеку"
	Lng(13) = "Удалить пункт из библиотеки"
	Lng(14) = "Меню метасимволов"
	Lng(15) = "Переместить текст вверх"
	Lng(16) = "Показать диапазон"
	Lng(17) = "Справка"
	Lng(18) = "Старт"
	Lng(19) = "Поверх"
	Lng(20) = "не обновлять"
	Lng(21) = "Не обновлять текст обработки при вставке шаблонов"
	Lng(22) = "(?s) точка всё"
	Lng(23) = "(?x) игнор пробелов и коммент."
	Lng(24) = "(?m) многостроч. текст (^...$)"
	Lng(25) = "Любой из CR, LF, и CRLF"
	Lng(26) = "(?i) не учитывать регистр"
	Lng(27) = "Точка включает в себя ещё и LF"
	Lng(28) = "Разделение строк может быть любым из этих символов"
	Lng(29) = "Поиск"
	Lng(30) = "Замена"
	Lng(31) = "Массив"
	Lng(32) = "Группы"
	Lng(33) = "Пошаговый"
	Lng(34) = "До первого совпадения"
	Lng(35) = "Замена всех вхождений"
	Lng(36) = "Все полные вхождения"
	Lng(37) = "То что в скобках"
	Lng(38) = "Ещё позиция и длина"
	Lng(39) = "Поддержка групп \1...\9"
	Lng(40) = "С разметкой"
	Lng(41) = "Помечает начало, полезно для многострочных"
	Lng(42) = "Входные данные пусты"
	Lng(43) = "Не найден файл шаблона"
	Lng(44) = "Имя"
	Lng(45) = "Укажите имя пункта"
	Lng(46) = "Перезаписать?"
	Lng(47) = "Пункт "
	Lng(48) = " уже существует, перезаписать его?"
	Lng(49) = "Удалить?"
	Lng(50) = "Удалить: "
	Lng(51) = "Найдено: "
	Lng(52) = "Тест диапазона"
	Lng(53) = "Код в буфере обмена"
EndIf

CompilerIf #PB_Compiler_Version < 610
	If Not InitScintilla()
		CompilerIf #PB_Compiler_OS = #PB_OS_Windows
			MessageRequester("", Lng(1))
		CompilerEndIf
		End
	EndIf
CompilerEndIf

w3 = w
h3 = h


CompilerIf #PB_Compiler_OS = #PB_OS_Windows


	Procedure MainWindow_Callback(hWnd, uMsg, wParam, lParam)
		Protected Gadget, Result = #PB_ProcessPureBasicEvents
		Select uMsg
			Case #WM_CTLCOLORSTATIC
				Gadget = GetDlgCtrlID_(lParam)
				If FindMapElement(PropColor(), Str(Gadget))
					SetTextColor_(wParam, PropColor(Str(Gadget))\TextColor)
					SetBkMode_(wParam, #TRANSPARENT)
					ProcedureReturn CreateSolidBrush_(PropColor(Str(Gadget))\BackColor)
				EndIf
		EndSelect
		ProcedureReturn Result
	EndProcedure

	Procedure WinRange_Callback(hWnd, uMsg, wParam, lParam)
		Protected Gadget, Result = #PB_ProcessPureBasicEvents
		Protected nNotifyCode
		Select uMsg
			Case #WM_COMMAND
				If lParam = hCmbSq
					nNotifyCode = wParam >> 16 ; HiWord
					If nNotifyCode = #CBN_SELCHANGE
						flgSelChange = 1
					EndIf
				EndIf
		EndSelect
		ProcedureReturn Result
	EndProcedure

CompilerEndIf

;- Data
DataSection
	CompilerIf #PB_Compiler_OS = #PB_OS_Linux
		IconTitle:
		IncludeBinary "images" + #PS$ + "icon.gif"
		IconTitleend:
	CompilerEndIf
	clear:
	IncludeBinary "images" + #PS$ + "clear.gif"
	clearend:
	folder:
	IncludeBinary "images" + #PS$ + "folder.gif"
	folderend:
	add:
	IncludeBinary "images" + #PS$ + "add.gif"
	addend:
	del:
	IncludeBinary "images" + #PS$ + "del.gif"
	delend:
	meta:
	IncludeBinary "images" + #PS$ + "meta.gif"
	metaend:
	up:
	IncludeBinary "images" + #PS$ + "up.gif"
	upend:
	range:
	IncludeBinary "images" + #PS$ + "range.gif"
	rangeend:
	re:
	IncludeBinary "images" + #PS$ + "re.gif"
	reend:
	ind:
	IncludeBinary "images" + #PS$ + "ind.gif"
	indend:
; 	save:
; 	IncludeBinary "images" + #PS$ + "save.gif"
; 	saveend:
; 	saver:
; 	IncludeBinary "images" + #PS$ + "saver.gif"
; 	saverend:
; 	Icon2:
; 	IncludeBinary "images" + #PS$ + "2.gif"
; 	Icon2end:
; 	Icon3:
; 	IncludeBinary "images" + #PS$ + "3.gif"
; 	Icon3end:
EndDataSection

CompilerIf #PB_Compiler_OS = #PB_OS_Linux
	CatchImage(0, ?IconTitle)
CompilerEndIf
CatchImage(1, ?clear)
CatchImage(2, ?folder)
CatchImage(3, ?add)
CatchImage(4, ?del)
CatchImage(5, ?meta)
CatchImage(6, ?up)
CatchImage(7, ?range)
CatchImage(8, ?re)
CatchImage(9, ?ind)
; CatchImage(4, ?save)
; CatchImage(5, ?saver)


;-┌───GUI───┐
If OpenWindow(#Window, 0, 0, w, h, Lng(6), #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_SizeGadget | #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget)
	CompilerIf #PB_Compiler_OS = #PB_OS_Linux
		gtk_window_set_icon_(WindowID(#Window), ImageID(0)) ; назначаем иконку в заголовке
	CompilerEndIf
	; 	StringGadget(1 , 10, 22, 590, 22 , "")
	WindowBounds(#Window, 670, 500, #PB_Ignore, #PB_Ignore)

	tmp = (w - 320) / 2
	If tmp < 270
		tmp = 270
	EndIf
	TextGadget(#t1, 10, 1,  tmp, 22, Lng(7))
	TextGadget(#t2, 10, 19 + SciHeight, 250, 22, Lng(8))
	TextGadget(#t3, 10, 70 + SciHeight, tmp, 22, Lng(9))
; 	SetGadgetColor(#t1 , #PB_Gadget_BackColor , $ffff00)
	; 	TextGadget(18, 10, 101, 280, 14, "Текст для обработки")
	; 	TextGadget(19, 10, 300, 280, 14, "Результаты обработки")

	Define hSci
	hSci = ScintillaGadget(#SciGadget, 10, 22, w - 320, SciHeight, @SciNotification())

	CompilerIf #PB_Compiler_OS = #PB_OS_Windows
; 	SetWindowLongPtr_(hSci, #GWL_STYLE, GetWindowLongPtr_(hSci, #GWL_STYLE) | #WS_BORDER)
		SetWindowLongPtr_(hSci, #GWL_EXSTYLE, GetWindowLongPtr_(hSci, #GWL_EXSTYLE) ! #WS_EX_CLIENTEDGE)
; 	SetWindowLongPtr_(hSci, #GWL_EXSTYLE, GetWindowLongPtr_(hSci, #GWL_EXSTYLE) | #WS_EX_STATICEDGE)
		SetWindowLongPtr_(hSci, #GWL_EXSTYLE, GetWindowLongPtr_(hSci, #GWL_EXSTYLE) | #WS_EX_WINDOWEDGE)
		SetWindowLongPtr_(hSci, #GWL_STYLE, GetWindowLongPtr_(hSci, #GWL_STYLE) | #WS_BORDER)
	CompilerEndIf
	; Устанавливает режим текста

	*Font = UTF8(SciFont$)
	ScintillaSendMessage(#SciGadget, #SCI_STYLESETFONT, #STYLE_DEFAULT, *Font)
	FreeMemory(*Font)

	ScintillaSendMessage(#SciGadget, #SCI_SETWRAPMODE, #SC_WRAP_NONE) ; без переносов строк
	ScintillaSendMessage(#SciGadget, #SCI_STYLESETSIZE, #STYLE_DEFAULT, SciFontSize) ; размер шрифта
	ScintillaSendMessage(#SciGadget, #SCI_STYLECLEARALL)     ; размер шрифта
; ScintillaSendMessage(#SciGadget, #SCI_STYLESETSIZEFRACTIONAL, #SCI_STYLECLEARALL, 1100) ; размер шрифта
	ScintillaSendMessage(#SciGadget, #SCI_SETCODEPAGE, #SC_CP_UTF8)   ; в кодировке UTF-8
	ScintillaSendMessage(#SciGadget, #SCI_SETCARETSTICKY, 1)    ; делает всегда видимым (?)
	ScintillaSendMessage(#SciGadget, #SCI_SETCARETWIDTH, 1)     ; толщина текстовго курсора
	ScintillaSendMessage(#SciGadget, #SCI_SETCARETFORE, caret) ; цвет текстовго курсора
	ScintillaSendMessage(#SciGadget, #SCI_SETSELALPHA, 100)     ; прозрачность выделения
	ScintillaSendMessage(#SciGadget, #SCI_SETSELBACK, 1, select_bg); цвет фона выделения
	ScintillaSendMessage(#SciGadget, #SCI_SETSELFORE, 1, select_fnt); цвет текста выделения
	ScintillaSendMessage(#SciGadget, #SCI_SETMULTIPLESELECTION, 0)   ; мультивыделение
	ScintillaSendMessage(#SciGadget, #SCI_STYLESETBACK, #STYLE_DEFAULT, background)    ; цвет фона
	ScintillaSendMessage(#SciGadget, #SCI_STYLESETFORE, #STYLE_DEFAULT, color_default)    ; цвет текста
	ScintillaSendMessage(#SciGadget, #SCI_STYLECLEARALL)
; 	ScintillaSendMessage(#SciGadget, #SCI_SETCARETLINEBACK, RGB(0, 0, 0)) ; цвет подсвеченной строки
	ScintillaSendMessage(#SciGadget, #SCI_SETHSCROLLBAR, 0)      ; не показывать горизонтальную прокрутку
	ScintillaSendMessage(#SciGadget, #SCI_SETVSCROLLBAR, 0)      ; не показывать вертикальную прокрутку
	ScintillaSendMessage(#SciGadget, #SCI_SETMARGINWIDTHN, 0, 0)    ; Устанавливает ширину поля 0 (номеров строк)
	ScintillaSendMessage(#SciGadget, #SCI_SETMARGINWIDTHN, 1, 0)	; Устанавливает ширину поля 1 (номеров строк)



; Эти константы будут использоватся для подсветки синтаксиса.
	Enumeration 1
		#LexerState_Repeat
		#LexerState_SquareBrackets
		#LexerState_RoundBrackets
		#LexerState_AnyText
		#LexerState_Meta
		#LexerState_Borders
		#LexerState_ChrH
		#LexerState_RoundBrackets2
; 	#LexerState_Number
; 	#LexerState_Keyword
; 	#LexerState_String
; 	#LexerState_Preprocessor
; 	#LexerState_Operator
; 	#LexerState_Comment
; 	#LexerState_FoldKeyword
	EndEnumeration


;- ├ RegExp highlighting
	AddElement(regex())
	regex()\re = "\{[\d,]+\}"
	regex()\id = #LexerState_Repeat

	AddElement(regex())
	regex()\re = "\.[*+]\??"
	regex()\id = #LexerState_AnyText

	AddElement(regex())
	regex()\re = "\\[fhrntvdswFHRNVDSW][*+]?\??"
	regex()\id = #LexerState_Meta

	AddElement(regex())
	regex()\re = "\\[ABbZzQE]"
	regex()\id = #LexerState_Borders

	AddElement(regex())
	regex()\re = "[$^|]"
	regex()\id = #LexerState_Borders

	AddElement(regex())
	regex()\re = "\\(x\d\d|x\{[0-9A-Fa-f]{2}(?:[0-9A-Fa-f]{2})?\}|\d{3})[*+]?\??"
	regex()\id = #LexerState_ChrH

	AddElement(regex())
	regex()\re = "[\[\]]\+?\??"
	regex()\id = #LexerState_SquareBrackets

	AddElement(regex())
	regex()\re = "\(\?<?[:=!]"
	regex()\id = #LexerState_RoundBrackets

	AddElement(regex())
	regex()\re = "\(\?[smixJU\-]+?:"
	regex()\id = #LexerState_RoundBrackets

	AddElement(regex())
	regex()\re = "[()][+?]?"
	regex()\id = #LexerState_RoundBrackets

	ForEach regex()
		regex()\len = Len(regex()\re)
		regex()\mem = UTF8(regex()\re)
	Next

	Define ColorType

	If typeBF
		ColorType = #SCI_STYLESETBACK
; 	For i = 1 To 7
; 		ScintillaSendMessage(#SciGadget, #SCI_STYLESETFORE, i, 0)
; 	Next
	Else
		ColorType = #SCI_STYLESETFORE
	EndIf
	ScintillaSendMessage(#SciGadget, ColorType, #LexerState_Repeat, re_Repeat) ; {3,4} повтор
	ScintillaSendMessage(#SciGadget, ColorType, #LexerState_SquareBrackets, re_SqBrackets) ; [ ... ] квадратные скобки, классы
	ScintillaSendMessage(#SciGadget, ColorType, #LexerState_RoundBrackets, re_RndBrackets)  ; ( ... ) круглые скобки, флаги
	ScintillaSendMessage(#SciGadget, ColorType, #LexerState_AnyText, re_AnyText)   ; .*? любой текст
	ScintillaSendMessage(#SciGadget, ColorType, #LexerState_Meta, re_Meta)    ; .\w метасимволы
	ScintillaSendMessage(#SciGadget, ColorType, #LexerState_Borders, re_Borders)   ; \A границы
	ScintillaSendMessage(#SciGadget, ColorType, #LexerState_ChrH, re_ChrH)    ; код символа
	ScintillaSendMessage(#SciGadget, ColorType, #LexerState_RoundBrackets2, re_RndBrackets2)  ; ( ... ) круглые скобки, флаги
; ScintillaSendMessage(#SciGadget, #SCI_STYLESETFORE, #LexerState_Comment, $71AE71) ; Цвет комментариев
; ScintillaSendMessage(#SciGadget, #SCI_STYLESETFORE, #LexerState_Number, $ABCEE3)				; Цвет чисел, BGR
; ScintillaSendMessage(#SciGadget, #SCI_STYLESETFORE, #LexerState_Keyword, $FF9F00)			; Цвет ключевых слов, BGR
; ScintillaSendMessage(#SciGadget, #SCI_STYLESETFORE, #LexerState_Operator, $8080FF)			; Цвет препроцессор, BGR
; ScintillaSendMessage(#SciGadget, #SCI_STYLESETFORE, #LexerState_FoldKeyword, RGB(0, 136, 0))	; Цвет ключевых слов со сворачиванием.
; ScintillaSendMessage(#SciGadget, #SCI_STYLESETBOLD, #LexerState_Number, 1)					; Выделять чисел жирным шрифтом
; ScintillaSendMessage(#SciGadget, #SCI_STYLESETITALIC, #LexerState_Comment, 1)				; Выделять комментарии наклонным шрифтом




	StringGadget(#FiedReplace, 10, 42 + SciHeight, w - 290, 28 , "")
	; 	EditorGadget(3, 10, 120, 640, 180)
	; 	SetGadgetText(3 , "Тестовый текст sRE1$, sED3$, sRP2$ , Text$)") ; Тестовый текст, временная вставка
	; 	EditorGadget(4, 10, 321, 640, 180)
	EditorGadget(#Ed_Sourse, 0, 0, 0, 0)
	; 	SetGadgetText(3 , "Тестовый текст sRE1$, sED3$, sRP2$ , Text$)") ; Тестовый текст, временная вставка
	EditorGadget(#Ed_Destination, 0, 0, 0, 0)
	; 	#Splitter
	SplitterGadget(#Splitter, 10, 92 + SciHeight, w - 290, h - 101 - SciHeight, #Ed_Sourse, #Ed_Destination, #PB_Splitter_Separator)

	#Font2 = 0
	If LoadFont(#Font2, Font$, fontsize)
		SetGadgetFont(#Ed_Sourse, FontID(#Font2))
		SetGadgetFont(#Ed_Destination, FontID(#Font2))
		SetGadgetFont(#FiedReplace, FontID(#Font2))
	EndIf

	ListViewGadget(#LV, w - 230, 155, 220, h - 405)

;- ├ Buttons
	ButtonImageGadget(#btnOpen, w - 270, 120, 30, 30, ImageID(2))
	GadgetToolTip(#btnOpen, Lng(10))
	ButtonImageGadget(#btnClear, w - 270, 155, 30, 30, ImageID(1))
	GadgetToolTip(#btnClear, Lng(11))
	ButtonImageGadget(#btnAddToLib, w - 270, 190, 30, 30, ImageID(3))
	GadgetToolTip(#btnAddToLib, Lng(12))
	ButtonImageGadget(#btnDel, w - 270, 225, 30, 30, ImageID(4))
	GadgetToolTip(#btnDel, Lng(13))
	ButtonImageGadget(#btnMeta, w - 270, 260, 30, 30, ImageID(5))
	GadgetToolTip(#btnMeta, Lng(14))
	ButtonImageGadget(#btnUp, w - 270, 295, 30, 30, ImageID(6))
	GadgetToolTip(#btnUp, Lng(15))
	ButtonImageGadget(#btnRange, w - 270, 330, 30, 30, ImageID(7))
	GadgetToolTip(#btnRange, Lng(16))

	HyperLinkGadget(#HL_help, w - 80, h - 110, 80, 30, Lng(17), RGB(0, 155, 255), #PB_HyperLink_Underline)
	GadgetToolTip(#HL_help, "F1")

	ButtonGadget(#btnStart, w - 270, h - 110, 110, 45, Lng(18))
	GadgetToolTip(#btnStart, "F5")
	ButtonGadget(#btnCopy, w - 150, h - 110, 60, 28, "Copy")
	ButtonGadget(#btnLib, w - 230, 120, 90, 28, "")

	ButtonGadget(#btnMenu, w - 308, 21, 28, 28, Chr($25BC))

;- ├ Menu
	If CreatePopupMenu(#MetaMenu)
		mn1 = -1

		If FileSize(iniMenu$) > -1 And OpenPreferences(iniMenu$)
			; 			OpenSubMenu("семплы")
			ExaminePreferenceGroups()
			While NextPreferenceGroup() ; Пока находит группы
										; 				MessageRequester("Groups", PreferenceGroupName()) ; Отображает группу
										; 				MenuItem(mn1, PreferenceGroupName())
				OpenSubMenu(PreferenceGroupName())
				ExaminePreferenceKeys()
				While NextPreferenceKey()
					mn1 + 1
					MenuItem(mn1, PreferenceKeyValue())
				Wend
				CloseSubMenu()
			Wend
			; 			CloseSubMenu()
			; 			If PreferenceGroup("regexp")
			; 				ExaminePreferenceKeys()
			; 				While NextPreferenceKey()
			; 					mn1 + 1
			; 					MenuItem(mn1, PreferenceKeyValue())
			; 				Wend
			; 			EndIf
			ClosePreferences()
		EndIf

		mn2 = mn1
		FindLIbFile()
		mn3 = mn1
		If CreatePopupMenu(#HotMenu)
			mn1 + 1
			MenuItem(mn1, Lng(18) + #TAB$ + "Ctr + Enter")
			mn1 + 1
			MenuItem(mn1, Lng(17) + #TAB$ + "F1")
			CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
				mn1 + 1
				MenuItem(mn1, "Exit" + #TAB$ + "Cmd + Q")
			CompilerEndIf
		EndIf

		mn4 = mn1

;- ├ Menu Recent
		i = 0
		If CreatePopupMenu(#HistoryMenu)
			If isINI And OpenPreferences(ini$)
				If PreferenceGroup("regexp")
					; 				mn1 = -1
					ExaminePreferenceKeys()
					While NextPreferenceKey()
						If Not Asc(PreferenceKeyValue()) ; пропускает (игнорирует) пустые значения
							Continue
						EndIf
						If AddElement(RecentUsed())
							mn1 + 1
							; TODO использовать регвыр для поиска и замены
							If FindString(PreferenceKeyValue(), "}—•—{")
								RecentUsed() = ReplaceString(PreferenceKeyValue(), "}—•—{", #CRLF$)
							Else
								RecentUsed() = PreferenceKeyValue()
							EndIf
							i + 1
							If i > maxhistor
								Break
							EndIf
; 							MenuItem(mn1, PreferenceKeyValue())
						EndIf
					Wend
				EndIf

				ClosePreferences()
			EndIf
		EndIf
		; 		MenuBar()
	EndIf
; 	задаток для истории
; 	mn1 + 50

;- ├ CheckBox
	tmp = (w - 320) / 2
	If tmp < 280
		tmp = 280
	EndIf
	CompilerSelect #PB_Compiler_OS
		CompilerCase #PB_OS_Windows
			CheckBoxGadget(#Ch_OnTop, tmp, 2, 120, 20, Lng(19))
		CompilerCase #PB_OS_Linux
			CheckBoxGadget(#Ch_OnTop, tmp, 0, 120, 20, Lng(19))
	CompilerEndSelect
	If topmost
		StickyWindow(#Window, #True)
		SetGadgetState(#Ch_OnTop, #PB_Checkbox_Checked)
	EndIf
	CheckBoxGadget(#Ch_NotUpd, tmp, 70 + SciHeight, 120, 20, Lng(20))
	GadgetToolTip(#Ch_NotUpd, Lng(21))



	CheckBoxGadget(#Ch_s, w - 270, 10, 250, 20, Lng(22))
	CheckBoxGadget(#Ch_x, w - 270, 30, 250, 20, Lng(23))
	CheckBoxGadget(#Ch_m, w - 270, 50, 250, 20, Lng(24))
	CheckBoxGadget(#Ch_CRLF, w - 270, 70, 250, 20, Lng(25))
	CheckBoxGadget(#Ch_i, w - 270, 90, 250, 20, Lng(26))
	SetGadgetState(#Ch_s, 1)
	SetGadgetState(#Ch_CRLF, 1)
	SetGadgetState(#Ch_i, 1)
	GadgetToolTip(#Ch_s, Lng(27))
	GadgetToolTip(#Ch_CRLF, Lng(28))



	OptionGadget(#Opt_Search, w - 190, h - 240, 190, 20, Lng(29))
	OptionGadget(#Opt_Replace, w - 190, h - 220, 190, 20, Lng(30))
	OptionGadget(#Opt_Array, w - 190, h - 200, 190, 20, Lng(31))
	OptionGadget(#Opt_Group, w - 190, h - 180, 190, 20, Lng(32))
	OptionGadget(#Opt_Step, w - 190, h - 160, 190, 20, Lng(33))
	SetGadgetState(#Opt_Array, 1)
	GadgetToolTip(#Opt_Search, Lng(34))
	GadgetToolTip(#Opt_Replace, Lng(35))
	GadgetToolTip(#Opt_Array, Lng(36))
	GadgetToolTip(#Opt_Group, Lng(37))
	GadgetToolTip(#Opt_Step, Lng(38))



	CheckBoxGadget(#Ch_Esc, w - 230, h - 220, 20, 20, "")
	GadgetToolTip(#Ch_Esc, "\r \n \t")
	CheckBoxGadget(#Ch_reg2, w - 210, h - 220, 20, 20, "")
	GadgetToolTip(#Ch_reg2, Lng(39))

	CheckBoxGadget(#Ch_markup, w - 210, h - 140, 220, 20, Lng(40))
	GadgetToolTip(#Ch_markup, Lng(41))


	TextGadget(#TimeOld, w - 270, h - 54, 265, 22, "", #PB_Text_Border)
	TextGadget(#TimeNew, w - 270, h - 32, 265, 22, "time, sec", #PB_Text_Border)

	CompilerIf #PB_Compiler_OS = #PB_OS_Windows
		If ColorGui
			SetWindowColor(#Window, ColorGui)
; 			For i = 0 To 12
			For i = #Opt_Search To #Ch_NotUpd
				If ColorGadgetFont
					CheckOptionColor(i, ColorGui, ColorGadgetFont)
				Else
					CheckOptionColor(i, ColorGui, #PB_Default)
				EndIf
			Next
; 			For i = 13 To 16
			For i = #HL_help To #t3
				SetGadgetColor(i, #PB_Gadget_BackColor, ColorGui)
			Next
		EndIf
		If ColorGadget
; 			For i = 17 To 23
			For i = #FiedReplace To #Splitter
				SetGadgetColor(i, #PB_Gadget_BackColor, ColorGadget)
			Next
		EndIf
		If ColorGadgetFont
; 			For i = 13 To 22
			For i = #HL_help To #TimeNew
				SetGadgetColor(i, #PB_Gadget_FrontColor, ColorGadgetFont)
			Next
		EndIf
	CompilerEndIf

	CompilerIf #PB_Compiler_OS = #PB_OS_Windows
		SetWindowCallback(@MainWindow_Callback(), #Window)
	CompilerEndIf


	EnableGadgetDrop(#Ed_Sourse, #PB_Drop_Files, #PB_Drag_Copy)

	AddKeyboardShortcut(#Window, #PB_Shortcut_Control | #PB_Shortcut_Return , mn3 + 1) ; Start
	AddKeyboardShortcut(#Window, #PB_Shortcut_F5 , mn3 + 1) ; Start
	AddKeyboardShortcut(#Window, #PB_Shortcut_F1 , mn3 + 2) ; Help

	CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
		AddKeyboardShortcut(#Window, #PB_Shortcut_Command | #PB_Shortcut_Q , mn3 + 2) ; Exit
	CompilerEndIf

	SetProgParam()

	BindEvent(#PB_Event_SizeWindow, @SizeWindow(), #Window)

;-┌───Loop───┐
	Repeat
		Select WaitWindowEvent()
			Case #PB_Event_GadgetDrop ; событие перетаскивания
				Select EventGadget()
					Case #Ed_Sourse
						ReadFileToEdit(EventDropFiles())
				EndSelect
			Case #PB_Event_RightClick
				DisplayPopupMenu(#HotMenu, WindowID(#Window))  ; покажем всплывающее Меню
;-├ Menu events
			Case #PB_Event_Menu
				eMenu = EventMenu()
				If eMenu > mn4
; меню истории
					*mem = UTF8(GetMenuItemText(#HistoryMenu, eMenu))
					ScintillaSendMessage(#SciGadget, #SCI_SETTEXT, 0, *mem) ; Установить текст гаджета
					FreeMemory(*mem)
					; прокручиваем -500 по горизонтали и -50 по вертикали, чтобы показать начало вставленного регвыра
					ScintillaSendMessage(#SciGadget, #SCI_LINESCROLL, -200, -50)
				ElseIf eMenu > mn3
					Select eMenu - mn3
						Case 1
							StartRE()
						Case 2
							CompilerSelect #PB_Compiler_OS
								CompilerCase #PB_OS_Windows
									tmp$ = GetPathPart(ProgramFilename()) + "RegExp.chm"
									If FileSize(tmp$) > 0
										RunProgram("hh.exe", #q$ + tmp$ + "::/html/RegExp.htm" + #q$, "")
									EndIf
								CompilerCase #PB_OS_Linux
									tmp$ = "/usr/share/help/ru/regexppb/regexp.html"
									If FileSize(tmp$) > 0
										RunProgram("xdg-open", tmp$, GetPathPart(tmp$))
									EndIf
							CompilerEndSelect
							StartRE()
							CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
							Case 3
								ExitProg()
							CompilerEndIf
					EndSelect
				ElseIf eMenu > mn2
							; меню библиотек
					Cur_idx = -2
					sResult$ = GetMenuItemText(#LibMenu , eMenu)
					SetSample(sResult$)
				Else
							; меню метасимволов
					*mem = UTF8(GetMenuItemText(#MetaMenu, eMenu))
					ScintillaSendMessage(#SciGadget, #SCI_REPLACESEL, 0, *mem) ; Заменить текст гаджета
					FreeMemory(*mem)
				EndIf
;-├ Gadget Events
			Case #PB_Event_Gadget
				Select EventGadget()
						CompilerIf #PB_Compiler_OS = #PB_OS_Windows
						Case #cmbSq
							If flgSelChange = 1
								flgSelChange = 0
								tmp$ = GetGadgetText(#cmbSq)
								If Asc(tmp$)
									SetExeRegExpToLV(tmp$)
								EndIf
							EndIf
						CompilerEndIf
					Case #btnUpdRng;, #cmbSq
						tmp$ = GetGadgetText(#cmbSq)
						If Asc(tmp$)
							SetExeRegExpToLV(tmp$)
						EndIf
					Case #LV
						If EventType() = #PB_EventType_LeftClick
							Fill_fields()
						EndIf
					Case #btnDel
						DeleteElemLib()
					Case #btnAddToLib
						AddToLib()
					Case #btnClear
						SetGadgetText(#Ed_Destination, "")
						SetGadgetText(#Ed_Sourse, "")
						SetGadgetText(#FiedReplace, "")
						ScintillaSendMessage(#SciGadget, #SCI_CLEARALL)
					Case #btnOpen
						sResult$ = OpenFileRequester("", GetCurrentDirectory(), "", 0)
						If Asc(sResult$)
							ReadFileToEdit(sResult$)
						EndIf
					Case #btnUp
						SetGadgetText(#Ed_Sourse, GetGadgetText(#Ed_Destination))
					Case #btnRange
						TestRange()
					Case #btnMeta
						DisplayPopupMenu(#MetaMenu, WindowID(#Window))  ; покажем всплывающее Меню
					Case #btnLib
						DisplayPopupMenu(#LibMenu, WindowID(#Window))  ; покажем всплывающее Меню
					Case #btnMenu
						; 						DisplayPopupMenu(#HistoryMenu, WindowID(#Window))  ; покажем всплывающее Меню
						If IsMenu(#HistoryMenu)
							FreeMenu(#HistoryMenu)
						EndIf
						If CreatePopupMenu(#HistoryMenu)
							i = mn4
							ForEach RecentUsed()
								i + 1
								MenuItem(i, RecentUsed())
							Next
						EndIf
						DisplayPopupMenu(#HistoryMenu, WindowID(#Window), WindowX(#Window, #PB_Window_InnerCoordinate) + 10, WindowY(#Window, #PB_Window_InnerCoordinate) + 50)

					Case #Ch_OnTop
						If GetGadgetState(#Ch_OnTop) & #PB_Checkbox_Checked
							StickyWindow(#Window , #True)
						Else
							StickyWindow(#Window , #False)
						EndIf
					Case #HL_help
						CompilerSelect #PB_Compiler_OS
							CompilerCase #PB_OS_Windows
								RunProgram("http://forum.ru-board.com/topic.cgi?forum=33&topic=0472&start=0&limit=1&m=2#1")
							CompilerCase #PB_OS_Linux
								RunProgram("xdg-open", "http://forum.ru-board.com/topic.cgi?forum=33&topic=0472&start=0&limit=1&m=2#1", "")
						CompilerEndSelect

					Case #btnCopy
						CopyCode2Clipboard()

					Case #btnStart
						StartRE()
				EndSelect
			Case #PB_Event_CloseWindow
				If EventWindow() = #WinRange
					CloseWindow(#WinRange)
				Else
					; 				CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
					; 				CompilerEndIf
					ExitProg()
				EndIf
		EndSelect
	ForEver
;-└───Loop───┘

EndIf

Procedure StartRE()
	Protected FlagsRE, Label, SciText$, TimeStart.q, TimeDiff.q
	Protected Text.string

	ClearGadgetItems(#Ed_Destination) ; SetGadgetText иногда не заменяет текст, пришлось очищать
	FlagsRE = 0
	If GetGadgetState(#Ch_s)
		FlagsRE | #PB_RegularExpression_DotAll
	EndIf
	If GetGadgetState(#Ch_x)
		FlagsRE | #PB_RegularExpression_Extended
	EndIf
	If GetGadgetState(#Ch_m)
		FlagsRE | #PB_RegularExpression_MultiLine
	EndIf
	If GetGadgetState(#Ch_CRLF)
		FlagsRE | #PB_RegularExpression_AnyNewLine
	EndIf
	If GetGadgetState(#Ch_i)
		FlagsRE | #PB_RegularExpression_NoCase
	EndIf
	Label = 0
	If GetGadgetState(#Ch_markup)
		Label = 1
	EndIf
	Text\s = GetGadgetText(#Ed_Sourse)
	SciText$ = GetScintillaGadgetText()
	If Not Asc(Text\s) Or Not Asc(SciText$)
		SetGadgetText(#Ed_Destination, Lng(42))
		ProcedureReturn
	EndIf
	AddLast() ; добавление пункта истории

	CompilerSelect #PB_Compiler_OS
		CompilerCase #PB_OS_Windows
			QueryPerformanceCounter_(@TimeStart)
		CompilerCase #PB_OS_Linux
			TimeStart = ElapsedMilliseconds()
	CompilerEndSelect

	; 						Delay(3000) ; тест что нет ошибки в рассчётах, выдаёт 3 секунды
	Select 1
		Case GetGadgetState(#Opt_Search)
			SciText$ = SearchRE(SciText$, @Text, FlagsRE)
			SetGadgetText(#Ed_Destination, SciText$)
		Case GetGadgetState(#Opt_Replace)
			SciText$ = ReplaceRE(SciText$, @Text, GetGadgetText(#FiedReplace), FlagsRE)
			SetGadgetText(#Ed_Destination, SciText$)
		Case GetGadgetState(#Opt_Array)
			SciText$ = ExtractRE(SciText$, @Text, FlagsRE, Label)
			SetGadgetText(#Ed_Destination, SciText$)
		Case GetGadgetState(#Opt_Group)
			SciText$ = GroupsRE(SciText$, @Text, FlagsRE, Label)
			SetGadgetText(#Ed_Destination, SciText$)
		Case GetGadgetState(#Opt_Step)
			SciText$ = StepRE(SciText$, @Text, FlagsRE, Label)
			SetGadgetText(#Ed_Destination, SciText$)
	EndSelect

	CompilerSelect #PB_Compiler_OS
		CompilerCase #PB_OS_Windows
			QueryPerformanceCounter_(@TimeDiff)
			TimeDiff = (TimeDiff - TimeStart)
			SetGadgetText(#TimeOld, StrD(TimeOldDiff / 10000000.0, 4))
			SetGadgetText(#TimeNew, StrD(TimeDiff / 10000000.0, 4))
		CompilerCase #PB_OS_Linux
			TimeDiff = ElapsedMilliseconds()
			; 								Debug TimeStart
			; 								Debug TimeDiff
			TimeDiff = TimeDiff - TimeStart
			SetGadgetText(#TimeOld, StrF(TimeOldDiff / 1000.0, 4))
			SetGadgetText(#TimeNew, StrF(TimeDiff / 1000.0, 4))
	CompilerEndSelect
	If TimeDiff > TimeOldDiff
		SetGadgetColor(#TimeNew , #PB_Gadget_BackColor, clrTime1) ; красный
	Else
		SetGadgetColor(#TimeNew , #PB_Gadget_BackColor, clrTime2) ; зелёный
	EndIf
	TimeOldDiff = TimeDiff

	FreeRegularExpression(#PB_All)
	Text\s = ""
	SciText$ = ""
EndProcedure

Procedure AddLast()
	Protected tmp$
	tmp$ = GetScintillaGadgetText()
	ForEach RecentUsed()
		If tmp$ = RecentUsed()
			MoveElement(RecentUsed(), #PB_List_First)
			ProcedureReturn
		EndIf
		If Not Asc(RecentUsed())
			DeleteElement(RecentUsed())
		EndIf
	Next
	SelectElement(RecentUsed(), 0)
	If InsertElement(RecentUsed())
		RecentUsed() = tmp$
	EndIf
	While ListSize(RecentUsed()) > maxhistor ; the maximum number of items in the menu
		LastElement(RecentUsed())
		DeleteElement(RecentUsed())
	Wend
; 	MenuMax = ListSize(RecentUsed()) - 1
EndProcedure

; Чтение файла в гаджет
Procedure ReadFileToEdit(FilePath$)
	Protected text$, Format, oFile
	oFile = ReadFile(#PB_Any, FilePath$)
	If oFile
		Format = ReadStringFormat(oFile)
;		Text$ = ReadString(oFile, Format | #PB_File_IgnoreEOL)
		Text$ = ReadString(oFile, #PB_UTF8 | #PB_File_IgnoreEOL)
		CloseFile(oFile)
		If Asc(Text$)
			SetGadgetText(#Ed_Sourse , Text$)
		EndIf
	EndIf

EndProcedure


; Получить код из шаблона с вставкой элементов и отправкой в буфер обмена
Procedure CopyCode2Clipboard()
	Protected Code$, FlagsTRE$, RegExp$, Replace$, hFile, FileName$, Format, File$
	FlagsTRE$ = ""
	If GetGadgetState(#Ch_s)
		FlagsTRE$ + "#PB_RegularExpression_DotAll | "
	EndIf
	If GetGadgetState(#Ch_x)
		FlagsTRE$ + "#PB_RegularExpression_Extended | "
	EndIf
	If GetGadgetState(#Ch_m)
		FlagsTRE$ + "#PB_RegularExpression_MultiLine | "
	EndIf
	If GetGadgetState(#Ch_CRLF)
		FlagsTRE$ + "#PB_RegularExpression_AnyNewLine | "
	EndIf
	If GetGadgetState(#Ch_i)
		FlagsTRE$ + "#PB_RegularExpression_NoCase | "
	EndIf
	If Asc(FlagsTRE$)
		FlagsTRE$ = LSet(FlagsTRE$, Len(FlagsTRE$) - 3)
	Else
		FlagsTRE$ = "0"
	EndIf
	; 	Text\s = GetGadgetText(#Ed_Sourse)
	RegExp$ = GetScintillaGadgetText()
	If Not Asc(RegExp$)
		SetGadgetText(#Ed_Destination, Lng(42))
		ProcedureReturn
	EndIf

	Select 1
		Case GetGadgetState(#Opt_Search)
			FileName$ = "Search"
		Case GetGadgetState(#Opt_Replace)
			FileName$ = "Replace"
			Replace$ = GetGadgetText(#FiedReplace)
		Case GetGadgetState(#Opt_Array)
			FileName$ = "Array"
		Case GetGadgetState(#Opt_Group)
			FileName$ = "Groups"
		Case GetGadgetState(#Opt_Step)
			FileName$ = "Step"
	EndSelect
	If copysel
		File$ = OpenFileRequester("", PathConfig$ + "template" + #PS$, "Code|*.pb*;*.cpp;*.c;*.py;*.h;*.inc;*.au3;*.pnp|All|*.*", 1)
		If Not Asc(File$)
			ProcedureReturn
		EndIf
	Else
		File$ = PathConfig$ + "template" + #PS$ + FileName$ + ".pb"
	EndIf
; 	Debug File$
	hFile = ReadFile(#PB_Any, File$)
	If hFile
		Format = ReadStringFormat(hFile)
		Code$ = ReadString(hFile, Format | #PB_File_IgnoreEOL)
		CloseFile(hFile)
		If Asc(Code$)
			Code$ = ReplaceString(Code$, "%regexp%", RegExp$)
			Code$ = ReplaceString(Code$, "%flags%", FlagsTRE$)
			; 			If Asc(Replace$)
			Code$ = ReplaceString(Code$, "%replace%", Replace$)
			; 			EndIf
			SetClipboardText(Code$)
			MessageRequester("", Lng(53))
		Else
			MessageRequester("", Lng(43))
		EndIf
	EndIf
EndProcedure

; Получить текст из Scintilla
Procedure.s GetScintillaGadgetText()
	Protected txtLen, *mem, text$
	txtLen = ScintillaSendMessage(#SciGadget, #SCI_GETLENGTH)          ; получает длину текста в байтах
	*mem = AllocateMemory(txtLen + 2)                 ; Выделяем память на длину текста и 1 символ на Null
	If *mem                       ; Если указатель получен, то
		ScintillaSendMessage(#SciGadget, #SCI_GETTEXT, txtLen + 1, *mem)        ; получает текста
		text$ = PeekS(*mem, -1, #PB_UTF8)               ; Считываем значение из области памяти
		FreeMemory(*mem)
		ProcedureReturn text$
	EndIf
	ProcedureReturn ""
EndProcedure

Procedure Brackets(*c.Character, Array ArrBrackets(2))
	Protected Pos = -1, Open, slash
	Protected NewList Stack()
	If *c = 0 Or *c\c = 0
		ProcedureReturn 0
	EndIf

	While *c\c
		Pos + 1
		Select *c\c
			Case '\'
				slash + 1
				If slash = 2
					slash = 0
				EndIf
			Case '('
				If slash
					*c + SizeOf(Character)
					slash = 0
					Continue
				EndIf
				Open + 1
				AddElement(Stack())
				Stack() = Open
				ReDim ArrBrackets(1, Open)
				ArrBrackets(0, Open) = Pos
				slash = 0
			Case ')'
				If slash
					*c + SizeOf(Character)
					slash = 0
					Continue
				EndIf
				If ListSize(Stack())
					ArrBrackets(1, Stack()) = Pos
					DeleteElement(Stack())
; 				Else
; 					Debug "Opening brackets are missing"
				EndIf
				slash = 0
			Default
				slash = 0
		EndSelect
		*c + SizeOf(Character)
	Wend

; 	If ListSize(Stack())
; 		Debug "Closing brackets are missing"
; 	EndIf
EndProcedure


; Подсвечивание через стиль
Procedure Color(*regex, regexLength, style_id)
	Protected txtLen, StartPos, EndPos, firstMatchPos

	; Устанавливает режим поиска (REGEX + POSIX фигурные скобки)
	ScintillaSendMessage(#SciGadget, #SCI_SETSEARCHFLAGS, #SCFIND_REGEXP | #SCFIND_POSIX)
; 	ScintillaSendMessage(#SciGadget, #SCI_SETSEARCHFLAGS, #SCFIND_REGEXP | #SCFIND_CXX11REGEX)

	; Устанавливает целевой диапазон поиска
	txtLen = ScintillaSendMessage(#SciGadget, #SCI_GETTEXTLENGTH) ; получает длину текста

	EndPos = 0
	Repeat
		ScintillaSendMessage(#SciGadget, #SCI_SETTARGETSTART, EndPos)    ; от начала (задаём область поиска) используя позицию конца предыдущего поиска
		ScintillaSendMessage(#SciGadget, #SCI_SETTARGETEND, txtLen)     ; до конца по длине текста
		firstMatchPos = ScintillaSendMessage(#SciGadget, #SCI_SEARCHINTARGET, regexLength, *regex) ; возвращает позицию первого найденного. В параметрах длина искомого и указатель
; 		Debug firstMatchPos
		If firstMatchPos > -1                   ; если больше -1, то есть найдено, то
			StartPos = ScintillaSendMessage(#SciGadget, #SCI_GETTARGETSTART)       ; получает позицию начала найденного
			EndPos = ScintillaSendMessage(#SciGadget, #SCI_GETTARGETEND)        ; получает позицию конца найденного
			ScintillaSendMessage(#SciGadget, #SCI_STARTSTYLING, StartPos, 0)      ; позиция начала (с 50-го)
			ScintillaSendMessage(#SciGadget, #SCI_SETSTYLING, EndPos - StartPos, style_id)     ; ширина и номер стиля
		Else
			Break
		EndIf
	ForEver
EndProcedure

; ; Подсвечивание через стиль
; Procedure Color(style_id)
; 	Protected txtLen, StartPos, EndPos, firstMatchPos

; 	ForEver
; EndProcedure




; Уведомления
ProcedureDLL SciNotification(Gadget, *scinotify.SCNotification)
	Protected regex$, *mem
	Protected Text$, i, Toggle;, id_style
	Protected Dim ArrBr(1, 0)
	; 	Select Gadget
	; 		Case 0 ; уведомление гаджету 0 (Scintilla)
	With *scinotify
		Select \nmhdr\code
			Case #SCN_STYLENEEDED ; нужна стилизация
; 				Debug 1 проверка, что после клика не идут события досящие гаджет подсветкой
				ForEach regex()
					Color(regex()\mem, regex()\len, regex()\id)
				Next
				Text$ = GetScintillaGadgetText()
				Brackets(@Text$, ArrBr())
				For i = 1 To ArraySize(ArrBr(), 2)
					If Toggle
; 						id_style = #LexerState_RoundBrackets2
						ScintillaSendMessage(#SciGadget, #SCI_STARTSTYLING, ArrBr(0, i), 0)
						ScintillaSendMessage(#SciGadget, #SCI_SETSTYLING, 1, #LexerState_RoundBrackets2)
						ScintillaSendMessage(#SciGadget, #SCI_STARTSTYLING, ArrBr(1, i), 0)
						ScintillaSendMessage(#SciGadget, #SCI_SETSTYLING, 1, #LexerState_RoundBrackets2)
; 					Else
; 						id_style = #LexerState_RoundBrackets
					EndIf
					Toggle = 1 - Toggle
				Next
				; подкраска, чтобы прекратить досить подсветкой каждую секунду
				ScintillaSendMessage(Gadget, #SCI_STARTSTYLING, 2147483646, 0) ; позиция больше документа
				ScintillaSendMessage(Gadget, #SCI_SETSTYLING, 0, 0)			  ; ширина и номер стиля
		EndSelect
	EndWith
	; 	EndSelect
EndProcedure


Procedure SetSample(File$)
	Protected File, regex_id, Text$
	File = ReadFile(#PB_Any, PathConfig$ + "Library" + #PS$ + File$ + ".ini")
	If File
		Text$ = ReadString(File, #PB_UTF8 | #PB_File_IgnoreEOL)
		CloseFile(File)

		regex_id = CreateRegularExpression(#PB_Any, "(?s)(?<=\[z--z\]\r\n)([^\r\n]+?)(?=[\r\n])")
		If regex_id
			If ExamineRegularExpression(regex_id, Text$)
				ClearGadgetItems(#LV)
				While NextRegularExpressionMatch(regex_id)
	; 				Debug RegularExpressionMatchString(regex_id)
					AddGadgetItem(#LV , -1, RegularExpressionMatchString(regex_id))
				Wend
				SetGadgetText(#btnLib , File$)
			EndIf
			FreeRegularExpression(regex_id)
		EndIf
	EndIf
EndProcedure

Procedure FindLIbFile()
	Protected hFind, namelib$, CurFile$ = PathConfig$ + "Library" + #PS$, FindSel$ = "", first
	hFind = ExamineDirectory(#PB_Any, CurFile$, "*.ini")
	If hFind And CreatePopupMenu(#LibMenu)
		first = mn1 + 1
		While NextDirectoryEntry(hFind)
			If DirectoryEntryType(hFind) = #PB_DirectoryEntry_File
				mn1 + 1
				; 				MenuItem(mn1, DirectoryEntryName(hFind))
				namelib$ = GetFilePart(DirectoryEntryName(hFind), #PB_FileSystem_NoExtension)
				MenuItem(mn1, namelib$)
; 				запомнить первую библиотеку, если нет сохранённого выбора
				If first = mn1
					FindSel$ = namelib$
				EndIf
; 				Если есть последняя сохранённая, то выбираем её
				If namelib$ = lastlib$
					FindSel$ = namelib$
				EndIf
			EndIf
		Wend
		FinishDirectory(hFind)

		If Asc(FindSel$)
			SetSample(FindSel$)
		EndIf

	EndIf
EndProcedure

Procedure Fill_fields()
	Protected idx, sResult$, regex_id, *mem, Text$, File, File$, OptCh, rep$, regex_id2
	 ; Проблема в Linux срабатывает дважды
	idx = GetGadgetState(#LV)
	If idx <> -1
		sResult$ = GetGadgetItemText(#LV, idx)
		If Cur_idx = idx
			ProcedureReturn
		EndIf
		Cur_idx = idx

		File$ = GetGadgetText(#btnLib)
		File = ReadFile(#PB_Any, PathConfig$ + "Library" + #PS$ + File$ + ".ini")
		If File
			Text$ = ReadString(File, #PB_UTF8 | #PB_File_IgnoreEOL)
			CloseFile(File)
		EndIf

		regex_id = CreateRegularExpression(#PB_Any, "\[z--z\]\r\n\Q" + sResult$ + "\E\r\n([^\r\n]+?)\r\n([^\r\n]*?)\r\n([^\r\n]+?)\r\n(.*?)\r\n\[z--z\]", #PB_RegularExpression_DotAll)
		If regex_id
			; 			Groups = CountRegularExpressionGroups(regex_id)
			If ExamineRegularExpression(regex_id, Text$)
				If NextRegularExpressionMatch(regex_id)
					*mem = UTF8(RegularExpressionGroup(regex_id, 1))
					ScintillaSendMessage(#SciGadget, #SCI_SETTEXT, 0, *mem) ; Установить текст гаджета
					FreeMemory(*mem)
					; 					ScintillaSendMessage(#SciGadget, #SCI_SETFIRSTVISIBLELINE, 0) ; сделать видимой первую строку
					; прокручиваем -500 по горизонтали и -50 по вертикали, чтобы показать начало вставленного регвыра
					ScintillaSendMessage(#SciGadget, #SCI_LINESCROLL, -200, -50)


					If Not GetGadgetState(#Ch_NotUpd)
						SetGadgetText(#Ed_Sourse, RegularExpressionGroup(regex_id, 4))
					EndIf

					rep$ = RegularExpressionGroup(regex_id, 2)

					SetGadgetText(#FiedReplace, rep$)
					OptCh = Val(RegularExpressionGroup(regex_id, 3))

					; 	Принудительно включаем поддержку групп, если есть ссылки на группы, а поддержка не включена.
					; 	CreateRegularExpression(1, "(?<!\\)\\\d")
					regex_id2 = CreateRegularExpression(#PB_Any, "\\\d")
					If MatchRegularExpression(regex_id2 , rep$)
						OptCh | 1024
					EndIf
					FreeRegularExpression(regex_id2)

					If OptCh & 32
						SetGadgetState(#Opt_Search , 1)
					ElseIf OptCh & 64
						SetGadgetState(#Opt_Replace , 1)
					ElseIf OptCh & 128
						SetGadgetState(#Opt_Array , 1)
					ElseIf OptCh & 256
						SetGadgetState(#Opt_Group , 1)
					ElseIf OptCh & 512
						SetGadgetState(#Opt_Step , 1)
					EndIf

					If OptCh & 1024
						SetGadgetState(#Ch_reg2 , 1)
					Else
						SetGadgetState(#Ch_reg2 , 0)
					EndIf

					If OptCh & 2048
						SetGadgetState(#Ch_markup , 1)
					Else
						SetGadgetState(#Ch_markup , 0)
					EndIf

					If OptCh & 4096
						SetGadgetState(#Ch_Esc , 1)
					Else
						SetGadgetState(#Ch_Esc , 0)
					EndIf

					If OptCh & #PB_RegularExpression_DotAll
						SetGadgetState(#Ch_s , 1)
					Else
						SetGadgetState(#Ch_s , 0)
					EndIf

					If OptCh & #PB_RegularExpression_Extended
						SetGadgetState(#Ch_x , 1)
					Else
						SetGadgetState(#Ch_x , 0)
					EndIf

					If OptCh & #PB_RegularExpression_MultiLine
						SetGadgetState(#Ch_m , 1)
					Else
						SetGadgetState(#Ch_m , 0)
					EndIf

					If OptCh & #PB_RegularExpression_AnyNewLine
						SetGadgetState(#Ch_CRLF , 1)
					Else
						SetGadgetState(#Ch_CRLF , 0)
					EndIf

					If OptCh & #PB_RegularExpression_NoCase
						SetGadgetState(#Ch_i , 1)
					Else
						SetGadgetState(#Ch_i , 0)
					EndIf

				EndIf
			EndIf
			FreeRegularExpression(regex_id)
		Else
			Debug RegularExpressionError()
		EndIf
	EndIf
EndProcedure

Procedure AddToLib()
	Protected tmp$, file_id, File$, field1$, field2$, field3$, i, OptCh, idx, Count, flgFind = 0, Text$, Replace$, RegExp_id
	idx = GetGadgetState(#LV)
	If idx <> -1
		tmp$ = GetGadgetItemText(#LV, idx)
	EndIf
	tmp$ = InputRequester(Lng(44), Lng(45), tmp$)
	If Asc(tmp$)
		; flag =

		Count = CountGadgetItems(#LV)
		For i = 0 To Count - 1
			If GetGadgetItemText(#LV, i) = tmp$
				flgFind = 1
				Break
			EndIf
		Next

		For i = #Opt_Search To #Opt_Step
			If GetGadgetState(i) & #PB_Checkbox_Checked
				Select i - #Opt_Search + 1
					Case 1
						OptCh | 32
					Case 2
						OptCh | 64
					Case 3
						OptCh | 128
					Case 4
						OptCh | 256
					Case 5
						OptCh | 512
				EndSelect
				Break
			EndIf
		Next

		If GetGadgetState(#Ch_reg2) & #PB_Checkbox_Checked
			OptCh | 1024
		EndIf

		If GetGadgetState(#Ch_markup) & #PB_Checkbox_Checked
			OptCh | 2048
		EndIf

		If GetGadgetState(#Ch_Esc) & #PB_Checkbox_Checked
			OptCh | 4096
		EndIf

		If GetGadgetState(#Ch_s) & #PB_Checkbox_Checked
			OptCh | #PB_RegularExpression_DotAll
		EndIf

		If GetGadgetState(#Ch_x) & #PB_Checkbox_Checked
			OptCh | #PB_RegularExpression_Extended
		EndIf

		If GetGadgetState(#Ch_m) & #PB_Checkbox_Checked
			OptCh | #PB_RegularExpression_MultiLine
		EndIf

		If GetGadgetState(#Ch_CRLF) & #PB_Checkbox_Checked
			OptCh | #PB_RegularExpression_AnyNewLine
		EndIf

		If GetGadgetState(#Ch_i) & #PB_Checkbox_Checked
			OptCh | #PB_RegularExpression_NoCase
		EndIf

		If flgFind And MessageRequester(Lng(46), Lng(47) + #q$ + tmp$ + #q$ + Lng(48), #PB_MessageRequester_YesNo) = #PB_MessageRequester_Yes

			file_id = OpenFile(#PB_Any, PathConfig$ + "Library" + #PS$ + GetGadgetText(#btnLib) + ".ini", #PB_UTF8)
			If file_id
				Text$ = ReadString(file_id, #PB_UTF8 | #PB_File_IgnoreEOL)
				Replace$ = "[z--z]" + #CRLF$ + tmp$ + #CRLF$ + GetScintillaGadgetText() + #CRLF$ + GetGadgetText(#FiedReplace) + #CRLF$ + Str(OptCh) + #CRLF$ + GetGadgetText(#Ed_Sourse) + #CRLF$ + "[z--z]"
				RegExp_id = CreateRegularExpression(#PB_Any, "\[z--z\]\r\n\Q" + tmp$ + "\E\r\n.+?\[z--z\]", #PB_RegularExpression_DotAll)
				If RegExp_id
; 					Debug 1
; 					tmp$ = Text$
					Text$ = ReplaceRegularExpression(RegExp_id, Text$, Replace$)
; 					If tmp$ = Text$
; 						Debug 2
; 					EndIf
					FileSeek(file_id, 0)
					WriteString(file_id, Text$, #PB_UTF8)
					TruncateFile(file_id)
				EndIf
				CloseFile(file_id)
			EndIf
		Else
			file_id = OpenFile(#PB_Any, PathConfig$ + "Library" + #PS$ + GetGadgetText(#btnLib) + ".ini", #PB_File_Append | #PB_UTF8)
			If file_id
				WriteString(file_id, #CRLF$ + tmp$ + #CRLF$, #PB_UTF8)
				WriteString(file_id, GetScintillaGadgetText() + #CRLF$, #PB_UTF8)
				WriteString(file_id, GetGadgetText(#FiedReplace) + #CRLF$, #PB_UTF8)

				WriteString(file_id, Str(OptCh) + #CRLF$, #PB_UTF8)
				WriteString(file_id, GetGadgetText(#Ed_Sourse) + #CRLF$, #PB_UTF8)
				WriteString(file_id, "[z--z]", #PB_UTF8)
				CloseFile(file_id)
				AddGadgetItem(#LV , -1, tmp$)
			EndIf
		EndIf
	EndIf
EndProcedure

Procedure DeleteElemLib()
	Protected idx, sResult$, regex_id, *mem, Text$, file_id, File$
	idx = GetGadgetState(#LV)
	If idx <> -1
		sResult$ = GetGadgetItemText(#LV, idx)
		If MessageRequester(Lng(49), Lng(50) + #q$ + sResult$ + #q$ + "?", #PB_MessageRequester_YesNo) = #PB_MessageRequester_No
			ProcedureReturn
		EndIf

		File$ = GetGadgetText(#btnLib)
		file_id = ReadFile(#PB_Any, PathConfig$ + "Library" + #PS$ + File$ + ".ini")
		If file_id
			Text$ = ReadString(file_id, #PB_UTF8 | #PB_File_IgnoreEOL)
			CloseFile(file_id)
		EndIf

		regex_id = CreateRegularExpression(#PB_Any, "(?<=\[z-)-z\]\r\n\Q" + sResult$ + "\E\r\n(.+?)\r\n\[z-(?=-z\])", #PB_RegularExpression_DotAll)
		If regex_id
			Text$ = ReplaceRegularExpression(regex_id, Text$, "")
		EndIf

; 		Debug Text$
; 		ProcedureReturn

		file_id = CreateFile(#PB_Any, PathConfig$ + "Library" + #PS$ + File$ + ".ini", #PB_UTF8)
		If file_id
			WriteStringFormat(file_id, #PB_UTF8)
; 			WriteString(file_id , Text$)
			*mem = UTF8(Text$)
; 			WriteData(file_id, @Text$, Len(Text$))
			WriteData(file_id, *mem, StringByteLength(Text$, #PB_UTF8))
			FreeMemory(*mem)
			CloseFile(file_id)
			RemoveGadgetItem(#LV, idx)
		EndIf

	EndIf
EndProcedure


Procedure RangeCheck(value, min, max)
	If value < min
		value = min
	ElseIf value > max
		value = max
	EndIf
	ProcedureReturn value
EndProcedure

; idle
; https://www.purebasic.fr/english/viewtopic.php?t=74264
Procedure.s Oct(number.q)
	Protected s.s = Space(8*SizeOf(Character))
	Protected a
	For a = 7 To 0 Step - 1
		PokeS(@s + a * SizeOf(Character), Str(number & 7), SizeOf(Character), #PB_String_NoZero)
		number >> 3
	Next
	s = LTrim(RTrim(s, " "), "0")
	If Not Asc(s) : s = "0" : EndIf
	ProcedureReturn s
EndProcedure



; число в массив
; Procedure StrToArrLetter(Array Arr.s(1), String$)
; 	Protected LenStr, n
; 	LenStr = Len(String$) ; если набор символов менее 2-х, то не имеет смысла
; 	If LenStr
; 		ReDim Arr(LenStr+1)
; 		For n = 1 To LenStr+1
; 			Arr(n) = Mid(String$, n, 1)
; 		Next
; 	EndIf
; 	ProcedureReturn
; EndProcedure
; 
; Procedure.s DecToNum(DEC, Symbol$)
; 	Protected OUT.s, ost, ArrSz
; 	Protected Dim Arr.s(1)
; 	StrToArrLetter(Arr(), Symbol$)
; 	ArrSz = ArraySize(Arr()) - 1
; 	Repeat
; 		ost = Mod(DEC, ArrSz)
; 		DEC = (DEC - ost) / ArrSz
; 		OUT = Arr(ost + 1) + OUT
; 	Until DEC < 1
; 	ProcedureReturn OUT
; EndProcedure


Procedure SetExeRegExpToLV(Text$)
	Protected i, old_i, Count, rex_id
	Protected Dim Chr$(32)
	ClearGadgetItems(#LvTest)
	Chr$(0) = "NUL"
	Chr$(1) = "SOH"
	Chr$(2) = "STX"
	Chr$(3) = "ETX"
	Chr$(4) = "EOT"
	Chr$(5) = "ENQ"
	Chr$(6) = "ACK"
	Chr$(7) = "BEL"
	Chr$(8) = "BS"
	Chr$(9) = "HT"
	Chr$(10) = "LF"
	Chr$(11) = "VT"
	Chr$(12) = "FF"
	Chr$(13) = "CR"
	Chr$(14) = "SO"
	Chr$(15) = "SI"
	Chr$(16) = "DLE"
	Chr$(17) = "DC1"
	Chr$(18) = "DC2"
	Chr$(19) = "DC3"
	Chr$(20) = "DC4"
	Chr$(21) = "NAK"
	Chr$(22) = "SYN"
	Chr$(23) = "ETB"
	Chr$(24) = "CAN"
	Chr$(25) = "EM"
	Chr$(26) = "SUB"
	Chr$(27) = "ESC"
	Chr$(28) = "FS"
	Chr$(29) = "GS"
	Chr$(30) = "RS"
	Chr$(31) = "US"
	Chr$(32) = "Space"
	
	CompilerIf  #PB_Compiler_OS = #PB_OS_Windows
		SendMessage_(GadgetID(#LvTest), #WM_SETREDRAW, 0, 0)
	CompilerEndIf
	
	For i = 0 To 126
		; AddGadgetItem(#LvTest, -1, Chr(i) + #LF$ + Str(i)  + #LF$ + RSet(Hex(i), 2, "0")  + #LF$ + RSet(Oct(i), 3, "0"))
		; 			sprintf(*mem, "%o", i)
		; 			tmp$ = PeekS(*mem, -1, #PB_UTF8)
		; 			AddGadgetItem(#LvTest, -1, Chr(i) + #LF$ + Str(i)  + #LF$ + RSet(Hex(i), 2, "0")  + #LF$ + tmp$)
		; 			tmp$ = Chr(i)
		; 			If tmp$ = #LF$ : tmp$ = "LF" : EndIf
		; 			If Not Asc(tmp$) : tmp$ = "0" : EndIf
		If i > 32
			; 			AddGadgetItem(#LvTest, -1, tmp$ + #LF$ + Str(i)  + #LF$ + RSet(Hex(i), 2, "0")  + #LF$ + DecToNum(i, "01234567"))
			AddGadgetItem(#LvTest, -1, Chr(i) + #LF$ + Str(i)  + #LF$ + RSet(Hex(i), 2, "0")  + #LF$ + RSet(Oct(i), 3, "0"))
		Else
			AddGadgetItem(#LvTest, -1, Chr$(i) + #LF$ + Str(i)  + #LF$ + RSet(Hex(i), 2, "0")  + #LF$ + RSet(Oct(i), 3, "0"))
		EndIf
	Next
	AddGadgetItem(#LvTest, -1, "DEL" + #LF$ + Str(i)  + #LF$ + RSet(Hex(i), 2, "0")  + #LF$ + RSet(Oct(i), 3, "0"))
	
	
	rex_id = CreateRegularExpression(#PB_Any, Text$)
	If rex_id
		For i = 0 To 127
			If MatchRegularExpression(rex_id, Chr(i))
				SetGadgetItemImage(#LvTest, i, ImageID(9))
				Count + 1
			EndIf
		Next
		If Asc(Text$) = '[' ; защита от \D, когда будет выбрано 50000
			For i = 128 To 55295
				If MatchRegularExpression(rex_id, Chr(i))
					If old_i + 1 <> i
						AddGadgetItem(#LvTest, -1, " ")
					EndIf
					old_i = i
					AddGadgetItem(#LvTest, -1, Chr(i) + #LF$ + Str(i)  + #LF$ + RSet(Hex(i), 4, "0")  + #LF$ + RSet(Oct(i), 5, "0"), ImageID(9))
					Count + 1
				EndIf
			Next
		EndIf
		SetGadgetText(#StatusBar, Lng(51) + Str(Count))
		FreeRegularExpression(rex_id)
	Else
; 		MessageRequester("", RegularExpressionError())
		SetGadgetText(#StatusBar, RegularExpressionError())
	EndIf
	
	CompilerIf  #PB_Compiler_OS = #PB_OS_Windows
		SendMessage_(GadgetID(#LvTest), #WM_SETREDRAW, 1, 0)
	CompilerEndIf
EndProcedure



Procedure TestRange()
	Protected Text$ ;, isFind, pos, pos2
	Protected height, pos
	Protected reSqBr
	; 	Protected *mem = AllocateMemory(256, #PB_Memory_NoClear)
; 	Static reSqBr

	Text$ = GetScintillaGadgetText()
; 	If Not reSqBr
; 	из-за FreeRegularExpression(#PB_All) глобальный reSqBr был удалён и
; 	выладала всегда одна и та же ошибка. Но не страшно, так как
; 	этот тест вызывается редко и хранить его в глобальных будучи
; 	никогда не создавая - роскошь.
		reSqBr = CreateRegularExpression(#PB_Any, "(?<!\\)\[.+?(?<![\\\[])\]")
; 	EndIf
	If reSqBr
		If ExamineRegularExpression(reSqBr, Text$)
			If  NextRegularExpressionMatch(reSqBr)
				Text$ = RegularExpressionMatchString(reSqBr)
			EndIf
		EndIf
	Else
		MessageRequester("Error", "Error")
		ProcedureReturn 
	EndIf
; 	pos = FindString(SciText$, "["
; 	If pos
; 		pos2 = FindString(SciText$, "]"
; 		If pos2 - pos > 1
; 			isFind = 1
; 		EndIf
; 	EndIf
	ExamineDesktops()
	height = DesktopHeight(0) - 100
	pos = (DesktopWidth(0) - 320) / 2

	If OpenWindow(#WinRange, pos, 0, 320, height, Lng(52), #PB_Window_SystemMenu | #PB_Window_SizeGadget | #PB_Window_MaximizeGadget, WindowID(#Window))

		TextGadget(#StatusBar, 5, height - 20, 310, 20, "")
		ComboBoxGadget(#cmbSq, 5, 5, 277, 30, #PB_ComboBox_Editable)
		hCmbSq = GadgetID(#cmbSq)
		If Asc(Text$)
; 		SetGadgetItemText(#cmbSq, 0, Text$)
			SetGadgetText(#cmbSq, Text$)
		EndIf
		AddGadgetItem(#cmbSq, -1, "\a")
		AddGadgetItem(#cmbSq, -1, "[\cA-\cZ]")
		AddGadgetItem(#cmbSq, -1, "\d")
		AddGadgetItem(#cmbSq, -1, "\D")
		AddGadgetItem(#cmbSq, -1, "\e")
		AddGadgetItem(#cmbSq, -1, "\f")
		AddGadgetItem(#cmbSq, -1, "\h")
		AddGadgetItem(#cmbSq, -1, "\H")
		AddGadgetItem(#cmbSq, -1, "\n")
		AddGadgetItem(#cmbSq, -1, "\N")
		AddGadgetItem(#cmbSq, -1, "\R")
		AddGadgetItem(#cmbSq, -1, "\s")
		AddGadgetItem(#cmbSq, -1, "\S")
		AddGadgetItem(#cmbSq, -1, "\t")
		AddGadgetItem(#cmbSq, -1, "\v")
		AddGadgetItem(#cmbSq, -1, "\V")
		AddGadgetItem(#cmbSq, -1, "\w")
		AddGadgetItem(#cmbSq, -1, "\W")
		AddGadgetItem(#cmbSq, -1, "[\x{01}-\x{0F}]")
		AddGadgetItem(#cmbSq, -1, "[\x01-\x0F]")
		AddGadgetItem(#cmbSq, -1, "[\001-\010]")
		AddGadgetItem(#cmbSq, -1, "[[:alnum:]]")
		AddGadgetItem(#cmbSq, -1, "[[:alpha:]]")
		AddGadgetItem(#cmbSq, -1, "[[:ascii:]]")
		AddGadgetItem(#cmbSq, -1, "[[:blank:]]")
		AddGadgetItem(#cmbSq, -1, "[[:cntrl:]]")
		AddGadgetItem(#cmbSq, -1, "[[:digit:]]")
		AddGadgetItem(#cmbSq, -1, "[[:graph:]]")
		AddGadgetItem(#cmbSq, -1, "[[:lower:]]")
		AddGadgetItem(#cmbSq, -1, "[[:print:]]")
		AddGadgetItem(#cmbSq, -1, "[[:punct:]]")
		AddGadgetItem(#cmbSq, -1, "[[:space:]]")
		AddGadgetItem(#cmbSq, -1, "[[:upper:]]")
		AddGadgetItem(#cmbSq, -1, "[[:word:]]")
		AddGadgetItem(#cmbSq, -1, "[[:xdigit:]]")

		ButtonImageGadget(#btnUpdRng, 320 - 35, 5, 30, 30, ImageID(8))
		ListIconGadget(#LvTest, 5, 38, 310, height - 60, "Character", 90, #PB_ListIcon_FullRowSelect | #PB_ListIcon_GridLines)
		AddGadgetColumn(#LvTest, 1, "Dec", 60)
		AddGadgetColumn(#LvTest, 2, "Hex", 60)
		AddGadgetColumn(#LvTest, 3, "Oct", 60)
		
		If Asc(Text$)
			SetExeRegExpToLV(Text$)
		EndIf
		
		
	BindEvent(#PB_Event_SizeWindow, @SizeWinRange(), #WinRange)
	CompilerIf #PB_Compiler_OS = #PB_OS_Windows
		SetWindowCallback(@WinRange_Callback(), #WinRange)
	CompilerEndIf
		
	EndIf
	

; 	FreeMemory(*mem)
EndProcedure


Procedure SizeWinRange()
	Protected w5 = WindowWidth(#WinRange)
	Protected h5 = WindowHeight(#WinRange)
	ResizeGadget(#cmbSq, #PB_Ignore, #PB_Ignore, w5 - 43, #PB_Ignore)
	ResizeGadget(#btnUpdRng, w5 - 35, #PB_Ignore, #PB_Ignore, #PB_Ignore)
	ResizeGadget(#LvTest, #PB_Ignore, #PB_Ignore, w5 - 10, h5 - 60)
	ResizeGadget(#StatusBar, #PB_Ignore, h5 - 20, w5 - 20, #PB_Ignore)
EndProcedure


Procedure SizeWindow()
	w = WindowWidth(#Window)
	h = WindowHeight(#Window)
	ResizeGadget(#Splitter, #PB_Ignore, #PB_Ignore, w - 290, h - 101 - SciHeight)
	ResizeGadget(#Ch_s, w - 270, #PB_Ignore, #PB_Ignore, #PB_Ignore)
	ResizeGadget(#Ch_x, w - 270, #PB_Ignore, #PB_Ignore, #PB_Ignore)
	ResizeGadget(#Ch_m, w - 270, #PB_Ignore, #PB_Ignore, #PB_Ignore)
	ResizeGadget(#Ch_CRLF, w - 270, #PB_Ignore, #PB_Ignore, #PB_Ignore)
	ResizeGadget(#Ch_i, w - 270, #PB_Ignore, #PB_Ignore, #PB_Ignore)
	ResizeGadget(#Opt_Search, w - 190, h - 240, #PB_Ignore, #PB_Ignore)
	ResizeGadget(#Opt_Replace, w - 190, h - 220, #PB_Ignore, #PB_Ignore)
	ResizeGadget(#Opt_Array, w - 190, h - 200, #PB_Ignore, #PB_Ignore)
	ResizeGadget(#Opt_Group, w - 190, h - 180, #PB_Ignore, #PB_Ignore)
	ResizeGadget(#Opt_Step, w - 190, h - 160, #PB_Ignore, #PB_Ignore)
	ResizeGadget(#Ch_reg2, w - 210, h - 220, #PB_Ignore, #PB_Ignore)
	ResizeGadget(#Ch_Esc, w - 230, h - 220, #PB_Ignore, #PB_Ignore)
	ResizeGadget(#Ch_markup, w - 210, h - 140, #PB_Ignore, #PB_Ignore)
	ResizeGadget(#HL_help, w - 80, h - 110, #PB_Ignore, #PB_Ignore)
	ResizeGadget(#btnOpen, w - 270, #PB_Ignore, #PB_Ignore, #PB_Ignore)
	ResizeGadget(#btnClear, w - 270, #PB_Ignore, #PB_Ignore, #PB_Ignore)
	ResizeGadget(#btnAddToLib, w - 270, #PB_Ignore, #PB_Ignore, #PB_Ignore)
	ResizeGadget(#btnDel, w - 270, #PB_Ignore, #PB_Ignore, #PB_Ignore)
	ResizeGadget(#btnMeta, w - 270, #PB_Ignore, #PB_Ignore, #PB_Ignore)
	ResizeGadget(#btnUp, w - 270, #PB_Ignore, #PB_Ignore, #PB_Ignore)
	ResizeGadget(#btnRange, w - 270, #PB_Ignore, #PB_Ignore, #PB_Ignore)
	ResizeGadget(#btnLib, w - 230, #PB_Ignore, #PB_Ignore, #PB_Ignore)
	ResizeGadget(#btnStart, w - 270, h - 110, #PB_Ignore, #PB_Ignore)
	ResizeGadget(#btnCopy, w - 150, h - 110, #PB_Ignore, #PB_Ignore)
	ResizeGadget(#SciGadget, #PB_Ignore, #PB_Ignore, w - 320, #PB_Ignore)
	ResizeGadget(#FiedReplace, #PB_Ignore, #PB_Ignore, w - 290, #PB_Ignore)
	ResizeGadget(#btnMenu, w - 308, #PB_Ignore, #PB_Ignore, #PB_Ignore)
	ResizeGadget(#TimeOld, w - 270, h - 54, #PB_Ignore, #PB_Ignore)
	ResizeGadget(#TimeNew, w - 270, h - 32, #PB_Ignore, #PB_Ignore)
	ResizeGadget(#LV, w - 230, #PB_Ignore, #PB_Ignore, h - 405)
	tmp = (w - 320) / 2
	If tmp < 280
		tmp = 280
	EndIf
	ResizeGadget(#Ch_OnTop, tmp, #PB_Ignore, #PB_Ignore, #PB_Ignore)
	ResizeGadget(#Ch_NotUpd, tmp, #PB_Ignore, #PB_Ignore, #PB_Ignore)
	ResizeGadget(#t1, #PB_Ignore, #PB_Ignore, tmp - 10, #PB_Ignore)
	ResizeGadget(#t3, #PB_Ignore, #PB_Ignore, tmp - 10, #PB_Ignore)
EndProcedure


Procedure ExitProg()
	Protected i, OldRecentUsed$
	Protected NewMap RecentUsedNoDupl()

	FreeRegularExpression(#PB_All)
	ForEach regex()
		FreeMemory(regex()\mem)
	Next

; 				If (w3 <> w Or h3 <> h) And isINI And OpenPreferences(ini$, #PB_Preference_GroupSeparator)
; 					If PreferenceGroup("Set")
; 						WritePreferenceInteger("height", h)
; 						WritePreferenceInteger("width", w)
; 					EndIf
; 					ClosePreferences()
; 				EndIf
	If isINI And OpenPreferences(ini$, #PB_Preference_GroupSeparator)
; 		If PreferenceGroup("regexp")
		RemovePreferenceGroup("regexp")
		PreferenceGroup("regexp")
		i = 0
		ForEach RecentUsed()
; 				Добавляем проверку для исключения дубликатов из списка
			If FindMapElement(RecentUsedNoDupl(), RecentUsed())
; 					DeleteElement(RecentUsed())
				Continue
			Else
				AddMapElement(RecentUsedNoDupl(), RecentUsed(), #PB_Map_NoElementCheck)
			EndIf
; 				Debug RecentUsed()
; 				If OldRecentUsed$ =  RecentUsed()
; 					Continue
; 				EndIf
; 				OldRecentUsed$ =  RecentUsed()
			i + 1
			If i > maxhistor
				Break
			EndIf
				; TODO использовать регвыр для поиска и замены
; 				Добавляем проверку переносов строк, чтобы правильно сохранить в строчный параметр ini-файла
			If FindString(RecentUsed(), #CR$) Or FindString(RecentUsed(), #LF$)
				RecentUsed() = ReplaceString(RecentUsed(), #CRLF$, "}—•—{")
				RecentUsed() = ReplaceString(RecentUsed(), #CR$, "}—•—{")
				RecentUsed() = ReplaceString(RecentUsed(), #LF$, "}—•—{")
			EndIf
			WritePreferenceString(Str(i), RecentUsed())
		Next
			; 			Если ручками добавлены дублирующие строки, то их можно затереть
; 			это код уже не нужен так как удаляем группу и все лишние исчезнут сами
; 			If i < maxhistor
; 				For i = i To maxhistor
; 					WritePreferenceString(Str(i), "")
; 				Next
; 			EndIf
; 		EndIf
		If PreferenceGroup("Set")
			WritePreferenceString("lastlib", GetGadgetText(#btnLib))
			i = GetGadgetState(#Ch_OnTop) & #PB_Checkbox_Checked
			If topmost <> i
				WritePreferenceInteger("topmost", i)
			EndIf
			If (w3 <> w Or h3 <> h)
				WritePreferenceInteger("height", h)
				WritePreferenceInteger("width", w)
			EndIf
		EndIf
		ClosePreferences()
	EndIf
	CloseWindow(#Window)
	End
EndProcedure
; IDE Options = PureBasic 6.04 LTS (Windows - x64)
; CursorPosition = 271
; FirstLine = 257
; Folding = ---------
; Optimizer
; EnableXP
; DPIAware
; UseIcon = icon.ico
; Executable = RegExpPB.exe
; CompileSourceDirectory
; Compiler = PureBasic 6.04 LTS - C Backend (Windows - x64)
; DisableCompileCount = 4
; EnableBuildCount = 0
; EnableExeConstant
; IncludeVersionInfo
; VersionField0 = 0.7.0.%BUILDCOUNT
; VersionField2 = AZJIO
; VersionField3 = RegExpPB
; VersionField4 = 0.7.0
; VersionField6 = RegExpPB
; VersionField9 = AZJIO