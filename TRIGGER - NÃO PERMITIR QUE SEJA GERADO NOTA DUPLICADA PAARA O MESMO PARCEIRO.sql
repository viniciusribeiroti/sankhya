-- CRIANDO UMA TRIGGER PARA QUE NÃO DEIXE SR INSERIDO A MESMA NOTA PARA O MESMO CNPJ DE FORMA DUPLICADA

-- AUTOR : RICARDO FERREIRA VASCONCELOS
-- DATA : 26/03/2021
-- OBJECTIVO : NÃO PERMITIR QUE SEJA INSERIDA A NOTA DOPLICADA, 
-- CHAMADO : 262033
CREATE OR REPLACE TRIGGER trg_bloq_not_dupl_sol BEFORE
    INSERT OR UPDATE ON tgfcab
    FOR EACH ROW
DECLARE 
-- VARIAVEIS 
    PRAGMA autonomous_transaction;
    v_numnota   INT;
    v_parceiro  INT;
BEGIN
-- VERIFICA SE TEM ALGUM REGISTRO 
                SELECT
        COUNT(numnota),
        COUNT(codparc)
    INTO
        v_numnota,
        v_parceiro
    FROM
        tgfcab
    WHERE
            numnota = :new.numnota
        AND codparc = :new.codparc
        AND tipmov = 'C';

-- CASO TENHA REGISTRO, SIGNFICA QUE ESSA NOTA JA FOI USADA PARA ESSE PARCEIRO
-- SERA APRESENTADA A MENSAGEM
        IF
        v_numnota > 0
        AND v_parceiro > 0
    THEN
        raise_application_error(-20101,
                               'Operação Não Permitida, Número Nota : '
                               || :new.numnota
                               || ' Já está em uso para o Parceiro : '
                               || :new.codparc);

    END IF;

END;