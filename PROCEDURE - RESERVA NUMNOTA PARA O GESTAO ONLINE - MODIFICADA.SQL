create or replace PROCEDURE "STP_SNK_RESERVANUMTOP_SOLUTI"(P_ARQUIVO  VARCHAR2,
                                                           P_CODEMP   NUMBER,
                                                           P_SERIE    VARCHAR2,
                                                           P_CODIGOSP OUT INTEGER,
                                                           P_ERROSP   OUT VARCHAR2) AS
  /**********************************************************************************
   *   CRIADO POR NETTO EM 16/02/21                                                  *
   *   OBJETIVO: ALTERAR NUMERACAO DA TOP                                            *
   *   USO EXCLUSIVO NA API-SANKHYA                                                  *
   *   ----------------------------------                                            *

   *  AJUSTES POR VINÍCIUS RIBEIRO 18/06/21                                          *
   *   1 -> CONFERENCIA NA TGFCAB NO SEGUNDO UPDATE                                  *
   *   2 -> SAVEPOINT PARA EVITAR DUPLICIDADE DE NOTA                                *            
   *   3 -> REGISTRAR OS LOGS DAS AÇÕES DA PROCEDURE. STP_SNK_REGLOG                 *   
   ************************************************************************************/

  -- VARIÁVEIS
  ERROR EXCEPTION;
  AVISO EXCEPTION;
  P_ERRMSG VARCHAR2(255);

  P_COUNT  INTEGER := 0;
  P_ULTCOD NUMBER;
  P_ARQUIVO2   VARCHAR2(30):='VENDA';

  P_NOMEPROCEDURE VARCHAR2(100):='STP_SNK_RESERVANUMTOP_SOLUTI';

BEGIN

  --OBTEM ULTIMA NUMERACAO
  IF P_SERIE IS NULL OR TRIM(P_SERIE) = '' THEN
    --NAO TEM SERIE
    SELECT NVL(COUNT(1), 0)
      INTO P_COUNT
      FROM TGFNUM
     WHERE ARQUIVO = P_ARQUIVO2
       AND CODEMP = P_CODEMP;

    IF NVL(P_COUNT, 0) = 0 THEN
      P_ERRMSG := 'Falha! Registro ' || P_ARQUIVO2 || ' não existe!';

      --REGISTRA LOG 1.0
       STP_SNK_REGLOG('1.0_RESERVANUMTOP...OK:' || ' FALHA NO ARQUIVO '|| P_ARQUIVO2 ||' - STP_SNK_RESERVANUMTOP_SOLUTI');

      P_CODIGOSP := 0;
      P_ERROSP   := P_ERRMSG;

      RETURN;

    END IF;

    SELECT NVL(MAX(ULTCOD), 0)
      INTO P_ULTCOD
      FROM TGFNUM
     WHERE ARQUIVO = P_ARQUIVO2
       AND CODEMP = P_CODEMP;

    IF NVL(P_ULTCOD, 0) > 0 THEN
      P_ULTCOD := P_ULTCOD + 1;
    ELSE
      P_ULTCOD := 1;
    END IF;

    -- GARANTE HÁ NÃO DE DUPLICITADE
    SAVEPOINT MY_SAVEPOINT;
    --GRAVA NUMERACAO E RETORNA NUMERO
    UPDATE TGFNUM
       SET ULTCOD = P_ULTCOD
     WHERE ARQUIVO = P_ARQUIVO2
       AND CODEMP = P_CODEMP
       AND SERIE = 'UN'; --FIXANDO PARA GRANTIR A INTEGRIDADE DA CHAVE; TODOSOLUTI: VERIFICAR REGRA COM O @RICARDO NETTO

    --FALHA
    IF (SQL%ROWCOUNT = 0) THEN
      P_ERRMSG := 'Falha na alteração da numeração da TOP!';

      --REGISTRA LOG
      --REGISTRA LOG 2.0
       STP_SNK_REGLOG('2.0_RESERVANUMTOP...OK:' || ' FALHA NO UPDATE TGFNUM  ARQ'|| P_ARQUIVO2 ||' NUMNOTA ' || P_ULTCOD ||' SERIE UN - STP_SNK_RESERVANUMTOP_SOLUTI');

      P_CODIGOSP := 0;
      P_ERROSP   := P_ERRMSG;

      ROLLBACK TO MY_SAVEPOINT;
      RETURN;

    ELSE
      COMMIT;

      --SUCESSO
      --REGISTRA LOG 2.0
      STP_SNK_REGLOG('2.1_RESERVANUMTOP...OK:' || ' RESERVOU O NUMNOTA NA TGFNUM '|| P_ULTCOD ||' - SERIE '|| P_SERIE ||' - EMPR '|| P_CODEMP ||' - STP_SNK_RESERVANUMTOP_SOLUTI');
      P_CODIGOSP := P_ULTCOD;
      P_ERROSP   := '';
      RETURN;

    END IF;

ELSE
    --TEM SERIE
    SELECT NVL(COUNT(1), 0)
      INTO P_COUNT
      FROM TGFNUM
     WHERE ARQUIVO = P_ARQUIVO2
       AND CODEMP = P_CODEMP
       AND SERIE = P_SERIE;

    IF NVL(P_COUNT, 0) = 0 THEN
      P_ERRMSG := 'Falha! Registro ' || P_ARQUIVO2 || ' não existe!';

      --REGISTRA LOG 3.0
      STP_SNK_REGLOG('3.0_RESERVANUMTOP...OK:' || ' FALHA NO ARQUIVO '|| P_ARQUIVO2 ||' - SERIE '||P_SERIE||' - STP_SNK_RESERVANUMTOP_SOLUTI');

      P_CODIGOSP := 0;
      P_ERROSP   := P_ERRMSG;

      RETURN;

    END IF;

    SELECT NVL(MAX(ULTCOD), 0)+1
      INTO P_ULTCOD
      FROM TGFNUM
     WHERE ARQUIVO = P_ARQUIVO2
       AND CODEMP = P_CODEMP
       AND SERIE = P_SERIE;


     -- GARANTE QUE O NUMNOTA NÃO EXISTE NA TGFCAB
    SAVEPOINT MY_SAVEPOINT;

     SELECT COUNT(1) 
            INTO P_COUNT 
       FROM TGFCAB 
      WHERE CODEMP    = P_CODEMP 
        AND NUMNOTA   = P_ULTCOD
        AND SERIENOTA = P_SERIE;

  IF NVL(P_COUNT,0) = 0 THEN

    --GRAVA NUMERACAO E RETORNA NUMERO
    UPDATE TGFNUM
       SET ULTCOD  = P_ULTCOD
     WHERE ARQUIVO = P_ARQUIVO2
       AND CODEMP  = P_CODEMP
       AND SERIE   = P_SERIE;

    --FALHA
    IF (SQL%ROWCOUNT = 0) THEN
      P_ERRMSG := 'Falha na reserva da numeração da TOP!';

     --REGISTRA LOG 3.0
       STP_SNK_REGLOG('3.1_RESERVANUMTOP...OK:' || ' FALHA NO UPDATE COM SERIE. ARQ: '|| P_ARQUIVO2 ||' CODEMP '|| P_CODEMP||' SERIE '|| P_SERIE||' NUMNOTA '|| P_ULTCOD|| ' - STP_SNK_RESERVANUMTOP_SOLUTI');

      P_CODIGOSP := 0;
      P_ERROSP   := P_ERRMSG;

      ROLLBACK TO MY_SAVEPOINT;
      RETURN;

  ELSE
     COMMIT;
      --REGISTRA LOG 3.0
       STP_SNK_REGLOG('3.2_RESERVANUMTOP...OK:' || ' SUCESSO NO UPDATE COM SERIE. ARQ: '|| P_ARQUIVO2 ||' CODEMP '|| P_CODEMP||' SERIE '|| P_SERIE||' NUMNOTA '|| P_ULTCOD|| ' - STP_SNK_RESERVANUMTOP_SOLUTI');

      --SUCESSO
      P_CODIGOSP := P_ULTCOD;
      P_ERROSP   := '';
      RETURN;

  END IF;

  ELSE 
       P_ERRMSG := 'NÚMERO já existente para outra NOTA na TGFCAB!';
       P_CODIGOSP := 0;
       P_ERROSP   := P_ERRMSG;

        --REGISTRA LOG 3.0
       STP_SNK_REGLOG('3.3_RESERVANUMTOP...OK:' || ' FALHA NO UPDATE NUMNOTA NA CAB. ARQ: '|| P_ARQUIVO2 ||' CODEMP '|| P_CODEMP||' SERIE '|| P_SERIE||' NUMNOTA '|| P_ULTCOD|| ' - STP_SNK_RESERVANUMTOP_SOLUTI');


       ROLLBACK TO MY_SAVEPOINT;
       RETURN;
  END IF;
END IF;

EXCEPTION

  WHEN ERROR THEN
     --REGISTRA LOG 4.0
       STP_SNK_REGLOG('4.0_RESERVANUMTOP...OK:' || ' FALHA PRIMEIRO EXCEPTION '||SQLCODE || ' - ' || SQLERRM || ' - STP_SNK_RESERVANUMTOP_SOLUTI');

   -- ROLLBACK;
    ROLLBACK TO MY_SAVEPOINT;
    
    P_ERRMSG := SQLCODE || ' - ' || SQLERRM;
    P_CODIGOSP := 0;
    P_ERROSP   := P_ERRMSG;


  WHEN OTHERS THEN

   --REGISTRA LOG 5.0
       STP_SNK_REGLOG('5.0_RESERVANUMTOP...OK:' || ' FALHA SEGUNDO EXCEPTION '||SQLCODE || ' - ' || SQLERRM || ' - STP_SNK_RESERVANUMTOP_SOLUTI');

   -- ROLLBACK;
    ROLLBACK TO MY_SAVEPOINT;
    P_ERRMSG := SQLCODE || ' - ' || SQLERRM;

    P_CODIGOSP := 0;
    P_ERROSP   := P_ERRMSG;

    --STP_SNK_REGLOGINTEG_SOLUTI(P_ORIGEMINTEG, P_IDPEDINTEG, P_NOMEPROCEDURE, P_ERROSP);

END;