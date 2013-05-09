--Oracle DB Monitoring user
--http://labs.consol.de/lang/en/nagios/check_oracle_health/

CREATE USER nagios IDENTIFIED BY oradbmon; 
GRANT CREATE SESSION TO nagios;
GRANT SELECT any dictionary TO nagios;
GRANT SELECT ON V_$SYSSTAT TO nagios;
GRANT SELECT ON V_$INSTANCE TO nagios;
GRANT SELECT ON V_$LOG TO nagios;
GRANT SELECT ON SYS.DBA_DATA_FILES TO nagios;
GRANT SELECT ON SYS.DBA_FREE_SPACE TO nagios;
