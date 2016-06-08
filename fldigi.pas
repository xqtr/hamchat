unit fldigi;

{$mode objfpc}{$H+}

//  Copyright (c) 2008 Julian Moss, G4ILO  (www.g4ilo.com)                           //
//  Released under the GNU GPL v2.0 (www.gnu.org/licenses/old-licenses/gpl-2.0.txt)  //

(* Fldigi communication unit - uses XML-RPC protocol.

   Supported methods:

	methods->push_back(rpc_method(new Fldigi_list, "fldigi.list"));
	methods->push_back(rpc_method(new Fldigi_name, "fldigi.name"));
	methods->push_back(rpc_method(new Fldigi_version_struct, "fldigi.version_struct"));
	methods->push_back(rpc_method(new Fldigi_version_string, "fldigi.version"));
	methods->push_back(rpc_method(new Fldigi_name_version, "fldigi.name_version"));

	methods->push_back(rpc_method(new Modem_get_name, "modem.get_name"));
	methods->push_back(rpc_method(new Modem_get_names, "modem.get_names"));
	methods->push_back(rpc_method(new Modem_get_id, "modem.get_id"));
	methods->push_back(rpc_method(new Modem_get_max_id, "modem.get_max_id"));
	methods->push_back(rpc_method(new Modem_set_by_name, "modem.set_by_name"));
	methods->push_back(rpc_method(new Modem_set_by_id, "modem.set_by_id"));

	methods->push_back(rpc_method(new Modem_set_carrier, "modem.set_carrier"));
	methods->push_back(rpc_method(new Modem_inc_carrier, "modem.inc_carrier"));
	methods->push_back(rpc_method(new Modem_get_carrier, "modem.get_carrier"));

	methods->push_back(rpc_method(new Modem_get_afc_sr, "modem.get_afc_search_range"));
	methods->push_back(rpc_method(new Modem_set_afc_sr, "modem.set_afc_search_range"));
	methods->push_back(rpc_method(new Modem_inc_afc_sr, "modem.inc_afc_search_range"));

	methods->push_back(rpc_method(new Modem_get_bw, "modem.get_bandwidth"));
	methods->push_back(rpc_method(new Modem_set_bw, "modem.set_bandwidth"));
	methods->push_back(rpc_method(new Modem_inc_bw, "modem.inc_bandwidth"));

	methods->push_back(rpc_method(new Modem_get_quality, "modem.get_quality"));
	methods->push_back(rpc_method(new Modem_search_up, "modem.search_up"));
	methods->push_back(rpc_method(new Modem_search_down, "modem.search_down"));

	methods->push_back(rpc_method(new Main_get_status1, "main.get_status1"));
	methods->push_back(rpc_method(new Main_get_status2, "main.get_status2"));

	methods->push_back(rpc_method(new Main_get_sb, "main.get_sideband"));
	methods->push_back(rpc_method(new Main_get_freq, "main.get_frequency"));
	methods->push_back(rpc_method(new Main_set_freq, "main.set_frequency"));
	methods->push_back(rpc_method(new Main_inc_freq, "main.inc_frequency"));

	methods->push_back(rpc_method(new Main_get_afc, "main.get_afc"));
	methods->push_back(rpc_method(new Main_set_afc, "main.set_afc"));
	methods->push_back(rpc_method(new Main_toggle_afc, "main.toggle_afc"));

	methods->push_back(rpc_method(new Main_get_sql, "main.get_squelch"));
	methods->push_back(rpc_method(new Main_set_sql, "main.set_squelch"));
	methods->push_back(rpc_method(new Main_toggle_sql, "main.toggle_squelch"));

	methods->push_back(rpc_method(new Main_get_sql_level, "main.get_squelch_level"));
	methods->push_back(rpc_method(new Main_set_sql_level, "main.set_squelch_level"));
	methods->push_back(rpc_method(new Main_inc_sql_level, "main.inc_squelch_level"));

	methods->push_back(rpc_method(new Main_get_rev, "main.get_reverse"));
	methods->push_back(rpc_method(new Main_set_rev, "main.set_reverse"));
	methods->push_back(rpc_method(new Main_toggle_rev, "main.toggle_reverse"));

	methods->push_back(rpc_method(new Main_get_lock, "main.get_lock"));
	methods->push_back(rpc_method(new Main_set_lock, "main.set_lock"));
	methods->push_back(rpc_method(new Main_toggle_lock, "main.toggle_lock"));

	methods->push_back(rpc_method(new Main_get_trx_status, "main.get_trx_status"));
	methods->push_back(rpc_method(new Main_tx, "main.tx"));
	methods->push_back(rpc_method(new Main_tune, "main.tune"));
	methods->push_back(rpc_method(new Main_rsid, "main.rsid"));
	methods->push_back(rpc_method(new Main_rx, "main.rx"));
	methods->push_back(rpc_method(new Main_abort, "main.abort"));

	methods->push_back(rpc_method(new Main_run_macro, "main.run_macro"));
	methods->push_back(rpc_method(new Main_get_max_macro_id, "main.get_max_macro_id"));

	methods->push_back(rpc_method(new Log_get_freq, "log.get_frequency"));
	methods->push_back(rpc_method(new Log_get_time, "log.get_time"));
	methods->push_back(rpc_method(new Log_get_call, "log.get_call"));
	methods->push_back(rpc_method(new Log_get_name, "log.get_name"));
	methods->push_back(rpc_method(new Log_get_rst_in, "log.get_rst_in"));
	methods->push_back(rpc_method(new Log_get_rst_out, "log.get_rst_out"));
	methods->push_back(rpc_method(new Log_get_qth, "log.get_qth"));
	methods->push_back(rpc_method(new Log_get_band, "log.get_band"));
	methods->push_back(rpc_method(new Log_get_sb, "log.get_sideband"));
	methods->push_back(rpc_method(new Log_get_notes, "log.get_notes"));
	methods->push_back(rpc_method(new Log_get_locator, "log.get_locator"));
	methods->push_back(rpc_method(new Log_get_az, "log.get_az"));
	methods->push_back(rpc_method(new Log_clear, "log.clear"));

	methods->push_back(rpc_method(new Text_get_rx_length, "text.get_rx_length"));
	methods->push_back(rpc_method(new Text_get_rx, "text.get_rx"));
	methods->push_back(rpc_method(new Text_clear_rx, "text.clear_rx"));
	methods->push_back(rpc_method(new Text_add_tx, "text.add_tx"));
	methods->push_back(rpc_method(new Text_add_tx_bytes, "text.add_tx_bytes"));
	methods->push_back(rpc_method(new Text_clear_tx, "text.clear_tx"));
 *)

interface

uses
  {$IFDEF WINDOWS}Windows,{$ENDIF} Classes, SysUtils;

function Fldigi_IsRunning: boolean;
function Fldigi_GetVersion: string;

function Fldigi_GetStatus1: string; // returns contents of 1st status bar panel
function Fldigi_GetStatus2: string; // returns contents of 2nd status bar panel

function Fldigi_GetFrequency: double;
procedure Fldigi_SetFrequency( frequency: double );
procedure Fldigi_ChangeFrequency( increment: double );

function Fldigi_GetQSOFrequency: double;

function Fldigi_IsAFC: boolean;
procedure Fldigi_SetAFC( state: boolean);

function Fldigi_IsSquelch: boolean;
procedure Fldigi_SetSquelch( state: boolean);

function Fldigi_IsLock: boolean;
procedure Fldigi_SetLock( state: boolean);

function Fldigi_IsReverse: boolean;
procedure Fldigi_SetReverse( state: boolean);

function Fldigi_GetCarrier: integer;
procedure Fldigi_SetCarrier( carrier: integer );
procedure Fldigi_ChangeCarrier( increment: integer );

function Fldigi_GetMode: string;
procedure Fldigi_SetMode( mode: string );
function Fldigi_ListModes: string;
function Fldigi_GetBandwidth: integer;

procedure Fldigi_ClearRx;
function Fldigi_RxCharsWaiting: boolean;
function Fldigi_GetRxString: string;

procedure Fldigi_StartTx;
procedure Fldigi_StopTx;
procedure Fldigi_AbortTx;
procedure Fldigi_Tune;
function Fldigi_IsTx: boolean;

procedure Fldigi_ClearTx;
procedure Fldigi_SendTxCharacter(ch: char);
procedure Fldigi_SendTxString(s: string);
procedure Fldigi_SendTxBytes(s: string);

procedure Fldigi_RunMacro( macro_id: integer );

function Fldigi_LastError: string;

var
  fldigiavailable: boolean = false;
  {$IFDEF WINDOWS}
  fl_handle: hWnd;
  {$ENDIF}

implementation

uses
  xmlrpc;

const
//  fl_host = 'http://localhost:7362/RPC2';
//  fl_host = 'http://localhost:7360/';
  fl_host =  'http://localhost:7362/RPC2';

var
  rxptr: integer = 0;

function Fldigi_IsRunning: boolean;
begin
  {$IFDEF WINDOWS}
  fl_handle := FindWindow('fldigi',PChar(0));
  Result := fl_handle <> 0;
  {$ELSE}
  Result := Length(Fldigi_GetVersion) > 0;
  {$ENDIF}
end;

function Fldigi_GetVersion: string;
begin
  Result := RequestStr(fl_host,'fldigi.version');
end;

function Fldigi_GetStatus1: string;
begin
  Result := RequestStr(fl_host,'main.get_status1');
end;

function Fldigi_GetStatus2: string;
begin
  Result := RequestStr(fl_host,'main.get_status2');
end;

function Fldigi_GetFrequency: double;
// frequency is in Hz
begin
  Result := RequestFloat(fl_host,'main.get_frequency');
end;

procedure Fldigi_SetFrequency( frequency: double );
// frequency is in Hz
begin
  RequestStr(fl_host,'main.set_frequency',frequency);
end;

procedure Fldigi_ChangeFrequency( increment: double );
// increment is in Hz
begin
  RequestStr(fl_host,'main.inc_frequency',increment);
end;

function Fldigi_GetQSOFrequency: double;
// frequency is in Hz
begin
  Result := StrToFloatDef(RequestStr(fl_host,'log.get_frequency'),0.0);
end;

function Fldigi_IsAFC: boolean;
begin
  Result := RequestBool(fl_host,'main.get_afc');
end;

procedure Fldigi_SetAFC( state: boolean);
begin
  RequestStr(fl_host,'main.set_afc',state);
end;

function Fldigi_IsSquelch: boolean;
begin
  Result := RequestBool(fl_host,'main.get_squelch');
end;

procedure Fldigi_SetSquelch( state: boolean);
begin
  RequestStr(fl_host,'main.set_squelch',state);
end;

function Fldigi_IsLock: boolean;
begin
  Result := RequestBool(fl_host,'main.get_lock');
end;

procedure Fldigi_SetLock( state: boolean);
begin
  RequestStr(fl_host,'main.set_lock',state);
end;

function Fldigi_IsReverse: boolean;
begin
  Result := RequestBool(fl_host,'main.get_reverse');
end;

procedure Fldigi_SetReverse( state: boolean);
begin
  RequestStr(fl_host,'main.set_reverse',state);
end;

function Fldigi_GetCarrier: integer;
begin
  Result := RequestInt(fl_host,'modem.get_carrier');
end;

procedure Fldigi_SetCarrier( carrier: integer );
begin
  RequestStr(fl_host,'modem.set_carrier',carrier);
end;

procedure Fldigi_ChangeCarrier( increment: integer );
begin
  RequestStr(fl_host,'modem.inc_carrier',increment);
end;

function Fldigi_GetMode: string;
var
  p: integer;
begin
  Result := RequestStr(fl_host,'modem.get_name');
  repeat
    p := Pos('-',Result);
    if p > 0 then Delete(Result,p,1)
  until p = 0;
  repeat
    p := Pos('_',Result);
    if p > 0 then Delete(Result,p,1)
  until p = 0;
end;

procedure Fldigi_SetMode( mode: string );
var
  p,t,f: integer;
  m,n: string;

  function submode( md: string ): string;
  begin
    Result := md;
    while (Length(Result) > 0) and not (Result[1] in ['0'..'9']) do
      Delete(Result,1,1);
  end;
begin
  case Pos(Copy(Uppercase(mode),1,2),'CWRTBPQPMFOLMTDO') div 2 of
  0:  m := 'CW';
  1:  m := 'RTTY';
  2:  m := 'BPSK'+submode(mode);
  3:  m := 'QPSK'+submode(mode);
  4:  begin
        n := submode(mode);
        if n = '16' then
          m := 'MFSK16'
        else
          m := 'MFSK-'+n;
      end;
  5:  begin
        m := 'OLIVIA';
        p := Pos(' ',mode);
        if p > 0 then
        begin
          Delete(mode,1,p);
          p := Pos('/',mode);
          if p > 0 then
          begin
            t := StrToIntDef(Copy(mode,1,p-1),32);
            f := StrToIntDef(Copy(mode,p+1,4),1000);
          end;
        end;
      end;
  6:  begin
        m := 'MT63'+submode(mode);
        p := Pos('000',m);
        if p > 0 then
        begin
          Delete(m,p,3);
          m := m + 'XX';
        end;
      end;
  7:  begin
        n := submode(mode);
        if Length(n) = 1 then
          m := 'DomEX'+n
        else
          m := 'DomX'+n;
      end;
  end;
  RequestStr(fl_host,'modem.set_by_name',m,false);
  if m = 'OLIVIA' then
  begin
    RequestInt(fl_host,'modem.olivia.set_tones',t);
    RequestInt(fl_host,'modem.olivia.set_bandwidth',f);
  end;
end;

function Fldigi_ListModes: string;
begin
  Result := RequestStr(fl_host,'modem.get_names');
//  if RequestError then
    Result := GetLastResponse;
end;

function Fldigi_GetBandwidth: integer;
// only supported by CW modem, returns -1 otherwise
begin
  Result := RequestInt(fl_host,'modem.get_bandwidth');
end;

procedure Fldigi_ClearRx;
begin
  RequestStr(fl_host,'text.clear_rx');
  rxptr := 0;
end;

function Fldigi_RxCharsWaiting: boolean;
var
  l: integer;
begin
  l := RequestInt(fl_host,'text.get_rx_length');
  Result := l > rxptr;
end;

function Fldigi_GetRxString: string;
var
  l: integer;
begin
  l := RequestInt(fl_host,'text.get_rx_length');
  if l < rxptr then rxptr := 0;
  if l > rxptr then
  begin
    Result := RequestStr(fl_host,'text.get_rx',rxptr,l-rxptr);
    rxptr := l;
  end
  else
    Result := '';
end;

procedure Fldigi_StartTx;
begin
  RequestStr(fl_host,'main.tx');
end;

procedure Fldigi_StopTx;
begin
  RequestStr(fl_host,'main.rx');
end;

procedure Fldigi_AbortTx;
begin
  RequestStr(fl_host,'main.abort');
end;

procedure Fldigi_Tune;
begin
  RequestStr(fl_host,'main.tune');
end;

function Fldigi_IsTx: boolean;
begin
  Result := RequestStr(fl_host,'main.get_trx_status') = 'tx';
end;

procedure Fldigi_ClearTx;
begin
  RequestStr(fl_host,'text.clear_tx');
end;

// end text with "^r" to return to receive when sent

procedure Fldigi_SendTxCharacter(ch: char);
begin
  RequestStr(fl_host,'text.add_tx',ch,false);
end;

procedure Fldigi_SendTxString(s: string);
begin
  RequestStr(fl_host,'text.add_tx',s,false);
end;

procedure Fldigi_SendTxBytes(s: string);
begin
  // send byte string
  RequestStr(fl_host,'text.add_tx_bytes',s,true);
end;

procedure Fldigi_RunMacro( macro_id: integer );
// macro_id is an ordinal number. First macro button is 0
begin
  RequestStr(fl_host,'main.run_macro',macro_id);
end;

function Fldigi_LastError: string;
begin
  if RequestError then
    Result := GetLastError
  else
    Result := '';
end;

end.

