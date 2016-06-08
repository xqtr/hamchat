
Program fpchamchat;

{$mode objfpc}
{$H+}

Uses 
  {$IFDEF UNIX}
cthreads,
  {$ENDIF}
  {$IFDEF WINDOWS}
Windows,
  {$ENDIF}
fldigi,
xmlrpc,
//unix,
//unixutil,
httpsend,
//process,
fptimer,
m_types,
f_Strings,
f_Output,
m_Input,
//f_menuinput,
//f_boxes,
f_textview,
f_menuline_ver,
f_fileutils,
crt,
m_DateTime,
m_Term_Ansi,
baseunix,
sysutils,
strutils,
classes,
config,
custapp;

Const 
{$IFDEF WIN32}
  PathSep = '\';
  CRLF = #13#10;
  OSID     = 'Windows';
  OSType   = 0;
  {$ENDIF}

  {$IFDEF LINUX}
  PathSep = '/';
  CRLF = #10;
    {$IFDEF CPUARM}
  OSID = 'Raspberry Pi'; {$ELSE}
  OSID = 'Linux'; {$ENDIF}
  OSType   = 1;
  {$ENDIF}

  {$IFDEF DARWIN}
  PathSep = '/';
  CRLF = #10;
  OSID     = 'OSX';
  OSType   = 2;
  {$ENDIF}

  {$IFDEF OS2}
  PathSep = '\';
  CRLF = #13#10;
  OSID     = 'OS/2';
  OSType   = 4;
  {$ENDIF}
  wait: integer = 30;

Type 
  Tfpchamchat = Class(TCustomApplication)
    Private 
      Code     : String[2];
      dFile    : File;
      Ext      : String[4];
      dRead    : LongInt;
      Buffer   : Array[1..4096] Of Char;
      Old      : Boolean;
      Str      : String;
      A        : Word;
      Ch       : Char;
      Done     : Boolean;

    Public 
      c: char;
      //Transmit texts
      padding: string;
      eot : string;
      vox_padding : string;
      md5 : string;
      
      Image  : TConsoleImageRec;
      f,d: byte;
      rxtimer: TFPTimer;
      input: tinput;
      screen: toutput;
      dir: string;
      //box:tbox;
      ss: string;
      //mm:tmenuinput;
      fCount : Integer;
      FTick : Integer;
      N : TDateTime;
      fldigiisrunning : boolean;
      rxbuf : string;
      parsebuf: string;
      Terminal : TTermAnsi;

      Procedure displayansi(filename:String; delay:integer);
      procedure loadsettings;
      Procedure rxontimer(Sender: TObject);
      Procedure OutStr (S: String);
      Function  transmittext(strs: String): boolean;
      Procedure centertext(strs:String; line:byte);
      Procedure writexy(x,y:integer; strs:String);
      Procedure enable_ansi_unix;
      Function  Ansi_Color (B : Byte) : String;
      procedure createconfig;
      Function  GetChar : Char;
      Procedure DoRun;
      
      override;
  End;

Var 
  hamchat : tfpchamchat;


{	
	 <?xml version=\"1.0\"?>
	<methodCall>
		<methodName>fldigi.version</methodName>
		<params>
		<param>
		<value>$NAME</value>
		</param>
		</params>
	</methodCall>

}
procedure tfpchamchat.loadsettings;
begin
	SetConfigFileName(dir+'config.xml');
	padding := GetValueFromConfigFile('transmit','padding','//HAMCHAT//');
	vox_padding := GetValueFromConfigFile('transmit','vox_padding','//ALPHA-BRAVO-ECHO-DELTA');
	eot := GetValueFromConfigFile('transmit','eot','//EOT//');
end;

procedure tfpchamchat.createconfig;
begin
	setconfigfilename(dir+'config.xml');
	SaveValueToConfigFile('transmit','padding','//HAMCHAT//');
	SaveValueToConfigFile('transmit','EOT','//END//');
	SaveValueToConfigFile('transmit','vox_padding','//ALPHA-BRAVO-ECHO-DELTA');
end;

Function pathchar(path:utf8string): utf8string;
Begin
  If path[length(path)]<>pathsep Then result := path+pathsep
  Else result := path;
End;

Procedure tfpchamchat.writexy(x,y:integer; strs:String);
Begin
  screen.WriteXYPipe(x,y,7,strMCILen(strs),strs);
End;

Procedure tfpchamchat.enable_ansi_unix;
Begin
  screen.RawWriteStr(#27 + '(U' + #27 + '[0m');
End;

Function tfpchamchat.GetChar : Char;
Begin
  If A = dRead Then
    Begin
      BlockRead (dFile, Buffer, SizeOf(Buffer), dRead);
      A := 0;
      If dRead = 0 Then
        Begin
          Done      := True;
          Buffer[1] := #26;
        End;
    End;

  Inc (A);
  GetChar := Buffer[A];
End;

Function tfpchamchat.Ansi_Color (B : Byte) : String;

Var 
  S : String;
Begin
  S          := '';
  Ansi_Color := '';

  Case B Of 
    00: S := #27 + '[0;30m';
    01: S := #27 + '[0;34m';
    02: S := #27 + '[0;32m';
    03: S := #27 + '[0;36m';
    04: S := #27 + '[0;31m';
    05: S := #27 + '[0;35m';
    06: S := #27 + '[0;33m';
    07: S := #27 + '[0;37m';
    08: S := #27 + '[1;30m';
    09: S := #27 + '[1;34m';
    10: S := #27 + '[1;32m';
    11: S := #27 + '[1;36m';
    12: S := #27 + '[1;31m';
    13: S := #27 + '[1;35m';
    14: S := #27 + '[1;33m';
    15: S := #27 + '[1;37m';
  End;

  If B In [00..07] Then B := (Screen.TextAttr SHR 4) And 7 + 16;

  Case B Of 
    16: S := S + #27 + '[40m';
    17: S := S + #27 + '[44m';
    18: S := S + #27 + '[42m';
    19: S := S + #27 + '[46m';
    20: S := S + #27 + '[41m';
    21: S := S + #27 + '[45m';
    22: S := S + #27 + '[43m';
    23: S := S + #27 + '[47m';
  End;

  Ansi_Color := S;
End;

Procedure tfpchamchat.OutStr (S: String);
Begin
  Terminal.ProcessBuf(S[1], Length(S));
End;

Procedure tfpchamchat.displayansi(filename:String; delay:integer);

Var 
  BaudEmu : LongInt;
Begin
  Assignfile (dFile, filename);
  Reset  (dFile, 1);

  If IoResult <> 0 Then
    Begin
      WriteLn('MTYPE: File ' + filename + ' not found.');
      Exit;
    End;

  Screen   := TOutput.Create(True);
  Terminal := TTermAnsi.Create(Screen);

  BaudEmu := delay;
  Done    := False;
  A       := 0;
  dRead   := 0;
  Ch      := #0;

  While Not Done Do
    Begin
      Ch := GetChar;

      If BaudEmu > 0 Then
        Begin
          Screen.BufFlush;

          If A Mod BaudEmu = 0 Then WaitMS(6);
        End;

      If Ch = #26 Then
        Break
      Else
        If Ch = #10 Then
          Begin
            Terminal.Process(#10);
          End
      Else
        If Ch = '|' Then
          Begin
            Code := GetChar;
            Code := Code + GetChar;

            If Code = '00' Then OutStr(Ansi_Color(0))
            Else
              If Code = '01' Then OutStr(Ansi_Color(1))
            Else
              If Code = '02' Then OutStr(Ansi_Color(2))
            Else
              If Code = '03' Then OutStr(Ansi_Color(3))
            Else
              If Code = '04' Then OutStr(Ansi_Color(4))
            Else
              If Code = '05' Then OutStr(Ansi_Color(5))
            Else
              If Code = '06' Then OutStr(Ansi_Color(6))
            Else
              If Code = '07' Then OutStr(Ansi_Color(7))
            Else
              If Code = '08' Then OutStr(Ansi_Color(8))
            Else
              If Code = '09' Then OutStr(Ansi_Color(9))
            Else
              If Code = '10' Then OutStr(Ansi_Color(10))
            Else
              If Code = '11' Then OutStr(Ansi_Color(11))
            Else
              If Code = '12' Then OutStr(Ansi_Color(12))
            Else
              If Code = '13' Then OutStr(Ansi_Color(13))
            Else
              If Code = '14' Then OutStr(Ansi_Color(14))
            Else
              If Code = '15' Then OutStr(Ansi_Color(15))
            Else
              If Code = '16' Then OutStr(Ansi_Color(16))
            Else
              If Code = '17' Then OutStr(Ansi_Color(17))
            Else
              If Code = '18' Then OutStr(Ansi_Color(18))
            Else
              If Code = '19' Then OutStr(Ansi_Color(19))
            Else
              If Code = '20' Then OutStr(Ansi_Color(20))
            Else
              If Code = '21' Then OutStr(Ansi_Color(21))
            Else
              If Code = '22' Then OutStr(Ansi_Color(22))
            Else
              If Code = '23' Then OutStr(Ansi_Color(23))
            Else
              Begin
                Terminal.Process('|');
                Dec (A, 2);
                Continue;
              End;
          End
      Else
        Terminal.Process(Ch);
    End;

  Close (dFile);
End;

Procedure tfpchamchat.centertext(strs:String; line:byte);
Begin
  screen.writexypipe((screenwidth Div 2) - (strMCILen(strs) div 2),line,7,strMCILen(strs),strs);
End;

Function tfpchamchat.transmittext(strs: String): boolean;
Var 
  tmp: string;
  i: integer;
Begin
  tmp := vox_padding+padding+strs+eot+'^r';
  Fldigi_ClearTx;
  i := 1;
  //disablewhiletransmit(true);
  While i<=length(tmp) Do
    Begin
      Fldigi_SendTxCharacter(tmp[i]);
      Fldigi_StartTx;
      i := i+1;
    End;
  //disablewhiletransmit(false);
  //edit1.SetFocus;
  //Fldigi_StopTx;
End;

Procedure tfpchamchat.rxonTimer(Sender : TObject);

Var 
  Dd : TDateTime;
  rxc: char;
  i:integer;

Begin
  Dd := Now-N;
   N := Now;
  //Writeln(FormatDateTime('ss.zzz',Dd),')');
  If Fldigi_IsRunning Then fldigiisrunning:=true else fldigiisrunning:=false;
  rxbuf := rxbuf + Fldigi_GetRxString;
  for i := 1 to Length(rxbuf) do
        begin
          rxc := rxbuf[i];
          if rxc > #127 then
            parsebuf := parsebuf + utf8encode(rxc)
          else if rxc >= #32 then
            parsebuf := parsebuf + rxc;
        end;
   i:=pos(lowercase(eot),lowercase(rxbuf));     
   if i>0 then begin
     parsebuf:=copy(rxbuf,1,i-1);
     rxbuf:='';
     Fldigi_Clearrx;
   end;
   writeln(parsebuf);
End;

Procedure tfpchamchat.DoRun;

Begin
  if lowercase(paramstr(1))='-c' then begin
    createconfig;
    halt;
  end;
  
  Screen := TOutput.Create(True);
  Input  := TInput.Create;
  enable_ansi_unix;
  screen.getoriginaltermsize;
  Screen.ClearScreen;
  dir := pathchar(extractfiledir(paramstr(0)));
  loadsettings;
  
  rxtimer := TFPTimer.Create(self);
  rxtimer.interval := 500;
  rxtimer.ontimer := @rxonTimer;
  rxtimer.starttimer;
  Try
    FTick := 0;
    FCount := 0;
    N := Now;
    Repeat
      c := readkey;
      If c='f' Then
        Begin
          If FldigiIsRunning Then writeln('Fldigi is running')
          Else writeln('Fldigi not running');
        End
      Else transmittext('hello');
      Sleep(1);
      CheckSynchronize;
      // Needed, because we are not running in a GUI loop.
    Until c='x';
  Finally
    rxTimer.Enabled := False;
    FreeAndNil(rxTimer);
End;
screen.textattr := 7;
screen.clearscreen;
//displayansi('loading.ans',wait);
screen.free;
input.free;
Terminate;
End;

Begin

  With tfpchamchat.Create(Nil) Do
    Try
      doRun
    Finally
      Free;
    End;
End.
