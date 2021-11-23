create or replace PROCEDURE STP_SNK_EMAILPEDPEND_SOLUTI
 AS
    P_COUNT NUMBER(10);
    P_ASSUNTO VARCHAR2(4000);
    P_TABINI VARCHAR2(4000);
    P_TABFIN VARCHAR2(4000);
    P_TABCAB VARCHAR(4000);
    V_MSG  CLOB;
    P_DIAMAIS1 VARCHAR(60);
    P_CHAVE NUMBER(10);

 BEGIN

    -- CONTADOR PARA VERIFICAR SE HÁ NECESSIDADE DO ENVIO DA MENSAGEM
       SELECT COUNT(1) 
              INTO P_COUNT
         FROM TGFCAB CAB, TGFFIN FIN
        WHERE CAB.NUNOTA   = FIN.NUNOTA
          AND CAB.DTNEG    >= '01-01-2021'
          AND CAB.TIPMOV   =  'P'
          AND CAB.PENDENTE =  'S'
          AND SYSDATE > (FIN.DTVENC + 9)
          AND CAB.VLRDESCTOTITEM < (SELECT SUM(TGFITE.VLRTOT) FROM TGFITE WHERE TGFITE.NUNOTA = CAB.NUNOTA)
          AND  NOT EXISTS (SELECT 1
                             FROM TGFITE ITE 
                            WHERE ITE.NUNOTA = CAB.NUNOTA 
                              AND AD_QTDENTREGUECERTIF IS NOT NULL)
          AND  NOT EXISTS (SELECT 1 
                             FROM TGFVAR VAR
                            WHERE VAR.NUNOTAORIG = CAB.NUNOTA)
          AND  NOT EXISTS (SELECT 1 
                             FROM TGFFIN FIN
                            WHERE FIN.NUNOTA = CAB.NUNOTA 
                              AND FIN.DHBAIXA IS NOT NULL
                              AND FIN.VLRBAIXA > 0)
          AND      EXISTS (SELECT 1
                             FROM AD_PARAMETROPRJ PRJ
                            WHERE CODPROJ = CAB.CODPROJ 
                              AND PRJ.NUPARAMETRO = 152);

    --- MOTANDO O CORPO DO E-MAIL

  IF P_COUNT > 0 
    THEN
        SELECT SYSDATE +1 INTO P_DIAMAIS1 FROM DUAL;
  -- ALIMENTANDO AS VARIÁVEIS 
     P_ASSUNTO := 'Pedidos pendentes que serão deletados - Amanhã ' || P_DIAMAIS1;
     P_TABINI  := '<h1>Pedidos Pendentes Para Exclusão </h1>';
     P_TABCAB  := '<table border=1px solid #ccc><tr><th>Nro. Único</th><th>Data Negociação</th><th>Valor do Pedido</th><th>Data Vencimento</th><th>Dias de Atraso</th><th>TOP - Tipo de operação</th><th>Nome Parceiro</th><th>Projeto</th></tr>';
     P_TABFIN  := '</table>';

     FOR CORPO IN (
        SELECT    
           ' <tr>'   ||
           ' <td>'   ||    NVL(CAB.NUNOTA,0)           || '</td>' || 
           ' <td>'   ||    NVL(CAB.DTNEG,'31/12/1999') || '</td>' || 
           ' <td>'   ||    NVL(CAB.VLRNOTA,0)||' R$'|| '</td>' || 
           ' <td>'   ||    NVL(FIN.DTVENC,'31/12/1999')|| '</td>' || 
           ' <td>'   ||    NVL(ROUND((SYSDATE - FIN.DTVENC),0),0) || '</td>' || 
           ' <td>'   ||    NVL(CAB.CODTIPOPER,0)||'-'||(SELECT DISTINCT NVL(descroper,'SEM TOP') FROM TGFTOP WHERE CODTIPOPER = CAB.CODTIPOPER) || '</td>' || 
           ' <td>'   ||    NVL(CAB.CODPARC,0) ||'-'||(SELECT NVL(TGFPAR.NOMEPARC,'SEM PARCEIRO') FROM TGFPAR WHERE TGFPAR.CODPARC = CAB.CODPARC) || '</td>' || 
           ' <td>'   ||    NVL(CAB.CODPROJ,0) ||'-'||(SELECT NVL(TCSPRJ.IDENTIFICACAO, 'SEM PROJETO') FROM TCSPRJ WHERE TCSPRJ.CODPROJ = CAB.CODPROJ)||  '</td>'||
           '</tr>'         AS MSGEMAIL

        FROM TGFCAB CAB, TGFFIN FIN
        WHERE CAB.NUNOTA = FIN.NUNOTA
          AND CAB.DTNEG    >= '01-01-2021'
          AND CAB.TIPMOV   = 'P'
          AND CAB.PENDENTE = 'S'
          AND SYSDATE > (FIN.DTVENC + 9)
          AND CAB.VLRDESCTOTITEM < (SELECT SUM(TGFITE.VLRTOT) FROM TGFITE WHERE TGFITE.NUNOTA = CAB.NUNOTA)
          AND  NOT EXISTS (SELECT 1 
                             FROM TGFITE ITE 
                            WHERE ITE.NUNOTA = CAB.NUNOTA 
                              AND AD_QTDENTREGUECERTIF IS NOT NULL)
          AND  NOT EXISTS (SELECT 1 
                             FROM TGFVAR VAR
                            WHERE VAR.NUNOTAORIG = CAB.NUNOTA)
          AND  NOT EXISTS (SELECT 1
                             FROM TGFFIN FIN
                            WHERE FIN.NUNOTA = CAB.NUNOTA 
                              AND FIN.DHBAIXA IS NOT NULL
                              AND FIN.VLRBAIXA > 0)
          AND      EXISTS (SELECT 1
                             FROM AD_PARAMETROPRJ PRJ
                            WHERE CODPROJ = CAB.CODPROJ 
                              AND PRJ.NUPARAMETRO = 152))

          LOOP 
               IF CORPO.MSGEMAIL IS NOT NULL
               THEN 
                   V_MSG := V_MSG || CORPO.MSGEMAIL;
               END IF;
        END LOOP;

  ELSE 
         -- QUANDO NÃO HÁ PEDIDOS LOCALIZADOS PELO O CONTADOR P_COUNT
         SELECT SYSDATE +1 INTO P_DIAMAIS1 FROM DUAL;
         P_ASSUNTO :=  'Não há pedidos pendentes para serem deletados amanhã, '|| P_DIAMAIS1;
         V_MSG     := '<h3> Na data de amanhã, dia '|| P_DIAMAIS1 ||' não há pedidos a serem excluídos </h3>';
  END IF;      

    -- LOOP PARA O ENVIO DO E-MAIL DOS USUÁRIOS CADASTRADOS NO PARAM 152 DA CENTRAL DE PARAMETROS    
  FOR EMAIL IN ( SELECT email AS DESDEMAIL FROM TSIUSU WHERE CODUSU IN 
                (SELECT CODUSU FROM AD_PARAMETROUSU WHERE NUPARAMETRO = 152 ))
            LOOP

            SELECT NVL(MAX(CODFILA),0)+1 INTO P_CHAVE FROM TMDFMG;

            INSERT INTO TMDFMG
                          ( CODFILA
                          , ASSUNTO
                          , CODMSG
                          , DTENTRADA
                          , STATUS
                          , CODCON
                          , TENTENVIO
                          , TIPOENVIO
                          , MAXTENTENVIO
                          , EMAIL
                          , CODUSU
                          , MENSAGEM)
                   VALUES ( P_CHAVE
                          , P_ASSUNTO                -- P_ASSUNTO 
                          , NULL                     -- P_CODMSG 
                          , SYSDATE                  -- P_DTENTRADA 
                          , 'Pendente'               -- P_STATUS 
                          , 0                        -- P_CODCON 
                          , 1                        -- P_TENTENVIO 
                          , 'E'                      -- P_TIPOENVIO 
                          , '3'                      -- P_MAXTENTENVIO 
                          , EMAIL.DESDEMAIL          -- P_EMAIL 
                          , 0                        -- P_CODUSU  
                          ,  P_TABINI||P_TABCAB||V_MSG||P_TABFIN || '<br><b><i>Email gerado automaticamente pelo Sankhya-W. Favor, não responder.</b></i>');
          END LOOP; 

      RETURN;
END;