module opcodes;

enum opcodes: ubyte {
    HALT = 0,
    MEMALLOC, // 1
    CALL,     // 2
    iRETURN,  // 3
    chRETURN, // 4

    iSUB,     // 5
    iMULT,    // 6
    iDIV,     // 7
    iEXP,     // 8
    iMOD,     // 9
    iADD,     // 10

    iPUSHv,   // 11
    iPUSHc,   // 12

    chPUSHc,  // 13
    chPUSHv,  // 14

    fpPUSHc,  // 15
    fpPUShv,  // 16

    iMOVE,    // 17 
    chMOVE,   // 18
    fpMOVE,   // 19

    NEWARRAY, // 20
    DELARRAY, // 21

    chARRINSERT,     // 22
    chARRGET,        // 23
    chARRAPPEND,     // 24
    chARRDUPLICATE,  // 25

    iARRINSERT,      // 26
    iARRGET,         // 27
    iARRAPPEND,      // 28
    iARRDUPLICATE,   // 29

    fpARRINSERT,     // 30
    fpARRGET,        // 31
    fpARRAPPEND,     // 32
    fpARRDUPLICATE,  // 33

    JUMP,            // 34
    chJUMPNEQ,       // 35
    chJUMPEQ,        // 36

    iJUMPNEQ,        // 37
    iJUMPEQ,         // 38
    iJUMPLT,         // 39
    iJUMPGT,         // 40
    
    fpJUMPNEQ,       // 41
    fpJUMPEQ,        // 42
    fpJUMPLT,        // 43
    fpJUMPGT,        // 44

    chPUT,           // 45
    chPUTLN,         // 46
    iPUT,            // 47
    iPUTLN,          // 48
    fpPUT,           // 49
    fpPUTLN,         // 50

    INPUT            // 51
}


ubyte get_operator(string operator_literal) {
    ubyte code;
    switch(operator_literal) {
        case "CALL":
            code = opcodes.CALL;
            break;
        case "iRETURN":
            code = opcodes.iRETURN;
            break;
        case "chRETURN":
            code = opcodes.chRETURN;
            break;
        case "iADD":
            code = opcodes.iADD;
            break;
        case "iSUB":
            code = opcodes.iSUB;
            break;
        case "iMULT":
            code = opcodes.iMULT;
            break;
        case "iDIV":
            code = opcodes.iDIV;
            break;
        case "iEXP":
            code = opcodes.iEXP;
            break;
        case "iMOD":
            code = opcodes.iMOD;
            break;
        case "iPUSHc":
            code = opcodes.iPUSHc;
            break;
        case "iPUSHv":
            code = opcodes.iPUSHv;
            break;
        case "chPUSHc":
            code = opcodes.chPUSHc;
            break;
        case "chPUSHv":
            code = opcodes.chPUSHv;
            break;
        case "fpPUSHc":
            code = opcodes.fpPUSHc;
            break;
        case "fpPUShv":
            code = opcodes.fpPUShv;
            break;
        case "iMOVE":
            code = opcodes.iMOVE;
            break;
        case "chMOVE":
            code = opcodes.chMOVE;
            break;
        case "fpMOVE":
            code = opcodes.fpMOVE;
            break;
        case "NEWARRAY":
            code = opcodes.NEWARRAY;
            break;
        case "DELARRAY":
            code = opcodes.DELARRAY;
            break;
        case "chARRINSERT":
            code = opcodes.chARRINSERT;
            break;
        case "chARRGET":
            code = opcodes.chARRGET;
            break;
        case "chARRAPPEND":
            code = opcodes.chARRAPPEND;
            break;
        case "chARRDUPLICATE":
            code = opcodes.chARRDUPLICATE;
            break;
        case "iARRINSERT":
            code = opcodes.iARRINSERT;
            break;
        case "iARRGET":
            code = opcodes.iARRGET;
            break;
        case "iARRAPPEND":
            code = opcodes.iARRAPPEND;
            break;
        case "iARRDUPLICATE":
            code = opcodes.iARRDUPLICATE;
            break;
        case "fpARRINSERT":
            code = opcodes.fpARRINSERT;
            break;
        case "fpARRGET":
            code = opcodes.fpARRGET;
            break;
        case "fpARRAPPEND":
            code = opcodes.fpARRAPPEND;
            break;
        case "fpARRDUPLICATE":
            code = opcodes.fpARRDUPLICATE;
            break;
        case "JUMP":
            code = opcodes.JUMP;
            break;
        case "chJUMPNEQ":
            code = opcodes.chJUMPNEQ;
            break;
        case "chJUMPEQ":
            code = opcodes.chJUMPEQ;
            break;
        case "iJUMPNEQ":
            code = opcodes.iJUMPNEQ;
            break;
        case "iJUMPEQ":
            code = opcodes.iJUMPEQ;
            break;
        case "iJUMPLT":
            code = opcodes.iJUMPLT;
            break;
        case "iJUMPGT":
            code = opcodes.iJUMPGT;
            break;
        case "fpJUMPNEQ":
            code = opcodes.fpJUMPNEQ;
            break;
        case "fpJUMPEQ":
            code = opcodes.fpJUMPEQ;
            break;
        case "fpJUMPLT":
            code = opcodes.fpJUMPLT;
            break;
        case "fpJUMTGT":
            code = opcodes.fpJUMPGT;
            break;
        case "chPUT":
            code = opcodes.chPUT;
            break;
        case "chPUTLN":
            code = opcodes.chPUTLN;
            break;
        case "iPUT":
            code = opcodes.iPUT;
            break;
        case "iPUTLN":
            code = opcodes.iPUTLN;
            break;
        case "fpPUT":
            code = opcodes.fpPUT;
            break;
        case "fpPUTLN":
            code = opcodes.fpPUTLN;
            break;
        case "INPUT":
            code = opcodes.INPUT;
            break;
        case "HALT":
            code = opcodes.HALT;
            break;
        default:
            code = ubyte.max;
            break;
    }
    return code;
}