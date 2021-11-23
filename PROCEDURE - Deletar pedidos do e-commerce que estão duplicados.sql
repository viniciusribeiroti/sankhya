create or replace PROCEDURE STP_SNK_DELDUP_ECOMMERCE_SOL
AS

BEGIN

DECLARE
  P_NUNOTA INT;
  P_NUPEDECOMMERCE VARCHAR(20);

CURSOR DUPLICADOS IS
SELECT FIN.NUNOTA,
       (SELECT MAX(TGFCAB.AD_NUPEDECOMMERCE) FROM TGFCAB WHERE NUNOTA = FIN.NUNOTA) as P_ECO
  FROM TGFFIN FIN
 WHERE FIN.DHBAIXA IS NULL
   AND FIN.VLRBAIXA = 0 
   AND FIN.NUNOTA IN (     
                  SELECT  NUNOTA AS NUNOTA
                    FROM
                        (SELECT AD_NUPEDECOMMERCE AS P_ECO, COUNT(*)
                          FROM TGFCAB
                         WHERE TIPMOV = 'P'
                           AND AD_NUPEDECOMMERCE IS NOT NULL
                           AND PENDENTE = 'S'
                           AND CODTIPOPER IN (1900, 1908)
                        GROUP BY AD_NUPEDECOMMERCE
                        HAVING COUNT(*) > 1) P_REP,
                        (SELECT NUNOTA, AD_NUPEDECOMMERCE AS P_ECO
                          FROM TGFCAB
                         WHERE TIPMOV = 'P'
                           AND AD_NUPEDECOMMERCE IS NOT NULL) P_PEDIDO 
                        WHERE P_REP.P_ECO = P_PEDIDO.P_ECO
                        GROUP BY NUNOTA, P_REP.P_ECO );

BEGIN
     OPEN DUPLICADOS;
   LOOP
     FETCH DUPLICADOS INTO P_NUNOTA, P_NUPEDECOMMERCE;

 IF STP_GET_ATUALIZANDO THEN RETURN; END IF;

 IF (NVL(P_NUNOTA,0) > 0) THEN
 STP_ECOLOG_SOLUTI('ECOMMERCE_SOL',
                        'STP_SNK_DELDUP_ECOMMERCE_SOL',
                        'DELETA PEDIDO',
                        'ERRO: VENDA DUPLICADA',
                        P_NUPEDECOMMERCE,
                        0,
                        P_NUNOTA);
  END IF;

 -- DELTA A CONTABILIZAÇÃO DA NOTA
 DELETE FROM TCBINT WHERE NUNICO =  P_NUNOTA;
 COMMIT;
 -- DELETA TGFREN
 DELETE FROM tgfren WHERE nufin IN ( SELECT nufin FROM tgffin WHERE nunota = P_NUNOTA );
 COMMIT;
 -- DELETA FIN
 DELETE FROM tgffin WHERE nunota = P_NUNOTA;
 COMMIT;
 -- DELETA CAB
 DELETE FROM tgfcab WHERE nunota = P_NUNOTA;
 COMMIT;
 -- DELETA TGFITE
 DELETE FROM tgfite WHERE nunota = P_NUNOTA;
 COMMIT;
  -- DELETA TGFNFSE
 DELETE FROM tgfnfse WHERE nunota = P_NUNOTA;
 COMMIT;

EXIT WHEN DUPLICADOS%NOTFOUND;
  END LOOP;
  CLOSE DUPLICADOS;
 END;
END STP_SNK_DELDUP_ECOMMERCE_SOL;
