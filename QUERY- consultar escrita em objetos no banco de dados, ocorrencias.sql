SELECT *
FROM ALL_SOURCE
WHERE UPPER(TEXT) LIKE '%Falha ao realizar envio da venda%'
AND TYPE = 'PROCEDURE';