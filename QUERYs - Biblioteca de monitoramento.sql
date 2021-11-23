-- VERIFICAR SE HÁ PEDIDOS DUPLICADOS DO GESTÃO ONLINE

SELECT
    AD_IDPEDINTEG,
    COUNT(*)
FROM
    TGFCAB
WHERE
    AD_IDPEDINTEG IS NOT NULL
    AND DTNEG > '01/05/21'
GROUP BY
    AD_IDPEDINTEG
HAVING
    COUNT(*) > 1;


-- MONITORA O LOG DA API 

SELECT * FROM LOGAPI ORDER BY SEQLOG DESC;

-- MONITORAR AS TAXAS DUPLICADAS

SELECT
    HISTORICO,
    CODCTABCOINT,
    VLRLANC,
    DTLANC,
    CODTIPOPER,
    COUNT(*) AS QTD
FROM
    TGFMBC
WHERE
    CODCTABCOINT IN ( 18, 561 )
    AND CODUSU IN ( 0, 2511 )
    AND DTALTER >= '01/10/21'
    AND CODTIPOPER = 4401
-- AND CONCILIADO = 'N'
GROUP BY
    HISTORICO,
    CODCTABCOINT,
    VLRLANC,
    DTLANC,
    CODTIPOPER
HAVING
    COUNT(*) > 1
ORDER BY
    HISTORICO ASC

-- MONITORAMENTO DA INSERÇÃO DAS TAXAS PELO O GESTÃO ONLINE

 SELECT *
    FROM TGFMBC
    WHERE CODCTABCOINT IN ( 18, 561 )
       AND CODLANC = 2
       AND CODUSU = 0
      ORDER BY DTINCLUSAO DESC