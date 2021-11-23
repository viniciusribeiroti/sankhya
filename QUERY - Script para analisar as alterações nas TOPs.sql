select top.codtipoper,
top.dhalter,
top.codusu,
usu.nomeusu
from tgftop top, tsiusu usu
where codtipoper = 1234
and usu.codusu = top.codusu