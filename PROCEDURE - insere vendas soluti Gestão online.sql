CREATE OR REPLACE PROCEDURE STP_SNK_INSEREVENDA_SOLUTI(P_ORIGEMINTEG IN VARCHAR2, --GESTAO_ONLINE, ASSINE_ONLINE, MERCADO_ON
                                                       P_IDPEDINTEG  INT, --
                                                       --DADOS CABEÇALHO VENDA
                                                       P_CNPJEMP       IN VARCHAR2, --
                                                       P_CODPROJ       INT,
                                                       P_CPFCNPJVEND   IN VARCHAR2, -- --COMO IDENTIFICAR VENDEDOR?
                                                       P_NUMNOTA       INT,
                                                       P_DTNOTA        IN VARCHAR2,
                                                       P_VLRNOTA       FLOAT,
                                                       P_DISCRIMINACAO IN VARCHAR2,
                                                       P_SERIENOTA     IN VARCHAR2,
                                                       P_ISSRETIDO     VARCHAR2,
                                                       P_BASEISS       FLOAT,
                                                       P_ALIQISS       FLOAT,
                                                       P_VLRISS        FLOAT,
                                                       --DADOS CLIENTE
                                                       P_CPF_CNPJ    IN VARCHAR2,
                                                       P_FANTASIA    IN VARCHAR2,
                                                       P_RAZAOSOCIAL IN VARCHAR2,
                                                       P_SEXO        IN VARCHAR2,
                                                       P_FONE        IN VARCHAR2,
                                                       P_EMAIL       IN VARCHAR2,
                                                       P_CEP         IN VARCHAR2,
                                                       P_ENDERECO    IN VARCHAR2,
                                                       P_NUMEND      IN VARCHAR2,
                                                       P_COMPLEMENTO IN VARCHAR2,
                                                       P_BAIRRO      IN VARCHAR2,
                                                       P_CIDADE      IN VARCHAR2,
                                                       P_UF          IN VARCHAR2,
                                                       --XML ITENS DA VENDA
                                                       P_XMLNFSE       CLOB,
                                                       P_XMLITENS      CLOB,
                                                       P_XMLFINANCEIRO CLOB,
                                                       --PARAMETROS DE RETORNO  DA PROCEDURE
                                                       P_CODIGOSP OUT INTEGER, --CODIGO GERADO PARA RETORNAR
                                                       P_ERROSP   OUT CLOB) --ERRO GERADO PARA RETORNAR

 AS
  P_DEBUG      BOOLEAN := FALSE; --TRUE: REGISTRA LOG
  P_COUNT      INT := 0;
  P_COUNTCAB   INT := 0;
  P_COUNTCTA   INT := 0;
  P_EXISTEVEND INT := 0;
  P_EXISTE_NF  INT := 0;
  P_CODVEND    INT := 0;
  P_NUNOTA     INT := 0;
  P_NUFIN      INT := 0;
  P_SEQUENCIA  INT := 0;
  P_COUNTKIT   INT := 0;
  P_COUNTID    INT := 0;

  P_DIFERENCA FLOAT;
  P_CODEMP    INT := 0;
  P_CODPARC   INT := 0;
  P_CODLOCAL  NUMBER(10);

  P_RG_IE  TGFPAR.IDENTINSCESTAD%TYPE;
  P_CODEND TGFPAR.CODEND%TYPE;
  P_CODBAI TGFPAR.CODBAI%TYPE;
  P_CODCID TGFPAR.CODCID%TYPE;
  --   P_TIPOEND           TSIEND.TIPO%TYPE:='RUA';
  P_NOMEEND  TSIEND.NOMEEND%TYPE;
  P_NOMEBAI  TSIBAI.NOMEBAI%TYPE;
  P_NOMECID  TSICID.NOMECID%TYPE;
  P_TIPOEND  TSIEND.TIPO%TYPE;
  P_TIPOEND2 TSIEND.TIPO%TYPE;

  P_CODTIPOPER      TGFTOP.CODTIPOPER%TYPE;
  P_CODNAT          TGFNAT.CODNAT%TYPE;
  P_CODTIPVENDA     TGFTPV.CODTIPVENDA%TYPE;
  P_CODCENCUS       TSICUS.CODCENCUS%TYPE;
  P_CODCTABCOINT    TSICTA.CODCTABCOINT%TYPE;
  P_CODTIPTIT       TGFTIT.CODTIPTIT%TYPE;
  P_CODUSU          TSIUSU.CODUSU%TYPE := 0;
  P_CODTIPTITCARTAO NUMBER(10);
  P_CODTIPTITBOLETO NUMBER(10);

  --DADOS XML ITENS
  P_CODPROD  NUMBER;
  P_QTDNEG   NUMBER := 0;
  P_VLRUNIT  FLOAT := 0;
  P_VLRDESC  FLOAT := 0;
  P_VLRTOTAL FLOAT := 0;

  P_CODVOL       TGFPRO.CODVOL%TYPE;
  P_USOPROD      VARCHAR2(3);
  P_PERCDESC     FLOAT;
  P_PRECOBASE    FLOAT;
  P_VLRCUS       FLOAT;
  P_VLRREPRED    FLOAT;
  P_CODLOCALORIG NUMBER;
  P_NUNOTAORIG   NUMBER;
  P_NUTAB        NUMBER;
  P_ALIQICMS     FLOAT;
  P_VLRICMS      FLOAT;
  P_ALIQIPI      FLOAT;
  P_VLRIPI       FLOAT;
  P_IDALIQICMS   FLOAT;

  --DADOS XML FINANCEIRO
  P_TIPO VARCHAR2(30);

  P_DESDOB TGFFIN.DESDOBRAMENTO%TYPE;

  --CARTAO
  P_REDE        NUMBER;
  P_TIPODOC     TGFFIN.CODTIPTIT%TYPE;
  P_OPERADORA   VARCHAR2(30);
  P_BANDEIRA    VARCHAR2(30);
  P_NUMNSU      VARCHAR2(30);
  P_AUTORIZACAO VARCHAR2(30);
  P_DTVENC      VARCHAR2(30); --DATE;
  P_VLRPARCELA  TGFFIN.VLRDESDOB%TYPE;
  P_VLRTAXA     FLOAT;
  P_BANCO       NUMBER;
  P_AGENCIA     VARCHAR2(10);
  P_CONTA       VARCHAR2(30);
  --BOLETO
  P_NOSSONUMERO    VARCHAR2(30);
  P_CODIGOBARRA    VARCHAR2(300);
  P_LINHADIGITAVEL VARCHAR2(300);
  P_VLRJURO        FLOAT;
  P_VLRMULTA       FLOAT;
  P_VLRDESCFIN     FLOAT;
  P_VLRISSFIN      FLOAT;
  P_HISTORICO      TGFFIN.HISTORICO%TYPE;
  P_ISSRETIDOFIN   CHAR(1);

  P_ITENSLIST    XMLTYPE;
  P_FINLIST      XMLTYPE;
  P_NFSELIST     XMLTYPE;
  P_COUNTXMLITE  INT := 0;
  P_COUNTXMLFIN  INT := 0;
  P_COUNTXMLNFSE INT := 0;
  P_COUNTITE     INT := 1;
  P_COUNTFIN     INT := 1;
  P_COUNTNFSE    INT := 1;
  P_COUNTEND     INT := 0;
  P_SEQLOG       INT := 0;

  ERR_CODE NUMBER;
  ERR_MSG  CLOB;

  P_NOMEPROCEDURE VARCHAR2(100) := 'STP_SNK_INSEREVENDA_SOLUTI';

  /***************************************************************
  PUBLICADO POR : RICARDO NETTO
  ORIGINAL: DOUGLAS
  DATA: 02/04/2021
  OBJETIVO: GERAR VENDAS OBTENDO FINANCEIRO E ITENS DO XML  
  USO EXCLUSIVO DA INTEGRAÇÃO GESTAO ONLINE/ASSINE ONLINE E OUTROS
  *****************************************************************/

BEGIN
  SAVEPOINT MY_SAVEPOINT;

  STP_SNK_REGLOG('INI_INSEREVENDA...OK:' || P_ORIGEMINTEG || ' - ' ||
                 P_IDPEDINTEG || ' - ' || P_CNPJEMP || ' - ' || P_CODPROJ || '-' ||
                 P_ENDERECO || '-' || SUBSTR(P_XMLFINANCEIRO, 1, 3900));
  --||'-'||SUBSTR(P_XMLFINANCEIRO,1,3900));

  --VERIFICA SE JA EXISTE (EVITA DUPLICAR)
  SELECT NVL(COUNT(1), 0)
    INTO P_COUNTID
    FROM TGFCAB
   WHERE TIPMOV = 'V'
     AND AD_ORIGEMINTEG = P_ORIGEMINTEG -- 16/06/21 - VINICIUS
     AND AD_IDPEDINTEG  = P_IDPEDINTEG;

  IF NVL(P_COUNTID, 0) > 0 THEN
    --SE EXISTE SAI DA ROTINA
     -- LOG IMPLEMENTADO 16/06/21 - VINICIUS
        STP_SNK_REGLOG('0.0_INSEREVENDA...OK:' || P_IDPEDINTEG ||'-'|| P_ORIGEMINTEG ||' EXISTE JA A VENDA COM O IDPEDINTEG'|| ' - STP_SNK_INCLUIR_CAB');
        P_ERROSP   := 'Falha: IDPEDINTEG Duplicado - '|| P_IDPEDINTEG ||'-'|| P_ORIGEMINTEG;
        RETURN;

  END IF;

  STP_SNK_REGLOGINTEG_SOLUTI(P_ORIGEMINTEG,
                             P_IDPEDINTEG,
                             P_NOMEPROCEDURE,
                             'INICIO');

  STP_SNK_REGLOG('1_INSEREVENDA...OK:' || P_ORIGEMINTEG || ' - ' ||
                 P_IDPEDINTEG || ' - ' || P_CNPJEMP || ' - ' || P_CODPROJ);
  --VALIDA XML
  SELECT DBMS_LOB.GETLENGTH(P_XMLITENS) INTO P_COUNTXMLITE FROM DUAL;
  SELECT DBMS_LOB.GETLENGTH(P_XMLFINANCEIRO) INTO P_COUNTXMLFIN FROM DUAL;
  SELECT DBMS_LOB.GETLENGTH(P_XMLNFSE) INTO P_COUNTXMLNFSE FROM DUAL;

  --VERIFICAR SE XML TEM VALOR, CASO TENHA ADICIONAR NA P_ITENSLIST
  IF NVL(P_COUNTXMLITE, 0) > 0 THEN
    P_ITENSLIST := XMLTYPE(P_XMLITENS);
  ELSE
    P_CODIGOSP := 0;
    P_ERROSP   := 'Falha: Xml Itens vazio!';

    STP_SNK_REGLOG('1.1_INSEREVENDA...OK: XML ITENS VAZIOS ' || P_IDPEDINTEG);

    STP_SNK_REGLOGINTEG_SOLUTI(P_ORIGEMINTEG,
                               P_IDPEDINTEG,
                               P_NOMEPROCEDURE,
                               P_ERROSP);

    RETURN; --TRATAR RETORNO QDO NAO EXISTE ITENS NO XML
  END IF;
  P_RG_IE := 'ISENTO';

  --VERIFICAR SE XML TEM VALOR, CASO TENHA ADICIONAR NA P_ITENSLIST
  IF NVL(P_COUNTXMLFIN, 0) > 0 THEN
    P_FINLIST := XMLTYPE(P_XMLFINANCEIRO);
  ELSE
    P_CODIGOSP := 0;
    P_ERROSP   := 'Falha: Xml Financeiro vazio!';

    STP_SNK_REGLOGINTEG_SOLUTI(P_ORIGEMINTEG,
                               P_IDPEDINTEG,
                               P_NOMEPROCEDURE,
                               P_ERROSP);

    RETURN; --TRATAR RETORNO QDO NAO EXISTE FINANCEIRO NO XML
  END IF;

  STP_SNK_REGLOG('2_INSEREVENDA...OK:' || P_ORIGEMINTEG || ' - ' ||
                 P_IDPEDINTEG || ' - ' || P_CNPJEMP || ' - ' || P_CODPROJ);

  --VERIFICAR SE XML TEM VALOR, CASO TENHA ADICIONAR NA P_NFSELIST
  IF NVL(P_COUNTXMLNFSE, 0) > 0 THEN
    P_NFSELIST := XMLTYPE(P_XMLNFSE);

  END IF;
  STP_SNK_REGLOG('3_INSEREVENDA...OK:' || P_ORIGEMINTEG || ' - ' ||
                 P_IDPEDINTEG || ' - ' || P_CNPJEMP || ' - ' || P_CODPROJ);
  STP_SNK_REGLOG('3.1_LEITURAXML...OK: cnpj:' || P_CNPJEMP || ' - prj:' ||
                 P_CODPROJ ||' - IDPEDINTEG: '|| P_IDPEDINTEG);

  --OBTEM PARAMETROS POR EMPRESA X PROJETO
  SELECT PARV.CODEMP,
         PARV.CODTIPOPER,
         PARV.CODNAT,
         PARV.CODTIPVENDA,
         PARV.CODCENCUS,
         PARV.CODUSUINC
    INTO P_CODEMP,
         P_CODTIPOPER,
         P_CODNAT,
         P_CODTIPVENDA,
         P_CODCENCUS,
         P_CODUSU
    FROM TSIEMP EMP, AD_SNKPARV PARV --CRIAR TABELA NO CONSTRUTOR DE TELAS
   WHERE EMP.CODEMP = PARV.CODEMP
     AND EMP.CGC = P_CNPJEMP
     AND PARV.CODPROJ = P_CODPROJ
     AND TRIM(PARV.ORIGEMINTEG) = TRIM(P_ORIGEMINTEG); --REGRA DA ORIGEM DA INTEGRACAO

  STP_SNK_REGLOG('4_INSEREVENDA...OK:' || P_ORIGEMINTEG || ' - ' ||
                 P_IDPEDINTEG || ' - ' || P_CNPJEMP || ' - ' || P_CODPROJ);

  STP_SNK_REGLOG('LEITURAPARAM...OK:' || P_CODEMP || '-' || P_CODTIPOPER || '-' ||
                 P_CODNAT || '-' || P_CODTIPVENDA || P_CODCENCUS);

  P_HISTORICO := 'Gerado pela Rotina do Integrador ' || P_ORIGEMINTEG;

  --IMPEDE DUPLICAÇÃO (NUM.NOTA X CODTIPOPER X CODEMP) --VER SE SAO UNICOS MESMO
  --REMOVIDO EM 20/03/21 PORQUE O NUMNOTA SEMPRE ZERADO

  SELECT NVL(MAX(CODEND), 0)
      INTO P_CODEND
    FROM TSIEND
   WHERE TRIM(UPPER(TRANSLATE(CODLOGRADOURO||' '|| NOMEEND,
                              'âàãáÁÂÀÃéêÉÊíÍóôõÓÔÕüúÜÚÇçñÑ',
                              'AAAAAAAAEEEEIIOOOOOOUUUUCCNN')))
        --TRIM(UPPER(REPLACE(REPLACE(TRANSLATE(NOMEEND,'âàãáÁÂÀÃéêÉÊíÍóôõÓÔÕüúÜÚÇçñÑ','AAAAAAAAEEEEIIOOOOOOUUUUCCNN'),CHR(09),''),CHR(11),'')))
         = TRIM(UPPER(TRANSLATE(P_ENDERECO,
                                'âàãáÁÂÀÃéêÉÊíÍóôõÓÔÕüúÜÚÇçñÑ',
                                'AAAAAAAAEEEEIIOOOOOOUUUUCCNN')))
        OR
        TRIM(UPPER(TRANSLATE(TIPO||' '||NOMEEND,
                              'âàãáÁÂÀÃéêÉÊíÍóôõÓÔÕüúÜÚÇçñÑ',
                              'AAAAAAAAEEEEIIOOOOOOUUUUCCNN')))
        --TRIM(UPPER(REPLACE(REPLACE(TRANSLATE(NOMEEND,'âàãáÁÂÀÃéêÉÊíÍóôõÓÔÕüúÜÚÇçñÑ','AAAAAAAAEEEEIIOOOOOOUUUUCCNN'),CHR(09),''),CHR(11),'')))
         = TRIM(UPPER(TRANSLATE(P_ENDERECO,
                                'âàãáÁÂÀÃéêÉÊíÍóôõÓÔÕüúÜÚÇçñÑ',
                                'AAAAAAAAEEEEIIOOOOOOUUUUCCNN')))
        OR

            TRIM(UPPER(TRANSLATE(NOMEEND,
                          'âàãáÁÂÀÃéêÉÊíÍóôõÓÔÕüúÜÚÇçñÑ',
                          'AAAAAAAAEEEEIIOOOOOOUUUUCCNN')))
        --TRIM(UPPER(REPLACE(REPLACE(TRANSLATE(NOMEEND,'âàãáÁÂÀÃéêÉÊíÍóôõÓÔÕüúÜÚÇçñÑ','AAAAAAAAEEEEIIOOOOOOUUUUCCNN'),CHR(09),''),CHR(11),'')))
         = TRIM(UPPER(TRANSLATE(P_ENDERECO,
                                'âàãáÁÂÀÃéêÉÊíÍóôõÓÔÕüúÜÚÇçñÑ',
                                'AAAAAAAAEEEEIIOOOOOOUUUUCCNN')));
  --TRIM(UPPER(REPLACE(REPLACE(TRANSLATE(P_ENDERECO,'âàãáÁÂÀÃéêÉÊíÍóôõÓÔÕüúÜÚÇçñÑ','AAAAAAAAEEEEIIOOOOOOUUUUCCNN'),CHR(09),''),CHR(11),'')));

  SELECT NVL(MAX(CODBAI), 0)
    INTO P_CODBAI
    FROM TSIBAI
   WHERE TRIM(UPPER(TRANSLATE(NOMEBAI,
                              'âàãáÁÂÀÃéêÉÊíÍóôõÓÔÕüúÜÚÇçñÑ',
                              'AAAAAAAAEEEEIIOOOOOOUUUUCCNN'))) =
         TRIM(UPPER(TRANSLATE(P_BAIRRO,
                              'âàãáÁÂÀÃéêÉÊíÍóôõÓÔÕüúÜÚÇçñÑ',
                              'AAAAAAAAEEEEIIOOOOOOUUUUCCNN')));

  SELECT NVL(MAX(CODCID), 0)
    INTO P_CODCID
    FROM TSICID CID, TSIUFS UFS
   WHERE CID.UF = UFS.CODUF
     AND TRIM(UPPER(TRANSLATE(NOMECID,
                              'âàãáÁÂÀÃéêÉÊíÍóôõÓÔÕüúÜÚÇçñÑ',
                              'AAAAAAAAEEEEIIOOOOOOUUUUCCNN'))) =
         TRIM(UPPER(TRANSLATE(P_CIDADE,
                              'âàãáÁÂÀÃéêÉÊíÍóôõÓÔÕüúÜÚÇçñÑ',
                              'AAAAAAAAEEEEIIOOOOOOUUUUCCNN')))
     AND TRIM(UPPER(UFS.UF)) = TRIM(UPPER(P_UF));

  SELECT COUNT(1)
    INTO P_COUNT
    FROM TSICEP
   WHERE CODCID = P_CODCID
     AND CODBAI = P_CODBAI
     AND CODEND = P_CODEND
     AND CEP = P_CEP;

  IF P_COUNT = 0 OR P_CODBAI = 0 OR P_CODEND = 0 THEN

    IF P_CODEND = 0 THEN

      SELECT MAX(CODEND) + 1 INTO P_CODEND FROM TSIEND;

      SELECT SUBSTR(P_ENDERECO, 0, 3) INTO P_TIPOEND FROM DUAL;

      P_COUNTEND := 0;
      SELECT NVL(COUNT(1), 0)
        INTO P_COUNTEND
        FROM TSITEND
       WHERE DESCRICAO LIKE INITCAP(P_TIPOEND) || '%'
         AND ROWNUM = 1;

      IF NVL(P_COUNTEND, 0) = 0 THEN
        P_TIPOEND2 := 'R';
      ELSE
        SELECT TIPO
          INTO P_TIPOEND2
          FROM TSITEND
         WHERE DESCRICAO LIKE INITCAP(P_TIPOEND) || '%'
           AND ROWNUM = 1;

      END IF;

      INSERT INTO TSIEND
        (CODEND, NOMEEND, TIPO, DTALTER)
      VALUES
        (P_CODEND, UPPER(P_ENDERECO), P_TIPOEND2, SYSDATE);

      COMMIT;

    END IF;

    IF P_CODBAI = 0 THEN

      SELECT NVL(MAX(CODBAI), 0) + 1 INTO P_CODBAI FROM TSIBAI;

      P_NOMEBAI := TRIM(UPPER(TRANSLATE(P_BAIRRO,
                                        'âàãáÁÂÀÃéêÉÊíÍóôõÓÔÕüúÜÚÇçñÑ',
                                        'AAAAAAAAEEEEIIOOOOOOUUUUCCNN')));

      INSERT INTO TSIBAI
        (CODBAI, NOMEBAI, DTALTER)
      VALUES
        (P_CODBAI, P_NOMEBAI, SYSDATE);
      COMMIT;

    END IF;

    IF P_CODCID = 0 THEN
      /*
      RAISE_APPLICATION_ERROR(-20101,
                              FC_FORMAT_RAISE('OPERAÇÃO NÃO PERMITIDA',
                                              'CIDADE NÃO HABILITADA PARA ENTREGA',
                                              'PARA UTILIZAR ESSA CIDADE NA INTEGRAÇÃO, CIDADE DEVE SER CONFIGURADA NO SANKHYA PELA CONTABILIDADE: IMPOSTOS, CÓDIGO IBGE, ETC'));
      */
      SELECT NVL(MAX(CODCID), 0) + 1 INTO P_CODCID FROM TSICID;

      P_NOMECID := TRIM(UPPER(TRANSLATE(P_CIDADE,
                                        'âàãáÁÂÀÃéêÉÊíÍóôõÓÔÕüúÜÚÇçñÑ',
                                        'AAAAAAAAEEEEIIOOOOOOUUUUCCNN')));

      INSERT INTO TSICID
        (CODCID, NOMECID, DTALTER)
      VALUES
        (P_CODCID, P_NOMECID, SYSDATE);
      COMMIT;

    END IF;

    INSERT INTO TSICEP
      (CODCID, CODBAI, CODEND, CEP)
    VALUES
      (P_CODCID, P_CODBAI, P_CODEND, P_CEP);
    COMMIT;

  END IF;

  SELECT COUNT(1), NVL(MAX(CODPARC), 0)
    INTO P_COUNT, P_CODPARC
    FROM TGFPAR
   WHERE TRIM(REGEXP_REPLACE(CGC_CPF, '[^[:digit:]]')) =
         TRIM(REGEXP_REPLACE(P_CPF_CNPJ, '[^[:digit:]]'));

  IF P_COUNT = 0 THEN

    -- GERA CADASTRO DO PARCEIRO QUANDO NÃO EXISTIR

    SELECT NVL(MAX(CODPARC), 0) + 1 INTO P_CODPARC FROM TGFPAR;
    STP_SNK_REGLOG('5_INSEREVENDA...OK:' || P_ORIGEMINTEG || ' - ' ||
                   P_IDPEDINTEG || ' - ' || P_CNPJEMP || ' - ' ||
                   P_CODPROJ);

    STP_SNK_INCLUIR_PAR(P_CODPARC,
                        TO_CHAR(TRIM(REGEXP_REPLACE(P_CPF_CNPJ,
                                                    '[^[:digit:]]'))),
                        UPPER(TRIM(SUBSTR(P_FANTASIA,1,100))),
                        UPPER(TRIM(SUBSTR(P_RAZAOSOCIAL,1,100))),
                        UPPER(TRIM(P_SEXO)),
                        UPPER(TRIM(P_RG_IE)),
                        REPLACE(REPLACE(REPLACE(P_FONE, '(', ''), ')', ' '),
                                '-',
                                ''),
                        TRIM(P_EMAIL),
                        TO_CHAR(TRIM(REGEXP_REPLACE(P_CEP, '[^[:digit:]]'))),
                        P_CODEND,
                        UPPER(TRIM(P_NUMEND)),
                        TRIM(UPPER(TRANSLATE(P_COMPLEMENTO,
                                             'âàãáÁÂÀÃéêÉÊíÍóôõÓÔÕüúÜÚÇçñÑ',
                                             'AAAAAAAAEEEEIIOOOOOOUUUUCCNN'))),
                        P_CODBAI,
                        P_CODCID,
                        P_CODVEND,
                        P_CODUSU,
                        P_ORIGEMINTEG,
                        P_DEBUG,
                        P_SEQLOG);

  END IF;

  SELECT COUNT(1)
    INTO P_COUNT
    FROM TGFPAR
   WHERE CEP = P_CEP
     AND CODEND = P_CODEND
     AND NUMEND = P_NUMEND
     AND COMPLEMENTO =
         TRIM(UPPER(TRANSLATE(P_COMPLEMENTO,
                              'âàãáÁÂÀÃéêÉÊíÍóôõÓÔÕüúÜÚÇçñÑ',
                              'AAAAAAAAEEEEIIOOOOOOUUUUCCNN')))
     AND CODBAI = P_CODBAI
     AND CODCID = P_CODCID
     AND TELEFONE =
         REPLACE(REPLACE(REPLACE(P_FONE, '(', ''), ')', ' '), '-', '')
     AND EMAIL = TRIM(P_EMAIL);

  IF P_COUNT = 0 THEN
    STP_SNK_REGLOG('6_INSEREVENDA...OK:' || P_ORIGEMINTEG || ' - ' ||
                   P_IDPEDINTEG || ' - ' || P_CNPJEMP || ' - ' ||
                   P_CODPROJ);
    UPDATE TGFPAR
       SET TELEFONE    = TRIM(REGEXP_REPLACE(P_FONE, '[^[:digit:]]')),
           EMAIL       = TRIM(P_EMAIL),
           CEP         = P_CEP,
           CODEND      = P_CODEND,
           NUMEND      = P_NUMEND,
           COMPLEMENTO = TRIM(UPPER(TRANSLATE(P_COMPLEMENTO,
                                              'âàãáÁÂÀÃéêÉÊíÍóôõÓÔÕüúÜÚÇçñÑ',
                                              'AAAAAAAAEEEEIIOOOOOOUUUUCCNN'))),
           CODBAI      = P_CODBAI,
           CODCID      = P_CODCID,
           CODUSU      = P_CODUSU,
           DTALTER     = SYSDATE
     WHERE CODPARC = P_CODPARC;

  END IF;

  --IMPEDE ERRO EM TRIGGER Q VERIFICA SE CLIENTE/FORNECEDOR NULL
  UPDATE TGFPAR SET CLIENTE = 'S' WHERE CODPARC = P_CODPARC;

  --STP_SNK_REGLOG('OBTEMPARC...OK:'||P_CODPARC);

  ----------------------------
  --INSERE CABEÇALHO DA NOTA
  ----------------------------
  --TRATAR CODVEND PELO CPF DO PARAMETRO
  STP_SNK_REGLOG('7_INSEREVENDA...OK:' || P_ORIGEMINTEG || ' - ' ||
                 P_IDPEDINTEG || ' - ' || P_CNPJEMP || ' - ' || P_CODPROJ);

  FOR C1 IN (SELECT P_NUMNOTA AS NUMNOTA,
                    P_SERIENOTA AS SERIENOTA, --, SUBSTR(FC_GET_TAG_XML(P_XML,'<Serie>','</Serie>'),1,2) AS SERIENOTA
                    P_CODEMP AS CODEMP,
                    P_CODEMP AS CODEMPNEGOC,
                    P_CODNAT AS CODNAT,
                    P_CODCENCUS AS CODCENCUS,
                    P_CODPROJ AS CODPROJ,
                    P_CODTIPOPER AS CODTIPOPER,
                    P_CODTIPVENDA AS CODTIPVENDA,
                    P_CODPARC AS CODPARC,
                    NULL CODCONTATO,
                    0 NUMCONTRATO,
                    0 AS VLRNOTA,
                    0 AS CODPARCTRANSP,
                    'C' CIF_FOB,
                    P_DISCRIMINACAO AS OBSERVACAO, --
                    TO_DATE(P_DTNOTA, 'YYYY-MM-DD') AS DTFATUR, --TRUNC(TO_DATE(P_DTNOTA, 'YYYY/MM/DD HH24:MI:SS')) DTFATUR,--, TRUNC(TO_DATE(TRANSLATE(FC_GET_TAG_XML(P_XML,'<DataEmissao>','</DataEmissao>'),'T',' '),'YYYY/MM/DD HH24:MI:SS')) DTFATUR
                    P_CODUSU AS CODUSU,
                    P_BASEISS AS BASEISS,
                    P_ALIQISS AS ALIQISS,
                    NVL(P_ISSRETIDO, 'N') AS ISSRETIDO, --, DECODE(FC_GET_TAG_XML(P_XML,'<IssRetido>','</IssRetido>'),1,'S','N') ISSRETIDO
                    NULL CODVERIFNFSE
               FROM DUAL)

   LOOP
    STP_SNK_REGLOG('8_INSEREVENDA...OK:' || P_ORIGEMINTEG || ' - ' ||
                   P_IDPEDINTEG || ' - ' || P_CNPJEMP || ' - ' ||
                   P_CODPROJ);
    --OBTEM CODVEND DA TELA USUARIO PELO CPF INFORMADO      

    SELECT COUNT(1)
      INTO P_EXISTEVEND
      FROM TSIUSU USU, TGFVEN VEN
     WHERE USU.CODVEND = VEN.CODVEND
       AND USU.CODVEND > 0
          -- AND USU.DTLIMACESSO IS NULL --USUARIO ATIVO
          -- AND VEN.ATIVO='S' --SE VENDEDOR NAO É ATIVO, ERRO TRIGGER
       AND TRIM(USU.CPF) = TRIM(P_CPFCNPJVEND);

    IF NVL(P_EXISTEVEND, 0) = 1 THEN
      SELECT NVL(USU.CODVEND, 0)
        INTO P_CODVEND
        FROM TSIUSU USU, TGFVEN VEN
       WHERE USU.CODVEND = VEN.CODVEND
         AND USU.CODVEND > 0
            -- AND USU.DTLIMACESSO IS NULL --USUARIO ATIVO
            -- AND VEN.ATIVO='S' --SE VENDEDOR NAO É ATIVO, ERRO TRIGGER
         AND TRIM(USU.CPF) = TRIM(P_CPFCNPJVEND);
    ELSE
      P_CODVEND := 2308;
    END IF;

    STP_SNK_REGLOG('9_INSEREVENDA...OK:' || P_ORIGEMINTEG || ' - ' ||
                   P_IDPEDINTEG || ' - ' || P_CNPJEMP || ' - ' ||
                   P_CODPROJ);


    --INSERE CABECALHO DA NOTA
    SELECT NVL(MAX(NUNOTA), 0) + 1 INTO P_NUNOTA FROM TGFCAB;

    -- GARANTE QUE NÃO HÁ O NÚMERO NA TGFCAB - 16/06/2021 VINICIUS
    SELECT COUNT(1) INTO P_COUNTCAB FROM TGFCAB WHERE NUNOTA = P_NUNOTA;

    IF (P_COUNTCAB = 0) THEN

    STP_SNK_INCLUIR_CAB(P_NUNOTA,
                        C1.NUMNOTA,
                        C1.SERIENOTA,
                        C1.DTFATUR,
                        C1.CODEMP,
                        C1.CODEMPNEGOC,
                        P_CODVEND, --CODVEND
                        C1.CODPARC,
                        C1.CODCONTATO,
                        C1.CODTIPOPER,
                        C1.CODTIPVENDA,
                        C1.CODNAT,
                        C1.CODCENCUS,
                        C1.CODPROJ,
                        C1.OBSERVACAO,
                        C1.NUMCONTRATO,
                        C1.CODPARCTRANSP,
                        C1.CIF_FOB,
                        C1.CODUSU,
                        P_ORIGEMINTEG,
                        P_IDPEDINTEG,
                        P_DEBUG,
                        P_SEQLOG);
    STP_SNK_REGLOG('10_INSEREVENDA...OK:' || P_ORIGEMINTEG || ' - ' ||
                   P_IDPEDINTEG || ' - ' || P_CNPJEMP || ' - ' ||
                   P_CODPROJ || ' - ' ||  P_COUNTITE);

    -- COMMIT DO SAVEPOINT
    COMMIT;

    ELSE 
          --  GRAVA O LOG - 16/06/2021 VINICIUS
        STP_SNK_REGLOG('10.9_INSEREVENDA...OK:' || P_NUNOTA ||' - '|| P_IDPEDINTEG ||' EXISTE NA TGFCAB '|| ' - STP_SNK_INCLUIR_CAB');
        P_ERROSP   := 'Falha: NUNOTA duplicado';
        ROLLBACK TO MY_SAVEPOINT;
        RETURN;

    END IF;

    ---------------------------
    --INSERE ITEM(S) PELO XML
    ---------------------------
    WHILE P_ITENSLIST.EXISTSNODE('//item[' || P_COUNTITE || ']') = 1 LOOP

      P_CODPROD := (P_ITENSLIST.EXTRACT('//item[' || P_COUNTITE ||']/codproduto/text()')
                   .GETSTRINGVAL());
      --LOG 10.1
      STP_SNK_REGLOG('10.1_INSEREVENDA...OK:' || P_CODPROD || ' - '|| P_IDPEDINTEG  ||' - loop2');

      P_QTDNEG  := (P_ITENSLIST.EXTRACT('//item[' || P_COUNTITE ||']/qtdneg/text()')
                   .GETSTRINGVAL());
        --LOG 10.2
      STP_SNK_REGLOG('10.2_INSEREVENDA...OK:' || P_QTDNEG ||' - '|| P_IDPEDINTEG  || ' - loop2');

      P_VLRUNIT := TO_NUMBER((P_ITENSLIST.EXTRACT('//item[' || P_COUNTITE ||']/vlrunit/text()')
                             .GETSTRINGVAL()),
                             '99999.99');
       --LOG 10.3
      STP_SNK_REGLOG('10.3_INSEREVENDA...OK:' || P_VLRUNIT ||' - '|| P_IDPEDINTEG  || ' - loop2');

      P_VLRDESC := TO_NUMBER((P_ITENSLIST.EXTRACT('//item[' || P_COUNTITE ||']/vlrdesc/text()')
                             .GETSTRINGVAL()),
                             '99999.99');
      --LOG 10.4
      STP_SNK_REGLOG('10.4_INSEREVENDA...OK:' || P_VLRDESC ||' - '|| P_IDPEDINTEG  || ' - loop2');

      --CALCULA ITEM
      P_VLRTOTAL := NVL(P_VLRTOTAL, 0) +
                    (NVL(P_VLRUNIT, 0) * NVL(P_QTDNEG, 0)); -- + P_VLRISS

       --LOG 10.5
      STP_SNK_REGLOG('10.5_INSEREVENDA...OK:' || P_VLRTOTAL ||' - '|| P_IDPEDINTEG  || ' - loop2');

      --IF 
      --% DESCONTO
      IF NVL(P_VLRDESC, 0) = 0 THEN
        P_PERCDESC := 0;
        --LOG 10.6
        STP_SNK_REGLOG('10.6_INSEREVENDA...OK: %DESC: ' || P_PERCDESC ||' - '|| P_IDPEDINTEG  || ' - loop2');
      ELSE
        P_PERCDESC := TRUNC(((NVL(P_VLRDESC, 0)) / (P_VLRTOTAL) * 100), 2);
        --LOG 10.7
        STP_SNK_REGLOG('10.7_INSEREVENDA...OK: %DESC: ' || P_PERCDESC ||' - '|| P_IDPEDINTEG  || ' - loop2');

      END IF;

      -- DESCONTO NO VALOR TOTAL
      IF NVL(P_VLRDESC, 0) = 0
      THEN
        P_VLRTOTAL := P_VLRTOTAL;
      ELSE
        P_VLRTOTAL := (P_VLRTOTAL - P_VLRDESC);
      END IF;

      STP_SNK_REGLOG('10.8_INSEREVENDA...OK:' || P_ORIGEMINTEG || ' - ' ||
                   P_IDPEDINTEG || ' - ' || P_CNPJEMP || ' - ' ||
                   P_CODPROJ || ' - loop2');

      SELECT NVL(MAX(SEQUENCIA), 0) + 1
        INTO P_SEQUENCIA
        FROM TGFITE
       WHERE NUNOTA = P_NUNOTA;

      --OBTEM LOCAL ESTOQUE PELO PROJETO
      SELECT NVL(AD_CODLOCAL, 0)
        INTO P_CODLOCAL
        FROM TCSPRJ
       WHERE CODPROJ = P_CODPROJ;

      STP_SNK_REGLOG('11_INSEREVENDA...OK:' || P_CODLOCAL || ' - ' ||
                     P_IDPEDINTEG);

      SELECT NVL(COUNT(1), 0)
        INTO P_COUNTKIT
        FROM TGFICP
       WHERE CODPROD = P_CODPROD;

      IF P_COUNTKIT > 0 THEN
        P_CODLOCALORIG := P_CODLOCAL;

      ELSE
        P_CODLOCALORIG := 0;
      END IF;

      SELECT PRO.CODPROD,
             PRO.CODVOL,
             PRO.USOPROD,
             NVL(P_PERCDESC, 0) AS PERCDESC,
             NVL(P_VLRDESC, 0) AS VLRDESC,
             0 AS PRECOBASE,
             0 AS VLRCUS,
             0 AS VLRREPRED,
             NVL(P_CODLOCALORIG, 0) AS CODLOCALORIG,
             NULL AS NUNOTAORIG,
             NULL AS NUTAB,
             NULL AS ALIQICMS,
             0 AS VLRICMS,
             0 AS ALIQIPI,
             0 AS VLRIPI,
             NULL AS IDALIQICMS
        INTO P_CODPROD,
             P_CODVOL,
             P_USOPROD,
             P_PERCDESC,
             P_VLRDESC,
             P_PRECOBASE,
             P_VLRCUS,
             P_VLRREPRED,
             P_CODLOCALORIG,
             P_NUNOTAORIG,
             P_NUTAB,
             P_ALIQICMS,
             P_VLRICMS,
             P_ALIQIPI,
             P_VLRIPI,
             P_IDALIQICMS
        FROM TGFPRO PRO
       WHERE PRO.CODPROD = P_CODPROD;

      STP_SNK_REGLOG('12_INSEREVENDA...OK:' || P_CODLOCAL || ' - ' ||
                     P_IDPEDINTEG);

      -- VERIFICA SE HÁ INTEGRIDADE ENTRE OS ITENS E O CABEÇALHO
     SELECT (AD_IDPEDINTEG - P_IDPEDINTEG) 
        INTO 
             P_COUNTCAB
        FROM TGFCAB 
       WHERE NUNOTA = P_NUNOTA; 

     IF (P_COUNTCAB = 0) THEN
      --INSERE ITENS
      STP_SNK_INCLUIR_ITE(P_NUNOTA,
                          P_SEQUENCIA,
                          P_NUTAB,
                          P_CODPROD,
                          P_CODVOL,
                          P_QTDNEG,
                          P_VLRUNIT,
                          P_PERCDESC,
                          P_VLRDESC,
                          P_PRECOBASE,
                          P_VLRCUS,
                          P_VLRREPRED,
                          P_CODLOCALORIG,
                          P_DISCRIMINACAO,
                          P_USOPROD,
                          P_DEBUG,
                          P_ORIGEMINTEG,
                          P_IDPEDINTEG);

      STP_SNK_REGLOG('13_INSEREVENDA...OK:' || P_CODLOCAL || ' - ' ||
                     P_IDPEDINTEG);
      ELSE

      STP_SNK_REGLOG('13.1_INSEREVENDA...OK:' || P_IDPEDINTEG || ' - ' ||
                     'IDPEDINTEG DIFERENTE DA TGFCAB');
      P_CODIGOSP := 0;
      P_ERROSP   := 'Falha na INSEREVENDA - IDPEDINTEG já encontrado na TGFCAB';
      RETURN;

      END IF;
      --ATUALIZA ISS NOS ITENS
      UPDATE TGFITE
         SET BASEISS = P_BASEISS, 
             ALIQISS = P_ALIQISS, 
             VLRISS = P_VLRISS
       WHERE NUNOTA = P_NUNOTA
         AND SEQUENCIA = P_SEQUENCIA;
      -- ATUALIZA QUANDO TEM MATÉRIA PRIMA PARA COMPOR O KIT 
      UPDATE TGFITE
         SET VLRDESC = 0, 
             PERCDESC = 0,
             VLRTOT = 0
       WHERE NUNOTA = P_NUNOTA
         AND USOPROD IN ('D', 'M', 'B');

      -- ACERTANDO A NOTA QUANDO TEM KIT

      SELECT 
             COUNT(1)
        INTO 
             P_COUNTCAB
        FROM TGFITE
       WHERE NUNOTA = P_NUNOTA
         AND USOPROD IN ('D', 'M', 'B');

      IF (P_COUNTCAB > 0) 
      THEN
        P_COUNTCAB := 0;

         UPDATE TGFCAB
            SET VLRDESCTOTITEM = (SELECT SUM(VLRDESC) FROM TGFITE WHERE NUNOTA = P_NUNOTA), 
                VLRNOTA        = (SELECT SUM(VLRTOT - VLRDESC) FROM TGFITE WHERE NUNOTA = P_NUNOTA)
          WHERE NUNOTA         = P_NUNOTA;

          STP_SNK_REGLOG('13.2_INSEREVENDA...OK: ' || P_IDPEDINTEG || ' - ' || P_NUNOTA || ' ATUALIZANDO A NOTA COM KIT');

      END IF;

  --FIM KIT

      P_COUNTITE := P_COUNTITE + 1;

    END LOOP;

    STP_SNK_REGLOG('14_INSEREVENDA...OK:' || P_CODLOCAL || ' - ' ||
                   P_IDPEDINTEG);

    -------------------------------------------------
    -- INSERIR PARCELAS NA MOV. FINANCEIRA PELO XML
    -------------------------------------------------
    WHILE P_FINLIST.EXISTSNODE('//parcela[' || P_COUNTFIN || ']') = 1 LOOP

      P_TIPO := (P_FINLIST.EXTRACT('//parcela[' || P_COUNTFIN ||']/tipo/text()')
                .GETSTRINGVAL());

      IF UPPER(TRIM(P_TIPO)) = 'CARTAO' THEN
        --OBTEM DADOS DE CARTAO

        P_CODTIPTIT := (P_FINLIST.EXTRACT('//parcela[' || P_COUNTFIN ||']/codtiptit/text()')
                       .GETSTRINGVAL());

        P_REDE    := 4;
        P_TIPODOC := P_CODTIPTIT;

        P_DESDOB      := (P_FINLIST.EXTRACT('//parcela[' || P_COUNTFIN ||']/desdob/text()')
                         .GETSTRINGVAL());
        P_OPERADORA   := (P_FINLIST.EXTRACT('//parcela[' || P_COUNTFIN ||']/operadora/text()')
                         .GETSTRINGVAL());
        P_BANDEIRA    := (P_FINLIST.EXTRACT('//parcela[' || P_COUNTFIN ||']/bandeira/text()')
                         .GETSTRINGVAL());
        P_NUMNSU      := (P_FINLIST.EXTRACT('//parcela[' || P_COUNTFIN ||']/numnsu/text()')
                         .GETSTRINGVAL());
        P_AUTORIZACAO := (P_FINLIST.EXTRACT('//parcela[' || P_COUNTFIN ||']/autorizacao/text()')
                         .GETSTRINGVAL());
        P_DTVENC      := (P_FINLIST.EXTRACT('//parcela[' || P_COUNTFIN ||']/dtvenc/text()')
                         .GETSTRINGVAL());
        P_VLRPARCELA  := TO_NUMBER((P_FINLIST.EXTRACT('//parcela[' || P_COUNTFIN ||']/vlrtransacao/text()')
                                   .GETSTRINGVAL()),
                                   '99999.99');
        P_VLRTAXA     := TO_NUMBER((P_FINLIST.EXTRACT('//parcela[' || P_COUNTFIN ||']/vlrtaxa/text()')
                                   .GETSTRINGVAL()),
                                   '99999.99');

        P_VLRISSFIN    := TO_NUMBER((P_FINLIST.EXTRACT('//parcela[' || P_COUNTFIN ||']/vlriss/text()')
                                    .GETSTRINGVAL()),
                                    '99999.99');
        P_ISSRETIDOFIN := (P_FINLIST.EXTRACT('//parcela[' || P_COUNTFIN ||']/issretido/text()')
                          .GETSTRINGVAL());

        P_BANCO   := (P_FINLIST.EXTRACT('//parcela[' || P_COUNTFIN ||']/banco/text()')
                     .GETSTRINGVAL());
        P_AGENCIA := (P_FINLIST.EXTRACT('//parcela[' || P_COUNTFIN ||']/agencia/text()')
                     .GETSTRINGVAL());
        P_CONTA   := (P_FINLIST.EXTRACT('//parcela[' || P_COUNTFIN ||']/conta/text()')
                     .GETSTRINGVAL());

      ELSIF UPPER(TRIM(P_TIPO)) = 'BOLETO' THEN
        --OBTEM DADOS DO BOLETO

        P_CODTIPTIT := (P_FINLIST.EXTRACT('//parcela[' || P_COUNTFIN ||']/codtiptit/text()')
                       .GETSTRINGVAL());

        P_DESDOB         := (P_FINLIST.EXTRACT('//parcela[' || P_COUNTFIN ||']/desdob/text()')
                            .GETSTRINGVAL());
        P_NOSSONUMERO    := (P_FINLIST.EXTRACT('//parcela[' || P_COUNTFIN ||']/nossonumero/text()')
                            .GETSTRINGVAL());
        P_CODIGOBARRA    := (P_FINLIST.EXTRACT('//parcela[' || P_COUNTFIN ||']/codigobarra/text()')
                            .GETSTRINGVAL());
        P_LINHADIGITAVEL := (P_FINLIST.EXTRACT('//parcela[' || P_COUNTFIN ||']/linhadigitavel/text()')
                            .GETSTRINGVAL());
        P_DTVENC         := (P_FINLIST.EXTRACT('//parcela[' || P_COUNTFIN ||']/dtvenc/text()')
                            .GETSTRINGVAL());

        P_VLRPARCELA := TO_NUMBER((P_FINLIST.EXTRACT('//parcela[' || P_COUNTFIN ||']/vlrboleto/text()')
                                  .GETSTRINGVAL()),
                                  '99999.99');
        P_VLRJURO    := TO_NUMBER((P_FINLIST.EXTRACT('//parcela[' || P_COUNTFIN ||']/vlrjuro/text()')
                                  .GETSTRINGVAL()),
                                  '99999.99');
        P_VLRMULTA   := TO_NUMBER((P_FINLIST.EXTRACT('//parcela[' || P_COUNTFIN ||']/vlrmulta/text()')
                                  .GETSTRINGVAL()),
                                  '99999.99');
        P_VLRDESCFIN := TO_NUMBER((P_FINLIST.EXTRACT('//parcela[' || P_COUNTFIN ||']/vlrdesc/text()')
                                  .GETSTRINGVAL()),
                                  '99999.99');
        P_VLRTAXA    := TO_NUMBER((P_FINLIST.EXTRACT('//parcela[' || P_COUNTFIN ||']/vlrtaxa/text()')
                                  .GETSTRINGVAL()),
                                  '99999.99');

        P_VLRISSFIN := TO_NUMBER((P_FINLIST.EXTRACT('//parcela[' || P_COUNTFIN ||']/vlriss/text()')
                                 .GETSTRINGVAL()),
                                 '99999.99');

        P_ISSRETIDOFIN := (P_FINLIST.EXTRACT('//parcela[' || P_COUNTFIN ||']/issretido/text()')
                          .GETSTRINGVAL());

        P_BANCO   := (P_FINLIST.EXTRACT('//parcela[' || P_COUNTFIN ||']/banco/text()')
                     .GETSTRINGVAL());
        P_AGENCIA := (P_FINLIST.EXTRACT('//parcela[' || P_COUNTFIN ||']/agencia/text()')
                     .GETSTRINGVAL());
        P_CONTA   := (P_FINLIST.EXTRACT('//parcela[' || P_COUNTFIN ||']/conta/text()')
                     .GETSTRINGVAL());

        /*STP_SNK_REGLOG('TESTE34:' || P_CODTIPTIT || '-' || P_DESDOB || '-' ||
        P_DTVENC || '-' || P_VLRPARCELA || '-' || P_BANCO || '-' ||
        P_AGENCIA || '-' || P_CONTA || '-' || P_TIPO);*/
      ELSIF UPPER(TRIM(P_TIPO)) = 'PIX' THEN
        --PIX (TRATAR)
        P_CODTIPTIT := 0;

      END IF;

      P_DTVENC := SUBSTR(P_DTVENC, 1, 10);

      P_COUNTFIN := P_COUNTFIN + 1;

      --OBTEM DADOS DA CONTA OBTIDA DO XML DA PARCELA
      ------------------------------------------------
      SELECT NVL(COUNT(1), 0)
        INTO P_COUNTCTA
        FROM TSICTA CTA
       WHERE CTA.ATIVA = 'S'
         AND CTA.CLASSE IN ('C', 'O') --SOMENTE CONTA CORRENTE
         AND CTA.CODBCO = TRIM(SUBSTR(P_BANCO, 1, 3))
         AND (SUBSTR(CTA.CODAGE, -4) = SUBSTR(P_AGENCIA, -4) OR
             SUBSTR(CTA.CODAGE, 1, 4) = SUBSTR(P_AGENCIA, -4))
         AND LPAD(TRIM(REPLACE(CTA.CODCTABCO, '-', '')),
                  LENGTH(P_CONTA),
                  '0') = SUBSTR(P_CONTA, LENGTH(P_CONTA) * -1);

      IF NVL(P_COUNTCTA, 0) = 1 THEN
        --ENCONTROU CONTA

        SELECT NVL(CODCTABCOINT, 0)
          INTO P_CODCTABCOINT
          FROM TSICTA CTA
         WHERE CTA.ATIVA = 'S'
           AND CTA.CLASSE IN ('C', 'O') --SOMENTE CONTA CORRENTE
           AND CTA.CODBCO = TRIM(SUBSTR(P_BANCO, 1, 3))
           AND (SUBSTR(CTA.CODAGE, -4) = SUBSTR(P_AGENCIA, -4) OR
               SUBSTR(CTA.CODAGE, 1, 4) = SUBSTR(P_AGENCIA, -4))
           AND LPAD(TRIM(REPLACE(CTA.CODCTABCO, '-', '')),
                    LENGTH(P_CONTA),
                    '0') = SUBSTR(P_CONTA, LENGTH(P_CONTA) * -1);
      ELSE
        P_CODCTABCOINT := 0; --NAO ENCONTROU (USUARIO ALTERA NO FINANCEIRO)
        --STP_SNK_REGLOG('OBTEMCONTA...OK:'||P_BANCO||'-'||P_AGENCIA||'-'||P_CONTA);

      END IF;

      --STP_SNK_REGLOG('OBTEMCONTA...OK:'||P_CODCTABCOINT||'-'||P_NUNOTA||'-'||P_BANCO||'-'||P_AGENCIA||'-'||P_CONTA);

      --P_CODCTABCOINT := 8;

      --INSERE FINANCEIRO
      --SELECT SEQ_TGFFIN_NUFIN.NEXTVAL INTO P_NUFIN FROM DUAL;
      STP_OBTEMID('TGFFIN', P_NUFIN);

      STP_SNK_INCLUIR_FIN(P_NUFIN,
                          P_NUNOTA,
                          P_NUMNOTA,
                          P_DESDOB,
                          P_VLRPARCELA, --VLRDESDOB
                          SYSDATE, --P_DTNOTA,
                          P_DTVENC,
                          P_CODEMP,
                          P_CODPARC,
                          P_CODTIPOPER,
                          P_CODNAT,
                          P_CODCENCUS,
                          P_CODPROJ,
                          P_CODCTABCOINT, --
                          P_CODTIPTIT,
                          P_CODVEND,
                          P_SEQUENCIA,
                          0, --NUMCONTRATO,
                          P_HISTORICO,
                          P_NOSSONUMERO,
                          P_CODIGOBARRA,
                          P_LINHADIGITAVEL,
                          NVL(P_VLRJURO, 0),
                          NVL(P_VLRMULTA, 0),
                          NVL(P_VLRDESCFIN, 0),
                          0, --VLRVENDOR
                          P_VLRISSFIN, --VLRISS (P_VLRISSFIN)
                          NVL(P_ISSRETIDOFIN, 'N'),
                          P_DEBUG,
                          P_SEQLOG); --ISSRETIDO

      --PARA CARTAO, INSERTE NA TGFTEF DADOS TRANSACAO
      ------------------------------------------------

      IF UPPER(TRIM(P_TIPO)) = 'CARTAO' AND P_NUFIN > 0 THEN

        --INSERE NA TGFTEF
        INSERT INTO TGFTEF
          (NUFIN,
           REDE,
           TIPODOC,
           NUMCV,
           NUMDOC,
           NUMNSU,
           NUMPV,
           AUTORIZACAO,
           DESDOBRAMENTO,
           DTTRANSACAO,
           VLRTRANSACAO,
           VLRTAXA,
           BANDEIRA,
           CODUSU)
        VALUES
          (P_NUFIN,
           P_REDE,
           P_TIPODOC,
           NULL, --NUMCV,
           P_NUMNOTA,
           LPAD(P_NUMNSU, 15, '0'),
           NULL, --NUMPV
           LPAD(P_AUTORIZACAO, 15, '0'),
           P_DESDOB,
           SYSDATE, --SYSDATE,--P_DTNOTA,
           P_VLRPARCELA,
           P_VLRTAXA,
           P_BANDEIRA,
           P_CODUSU);

        --INSERE TAXA DO CARTAO

      END IF;
    END LOOP;

    --SETA FINANCEIRO COMO REAL
    UPDATE TGFFIN SET PROVISAO = 'S' WHERE NUNOTA = P_NUNOTA;

    --CALCULA E ATUALIZA ISS NO CABECALHO DA NOTA
    UPDATE TGFCAB
       SET BASEISS   = NVL((SELECT SUM(BASEISS)
                             FROM TGFITE
                            WHERE NUNOTA = P_NUNOTA),
                           0),
           VLRISS    = NVL((SELECT SUM(VLRISS)
                             FROM TGFITE
                            WHERE NUNOTA = P_NUNOTA),
                           0),
           ISSRETIDO = C1.ISSRETIDO
     WHERE NUNOTA = P_NUNOTA;

  END LOOP;

  --ATUALIZA CHAVE DO FINANCEIRO

  SELECT NVL(MAX(NUFIN), 0) 
    INTO P_NUFIN
    FROM TGFFIN;

  UPDATE TGFNUM
     SET ULTCOD = P_NUFIN
   WHERE ARQUIVO = 'TGFFIN';
  /*UPDATE TGFNUM
     SET ULTCOD = NVL((SELECT NVL(MAX(NUNOTA), 0) FROM TGFCAB), 0)
   WHERE ARQUIVO = 'TGFCAB';*/

  COMMIT;


  STP_SNK_REGLOG('FIM_INSEREVENDA...OK');

  --FINALIZA LOG
  /*STP_SNK_REGISTRAR_LOG('S', NULL, NULL, NULL, NULL,
  NULL, NULL, NULL, NULL, P_NUNOTA,
  'CONCLUIDO', '', P_SEQLOG);*/

  --VALIDA RESULTADO

  IF NVL(P_NUNOTA, 0) > 0 THEN

    P_CODIGOSP := P_NUNOTA;
    P_ERROSP   := '';
    RETURN;

  ELSE

    P_CODIGOSP := 0;
    P_ERROSP   := 'Falha na geração da venda!';

    STP_SNK_REGLOG('INSEREVENDA_FALHA: ' || P_ERROSP);

    STP_SNK_REGLOGINTEG_SOLUTI(P_ORIGEMINTEG,
                               P_IDPEDINTEG,
                               P_NOMEPROCEDURE,
                               P_ERROSP);

    RETURN;

  END IF;

  -- END IF; --IMPEDE-DUPLICA NOTA (PERMITIDO)

  --RETURN;

EXCEPTION

  WHEN OTHERS THEN
    --ROLLBACK; --DESFAZ
    ROLLBACK TO MY_SAVEPOINT;
    ERR_CODE := SQLCODE;
    ERR_MSG  := SQLERRM;

    P_CODIGOSP := 0;
    P_ERROSP   := 'Exception: ' || ERR_CODE || '-' || ERR_MSG; --
    --P_ERROSP   := 'Exception: ' || ERR_CODE || '-' || ERR_MSG || '-' ||SQL%BULK_ROWCOUNT; 

    STP_SNK_REGLOGINTEG_SOLUTI(P_ORIGEMINTEG,
                               P_IDPEDINTEG,
                               P_NOMEPROCEDURE,
                               P_ERROSP);

    STP_SNK_REGLOG('INSEREVENDA_EXCEPTION: ' || P_ERROSP);

    RETURN;

END;
