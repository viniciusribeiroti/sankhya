SELECT CAB.NUNOTA, 
       CAB.CODPARC,
       PAR.nomeparc,
       ite.codprod,
       pro.descrprod,
       ite.qtdneg,
       ite.vlrunit,
       ite.vlrtot,
       cab.dtneg
       
FROM TGFCAB CAB,
     TGFPAR PAR,
     TGFITE ITE,
     TGFPRO PRO
WHERE cab.codparc = par.codparc 
  AND ite.nunota = cab.nunota
  AND ite.codprod = pro.codprod
  AND CAB.TIPMOV = 'V'
  AND  cab.codproj =  '010003032'
  AND  ITE.VLRTOT > 0
  AND  CAB.DTNEG BETWEEN  '01/08/2020' AND '10/12/2020'
  ORDER BY CAB.DTNEG, CAB.NUNOTA