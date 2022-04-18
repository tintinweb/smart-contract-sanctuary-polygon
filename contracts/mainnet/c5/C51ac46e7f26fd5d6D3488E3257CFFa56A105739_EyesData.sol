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


// File contracts/data/EyesData.sol

pragma solidity ^0.8.0;

contract EyesData is IFishData {

    bytes constant attr0 = 'Muzzy';
    bytes constant attr1 = 'Desired';
    bytes constant attr2 = 'Tricky';
    bytes constant attr3 = 'Scared';
    bytes constant attr4 = 'Cute';
    bytes constant attr5 = 'Tired';
    bytes constant attr6 = 'Frowned';
    bytes constant attr7 = 'Curious';
    bytes constant attr8 = 'Moonish';
    bytes constant attr9 = 'Faint';

    bytes constant style0 = '.bE10{fill:#f08223;}.cE10{fill:#231815;}';
    bytes constant style1 = '.bE1{fill:#e1e8f6;}.cE1{fill:#231815;}';
    bytes constant style2 = '.bE2{fill:#e1e8f6;}.cE2{fill:#231815;}.dE2{fill:#d363a1;opacity:0.87;}.eE2{fill:#e1007f;opacity:0.62;}';
    bytes constant style3 = '.eE3{fill:none;}.bE3{fill:#feeb00;}.cE3{fill:#e1e8f6;}.dE3{fill:#231815;}.eE3{stroke:#feeb00;stroke-miterlimit:10;}';
    bytes constant style4 = '.bE4{fill:#231815;stroke:#204b95;stroke-miterlimit:10;}';
    bytes constant style5 = '.bE5{fill:#e1e8f6;stroke-width:2px;}.bE5,.cE5{stroke:#231815;stroke-miterlimit:10;}.cE5{fill:#45b9ec;}.dE5,.gE5{fill:#231815;}.eE5{fill:#fff;}.fE5{fill:#d7000f;}.gE5{opacity:0.22;}';
    bytes constant style6 = '.bE6{fill:#231815;stroke:#feeb00;stroke-miterlimit:10;}.cE6{fill:#d363a1;opacity:0.85;}';
    bytes constant style7 = '.bE7{fill:none;}.bE7{stroke:#231815;stroke-miterlimit:10;}.cE7{fill:#e1e8f6;}.dE7{fill:#231815;}';
    bytes constant style8 = '.bE8{fill:#e1e8f6;stroke:#231815;}.bE8,.dE8{stroke-miterlimit:10;}.cE8,.dE8{fill:#231815;}.dE8{stroke:#fff;}';
    bytes constant style9 = '.bE9{fill:none;}.bE9{stroke:#231815;stroke-miterlimit:10;stroke-width:2px;}';

    bytes constant data0 = '<circle class="bE10" cx="120.79" cy="75.83" r="9.28"/><circle class="cE10" cx="120.79" cy="75.83" r="3.19"/>';
    bytes constant data1 = '<circle class="bE1" cx="124.22" cy="88.89" r="15.75"/><circle class="cE1" cx="124.22" cy="89.39" r="6.25"/>';
    bytes constant data2 = '<path class="bE2" d="M99.47,73.64s10-9,23,.5C122.47,74.14,112,89.14,99.47,73.64Z"/><path class="cE2" d="M110.47,74.39a5.75,5.75,0,0,1-3.61,5.34,20,20,0,0,1-7.39-6.09,17.33,17.33,0,0,1,8.85-3.73A5.73,5.73,0,0,1,110.47,74.39Z"/><ellipse class="dE2" cx="120.72" cy="88.64" rx="10.75" ry="6"/><ellipse class="eE2" cx="116.47" cy="89.14" rx="1" ry="3"/><ellipse class="eE2" cx="120.97" cy="89.14" rx="1" ry="3"/><ellipse class="eE2" cx="125.47" cy="89.14" rx="1" ry="3"/>';
    bytes constant data3 = '<circle class="bE3" cx="120.84" cy="64.26" r="15.13"/><circle class="cE3" cx="117.55" cy="63.02" r="11.73"/><circle class="dE3" cx="111.92" cy="61.3" r="2.19"/><path class="eE3" d="M107.47,77.14s21.75,16.75,28,0"/>';
    bytes constant data4 = '<circle class="bE4" cx="103.35" cy="67.16" r="4.54"/><circle class="bE4" cx="113.67" cy="73.76" r="4.54"/>';
    bytes constant data5 = '<circle class="bE5" cx="134.98" cy="88.24" r="13.16"/><circle class="cE5" cx="130.47" cy="85.83" r="5.44"/><circle class="dE5" cx="129.5" cy="84.98" r="2.78"/><circle class="eE5" cx="127.74" cy="83.06" r="0.46"/><path class="fE5" d="M139.24,95.1c0,.63,0,1.26,0,1.89l0-.09c.27.12.54.26.81.39l.06,0v.07l.08,1.08-.15-.12,1-.19-.05,0c.32-.25.64-.48,1-.72l.14-.11,0,.18c0,.25-.06.49-.1.74l0,0,.45.44-.5-.38h0v0q0-.37,0-.75l.12.07-.92.77,0,0h0l-.95.22-.14,0v-.15l-.06-1.08.06.1c-.27-.14-.54-.27-.8-.42L139,97V97C139.07,96.35,139.14,95.72,139.24,95.1Z"/><path class="fE5" d="M142.7,81.51c.25.58.48,1.17.7,1.76l-.09-.07.91,0h.06l0,.06.49,1-.18,0,.8-.54,0,0c.2-.35.41-.69.62-1l.09-.16,0,.17c.07.24.13.48.19.73l0,0,.58.23-.6-.15h0v0c-.09-.23-.18-.46-.26-.7l.14,0c-.18.35-.36.71-.55,1.06v0l0,0-.79.56-.12.08-.06-.13-.47-1,.09.06-.9-.07h-.07v-.06C143,82.73,142.86,82.12,142.7,81.51Z"/><path class="fE5" d="M142.94,87c.62-.08,1.25-.15,1.88-.2l-.09.06c.09-.29.19-.57.29-.85l0-.07h.06l1.06-.21-.09.16-.31-.91,0,0c-.28-.28-.55-.58-.83-.87l-.12-.13h.92l0,0,.37-.5-.31.54v0h0l-.74.07,0-.14.88.82,0,0v0l.33.91,0,.14-.14,0-1.06.19.08-.07c-.1.28-.2.57-.31.85l0,.06h-.06C144.2,87,143.57,87,142.94,87Z"/><path class="fE5" d="M128.41,94.91c.28.53.55,1.07.79,1.61l-.09-.06c.43,0,.86,0,1.29,0l-.07,0c.56-.42,1.14-.81,1.68-1.24l0,0h0c.43.24.87.45,1.31.67h0l0,0c.41.57.81,1.15,1.21,1.73l0,0v0c-.08.55-.15,1.1-.25,1.64v0c.22.68.43,1.36.61,2h0c-.29-.65-.56-1.32-.81-2v0c.06-.55.15-1.1.22-1.65l0,.1c-.38-.6-.76-1.19-1.13-1.79l0,0c-.42-.25-.84-.5-1.27-.74h0c-.55.43-1.07.89-1.6,1.34l0,0h0q-.65,0-1.29,0H129l0-.06c-.22-.55-.43-1.11-.62-1.68Z"/><path class="fE5" d="M145.77,94.22c-.16.34-.33.68-.52,1l0,0h-.06c-.36,0-.73,0-1.09,0H144a13.11,13.11,0,0,0-1.36-.8h0l-1.07.46,0,0c-.32.36-.63.71-1,1l0-.12c.06.32.12.64.17,1v0l0,0c-.21.39-.44.77-.68,1.14h0c.16-.41.33-.82.52-1.22v.07c-.08-.32-.15-.64-.22-1v-.06l.05,0c.32-.35.66-.68,1-1l0,0h0l1.11-.36h0a14.22,14.22,0,0,0,1.41.7h0c.36,0,.73,0,1.09,0l-.08.05c.2-.31.43-.62.66-.91Z"/><path class="fE5" d="M138.6,89.37c.57.19,1.13.39,1.68.61l-.11,0c.3-.3.61-.61.93-.9l0,.07c.12-.69.26-1.37.35-2.06v0h0c.47-.13.94-.28,1.4-.43h0l2.08.41H145l0,0c.32.45.65.89.95,1.35l0,0c.63.34,1.26.68,1.87,1v0c-.66-.28-1.31-.57-2-.88h0l0,0c-.34-.44-.66-.89-1-1.34l.08.06c-.68-.17-1.37-.33-2-.51h0c-.48.11-1,.22-1.43.35l0,0c-.1.69-.15,1.38-.23,2.07v0l0,0q-.45.47-.93.9l-.05,0-.06,0c-.54-.24-1.08-.5-1.61-.78Z"/><path class="gE5" d="M140.54,76.31s11.18,19.39-9.23,23.74C139.6,106.94,159.39,88.9,140.54,76.31Z"/>';
    bytes constant data6 = '<path class="bE6" d="M131.8,66.15S143.32,83,150.23,67.44C150.23,67.44,143.15,77.68,131.8,66.15Z"/><path class="bE6" d="M109.82,58.36s7.56,19,17.7,5.29C127.52,63.65,118.38,72.1,109.82,58.36Z"/><circle class="cE6" cx="112.1" cy="71.86" r="4.75"/><circle class="cE6" cx="144.67" cy="80.39" r="4.75"/>';
    bytes constant data7 = '<line class="bE7" x1="127.59" y1="70.98" x2="126.98" y2="69.5"/><line class="bE7" x1="135.36" y1="70.91" x2="136.42" y2="69.59"/><line class="bE7" x1="131.27" y1="69.65" x2="131.22" y2="68.33"/><circle class="cE7" cx="131.26" cy="76.77" r="7.16"/><circle class="dE7" cx="129.79" cy="76.52" r="4.01"/>';
    bytes constant data8 = '<path class="bE8" d="M134,81.46v0a10.28,10.28,0,1,1-16.51-8.17,10.14,10.14,0,0,1,6.23-2.11A10.28,10.28,0,0,1,134,81.46Z"/><path class="cE8" d="M134,81.46a9.12,9.12,0,0,1-7.89,4.68A9.36,9.36,0,0,1,117,76.6a9.58,9.58,0,0,1,.56-3.28,10.14,10.14,0,0,1,6.23-2.11A10.28,10.28,0,0,1,134,81.46Z"/><line class="dE8" x1="119.28" y1="70.41" x2="119.44" y2="71.78"/><line class="dE8" x1="124.58" y1="70.82" x2="124.83" y2="69.05"/><line class="dE8" x1="129.16" y1="72.5" x2="130.37" y2="71.54"/>';
    bytes constant data9 = '<path class="bE9" d="M142.46,78.31a11.94,11.94,0,0,1-11.93,11.94,10.74,10.74,0,0,1-10.75-10.74,9.67,9.67,0,0,1,9.67-9.67,8.69,8.69,0,0,1,8.7,8.7,7.83,7.83,0,0,1-7.83,7.83,7.05,7.05,0,0,1-7-7.05A6.34,6.34,0,0,1,129.62,73a5.71,5.71,0,0,1,5.71,5.71,5.14,5.14,0,0,1-5.14,5.14,4.63,4.63,0,0,1-4.63-4.63A4.16,4.16,0,0,1,129.72,75a3.75,3.75,0,0,1,3.75,3.75,3.37,3.37,0,0,1-3.37,3.37,3,3,0,0,1-3-3,2.74,2.74,0,0,1,2.74-2.73,2.46,2.46,0,0,1,2.45,2.46"/>';

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