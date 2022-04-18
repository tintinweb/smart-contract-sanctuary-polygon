/**
 *Submitted for verification at polygonscan.com on 2022-04-18
*/

// Sources flattened with hardhat v2.9.1 https://hardhat.org

// File contracts/interfaces/IFishData.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IFishData {

    function getAttr (uint idx) external pure returns (bytes memory);
    function getStyle(uint idx) external pure returns (bytes memory);
    function getData (uint idx) external pure returns (bytes memory);

}


// File contracts/data/TailData.sol

pragma solidity ^0.8.0;

contract TailData is IFishData {

    bytes constant attr0 = 'Brush';
    bytes constant attr1 = 'Boomerang';
    bytes constant attr2 = 'Heart';
    bytes constant attr3 = 'Handlebar';
    bytes constant attr4 = 'Sprout';
    bytes constant attr5 = 'Skirt';
    bytes constant attr6 = 'Chips';
    bytes constant attr7 = 'Fork';
    bytes constant attr8 = 'Butterfly';
    bytes constant attr9 = 'Broccoli';

    bytes constant style0 = '.bT10{fill:#8e60a6;}';
    bytes constant style1 = '.bT1{fill:#324681;}.cT1{fill:#e1e8f6;}';
    bytes constant style2 = '.bT2{fill:#e60012;}.cT2{fill:#d363a1;}';
    bytes constant style3 = '.cT3{fill:none;}.bT3{fill:#f08223;}.cT3{stroke:#fff;stroke-miterlimit:10;}';
    bytes constant style4 = '.cT4,.dT4{fill:none;}.bT4{fill:#4ab134;}.cT4{stroke:#4ab134;stroke-width:8px;}.dT4{stroke:#fff;stroke-width:3px;}';
    bytes constant style5 = '.cT5,.dT5{fill:none;}.bT5{fill:#ffd600;}.cT5,.dT5{stroke:#fff;stroke-miterlimit:10;}.dT5{stroke-width:2px;}';
    bytes constant style6 = '.bT6{fill:#58beb9;stroke:#feeb00;stroke-miterlimit:10;}.cT6{fill:#ffd600;}';
    bytes constant style7 = '.bT7{fill:#0085cc;}';
    bytes constant style8 = '.bT8{fill:#231815;}.cT8{fill:#e36106;}';
    bytes constant style9 = '.bT9{fill:#58beb9;}.cT9{fill:#ffd600;}';

    bytes constant data0 = '<path class="bT10" d="M317,76.76c-7.25,15.53-59.11,37.84-85.5,44.75,0,0,15.2-36.27,28.23-36.27,0,0,24.53,10.91,46.36-7.87,11-9.44-8.56-34.07-14-39.36-3.8,1.5-3.24-.09-6.81-.09C277,37.92,279,15.11,279,15.11s24.25,6.76,20.31,14.64c-1.62,3.24-.19,4.51-3.5,6.42C301.45,43.45,321.81,66.33,317,76.76Z"/>';
    bytes constant data1 = '<path class="bT1" d="M258.65,89.08l43.6-35.29A1.85,1.85,0,0,1,305,56.18L279.63,98a1.86,1.86,0,0,0,.13,2.1L302.46,129a1.84,1.84,0,0,1-2.52,2.64l-41.2-29.42a1.87,1.87,0,0,1-.77-1.5V90.52A1.86,1.86,0,0,1,258.65,89.08Z"/><path class="cT1" d="M260,95.3A143.9,143.9,0,0,0,279.55,81c1.46-1.27-.67-3.38-2.12-2.12a139.51,139.51,0,0,1-18.95,13.81c-1.65,1-.14,3.6,1.52,2.59Z"/><path class="cT1" d="M259.26,97.49a27.3,27.3,0,0,0,19.07-6.84c1.46-1.27-.67-3.38-2.12-2.12a24.09,24.09,0,0,1-16.95,6c-1.93-.06-1.93,2.94,0,3Z"/><path class="cT1" d="M256.87,100a50.56,50.56,0,0,1,16.88,9.77c1.45,1.26,3.58-.85,2.12-2.12a54.54,54.54,0,0,0-18.2-10.54c-1.83-.64-2.62,2.26-.8,2.89Z"/><path class="cT1" d="M257,97.72c8.51,1.45,15,6.68,21.23,12.28,1.44,1.28,3.57-.84,2.12-2.13-6.61-5.9-13.58-11.52-22.55-13-1.89-.32-2.7,2.57-.8,2.89Z"/>';
    bytes constant data2 = '<ellipse class="bT2" cx="279.47" cy="85.61" rx="23" ry="12.75" transform="translate(12.91 205.52) rotate(-41.25)"/><ellipse class="bT2" cx="281.57" cy="101.79" rx="12.75" ry="23" transform="translate(64.65 308.16) rotate(-63.45)"/><circle class="cT2" cx="290.22" cy="75.89" r="5.25"/><circle class="cT2" cx="293.22" cy="108.39" r="5.25"/>';
    bytes constant data3 = '<path class="bT3" d="M340.08,140.78c-59.93,13.22-82.86-38-82.86-38l.74-9.35a0,0,0,0,0,0,0V86.83l.09-.19c1.67-3.53,25.08-50.54,82.76-37.82-2.88-.56-26.79-4.4-53.77,16.15,17.26,21,5,49.9-.26,60C313.56,145.14,337.22,141.34,340.08,140.78Z"/><path class="cT3" d="M259.47,89.64s10-14,21-18.5"/><path class="cT3" d="M259.47,100.14s10,14,21,18.5"/><path class="cT3" d="M261.22,91.39s9-7,20.5-5.5"/><path class="cT3" d="M260.72,98.17s9,7,20.5,5.5"/>';
    bytes constant data4 = '<path class="bT4" d="M324.52,103.9c-1.94.46-3.53.78-4.9,1-5.95,1-7.95.42-18.38,1.63-11.84,1.37-31.31-1.26-38.85-6.42a4.2,4.2,0,0,1-3.28-1.84c-4.54-7.18,10.43-23.39,28.34-34.54a64.39,64.39,0,0,1,8.73-4.57,45.31,45.31,0,0,1,16.37-3.85,3,3,0,0,1,2.56,4.74A61.06,61.06,0,0,1,306.2,70.9c-1.91,1.87-4.21,4.06-8,8.3a66.86,66.86,0,0,1-7.78,7.23,118.22,118.22,0,0,1,13,1.44,58.6,58.6,0,0,1,15.95,4.93A43.78,43.78,0,0,1,326,96.74,4,4,0,0,1,324.52,103.9Z"/><path class="cT4" d="M324.52,103.9c-1.94.46-3.53.78-4.9,1-5.95,1-7.95.42-18.38,1.63-11.84,1.37-31.31-1.26-38.85-6.42a4.2,4.2,0,0,1-3.28-1.84c-4.54-7.18,10.43-23.39,28.34-34.54a64.39,64.39,0,0,1,8.73-4.57,45.31,45.31,0,0,1,16.37-3.85,3,3,0,0,1,2.56,4.74A61.06,61.06,0,0,1,306.2,70.9c-1.91,1.87-4.21,4.06-8,8.3a66.86,66.86,0,0,1-7.78,7.23,118.22,118.22,0,0,1,13,1.44,58.6,58.6,0,0,1,15.95,4.93A43.78,43.78,0,0,1,326,96.74,4,4,0,0,1,324.52,103.9Z"/><path class="dT4" d="M324.52,103.9c-1.94.46-3.53.78-4.9,1-5.95,1-7.95.42-18.38,1.63-11.84,1.37-31.31-1.26-38.85-6.42a4.2,4.2,0,0,1-3.28-1.84c-4.54-7.18,10.43-23.39,28.34-34.54a64.39,64.39,0,0,1,8.73-4.57,45.31,45.31,0,0,1,16.37-3.85,3,3,0,0,1,2.56,4.74A61.06,61.06,0,0,1,306.2,70.9c-1.91,1.87-4.21,4.06-8,8.3a66.86,66.86,0,0,1-7.78,7.23,118.22,118.22,0,0,1,13,1.44,58.6,58.6,0,0,1,15.95,4.93A43.78,43.78,0,0,1,326,96.74,4,4,0,0,1,324.52,103.9Z"/>';
    bytes constant data5 = '<path class="bT5" d="M259.87,85.61,305,63.32a1.34,1.34,0,0,1,1.82,1.73c-3.76,8.64-12.4,32.25-6,54.57a1.74,1.74,0,0,1-2.39,2l-47.3-21.42"/><path class="cT5" d="M260.05,87.91s23.1-5.46,28.87-7.8"/><path class="cT5" d="M259.73,91.81s20.29,0,28.41-2.18"/><path class="cT5" d="M259.42,95.87s20,4.22,28.41,2.81"/><path class="cT5" d="M259.11,99.46c-2.77-.41,11.27,10.75,30.29,8.24"/><path class="cT5" d="M256.77,89.47s30.59-4.52,33.71-3.28"/><path class="cT5" d="M257.7,97s23.88,10.15,32.31,5.16"/><circle class="dT5" cx="290.56" cy="80.03" r="1.79"/><circle class="dT5" cx="292.28" cy="85.88" r="1.79"/><circle class="dT5" cx="289.62" cy="89.63" r="1.79"/><circle class="dT5" cx="288.89" cy="98.19" r="1.79"/><circle class="dT5" cx="291.81" cy="101.49" r="1.79"/><circle class="dT5" cx="290.86" cy="106.94" r="1.79"/>';
    bytes constant data6 = '<polygon class="bT6" points="305.31 109.7 258.79 101.04 258.78 101.04 257.86 100.87 257.86 100.87 257.34 100.77 258.36 91.16 258.36 91.15 258.64 88.48 301.99 67.86 302.33 72.12 302.87 78.99 303.16 82.64 303.76 90.18 304.26 96.44 304.61 100.87 305.31 109.7"/><polygon class="cT6" points="302.87 78.99 258.89 93.13 258.36 91.16 258.36 91.15 258.36 91.15 302.33 72.12 302.87 78.99"/><polygon class="cT6" points="303.76 90.18 259.64 97.09 259.64 95.11 303.16 82.64 303.76 90.18"/><polygon class="cT6" points="304.61 100.87 258.79 101.04 258.78 101.04 257.82 101.04 257.86 100.87 257.86 100.87 258.46 98.35 304.26 96.44 304.61 100.87"/>';
    bytes constant data7 = '<path class="bT7" d="M342.54,69.66c-5.64-.72-16.91,2.53-25.05,5.26,5.09-7.84,8.85-17.66.87-23-11.54-7.7-14.95,16.66-15.87,27.35-.15.1-18.1,11.8-44.46,5.65s-23.54,22.21-5.92,23.91S287.75,107.57,309,87.4a160.73,160.73,0,0,0,25.71-1.81C353.41,83,346.41,69.42,342.54,69.66Z"/>';
    bytes constant data8 = '<path class="bT8" d="M260.63,88.66s37.48-22.29,40.5-15-.67,7.66-.67,7.66,5.35,3.48.67,7.66c0,0,3.68,3.14.67,6.27,0,0,5.35,3.48,0,7.66,0,0,5.69,4.18.33,7s-33.87-6.33-41.36-10.65-.14-10.6-.14-10.6h3"/><path class="cT8" d="M260.44,89.13s35.08-20,37.9-13.47-.62,6.89-.62,6.89,5,3.13.62,6.89c0,0,3.45,2.82.63,5.64,0,0,5,3.13,0,6.89,0,0,5.32,3.76.31,6.27s-31.7-5.7-38.72-9.58-.12-9.53-.12-9.53h0"/>';
    bytes constant data9 = '<path class="bT9" d="M257.68,93.51s48.39-19.15,20.95-42.12c0,0,7.42-6.31,16.79.4,0,0,11.52-.26,13,8.29,0,0,10.3.29,10.1,8.68,0,0,8.23,2.94,5.16,11.73a11.05,11.05,0,0,1,2.51,14.23S336.73,103,329,111.31c0,0,3.74,9.1-7.55,15,0,0,2.08,8.94-16.72,10.36,0,0-2.89-32.44-46.93-36.45Z"/><path class="cT9" d="M291.4,62.19s1.54,15.45-14.17,26.52c0,0,26.53-19.06,23.7-24.46S295,59.61,291.4,62.19Z"/><path class="cT9" d="M277.75,91.54S302,74.81,306.33,78.41s4.9,5.15,2.84,8.76S277.75,91.54,277.75,91.54Z"/><path class="cT9" d="M278,94.63,310.71,97s6.34,4.08,1.19,9.68a2.82,2.82,0,0,1-2.71.82C296.76,104.6,278,94.63,278,94.63Z"/><path class="cT9" d="M277.23,98.75s23.47,14.33,27.88,21a2.62,2.62,0,0,0,3.31.89c3.09-1.45,7.44-4.36,4.09-8.23C306.33,108.54,297.58,107.77,277.23,98.75Z"/><ellipse class="cT9" cx="308.87" cy="69.9" rx="3.29" ry="3.44"/><ellipse class="cT9" cx="317.24" cy="91.27" rx="3.29" ry="3.44"/><ellipse class="cT9" cx="318.18" cy="110.23" rx="3.29" ry="3.44"/>';

    function getAttr(uint idx) external pure override returns (bytes memory) {
        if (idx == 0) { return attr0; }
        if (idx == 1) { return attr1; }
        if (idx == 2) { return attr2; }
        if (idx == 3) { return attr3; }
        if (idx == 4) { return attr4; }
        if (idx == 5) { return attr5; }
        if (idx == 6) { return attr6; }
        if (idx == 7) { return attr7; }
        if (idx == 8) { return attr8; }
                        return attr9;
    }

    function getStyle(uint idx) external pure override returns (bytes memory) {
        if (idx == 0) { return style0; }
        if (idx == 1) { return style1; }
        if (idx == 2) { return style2; }
        if (idx == 3) { return style3; }
        if (idx == 4) { return style4; }
        if (idx == 5) { return style5; }
        if (idx == 6) { return style6; }
        if (idx == 7) { return style7; }
        if (idx == 8) { return style8; }
                        return style9;
    }

    function getData(uint idx) external pure override returns (bytes memory) {
        if (idx == 0) { return data0; }
        if (idx == 1) { return data1; }
        if (idx == 2) { return data2; }
        if (idx == 3) { return data3; }
        if (idx == 4) { return data4; }
        if (idx == 5) { return data5; }
        if (idx == 6) { return data6; }
        if (idx == 7) { return data7; }
        if (idx == 8) { return data8; }
                        return data9;
    }

}