/**
 *Submitted for verification at polygonscan.com on 2022-11-16
*/

// SPDX-License-Identifier: MIT
// File: Base64.sol


pragma solidity ^0.8.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}
// File: token.sol


pragma solidity >=0.8.0 <0.9.0;


contract token {
 
 event image(string  img);
    function buildImage(string[5] calldata _data) public  returns (string memory) {
        string memory result =  Base64.encode(
                bytes(
                    abi.encodePacked(
                        '<svg id="NFTSVG" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 447 394.62">',
                        '<style>',
                        "#NFTSVG { filter: drop-shadow(0px 8px 6px rgba(0, 0, 0, 0.4)); transform:scale(0.925); caret-color: transparent; } #bg { fill: url(#grad); } #circuit { fill: none; stroke-miterlimit: 10; stroke-width: 2.2px; stroke: url(#grad2); } #glyph { fill: url(#grad3); } #animaltxt1, #elem1 { font-size: 15.45px; } #amount1, #period1 { font-size: 12.93px; } text, #r1, #r2 {font-family: Trebuchet MS, sans-serif;font-size: 8px;line-height: 1;visibility: visible;font-weight: 500;letter-spacing: 2px;fill: url(#grad3);} #enddate, #endtime, #period2, #elem2 { fill: #cb2f3a; } #id, #chain, #animaltxt2, #amount2{ fill: #ff9d32; } #title, #everrise, #version1, #version2{ fill: #e25637; }",
                        '</style>',
                        '<linearGradient id="grad" x1="150.61" y1="148.95" x2="457.27" y2="455.61" gradientTransform="matrix(1, 0, 0, -1, -25.57, 1873.39)" gradientUnits="userSpaceOnUse">',
                        '<stop offset="0.2" stop-color="#080d29" />',
                        '<stop offset="1" stop-color="#0a1b51" />',
                        '</linearGradient>',
                        '<linearGradient id="grad2" x1="0%" y1="0%" x2="100%" y2="0" gradientTransform="rotate(-25 .5 .5)">',
                        '<stop offset="0.2" stop-color="#cb1c3b" />',
                        '<stop offset="0.7" stop-color="#ff9d32" />',
                        '</linearGradient>',
                        '<linearGradient id="grad3" x1="0%" y1="0%" x2="100%" y2="0">',
                        '<stop offset="0.2" stop-color="#ca1b3b" />',
                        '<stop offset="1" stop-color="#ff9d32" />',
                        '</linearGradient>',
                        '<path id="bg" data-name="bg" d="M156.37,1754.42,58.62,1585.11a28,28,0,0,1,0-28l97.75-169.31a28,28,0,0,1,24.25-14h195.5a28,28,0,0,1,24.25,14l97.75,169.31a28,28,0,0,1,0,28l-97.75,169.31a28,28,0,0,1-24.25,14H180.62A28,28,0,0,1,156.37,1754.42Z" transform="translate(-54.87 -1373.5)" />',
                        '<path id="circuit" d="M393.34,1407.24a5.5,5.5,0,1,1-5.5-5.49A5.5,5.5,0,0,1,393.34,1407.24Zm-199.45-16.49a5.5,5.5,0,1,0,5.5,5.5,5.5,5.5,0,0,0-5.5-5.5Zm-110,162a5.5,5.5,0,1,0,5.5,5.5,5.5,5.5,0,0,0-5.5-5.5Zm87,173a5.5,5.5,0,1,0,5.5,5.5,5.51,5.51,0,0,0-5.5-5.5Zm196,15a5.5,5.5,0,1,0,5.5,5.5,5.5,5.5,0,0,0-5.5-5.5Zm106-162a5.5,5.5,0,1,0,5.49,5.49,5.49,5.49,0,0,0-5.49-5.49Zm-389.42,4,93.29-162h73.67l13-13H172.89m-86.48,145,76-132H176.7m-4.81-13H359.35l44,77,18,5,39,66-37,64,5,18-48,83-72.73,0-13.25,13h-93l-36-63-19-6-47.91-82,44.91-78-5-17.58m60.44-91.39H352.35l9.11,15.64m5.59-16,54.29,94.31m46,54-76.62-132m73.91,127.32,2.71,4.65-11,19M167.47,1726.28,91.41,1594.7l7.08-12m47.88,81.94,46,80M427.56,1639l46.27-79.82m-3,29.27-75.36,132.19H377.54m-84.67,13H389m-27.14,12H208.38L199,1729.4" transform="translate(-54.87 -1373.8)" />',
                        '<path id="r2" d="M372.47,1724.6a3.55,3.55,0,0,1,2.56-1.27,3.76,3.76,0,0,1,3.2,2.23,3.47,3.47,0,0,1,.21,1.91,3.41,3.41,0,0,1-1,1.89,3.46,3.46,0,0,1-1.35.81c-.29-1.44-.59-2.88-.88-4.32.64.49,1.27,1,1.9,1.49l.16-.17-2.21-2.81-2.21,2.81.16.17,1.91-1.49c-.3,1.43-.59,2.87-.89,4.31a3.2,3.2,0,0,1-1.12-.6,3.43,3.43,0,0,1-1.23-2,3.53,3.53,0,0,1-.05-.92A3.42,3.42,0,0,1,372.47,1724.6Z" transform="translate(-54.87 -1373.8)" />',
                        '<path id="r1" d="M271.59,1713.21a8.18,8.18,0,0,1,10.68-1.31,8.13,8.13,0,0,1,3.41,8.09,8,8,0,0,1-2.39,4.48,8.23,8.23,0,0,1-3.19,1.9q-1-5.1-2.08-10.21c1.5,1.16,3,2.35,4.49,3.52l.38-.38c-1.74-2.21-3.48-4.43-5.23-6.64l-5.22,6.64.39.38,4.5-3.52c-.69,3.4-1.4,6.8-2.09,10.19a7.84,7.84,0,0,1-2.66-1.41,8.16,8.16,0,0,1-2.89-4.73,8.74,8.74,0,0,1-.13-2.17A8.1,8.1,0,0,1,271.59,1713.21Z" transform="translate(-54.87 -1373.8)" />',
                        '<path id="glyph" d="M1225.8,219.8c5.1-.6,8.2-4,9.5-8.8,1-3.7,4.7-41.1,6.8-46.7,2.8-12.2,16-17.7,22.5-5.3,6.5,10.9,16.7,48.3,18.1,51.8,1.7,4.6,4.6,5.8,10.1,4.9,6-1.0,45.6-6.2,50.2-5.3a11.8,11.8,0,0,1,6.8,19.2c-2.4,3.1-38.4,30.4-40.7,32.8-3.9,4-4.4,8.5-2,13.5,6.2,12.8,20,39.0,23.3,52.7,1.3,4.8-4.5,14.8-16.4,7.7-7.7-4.8-42-34.3-44.1-35.7-2.8-1.9-5.7-1.8-8.2.5-3.1,2.8-33.1,36.7-43,39.6-7.6,2.3-14.5-2.7-14.5-10.7-.0-7.1,14.1-51.7,14.4-54.3a10.4,10.4,0,0,0-4.8-10.1c-4.2-2.9-37.9-17.1-49.2-29.2-5.1-11.2,3.8-17.6,10.4-17.7C1179.6,218.6,1222.1,220.3,1225.8,219.8Zm57.4,49.8a5.5,5.5,0,0,0-5.4-5.5,5.6,5.6,0,0,0-5.6,5.4,5.8,5.8,0,0,0,5.7,5.5A5.6,5.6,0,0,0,1283.2,269.6Zm-38.3-5.5a5.5,5.5,0,0,0-5.4,5.4,5.5,5.5,0,0,0,5.5,5.5,5.7,5.7,0,0,0,5.4-5.5A5.6,5.6,0,0,0,1244.9,264.1ZM1287,241.3a5.4,5.4,0,0,0-5.4-5.5,5.4,5.4,0,0,0-.1,10.9,5.4,5.4,0,0,0,5.6-5.3Zm-48,8.5a5.6,5.6,0,0,0,5.6-5.4,5.5,5.5,0,0,0-11.0-.0A5.6,5.6,0,0,0,1239.0,249.8Zm24-24.7a5.4,5.4,0,1,0-5.4,5.4,5.3,5.3,0,0,0,5.4-5.4Zm23.7,60.2a4.1,4.1,0,0,0-.0-8.1,4.1,4.1,0,1,0,.0,8.1Zm4.6-49a4.2,4.2,0,0,0,4.0,4.0,4.2,4.2,0,0,0,4.1-4.2,4.1,4.1,0,0,0-8.2.1Zm-62.8,4.9a4.0,4.0,0,1,0-8.1.0,4.0,4.0,0,0,0,8.1-.0Zm10.2,45.8a4.0,4.0,0,0,0,4-4,4.2,4.2,0,0,0-4.0-4.1,4.1,4.1,0,0,0-4.0,4.1,4,4,0,0,0,4.0,4Zm18.1-72.8a4,4,0,0,0,4-4.0v0a4.0,4.0,0,0,0-8.1.1v.0a4,4,0,0,0,4.1,3.9Zm-41.5,24.1a3.6,3.6,0,1,0-7.2.1,3.7,3.7,0,0,0,3.7,3.5A3.7,3.7,0,0,0,1215.5,238.5Zm75.5,53.1a3.6,3.6,0,0,0,3.6,3.5,3.8,3.8,0,0,0,3.5-3.6,3.6,3.6,0,0,0-3.7-3.5A3.6,3.6,0,0,0,1291.1,291.7Zm20.4-59.5a3.6,3.6,0,1,0-3.5,3.6,3.7,3.7,0,0,0,3.5-3.6ZM1237.1,295a3.7,3.7,0,0,0-3.6-3.6,3.5,3.5,0,1,0-.1,7.1A3.7,3.7,0,0,0,1237.1,295Zm19.3-94.1a3.5,3.5,0,0,0-.0-7,3.4,3.4,0,0,0-3.4,3.4v0A3.4,3.4,0,0,0,1256.4,200.9Zm-28.3,102.6a3.1,3.1,0,1,0,3.1,3.2A3.3,3.3,0,0,0,1228.1,303.5Zm92.1-78.4a3.1,3.1,0,1,0-.1,6.2h.1a3.0,3.0,0,0,0,3.0-3,3.1,3.1,0,0,0-3.0-3.1Zm-17.7,80a3.1,3.1,0,1,0-3.2-3.1,3.2,3.2,0,0,0,3.2,3.1Zm-100.0-69.2a3.1,3.1,0,1,0-6.2,0,3.1,3.1,0,0,0,3.0,3.1h0A3.1,3.1,0,0,0,1202.4,235.7Zm56.6-51.3a3.0,3.0,0,1,0-6.1,0,3.0,3.0,0,0,0,6.1,0Zm-.8-12a2.5,2.5,0,0,0-2.6-2.6,2.7,2.7,0,0,0-2.6,2.7,3.0,3.0,0,0,0,2.6,2.9,3,3,0,0,0,2.5-3Zm51.3,136a2.7,2.7,0,0,0-.1,5.4,2.7,2.7,0,0,0,.1-5.4Zm-86.7,11.1a2.7,2.7,0,0,0,2.7-2.6,2.7,2.7,0,0,0-5.4,0,2.7,2.7,0,0,0,2.7,2.6Zm-32.1-86.8a2.5,2.5,0,0,0-2.7-2.5,2.6,2.6,0,0,0-2.6,2.6V233a2.6,2.6,0,0,0,5.3-.0v0Zm143.4-8.4a2.6,2.6,0,0,0-2.7-2.6,2.6,2.6,0,0,0-2.6,2.5v.1a2.6,2.6,0,0,0,2.6,2.6h0a2.6,2.6,0,0,0,2.6-2.6Zm-156,8.2a2.2,2.2,0,0,0,2.2-2,2.2,2.2,0,0,0-2.1-2.1,2.1,2.1,0,1,0-.0,4.1Zm165.2-10.8a2.1,2.1,0,1,0-4.3,0,2.1,2.1,0,0,0,4.3,0Zm-30.0,97.8a2.1,2.1,0,1,0,4.1-.0,2.1,2.1,0,1,0-4.1.0Zm-96.8,6.6a2.2,2.2,0,0,0,2.0,2.2,2.3,2.3,0,0,0,2.1-2.1,2.2,2.2,0,0,0-2.1-2.1A2.1,2.1,0,0,0,1216.4,326.3ZM1257,162.7a2,2,0,0,0-1.8-2.1H1255a2.0,2.0,0,0,0-.1,4.1h0a2,2,0,0,0,2.1-1.8s0-.0,0-.1Z" transform="translate(-1034.8 -49.8)" />',
                        '<text id="enddate" transform="translate(77.5 118) rotate(-60)" text-anchor="middle">',
                        _data[0],
                        '</text>',
                        '<text id="endtime" transform="translate(63 168.8) rotate(-60)" text-anchor="middle">',
                        _data[1],
                        '</text>',
                        '<text id="amount1" transform="translate(221.26 313.47)" text-anchor="middle">',
                         _data[2]," POLLYA",
                        '</text>',
                        '<text id="amount2" transform="translate(375.1 280) rotate(-60)" text-anchor="middle">',
                        _data[3]," POLLYA",
                        '</text>',
                        '<text id="animaltxt2" transform="translate(395.4 219) rotate(-60)" text-anchor="middle">',
                        "STARFISH",
                        '</text>',
                        '<text id="animaltxt1" transform="translate(220.96 88.5)" text-anchor="middle">',
                        "STARFISH",
                        '</text>',
                        '<text id="id" transform="translate(326.85 66.78) rotate(60)" text-anchor="middle">',
                         _data[4],
                        '</text>',
                        '<text id="chain" transform="translate(366 108.4) rotate(60)" text-anchor="middle">',
                        "POLYGON",
                        '</text>',
                        '<text id="everrise" transform="translate(223 368.8)" text-anchor="middle">',
                        "POLLYA",
                        '</text>',
                        '<text id="version2" transform="translate(288.94 356.5)" text-anchor="middle">',
                        "GENESIS",
                        '</text>',
                        '<text id="version1" transform="translate(153.33 43.5)" text-anchor="middle">',
                        "GENESIS",
                        '</text>',
                        '<text id="title" transform="translate(220.65 31)" text-anchor="middle">',
                        "POLLYA STAKE",
                        '</text>',
                        '<text id="elem1" transform="translate(220.96 72)" text-anchor="middle">',
                        "POLLYA",
                        '</text>',
                        '<text id="elem2" transform="translate(119.4 332) rotate(60)" text-anchor="middle">',
                        "lets Poll,"
                        '</text>',
                        '<text id="period1" transform="translate(221.26 329.68)" text-anchor="middle">',
                        "36 MONTHS",
                        '</text>',
                        '<text id="period2" transform="translate(77 285) rotate(60)" text-anchor="middle">',
                        "36 MONTHS",
                        '</text>',
                        '</svg>'
                    )
                )
            );
            emit image(result);
            return result;
    }
}