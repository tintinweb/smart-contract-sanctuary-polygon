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


// File contracts/data/HeadData.sol

pragma solidity ^0.8.0;

contract HeadData is IFishData {

    bytes constant attr0 = 'Awl';
    bytes constant attr1 = 'Squre';
    bytes constant attr2 = 'Semicircle';
    bytes constant attr3 = 'Taper';
    bytes constant attr4 = 'Cone';
    bytes constant attr5 = 'Hopper';
    bytes constant attr6 = 'Sector';
    bytes constant attr7 = 'Stamper';
    bytes constant attr8 = 'Nut';
    bytes constant attr9 = 'Beards';

    bytes constant style0 = '.bH10{fill:#231815;}';
    bytes constant style1 = '.bH1{fill:#58beb9;}.cH1{fill:#feeb00;}';
    bytes constant style2 = '.bH2{fill:#324681;}.cH2{fill:#d7000f;}';
    bytes constant style3 = '.bH3{fill:#d363a1;}.cH3{fill:#8e60a6;}';
    bytes constant style4 = '.bH4{fill:#57a5dc;}.cH4{fill:#324681;}.cH4,.dH4{stroke:#231815;stroke-miterlimit:10;}.dH4{fill:#204b95;}';
    bytes constant style5 = '.bH5{fill:#ffd600;}';
    bytes constant style6 = '.bH6{fill:#d7000f;}';
    bytes constant style7 = '.bH7{fill:#4ab134;}';
    bytes constant style8 = '.bH8{fill:#e36106;}.cH8{fill:#fff;}.dH8{fill:#231815;}';
    bytes constant style9 = '.bH9{fill:#8e60a6;}';

    bytes constant data0 = '<path class="bH10" d="M142.72,142.77s-53.51,2.47-57.13-41.41c-8.69,0-40.79-.38-40.79-4.64s31.81-5.26,40.85-5.47C89.56,48,139.93,48.57,139.93,48.57s34.23,16.82,37.42,37.71S142.72,142.77,142.72,142.77Z"/>';
    bytes constant data1 = '<path class="bH1" d="M84.88,65.59l1.91,75c.09,3.24,3.4,5.74,7.19,5.4,16.52-1.49,52.1-1.92,70.34-6.18,13.46-2.29,4.46-70.18,1.46-90.5-.46-3.11-5.63-5.12-10.8-4.11-5.41,3.15-57.64,7.68-57.64,7.68C90,53.85,84.72,59.29,84.88,65.59Z"/><path class="bH1" d="M98.26,55.81c-1.64-9.09-5.3-20.4-16.54-20.06-11.64.36-15.53,10.46-14.16,20.69.25,1.89,3.25,1.92,3,0-1.19-8.9,2.17-19.35,13.29-17.53C92.2,40.27,94.1,49.6,95.36,56.6c.35,1.9,3.24,1.1,2.9-.79Z"/><circle class="cH1" cx="69.97" cy="60.14" r="4.5"/><path class="cH1" d="M74.4,55.3l.64-1a1.5,1.5,0,0,0-2.59-1.51l-.64,1A1.5,1.5,0,0,0,74.4,55.3Z"/><path class="cH1" d="M76.26,58.48c-.13.11.21,0,.09,0s.3,0,.06,0a1.5,1.5,0,0,0,0-3,3.88,3.88,0,0,0-2.27.9,1.51,1.51,0,0,0,0,2.12,1.53,1.53,0,0,0,2.12,0Z"/><path class="cH1" d="M75.57,62.64l1.43.57a1.49,1.49,0,0,0,1.84-1.05,1.54,1.54,0,0,0-1-1.84l-1.44-.57a1.49,1.49,0,0,0-1.84,1,1.54,1.54,0,0,0,1,1.85Z"/><path class="cH1" d="M73.13,65.81A9.46,9.46,0,0,1,74,67.45a1.53,1.53,0,0,0,1.84,1,1.5,1.5,0,0,0,1-1.84,12,12,0,0,0-1.14-2.36,1.54,1.54,0,0,0-2-.54,1.51,1.51,0,0,0-.54,2.05Z"/><path class="cH1" d="M70,66.57l.21,1.11a1.51,1.51,0,0,0,1.84,1,1.55,1.55,0,0,0,1-1.85l-.2-1.11a1.52,1.52,0,0,0-1.85-1,1.54,1.54,0,0,0-1,1.85Z"/><path class="cH1" d="M65.13,55.72a.24.24,0,0,1-.13-.13.94.94,0,0,1,.14.26,1.5,1.5,0,0,0,2.59-1.52,3.22,3.22,0,0,0-1.09-1.2,1.51,1.51,0,0,0-2,.54,1.53,1.53,0,0,0,.54,2Z"/><path class="cH1" d="M63.27,58.3l.89.33A1.52,1.52,0,0,0,66,57.58,1.54,1.54,0,0,0,65,55.74l-.89-.33a1.5,1.5,0,0,0-1.84,1.05,1.54,1.54,0,0,0,1,1.84Z"/><path class="cH1" d="M64.1,61.59c.24-.18,0,0-.1,0a1.5,1.5,0,0,0,0-3,2.47,2.47,0,0,0-1.42.43,1.55,1.55,0,0,0-.53,2.06,1.51,1.51,0,0,0,2,.53Z"/><path class="cH1" d="M65.06,64.79l.56-.55a1.53,1.53,0,0,0,0-2.12,1.51,1.51,0,0,0-2.12,0l-.56.55a1.53,1.53,0,0,0,0,2.12,1.51,1.51,0,0,0,2.12,0Z"/><path class="cH1" d="M66.53,67.68a4.58,4.58,0,0,0,1.32-1.31,1.5,1.5,0,0,0-2.59-1.51c-.13.18,0,0-.11.12s.27-.15-.13.11a1.54,1.54,0,0,0-.54,2.06,1.51,1.51,0,0,0,2,.53Z"/><path class="cH1" d="M70.14,67.83l.13-1.22a1.5,1.5,0,0,0-1.5-1.5,1.54,1.54,0,0,0-1.5,1.5l-.13,1.22a1.5,1.5,0,0,0,1.5,1.5,1.54,1.54,0,0,0,1.5-1.5Z"/><path class="cH1" d="M69.35,52.47l-.78,1a1.54,1.54,0,0,0,0,2.12,1.5,1.5,0,0,0,2.12,0l.79-1a1.56,1.56,0,0,0,0-2.12,1.51,1.51,0,0,0-2.13,0Z"/>';
    bytes constant data2 = '<path class="bH2" d="M91.6,124.54c27.82,37.6,70.53,10.25,72,10.91s3.42-83,3.42-83l-28-3.55s-34.53-15-40.38,10.62c-5.69,25-34.25,2.67-14.81,50.21"/><circle class="cH2" cx="76.97" cy="76.14" r="5"/>';
    bytes constant data3 = '<path class="bH3" d="M138.47,48.64s-48.5,6-54,31.5c-12.66,58.68-74.5,45-74.5,45s-6,4,1,4,114.5,27,132,13.5,24.5-66,24.5-66Z"/><path class="cH3" d="M10.65,128.33a1.5,1.5,0,0,0,0-3,1.5,1.5,0,0,0,0,3Z"/><path class="cH3" d="M9.23,129.48a1.5,1.5,0,0,0,0-3,1.5,1.5,0,0,0,0,3Z"/>';
    bytes constant data4 = '<path class="bH4" d="M138.75,48.76S28.46,67.25,27.07,79.55,130.6,144.43,142.72,143C185,138.15,174.6,95.05,174.6,95.05S154.67,45.41,138.75,48.76Z"/><path class="cH4" d="M124.54,85.42l.39,27.66s4-8.26,3.45-17.28S124.54,85.42,124.54,85.42Z"/><path class="cH4" d="M133,86.89l.38,27.65s4-8.25,3.46-17.28S133,86.89,133,86.89Z"/><path class="cH4" d="M141.74,86.89l.39,27.65s4-8.25,3.45-17.28S141.74,86.89,141.74,86.89Z"/><path class="dH4" d="M31.38,80.33s3.12-1.24,4.75-.11S31.38,80.33,31.38,80.33Z"/><path class="dH4" d="M31,82s1.86,2.79,3.84,2.79S31,82,31,82Z"/>';
    bytes constant data5 = '<path class="bH5" d="M138.67,48.6C106.41,53.91,107,85.44,86.1,96.26c-23.35,12,35.47,47.24,56.46,46.59,20.1-.62,41.45-62.77,41.45-62.77S170.93,43.29,138.67,48.6Z"/><path class="bH5" d="M85.89,97.22c-16.38,7.28-21,1.18-25.7-3.92s-8.94,6.81-2.13,11.06S93.4,116.71,93.4,116.71,93.17,101.59,85.89,97.22Z"/>';
    bytes constant data6 = '<path class="bH6" d="M142.88,142.82l-83.21-.06a7.45,7.45,0,0,1-6.93-10.19c8.15-20.54,32.12-66.35,85.85-84C185.14,49.69,161.69,128.64,142.88,142.82Z"/>';
    bytes constant data7 = '<path class="bH7" d="M171.34,96.92l-28.68,45.93L90,130.42v15a6,6,0,0,1-6,6H73.06a14.56,14.56,0,0,1-14.52-14.52v-94A10.56,10.56,0,0,1,69.06,32.38H84a6,6,0,0,1,6,6v20.3l48.63-10L160.08,60.1Z"/>';
    bytes constant data8 = '<path class="bH8" d="M176.14,86.1s-8.31,53.31-33.68,56.79a29.14,29.14,0,0,1-2.94.25c-.35,0-.7,0-1.05,0s-.7,0-1.05,0a33.42,33.42,0,0,1-5.43-.6l-.81-.15-.78-.18c-21.55-5-41.94-28.84-43.85-44.78C85,84.5,109.93,66.38,125.79,56.26l.66-.42.65-.41c3-1.9,5.61-3.47,7.58-4.62l.68-.4h0L136,50c1.54-.89,2.42-1.37,2.42-1.37Z"/><path class="cH8" d="M135.36,50.41h0l-.68.4c-2,1.15-4.58,2.72-7.58,4.62l-.65.41c9.92,8.16,34.43,41.73,4.73,86.56l.81.14a19.7,19.7,0,0,0,5.45.61h1C148.93,132.07,173.77,84.13,135.36,50.41Z"/><path class="dH8" d="M136,50l-.68.4h0l-.68.4c19.15,16.74,21.71,36.53,20.3,50.62-2,19.64-12.27,36.35-17.47,41.63l-.09.09c.35,0,.7,0,1.05,0s.7,0,1.05,0c5.95-6.65,15.1-23.21,16.95-41.56C157.92,87.22,155.33,67.09,136,50Zm7.29,31.18c-4.06-12.8-11.53-21.83-16.23-25.76l-.65.41-.66.42c4.37,3.53,12.06,12.58,16.11,25.38,4.25,13.44,5.67,34.8-11.5,60.58l.78.18.81.15,0-.06C149.13,116.46,147.65,94.83,143.33,81.19Z"/>';
    bytes constant data9 = '<path class="bH9" d="M139.19,48.7S60.7,58.39,75.3,97.87,98.61,151,143.52,142.53c30-5.64,30.55-24.88,33.53-40.84S139.19,48.7,139.19,48.7Z"/><path class="bH9" d="M74.27,88.3C70.74,87,67.91,85,64.91,83.47a20.29,20.29,0,0,0-4.67-1.76,12.92,12.92,0,0,0-5-.12,13.38,13.38,0,0,1,5.16-.87,21.21,21.21,0,0,1,5.26.88c3.41,1,6.63,2.33,9.73,2.85Z"/><path class="bH9" d="M74.35,90.32c-3.64-1-6.65-2.7-9.79-3.9a20.13,20.13,0,0,0-4.81-1.29,12.85,12.85,0,0,0-5,.38,13.36,13.36,0,0,1,5.05-1.38,22,22,0,0,1,5.32.36c3.48.62,6.82,1.68,10,1.89Z"/><path class="bH9" d="M76,92.28a33.61,33.61,0,0,1-11.12,1.91A100.58,100.58,0,0,1,54,93.62,98.29,98.29,0,0,0,64.67,92.2a30.73,30.73,0,0,0,9.63-3.53Z"/><path class="bH9" d="M75.66,94.46a33.81,33.81,0,0,1-11.12,1.9,97.79,97.79,0,0,1-10.87-.57,97.77,97.77,0,0,0,10.65-1.41A30.8,30.8,0,0,0,74,90.84Z"/>';

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