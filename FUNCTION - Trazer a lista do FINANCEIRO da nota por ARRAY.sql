create or replace FUNCTION FC_LIST_NOTA_FINANCEIRO (P_NUNOTA IN NUMBER)
RETURN VARCHAR
IS
P_LISTA   VARCHAR2(4000);
BEGIN
  /***************************************
  * AUTOR: VINÍCIUS RIBEIRO
  * CRIAÇÃO: 29/10/2021
  * OBJETIVO: LISTA PRODUTOS DE UMA NOTA
  ***************************************/
    FOR L_CURSOR IN (SELECT 'NUFIN: '||NUFIN||' DTVENC: '||DTVENC||' DTALTER: '||DTALTER||' DESD: '||DESDOBRAMENTO||' VLRNOTA: '||REPLACE(VLRDESDOB,',','.')||' DHBAIXA: '||DHBAIXA||' VLRPAGO: '||REPLACE(VLRBAIXA,',','.')  
                         AS FINANCEIRO
                       FROM TGFFIN
                      WHERE NUNOTA = P_NUNOTA ) LOOP

    P_LISTA := P_LISTA || L_CURSOR.FINANCEIRO || '; ';

  END LOOP;

  P_LISTA := substr(P_LISTA,1,LENGTH(P_LISTA)-2);

  RETURN(P_LISTA);
end;