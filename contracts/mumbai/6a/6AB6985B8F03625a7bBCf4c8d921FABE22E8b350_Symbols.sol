// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Symbols {
    enum Symbols {
        A0,
        A1,
        A2,
        A3,
        B1,
        B2,
        B3,
        B4,
        B5,
        B6,
        B7,
        B8,
        B9,
        B10,
        B11,
        B12,
        B13,
        B14,
        B15,
        B16,
        C1,
        C2,
        C3,
        C4,
        C5,
        C6,
        C7,
        C8,
        C9,
        C10,
        C11,
        C12,
        C13,
        C14,
        C15,
        C16,
        C17,
        C18,
        C19,
        D1,
        D2,
        D3,
        D4,
        D5,
        D6,
        D7,
        D8,
        E1,
        E2,
        E3,
        E4,
        E5,
        F1,
        F2,
        F3,
        F4,
        G1,
        G2,
        G3,
        G4,
        G5,
        G6,
        G7,
        G8,
        H1,
        H2,
        H3,
        H4,
        H5,
        H6,
        H7,
        H8,
        H9,
        H10,
        H11,
        H12,
        I1,
        J1,
        J2,
        K1,
        K2,
        L1,
        L2,
        L3,
        M1,
        M2,
        M3,
        M4,
        M5,
        M6,
        M7,
        M8,
        M9,
        M10,
        M11,
        M12,
        M13,
        M14,
        M15,
        M16,
        M17,
        M18,
        N1,
        O1,
        O2,
        O3,
        O4,
        O5,
        P1,
        P2,
        P3,
        P4,
        P5,
        P6,
        P7,
        R1,
        R2,
        R3,
        R4,
        R5,
        R6,
        R7,
        S1,
        S2,
        S3,
        S4,
        S5,
        S6,
        S7,
        S8,
        S9,
        S10,
        S11,
        S12,
        T1,
        T2,
        T3,
        T4,
        T5,
        T6,
        T7,
        T8,
        T9,
        U1,
        V1,
        V2,
        V3,
        W1,
        W2,
        W3,
        W4,
        W5,
        W6
    }
    function findSymbol(uint256 index) public pure returns (Symbols) {
        if (index == 1) return Symbols.A1;
        if (index == 2) return Symbols.A2;
        if (index == 3) return Symbols.A3;
        if (index == 4) return Symbols.B1;
        if (index == 5) return Symbols.B2;
        if (index == 6) return Symbols.B3;
        if (index == 7) return Symbols.B4;
        if (index == 8) return Symbols.B5;
        if (index == 9) return Symbols.B6;
        if (index == 10) return Symbols.B7;
        if (index == 11) return Symbols.B8;
        if (index == 12) return Symbols.B9;
        if (index == 13) return Symbols.B10;
        if (index == 14) return Symbols.B11;
        if (index == 15) return Symbols.B12;
        if (index == 16) return Symbols.B13;
        if (index == 17) return Symbols.B14;
        if (index == 18) return Symbols.B15;
        if (index == 19) return Symbols.B16;
        if (index == 20) return Symbols.C1;
        if (index == 21) return Symbols.C2;
        if (index == 22) return Symbols.C3;
        if (index == 23) return Symbols.C4;
        if (index == 24) return Symbols.C5;
        if (index == 25) return Symbols.C6;
        if (index == 26) return Symbols.C7;
        if (index == 27) return Symbols.C8;
        if (index == 28) return Symbols.C9;
        if (index == 29) return Symbols.C10;
        if (index == 30) return Symbols.C11;
        if (index == 31) return Symbols.C12;
        if (index == 32) return Symbols.C13;
        if (index == 33) return Symbols.C14;
        if (index == 34) return Symbols.C15;
        if (index == 35) return Symbols.C16;
        if (index == 36) return Symbols.C17;
        if (index == 37) return Symbols.C18;
        if (index == 38) return Symbols.C19;
        if (index == 39) return Symbols.D1;
        if (index == 40) return Symbols.D2;
        if (index == 41) return Symbols.D3;
        if (index == 42) return Symbols.D4;
        if (index == 43) return Symbols.D5;
        if (index == 44) return Symbols.D6;
        if (index == 45) return Symbols.D7;
        if (index == 46) return Symbols.D8;
        if (index == 47) return Symbols.E1;
        if (index == 48) return Symbols.E2;
        if (index == 49) return Symbols.E3;
        if (index == 50) return Symbols.E4;
        if (index == 51) return Symbols.E5;
        if (index == 52) return Symbols.F1;
        if (index == 53) return Symbols.F2;
        if (index == 54) return Symbols.F3;
        if (index == 55) return Symbols.F4;
        if (index == 56) return Symbols.G1;
        if (index == 57) return Symbols.G2;
        if (index == 58) return Symbols.G3;
        if (index == 59) return Symbols.G4;
        if (index == 60) return Symbols.G5;
        if (index == 61) return Symbols.G6;
        if (index == 62) return Symbols.G7;
        if (index == 63) return Symbols.G8;
        if (index == 64) return Symbols.H1;
        if (index == 65) return Symbols.H2;
        if (index == 66) return Symbols.H3;
        if (index == 67) return Symbols.H4;
        if (index == 68) return Symbols.H5;
        if (index == 69) return Symbols.H6;
        if (index == 70) return Symbols.H7;
        if (index == 71) return Symbols.H8;
        if (index == 72) return Symbols.H9;
        if (index == 73) return Symbols.H10;
        if (index == 74) return Symbols.H11;
        if (index == 75) return Symbols.H12;
        if (index == 76) return Symbols.I1;
        if (index == 77) return Symbols.J1;
        if (index == 78) return Symbols.J2;
        if (index == 79) return Symbols.K1;
        if (index == 80) return Symbols.K2;
        if (index == 81) return Symbols.L1;
        if (index == 82) return Symbols.L2;
        if (index == 83) return Symbols.L3;
        if (index == 84) return Symbols.M1;
        if (index == 85) return Symbols.M2;
        if (index == 86) return Symbols.M3;
        if (index == 87) return Symbols.M4;
        if (index == 88) return Symbols.M5;
        if (index == 89) return Symbols.M6;
        if (index == 90) return Symbols.M7;
        if (index == 91) return Symbols.M8;
        if (index == 92) return Symbols.M9;
        if (index == 93) return Symbols.M10;
        if (index == 94) return Symbols.M11;
        if (index == 95) return Symbols.M12;
        if (index == 96) return Symbols.M13;
        if (index == 97) return Symbols.M14;
        if (index == 98) return Symbols.M15;
        if (index == 99) return Symbols.M16;
        if (index == 100) return Symbols.M17;
        if (index == 101) return Symbols.M18;
        if (index == 102) return Symbols.N1;
        if (index == 103) return Symbols.O1;
        if (index == 104) return Symbols.O2;
        if (index == 105) return Symbols.O3;
        if (index == 106) return Symbols.O4;
        if (index == 107) return Symbols.O5;
        if (index == 108) return Symbols.P1;
        if (index == 109) return Symbols.P2;
        if (index == 110) return Symbols.P3;
        if (index == 111) return Symbols.P4;
        if (index == 112) return Symbols.P5;
        if (index == 113) return Symbols.P6;
        if (index == 114) return Symbols.P7;
        if (index == 115) return Symbols.R1;
        if (index == 116) return Symbols.R2;
        if (index == 117) return Symbols.R3;
        if (index == 118) return Symbols.R4;
        if (index == 119) return Symbols.R5;
        if (index == 120) return Symbols.R6;
        if (index == 121) return Symbols.R7;
        if (index == 122) return Symbols.S1;
        if (index == 123) return Symbols.S2;
        if (index == 124) return Symbols.S3;
        if (index == 125) return Symbols.S4;
        if (index == 126) return Symbols.S5;
        if (index == 127) return Symbols.S6;
        if (index == 128) return Symbols.S7;
        if (index == 129) return Symbols.S8;
        if (index == 130) return Symbols.S9;
        if (index == 131) return Symbols.S10;
        if (index == 132) return Symbols.S11;
        if (index == 133) return Symbols.S12;
        if (index == 134) return Symbols.T1;
        if (index == 135) return Symbols.T2;
        if (index == 136) return Symbols.T3;
        if (index == 137) return Symbols.T4;
        if (index == 138) return Symbols.T5;
        if (index == 139) return Symbols.T6;
        if (index == 140) return Symbols.T7;
        if (index == 141) return Symbols.T8;
        if (index == 142) return Symbols.T9;
        if (index == 143) return Symbols.U1;
        if (index == 144) return Symbols.V1;
        if (index == 145) return Symbols.V2;
        if (index == 146) return Symbols.V3;
        if (index == 147) return Symbols.W1;
        if (index == 148) return Symbols.W2;
        if (index == 149) return Symbols.W3;
        if (index == 150) return Symbols.W4;
        if (index == 151) return Symbols.W5;
        if (index == 152) return Symbols.W6;

        // If index is out of range, return an invalid symbol
        revert("Invalid index");
    }
}