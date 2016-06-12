// ====================================================================
// Mystic BBS Software               Copyright 1997-2013 By James Coyle
// ====================================================================
//
// This file is part of Mystic BBS.
//
// Mystic BBS is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Mystic BBS is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Mystic BBS.  If not, see <http://www.gnu.org/licenses/>.
//
// ====================================================================
{$I M_OPS.PAS}

Unit f_dMenuInput;

Interface

Uses
  classes,
  m_types,
  f_Strings,
  m_Input,
  f_Output;

Type
  TdMenuInput = Class
  Private
    Console  : TOutput;
  Public
    Key      : TInput;
    HiChars  : String;
    LoChars  : String;
    ExitCode : Char;
    Attr     : Byte;
    FillChar : Char;
    FillAttr : Byte;
    Changed  : Boolean;
    fpass    : boolean;
    Str    : String;
  StrPos : Integer;
  Junk   : Integer;
  CurPos : Integer;

   flist    : tstringlist;
    ficount  : byte;
    fsel     : integer;
    findex   : integer;
    image    : tconsoleimagerec;
    fselfg,fselbg,ffg,fbg:byte;
    visiblelist:boolean;
    auto:boolean;
    fcase:boolean;
    autostr:string;

    Constructor Create (Var Screen: TOutput);
    Destructor  Destroy; Override;
    procedure   Hidelist;
    procedure   Showlist(x,y,width:byte);
    Function    GetStr (X, Y, Field, Len, Mode : Byte; var Default : String;ch:char) : String;
    Function    GetChar (X, Y : Byte; Default: Char) : Char;
    Function    GetEnter (X, Y, Len: Byte; Default : String) : Boolean;
    Function    GetYN (X, Y : Byte; Default: Boolean) : Boolean;

    Function    KeyWaiting : Boolean;
    Function    ReadKey : Char;
    property    password:boolean read fpass write fpass;
    property    list:tstringlist read flist write flist;
    property    itemscount:byte read ficount write ficount;
    property    selected:integer read fsel write fsel;
    property    selfg:byte read fselfg write fselfg;
    property    selbg:byte read fselbg write fselbg;
    property    fg:byte read ffg write ffg;
    property    bg:byte read fbg write fbg;
    property    autocomplete:boolean read auto write auto;
    property    casesensitive:boolean read fcase write fcase;
  End;

Implementation

uses f_boxes;

Constructor TdMenuInput.Create (Var Screen: TOutput);
Begin
  Inherited Create;

  Console  := Screen;
  Key      := TInput.Create;
  LoChars  := #13;
  HiChars  := '';
  ffg:=white;
  fbg:=green;
  fselfg:=yellow;
  fselbg:=red;
  Attr     := ffg+fbg*16;//7 + 5 * 16;
  FillAttr := fselfg+fselbg*16;//  + 5 * 16;
  FillChar := ' ';
  Changed  := False;
  fpass:=false;
  ficount:=5;
  fcase:=false;
  Changed := False;
  
  
  visiblelist:=false;
  auto:=false;
  autostr:='';
  flist:=tstringlist.create;
End;

Destructor TdMenuInput.Destroy;
Begin
  Key.Free;

 flist.free;
  Inherited Destroy;
End;

procedure TdMenuInput.hidelist;
begin
  visiblelist:=false;
  console.putscreenimage(image);
end;

procedure TdMenuInput.showlist(x,y,width:byte);
var
  a,b,i,w:byte;
  thumbs,idx,sel:integer;
  c:char;
  ok:boolean;
  s:string;
  x1,y1:byte;

begin
  if flist.count=0 then exit;
  console.getscreenimage(1,1,screenwidth,screenheight,image);
  visiblelist:=true;
  ok:=false;
  sel:=0;
  idx:=0;
  w:=length(flist[0]);//length(items[0][0]);
  if x+w+2>screenwidth then x1:=screenwidth-w-2 else x1:=x;
  if y+2+ficount>screenheight then y1:=screenheight-ficount-2 else y1:=y+1;
  repeat
  //textcolor(fg);textbackground(bg);
  console.textattr:=ffg+fbg*16;
  console.cursorxy(x1,y1);
  if idx>0 then begin
      for a:=0 to width-1 do console.writechar('-');
    end else
      for a:=0 to width-1 do console.writechar(' ');
  console.cursorxy(x1,y1+ficount+1);
  if idx+ficount<flist.count then
    begin
      for a:=0 to width-1 do console.writechar('-');
    end else
      for a:=0 to width-1 do console.writechar(' ');
  {
  for i:=0 to ficount-1 do begin
    if idx+i=sel then begin
          //textcolor(selfg);textbackground(selbg);
          console.writexy(x1,y1+1+i,fselfg+fselbg*16,strpadr(flist[idx+i],width,' '));
          end else begin
          //textcolor(fg);textbackground(bg);
          console.writexy(x1,y1+1+i,ffg+fbg*16,strpadr(flist[idx+i],width,' '));
    end;
   end;
   }
   for i:=0 to ficount-1 do begin
    if idx+i<=flist.count-1 then begin
    	if idx+i=sel then begin
          //textcolor(selfg);textbackground(selbg);
            console.writexy(x1,y1+1+i,fselfg+fselbg*16,strpadr(flist[idx+i],width,' '));
        	end else begin
          //textcolor(fg);textbackground(bg);
            console.writexy(x1,y1+1+i,ffg+fbg*16,strpadr(flist[idx+i],width,' '));
        	end;
    end  else begin
          console.writexy(x1,y1+1+i,ffg+fbg*16,strrep(' ',width));
       end;
   end;


  addshadow(console,x1,y1,width-1,ficount+1,shadowattr);
  C := Key.ReadKey;
  case c of
  #73: begin //page up
           sel:=sel-ficount;
           if sel<0 then sel:=0;
           idx:=sel;
           if idx<=0 then idx:=0;
           if idx>=flist.count-ficount-1 then idx:=flist.count-ficount-1;
           if flist.count-1<ficount then idx:=0;    
  end;
  #81: begin //pagedown
           sel:=sel+ficount;
           if sel>flist.count-1 then sel:=flist.count-1;
           idx:=sel;
           if idx>=flist.count-ficount then idx:=flist.count-ficount;
           if flist.count-1<ficount then idx:=0;
  end;
  #75  : begin fsel:=-1;ok:=true;end;  //left
  #77  : begin fsel:=-1;ok:=true;end;//right
  #72  : begin //up
           sel:=sel-1;
           if sel<0 then sel:=0;
           idx:=sel;
           if idx<=0 then idx:=0;
           if idx>=flist.count-ficount-1 then idx:=flist.count-ficount-1;
           if flist.count-1<ficount then idx:=0;
    end;
  #80  : begin //down
           sel:=sel+1;
           if sel>flist.count-1 then sel:=flist.count-1;
           idx:=sel;
           if idx>=flist.count-ficount then idx:=flist.count-ficount;
           if flist.count-1<ficount then idx:=0;
    end;
    #13: begin fsel:=sel;ok:=true;end;
    #27: begin fsel:=-1;ok:=true;end;
  end;
  until ok;

end;

Function TdMenuInput.GetYN (X, Y : Byte; Default: Boolean) : Boolean;
Var
  Ch  : Char;
  Res : Boolean;
  YS  : Array[False..True] of String[3] = ('No ', 'Yes');
Begin
  ExitCode := #0;
  Changed  := False;

  Console.CursorXY (X, Y);

  Res := Default;

  Repeat
    Console.WriteXY (X, Y, ffg+fbg*16, YS[Res]);

    Ch := ReadKey;
    Case Ch of
      #00 : Begin
              Ch := ReadKey;
              case ch of
                #77,#75,#72,#80 : res:=not res;
              end;
              If Pos(Ch, HiChars) > 0 Then Begin
                ExitCode := Ch;
                Break;
              End;
            End;

      #13 : break;
      #32 : Res := Not Res;
    Else
      If Pos(Ch, LoChars) > 0 Then Begin
        ExitCode := Ch;
        Break;
      End;
    End;
  Until False;

  Changed := (Res <> Default);
  GetYN   := Res;
End;

Function TdMenuInput.GetChar (X, Y : Byte; Default: Char) : Char;
Var
  Ch  : Char;
  Res : Char;
Begin
  ExitCode := #0;
  Changed  := False;
  Res      := Default;

  Console.CursorXY (X, Y);

  Repeat
    Console.WriteXY (X, Y, ffg+fbg*16, Res);

    Ch := ReadKey;

    Case Ch of
      #00 : Begin
              Ch := ReadKey;
              If Pos(Ch, HiChars) > 0 Then Begin
                ExitCode := Ch;
                Break;
              End;
            End;
    Else
      If Ch = #27 Then Res := Default;

      If Pos(Ch, LoChars) > 0 Then Begin
        ExitCode := Ch;
        Break;
      End;

      If Ord(Ch) > 31 Then Res := Ch;
    End;
  Until False;

  GetChar := Res;
End;

Function TdMenuInput.GetEnter (X, Y, Len: Byte; Default : String) : Boolean;
Var
  Ch  : Char;
  Res : Boolean;
Begin
  ExitCode := #0;
  Changed  := False;

  Console.WriteXY (X, Y, ffg+fbg*16, strPadR(Default, Len, ' '));
  Console.CursorXY (X, Y);

  Repeat
    Ch  := ReadKey;
    Res := Ch = #13;
    Case Ch of
      #00 : Begin
              Ch := ReadKey;
              If Pos(Ch, HiChars) > 0 Then Begin
                ExitCode := Ch;
                Break;
              End;
            End;
      Else
        If Pos(Ch, LoChars) > 0 Then Begin
          ExitCode := Ch;
          Break;
        End;
    End;
  Until Res;

  Changed  := Res;
  GetEnter := Res;
End;

Function TdMenuInput.GetStr (X, Y, Field, Len, Mode : Byte; var Default : String;ch:char) : String;
{ mode options:      }
{   0 = numbers only }
{   1 = as typed     }
{   2 = all caps     }
{   3 = date input   }
Var
  //Ch     : Char;
{
  Str    : String;
  StrPos : Integer;
  Junk   : Integer;
  CurPos : Integer;
}
  bb:tbox;

  Procedure ReDraw;
  Var
    T : String;
  Begin
    T := Copy(Str, Junk, Field);

   if not fpass then begin
    Console.WriteXY  (X, Y, ffg+fbg*16, T);
    Console.WriteXY  (X + Length(T), Y, fselfg+blue*16, strRep(FillChar, Field - Length(T)));
    end else begin
    Console.WriteXY  (X, Y, ffg+fbg*16, strrep('#',length(t)));
    Console.WriteXY  (X + Length(T), Y, fselfg+fselbg*16, strRep(FillChar, Field - Length(T)));
    end;
    Console.CursorXY (X + CurPos - 1, Console.CursorY);
  End;

  Procedure ReDrawPart;
  Var
    T : String;
  Begin
    T := Copy(Str, StrPos, Field - CurPos + 1);

    if not fpass then begin
    Console.WriteXY  (Console.CursorX, Y, ffg+fbg*16, T);
    Console.WriteXY  (Console.CursorX + Length(T), Y, fselfg+blue*16, strRep(FillChar, (Field - CurPos + 1) - Length(T)));
    end else begin
    Console.WriteXY  (Console.CursorX, Y, ffg+fbg*16, strrep('#',length(t)));
    Console.WriteXY  (Console.CursorX + Length(T), Y, fselfg+fselbg*16, strRep(FillChar, (Field - CurPos + 1) - Length(T)));
    end;
    Console.CursorXY (X + CurPos - 1, Y);
  End;

  Procedure ScrollRight;
  Begin
    Inc (Junk);
    If Junk > Length(Str) Then Junk := Length(Str);
    If Junk > Len then Junk := Len;
    CurPos := StrPos - Junk + 1;
    ReDraw;
  End;

  Procedure ScrollLeft;
  Begin
    If Junk > 1 Then Begin
      Dec (Junk);
      CurPos := StrPos - Junk + 1;
      ReDraw;
    End;
  End;

procedure endkeyf;
begin
  StrPos := Length(Str) + 1;
  Junk   := Length(Str) - Field + 1;
  If Junk < 1 Then Junk := 1;
  CurPos := StrPos - Junk + 1;
  ReDraw;
end;

  Procedure Add_Char (Ch : Char);
  var
    i:integer;
    s1,s2:string;
  Begin
    autostr:='';
    If Length(Str) >= Len Then Exit;

    If (CurPos >= Field) and (Field <> Len) Then ScrollRight;

    Insert (Ch, Str, StrPos);
    If StrPos < Length(Str) Then ReDrawPart;

    Inc (StrPos);
    Inc (CurPos);

    if not fpass then Console.WriteXY(Console.CursorX, Console.CursorY, ffg+fbg*16, Ch) else
       Console.WriteXY(Console.CursorX, Console.CursorY, ffg+fbg*16, '#');
    
    if auto then
      if flist.count>0 then begin
        for i:=0 to flist.count-1 do begin
            if fcase=false then begin
              s1:=strupper(str);
              s2:=strupper(flist[i]);
            end else begin
              s1:=str;
              s2:=flist[i];
            end;
            if pos(s1,s2)=1 then begin
            autostr:=copy(flist[i],strpos,length(flist[i])-strpos+1);
            if field>curpos then
              console.writexy(x+strpos-1,y,8+fbg*16,copy(autostr,1,field-curpos))
              else
              console.writexy(x+strpos-1,y,8+fbg*16,autostr);
            break;
          end;
        end;
      end;

    Console.CursorXY (Console.CursorX + 1, Console.CursorY);
  End;

Begin
  //Changed := False;
  Str     := Default;
  StrPos  := Length(Str) + 1;
  Junk    := Length(Str) - Field + 1;

  If Junk < 1 Then Junk := 1;

  CurPos  := StrPos - Junk + 1;

  //Console.CursorXY (X, Y);
  Console.TextAttr := ffg+fbg*16;

  ReDraw;

  //Repeat
    //if key.keypressed then begin
    //Ch := Key.ReadKey;

    Case Ch of
      #00 : Begin
              Ch := Key.ReadKey;

              Case Ch of
                #65 : if visiblelist=false then begin
                        if flist.count<>0 then begin
                        flist.sort;
                        showlist(x,y,field);
                        hidelist;
                        if fsel<>-1 then begin
                          str:=flist[fsel];
                          curpos:=length(flist[fsel])+1;
                          strpos:=curpos;
                          endkeyf;
                          redraw;
                          //console.cursorxy(x+curpos,y);
                          end;
                         end;
                        end;
                #66: begin
                       auto:=not auto;
                       bb:=tbox.create(console);
	               bb.title:='Info';
                       if auto then bb.text:='Autocomplete is ON' else bb.text:='Autocomplete is OFF';
                       bb.shadow:=true;
                       bb.open((screenwidth div 2) - 13,(screenheight div 2) - 2,26,3,attr,1);
                       key.keywait(700);
                       bb.close;
                       bb.free;
                     end;
                #77 : If StrPos < Length(Str) + 1 Then Begin
                        If (CurPos = Field) and (StrPos < Length(Str)) Then ScrollRight;
                        Inc (CurPos);
                        Inc (StrPos);
                        Console.CursorXY (Console.CursorX + 1, Console.CursorY);
                      End;
                #75 : If StrPos > 1 Then Begin
                        If CurPos = 1 Then ScrollLeft;
                        Dec (StrPos);
                        Dec (CurPos);
                        Console.CursorXY (Console.CursorX - 1, Console.CursorY);
                      End;
                #71 : If StrPos > 1 Then Begin
                        StrPos := 1;
                        Junk   := 1;
                        CurPos := 1;
                        ReDraw;
                      End;
                #79 : Begin
                        endkeyf;
                      End;
                #83 : If (StrPos <= Length(Str)) and (Length(Str) > 0) Then Begin
                        Delete (Str, StrPos, 1);
                        ReDrawPart;
                      End;
                #115: Begin
                        If (StrPos > 1) and (Str[StrPos] = ' ') or (Str[StrPos - 1] = ' ') Then Begin
                          If CurPos = 1 Then ScrollLeft;
                          Dec(StrPos);
                          Dec(CurPos);

                          While (StrPos > 1) and (Str[StrPos] = ' ') Do Begin
                            If CurPos = 1 Then ScrollLeft;
                            Dec(StrPos);
                            Dec(CurPos);
                          End;
                        End;

                        While (StrPos > 1) and (Str[StrPos] <> ' ') Do Begin
                          If CurPos = 1 Then ScrollLeft;
                          Dec(StrPos);
                          Dec(CurPos);
                        End;

                        While (StrPos > 1) and (Str[StrPos] <> ' ') Do Begin
                          If CurPos = 1 Then ScrollLeft;
                          Dec(StrPos);
                          Dec(CurPos);
                        End;

                        If (Str[StrPos] = ' ') and (StrPos > 1) Then Begin
                          Inc(StrPos);
                          Inc(CurPos);
                        End;

                        ReDraw;
                      End;
                #116: Begin
                        While StrPos < Length(Str) + 1 Do Begin
                          If (CurPos = Field) and (StrPos < Length(Str)) Then ScrollRight;
                          Inc (CurPos);
                          Inc (StrPos);

                          If Str[StrPos] = ' ' Then Begin
                            If StrPos < Length(Str) + 1 Then Begin
                              If (CurPos = Field) and (StrPos < Length(Str)) Then ScrollRight;
                              Inc (CurPos);
                              Inc (StrPos);
                            End;
                            Break;
                          End;
                        End;
                        Console.CursorXY (X + CurPos - 1, Y);
                      End;
              Else
                If Pos(Ch, HiChars) > 0 Then Begin
                  ExitCode := Ch;
                  //Break;
                End;
              End;
            End;
      #08 : If StrPos > 1 Then Begin
              Dec (StrPos);
              Delete (Str, StrPos, 1);
              If CurPos = 1 Then
                ScrollLeft
              Else Begin
                Console.CursorXY (Console.CursorX - 1, Console.CursorY);
                Dec (CurPos);
                ReDrawPart;
              End;
            End;
      #09 : begin
              if autostr<>'' then str:=str+autostr;
              strpos:=length(str)+1;
              curpos:=strpos;
              redraw;
              endkeyf;
            end;      
      ^Y  : Begin
              Str    := '';
              StrPos := 1;
              Junk   := 1;
              CurPos := 1;
              ReDraw;
            End;
      #32..
      #254: Case Mode of
              0 : If Ch in ['0'..'9', '-'] Then Add_Char(Ch);
              1 : Add_Char (Ch);
              2 : Add_Char (UpCase(Ch));
              3 : If (Ch > '/') and (Ch < ':') Then
                    Case StrPos of
                      2,5 : Begin
                              Add_Char (Ch);
                              Add_Char ('/');
                            End;
                      3,6 : Begin
                              Add_Char ('/');
                              Add_Char (Ch);
                            End;
                    Else
                      Add_Char (Ch);
                    End;
            End;
    Else
      If Pos(Ch, LoChars) > 0 Then Begin
        ExitCode := Ch;
        //Break;
       End;
    End;
    //end;
  //Until False;

  //Changed := (Str <> Default);
  Result  := Str;
End;

Function TdMenuInput.KeyWaiting : Boolean;
Begin
  Result := Key.KeyPressed;
End;

Function TdMenuInput.ReadKey : Char;
Begin
  Result := Key.ReadKey;
End;

End.
