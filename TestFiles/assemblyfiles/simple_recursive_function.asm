iPUSHc
10
iPUSHc
0
CALL
recursion
iPUSHc
11
iPUTLN
HALT
`recursion
<~add_num:8
<~counter:8
iPUSHv
add_num
iPUTLN
iPUSHv
add_num
iPUSHc
1
iADD
iMOVE
add_num
iPUSHv
counter
iPUSHc
5
iJUMPEQ
end
iPUSHv
add_num
iPUSHv
counter
iPUSHc
1
iADD
CALL
recursion
>end:iPUSHv
add_num
iPUTLN
iPUSHv
counter
iPUTLN
chPUSHc
'a'
chPUTLN
HALT