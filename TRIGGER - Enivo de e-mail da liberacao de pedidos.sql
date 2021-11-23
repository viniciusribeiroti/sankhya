create or replace TRIGGER TRG_I_TSILIB_EMAIL_SOLUTI
BEFORE INSERT OR UPDATE ON  TSILIB
REFERENCING NEW AS NEW
FOR EACH ROW
DECLARE
 --  P_NUCHAVE       TSILIB.NUCHAVE%TYPE;
   P_ASSUNTO       VARCHAR2(200);
   P_NOMEUSU       VARCHAR(200);
   P_MENSAGEM      VARCHAR2(4000);
   P_EMAILDESTINO  VARCHAR2(200);
   P_COUNT         INT;
   --PRAGMA autonomous_transaction;

    /************************************************************
       AUTHOR.: VINICIUS RIBEIRO - 15/04/2021                   *
       AÇÃO.:   ENVIAR E-MAIL PARA ALERTAR LIBERADOR DO PEDIDO  *
    *************************************************************/
BEGIN
  -- VALIDANDO o número da chave
    IF NVL(:NEW.NUCHAVE,0)=0 THEN
        RETURN;
    END IF;
   
   IF UPDATING('CODUSULIB')
   THEN
   -- BUSCAND o e-mail
    SELECT TSIUSU.EMAIL, TSIUSU.NOMEUSU 
      INTO P_EMAILDESTINO, P_NOMEUSU
    FROM TSIUSU
    WHERE TSIUSU.CODUSU = :NEW.CODUSULIB; 
                              
  -- ASSUNTO                       
    P_ASSUNTO := 'Pedido Pendente de Liberação - Favor Verificar';

  -- MENSAGEM DO E-MAIL
     SELECT 'PEDIDO.: '          ||CAB.NUNOTA || ' -- ' ||
            'RAZÃO SOCIAL.: '    ||PAR.NOMEPARC || ' -- ' ||
            'SOLIC. LIBERAÇÃO.: '||P_NOMEUSU || ' -- ' ||
            'VALOR SOLICITADO.:' ||NVL(:NEW.VLRATUAL,0)||'R$ ' || 
            'DATA SOLICT.: '     ||:NEW.DHSOLICIT AS MENSAGEM 
           INTO P_MENSAGEM
     FROM TGFCAB CAB, TGFPAR PAR
     WHERE CAB.CODPARC = PAR.CODPARC 
       AND CAB.NUNOTA = :NEW.NUCHAVE;
       
  -- ENVIO DO E-MAIL
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
                   VALUES ( (SELECT NVL(MAX(CODFILA),0) FROM TMDFMG)+1
                          , P_ASSUNTO                -- P_ASSUNTO 
                          , NULL                  -- P_CODMSG 
                          , SYSDATE              -- P_DTENTRADA 
                          , 'Pendente'                 -- P_STATUS 
                          , 0                 -- P_CODCON 
                          , 1              -- P_TENTENVIO 
                          , 'E'              -- P_TIPOENVIO 
                          , '3'           -- P_MAXTENTENVIO 
                          , P_EMAILDESTINO     -- E-MAIL DESTINO 
                          , 0                  -- P_CODUSU  
                          , P_MENSAGEM || '<br><b><i>Email gerado automaticamente pelo Sankhya-W. Favor, não responder.</b></i>');
    END IF;
END;
