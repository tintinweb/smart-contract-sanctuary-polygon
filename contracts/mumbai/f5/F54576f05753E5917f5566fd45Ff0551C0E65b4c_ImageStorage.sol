// SPDX-License-Identifier: GPL-3.0

// Storage Contract for Giv3NFT (combined, layered)
pragma solidity ^0.8.10;

import "./interface/IImageStorage.sol";

contract ImageStorage is IImageStorage {
    string public body =
        "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAIAAAD8GO2jAAAAAXNSR0IArs4c6QAAAClJREFUSIntzTEBAAAIwzDAv+dhAr5UQNNJ6rN5vQMAAAAAAAAAAIDDFsfxAz1KKZktAAAAAElFTkSuQmCC";
    mapping(uint256 => string) public layer_1_data;
    mapping(uint256 => string) public layer_2_data;
    mapping(uint256 => string) public layer_3_data;
    mapping(uint256 => string) public layer_4_data;
    mapping(uint256 => string) public layer_5_data;

    constructor() {
        // Layer 1
        layer_1_data[
            0
        ] = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAMNJREFUWIXtlkEOhCAMRTtm3Hoc7r/2OGxZMBuHYKeU0rROjLzEHYXnLzYCTCZ/5jVakGLII3uu284ufo8K4AMQ+Xgka2ULpKQYsEjZn0vBTIAQEUks1gLVQd+XY++MuQCSKKAW+QpUdFNwE+h9fmqBFEMzzgblolN1mgR6g6iAUiDrvO9AF42AZnY0a8wHEcXR+wwAsG776cxbtkALmfYlAtxMeFQLSIZ/SOppJh23HNoExNPQS0DLz5dwmYBFuyYTFz5epyfpkh3ccwAAAABJRU5ErkJggg==";
        layer_1_data[
            1
        ] = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAMdJREFUWIXtlmEKwyAMRuPYnXqUHUC800A8a/anLdbGmAR1jPmg0IJpHp82FGCx+DJOW+AjouadKfAtnlqBskEB7pdkrWyBFB8vwRwPDoBPoZsAISKSePQWyBodN+yZ6S5QSJwUWzRWIKOZwjCB1udnFvARq3FWOE2oOksC4u5FCmTd6DPQxCJgmR3Vmu6DiGLfewQASMFdev7kFlgh054iwM2Ev9oCEvUPST7NpOOWw5qAahaPELByi2yaQAoO3q9tVrvFQs4Hy9IpW3PXM8QAAAAASUVORK5CYII=";
        layer_1_data[
            2
        ] = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAANFJREFUWIXtlsENwyAMRd0qy7BAR2ApzizFIuzRaw/0kiLiGmMsSFSVJ+WG8c83fAGwWFzMrbcgupB69jTesou3XgG4ASLtn2StbIGU6AIWkvfnXBgmgBAiEnEfLaBo9Pk59swMF4BEZNCI5gooaLowTUDr+qkFRBeqdlbIB52q0zjQCqIMcoGsm30GmmgEaLKjWjM8iCj22ScAAOPtoedPjkAL6fYpArhM+KsRkHQ/SMo0k8Yth9YBcRrOEqDl6yZo3oQqjLfwej4A/FkdFwshbycyKsFCWON8AAAAAElFTkSuQmCC";
        layer_1_data[
            3
        ] = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAMxJREFUWIXtltENAiEMQKvx1wlYihn8YSa2YClcA39OgrWU0gAXIy+5P0ofLTQHsNmczKU3wEebevZ0JrCLb70COAEiHZ9krWyBFB8tFsn7c1UYJkCIiCSuowWKRO/DsXdmuACSyKAWzRUoaFZhmkDr+akFfLTVclbIF52K01SgNYgyqApk3Ow70EQjoJkd1Zjhg4ji6H0CAHAmfOT8yRZoIau9RICbCX/VApLuH5JymknHLYe2AuJpOEtAy9dLWCbgTIDH/bkq3WYj5wUJbinok8JJ6AAAAABJRU5ErkJggg==";
        layer_1_data[
            4
        ] = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAM9JREFUWIXtlsENwyAMRd2q547TARjKQ3gohsq1B3pJEXWMMRakqsqTcsP45xu+AFgsvsyltwADpZ49KaK6+NYrgDdgpP2zrLUtsIKBuJC8v+bCMAGCEJOI62gBRaP3z6lnZrgAJiLDRjRXQEHThWkCWtfPLQADVe2skA+6VOdxoBVEGeaCWDf7DDTxCPBkR7VmeBBJ7LNPAAAU8aPnT47Ai+j2KQK0TPirEYh0P0jKNLPGrYbXAXMazhLg5XATPG9CFxQRntsD6H5Wx8XCyAv5pyxo84Dy6wAAAABJRU5ErkJggg==";

        // layer 2
        layer_2_data[
            0
        ] = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAMJJREFUWIXtlNENgzAMRE3VZbpIl+o3S7FIx6FfRAmJE9+Zwgd+EhJSEudsXywSBMHFTL3F72fZflck1mt++wWAl1cxrSIeg3X08nQmS8AlgMUsvCeAyb7AUoUnEbflm5bYVdlbgLYgGWz7OqJEZFwF2APIExNDG10mdDzVRK90raDW/ldntMqhJmTngprov+aAmdsIUFvHDKKcvLfUS2ArMEnt7uHUO0pAMQ13Ig4VoGbkuRARcApnCaAHEWWsIED4AU4uKfOXB18OAAAAAElFTkSuQmCC";
        layer_2_data[
            1
        ] = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAMFJREFUWIXtlEEOwyAMBJ2qr+tPeuxLcsxP+r30FAQBg3edJod4pEiRALO2F4sEQXAxU29xXl7b74rE+ry/fgHg5VVMq4jHYB29PJ3JEnAJYDEL7wlgsi+wVOFJxG35piV2VfYWoC1IBtu+jigRGVcB9gDyxMTQRpcJHU810StdK6i1/9UZrXKoCdm5oCb6rzlg5jYC1NYxgygn7y31EtgKTFK7ezj1jhJQTMOdiEMFqBl5LkQEnMJZAuhBRBkrCBB+qMMs/1rULtkAAAAASUVORK5CYII=";
        layer_2_data[
            2
        ] = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAALxJREFUWIXtlNsKgCAMhmf0ptFTRc9qV4qmmztYXbQPgkDd/h0BHMf5mEAdbkdMv5G6d7d17qRZngCh88YmV8QyOJc6z2+KAEwCtLCFUwI00VdwsrAq7PaK2/MUkbsV0hLkBksfIQoAxlkQ94BkxIBRRlMTGkY1Q6WuZ5Rb/+YNljlpE2r3AhroU3uAzW8EoKXTLKKSsraqSdBmIEDb3aIFYRFQbcObiKkCUKsWhxIBr/CWAPUimpdrx0G4AGlYKj5VES0PAAAAAElFTkSuQmCC";
        layer_2_data[
            3
        ] = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAMFJREFUWIXtlEEOwyAMBJ2qD+rPeusjcsvP+qP0FAQBg3edJod4pEiRALO2F4sEQXAxU29xfr+23xWJ9Vm+fgHg5VVMq4jHYB29PJ3JEnAJYDEL7wlgsi+wVOFJxG35piV2VfYWoC1IBtu+jigRGVcB9gDyxMTQRpcJHU810StdK6i1/9UZrXKoCdm5oCb6rzlg5jYC1NYxgygn7y31EtgKTFK7ezj1jhJQTMOdiEMFqBl5LkQEnMJZAuhBRBkrCBB+05MuYnfWq+gAAAAASUVORK5CYII=";
        layer_2_data[
            4
        ] = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAL5JREFUWIXtlFEOhCAMRKvZk+2hPISH8mrulwSEQmfq6od9iYkJUKbtUJEgCB5m6i0u3/X43ZFY67b4BYCXVzGtIubBOnp5OpMl4BLAYhbeE8BkX2CpwoeI2/JNS+yu7C1AW5AMdnwdUSIyrgLsAeSJiaGNLhM6nmqiV7pWUGv/qzNa5VATsnNBTfRfc8DMawSorWMGUU7eW+olsBWYpHb3cOpdJaCYhicRlwpQM/JciAi4hbsE0IOIMlYQIPwAA9gt5f6SFBQAAAAASUVORK5CYII=";
        // layer 3
        layer_3_data[
            0
        ] = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAMJJREFUWIXtlNENgzAMRE3VZbpIl+o3S7FIx6FfRAmJE9+Zwgd+EhJSEudsXywSBMHFTL3F72fZflck1mt++wWAl1cxrSIeg3X08nQmS8AlgMUsvCeAyb7AUoUnEbflm5bYVdlbgLYgGWz7OqJEZFwF2APIExNDG10mdDzVRK90raDW/ldntMqhJmTngprov+aAmdsIUFvHDKKcvLfUS2ArMEnt7uHUO0pAMQ13Ig4VoGbkuRARcApnCaAHEWWsIED4AU4uKfOXB18OAAAAAElFTkSuQmCC";
        layer_3_data[
            1
        ] = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAMFJREFUWIXtlEEOwyAMBJ2qr+tPeuxLcsxP+r30FAQBg3edJod4pEiRALO2F4sEQXAxU29xXl7b74rE+ry/fgHg5VVMq4jHYB29PJ3JEnAJYDEL7wlgsi+wVOFJxG35piV2VfYWoC1IBtu+jigRGVcB9gDyxMTQRpcJHU810StdK6i1/9UZrXKoCdm5oCb6rzlg5jYC1NYxgygn7y31EtgKTFK7ezj1jhJQTMOdiEMFqBl5LkQEnMJZAuhBRBkrCBB+qMMs/1rULtkAAAAASUVORK5CYII=";
        layer_3_data[
            2
        ] = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAALxJREFUWIXtlNsKgCAMhmf0ptFTRc9qV4qmmztYXbQPgkDd/h0BHMf5mEAdbkdMv5G6d7d17qRZngCh88YmV8QyOJc6z2+KAEwCtLCFUwI00VdwsrAq7PaK2/MUkbsV0hLkBksfIQoAxlkQ94BkxIBRRlMTGkY1Q6WuZ5Rb/+YNljlpE2r3AhroU3uAzW8EoKXTLKKSsraqSdBmIEDb3aIFYRFQbcObiKkCUKsWhxIBr/CWAPUimpdrx0G4AGlYKj5VES0PAAAAAElFTkSuQmCC";
        layer_3_data[
            3
        ] = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAMFJREFUWIXtlEEOwyAMBJ2qD+rPeusjcsvP+qP0FAQBg3edJod4pEiRALO2F4sEQXAxU29xfr+23xWJ9Vm+fgHg5VVMq4jHYB29PJ3JEnAJYDEL7wlgsi+wVOFJxG35piV2VfYWoC1IBtu+jigRGVcB9gDyxMTQRpcJHU810StdK6i1/9UZrXKoCdm5oCb6rzlg5jYC1NYxgygn7y31EtgKTFK7ezj1jhJQTMOdiEMFqBl5LkQEnMJZAuhBRBkrCBB+05MuYnfWq+gAAAAASUVORK5CYII=";
        layer_3_data[
            4
        ] = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAL5JREFUWIXtlFEOhCAMRKvZk+2hPISH8mrulwSEQmfq6od9iYkJUKbtUJEgCB5m6i0u3/X43ZFY67b4BYCXVzGtIubBOnp5OpMl4BLAYhbeE8BkX2CpwoeI2/JNS+yu7C1AW5AMdnwdUSIyrgLsAeSJiaGNLhM6nmqiV7pWUGv/qzNa5VATsnNBTfRfc8DMawSorWMGUU7eW+olsBWYpHb3cOpdJaCYhicRlwpQM/JciAi4hbsE0IOIMlYQIPwAA9gt5f6SFBQAAAAASUVORK5CYII=";
        // layer 4
        layer_4_data[
            0
        ] = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAMJJREFUWIXtlNENgzAMRE3VZbpIl+o3S7FIx6FfRAmJE9+Zwgd+EhJSEudsXywSBMHFTL3F72fZflck1mt++wWAl1cxrSIeg3X08nQmS8AlgMUsvCeAyb7AUoUnEbflm5bYVdlbgLYgGWz7OqJEZFwF2APIExNDG10mdDzVRK90raDW/ldntMqhJmTngprov+aAmdsIUFvHDKKcvLfUS2ArMEnt7uHUO0pAMQ13Ig4VoGbkuRARcApnCaAHEWWsIED4AU4uKfOXB18OAAAAAElFTkSuQmCC";
        layer_4_data[
            1
        ] = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAMFJREFUWIXtlEEOwyAMBJ2qr+tPeuxLcsxP+r30FAQBg3edJod4pEiRALO2F4sEQXAxU29xXl7b74rE+ry/fgHg5VVMq4jHYB29PJ3JEnAJYDEL7wlgsi+wVOFJxG35piV2VfYWoC1IBtu+jigRGVcB9gDyxMTQRpcJHU810StdK6i1/9UZrXKoCdm5oCb6rzlg5jYC1NYxgygn7y31EtgKTFK7ezj1jhJQTMOdiEMFqBl5LkQEnMJZAuhBRBkrCBB+qMMs/1rULtkAAAAASUVORK5CYII=";
        layer_4_data[
            2
        ] = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAALxJREFUWIXtlNsKgCAMhmf0ptFTRc9qV4qmmztYXbQPgkDd/h0BHMf5mEAdbkdMv5G6d7d17qRZngCh88YmV8QyOJc6z2+KAEwCtLCFUwI00VdwsrAq7PaK2/MUkbsV0hLkBksfIQoAxlkQ94BkxIBRRlMTGkY1Q6WuZ5Rb/+YNljlpE2r3AhroU3uAzW8EoKXTLKKSsraqSdBmIEDb3aIFYRFQbcObiKkCUKsWhxIBr/CWAPUimpdrx0G4AGlYKj5VES0PAAAAAElFTkSuQmCC";
        layer_4_data[
            3
        ] = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAMFJREFUWIXtlEEOwyAMBJ2qD+rPeusjcsvP+qP0FAQBg3edJod4pEiRALO2F4sEQXAxU29xfr+23xWJ9Vm+fgHg5VVMq4jHYB29PJ3JEnAJYDEL7wlgsi+wVOFJxG35piV2VfYWoC1IBtu+jigRGVcB9gDyxMTQRpcJHU810StdK6i1/9UZrXKoCdm5oCb6rzlg5jYC1NYxgygn7y31EtgKTFK7ezj1jhJQTMOdiEMFqBl5LkQEnMJZAuhBRBkrCBB+05MuYnfWq+gAAAAASUVORK5CYII=";
        layer_4_data[
            4
        ] = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAL5JREFUWIXtlFEOhCAMRKvZk+2hPISH8mrulwSEQmfq6od9iYkJUKbtUJEgCB5m6i0u3/X43ZFY67b4BYCXVzGtIubBOnp5OpMl4BLAYhbeE8BkX2CpwoeI2/JNS+yu7C1AW5AMdnwdUSIyrgLsAeSJiaGNLhM6nmqiV7pWUGv/qzNa5VATsnNBTfRfc8DMawSorWMGUU7eW+olsBWYpHb3cOpdJaCYhicRlwpQM/JciAi4hbsE0IOIMlYQIPwAA9gt5f6SFBQAAAAASUVORK5CYII=";
        // layer 5
        layer_5_data[
            0
        ] = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAMJJREFUWIXtlNENgzAMRE3VZbpIl+o3S7FIx6FfRAmJE9+Zwgd+EhJSEudsXywSBMHFTL3F72fZflck1mt++wWAl1cxrSIeg3X08nQmS8AlgMUsvCeAyb7AUoUnEbflm5bYVdlbgLYgGWz7OqJEZFwF2APIExNDG10mdDzVRK90raDW/ldntMqhJmTngprov+aAmdsIUFvHDKKcvLfUS2ArMEnt7uHUO0pAMQ13Ig4VoGbkuRARcApnCaAHEWWsIED4AU4uKfOXB18OAAAAAElFTkSuQmCC";
        layer_5_data[
            1
        ] = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAMFJREFUWIXtlEEOwyAMBJ2qr+tPeuxLcsxP+r30FAQBg3edJod4pEiRALO2F4sEQXAxU29xXl7b74rE+ry/fgHg5VVMq4jHYB29PJ3JEnAJYDEL7wlgsi+wVOFJxG35piV2VfYWoC1IBtu+jigRGVcB9gDyxMTQRpcJHU810StdK6i1/9UZrXKoCdm5oCb6rzlg5jYC1NYxgygn7y31EtgKTFK7ezj1jhJQTMOdiEMFqBl5LkQEnMJZAuhBRBkrCBB+qMMs/1rULtkAAAAASUVORK5CYII=";
        layer_5_data[
            2
        ] = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAALxJREFUWIXtlNsKgCAMhmf0ptFTRc9qV4qmmztYXbQPgkDd/h0BHMf5mEAdbkdMv5G6d7d17qRZngCh88YmV8QyOJc6z2+KAEwCtLCFUwI00VdwsrAq7PaK2/MUkbsV0hLkBksfIQoAxlkQ94BkxIBRRlMTGkY1Q6WuZ5Rb/+YNljlpE2r3AhroU3uAzW8EoKXTLKKSsraqSdBmIEDb3aIFYRFQbcObiKkCUKsWhxIBr/CWAPUimpdrx0G4AGlYKj5VES0PAAAAAElFTkSuQmCC";
        layer_5_data[
            3
        ] = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAMFJREFUWIXtlEEOwyAMBJ2qD+rPeusjcsvP+qP0FAQBg3edJod4pEiRALO2F4sEQXAxU29xfr+23xWJ9Vm+fgHg5VVMq4jHYB29PJ3JEnAJYDEL7wlgsi+wVOFJxG35piV2VfYWoC1IBtu+jigRGVcB9gDyxMTQRpcJHU810StdK6i1/9UZrXKoCdm5oCb6rzlg5jYC1NYxgygn7y31EtgKTFK7ezj1jhJQTMOdiEMFqBl5LkQEnMJZAuhBRBkrCBB+05MuYnfWq+gAAAAASUVORK5CYII=";
        layer_5_data[
            4
        ] = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAL5JREFUWIXtlFEOhCAMRKvZk+2hPISH8mrulwSEQmfq6od9iYkJUKbtUJEgCB5m6i0u3/X43ZFY67b4BYCXVzGtIubBOnp5OpMl4BLAYhbeE8BkX2CpwoeI2/JNS+yu7C1AW5AMdnwdUSIyrgLsAeSJiaGNLhM6nmqiV7pWUGv/qzNa5VATsnNBTfRfc8DMawSorWMGUU7eW+olsBWYpHb3cOpdJaCYhicRlwpQM/JciAi4hbsE0IOIMlYQIPwAA9gt5f6SFBQAAAAASUVORK5CYII=";
    }

    function getBody() external view returns (string memory) {
        return body;
    }

    function getLayer1(uint256 _index) public view returns (string memory) {
        return layer_1_data[_index];
    }

    function getLayer2(uint256 _index) public view returns (string memory) {
        return layer_2_data[_index];
    }

    function getLayer3(uint256 _index) public view returns (string memory) {
        return layer_3_data[_index];
    }

    function getLayer4(uint256 _index) public view returns (string memory) {
        return layer_4_data[_index];
    }

    function getLayer5(uint256 _index) public view returns (string memory) {
        return layer_5_data[_index];
    }

    function getImageForCollection(uint256 collectionIndex, uint256 imageIndex)
        public
        view
        returns (string memory)
    {
        if (collectionIndex == 0) {
            return getLayer1(imageIndex);
        } else if (collectionIndex == 1) {
            return getLayer2(imageIndex);
        } else if (collectionIndex == 2) {
            return getLayer3(imageIndex);
        } else if (collectionIndex == 3) {
            return getLayer4(imageIndex);
        } else if (collectionIndex == 4) {
            return getLayer5(imageIndex);
        } else {
            return "";
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

interface IImageStorage {
    function getBody() external view returns (string memory);

    function getLayer1(uint256 _index) external view returns (string memory);

    function getLayer2(uint256 _index) external view returns (string memory);

    function getLayer3(uint256 _index) external view returns (string memory);

    function getLayer4(uint256 _index) external view returns (string memory);

    function getLayer5(uint256 _index) external view returns (string memory);

    function getImageForCollection(uint256 collectionIndex, uint256 imageIndex)
        external
        view
        returns (string memory);
}