<var1:8
iPUSHc
8
CALL
recur
iPUSHv
var1
iPUTLN
chPUSHc
'x'
chPUTLN
HALT
`recur
<~r_arg1:8
<var333:8
iPUSHv
r_arg1
iPUSHc
9
iJUMPEQ
end
iPUSHv
r_arg1
iPUSHc
1
iADD
iMOVE
r_arg1
iPUSHv
r_arg1
iPUTLN
iPUSHv
r_arg1
CALL
recur
>end:iMOVE
r_arg1
chPUSHc
'r'
chPUTLN
iPUSHv
r_arg1
iRETURN