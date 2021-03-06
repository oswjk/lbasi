program calc1;

{$H+}

uses
    typinfo, sysutils, character;

type
    TokenType = (TT_Integer, TT_Plus, TT_Minus, TT_Asterisk, TT_Slash, TT_Eof,
        TT_LParen, TT_RParen);

    Token = class
        TokenType: TokenType;
        constructor Create(Type_: TokenType);
        function ToStr: String; virtual;
    end;

    TokenInteger = class(Token)
        Val: Integer;
        constructor Create(Value_: Integer);
        function ToStr: String; override;
    end;

    TokenPlus = class(Token)
        constructor Create;
    end;

    TokenMinus = class(Token)
        constructor Create;
    end;

    TokenEof = class(Token)
        constructor Create;
    end;

    TLexer = class
        Text: AnsiString;
        CurPos: Integer;

        constructor Create(Text_: AnsiString);

        procedure Error;
        procedure SkipWhitespace;
        function AtEnd: Boolean;
        function CurChar: Char;
        function GetInteger: Integer;
        function GetNextToken: Token;
    end;

    TInterpreter = class
        Lexer: TLexer;
        CurrentToken: Token;

        constructor Create(Lexer_: TLexer);

        procedure Error;
        procedure Eat(T: TokenType);
        function Factor: Integer;
        function Expr: Integer;
        function Term: Integer;
    end;

constructor Token.Create(Type_: TokenType);
begin
    inherited Create;
    TokenType := Type_;
end;

function Token.ToStr: String;
begin
    Result := GetEnumName(TypeInfo(TokenType), Ord(Self.TokenType));
end;

constructor TokenInteger.Create(Value_: Integer);
begin
    inherited Create(TT_Integer);
    Val := Value_;
end;

function TokenInteger.ToStr: String;
begin
    Result := inherited;
    Result := Result + '(' + IntToStr(Val) + ')';
end;

constructor TokenPlus.Create;
begin
    inherited Create(TT_Plus);
end;

constructor TokenMinus.Create;
begin
    inherited Create(TT_Minus);
end;

constructor TokenEof.Create;
begin
    inherited Create(TT_Eof);
end;

constructor TLexer.Create(Text_: String);
begin
    inherited Create;
    Text := Text_;
    CurPos := 1;
end;

procedure TLexer.Error;
begin
    Raise Exception.Create('invalid input');
end;

procedure TLexer.SkipWhitespace;
begin
    while (not AtEnd) and IsWhiteSpace(CurChar) do
        Inc(CurPos);
end;

function TLexer.AtEnd: Boolean;
begin
    Result := CurPos > Length(Text);
end;

function TLexer.CurChar: Char;
begin
    Result := Text[CurPos];
end;

function TLexer.GetInteger: Integer;
var
    Start: Integer;
begin
    Start := CurPos;

    while (not AtEnd) and IsDigit(CurChar) do
        Inc(CurPos);

    Result := StrToInt(Copy(Text, Start, CurPos - Start));
end;

function TLexer.GetNextToken: Token;
begin
    SkipWhitespace;

    if AtEnd then
    begin
        Result := TokenEof.Create;
        Exit;
    end;

    if IsDigit(CurChar) then
    begin
        Result := TokenInteger.Create(GetInteger);
    end
    else if CurChar = '+' then
    begin
        Result := TokenPlus.Create;
        Inc(CurPos);
    end
    else if CurChar = '-' then
    begin
        Result := TokenMinus.Create;
        Inc(CurPos);
    end
    else if CurChar = '*' then
    begin
        Result := Token.Create(TT_Asterisk);
        Inc(CurPos);
    end
    else if CurChar = '/' then
    begin
        Result := Token.Create(TT_Slash);
        Inc(CurPos);
    end
    else if CurChar = '(' then
    begin
        Result := Token.Create(TT_LParen);
        Inc(CurPos);
    end
    else if CurChar = ')' then
    begin
        Result := Token.Create(TT_RParen);
        Inc(CurPos);
    end
    else
        Error;
end;

constructor TInterpreter.Create(Lexer_: TLexer);
begin
    Lexer := Lexer_;
    CurrentToken := Lexer.GetNextToken;
end;

procedure TInterpreter.Error;
begin
    Raise Exception.Create('syntax error');
end;

procedure TInterpreter.Eat(T: TokenType);
begin
    if CurrentToken.TokenType = T then
    begin
        CurrentToken := Lexer.GetNextToken;
    end
    else
        Error;
end;


function TInterpreter.Factor: Integer;
var
    T: Token;
begin
    T := CurrentToken;

    if T.TokenType = TT_Integer then
    begin
        Eat(TT_Integer);
        Result := TokenInteger(T).Val;
    end
    else if T.TokenType = TT_LParen then
    begin
        Eat(TT_LParen);
        Result := Expr;
        Eat(TT_RParen);
    end
    else
        Error;
end;

function TInterpreter.Expr: Integer;
var
    Tok: Token;
begin
    // expr : term ((PLUS|MINUS) term)*
    // term : factor ((MUL|DIV) factor)*
    // factor : INTEGER | LPAREN expr RPAREN

    Result := Term;

    while CurrentToken.TokenType in [TT_Plus, TT_Minus] do
    begin
        Tok := CurrentToken;
        if Tok.TokenType = TT_Plus then
        begin
            Eat(TT_Plus);
            Result := Round(Result + Term);
        end
        else if Tok.TokenType = TT_Minus then
        begin
            Eat(TT_Minus);
            Result := Round(Result - Term);
        end;
    end;
end;

function TInterpreter.Term: Integer;
var
    Tok: Token;
begin
    Result := Factor;

    while CurrentToken.TokenType in [TT_Asterisk, TT_Slash] do
    begin
        Tok := CurrentToken;
        if Tok.TokenType = TT_Asterisk then
        begin
            Eat(TT_Asterisk);
            Result := Result * Factor;
        end
        else if Tok.TokenType = TT_Slash then
        begin
            Eat(TT_Slash);
            Result := Round(Result / Factor);
        end;
    end;
end;

var
    Lexer: TLexer;
    Interp: TInterpreter;
    Line: String;
    I: Integer;

procedure InterpString(S: String);
begin
    Lexer := TLexer.Create(S);
    Interp := TInterpreter.Create(Lexer);
    WriteLn(Interp.Expr);
    FreeAndNil(Interp);
end;

procedure InputLoop;
begin
    while True do
    begin
        Write('calc> ');
        if Eof(Input) then break;
        ReadLn(Line);
        if Length(Line) = 0 then continue;
        InterpString(Line);
    end;
end;

begin
    if ParamCount > 0 then
    begin
        Line := '';
        for I := 1 to ParamCount do
        begin
            Line := Line + ParamStr(I);
        end;
        InterpString(Line);
    end
    else
        InputLoop;
end.
