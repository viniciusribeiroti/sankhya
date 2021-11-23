CREATE OR REPLACE PROCEDURE STP_SNK_UPDATE_PAR( P_CPF_CNPJ      IN VARCHAR2,
                                                P_RAZAOSOCIAL   IN VARCHAR2,
                                                P_EMAILINDICADO IN VARCHAR2,
                                                P_FONEINDICADO  IN VARCHAR2,
                                                P_CIDADE        IN VARCHAR2,
                                                P_UF            IN VARCHAR2,
                                                P_ENDERECO      IN VARCHAR2,
                                                P_NUMEND        IN VARCHAR2,
                                                P_COMPLEMENTO   IN VARCHAR2,
                                                P_BAIRRO        IN VARCHAR2,
                                                P_CEP           IN VARCHAR2,
                                                P_VALIDA        OUT INT) AS

  ERROR EXCEPTION;
  AVISO EXCEPTION;
  P_CGCCPFINDICADO2           VARCHAR2(20);
  P_FONEINDICADO2             VARCHAR2(15);
  P_RAZAOSOCIAL2              VARCHAR2(100);
  P_CIDADE2                   TSICID.CODCID%TYPE;
  P_CODEND                    TSIEND.CODEND%TYPE;
  P_CODPARCINDICADO           NUMBER(10);
  P_TELEFONE                  VARCHAR2(15);
  P_TELEFONE2                 VARCHAR2(15);
  P_TIPOEND                   VARCHAR2(100);
  P_TIPOEND2                  VARCHAR2(100);
  P_VARIAVEL                  INTEGER := 0;
  P_COUNT                     INTEGER := 0;
  P_COUNTEND                  INTEGER := 0;
  P_COUNTBAI                  INTEGER := 0;
  P_TIPPESSOA                 TGFPAR.TIPPESSOA%TYPE;
  P_CODBAI                    TSIBAI.CODBAI%TYPE;
  P_CLASSIFICMS               TGFPAR.CLASSIFICMS%TYPE;
  P_ROTINA                    VARCHAR2(150) := 'STP_SNK_UPDATE_PAR';
  P_CODCONTATO                INTEGER := 0;
  P_ENDERECOOLD               VARCHAR2(4000);

BEGIN

  /****************************************************
      - DEV: Vinícius Rodrigues Ribeiro               *
      - DATA: 09/08/2021 - 17:06                      *
      - Atualizar dados dos clientes do Gestão Online *
  ****************************************************/

  P_CODPARCINDICADO := 0;
  P_RAZAOSOCIAL2    := SUBSTR(P_RAZAOSOCIAL, 1, 100);
  P_CGCCPFINDICADO2 := TRIM(TRANSLATE(TRIM(FC_REMOVESTR(P_CPF_CNPJ)),' ./\-:',' '));


  STP_SNK_REGLOG('1.1 ATUALIZAR PARCEIRO: ' || P_ROTINA || ' - CNPJ: ' ||P_CPF_CNPJ);

  /*
    -- CONTATOS DO PARCEIRO
    -- TELEFONES PARA OS CONTATOS DO PARCEIRO
    -- CELULAR DOS CADASTROS
  */
  SELECT CONCAT(SUBSTR(P_FONEINDICADO, 0, 2), '  ') INTO P_TELEFONE2 FROM DUAL;

  SELECT SUBSTR(P_FONEINDICADO, 3, 15) INTO P_TELEFONE FROM DUAL;

  SELECT CONCAT(P_TELEFONE2, P_TELEFONE) INTO P_FONEINDICADO2 FROM DUAL;

  -- CIDADE
  P_VARIAVEL := 0;

  SELECT NVL(COUNT(1), 0)
         INTO P_VARIAVEL
    FROM TSICID CID, TSIUFS UFS
   WHERE UFS.CODUF = CID.UF
     AND CID.NOMECID =
         SUBSTR(TRIM(TRANSLATE(UPPER(P_CIDADE),'ÂÀÃÁÁÂÀÃÉÊÉÊÍÍÓÔÕÓÔÕÜÚÜÚÇÇÑÑ','AAAAAAAAEEEEIIOOOOOOUUUUCCNN')), 0, 20)
     AND UFS.UF = UPPER(P_UF);

  IF NVL(P_VARIAVEL, 0) > 0 THEN

    SELECT CID.CODCID
           INTO P_CIDADE2
      FROM TSICID CID, TSIUFS UFS
     WHERE UFS.CODUF = CID.UF
       AND CID.NOMECID =
           SUBSTR(TRIM(TRANSLATE(UPPER(P_CIDADE),'ÂÀÃÁÁÂÀÃÉÊÉÊÍÍÓÔÕÓÔÕÜÚÜÚÇÇÑÑ','AAAAAAAAEEEEIIOOOOOOUUUUCCNN')), 0, 20)
       AND UFS.UF = UPPER(P_UF);

  ELSE

    P_CIDADE2 := 5412;

  END IF;

  --ENDEREÇO
  SELECT  TRIM(UPPER(TRANSLATE(UPPER(P_ENDERECO),'ÂÀÃÁÁÂÀÃÉÊÉÊÍÍÓÔÕÓÔÕÜÚÜÚÇÇÑÑ', 'AAAAAAAAEEEEIIOOOOOOUUUUCCNN')))
          INTO P_ENDERECOOLD
    FROM  DUAL;

  SELECT NVL(COUNT(1), 0)
         INTO P_COUNTEND
    FROM TSIEND
   WHERE NOMEEND LIKE '%'||(P_ENDERECOOLD) || '%';

  IF NVL(P_COUNTEND, 0) = 0 THEN

    SELECT MAX(CODEND) + 1 INTO P_CODEND FROM TSIEND;

    SELECT SUBSTR(P_ENDERECOOLD, 0, 3) INTO P_TIPOEND FROM DUAL;

    P_COUNTEND := 0;

    SELECT NVL(COUNT(1), 0)
           INTO P_COUNTEND
      FROM TSITEND
     WHERE DESCRICAO LIKE INITCAP(P_TIPOEND) || '%'
       AND ROWNUM = 1;

    IF NVL(P_COUNTEND, 0) = 0 THEN

      P_TIPOEND2 := 'R';

    ELSE

      SELECT TIPO INTO P_TIPOEND2 FROM TSITEND WHERE DESCRICAO LIKE INITCAP(P_TIPOEND) || '%' AND ROWNUM = 1;

    END IF;

    INSERT INTO TSIEND (CODEND, NOMEEND, TIPO, DTALTER)
    VALUES (P_CODEND, TRIM(UPPER(TRANSLATE(UPPER(P_ENDERECOOLD), 'ÂÀÃÁÁÂÀÃÉÊÉÊÍÍÓÔÕÓÔÕÜÚÜÚÇÇÑÑ', 'AAAAAAAAEEEEIIOOOOOOUUUUCCNN'))),
            P_TIPOEND2, SYSDATE);
    COMMIT;

  ELSE

    SELECT MAX(CODEND)
           INTO P_CODEND
      FROM TSIEND
     WHERE NOMEEND LIKE '%'||(P_ENDERECOOLD) || '%';

  END IF;

  --BAIRRO
  SELECT NVL(COUNT(1), 0)
         INTO P_COUNTBAI
    FROM TSIBAI
   WHERE NOMEBAI =
         TRIM(UPPER(TRANSLATE(UPPER(P_BAIRRO), 'ÂÀÃÁÁÂÀÃÉÊÉÊÍÍÓÔÕÓÔÕÜÚÜÚÇÇÑÑ', 'AAAAAAAAEEEEIIOOOOOOUUUUCCNN')));

  IF NVL(P_COUNTBAI, 0) = 0 THEN

    SELECT MAX(CODBAI) + 1 INTO P_CODBAI FROM TSIBAI;

    INSERT INTO TSIBAI (CODBAI, NOMEBAI, DTALTER) VALUES (P_CODBAI, P_BAIRRO, SYSDATE);

    COMMIT;

  ELSE

    SELECT CODBAI
           INTO P_CODBAI
      FROM TSIBAI
     WHERE NOMEBAI =
           TRIM(UPPER(TRANSLATE(UPPER(P_BAIRRO), 'ÂÀÃÁÁÂÀÃÉÊÉÊÍÍÓÔÕÓÔÕÜÚÜÚÇÇÑÑ', 'AAAAAAAAEEEEIIOOOOOOUUUUCCNN')));

  END IF;

  IF LENGTH(P_CGCCPFINDICADO2) = 14 THEN P_TIPPESSOA := 'J'; ELSE P_TIPPESSOA := 'F'; END IF;

  SELECT NVL(CLASSIFICMS, 0)  INTO P_CLASSIFICMS FROM TGFPAR  WHERE CGC_CPF = P_CGCCPFINDICADO2;

  IF P_CLASSIFICMS NOT IN ('X', 'C') THEN P_CLASSIFICMS := 'C'; END IF;

  UPDATE TGFPAR
     SET CEP             = P_CEP,
         CLASSIFICMS     = P_CLASSIFICMS,
         CODBAI          = P_CODBAI,
         CODCID          = P_CIDADE2,
         CODEND          = P_CODEND,
         COMPLEMENTO     = UPPER(P_COMPLEMENTO),
         EMAIL           = LOWER(P_EMAILINDICADO),
         EMAILNFE        = LOWER(P_EMAILINDICADO),
         TELEFONE        = P_FONEINDICADO2,
         NUMEND          = P_NUMEND,
         CLIENTE         = 'S',
         AD_IDINTEGRADOR = 'GESTON',
         TIPPESSOA       = P_TIPPESSOA
   WHERE CGC_CPF = P_CGCCPFINDICADO2;

   COMMIT;

    SELECT CODPARC INTO P_CODPARCINDICADO FROM TGFPAR WHERE CGC_CPF = P_CGCCPFINDICADO2;

    SELECT COUNT(1)  INTO P_COUNT  FROM TGFCTT CTT  WHERE CTT.CODPARC = P_CODPARCINDICADO;

  IF NVL(P_COUNT, 0) >= 1 THEN

    UPDATE TGFCTT SET EMAIL=LOWER(P_EMAILINDICADO), RECEBENOTAEMAIL='S', ATIVO='S' WHERE CODPARC = P_CODPARCINDICADO;

    COMMIT;

  ELSE

    SELECT NVL(MAX(CODCONTATO), 0) + 1 INTO P_CODCONTATO FROM TGFCTT WHERE CODPARC = P_CODPARCINDICADO;

    INSERT INTO TGFCTT
      (CODPARC,
       CODCONTATO,
       NOMECONTATO,
       APELIDO,
       CARGO,
       CODEND,
       NUMEND,
       COMPLEMENTO,
       CODBAI,
       CODCID,
       CEP,
       TELEFONE,
       RAMAL,
       FAX,
       EMAIL,
       DTNASC,
       CPF,
       PRIORIDADE,
       ATIVO,
       DTCAD,
       CELULAR,
       CNPJ,
       CODPARCCAD,
       TELRESID,
       POSSUIACESSOBT,
       SENHABT,
       SENHAACESSO,
       CODUSU,
       NIVELCOB,
       RECEBEBOLETOEMAIL,
       RECEBENOTAEMAIL,
       SOCIO,
       LATITUDE,
       LONGITUDE,
       CODREG,
       RECEMAILIMPPED,
       EMAILRECBOL,
       AD_RG,
       AD_ORGEXPED,
       HABPLANENTCESTAS,
       QTDENTREGACESTAS,
       ENVIANOTIFCOTA,
       AD_CODBCO,
       AD_AGENCIA,
       AD_CONTA)
    VALUES

      ( P_CODPARCINDICADO,
       P_CODCONTATO,
       SUBSTR(UPPER(P_RAZAOSOCIAL2), 1, 40),
       NULL,
       NULL,
       NULL,
       NULL,
       NULL,
       NULL,
       NULL,
       NULL,
       NULL,
       NULL,
       NULL,
       LOWER(P_EMAILINDICADO),
       NULL,
       NULL,
       NULL,
       'S',
       NULL,
       NULL,
       NULL,
       '0',
       NULL,
       'N',
       NULL,
       NULL,
       NULL,
       '0',
       'N',
       'S',
       'N',
       NULL,
       NULL,
       NULL,
       'N',
       'N',
       NULL,
       NULL,
       NULL,
       NULL,
       'N',
       NULL,
       NULL,
       NULL);

  END IF;

  IF (SQL%ROWCOUNT = 0) THEN
    --P_ERRMSG := 'AÇÃO CANCELADA! CADASTRO DE PARCEIRO COM ERRO.';
    STP_SNK_REGLOG('1.2 - ATUALIZAR PARCEIRO: ' || P_ROTINA || ' - CNPJ: ' ||P_CPF_CNPJ||' - ERRO:  CADASTRO DE PARCEIRO COM ERRO ');

   -- P_VALIDA := 1;
  END IF;

  COMMIT;

  P_VALIDA := P_CODPARCINDICADO;

   STP_SNK_REGLOG('1.3 - ATUALIZAR PARCEIRO: ' || P_ROTINA || ' - CNPJ: ' ||P_CPF_CNPJ||' - CODPARC: ' || P_CODPARCINDICADO);

  COMMIT;

  RETURN;

EXCEPTION

  WHEN OTHERS THEN

    P_VALIDA := 1;

    STP_SNK_REGLOG('1.4 - ATUALIZAR PARCEIRO: ' || P_ROTINA || ' - CNPJ: ' ||P_CPF_CNPJ||' - ERRO: ' || SQLERRM);

    COMMIT;
END;
