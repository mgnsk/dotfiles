local lush = require("lush")
local hsl = lush.hsl

local cdFront = hsl("#D4D4D4")
local cdBack = hsl("#101010")
local cdLeftDark = hsl("#252526")
local cdLeftMid = hsl("#373737")
local cdLeftLight = hsl("#3F3F46")
local cdPopupFront = hsl("#BBBBBB")
local cdPopupBack = hsl("#2D2D30")
local cdPopupHighlightBlue = hsl("#073655")
local cdPopupHighlightGray = hsl("#3D3D40")
local cdSplitDark = hsl("#444444")
local cdCursorDarkDark = hsl("#222222")
local cdCursorDark = hsl("#51504F")
local cdCursorLight = hsl("#AEAFAD")
local cdSelection = hsl("#264F78")
local cdLineNumber = hsl("#5A5A5A")
local cdDiffRedDark = hsl("#4B1818")
local cdDiffRedLight = hsl("#6F1313")
local cdDiffGreenDark = hsl("#373D29")
local cdSearchCurrent = hsl("#4B5632")
local cdSearch = hsl("#264F78")
local cdGray = hsl("#808080")
local cdViolet = hsl("#646695")
local cdBlue = hsl("#569CD6")
local cdLightBlue = hsl("#9CDCFE")
local cdGreen = hsl("#6A9955")
local cdBlueGreen = hsl("#4EC9B0")
local cdLightGreen = hsl("#B5CEA8")
local cdRed = hsl("#F44747")
local cdOrange = hsl("#CE9178")
local cdYellowOrange = hsl("#D7BA7D")
local cdYellow = hsl("#DCDCAA")
local cdPink = hsl("#C586C0")

local codedarker = lush(function()
    return {
        Normal({ fg = cdFront, bg = cdBack }),
        ColorColumn({ bg = cdCursorDarkDark }),
        Cursor({ fg = cdCursorDark, bg = cdCursorLight }),
        CursorLine({ bg = cdCursorDarkDark }),
        CursorColumn({ bg = cdCursorDarkDark }),
        Directory({ fg = cdBlue, bg = cdBack }),
        DiffAdd({ bg = cdDiffGreenDark }),
        DiffChange({ bg = cdDiffRedDark }),
        DiffDelete({ bg = cdDiffRedLight }),
        DiffText({ bg = cdDiffRedLight }),
        EndOfBuffer({ fg = cdLineNumber, bg = cdBack }),
        ErrorMsg({ fg = cdRed, bg = cdBack }),
        VertSplit({ fg = cdSplitDark, bg = cdBack }),
        Folded({ fg = cdLeftLight, bg = cdLeftDark }),
        FoldColumn({ fg = cdLineNumber, bg = cdBack }),
        SignColumn({ bg = cdBack }),
        IncSearch({ bg = cdSearchCurrent }),
        LineNr({ fg = cdLineNumber, bg = cdBack }),
        CursorLineNr({ fg = cdPopupFront, bg = cdBack }),
        MatchParen({ bg = cdCursorDark }),
        ModeMsg({ fg = cdFront, bg = cdLeftDark }),
        MoreMsg({ fg = cdFront, bg = cdLeftDark }),
        NonText({ fg = cdLineNumber, bg = cdBack }),
        Pmenu({ fg = cdPopupFront, bg = cdPopupBack }),
        PmenuSel({ fg = cdPopupFront, bg = cdPopupHighlightBlue }),
        PmenuSbar({ bg = cdPopupHighlightGray }),
        PmenuThumb({ bg = cdPopupFront }),
        Question({ fg = cdBlue, bg = cdBack }),
        Search({ bg = cdSearch }),
        SpecialKey({ fg = cdBlue }),
        StatusLine({ fg = cdFront, bg = cdLeftMid }),
        StatusLineNC({ fg = cdFront, bg = cdLeftDark }),
        TabLine({ fg = cdGray, bg = cdBack }),
        TabLineFill({ fg = cdGray, bg = cdBack }),
        TabLineSel({ fg = cdFront, bg = cdBack }),
        --Title {, s:cdNone, 'bold', {})
        Visual({ bg = cdSelection }),
        VisualNOS({ bg = cdSelection }),
        WarningMsg({ fg = cdOrange, bg = cdBack }),
        WildMenu({ bg = cdSelection }),
        Comment({ fg = cdGreen }),
        Constant({ fg = cdFront }),
        String({ fg = cdOrange }),
        Character({ fg = cdOrange }),
        Number({ fg = cdLightGreen }),
        Boolean({ fg = cdBlue }),
        Float({ fg = cdLightGreen }),
        Identifier({ fg = cdLightBlue }),
        Function({ fg = cdYellow }),
        Statement({ fg = cdPink }),
        Conditional({ fg = cdPink }),
        Repeat({ fg = cdPink }),
        Label({ fg = cdPink }),
        Operator({ fg = cdFront }),
        Keyword({ fg = cdPink }),
        Exception({ fg = cdPink }),
        PreProc({ fg = cdPink }),
        Include({ fg = cdPink }),
        Define({ fg = cdPink }),
        Macro({ fg = cdPink }),
        PreCondit({ fg = cdPink }),
        Type({ fg = cdBlueGreen }),
        StorageClass({ fg = cdBlue }),
        Structure({ fg = cdBlue }),
        Typedef({ fg = cdBlueGreen }),
        Special({ fg = cdYellowOrange }),
        SpecialChar({ fg = cdFront }),
        Tag({ fg = cdFront }),
        Delimiter({ fg = cdFront }),
        SpecialComment({ fg = cdGreen }),
        Debug({ fg = cdFront }),
        Conceal({ fg = cdFront, bg = cdBack }),
        Ignore({ fg = cdFront }),
        Error({ fg = cdRed, gui = "undercurl" }),
        Todo({ bg = cdLeftMid }),
        SpellBad({ fg = cdRed, gui = "undercurl" }),
        SpellCap({ SpellBad }),
        SpellRare({ SpellBad }),
        SpellLocal({ SpellBad }),
        GitGutterAdd({ fg = cdGreen }),
        GitGutterChange({ fg = cdOrange }),
        GitGutterDelete({ fg = cdRed }),
        GitGutterChangeDelete({ fg = cdViolet }),
        TSNamespace({ fg = cdFront }),
    }
end)

lush(codedarker)
