create or replace FUNCTION FC_LISTA_NOMEPROD_PORNOTA (P_NUNOTA IN NUMBER)
RETURN VARCHAR
IS
P_LISTA   VARCHAR2(4000);
begin
  /***************************************
  * AUTOR: VINÍCIUS RIBEIRO
  * CRIAÇÃO: 28/10/2021
  * OBJETIVO: LISTA PRODUTOS DE UMA NOTA
  ***************************************/
    FOR L_CURSOR IN (SELECT
                     PRO.CODPROD ||'-'||PRO.DESCRPROD AS LISTPRODUTO, pro.REFERENCIA
                     FROM TGFITE ITE, TGFPRO PRO
                    WHERE ITE.CODPROD = PRO.CODPROD
                    AND ITE.NUNOTA = P_NUNOTA
                    AND ITE.USOPROD <> 'D'
                    ORDER BY PRO.CODPROD) LOOP

    P_LISTA := P_LISTA || L_CURSOR.LISTPRODUTO || ', ';

  END LOOP;

  P_LISTA := substr(P_LISTA,1,LENGTH(P_LISTA)-2);

  return(P_LISTA);
end;
