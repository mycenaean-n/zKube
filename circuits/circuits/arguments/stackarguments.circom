pragma circom 2.0.0;
include "../../../node_modules/circomlib/circuits/comparators.circom";

// "STACK_YELLOW",
template ArgumentsStackYellow(C, ARG_LEN) {
    signal input inputIndex;
    signal output out[C][ARG_LEN];
    signal instruction[ARG_LEN] <== [1, 1, 0, 0];
    signal instructionOut[ARG_LEN]; 

    component isEq;
    isEq = IsEqual();
    isEq.in[0] <== inputIndex;
    isEq.in[1] <== 7;

     for (var i = 0; i < ARG_LEN; i++) {
        instructionOut[i] <== instruction[i] * isEq.out;
    }

    out <== [
        [0, 0, 0, 0],
        instructionOut,
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0]
    ];
}

// "STACK_RED"
template ArgumentsStackRed(C, ARG_LEN) {
    signal input inputIndex;
    signal output out[C][ARG_LEN];
    signal instruction[ARG_LEN] <== [1, 2, 0, 0];
    signal instructionOut[ARG_LEN];

    component isEq;
    isEq = IsEqual();
    isEq.in[0] <== inputIndex;
    isEq.in[1] <== 8;

     for (var i = 0; i < ARG_LEN; i++) {
        instructionOut[i] <== instruction[i] * isEq.out;
    }

    out <== [
        [0, 0, 0, 0],
        instructionOut,
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0]
    ];
}

// "STACK_BLUE",
template ArgumentsStackBlue(C, ARG_LEN) {
    signal input inputIndex;
    signal output out[C][ARG_LEN];
    signal instruction[ARG_LEN] <== [1, 3, 0, 0];
    signal instructionOut[ARG_LEN];

    component isEq;
    isEq = IsEqual();
    isEq.in[0] <== inputIndex;
    isEq.in[1] <== 9;

     for (var i = 0; i < ARG_LEN; i++) {
        instructionOut[i] <== instruction[i] * isEq.out;
    }

    out <== [
        [0, 0, 0, 0],
        instructionOut,
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0]
    ];
}
