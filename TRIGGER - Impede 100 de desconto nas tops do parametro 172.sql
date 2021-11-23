create or replace TRIGGER TRG_INC_UPD_DESCTGFITE_SOL
BEFORE UPDATE OR INSERT ON TGFCAB FOR EACH ROW
DECLARE

 V_COUNT      INT;

BEGIN
    /**********************************************************
        - Author: Vinícius Ribeiro - Data: 28/07/2021         *
        - Impedir desconto de 100% nas TOPS                   *
        - As TOPs devem estar configuradas no parâmetros 172  *
        - Verifica se todos os itens tem 100% de desconto     *
     **********************************************************/

        IF (NVL(:NEW.VLRNOTA,0)= 0 ) THEN

           SELECT COUNT(1) 
             INTO V_COUNT 
             FROM AD_PARAMETROTOP 
            WHERE NUPARAMETRO = 172 
              AND CODTIPOPER = :NEW.CODTIPOPER;

           IF (V_COUNT > 0)THEN

                RAISE_APPLICATION_ERROR(-20101, 'TOP NÃO PERMITI DESCONTO 100%. 
                REVISE O PARÂMETRO 172 NA CENTRAL DE PARÂMETROS, CASO PRECISE
                LIBERAR TAL OPERAÇÃO');
       END IF;
    END IF;
END;