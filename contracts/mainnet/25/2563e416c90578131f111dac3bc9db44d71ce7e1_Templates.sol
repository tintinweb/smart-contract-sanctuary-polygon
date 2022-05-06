/**
 *Submitted for verification at polygonscan.com on 2022-05-06
*/

// SPDX-License-Identifier: MIT
// File: contracts/library/Templates.sol


pragma solidity ^0.8.1;

library Templates {
    function buildRawSVG(string memory trends) public pure returns(bytes memory) {
        return bytes(
                    abi.encodePacked(
                        '<svg width="500" height="500" version="1.1" xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape" xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns="http://www.w3.org/2000/svg" xmlns:svg="http://www.w3.org/2000/svg">',
                        '<sodipodi:namedview id="namedview7" pagecolor="#ffffff" bordercolor="#666666" borderopacity="1.0" inkscape:pageshadow="2" inkscape:pageopacity="0.0" inkscape:pagecheckerboard="true" inkscape:document-units="px" showgrid="false" inkscape:zoom="0.72032148" inkscape:cx="261.68871" inkscape:cy="277.6538" inkscape:window-width="1440" inkscape:window-height="794" inkscape:window-x="0" inkscape:window-y="25" inkscape:window-maximized="0" inkscape:current-layer="layer1" borderlayer="true" />',
                        '<defs id="defs2" />',
                        '<g inkscape:label="Layer 1" inkscape:groupmode="layer" id="layer1">',
                            '<rect style="fill:#1d9bf0;fill-opacity:1" id="rect2063" width="500" height="500" x="0" y="0" />',
                            '<g id="Logo_1_" transform="matrix(3.1017211,0,0,3.1017211,-282.12967,91.100636)" style="fill:#ffffff">',
                            '<path id="white_background" class="st0" d="m 221.95,51.29 c 0.15,2.17 0.15,4.34 0.15,6.53 0,66.73 -50.8,143.69 -143.69,143.69 v -0.04 C 50.97,201.51 24.1,193.65 1,178.83 c 3.99,0.48 8,0.72 12.02,0.73 22.74,0.02 44.83,-7.61 62.72,-21.66 -21.61,-0.41 -40.56,-14.5 -47.18,-35.07 7.57,1.46 15.37,1.16 22.8,-0.87 C 27.8,117.2 10.85,96.5 10.85,72.46 c 0,-0.22 0,-0.43 0,-0.64 7.02,3.91 14.88,6.08 22.92,6.32 C 11.58,63.31 4.74,33.79 18.14,10.71 c 25.64,31.55 63.47,50.73 104.08,52.76 -4.07,-17.54 1.49,-35.92 14.61,-48.25 20.34,-19.12 52.33,-18.14 71.45,2.19 11.31,-2.23 22.15,-6.38 32.07,-12.26 -3.77,11.69 -11.66,21.62 -22.2,27.93 10.01,-1.18 19.79,-3.86 29,-7.95 -6.78,10.16 -15.32,19.01 -25.2,26.16 z" style="fill:#ffffff" />',
                            '</g>',
                            '<path style="color:#000000;fill:none;fill-rule:evenodd;-inkscape-stroke:none" d="m 92.511292,273.50825 c 12.143138,51.03334 48.520808,94.45236 97.058588,114.59961 79.02716,32.80291 173.86024,-3.91578 206.78125,-83.7539 30.64123,-74.3093 -3.95336,-163.40073 -79.08008,-194.14649 -69.59105,-28.480282 -152.94234,3.98851 -181.51171,74.4043 -26.32027,64.87235 4.02501,142.48537 69.73046,168.87695 60.1531,24.1614 132.03015,-4.06079 156.24219,-65.05664 22.00395,-55.43315 -4.09566,-121.57521 -60.38281,-143.60547 -50.71232,-19.84832 -111.12513,4.12935 -130.9707,55.70899 -17.69507,45.99035 4.16347,100.67893 51.03711,118.33593 41.26689,15.54498 90.23615,-4.1975 105.69921,-46.36718 13.39925,-36.54141 -4.22675,-79.79911 -41.69531,-93.06055 -31.81303,-11.25976 -69.3775,4.25589 -80.42578,37.02734 -9.12964,27.08038 4.28295,58.97053 32.36328,67.78711 22.3409,7.01453 48.59408,-4.30656 55.14649,-27.70508 4.92563,-17.58933 -4.32504,-38.28037 -23.05664,-42.5039 -6.40608,-1.44442 -13.40942,-0.3633 -19.05274,2.83789 -5.64332,3.20119 -9.93225,8.5549 -10.80078,15.59766 -0.49109,3.98212 0.61755,8.54041 3.02148,11.99804 2.40394,3.45763 6.17898,5.81469 10.875,5.17188 1.90481,-0.26074 4.21542,-1.8784 5.53321,-3.81446 0.65889,-0.96803 1.07084,-2.04489 0.91406,-3.11132 -0.15678,-1.06644 -0.92414,-2.03431 -2.32813,-2.67969 l -0.41796,0.9082 c 1.19985,0.55155 1.65345,1.20615 1.75781,1.91602 0.10436,0.70986 -0.18035,1.56255 -0.75195,2.40234 -1.14322,1.67958 -3.4274,3.19284 -4.84375,3.38672 -4.30412,0.58917 -7.6688,-1.51692 -9.91797,-4.75195 -2.24917,-3.23503 -3.30655,-7.5995 -2.84961,-11.30469 0.82726,-6.70806 4.8849,-11.77437 10.30273,-14.84766 5.41784,-3.07328 12.18989,-4.1206 18.33789,-2.73437 18.11563,4.08465 27.0975,24.17961 22.31446,41.25976 -6.38774,22.81046 -32.05092,33.87487 -53.88477,27.01953 -27.50909,-8.63722 -40.67382,-39.93952 -31.71484,-66.51367 10.85945,-32.21137 47.83737,-47.485 79.14453,-36.40429 36.9164,13.06601 54.30365,55.7397 41.08984,91.77539 -15.26276,41.62343 -63.64695,61.12794 -104.4082,45.77343 -46.33196,-17.45295 -67.95561,-71.55433 -50.45508,-117.03906 19.63856,-51.04159 79.46518,-74.78715 129.67187,-55.13672 55.75208,21.82084 81.62161,87.37717 59.81836,142.30469 -24.00062,60.46323 -95.292,88.45634 -154.93945,64.49805 C 140.68794,326.38251 110.57196,249.35541 136.68707,184.98872 165.0419,115.1017 247.80678,82.859928 316.89215,111.13325 391.49163,141.66324 425.86,230.16951 395.4273,303.9731 362.72315,383.28532 268.47413,419.77897 189.95269,387.18599 141.72144,367.16596 105.55252,323.99582 93.483952,273.27583 Z" id="path32" />',
                            '<text xml:space="preserve" style="font-style:normal;font-variant:normal;font-weight:normal;font-stretch:normal;font-size:26.6667px;line-height:1.25;font-family:sans-serif;-inkscape-font-specification:sans-serif;fill:#000000;fill-opacity:1;stroke:none" id="text102" transform="rotate(-7.1,356.03326,385.75525)"><textPath xlink:href="#path32" id="textPath1848"><tspan id="tspan100" style="font-style:normal;font-variant:normal;font-weight:normal;font-stretch:normal;font-size:26.6667px;font-family:sans-serif;-inkscape-font-specification:sans-serif">',
                            trends,
                            '</tspan></textPath></text>',
                        '</g>',
                        '</svg>'
                    )
                );
    }

    function buildRawMetadata(
        string memory name, 
        string memory description,
        string memory image,
        string memory trends
    ) public pure returns(bytes memory) {
        return bytes(
                        abi.encodePacked(
                            '{"name":"',
                            name,
                            '", "description":"',
                            description,
                            '", "image": "',
                            "data:image/svg+xml;base64,",
                            image,
                            '", "attributes": ',
                            "[",
                            '{"trait_type": "Trends",',
                            '"value":"',
                            trends,
                            '"}',
                            "]",
                            "}"
                        )
                    );
    }
}