      SID,SERIAL#
--alter system kill session '1168,37047,@1';
select  w.total_waits, w.time_waited, to_char(sysdate, 'DD/MM/YYYY HH24:MI:SS') timestamp, s.inst_id, p.spid, s.sid, s.serial#, s.username,
      s.osuser, s.status, s.server, to_char(s.logon_time, 'DD/MM/YYYY HH24:MI:SS') logon_time,
      s.machine, s.process client_pid_port, s.program,
      s.last_call_et state_time, s.wait_class, s.event, s.state,        
      p.pga_used_mem, p.pga_alloc_mem, p.pga_freeable_mem, p.pga_max_mem,
      s.sql_id, sqla.hash_value, sql.child_number, sqla.executions, sqla.parse_calls, sqla.plan_hash_value, sqla.first_load_time, sql.sql_text
 From gv$session s, gv$process p, gv$sql sql, gv$session_wait_class w, gv$sqlarea sqla
Where s.username is not null
  And s.paddr = p.addr (+)
  and s.inst_id = p.inst_id (+)
  And s.sql_address = sql.address (+)
  and s.sql_hash_value = sql.hash_value (+)  
  and s.inst_id = sql.inst_id (+)
  and s.wait_class# = w.wait_class# (+)
  and s.sid = w.sid (+)
  and s.serial# = w.serial# (+)
  and s.inst_id = w.inst_id (+)
  AND s.sql_hash_value = sqla.hash_value (+)
  and s.sql_address = sqla.address (+)
  and s.status = 'ACTIVE'
  and rownum <= 20
Order by w.total_waits desc
e procurando alguma sessao minha, da minha maquina
e ai da um kill assim
-alter system kill session '1168,37047,@1';
onde parametros sao campos  SID, SERIAL
O @1 pode deixar