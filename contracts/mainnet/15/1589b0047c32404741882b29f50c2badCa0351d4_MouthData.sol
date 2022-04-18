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


// File contracts/data/MouthData.sol

pragma solidity ^0.8.0;

contract MouthData is IFishData {

    bytes constant attr0 = 'Pride';
    bytes constant attr1 = 'Greedy';
    bytes constant attr2 = 'Laugh';
    bytes constant attr3 = 'Rude';
    bytes constant attr4 = 'Kissy';
    bytes constant attr5 = 'Smile';
    bytes constant attr6 = 'Snicker';
    bytes constant attr7 = 'Surprise';
    bytes constant attr8 = 'Sad';
    bytes constant attr9 = 'Awkward';

    bytes constant style0 = '.dM10{fill:none;}.bM10{fill:#ffd600;}.bM10,.dM10{stroke:#f08223;stroke-miterlimit:10;}.cM10{fill:#fff;}';
    bytes constant style1 = '.dM1{fill:none;}.bM1{fill:#d7000f;stroke:#b7021d;}.bM1,.dM1{stroke-miterlimit:10;}.cM1{fill:#45b9ec;}.dM1{stroke:#fff;}';
    bytes constant style2 = '.bM2{fill:#e36106;stroke:#e60012;stroke-miterlimit:10;}';
    bytes constant style3 = '.bM3{fill:#231815;stroke:#8e60a6;stroke-miterlimit:10;stroke-width:6px;}.cM3{fill:#fff;}';
    bytes constant style4 = '.bM4{fill:#d7000f;}';
    bytes constant style5 = '.bM5{fill:none;}.bM5{stroke:#231815;stroke-miterlimit:10;stroke-width:2px;}';
    bytes constant style6 = '.bM6{fill:#b91a20;}.cM6{fill:#fff;}';
    bytes constant style7 = '.bM7{fill:#e36106;stroke:#57a5dc;stroke-miterlimit:10;stroke-width:6px;}';
    bytes constant style8 = '.bM8{fill:#e1e8f6;stroke:#e60012;stroke-miterlimit:10;}';
    bytes constant style9 = '.cM9{fill:none;}.bM9{fill:#fff;}.bM9,.cM9{stroke:#db0010;stroke-miterlimit:10;stroke-width:3px;}';

    bytes constant data0 = '<path class="bM10" d="M102.52,106.29s-6.35,1.4-.94,7.51,30.06,7,28.65.71S102.52,106.29,102.52,106.29Z"/><path class="cM10" d="M105.08,110.08l3.07-7.23,1.09,8.53S106.1,111,105.08,110.08Z"/><path class="cM10" d="M109.17,111.24l3.08-7.23,1.09,8.53S110.2,112.19,109.17,111.24Z"/><path class="dM10" d="M102.19,109.05s12,5.54,24.41,6"/>';
    bytes constant data1 = '<path class="bM1" d="M98.46,122.46c2.53,2.84-8.82,4.68-7.53,7.73s18.2-4.34,15.64-4.42Z"/><path class="cM1" d="M88.81,129.19s-5.94.49-5.56,3S88.81,129.19,88.81,129.19Z"/><path class="cM1" d="M91,132.2s-2.58,5.38-.23,6.32S91,132.2,91,132.2Z"/><path class="dM1" d="M91.3,117.54s21.58,19.16,36.25.18"/>';
    bytes constant data2 = '<path class="bM2" d="M126.76,125.22h0s-8.93,10.94-21.28.89a25.62,25.62,0,0,1-6.91-7.81A24.75,24.75,0,0,0,108.85,125c2.81-.66,6.38-1,7,1.18a1.85,1.85,0,0,1,.09.49,2.79,2.79,0,0,1,.22-.49c.62-1.15,2.77-3.77,8.75-1.68a38.71,38.71,0,0,0,10.91-6.53A43.86,43.86,0,0,1,126.76,125.22Z"/>';
    bytes constant data3 = '<path class="bM3" d="M85.7,119a3.29,3.29,0,0,1,3-2.92c6.81-.65,26.34-1.85,38.57,4.27,14.1,7-8.91,12.77-11.72,13.43a2.8,2.8,0,0,1-.57.08C111.78,134.08,84,135.19,85.7,119Z"/><polygon class="cM3" points="90.39 117.39 92.82 125.83 94.64 117.24 90.39 117.39"/><polygon class="cM3" points="96.39 117.39 98.82 125.83 100.64 117.24 96.39 117.39"/><polygon class="cM3" points="103.73 117.66 105.44 126.27 107.98 117.87 103.73 117.66"/><polygon class="cM3" points="110.88 118.05 112.09 125.23 115.11 118.33 110.88 118.05"/><polygon class="cM3" points="117.47 118.69 117.41 125.97 121.59 119.71 117.47 118.69"/><polygon class="cM3" points="123.22 120.61 122.78 127.88 127.28 121.83 123.22 120.61"/><polygon class="cM3" points="110.07 132.49 108.88 125.3 105.84 132.19 110.07 132.49"/><polygon class="cM3" points="117.1 132.07 114.78 125.17 112.88 132.45 117.1 132.07"/><polygon class="cM3" points="102.97 132.34 103.09 123.56 98.7 131.22 102.97 132.34"/>';
    bytes constant data4 = '<ellipse class="bM4" cx="94.83" cy="121.48" rx="9.36" ry="6.28" transform="translate(-36.55 40.93) rotate(-20.51)"/><ellipse class="bM4" cx="94.87" cy="115.67" rx="6.28" ry="10.79" transform="translate(-53.62 133.85) rotate(-57.62)"/>';
    bytes constant data5 = '<path class="bM5" d="M97.42,117a40.13,40.13,0,0,1-7.07-.58l.4-2c.18,0,18.1,3.49,25.91-7.21l1.61,1.18C113,115.62,103.83,117,97.42,117Z"/><path class="cM5" d="M97.42,117.52a41.71,41.71,0,0,1-7.16-.58l-.5-.1.59-2.94.49.09c.18,0,17.86,3.34,25.41-7l.3-.4,2.42,1.77-.29.4C113.38,116,104.19,117.52,97.42,117.52ZM90.94,116a42.7,42.7,0,0,0,6.48.48c6.41,0,15.06-1.39,20.15-8l-.81-.59c-7.41,9.55-22.63,7.59-25.62,7.1Z"/>';
    bytes constant data6 = '<path class="bM6" d="M83.64,111.46l65.7,6.45s-47.76,3.62-63.77-2.19S83.64,111.46,83.64,111.46Z"/><polygon class="cM6" points="86.36 111.85 87.42 114.38 88.72 112.2 86.36 111.85"/><polygon class="cM6" points="83.99 111.56 85.05 114.09 86.34 111.92 83.99 111.56"/><polygon class="cM6" points="81.65 111.32 82.81 113.81 84.02 111.58 81.65 111.32"/><polygon class="cM6" points="80.06 111.28 80.93 113.01 81.73 111.41 80.06 111.28"/><polygon class="cM6" points="93.43 112.74 94.69 115.17 95.81 112.9 93.43 112.74"/><polygon class="cM6" points="91.06 112.56 92.32 114.99 93.43 112.72 91.06 112.56"/><polygon class="cM6" points="98.16 113.23 99.22 115.76 100.51 113.59 98.16 113.23"/><polygon class="cM6" points="95.81 112.86 96.87 115.39 98.17 113.21 95.81 112.86"/><polygon class="cM6" points="102.88 113.75 104.14 116.18 105.25 113.9 102.88 113.75"/><polygon class="cM6" points="100.51 113.56 101.77 116 102.88 113.72 100.51 113.56"/><polygon class="cM6" points="107.58 114.24 108.64 116.77 109.93 114.59 107.58 114.24"/><polygon class="cM6" points="105.23 113.87 106.29 116.4 107.58 114.22 105.23 113.87"/><polygon class="cM6" points="112.3 114.75 113.56 117.19 114.67 114.91 112.3 114.75"/><polygon class="cM6" points="109.92 114.57 111.19 117.01 112.3 114.73 109.92 114.57"/>';
    bytes constant data7 = '<path class="bM7" d="M132.59,125.43H100.11A4.49,4.49,0,0,1,95.64,121h0c0-2.46,2-4.47,4.57-3.68h32.48c2.36-.21,8-1.06,8,1l-.1,1.38C140.56,122.09,135.05,125.43,132.59,125.43Z"/>';
    bytes constant data8 = '<path class="bM8" d="M93,113.57s6.81-11.8,23.06,14.67"/>';
    bytes constant data9 = '<path class="bM9" d="M95.52,112.12a1.22,1.22,0,0,1,1.13-1.48c4.95-.24,21.6-.79,24.29,2.8,3.17,4.23-19.48,6.34-22.2,4.68C96.87,117,95.93,113.93,95.52,112.12Z"/><line class="cM9" x1="100.56" y1="110.58" x2="102.05" y2="118.46"/><line class="cM9" x1="107.81" y1="110.5" x2="108.21" y2="118.23"/><line class="cM9" x1="114.12" y1="111.05" x2="114.04" y2="117.04"/>';

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