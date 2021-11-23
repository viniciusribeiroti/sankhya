create or replace FUNCTION SNK_GET_NUBCO_SOL
RETURN NUMBER
AS
  PRAGMA AUTONOMOUS_TRANSACTION;
  P_LOTE        NUMBER(10,0);
  P_VALOR       NUMBER(10,0);
  P_ULTCOD      NUMBER(10,0);
  P_MINNUBCO    NUMBER(10,0); 
  P_MAXNUBCO    NUMBER(10,0);
  P_COUNT       NUMBER(10,0);
  P_FICA        BOOLEAN;
  P_RECOMECOU   BOOLEAN;
BEGIN

  --SELECT SEQ_TGFMBC_NUBCO.NEXTVAL
  SELECT NVL(MAX(NUBCO),0) + 1
  INTO P_VALOR
  FROM TGFMBC;

  P_ULTCOD := P_VALOR; --Não mexer no P_VALOR para verificar no final se o P_ULTCOD foi alterado.

  SELECT COUNT(1)
  INTO P_COUNT
  FROM TGFMBC
  WHERE NUBCO = P_ULTCOD;
  IF P_COUNT = 0 THEN
    RETURN P_ULTCOD;     
  END IF;

  P_ULTCOD := P_ULTCOD + 1;
  P_RECOMECOU := FALSE;
  P_LOTE := 100000000; -- 100.000.000
  P_FICA := TRUE;
  --Verifica em lotes se tem algum número faltando
  WHILE P_FICA LOOP
    SELECT MIN(NUBCO), MAX(NUBCO), COUNT(1)
    INTO P_MINNUBCO, P_MAXNUBCO, P_COUNT
    FROM TGFMBC
    WHERE NUBCO BETWEEN P_ULTCOD AND P_ULTCOD + P_LOTE - 1; -- 1 até ((1+100-1) = 100)

    IF P_MINNUBCO IS NULL OR P_MINNUBCO > P_ULTCOD THEN
      --se MIN(NUFIN) diferente do valor valor pretendido pode sair do loop e utilizá-lo
      P_FICA := FALSE;
    ELSIF P_COUNT < P_LOTE THEN

     --Se max(nufin) for menor que 100 sai do loop, se não tira um zero do lote até que ele chegue a 100
      IF P_LOTE > 100 AND P_MAXNUBCO > 100 THEN
        P_LOTE := TRUNC(P_LOTE / 10);

        --se o lote for maior que max(nufin) diminui do lote o número de zeros necessários para o lote ficar menor que max(nufin) 
        IF P_LOTE > P_MAXNUBCO THEN
          P_LOTE := POWER(10, LENGTH(P_MAXNUBCO)-1);
        END IF;
        P_ULTCOD := P_ULTCOD + 1;
      ELSE
        P_FICA := FALSE;
      END IF;

    ELSE
      P_ULTCOD := P_ULTCOD + P_LOTE;

      IF P_ULTCOD > 1999999999 THEN --1.999.999.999
        IF P_RECOMECOU THEN
          RAISE_APPLICATION_ERROR (-20101, 'Não achamos número disponível para novos registros na TGFMBC.');
        END IF;
        P_ULTCOD := 1;
        P_LOTE := 100000000;
        P_RECOMECOU := TRUE;
      END IF;

    END IF;

  END LOOP;

  --Se o P_MINNUBCO for maior que o P_ULTCOD não precisa procurar mais
  IF NVL(P_MINNUBCO,0) = P_ULTCOD THEN
    P_FICA := TRUE;
  END IF;

  WHILE P_FICA LOOP

    FOR BAN IN (
      SELECT NUBCO
      FROM  TGFMBC
      WHERE NUBCO BETWEEN P_ULTCOD AND P_ULTCOD + 99  -- 1 até ((1+99) = 100)
      ORDER BY NUBCO)
    LOOP

      IF BAN.NUBCO > P_ULTCOD THEN         
        P_FICA := FALSE;
        EXIT;
      ELSE
        P_ULTCOD := P_ULTCOD + 1;
        IF P_ULTCOD > 1999999999 THEN
          RAISE_APPLICATION_ERROR (-20101, 'Não achamos número disponível para novos registros na TGFMBC.');
        END IF;
      END IF;

    END LOOP;

  END LOOP;

  IF P_ULTCOD <> P_VALOR THEN
    --Altera a o incremento da sequencia para a diferença entre o novo valor e valor antigo 

    IF (P_ULTCOD - P_VALOR) > 0 THEN

      UPDATE TGFNUM SET ULTCOD = ULTCOD + TO_CHAR(P_ULTCOD - P_VALOR) WHERE ARQUIVO = 'TGFMBC';

    ELSE 

      UPDATE TGFNUM SET ULTCOD = ULTCOD + (-1 * TO_CHAR(P_ULTCOD - P_VALOR)) WHERE ARQUIVO = 'TGFMBC';

    END IF;

  END IF;

  RETURN P_ULTCOD;     
END;