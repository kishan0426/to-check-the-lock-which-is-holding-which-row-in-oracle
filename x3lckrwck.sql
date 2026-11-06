
SET SERVEROUTPUT ON SIZE UNLIMITED;

DECLARE
    -- Configuration
    p_owner       VARCHAR2(128) := USER;
    p_table_name  VARCHAR2(128) := 'LOCKS';
    p_column_name VARCHAR2(128) := 'LOCKTYPE';
    p_value       VARCHAR2(4000) := 'LOCKBATCH';

    v_sql         VARCHAR2(32767);
    v_count       NUMBER := 0;
    v_owner       VARCHAR2(128);
    v_table       VARCHAR2(128);
    v_column      VARCHAR2(128);

BEGIN
    -- Validate identifiers
    v_owner  := DBMS_ASSERT.SCHEMA_NAME(UPPER(p_owner));
    v_table  := DBMS_ASSERT.SIMPLE_SQL_NAME(UPPER(p_table_name));
    v_column := DBMS_ASSERT.SIMPLE_SQL_NAME(UPPER(p_column_name));

    DBMS_OUTPUT.PUT_LINE('======================================');
    DBMS_OUTPUT.PUT_LINE('ORACLE ROW LOCK DIAGNOSTICS');
    DBMS_OUTPUT.PUT_LINE('======================================');
    DBMS_OUTPUT.PUT_LINE('Owner  : ' || v_owner);
    DBMS_OUTPUT.PUT_LINE('Table  : ' || v_table);
    DBMS_OUTPUT.PUT_LINE('Column : ' || v_column);
    DBMS_OUTPUT.PUT_LINE('Value  : ' || p_value);
    DBMS_OUTPUT.PUT_LINE('======================================');

    -- Check matching records and display ROWIDs
    v_sql :=
        'SELECT ROWID FROM "' || v_owner || '"."' ||
        v_table || '" WHERE "' || v_column || '" = :1';

    FOR r IN (
        SELECT ROWID AS rid
        FROM BatchLocks
        WHERE BatchType = 'DataCdrUsageBatch'
    )
    LOOP
        v_count := v_count + 1;
        DBMS_OUTPUT.PUT_LINE('Matching ROWID: ' || r.rid);
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('Matching rows: ' || v_count);

    -- Display sessions holding locks on the object
    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'LOCKING SESSIONS');

    FOR s IN (
        SELECT
            gs.inst_id,
            gs.sid,
            gs.serial#,
            gs.username,
            gs.machine,
            gs.program,
            gs.sql_id,
            gs.status,
            gs.event,
            glo.locked_mode
        FROM gv$locked_object glo
        JOIN dba_objects obj
          ON obj.object_id = glo.object_id
        JOIN gv$session gs
          ON gs.sid = glo.session_id
         AND gs.inst_id = glo.inst_id
        WHERE obj.owner = v_owner
          AND obj.object_name = v_table
        ORDER BY gs.inst_id, gs.sid
    )
    LOOP
        DBMS_OUTPUT.PUT_LINE('--------------------------------------');
        DBMS_OUTPUT.PUT_LINE('Instance : ' || s.inst_id);
        DBMS_OUTPUT.PUT_LINE('SID      : ' || s.sid);
        DBMS_OUTPUT.PUT_LINE('Serial   : ' || s.serial#);
        DBMS_OUTPUT.PUT_LINE('Username : ' || s.username);
        DBMS_OUTPUT.PUT_LINE('Machine  : ' || s.machine);
        DBMS_OUTPUT.PUT_LINE('Program  : ' || s.program);
        DBMS_OUTPUT.PUT_LINE('SQL ID   : ' || s.sql_id);
        DBMS_OUTPUT.PUT_LINE('Status   : ' || s.status);
        DBMS_OUTPUT.PUT_LINE('Event    : ' || s.event);
        DBMS_OUTPUT.PUT_LINE('LockMode : ' || s.locked_mode);
    END LOOP;

    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No matching records found.');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
        RAISE;
END;
/
