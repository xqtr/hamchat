
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
BlowFish,
RegExpr,
//unix,
//unixutil,
httpsend,
md5,
base64,
//process,
fptimer,
//clipbrd,
m_types,
f_Strings,
f_boxes,
f_Output,
m_Input,
//f_menuinput,
//f_boxes,
f_textview,
f_menuline_ver,
f_menuline_hor,
f_menuinput,
//f_dmenuinput,
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


{Function B64Encode   (S: String) : String;  
Function B64Decode     (S: String) : String;
Function HMAC_MD5      (Text, Key: String) : String;
Function MD5           (Const Value: String) : String;
Function Digest2String (Digest: String) : String;
Function String2Digest (Str: String) : String;}

Const 
  Field = 79;
  ffg = yellow;
  fbg = blue;
  fselbg = blue;
  fselfg = white;
  attr = ffg+fbg*16;
  len = 250;
  mode = 1;

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

  THCMessage = Record
    md5: string;
    msg: string;
    from: string;
    msgto: string;
    group: string;
    time: string;
    decoded: string;
    encode: boolean;
  End;
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
      md5_format : string;
      time_format : string;
      userid: string;
      touserid: string;
      groupid: string;
      modem: string;
      key: string;
      encrypt: string;
      lastmd5: string;
      storemsg: boolean;
      FillChar : Char;
      isexit: boolean;
      inrec:integer;
      outrec:integer;
      bufferrec:integer;
      inbuffer:tstringlist;


      StrPos : Integer;
      Junk   : Integer;
      CurPos : Integer;
      autostr: string;
      flist    : tstringlist;
      auto: boolean;
      fcase: boolean;
      x,y: integer;
      bb: tbox;
      ExitCode : Char;
      LoChars : string;
      HiChars : string;

      command: string;
      disablewhiletransmit:boolean;
      Image  : TConsoleImageRec;
      HideImage  : ^TConsoleImageRec;
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
      Procedure helpscreen;
      Procedure loadsettings;
      Function parseincomingtext(mes:String): string;
      Procedure rxontimer(Sender: TObject);
      Procedure OutStr (S: String);
      Function  getmd5(mes:String): string;
      Procedure optionsmenu;
      Function  gettime(mes:String): string;
      Function  transmittext(strs: String): boolean;
      Procedure centertext(strs:String; line:byte);
      Procedure writexy(x1,y1:integer; strs:String);
      Procedure enable_ansi_unix;
      Function  Ansi_Color (B : Byte) : String;
      Procedure createconfig;
      Function  GetChar : Char;
      Procedure show;
      Procedure hide;
      procedure trimfilerec(filename:string; i:integer);
      Procedure menu;
      Procedure appmenu;
      Procedure modemmenu;
      Procedure bottomline(s:String);
      Procedure appendmsg(s:String);
      Procedure appendincoming(s:String);
      Function blowEn(s,keys:String): string;
      Function blowDe(s,keys:String): string;
      Procedure fldigimenu;
      Procedure ReDraw;
      Procedure ReDrawPart;
      Procedure ScrollRight;
      Procedure ScrollLeft;
      Procedure endkeyf;
      Procedure Add_Char (Chr : Char);
      procedure redrawbuffer;
      Procedure DoRun; override;
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

procedure tfpchamchat.redrawbuffer;
var
  i:integer;
begin
    screen.textattr:=lightgray+black*16;
    screen.clearscreen;
    if inbuffer.count<screenheight-1 then begin
      for i:=0 to inbuffer.count-1 do screen.writeline(inbuffer[i]);
    end;
    if inbuffer.count>screenheight-1 then begin
      screen.cursorxy(1,screenheight-1);
      i:=inbuffer.count-1;
      while screen.cursory>=1 do begin
        screen.writestr(inbuffer[i]);
        screen.cursorxy(1,screen.cursory-1);
        i:=i-1;
      end;
    end;
    bottomline('Press ESC for menu...');
    screen.CursorXY (X, Y);
end;

procedure tfpchamchat.trimfilerec(filename:string; i:integer);
var
  sl:tstringlist;
begin
  if not fileexists(filename) then exit;
  sl:=tstringlist.create;
  sl.loadfromfile(filename);
  while sl.count > i do begin
    sl.delete(0);
  end;
  sl.savetofile(filename);
  sl.free;
end;

Procedure tfpchamchat.helpscreen;
Begin
  writeln;
  writeln('Hamchat - Chat with ham radio... ');
  writeln;
  writeln('Usage:');
  writeln;
  writeln('  hamchat [-c] [-t<touser>] [-e<yes/no>] [-u<fromuser>] [-g<togroup>]'+
          ' [-m<modem_type>] [-k<encode_key>] [Text to trasmit]');
  writeln;
  writeln('Options:');
  writeln;
  writeln('-c : Create config file template');
  writeln('-t<touser>     : username of receiver');
  writeln('-e<yes/no>     : encode message. Yes or No');
  writeln('-u<fromuser>   : username of sender');
  writeln('-g<togroup>    : group to receive message');
  writeln('-m<modem_type> : modem type');
  writeln('-k<encode_key> : encryption key to use');
  writeln;
  writeln('Examples:');
  writeln;
  writeln('hamchat');
  writeln('  Will run the program with UI');
  writeln('hamchat -c');
  writeln('  Create config file template');
  writeln('hamchat -umyname "Hello world"');
  writeln('  Set the sender name as myname and send the message "Hello world"');
  writeln('hamchat -h');
  writeln('  This help screen');
  writeln;
End;

Procedure tfpchamchat.loadsettings;
Begin
  SetConfigFileName(dir+'config.xml');
  padding := GetValueFromConfigFile('transmit','padding','/HAMCHAT/');
  vox_padding := GetValueFromConfigFile('transmit','vox_padding','/ALPHA-BRAVO-ECHO-DELTA/');
  eot := GetValueFromConfigFile('transmit','EOT','//EOT//');
  md5_format := GetValueFromConfigFile('transmit','md5_format','/MD5:%s/');
  time_format := GetValueFromConfigFile('transmit','time_format','/TIME:%s//');
  userid := getValuefromConfigFile('user','id','Unknown');
  groupid := getValuefromConfigFile('user','groupid','');
  modem := getValuefromConfigFile('transmit','modem','QPSK31');
  key := getValuefromConfigFile('user','key','temp');
  encrypt := getValuefromConfigFile('transmit','encrypt','No');
  inrec:=strs2i(getValuefromConfigFile('options','inbox_reccount','10'));
  outrec:=strs2i(getValuefromConfigFile('options','outbox_reccount','10'));
  bufferrec:=strs2i(getValuefromConfigFile('options','buffer_lines','200'));
  disablewhiletransmit:=false;
  If getValuefromConfigFile('options','store_messages','yes')='yes' Then storemsg := true
  Else storemsg := false;
  If fldigi_isrunning Then
    Begin
      Fldigi_AbortTx;
      Fldigi_SetModex(modem);
      Fldigi_ClearRx;
      Fldigi_ClearTx;
    End;
  If (lowercase(modem)='rtty') And (lowercase(encrypt)='yes') Then
    Begin
      addshadow(screen,25,10,30,4,darkgray+darkgray*16);
      textbox(screen,25,10,30,4,yellow+red*16,4,'Warning!',
              'Encryption cannot work with the RTTY protocol!');
    End;
  lastmd5 := '';
  command := '';
  FillChar := ' ';
  autostr := '';
  auto := false;
  fcase := false;
  x := 1;
  y := screenheight-1;
  LoChars  := #13;
  HiChars  := '';
  touserid := '';

End;

Procedure tfpchamchat.createconfig;
Begin
  setconfigfilename(dir+'config.xml');
  SaveValueToConfigFile('transmit','padding','/HAMCHAT/');
  SaveValueToConfigFile('transmit','EOT','//EOT//');
  SaveValueToConfigFile('transmit','vox_padding','/ALPHA-BRAVO-ECHO-DELTA');
  SaveValueToConfigFile('transmit','md5_format','/MD5:%s/');
  SaveValueToConfigFile('transmit','time_format','/TIME:%s//');
  SaveValueToConfigFile('user','id','Unknown');
  SaveValueToConfigFile('user','groupid','');
  SaveValueToConfigFile('user','key','temp');
  SaveValueToConfigFile('transmit','modem','QPSK31');
  SaveValueToConfigFile('transmit','encrypt','No');
  SaveValueToConfigFile('options','inbox_reccount','10');
  SaveValueToConfigFile('options','outbox_reccount','10');
  SaveValueToConfigFile('options','buffer_lines','200')

End;

Function tfpchamchat.blowEn(s,keys:String): string;

Var 
  en: TBlowFishEncryptStream;
  s1: TStringStream;
  value,temp: String;
Begin
  s1 := TStringStream.Create('');
  en := TBlowFishEncryptStream.Create(keys,s1);
  en.WriteAnsiString(s);
  en.Free;
  //WriteLn('encrypted: ' + s1.DataString);
  result := s1.DataString;
  s1.Free;
End;

Function tfpchamchat.blowDe(s,keys:String): string;

Var 
  de: TBlowFishDeCryptStream;
  s2: TStringStream;
  temp: String;
Begin
  s2 := TStringStream.Create(s);
  de := TBlowFishDeCryptStream.Create(keys,s2);
  temp := de.ReadAnsiString;
  result := temp;
  de.Free;
  s2.Free;
End;

Procedure tfpchamchat.fldigimenu;

Var 
  am: tmenuline_ver;
Begin
  am := tmenuline_ver.create(screen);
  With am Do
    Begin
      fg := black;
      bg := white;
      selfg := yellow;
      selbg := blue;
      shadow := false;
      add(' Abort    ','','','','abort','A',true,false);
      add(' Clear Rx ','','','','rx','C',true,false);
      add(' Clear Tx ','','','','tx','C',true,false);
      add(' Ver. '+Fldigi_GetVersion,'','','','','',true,false);
    End;
  simplebox(screen,15,10,18,5,blue+lightgray*16,4);
  addshadow(screen,15,10,18,5,darkgray+darkgray*16);
  am.open(16,10);
  Case am.result Of 
    'abort': Fldigi_AbortTx;
    'rx': Fldigi_ClearRx;
    'tx': Fldigi_Cleartx;
  End;
  am.destroy;
End;

Procedure tfpchamchat.optionsmenu;
Var 
  am: tmenuline_ver;
  mi: tmenuinput;
  img: TConsoleImageRec;
Begin
  am := tmenuline_ver.create(screen);
 
  With am Do
    Begin
      fg := black;
      bg := white;
      selfg := yellow;
      selbg := blue;
      shadow := false;
      add(' Inbox Records  ','','','','inrec','I',true,false);
      add(' Outbox Records  ','','','','outrec','O',true,false);
    End;
    repeat
  simplebox(screen,15,9,22,5,blue+lightgray*16,4);
  addshadow(screen,15,9,22,5,darkgray+darkgray*16);
  am.open(16,9);
  
  Case am.result Of 
    'inrec': Begin
			  screen.GetScreenImage(1,1,screenwidth,screenheight,img);
              simplebox(screen,9,8,30,2,red+lightgray*16,4);
              addshadow(screen,9,8,30,2,darkgray+darkgray*16);
              screen.writexy(11,9,black+lightgray*16,'Inbox Records count: ');
              mi := TMenuInput.create(screen);
              mi.fg := yellow;
              mi.bg := red;
              inrec := mi.getnum (32, 9, 3, 3, 1,500,inrec);
              SaveValueToConfigFile('options','inbox_reccount',inrec);
              mi.Destroy;
              screen.putscreenimage(img);
            End;
    'outrec': Begin
			  screen.GetScreenImage(1,1,screenwidth,screenheight,img);
              simplebox(screen,9,8,30,2,red+lightgray*16,4);
              addshadow(screen,9,8,30,2,darkgray+darkgray*16);
              screen.writexy(11,9,black+lightgray*16,'Outbox Records count: ');
              mi := TMenuInput.create(screen);
              mi.fg := yellow;
              mi.bg := red;
              outrec := mi.getnum (32, 9, 3, 3, 1,500,10);
              SaveValueToConfigFile('options','outbox_reccount',outrec);
              mi.Destroy;
              screen.putscreenimage(img);
            End;
  End;
  until am.result='-1';
  am.destroy;
End;

Procedure tfpchamchat.appendmsg(s:String);

Var 
  tfOut: TextFile;
Begin
  If storemsg=false Then exit;
  AssignFile(tfOut, dir+'outbox.txt');
  Try
    If fileexists(dir+'outbox.txt') Then append(tfOut)
    Else rewrite(tfout);
    writeln(tfOut, s);
    CloseFile(tfOut);
  Except
    on E: EInOutError Do
          writeln('File handling error occurred. Details: ', E.Message);
	End;
trimfilerec(dir+'outbox.txt',outrec);
End;

Procedure tfpchamchat.appendincoming(s:String);

Var 
  tfOut: TextFile;
Begin
  If storemsg=false Then exit;
  AssignFile(tfOut, dir+'inbox.txt');
  Try
    If fileexists(dir+'inbox.txt') Then append(tfOut)
    Else rewrite(tfout);
    writeln(tfOut, s);
    CloseFile(tfOut);
  Except
    on E: EInOutError Do
          writeln('File handling error occurred. Details: ', E.Message);
	End;
	trimfilerec(dir+'inbox.txt',inrec);
End;

Procedure tfpchamchat.show;
Begin
  If Assigned (HideImage) Then
    Begin
      screen.PutScreenImage(HideImage^);
      FreeMem (HideImage, SizeOf(TConsoleImageRec));
      HideImage := Nil;
    End;
End;

Procedure tfpchamchat.hide;
Begin
  If Assigned(HideImage) Then FreeMem(HideImage, SizeOf(TConsoleImageRec));

  GetMem (HideImage, SizeOf(TConsoleImageRec));

  screen.GetScreenImage (Image.X1, Image.Y1, Image.X2, Image.Y2, HideImage^);
  screen.PutScreenImage (Image);
End;

Procedure tfpchamchat.bottomline(s:String);

Var 
  xx: string;
Begin
  screen.WriteXYPipe(1,screenheight,yellow+red*16,screenwidth,s);
  //x:='| '+modem;
  If fldigiisrunning Then xx := '| Fldigi: '+Fldigi_GetMode
  Else xx := '| '+modem;
  If lowercase(encrypt)='yes' Then xx := '| Encrypt! '+xx;

  screen.WriteXYPipe(screenwidth-length(xx),screenheight,yellow+red*16,length(xx),xx);
End;

Procedure tfpchamchat.appmenu;

Var 
  am: tmenuline_ver;
  mi: tmenuinput;
  img: TConsoleImageRec;
Begin
  am := tmenuline_ver.create(screen);
  With am Do
    Begin
      fg := black;
      bg := white;
      selfg := yellow;
      selbg := blue;
      shadow := false;
      add(' User           ','','','','user','U',true,false);
      add(' Group          ','','','','group','G',true,false);
      add(' Encryption Key ','','','','key','E',true,false);
      add('-','','','','',' ',true,false);
      add(' Modem          ','','','','modem','M',true,false);
      add(' Encrypt        ','','','','encrypt','E',true,false);
      add(' FlDigi        ','','','','fldigi','F',true,false);
      add('-','','','','',' ',true,false);
      add(' Options        ','','','','options','O',true,false);
      add('-','','','','',' ',true,false);
      add(' Exit  ','','','','exit','E',true,false);
    End;
  repeat  
  simplebox(screen,1,3,20,12,blue+lightgray*16,4);
  addshadow(screen,1,3,20,12,darkgray+darkgray*16);
  am.open(2,3);
  Case am.result Of 
    'user':
            Begin
            screen.GetScreenImage(1,1,screenwidth,screenheight,img);
              simplebox(screen,9,8,22,3,red+lightgray*16,4);
              addshadow(screen,9,8,22,3,darkgray+darkgray*16);
              screen.writexy(15,9,black+lightgray*16,'Call Sign');
              mi := TMenuInput.create(screen);
              mi.fg := yellow;
              mi.bg := red;
              userid := mi.GetStr (10, 10, 21, 21, 1,userid);
              SaveValueToConfigFile('user','id',userid);
              mi.Destroy;
              screen.PutScreenImage(img);
            End;
    'group':
             Begin
             screen.GetScreenImage(1,1,screenwidth,screenheight,img);
               simplebox(screen,9,8,22,3,red+lightgray*16,4);
               addshadow(screen,9,8,22,3,darkgray+darkgray*16);
               screen.writexy(15,9,black+lightgray*16,'Group Name');
               mi := TMenuInput.create(screen);
               mi.fg := yellow;
               mi.bg := red;
               groupid := mi.GetStr (10, 10, 21, 21, 1,groupid);
               SaveValueToConfigFile('user','groupid',groupid);
               mi.Destroy;
               screen.PutScreenImage(img);
             End;
    'key':
           Begin
           screen.GetScreenImage(1,1,screenwidth,screenheight,img);
             simplebox(screen,9,8,22,3,red+lightgray*16,4);
             addshadow(screen,9,8,22,3,darkgray+darkgray*16);
             screen.writexy(13,9,black+lightgray*16,'Encryption Key');
             mi := TMenuInput.create(screen);
             mi.fg := yellow;
             mi.bg := red;
             key := mi.GetStr (10, 10, 21, 21, 1,key);
             key := strStripL(key,' ');
             key := strStripR(key,' ');
             key := strReplace(key,' ','');
             SaveValueToConfigFile('user','key',key);
             mi.Destroy;
             screen.PutScreenImage(img);
           End;
    'encrypt': Begin
				screen.GetScreenImage(1,1,screenwidth,screenheight,img);
                 simplebox(screen,9,8,24,2,red+lightgray*16,4);
                 addshadow(screen,9,8,24,2,darkgray+darkgray*16);
                 screen.writexy(11,9,black+lightgray*16,'Use Encryption?');
                 bottomline('Use Cursor keys to choose.');
                 mi := TMenuInput.create(screen);
                 mi.fg := white;
                 mi.bg := blue;
                 If lowercase(encrypt)='yes' Then encrypt := strYN(mi.GetYN(29, 9,true))
                 Else
                   encrypt := strYN(mi.GetYN(29, 9,false));
                 SaveValueToConfigFile('transmit','encrypt',encrypt);
                 mi.Destroy;
                 If (lowercase(modem)='rtty') And (lowercase(encrypt)='yes') Then
                   Begin
                     addshadow(screen,25,10,30,4,darkgray+darkgray*16);
                     textbox(screen,25,10,30,4,yellow+red*16,4,'Warning!',
                             'Encryption cannot work with the RTTY protocol!');
                   End;
                   screen.PutScreenImage(img);
               End;
    'fldigi':
              Begin
              screen.GetScreenImage(1,1,screenwidth,screenheight,img);
                fldigimenu;screen.PutScreenImage(img);
              End;
    'options': begin
    screen.GetScreenImage(1,1,screenwidth,screenheight,img);
     optionsmenu;screen.PutScreenImage(img);end;
    'exit':
            Begin
              isexit := true;
            End;
    'modem': begin
    screen.GetScreenImage(1,1,screenwidth,screenheight,img);
     modemmenu;screen.PutScreenImage(img);end;
  End;
  until (am.result='-1') or (isexit=true);
End;

Procedure tfpchamchat.modemmenu;

Var 
  mi: tmenuinput;
  xi,yi: byte;
Begin
  xi := 9;
  yi := 8;
  simplebox(screen,xi,yi,22,3,red+lightgray*16,4);
  addshadow(screen,xi,yi,22,3,darkgray+darkgray*16);
  screen.writexy(15,yi+1,black+lightgray*16,'Modem');
  mi := TMenuInput.create(screen);
  bottomline('Press F7 for values or type a custom value.');
  With mi Do
    Begin
      fg := yellow;
      bg := red;
      selfg := white;
      selbg := blue;
      autocomplete := true;
      casesensitive := true;
      list.add('RTTY');
      list.add('CW');
      list.add('QPSK31');
      list.add('QPSK63');
      list.add('QPSK125');
      list.add('QPSK250');
      list.add('QPSK500');
      list.add('PSK125R');
      list.add('PSK250R');
      list.add('PSK500R');
      list.add('PSK1000R');
      list.add('MT63-500S');
      list.add('MT63-500L');
      list.add('MT63-1KS');
      list.add('MT63-1KL');
      list.add('MT63-2KS');
      list.add('MT63-2KL');
      list.add('BPSK31');
      list.add('BPSK63');
      list.add('BPSK125');
      list.add('BPSK250');
      list.add('BPSK500');
      list.add('MFSK16');
      list.add('MFSK4');
      list.add('MFSK8');
      list.add('MFSK11');
      list.add('MFSK22');
      list.add('MFSK32');
      list.add('MFSK64');
      list.add('MFSK128');
      list.add('DOMX4');
      list.add('DOMX8');
      list.add('DOMX11');
      list.add('DOMX22');
      list.add('DOMX44');
      list.add('DOMX88');
      list.add('DOMX5');
      list.add('Olivia-4-250');
      list.add('Olivia-8-250');
      list.add('Olivia-4-500');
      list.add('Olivia-8-500');
      list.add('Olivia-16-500');
      list.add('Olivia-8-1K');
      list.add('Olivia-16-1K');
      list.add('Olivia-32-1K');
      list.add('Olivia-64-1K');
      itemscount := 10;

      modem := GetStr (xi+1, yi+2, 21, 21, 1,modem);
      If modem<>'' Then SaveValueToConfigFile('transmit','modem',modem);
      If modem<>'' Then Fldigi_SetModex(modem);
    End;
  mi.Destroy;

End;


Procedure tfpchamchat.menu;
Begin
  screen.getscreenimage(1,1,screenwidth,screenheight,image);
  appmenu;
  screen.PutScreenImage (Image);
  bottomline('Press ESC for menu...');
End;

Function pathchar(path:utf8string): utf8string;
Begin
  If path[length(path)]<>pathsep Then result := path+pathsep
  Else result := path;
End;

Procedure tfpchamchat.writexy(x1,y1:integer; strs:String);
Begin
  screen.WriteXYPipe(x1,y1,7,strMCILen(strs),strs);
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
  hash: string;
  ouststr: string;
Begin
  If (modem='RTTY') Or (modem='CW') Then ouststr := uppercase(strs)
  Else
    ouststr := strs;
  If lowercase(encrypt)='yes' Then
    Begin
      ouststr := blowen(strs,key);
      ouststr := EncodeStringBase64(ouststr);
      ouststr := '/ENC/'+ouststr;
    End
  Else ouststr := '/MSG/'+ouststr;
  tmp := format(time_format,[inttostr(CurDateDos)]);
  If userid<>'' Then tmp := tmp+'/FROM/'+userid;
  If groupid<>'' Then tmp := tmp+'/GROUP/'+groupid;
  tmp := tmp+ouststr;
  hash := uppercase(MD5print(MD5String(tmp)));
  tmp := vox_padding+padding+format(md5_format,[hash])+ouststr+eot+'^r';
  appendmsg(tmp);
  Fldigi_ClearTx;
  i := 1;
  disablewhiletransmit:=true;
  While i<=length(tmp) Do
    Begin
      Fldigi_SendTxCharacter(tmp[i]);
      Fldigi_StartTx;
      i := i+1;
    End;
  lastmd5 := hash;
  disablewhiletransmit:=false;
  //edit1.SetFocus;
  //Fldigi_StopTx;
End;

Function tfpchamchat.parseincomingtext(mes:String): string;

Var 
  i: integer;
  incoming: string;
Begin
  i := pos(lowercase(eot),lowercase(mes));
  If i>0 Then
    Begin
      incoming := copy(mes,1,i-1);
      parsebuf := '';
      Fldigi_Clearrx;
    End;
  i := pos(lowercase(padding),lowercase(incoming));
  If i>0 Then
    Begin
      incoming := copy(incoming,i+length(padding),length(incoming)-i-length(padding)+1);
      //delete(parsebuf,1,length(padding));
    End;
  rxbuf := '';
  result := incoming;
End;

Function tfpchamchat.getmd5(mes:String): string;

Var 
  RegexObj: TRegExpr;
Begin
  RegexObj := TRegExpr.Create;
  RegexObj.Expression := '([A-F]|[0-9]|[a-f]){32}';
  RegexObj.Exec(mes);
  result := uppercase(regexobj.match[0]);
  RegexObj.Free;
End;

Function tfpchamchat.gettime(mes:String): string;

Var 
  RegexObj: TRegExpr;
Begin
  RegexObj := TRegExpr.Create;
  RegexObj.Expression := '[0-9]{10}';
  RegexObj.Exec(mes);
  result := regexobj.match[0];
  RegexObj.Free;
End;

Procedure tfpchamchat.rxonTimer(Sender : TObject);

Var 
  Dd : TDateTime;
  rxc: char;
  i: integer;
  s,bufstr,md5,dostime,tmp,hash: string;
  msg: thcmessage;

Begin
  Dd := Now-N;
  N := Now;
  //Writeln(FormatDateTime('ss.zzz',Dd),')');
  If Fldigi_IsRunning And fldigiisrunning=false Then
    Begin
      Fldigi_AbortTx;
      Fldigi_SetModex(modem);
      Fldigi_ClearRx;
      Fldigi_ClearTx;
      fldigiisrunning := true;
    End;
  bufstr:='';
  rxbuf := rxbuf + Fldigi_GetRxString;
  For i := 1 To Length(rxbuf) Do
    Begin
      rxc := rxbuf[i];
      If rxc > #127 Then
        parsebuf := parsebuf + utf8encode(string(rxc)) //utf8encode(rxc)
      Else If rxc >= #32 Then
             parsebuf := parsebuf + rxc;
    End;
  s := parseincomingtext(parsebuf);
  If s<>'' Then
    Begin

      md5 := getmd5(s);
      If uppercase(md5)=uppercase(lastmd5) Then
        Begin
          msg.msg := s;
          appendincoming(msg.msg);
          screen.clearscreen;
          msg.time := gettime(s);
          msg.md5 := md5;
          //writeln('Time:'+dostime);
          s := strreplace(s,format(md5_format,[md5]),'');
          //writeln(msg.md5);
          //tmp:=format(time_format,[inttostr(CurDateDos)])+ouststr;
          hash := uppercase(MD5print(MD5String(s)));
          If hash<>msg.md5 Then writeln('HASH doesn''t match: '+hash);
          //writeln('MD5:'+md5);
          s := strreplace(s,format(time_format,[dostime]),'');
          bufstr:='Date: '+DateDos2Str(strs2i(msg.time),2) + ' Time: '+TimeDos2Str(strs2i(msg.time),2);
          //writeln('Date: '+DateDos2Str(strs2i(msg.time),2));
          //writeln('Time: '+TimeDos2Str(strs2i(msg.time),2));
          i := pos('/ENC/',s);
          msg.encode := false;
          If i>0 Then
            Begin
              //s:=strreplace(s,'/ENC/','');
              msg.encode := true;
              //writeln(copy(s,i+5,length(s)-i+5));
              msg.decoded := DecodeStringBase64(copy(s,i+5,length(s)-i+5));
              //writeln(msg.decoded);
              msg.decoded := blowde(msg.decoded,key);
              //writeln('Decoded msg: '+msg.decoded);
              bufstr:=bufstr+' '+msg.decoded;
            End;
          i := pos('/GROUP/',s);
          If i>0 Then
            Begin

              msg.group := copy(s,i+7,length(s)-i+7);
              msg.group := copy(msg.group,1,pos('/',msg.group)-1);
              //writeln('Group: '+msg.group);
              bufstr:=bufstr+'Group: '+msg.group;
              s := strreplace(s,'/GROUP/','');
            End;
          i := pos('/MSG/',s);
          If i>0 Then
            Begin
              //writeln('Message: '+copy(s,i+5,length(s)-i+5));
              bufstr:=bufstr+' '+copy(s,i+5,length(s)-i+5);
              s := strreplace(s,'/MSG/','');
            End;
          i := pos('/TO/',s);
          If i>0 Then
            Begin
              msg.msgto := copy(s,i+4,length(s)-i+4);
              msg.msgto := copy(msg.msgto,1,pos('/',msg.msgto)-1);
              //writeln('Recepient: '+msg.msgto);
              bufstr:=bufstr+' To: '+msg.msgto;
              s := strreplace(s,'/MSG/','');
            End;
            inbuffer.add(bufstr);
            inbuffer.savetofile(dir+'buffer.txt');
          redrawbuffer;
        End;
    End;
End;

Procedure tfpchamchat.ReDraw;

Var 
  T : String;
Begin
  T := Copy(Str, Junk, Field);


  screen.WriteXY  (X, Y, ffg+fbg*16, T);
  screen.WriteXY  (X + Length(T), Y, fselfg+blue*16, strRep(FillChar, Field - Length(T)));

  screen.CursorXY (X + CurPos - 1, screen.CursorY);
End;

Procedure tfpchamchat.ReDrawPart;

Var 
  T : String;
Begin
  T := Copy(Str, StrPos, (Field - CurPos + 1));

  screen.WriteXY  (screen.CursorX, Y, ffg+fbg*16, T);
  screen.WriteXY  (screen.CursorX + Length(T), Y, fselfg+blue*16, strRep(FillChar, (Field - CurPos +
                                                                         1) - Length(T)));

  screen.CursorXY (X + CurPos - 1, Y);
End;

Procedure tfpchamchat.ScrollRight;
Begin
  Inc (Junk);
  If Junk > Length(Str) Then Junk := Length(Str);
  If Junk > Len Then Junk := Len;
  CurPos := StrPos - Junk + 1;
  ReDraw;
End;

Procedure tfpchamchat.ScrollLeft;
Begin
  If Junk > 1 Then
    Begin
      Dec (Junk);
      CurPos := StrPos - Junk + 1;
      ReDraw;
    End;
End;

Procedure tfpchamchat.endkeyf;
Begin
  StrPos := Length(Str) + 1;
  Junk   := Length(Str) - Field + 1;
  If Junk < 1 Then Junk := 1;
  CurPos := StrPos - Junk + 1;
  ReDraw;
End;

Procedure tfpchamchat.Add_Char (Chr : Char);

Var 
  i: integer;
  s1,s2: string;
Begin
  autostr := '';
  If Length(Str) >= Len Then Exit;

  If (CurPos >= Field) And (Field <> Len) Then ScrollRight;

  Insert (Chr, Str, StrPos);
  If StrPos < Length(Str) Then ReDrawPart;

  Inc (StrPos);
  Inc (CurPos);

  screen.WriteXY(screen.CursorX, screen.CursorY, ffg+fbg*16, Chr);

  If auto Then
    If flist.count>0 Then
      Begin
        For i:=0 To flist.count-1 Do
          Begin
            If fcase=false Then
              Begin
                s1 := uppercase(str);
                s2 := uppercase(flist[i]);
              End
            Else
              Begin
                s1 := str;
                s2 := flist[i];
              End;
            If pos(s1,s2)=1 Then
              Begin
                autostr := copy(flist[i],strpos,length(flist[i])-strpos+1);
                If field>curpos Then
                  screen.writexy(x+strpos-1,y,8+fbg*16,copy(autostr,1,field-curpos))
                Else
                  screen.writexy(x+strpos-1,y,8+fbg*16,autostr);
                break;
              End;
          End;
      End;

  screen.CursorXY (screen.CursorX + 1, screen.CursorY);
End;

Procedure tfpchamchat.DoRun;

Var 
  i: byte;
  tmp: string;
  term: boolean;
Begin
  If lowercase(paramstr(1))='-c' Then
    Begin
      createconfig;
      halt;
    End;
  loadsettings;
  dir := pathchar(extractfiledir(paramstr(0)));
  term := false;
  For i:=0 To paramcount Do
    Begin
      tmp := lowercase(paramstr(i));
      If pos('-u',tmp)>0 Then
        Begin
          delete(tmp,1,2);
          userid := tmp;
          term := true;
        End;
      If pos('-g',tmp)>0 Then
        Begin
          delete(tmp,1,2);
          groupid := tmp;
          term := true;
        End;
      If pos('-m',tmp)>0 Then

    Begin
          delete(tmp,1,2);
          modem := tmp;
          term := true;
        End;
      If pos('-k',tmp)>0 Then
        Begin
          delete(tmp,1,2);
          key := tmp;
          term := true;
        End;
      If pos('-e',tmp)>0 Then
        Begin
          delete(tmp,1,2);
          encrypt := tmp;
          term := true;
        End;
      If pos('-t',tmp)>0 Then
        Begin
          delete(tmp,1,2);
          touserid := tmp;
          term := true;
        End;
      If (pos('-h',tmp)>0) Then // Or (pos('-help',tmp)>0) Or (pos('--help',tmp)>0) Or (pos('/h',tmp)>0) Or (pos('/?',tmp)>0)
        Begin
          helpscreen;
          halt(1);
        End;
    End;

  If (term=true) then 
	if (fldigi_isrunning=true) Then
    Begin
      Fldigi_AbortTx;
      Fldigi_SetModex(modem);
      Fldigi_ClearRx;
      Fldigi_ClearTx;
      transmittext(paramstr(paramcount));
      halt(0);
    End
  Else
    Begin
      writeln('[hamchat] FlDigi is not active. Cannot send message. Aborting!');
      halt(-1);
    End;

  isexit := false;
  Screen := TOutput.Create(True);
  Input  := TInput.Create;
  enable_ansi_unix;
  screen.getoriginaltermsize;
  Screen.ClearScreen;
  HideImage  := Nil;

  rxtimer := TFPTimer.Create(self);
  rxtimer.interval := 1000;
  rxtimer.ontimer := @rxonTimer;
  rxtimer.starttimer;
  If fldigi_isrunning=false Then textbox(screen, 20, 10, 40, 5, white+green*16, 4,' Warning... ',
                                  'Fldigi is not active! Run the program to be able to use Hamchat.'
    );
  flist := tstringlist.create;
  inbuffer := tstringlist.create;
  if fileexists(dir+'buffer.txt') then inbuffer.loadfromfile(dir+'buffer.txt');
  redrawbuffer;
  Try
    FTick := 0;
    FCount := 0;
    N := Now;
    bottomline('Press ESC for menu...');
    screen.TextAttr := white+green*16;
    screen.cursorxy(1,screenheight-1);
    screen.ClearEOL;
    command := '';
    Str     := '';
    StrPos  := Length(Str) + 1;
    Junk    := Length(Str) - Field + 1;
    If Junk < 1 Then Junk := 1;
    CurPos  := StrPos - Junk + 1;
    screen.CursorXY (X, Y);
    screen.TextAttr := ffg+fbg*16;
    Repeat
      ReDraw;
      If input.keypressed Then
        Begin
          c := input.readkey;
          Case C Of 
            #00 :
                  Begin
                    C := input.ReadKey;

                    Case C Of 
                      #66:
                           Begin
                             auto := Not auto;
                             bb := tbox.create(screen);
                             bb.title := 'Info';
                             If auto Then bb.text := 'Autocomplete is ON'
                             Else bb.text := 'Autocomplete is OFF';
                             bb.shadow := true;
                             bb.open((screenwidth Div 2) - 13,(screenheight Div 2) - 2,26,3,attr,1);
                             input.keywait(700);
                             bb.close;
                             bb.free;
                           End;
                      #77 : If StrPos < Length(Str) + 1 Then
                              Begin
                                If (CurPos = Field) And (StrPos < Length(Str)) Then ScrollRight;
                                Inc (CurPos);
                                Inc (StrPos);
                                screen.CursorXY (screen.CursorX + 1, screen.CursorY);
                              End;
                      #75 : If StrPos > 1 Then
                              Begin
                                If CurPos = 1 Then ScrollLeft;
                                Dec (StrPos);
                                Dec (CurPos);
                                screen.CursorXY (screen.CursorX - 1, screen.CursorY);
                              End;
                      #71 : If StrPos > 1 Then
                              Begin
                                StrPos := 1;
                                Junk   := 1;
                                CurPos := 1;
                                ReDraw;
                              End;
                      #79 :
                            Begin
                              endkeyf;
                            End;
                      #83 : If (StrPos <= Length(Str)) And (Length(Str) > 0) Then
                              Begin
                                Delete (Str, StrPos, 1);
                                ReDrawPart;
                              End;
                      #115:
                            Begin
                              If (StrPos > 1) And (Str[StrPos] = ' ') Or (Str[StrPos - 1] = ' ')
                                Then
                                Begin
                                  If CurPos = 1 Then ScrollLeft;
                                  Dec(StrPos);
                                  Dec(CurPos);

                                  While (StrPos > 1) And (Str[StrPos] = ' ') Do
                                    Begin
                                      If CurPos = 1 Then ScrollLeft;
                                      Dec(StrPos);
                                      Dec(CurPos);
                                    End;
                                End;

                              While (StrPos > 1) And (Str[StrPos] <> ' ') Do
                                Begin
                                  If CurPos = 1 Then ScrollLeft;
                                  Dec(StrPos);
                                  Dec(CurPos);
                                End;

                              While (StrPos > 1) And (Str[StrPos] <> ' ') Do
                                Begin
                                  If CurPos = 1 Then ScrollLeft;
                                  Dec(StrPos);
                                  Dec(CurPos);
                                End;

                              If (Str[StrPos] = ' ') And (StrPos > 1) Then
                                Begin
                                  Inc(StrPos);
                                  Inc(CurPos);
                                End;

                              ReDraw;
                            End;
                      #116:
                            Begin
                              While StrPos < Length(Str) + 1 Do
                                Begin
                                  If (CurPos = Field) And (StrPos < Length(Str)) Then ScrollRight;
                                  Inc (CurPos);
                                  Inc (StrPos);

                                  If Str[StrPos] = ' ' Then
                                    Begin
                                      If StrPos < Length(Str) + 1 Then
                                        Begin
                                          If (CurPos = Field) And (StrPos < Length(Str)) Then
                                            ScrollRight;
                                          Inc (CurPos);
                                          Inc (StrPos);
                                        End;
                                      Break;
                                    End;
                                End;
                              screen.CursorXY (X + CurPos - 1, Y);
                            End;
                      Else
                        If Pos(C, HiChars) > 0 Then
                          Begin
                            ExitCode := C;
                            //Break;
                          End;
                    End;
                  End;
            #08 : If StrPos > 1 Then
                    Begin
                      Dec (StrPos);
                      Delete (Str, StrPos, 1);
                      If CurPos = 1 Then
                        ScrollLeft
                      Else
                        Begin
                          screen.CursorXY (screen.CursorX - 1, screen.CursorY);
                          Dec (CurPos);
                          ReDrawPart;
                        End;
                    End;
            #09 :
                  Begin
                    If autostr<>'' Then str := str+autostr;
                    strpos := length(str)+1;
                    curpos := strpos;
                    redraw;
                    endkeyf;
                  End;
            ^Y  :
                  Begin
                    Str    := '';
                    StrPos := 1;
                    Junk   := 1;
                    CurPos := 1;
                    ReDraw;
                  End;
            #13:
                 Begin
                   if disablewhiletransmit = false then begin
                   If strstripb(str,' ')<>'' Then transmittext(str);
                   str := '';
                   StrPos  := Length(Str) + 1;
                   Junk    := Length(Str) - Field + 1;
                   If Junk < 1 Then Junk := 1;
                   CurPos  := StrPos - Junk + 1;
                   screen.CursorXY (X, Y);
                   end else bottomline('Transmitting data. Please wait...');
                 End;
            #3: isexit := true;
            #27,#196,#140,#178: menu;
            #32..
            #126: Case Mode Of 
                    0 : If C In ['0'..'9', '-'] Then Add_Char(C);
                    1 : Add_Char (C);
                    2 : Add_Char (UpCase(C));
                    3 : If (C > '/') And (C < ':') Then
                          Case StrPos Of 
                            2,5 :
                                  Begin
                                    Add_Char (C);
                                    Add_Char ('/');
                                  End;
                            3,6 :
                                  Begin
                                    Add_Char ('/');
                                    Add_Char (C);
                                  End;
                            Else
                              Add_Char (Ch);
                          End;
                  End;
            Else
              If Pos(C, LoChars) > 0 Then
                Begin
                  ExitCode := C;
                  //Break;
                End;
          End;
        End;
      Sleep(1);
      CheckSynchronize;
      // Needed, because we are not running in a GUI loop.
    Until isexit=true;
  Finally
    rxTimer.Enabled := False;
    FreeAndNil(rxTimer);
    flist.free;

End;
screen.textattr := 7;
screen.clearscreen;
//displayansi('loading.ans',wait);
screen.free;
inbuffer.free;
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
