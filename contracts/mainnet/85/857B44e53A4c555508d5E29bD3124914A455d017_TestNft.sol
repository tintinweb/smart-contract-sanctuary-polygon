// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

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
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2022 xxxxxx xxxxxxxxxxxx xxx. All Rights Reserved
pragma solidity 0.8.x;

import {Base64} from "./Base64.sol";
import {Strings} from "openzeppelin-contracts/utils/Strings.sol";

contract MetadataGenerator {

    string _svg;

    function setSvg(string memory svg_) public {
        _svg = svg_;
    }

    /**
     * 
     */
    function generateImage(uint256 tokenId) internal returns (string memory) {
        // string memory svg = string(abi.encodePacked(
        //     '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 1125 1125">' 
        //         '<defs>'
        //             '<style>'
        //                 '<!--color theme-->'
        //                 '.colorCore {'
        //                     'fill: #ff00cd;'
        //                 '}'
        //                 '.colorAccent00 {'
        //                     'fill: #0091ff;'
        //                 '}'
        //                 '.colorAccent01 {'
        //                     'fill: #ff89de;'
        //                 '}'
        //                 '.colorAccent02 {'
        //                     'fill: #ff4300;'
        //                 '}'
        //             '</style>'
        //         '</defs>'
        //     '<rect width="100%" height="100%" fill="black"/>'
        //     '<!--planet top right-->'
        //     '<path class="colorAccent00" d="m1126.4,247.8c-28.7-45.1-75-77.9-130.9-87-106.3-17.4-207.1,57.7-225.1,167.7s53.6,213.3,160,230.7c78.9,12.9,154.8-25.2,196-90.6v-220.8Z"/>'
        //     '<path class="colorCore" d="m1125,458.2c-24.5,44.2-67.5,77.8-121,88.4-96.2,19-189.7-43.6-208.7-139.8-19-96.3,43.6-189.7,139.8-208.7,77.6-15.3,153.5,22.5,189.9,88.2V0h-179c-1.2,1.5-2.3,3.1-3.3,4.7-10.1,17-5.1,41.2,11.5,68.2,8.3,13.5.6,30.8-14.9,33.8-.1,0-.2.1-.4.1-135,26.7-220.8,162.1-184.2,297.2,30.7,113.9,142.8,189,260,174.2,41.6-5.3,79-20.7,110.3-43.3v-76.7Z"/>'
        //     '<path class="colorAccent00" d="m1125,15.9c-3-2.1-6.2-4.1-9.4-6-6.3-3.8-12.8-7.1-19.2-9.9h-97.5c-5.2,3.8-9.5,8.4-12.8,13.9-19.7,33.1,6.2,85,58,115.9,27.4,16.4,56.6,23.6,80.9,21.8V15.9h0Z"/>'
        //     '<path d="m1125,32.9c-5.1-4.2-10.7-8.2-16.8-11.8-42.5-25.3-90.6-22.9-107.5,5.4-16.9,28.3,3.9,71.8,46.4,97.2,26.8,16,55.9,20.9,77.9,15.3V32.9Z"/>'
        //     '<path class="colorAccent02" d="m1125,72.8c-7.7-9.8-18.3-19.1-31.1-26.7-35.1-20.9-73.4-21.2-85.7-.7-12.2,20.5,6.2,54.1,41.3,75,28.1,16.7,58.2,20.2,75.4,10.5l.1-58.1h0Z"/>'
        //     '<ellipse cx="1067.32" cy="93.07" rx="30.6" ry="58.2" transform="translate(440.72 962.1) rotate(-59.19)"/>'
        //     '<path class="colorCore" d="m873.7,21.7c-54.3,31.1-157.1,109.3-166.9,259.1-.8,12.6,17.3,15.4,20.2,3,16.4-70.3,59.3-150.6,165.5-190.1,19.2-7.1,30-27.6,24.9-47.5l-1.7-6.7c-4.8-18.3-25.6-27.2-42-17.8h0Z"/>'
        //     '<ellipse cx="83.73%" cy="33.14%" rx="129" ry="154" transform="translate(-54.43 189.73) rotate(-11.18)"/>'
        //     '<ellipse class="colorAccent02" cx="917.98" cy="377.69" rx="88.1" ry="124.4" transform="translate(-55.81 185.17) rotate(-11.18)"/>'
        //     '<ellipse cx="903.68" cy="381.59" rx="66.5" ry="109" transform="translate(-56.84 182.47) rotate(-11.18)"/>'
        //     '<!--curved text-->'
        //     '<path transform="translate(-15,-40)" id="curve" fill="transparent" d="M625.6,103.9c-45.4,97.4-50.2,212.3-3.9,324.8,80,194.3,288.1,321.2,503.4,323.5"/>'
        //     '<text width="1000" font-family="monospace" font-size="1.75em" fill="white">'
        //     '<textPath xlink:href="#curve" fill="white">'
        //     'admin: 0x18181a21BB74A9De56d1Fbd408c4FeC175Ca0b16'
        //     '</textPath>'
        //     '</text>'
        //     '<!--0x00000000000000000000000000000000DeaDBeef-->'
        //     '<path id="xurve" transform="translate(-13,-20)" fill="transparent" d="M701,53.3c-61,88-72.5,242.4-30.6,344,72.3,175.5,260.2,290.1,454.7,292.2"/>'
        //     '<text width="1000" font-family="monospace" font-size="1.75em" fill="white">'
        //     '<textPath xlink:href="#xurve" class="colorCore">'
        //     'pool: 0x00000000000000000000000000000000DeaDBeef'
        //     '</textPath>'
        //     '</text>'
        //     '<!--icons bottom right-->'
        //     '<!--curve:border-->'
        //     '<path class="colorCore" d="m177.47,584.01h-41.4v-41.5h41.4v41.5Zm-39.4-2h37.4v-37.5h-37.4v37.5Z" transform="translate(-90,0)"/>'
        //     '<!--curve:interior-->'
        //     '<path class="colorCore" d="m176.37,543.41c0,8.8,0,28.9-20.6,36.4-2.7,1-5.7,1.7-9.2,2.2-2.9.4-6.1.6-9.6.6v.2h39.5l-.1-39.4h0Z" transform="translate(-90,0)"/>'
        //     '<!--...-->'
        //     '<text x="95" y="575" font-family="monospace" font-size="1.75em" fill="white">'
        //     'curve: exp'
        //     '</text>'
        //     '<!--triangle-->'
        //     '<polygon class="colorCore" points="176.47 631.72 137.07 631.72 156.77 592.31 176.47 631.72" transform="translate(-90,5)"/>'
        //     '<text x="95" y="629" font-family="monospace" font-size="1.75em" fill="white">'
        //     'delta: 0.05%'
        //     '</text>'
        //     '<!--fee-->'
        //     '<ellipse class="colorCore" cx="67" cy="656.82" rx="19.75" ry="5.61"/>'
        //     '<path class="colorCore" transform="translate(-90,10)" d="m137.07,650.34v24.77c0,3.1,8.84,5.61,19.75,5.61s19.75-2.51,19.75-5.61v-24.77c-4.09,3.14-13.56,4.09-19.75,4.09s-15.66-.94-19.75-4.09Z"/>'
        //     '<text x="95" y="683" font-family="monospace" font-size="1.75em" fill="white">'
        //     'fee: 0.05%'
        //     '</text>'
        //     '<!--square-->'
        //     '<rect class="colorCore" x="47" y="732.51" width="39.5" height="39.5"/>'
        //     '<text x="95" y="763" font-family="monospace" font-size="1.75em" fill="white">'
        //     'nft_symbol: 10,000'
        //     '</text>'
        //     '<!--circle-->'
        //     '<path class="colorCore" d="m156.77,784.22h0c10.9,0,19.7,8.8,19.7,19.7h0c0,10.9-8.8,19.7-19.7,19.7h0c-10.9,0-19.7-8.8-19.7-19.7h0c0-10.9,8.8-19.7,19.7-19.7Z" transform="translate(-90,0)"/>'
        //     '<text x="95" y="816" font-family="monospace" font-size="1.75em" fill="white">'
        //     'token_symbol_: 1,000,000'
        //     '</text>'
        //     '<!--top left-->'
        //     '<image width="100%" height="100%" xlink:href="data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHN2ZyBpZD0iTGF5ZXJfMSIgZGF0YS1uYW1lPSJMYXllciAxIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxMTI1IDExMjUiPgogIDxkZWZzPgogICAgPHN0eWxlPgogICAgICAuY2xzLTEgewogICAgICAgIGZpbGw6ICMwMDNkZmY7CiAgICAgIH0KCiAgICAgIC5jbHMtMiB7CiAgICAgICAgZmlsbDogIzAwOTFmZjsKICAgICAgfQoKICAgICAgLmNscy0zIHsKICAgICAgICBmaWxsOiAjZmY0MzAwOwogICAgICB9CiAgICA8L3N0eWxlPgogIDwvZGVmcz4KICA8cGF0aCBkPSJtNTYwLjgyLjY4aC03NS45NGMtNTUuOTUsMzQuMTUtNzYuMDcsMTAxLjY3LTg5LjgzLDEyMy4xOC0xMC4zMiwxNi4xMi0yNi42MiwzMC43OS00NS43MywyOS43My0yMC44NS0xLjE2LTQ2Ljc1LTI0LjUyLTY2LjcxLDIyLjIxLTYuMDksMTQuMjYtMjIuMSwzNi41Mi0zNy4xNCwzMi43OS0yNi44Mi02LjY1LTM2Ljg3LTgwLjkzLTQ3Ljc2LTEwOS40My0xMC43NS0yOC4xNC0zMi4yNS01Ny40OS02Mi4zNy01Ny41My0xNy4yNS0uMDItMzguNjcsMzkuMTYtNTUuNjIsMzUuOTctMTUuMzMtMi44OC0yNi45OS0xNi4yNi0zMi4yNy0zMC45My01LjI2LTE0LjYtNS4zNC0zMC40Ny01LjM0LTQ2SC44MnYzNDQuODFoN2MyNC45NS04My4zNCw1MS4wOC03NC45Miw5Mi4yNS04OC44Myw3LjkyLTIuNjgsMTYuMzUtNC41MywyMy4xLTkuNDcsMTAuNjktNy44MywxNC45Ny0yMS43MiwyMy45OS0zMS40MywxMS42Ny0xMi41NywzMS41OC0xNi42Myw0Ny4yNC05LjY0LDE2LjU5LDcuNCwyOC42MiwyMC42Myw0Ni43NiwyMS41MSwzMC4xNiwxLjQ2LDQzLjQ4LTM5LjUsNzMuNDUtNDMuMiwyMi4yMi0yLjc0LDM4Ljk0LDE4Ljg0LDUxLjIxLDM3LjU2LDEyLjI3LDE4LjcyLDQ3LjY5LDQzLjU3LDY5LjU4LDM4LjkxLDE4LjQtMy45Miw1NC45MS00MS42NCw5MS4zNiw3LjMyLDEwLjAxLDEzLjQ0LDE4LjczLDUyLjMzLDM0LjA5LDcwLjQ3bC0uMDMtMzM4LjAxWiIvPgogIDxwYXRoIGNsYXNzPSJjbHMtMiIgZD0ibTE5Ny4yNSwxNjguNzNjLTguOTYtMjAuNDUtMTMuMDMtNDIuNjUtMTkuOTgtNjMuODYtMy4yMy05Ljg1LTcuMjUtMTkuNzYtMTQuMzUtMjcuMzEtNy4xLTcuNTYtMTcuOS0xMi4zOC0yNy45Ny05LjkxLTEzLjY2LDMuMzUtMjAuODYsMTcuNzMtMjguNywyOS40MS00Ljk2LDcuMzgtMTAuOTEsMTQuMjctMTguNDUsMTguOTktNy41NCw0LjcxLTE2LjgzLDcuMDgtMjUuNDksNS4wNi04LjI1LTEuOTItMTUuMjQtNy42MS0yMC4zMi0xNC4zOXMtOC40Ny0xNC42NS0xMS43Mi0yMi40OEMyMS42OSw2My42LDYuNiwzMy4zLS43NSwxMi4ydjc0LjQ5YzIuNDguNDIsNS4wMiwxLjg1LDcuMDMsMy40NCw4LjY3LDYuODgsMTUuNywyNi40NiwyMy4wMiwzNC43NSw4LjA5LDkuMTYsMjIuODgsMTkuODIsMzMuNzMsMjUuNDYsMTIuODEsNi42NywzNC4zLS43Myw1Ni4xNC0zOC45NSw3LjM1LTEyLjg2LDE3Ljc5LTIxLjQ1LDIzLjYzLTIwLjU3LDguNzEsMS4zMiwxMC4wMi0xLDE4Ljc4LDM0LjkxLDUuNzYsMjMuNjEsNDYuNzIsODEuODgsNzkuMDUsODkuOTYuMzQtLjAxLjY4LS4wMSwxLjAyLS4wNC0yMC40LTcuMjUtMzUuNDUtMjYuNDgtNDQuNC00Ni45M1oiLz4KICA8cGF0aCBjbGFzcz0iY2xzLTIiIGQ9Im01NjAuODUsNjkuNDVjLTEwLTEuNDQtMjAuMTEtMS44Ni0zMC4xOC0uOTMtMjMuNzMsMi4xOC00Ny4yNSwxMi4zNC02Mi42OSwzMC40OS0yMC42MiwyNC4yNC0xNy43NCw5MS4xLTQ4LjEsMTAyLjAxLTEzLjYyLDQuODktMzguNTQtNy44LTU3Ljk3LTIwLjkyLTE0LjcyLTkuOTQtMzAuOTgtMjAuMjUtNDguMzMtMTYuNS0xNi4xNiwzLjQ5LTM2LjcsNDguMDQtNjcuMDcsNTMuNTQsMjIuNzQtMi44OSw0NS40Ni0zMi41NCw1MS41OS0zNy45Miw1LjAzLTQuNDIsOC42NS04LjA5LDE0Ljk5LTEwLjI0LDExLTMuNzIsMjQuMywyLjIxLDM0LjQsNy45NCwxNC4zMiw4LjEzLDI2LjY4LDE5LjM0LDQwLjgyLDI3Ljc3czMxLjc2LDE5LjA1LDQ3LjU2LDE0LjQxYzI1LjM0LTcuNDMsNTEuMjktNzIuNzcsODcuNzctNjcuNTcsMjUuNDksMy42MywyOS42MSwyNi42LDM3LjIxLDU0LjA2VjY5LjQ1WiIvPgogIDxwYXRoIGNsYXNzPSJjbHMtMSIgZD0ibTUyMy42NCwxNTEuNTVjLTM2LjQ4LTUuMi02Mi40Myw2MC4xNC04Ny43Nyw2Ny41Ny0xNS44LDQuNjMtMzMuNDItNS45OC00Ny41Ni0xNC40MS0xNC4xNC04LjQzLTI2LjUtMTkuNjQtNDAuODItMjcuNzctMTAuMS01LjczLTIzLjQtMTEuNjYtMzQuNC03Ljk0LTYuMzQsMi4xNC05Ljk2LDUuODItMTQuOTksMTAuMjQtNS43LDUuMDEtMjUuNzMsMzAuOTctNDYuOCwzNi45MiwyNS4xOS02LjYsMzYuMzQtMzEuODksNTguMzUtMzksMTYuOTgtNS40OCwzNS42MiwxLjc2LDUwLjA3LDEyLjIyLDE0LjQ1LDEwLjQ1LDI2LjQ0LDI0LjA5LDQxLjI2LDM0LjAyLDkuMiw2LjE2LDIwLjE2LDEwLjk0LDMxLjEsOS4yMiwxMi43OS0yLDIyLjQ1LTEyLjE3LDMzLjI1LTE5LjI5LDEzLjYtOC45NiwzMC43LTEzLjQsNDYuNTMtOS41NiwxOS45NCw0Ljg0LDMzLjg3LDIwLjk2LDQ4Ljk5LDM1LjQ3di0zMy42MWMtNy42LTI3LjQ2LTExLjcyLTUwLjQzLTM3LjIxLTU0LjA2WiIvPgogIDxwYXRoIGNsYXNzPSJjbHMtMyIgZD0ibTQzMC4yOSwxMDguOTFjLTYuNjgsMTQuNjQtMTIuMjYsMzAuMTEtMjIuNjcsNDIuMzgtMTAuNDEsMTIuMjctMjUuOTIsMjEuMzYtNDEuOTUsMTkuOTYtMTAuMzYtLjktMTkuODEtNS45Ny0yOS40OS05Ljc5LTkuNjctMy44Mi0yMC43My02LjQyLTMwLjMxLTIuMzctNy4xMywzLjAxLTEyLjM2LDkuMjktMTYuMzcsMTUuOTEtNC4wMSw2LjYyLTcuMDksMTMuOC0xMS41MywyMC4xMy03LjUsMTAuNy0xOC44NSwxOC42My0zMS40NywyMiwzMC4zNy01LjUsNTAuOTEtNTAuMDUsNjcuMDctNTMuNTQsMTcuMzYtMy43NSwzMy42Miw2LjU2LDQ4LjMzLDE2LjUsMTkuNDQsMTMuMTIsNDQuMzYsMjUuODEsNTcuOTcsMjAuOTIsMzAuMzctMTAuOTIsMjcuNDgtNzcuNzcsNDguMS0xMDIuMDEsMTUuNDQtMTguMTUsMzguOTYtMjguMyw2Mi42OS0zMC40OSwxMC4wNy0uOTMsMjAuMTgtLjUxLDMwLjE4LjkzVjI4LjU5Yy0zNy43My0xLjEyLTEwMS40LDE2LjQ0LTEzMC41Niw4MC4zMloiLz4KICA8cGF0aCBjbGFzcz0iY2xzLTMiIGQ9Im00MzUuNCwyNjAuOWMtMjEuODksNC42Ni01Ny4zMS0yMC4xOS02OS41OC0zOC45MS0xMi4yNy0xOC43Mi0yOC45OS00MC4zLTUxLjIxLTM3LjU2LTIxLjQ0LDIuNjUtMzQuMzYsMjQuMzYtNTEuMDEsMzUuOTcsOS40NS02LjAxLDIxLjg5LTE2LjAyLDI5Ljg3LTIyLjAzLDYuNjgtNS4wMywxNC4wOS03LjQ3LDI1LjIzLTcuNDMsMTcuNDQuMDUsMjkuNjgsMTYuNTksMzguOTMsMzEuMzcsMTAuMzQsMTYuNTIsMjAuNjksMzMuMDUsMzEuMDMsNDkuNTcsNS42Miw4Ljk4LDEyLjE5LDE4LjY5LDIyLjQ0LDIxLjQsMTQuNzUsMy45LDI4LjM0LTguMzIsMzkuMzItMTguOTEsMTAuOTktMTAuNTgsMjYuODgtMjEuMTQsNDAuMzEtMTMuOTEsMTAuMDksNS40MywxMy4xMiwxOC4yMiwxNS4xMSwyOS41LDIuMjUsMTIuNzMsNC40OSwyNS40Niw2Ljc0LDM4LjE4LDEuMDEsNS43MiwyLjEsMTIuMzMsMy42MSwxOC4wNmg0NC42NGwuMDMtNy41MWMtMTUuMzYtMTguMTUtMjQuMDgtNTcuMDQtMzQuMDktNzAuNDctMzYuNDUtNDguOTYtNzIuOTYtMTEuMjMtOTEuMzYtNy4zMloiLz4KICA8cGF0aCBjbGFzcz0iY2xzLTMiIGQ9Im0yNDEuMTYsMjI3LjYzYy0xOC4xNC0uODgtMzAuMTctMTQuMTEtNDYuNzYtMjEuNTEtMTUuNjctNi45OS0zNS41Ny0yLjkyLTQ3LjI0LDkuNjQtOS4wMSw5LjcxLTEzLjMsMjMuNi0yMy45OSwzMS40My02Ljc0LDQuOTQtMTUuMTgsNi43OS0yMy4xLDkuNDctNDEuMTcsMTMuOTEtNjYuMDYsMS40My05Mi4yNSw4OC44M2g0OC42OGMzLjQ4LTYuNzUsMi4wMS0xNy4yOCwzLjUtMjcuODksMi4xMS0xNS4xMSwxMC4xNi0yNC4yMywyMS43NS0yNi42MiwxMi4xOS0yLjUyLDI2Ljk4LDE0LjgsNDEuMDksMTEuNiwxNy4wOC0zLjg2LDI0LjE1LTIzLjY0LDMwLjQ1LTM5Ljk4LDQuMjQtMTEuMDEsOS4zOS0yMS42NywxNS4zNy0zMS44MywzLjA5LTUuMjYsNi43Ny0xMC43LDEyLjQ0LTEyLjk2LDExLjk2LTQuNzcsMjEuNDYtMS4zNSwzMy4zMSwzLjY5LDIzLjUyLDEwLDMzLjM2LDcuNTksNDEuOTksMy4wOC00LjY0LDIuMTMtOS42NSwzLjMyLTE1LjI0LDMuMDVaIi8+CiAgPHBhdGggZD0ibTU2MC44NSw5My44MXMtNTkuOTEtMTkuMDYtODQuMTUsMzcuNTEtMzIuMjEsNzYuNDItNjMuNTksNzguNzFjMCwwLDI5LjUzLDEyLjI2LDU1LjQtMzcuNDksMjMuNjMtNDUuNDYsNTguNjktNjYuMyw5Mi4zNS0zNS45NXYtNDIuNzhaIi8+CiAgPHBhdGggZD0ibTE3MS43MywxMjUuOTdjLTcuNTMtMzIuMTEtMjIuMTQtMzguMjctMjkuNjktMzguMTgtMTAuNjYuMTItMTUuNTIsMTAuNzUtMjIuODYsMjMuNjEtMjEuODQsMzguMjItNDIuMDcsNDMuMjUtNTUuNjIsMzguMjUtMjguOTctMTAuNjktNDkuMDQtNTQuODctNTcuMjgtNTkuNTEtMi4yNC0xLjI2LTQuNTUtMy4wMi03LjAzLTMuNDR2MTI2Ljg1YzE0LjAzLTYuNDQsMjMuNzEtMjIuMjUsMzkuMDktMjQuMDEsMTMuMDUtMS41LDI0LjcxLDcuOTIsMzMuNDcsMTcuNzEsNC4yOCw0Ljc4LDkuNjIsMTAuMzIsMTUuOTMsOS4xMiw1LjMtMSw4LjQ4LTYuNCwxMC40Ny0xMS40MiwzLjc4LTkuNTQsNS44LTE5LjcyLDkuODYtMjkuMTQsMTEuMjUtMjYuMSwzOS4xLTMxLjczLDUyLjc3LTE4LjA2LDE5LjU2LDE5LjU2LDYwLjQ2LDU2Ljk3LDc5LjgxLDU3Ljk1LTMyLjMzLTguMDctNjEuOTktNjAuMTgtNjguOTItODkuNzNaIi8+CiAgPHBhdGggY2xhc3M9ImNscy0xIiBkPSJtMTYwLjg0LDE1Ny43NWMtMTMuNjctMTMuNjctNDEuNTItOC4wNC01Mi43NywxOC4wNi00LjA2LDkuNDItNi4wOSwxOS42LTkuODYsMjkuMTQtMS45OSw1LjAyLTUuMTYsMTAuNDEtMTAuNDcsMTEuNDItNi4zMSwxLjE5LTExLjY1LTQuMzQtMTUuOTMtOS4xMi04Ljc2LTkuNzktMjAuNDItMTkuMjEtMzMuNDctMTcuNzEtMTUuMzcsMS43Ni0yNS4xMSw4LjktMzkuMDksMjQuMDF2OTcuNzVjNC4xOS00Ni4yLDExLjMxLTYxLjA3LDE5LjA3LTczLjI1LDExLjIzLTE3LjYxLDI3LjQ0LTE2Ljk1LDQyLjY5LTExLjc2LDEwLjQzLDMuNTUsMzUuNjIsMTUuMjIsNDUuNzUsMTAuOSw3LjI0LTMuMDksMTAuODEtMTEuMzEsMTIuMjUtMTkuMDUsMS40My03Ljc0LDEuNDctMTUuODgsNC43Mi0yMy4wNSw1LjMxLTExLjcsMTguNi0xOC40MSwzMS40NC0xOC41MSwxMi44NS0uMSwyNS4xNiw1LjQ2LDM1LjY5LDEyLjgyLDcuOTksNS41OSwxNS4yMSwxMi4yNSwyMy4zOCwxNy41OCw3Ljg4LDUuMTQsMTcsOS4wMywyNi4zNyw4Ljc0LTE5LjM2LTEuMDEtNjAuMjMtMzguNC03OS43OC01Ny45NVoiLz4KICA8cGF0aCBjbGFzcz0iY2xzLTEiIGQ9Im00MzguNTUuNjhjLTI0LjY2LDQyLjIzLTM3LjMsOTEuMi02NS45MywxMzAuODctNC44NSw2LjczLTEyLjE2LDEzLjg3LTIwLjE3LDExLjcyLTMuMDUtLjgyLTUuNTgtMi45MS03LjkyLTUuMDMtNy41LTYuODEtMTQuMzEtMTQuNjUtMjMuMjMtMTkuNDYtOC45Mi00LjgxLTE4Ljk1LTUuOC0yNi41MS45NS00LjM4LDMuOTEtNi41Myw5LjY4LTguNTIsMTUuMjEtNS40MywxNS4wNy05Ljg1LDMwLjE0LTE1LjI4LDQ1LjIyLTMuOTEsMTAuODctMTIuOTQsMjkuNjItMjQuNDQsMjguNjYsMTQuNzIsMi40MywzMC4xMS0xOS4wOSwzNi4wNS0zMywxOS45Ni00Ni43Myw0NS44Ny0yMy4zNyw2Ni43MS0yMi4yMSwxOS4xMSwxLjA2LDM1LjQyLTEzLjYxLDQ1LjczLTI5LjczLDEzLjc2LTIxLjUxLDMzLjg4LTg5LjA0LDg5LjgzLTEyMy4xOGgtNDYuMzNaIi8+CiAgPHBhdGggY2xhc3M9ImNscy0zIiBkPSJtMjM1LjE4LDE5Mi42Yy0xOC4wNS00NS43MS0yMi4zOS05Ni00MS4yNy0xNDEuMzctNS45Ny0xNC4zNS0xMy43LTI4LjUxLTI1Ljg2LTM4LjE5LTEyLjE3LTkuNjctMjkuNjEtMTMuOTctNDMuNjItNy4yNS0xOC4wOSw4LjY3LTI1LjE5LDMxLjk5LTQyLjg3LDQxLjQ3LTEuNDYuNzgtMy4wMywxLjQ3LTQuNjgsMS41Mi00Ljg5LjE0LTguMDktNS4wMi05LjY1LTkuNjYtNC4xNS0xMi4zNS00LjE1LTI1LjQ0LTIuMjgtMzguNDVoLTIyLjgyYzAsMTUuNTIuMDcsMzEuNCw1LjM0LDQ2LDUuMjksMTQuNjcsMTYuOTQsMjguMDUsMzIuMjcsMzAuOTMsMTYuOTUsMy4xOSwzOC4zNy0zNS45OSw1NS42Mi0zNS45NywzMC4xMi4wNCw1MS42MiwyOS4zOSw2Mi4zNyw1Ny41MywxMC44OSwyOC41LDIwLjk0LDEwMi43Nyw0Ny43NiwxMDkuNDMuMzIuMDguNjMuMTMuOTUuMTgtNi4xOS0xLjQ2LTkuNTUtMTEuODktMTEuMjQtMTYuMThaIi8+Cjwvc3ZnPg=="/> '
        //     '<!--component seperator-->'
        //     '<path d="M1087 779.7H602.3a37.3 37.3 0 0 1-37.3-37.3v-705A37.3 37.3 0 0 1 602.3 0H565V0h-42.3A37.3 37.3 0 0 1 560 37.4v271h-.3a37.3 37.3 0 0 1-37.3 37.3S0 345.6 0 345.6v5h522.5a37.3 37.3 0 0 1 37.2 37.3h.3v699.9a37.3 37.3 0 0 1-37.3 37.2h79.5a37.3 37.3 0 0 1-37.2-37.3V822a37.3 37.3 0 0 1 37.3-37.3h485.4A37.3 37.3 0 0 1 1125 822v-79.6a37.3 37.3 0 0 1-37.3 37.3Z" fill="white"/>'
        //     '<!--bottom right-->'
        //     '<image width="100%" height="100%" xlink:href="data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHN2ZyBpZD0iTGF5ZXJfMSIgZGF0YS1uYW1lPSJMYXllciAxIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxMTI1IDExMjUiPgogIDxkZWZzPgogICAgPHN0eWxlPgogICAgICAuY2xzLTEgewogICAgICAgIGZpbGw6ICMwNDMyZmY7CiAgICAgIH0KCiAgICAgIC5jbHMtMiB7CiAgICAgICAgZmlsbDogIzAwOTFmZjsKICAgICAgfQoKICAgICAgLmNscy0zIHsKICAgICAgICBmaWxsOiAjZWRlZWVlOwogICAgICB9CgogICAgICAuY2xzLTQgewogICAgICAgIGZpbGw6ICNmZjI1MDA7CiAgICAgIH0KCiAgICAgIC5jbHMtNSB7CiAgICAgICAgZmlsbDogIzJkMmQyZDsKICAgICAgfQogICAgPC9zdHlsZT4KICA8L2RlZnM+CiAgPHBhdGggY2xhc3M9ImNscy0xIiBkPSJtODYyLjc1LDExMDguNzJjMTQuMjQsMy43NCwzNS4wMiw5LjY2LDU4LjUzLDE2LjI4aDEwOC40M2MtNjEuNzMtMjguNDQtMTUzLjM3LTY4LjI2LTI0Ni42MS0xMDAuMDUtMTUyLjc0LTU3LjA0LTMyOS41NS04NS43OS0zMjYuMzktODcuMzctLjI2LS4yNy0uNTItLjU0LS43OC0uODFsLTIuNDIsMi4zN2MtNi4wMywxNy42OSwxNjguODEsODIuODIsMjI2LjUsMTA3LjI4LDIuMi45Myw0LjgyLDIuMDgsNy43NiwzLjM4LDUzLjM2LDIzLjc1LDEwOC43Miw0Mi43NCwxNjUuNDcsNTYuNTIsMy42NS44OSw2Ljg3LDEuNjksOS41LDIuMzhaIi8+CiAgPGNpcmNsZSBjbGFzcz0iY2xzLTMiIGN4PSI4MjguMyIgY3k9Ijg0OS4yOSIgcj0iMi43Ii8+CiAgPHBhdGggY2xhc3M9ImNscy0zIiBkPSJtODE0LjI3LDk5MWMtLjgsNS40LTEuNCw3LjgsMCw5LjMsMS44LDEuOCw1LjcuMSwxMC4zLTEuMy01LjEsMi41LTguNSwzLjQtOC45LDUuNS0uNCwyLjEsMS43LDUuNywzLDkuNC0xLjYtMy4xLTQtNy4zLTYuNi03LjYtMi40LS4yLTcuMyw0LjUtOS40LDUuOSwyLjItMi4zLDYuMy01LjcsNS42LTktLjYtMi44LTMtMi41LTYuMi01LjIsMi45LDEuNCw2LjUsMy40LDguMiwyLjUsMS45LTEsMi43LTQuNyw0LTkuNWgwWiIvPgogIDxwYXRoIGNsYXNzPSJjbHMtMyIgZD0ibTYyNy42Nyw4MzIuNTdjLTEuMyw5LjgtMi41LDE0LjIuMSwxNi44LDMuMiwzLjIsMTAuMy4yLDE4LjctMi4zLTkuMiw0LjYtMTUuMyw2LjEtMTYuMSw5LjlzMy4yLDEwLjMsNS40LDE2LjljLTIuOS01LjYtNy4zLTEzLjItMTEuOS0xMy43LTQuNC0uNC0xMy4xLDguMS0xNywxMC43LDQtNC4xLDExLjQtMTAuMiwxMC4xLTE2LjItMS4xLTUtNS4zLTQuNS0xMS4yLTkuNSw1LjIsMi41LDExLjcsNi4yLDE0LjcsNC41LDMuNC0xLjcsNC43LTguNCw3LjItMTcuMWgwWiIvPgogIDxjaXJjbGUgY2xhc3M9ImNscy0zIiBjeD0iNjY5LjM3IiBjeT0iODc4LjU1IiByPSI0LjUiLz4KICA8Y2lyY2xlIGNsYXNzPSJjbHMtMyIgY3g9IjExMDQuMjciIGN5PSIxMDM4LjQiIHI9IjQuNSIvPgogIDxjaXJjbGUgY2xhc3M9ImNscy0zIiBjeD0iOTUwLjE3IiBjeT0iODg5LjgiIHI9IjQuNSIvPgogIDxwYXRoIGNsYXNzPSJjbHMtMyIgZD0ibTYxMC43NywxMDczLjNjLTMsMS4yLTQuNCwxLjYtNC43LDIuOC0uNCwxLjQsMS43LDIuOSwzLjgsNC44LTIuOC0xLjgtNC4yLTMuMy01LjUtMi45cy0yLjQsMi42LTMuOSw0LjNjMS4xLTEuOCwyLjUtNC4yLDEuOS01LjZzLTQuNC0yLjMtNS44LTNjMS44LjQsNC44LDEuNSw2LjIuMiwxLjItMS4xLjQtMi4yLjgtNC43LjIsMS45LjIsNC4zLDEuMiw0LjksMSwuNywzLjEsMCw2LS44aDBaIi8+CiAgPHBhdGggY2xhc3M9ImNscy0zIiBkPSJtNzk5LjA3LDEwNDcuMWMtMywxLjItNC40LDEuNi00LjcsMi44LS40LDEuNCwxLjcsMi45LDMuOCw0LjgtMi44LTEuOC00LjItMy4zLTUuNS0yLjktMS4yLjQtMi40LDIuNi0zLjksNC4zLDEuMS0xLjgsMi41LTQuMiwxLjktNS42LS42LTEuMy00LjQtMi4zLTUuOC0zLDEuOC40LDQuOCwxLjUsNi4yLjIsMS4yLTEuMS40LTIuMi44LTQuNy4yLDEuOS4yLDQuMywxLjIsNC45LDEuMS42LDMuMi0uMSw2LS44aDBaIi8+CiAgPGNpcmNsZSBjbGFzcz0iY2xzLTMiIGN4PSI3MTcuMjciIGN5PSI4MzMuNTUiIHI9IjIuNyIvPgogIDxjaXJjbGUgY2xhc3M9ImNscy0zIiBjeD0iNjkyLjY3IiBjeT0iODAxLjU1IiByPSIyLjciLz4KICA8Y2lyY2xlIGNsYXNzPSJjbHMtMyIgY3g9IjcxMS45NyIgY3k9Ijc5OC44NSIgcj0iMi43Ii8+CiAgPGNpcmNsZSBjbGFzcz0iY2xzLTMiIGN4PSIxMDg2LjI3IiBjeT0iMTA2OC43IiByPSIyLjciLz4KICA8Y2lyY2xlIGNsYXNzPSJjbHMtMyIgY3g9IjkwMi45NyIgY3k9IjgwNy43IiByPSIyLjciLz4KICA8cGF0aCBjbGFzcz0iY2xzLTEiIGQ9Im04MDQuNjIsOTkzLjgzbC00LjktMS42N2MxLjYzLjU3LDMuMjYsMS4xMiw0LjksMS42N1oiLz4KICA8ZWxsaXBzZSBjbGFzcz0iY2xzLTIiIGN4PSI3OTcuNSIgY3k9IjEwMDAuNDQiIHJ4PSI5OS4zNyIgcnk9Ijc3LjM2IiB0cmFuc2Zvcm09InRyYW5zbGF0ZSgtNDA2Ljc1IDE0MzIuNSkgcm90YXRlKC03MS4xOCkiLz4KICA8cGF0aCBjbGFzcz0iY2xzLTEiIGQ9Im03MTIuNDcsOTUyLjVjNS45MS0xNy4zNCw0MC43LDEzLjc1LDkwLjg2LDMwLjg1LDUwLjE2LDE3LjEsOTYuNjgsMTMuNzYsOTAuNzgsMzEuMDctMy4zLDkuNjktNDYuNjQsMy42OC05Ni44LTEzLjQyLTUwLjE2LTE3LjEtODguMTQtMzguODEtODQuODQtNDguNVoiLz4KICA8cGF0aCBkPSJtNzQwLjAyLDk1NC4zN2MxMC42OS0xOC40MSwyNi4yNC0zMy4xOCw0Ni4wOC00MC44OCwyNi4yMi0xMC4xOCwzOC4xNC0yLjA1LDM4LjIyLDEuMi4xNyw3LjUxLTE0Ljc5LDEuNzItMzMuNzYsNS4zNy0xMC45NywyLjExLTIxLjgyLDEwLjUxLTI1LjI3LDIxLjE0LTEuMjQsMy44MSwxLjQyLDUuMiw4LjQ4LDEuMzksMTIuNDgtNi43NCwyNy45LTQuNTIsMzAuMzItLjY5LDIuNDQsMy44Ny0xMC4yNyw3LjIzLTExLjMyLDExLjgxLTEuNjgsNy4yNywyMC4yNSwxNS44NSwyOS4xNiwxOC44NiwxMy4yLDQuNDUsMzAuMDYsOS4xNiwyOS4yNywxNS4zNy0uMjMsMS44Mi0zLjQsNi42NS0xNiw0LjEzLTM3Ljg1LTcuNTgtNjYuNTYtMjIuODgtOTUuMTgtMzcuNjlaIi8+CiAgPHBhdGggZD0ibTcyMy4wMiwxMDA0LjIyYzIwLjksMy41OCw0NC42NywxNC41Niw2NC41OSwyMS44Mi4wNS4wMi4xLjA0LjE0LjA1LDQuMjYsMS41NiwyLjQyLDcuOTUtMi4wMiw3LjAyLTYuNTYtMS4zNy0xNC4zNi0zLjM1LTIxLjQ1LTUuMDgtNy44Ni0xLjkxLTIwLjk1LTkuMDgtMjMuOS0xLjU0LTMuMSw3LjkyLDE4LjY4LDguNzQsMTkuMDksMTUuNjYuMzcsNi4wOC0xMS44MywzLjU5LTE1LjE4LDExLjctMS43MSw0LjEyLS4wMSw4Ljg1LDMuNjgsMTEuMzYsMTEuMTMsNy41NiwyOS42Ni03LjA4LDM0LjA0LTYuNjYsMTQuNSwxLjQsMS4wNywxNS45OSwxNC42NSwyMi4yLjA0LjAyLjA4LjAzLjExLjA1LDQuOTIsMi4yMiw0LjMsOS4zNS0uOTYsMTAuNTYtMTkuODcsNC41OC00Ny44NC01LjMzLTYyLjcxLTI4Ljk4LTExLjI1LTE3Ljg4LTEyLjI2LTUzLjMyLTEwLjA5LTU4LjE3WiIvPgogIDxwYXRoIGNsYXNzPSJjbHMtMyIgZD0ibTgzMC41MSw5MjUuMTdjLTMuOTMsMy42OC00Ljc3LDEwLjIyLTEuOTEsMTQuNzguODQsMS4zMywxLjk2LDIuNSwzLjMyLDMuMjgsMy4zNywxLjkyLDcuNzYsMS4xNiwxMS4wNS0uOTEsMy4xLTEuOTUsNS41NC01LjExLDYuMDgtOC43My42My00LjIyLTEuNTktOC43My01LjMzLTEwLjgtMy43NC0yLjA3LTguODYtMS43LTEzLjIyLDIuMzhaIi8+CiAgPHBhdGggY2xhc3M9ImNscy0zIiBkPSJtODY5LjUsOTkxLjg1YzIuMDktOC45LjMzLTE4LjItMS41OS0yNy4xMy0uOTktNC42Mi0yLjA0LTkuMjgtNC4xOS0xMy40OC0uOTMtMS44My0yLjEtMy42LTMuNzctNC44LTIuNC0xLjczLTUuNy0yLjA4LTguNDQtLjk3LTIuNzQsMS4xMS00Ljg2LDMuNi01LjYxLDYuNDYtLjI2Ljk5LS4zNiwyLjA2LDAsMy4wMi40OSwxLjM1LDEuOCwyLjI2LDMuMTQsMi43NywxLjM0LjUyLDIuNzkuNzQsNC4xNCwxLjI0LDEuOTkuNzQsMy43MiwyLjA3LDUuMjMsMy41NiwzLjcyLDMuNjksNi4yNSw4LjU2LDcuMTUsMTMuNzMuOCw0LjYyLjMxLDkuMzcuOTcsMTQuMDEuMTYsMS4xMi44NiwyLjU1LDIuOTgsMS41OFoiLz4KICA8cGF0aCBjbGFzcz0iY2xzLTMiIGQ9Im03OTUuMSwxMDgyLjc0YzQuMjEsMS4xLDguOC4wMiwxMy4wMy0xLjcsOS45NC00LjA0LDE4Ljg1LTExLjY2LDI0Ljk2LTIxLjM1LDEuMzItMi4xLDIuNTYtNC4zNCw0LjQtNS45LDEuMjItMS4wMywyLjk5LTEuNjksNC4xNC0uNzQsMS4zMywxLjA5LjkyLDMuNDUuMjIsNS4yNC0zLjQ3LDguODktMTAuODYsMTUuNC0xOC40MSwyMC41MS04LjEyLDUuNDktMTcuMTcsOS45OC0yNi4zOCwxMC0xLjY1LDAtMy40Mi0uMi00LjU0LTEuNDQtMS4xMi0xLjI0LS44OC01LjUyLDIuNTgtNC42MVoiLz4KICA8cGF0aCBjbGFzcz0iY2xzLTMiIGQ9Im02MTYuODksOTg2LjQxYy02Ny4zMy0yMC41MS0xMjguOTItNDAuNjYtMTI5LjcxLTMzLjQxLS40MywzLjkzLDQzLjU2LDIyLjQyLDg3LjM3LDM4LjYxLDE0LjQxLDUuMzMsNjcuMzEsMjUuNjEsOTQuMTcsMzUuNTQsMzQuNjQsMTIuOCwyNi43OCwxMi4zOCwxNy4wNyw5LjA3LTI3LjcyLTkuNDUtMjA3LjExLTc1LjYyLTIyNy4yNi05MS4yOC0uOTktLjc3LTEuOS0xLjU3LTIuMTQtMi4yNy0uOS0yLjY3LDExLjMyLTQuOTQsMTA1LjM2LDIzLjQzLDE3LjA5LDUuMTYsMzUuNSw5LjU0LDU1LjUsMTYuMzYsMTIuMDIsNC4xLDExLjEyLDcuODgtLjM2LDMuOTZaIi8+CiAgPGc+CiAgICA8cGF0aCBjbGFzcz0iY2xzLTMiIGQ9Im05NDYuNTMsMTEwMC45MmMyMi42OCw4LjY0LDQ0Ljc0LDE2Ljg1LDYzLjMxLDI0LjA4aDguODJjLTYuMjItMi40OC0xMi45Ny01LjEyLTIwLjMxLTcuOTQtMTUuMzktNS45Mi0zMS4yOC0xMy4yMi00OS43NS0xOS41Mi0xMS4xLTMuNzgtMTIuNjctLjIzLTIuMDcsMy4zOFoiLz4KICAgIDxwYXRoIGNsYXNzPSJjbHMtMyIgZD0ibTg2Ny40NSwxMTAwLjI4YzEwLjA4LDMuNDMsNDIuMzEsMTMuNjQsNzkuMTQsMjQuNzJoMTEuMTljLTIxLjAyLTYuMzItNTMuNzktMTYuMDktNzIuNjYtMjEuOTQtMzIuNTgtMTAuMTEtMjYuNjQtNS44My0xNy42Ny0yLjc4WiIvPgogIDwvZz4KICA8cGF0aCBjbGFzcz0iY2xzLTQiIGQ9Im0xMDU4Ljg5LDExMjVjLTkzLjQ0LTcyLjY1LTEyMi4yNi05Ni4xLTE2NC43Ny0xMTAuNTksMCwwLTQ5LjQ2LTYuNTUtOTQuNC0yMi4yNi00My45OC0xNC45OS04OC4zNC00MC4wMy04OC4zNC00MC4wMy00Ni40Ny0xNS44NC04OC45OC0xMy4wNi0yNTUuNDQtMTUuMzUuMjYuMjcuNTIuNTQuNzguODEtMy4xNiwxLjU4LDE3My42NCwzMC4zMywzMjYuMzksODcuMzcsOTMuMjQsMzEuNzgsMTg0Ljg4LDcxLjYsMjQ2LjYxLDEwMC4wNWgyOS4xN1oiLz4KICA8cGF0aCBkPSJtNzEzLjU2LDk1OS4yM2MtMTcuOTMtNi44Ny0zMC4yNS0xMC4xMi00MC40My0xMS4zOS0xNi45LTIuMS04LjIsOC43MS0xMS4yMiwxMS44MS00LjQ2LDQuNTctMTQuNzYsMS42NC0yOS45OC03LjYyLTE1LjI2LTkuMjktNTQuNDItNy42OS04MS44OC04LjczLTEuNjgtLjA2LTEuODksMi41Ni0uMiwyLjYyLDE5LjE5LjczLDQ0Ljc5Ljg4LDYxLjAyLDMuOTgsMTUuNzYsMy4wMSwyNi4zNiwxMi40OCwzNy4wNywxNi44OCwxOC44NCw3Ljc0LDMyLjM5LDExLjQ1LDM0LjY5LDguMTcsMi42Ny0zLjgxLTEzLjc2LTE1LjE4LTEwLjg3LTIwLjU4LDQuMDctNy42LDIzLjg2LjYyLDQxLjgxLDQuODZaIi8+CiAgPHBhdGggZD0ibTUwNy4wMSw5NDAuMjZjOS4zNC0uMTUsMTguNjkuMzIsMjcuOTYsMS40MSwyLjE3LjI2LDQuNDYuNTksNi4xOCwxLjk1LjE1LjEyLjMxLjI2LjM0LjQ1LjAzLjE4LS4wNi4zNi0uMTguNS0uNzEuOS0yLjA3LjgyLTMuMjEuNjctOC4zOC0xLjEzLTE2LjgyLTEuODEtMjUuMjctMi4wMy0xLjM2LS4wNC0yLjc1LS4wNy00LjA0LS41LTEuMjktLjQzLTIuNDktMS4zNS0xLjc5LTIuNDVaIi8+CiAgPHBhdGggZD0ibTkwNy4zNSwxMDI1LjQ1YzguMDUsNC4yMSwxNS45MSw4Ljc5LDIzLjU0LDEzLjczLDEuMjcuODIsMi41NywxLjcsMy4zNSwyLjk5Ljc4LDEuMy44NiwzLjE0LS4yMiw0LjE5LS45MS44OS0yLjMxLjk4LTMuNTgsMS4wMS00LjUuMTMtOS4wMS4yNS0xMy41MS4zOC0xLjQ2LjA0LTMuMjEuMjYtMy44NSwxLjU3LS43NiwxLjU0LjY0LDMuMjYsMi4wMSw0LjI5LDE0LjM5LDEwLjg3LDM2LjI0LDQuNTYsNTEuNjQsMTMuOTUsMy4xMywxLjkxLDUuODYsNC40LDguODIsNi41Niw1LjU1LDQuMDUsMTEuODUsNi45MiwxNy44OCwxMC4yLDE0LjQzLDcuODYsMjcuMzYsMTguMTYsNDAuMjEsMjguNC0xMC44LTguODUtMjEuNTktMTcuNy0zMi4zOS0yNi41NS0zLjUyLTIuODgtNy4wNS01Ljc4LTEwLjk2LTguMTEtMi44NC0xLjY5LTUuODYtMy4wOC04LjU4LTQuOTUtMy42NS0yLjUxLTYuNjktNS44MS0xMC4yMy04LjQ3LTYuNDUtNC44NS0xNC40LTcuMzgtMjIuMzktOC41LTYuNDYtLjktMTMuNDctMS4xLTE4LjYzLTUuMDksNS4wMy0uMzgsMTAuMDYtLjc1LDE1LjA5LTEuMTMsMS42MS0uMTIsMy42Ny0uNjUsMy44Mi0yLjI2LjEyLTEuMjktMS4xNC0yLjI0LTIuMjYtMi45LTEzLjYyLTguMDctMjcuNzQtMTUuMjgtMzkuNzQtMTkuMjlaIi8+CiAgPHBhdGggZD0ibTcyNS45Miw5NjkuMDRjLTEyLjU2LDEuOTMtMjQuODYsNS41NS0zNi40NiwxMC43My0yLjI2LDEuMDEtNC43MywyLjM0LTUuNCw0LjcyLDUuMDQuNDEsMTAuMDIsMS42NSwxNC42NiwzLjY2LjguMzUsMS42Mi43MiwyLjQ5Ljc2LDEuMzQuMDUsMi41Ni0uNywzLjctMS40LDEwLjQ2LTYuNDEsMjIuMTMtMTAuODIsMzQuMjItMTIuOTMtMy41NC0yLjkxLTguMTMtNC41My0xMi43MS00LjQ5LDEuMDYuMDQsMi4xMi4wOC0uNS0xLjA2WiIvPgogIDxwYXRoIGQ9Im03NDcuNDUsOTc5LjMyYy0xMS4xOCwxLjI1LTIyLjA3LDQuOTctMzEuNjgsMTAuODIsMi43My42LDUuNDYsMS4xOSw4LjE4LDEuNzksMS4wOC4yNCwyLjE4LjQ3LDMuMjguNCwxLjkxLS4xNCwzLjYyLTEuMTksNS4yOC0yLjE2LDguMTUtNC43MywxNy4yNy03Ljc4LDI2LjYzLTguODktMy40NS0xLjczLTcuMjQtMi40NS0xMS42OS0xLjk1WiIvPgogIDxwYXRoIGNsYXNzPSJjbHMtMyIgZD0ibTk2MS45Myw3ODQuNzVjLTYuMSw4LjQyLTkuNzQsMTguODItOS43NCwzMC4wMywwLDI4LjMsMjIuOTMsNTEuMjQsNTEuMjQsNTEuMjRzNTEuMjQtMjIuOTMsNTEuMjQtNTEuMjRjMC0xMS4yLTMuNTgtMjEuNTQtOS43NC0zMC4wM2gtODIuOTlaIi8+CiAgPHBhdGggY2xhc3M9ImNscy01IiBkPSJtMTAyOS42MSw4NTQuODhjLTguNjIsMS4xMy0xNi44NCw0Ljk3LTIzLjA3LDEwLjk0LDExLS42NiwyMS44Ny00Ljg0LDMwLjY5LTEyLjU5LS42LjI3LTEuMTMuNTMtMS43Mi43My0xLjk5LjYtMy45OC42Ni01LjkuOTNaIi8+CiAgPHBhdGggY2xhc3M9ImNscy01IiBkPSJtOTU1LjgzLDgzMy42Yy4yLS4yNy42LS40LjczLS42Ni42LS43My40Ni0xLjcyLjMzLTIuNjUtMS4xOS0xMC42MSw2LjM2LTIwLjE1LDE0LjE4LTI3LjM4LDcuNDItNi44MywxNS41OC0xMi45MywyNC4yNi0xOC4xNmgtNi44M2MtMS4wNi42Ni0yLjE5LDEuMzktMy4yNSwyLjEyLTEuNDYuOTktMS44Ni0uNi0uNDYtMS43OS4xMy0uMTMuMjctLjIuNC0uMzNoLTUuNWMtNC4xMSwzLjY1LTcuNjksNy42OS0xMC43NCwxMi4yLTIuNTksMy44NC04LjM1LDEwLjk0LTExLjYsOS4xNS0zLjQ1LTEuODYuMTMtOC44Miw5LjU0LTE4LjQ5LjkzLS45OSwxLjk5LTEuOTIsMy4xMi0yLjg1aC04LjA5Yy0xMC40MSwxNC4zOC0xMi40NiwzMi44OC02LjEsNDguODVaIi8+CiAgPHBhdGggY2xhc3M9ImNscy01IiBkPSJtMTA1NC42Niw4MTQuNzFjMCwxLjcyLS4xMywzLjQ1LS4yNyw1LjEtMi4zMiwyLjY1LTcuMjIsMS4yNi05Ljk0LjQ2LTExLjE0LTMuMjUtMzQuOC40LTUzLjQzLDUuMS0yLjU5LjY2LTMuNzgtMi45OC0xLjMzLTQuMDQsMTIuMTMtNS4xNywyNy41Ny0xMC4xNCwzOS4xMS0xMS4yLDUuOTctLjUzLDE3LjE3LTEuNjYsMjIuNCwxLjEzLDEuMDYuNTMsMi41MiwxLjU5LDMuNDUsMi45OC0uMDctMTAuMzQtMy4zMS0yMC42OC05LjY4LTI5LjVoLTMyLjgxYy0xNi41LDcuOTUtMzEuODgsMTguMzYtNDUuNCwzMC43Ni0yLjA1LDEuODYtNC4xOCw0LjA0LTQuMjQsNi44MywwLC42Ni4xMywxLjM5LjYsMS44NiwxLjE5LDEuMzMsMy4zMS4yLDQuNzEtLjkzLDE5LjU1LTE2LjM3LDQwLjM3LTMzLjQ3LDY1LjU2LTM3LjU4LDQuMzctLjczLDkuMTUtLjkzLDEyLjk5LDEuMTksMS44NiwyLjkyLDMuNDUsNS45Nyw0LjcxLDkuMjEtLjEzLjczLS40LDEuMzktLjgsMi4wNS0xLjk5LDMuMTItNi4xNiwzLjkxLTkuODEsNC4zMS0xMi41OSwxLjMzLTI1LjUyLDEuNzItMzcuNjUsNS40NC0xNy4zNyw1LjMtMzEuOTUsMTcuMS00NS41NCwyOS4wMywyLjQ1LDUuMDQsNS43Nyw5LjgxLDkuOTQsMTMuOTksMi43OCwyLjc4LDUuODMsNS4xNyw5LjA4LDcuMjIsNS4yNC00Ljk3LDEwLjgtOS40MSwxNC44NS0xMS43Myw3LjE2LTQuMTEsMTAuNjctNC45Nyw5LjQxLTIuNDUtMS4xOSwyLjM5LTUuODMsNC42NC04LjA5LDUuNTctNC41NywxLjg2LTkuNDgsNC43Ny0xNS4xMSw5LjM1LDguMDIsNC43MSwxNy4wNCw3LjA5LDI2LjA1LDcuMDksNy42OS02LjAzLDEzLjE5LTE1LjMxLDIyLjQtMTguMzYsNC4wNC0xLjMzLDguMzUtMS4zMywxMi41OS0xLjI2LDEuNTIsMCwzLjY1LjUzLDMuNjUsMi4wNSw4LjQ4LTkuNzQsMTIuNjYtMjEuODcsMTIuNTktMzR2LjMzWm0tNi42OSwyNS4zMmMtMTcuNy40LTM0LjQ3LDMuODQtNDUuOTMsMTcuMzctNy4wMyw4LjIyLTEyLjkzLS4yLTYuOTYtNS41LDE2LjM3LTE0LjUyLDM3LjA1LTE0LjE4LDQ4Ljc5LTEyLjY2LDEuNjYuMiwzLjcxLjI3LDQuNTEtMS4xOS0uNzMtMS4xOS0yLjI1LTEuNTktMy42NS0xLjg2LTIxLjgxLTMuOTEtNDQuNDEsMS45OS02NC4xLDEyLTIuMjUsMS4xMy00LjU3LDIuMzktNy4wMywyLjc4cy01LjMtLjEzLTYuOTYtMi4wNWMtMi4zMi0yLjcyLTEuNDYtNy4xNiwxLjE5LTkuODgsMi40NS0yLjU5LDYuMS0zLjc4LDkuNTQtNC43MSwxNC42NS0zLjk4LDI5Ljg5LTUuNjMsNDUuMDctNS42Myw4LjU1LDAsMTcuNTcuNzMsMjQuNjYsNS41Ljk5LjY2LDEuOTksMS41MiwyLjU5LDIuNTItLjUzLDEuMTMtMS4xMywyLjI1LTEuNzIsMy4zMVptMy45OC04Ljg4Yy0xMy44NS01LjUtMjkuMDMtNy4yMi00NC4xNS00Ljg0LTIuMDUuMi0xLjY2LTEuNTIuMzMtMS44NiwxNC4zMi0yLjI1LDMyLjIxLTQuOTEsNDUuMjEsMS43Mi0uNCwxLjY2LS44NiwzLjMxLTEuMzksNC45N1oiLz4KPC9zdmc+"/>'
        //     '<!--white around the logo-->'
        //     '<path d="M664.1 576.7c0-49.6-35.7-91-82.8-99.8A37.3 37.3 0 0 1 565 446h-5c0 12.7-6.5 24-16.3 30.7a101.8 101.8 0 0 0-20 193.8h-1 1c6 2.5 12.4 4.4 18.9 5.7A37.3 37.3 0 0 1 560 708h5c0-13.3 7-25 17.4-31.6 6.6-1.3 12.8-3.2 18.8-5.7h1-.9a101.8 101.8 0 0 0 62.8-93.9Zm-78.9 93.9h-45.4a96.8 96.8 0 0 1-2-187.3h49.5c41.3 11 71.8 48.7 71.8 93.4s-31.5 83.7-73.9 93.9Z" fill="white"/>'
        //     '<!--black circle around color core logo-->'
        //     '<circle cx="50%" cy="51.26%" r="99"/>'
        //     '<!--logo color core-->'
        //     '<circle cx="50%" cy="51.26%" r="65" class="colorCore"/>'
        //     '<!--white bubble shading logo-->'
        //     '<path d="M590.2 532.7c-2.8-2.4.4-6.7 3.5-4.8a53 53 0 0 1 16 16.3c8.6 13.5 9 30.7 3.2 30.7-4.6 0-8.6-1-8.6-15.1a36 36 0 0 0-14.1-27.1ZM571.4 520.7c4-.5 8 0 11.7 1.7 1.4.6 2.8 1.4 3.2 2.8a4 4 0 0 1-.4 2.7c-.2.3-.4.7-.7.8-.4.2-.7.2-1.1 0-1.4-.3-2.8-1-4-1.8a25 25 0 0 0-8.5-2.7c-.7 0-1.4-.2-1.8-.6-.6-.5-.5-1.5-.2-2.1.5-.8 1.5-1.3 1.7-.8ZM504.7 583a45.6 45.6 0 0 0 30.9 31.7c11.6 2.8 17-7.2 8.6-10.1-6-2.1-8.8 2-20.8-2.9-8-3.1-12.6-8.2-18.7-18.6ZM519 613.6a60.6 60.6 0 0 0 51.9 23.2 43 43 0 0 1-1.5-7c-1.5.5-3.1.6-4.7.6a71.4 71.4 0 0 1-45.7-16.8ZM572.1 629.9c.9 2 1.6 4 2 6.1 4.6-.8 9.1-2.2 13.2-4.2a20.5 20.5 0 0 1-2.5-7c-4 1.9-8.3 3.5-12.7 5Z" fill="white"/>'
        //     '<!--black center component, upshot chess in logo-->'
        //     '<path d="M596 585c0 18.7-11 30-31.4 30-6.1 0-11.5-1-16-3 10.3-4.5 15.8-14 15.8-27v-5.6c0-.6-.6-1.1-1.2-1.1h-30.6v-36.8h4.5c1.6 3.2 4 5.7 6.8 7.6 2.2-3.4 5.3-6 9.4-7.6h.2c1.6 3.2 4 5.7 6.8 7.6 2.1-3.2 5-5.7 8.7-7.3 4.1.4 7.9 1.3 11.1 2.7-10.2 4.5-15.7 14-15.7 27v5c0 .9.8 1.7 1.8 1.7h30l-.1 6.7Z"/>'
        //     '</svg>'));
        return _svg;
    }

    /**
     * TODO: write a more comprehensive description
     */
    function _payloadTokenURI(uint256 tokenId, string memory name) internal returns (string memory) {
        
        string memory description = "This NFT represents a liquidity position.";
        
        return
            string(abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(bytes(abi.encodePacked(
                        '{"name":"',
                            name,
                        '", "description":"',
                            description,
                        '", "image": "',
                            'data:image/svg+xml;base64,',
                            Base64.encode(bytes(generateImage(tokenId))),
                        '"}'
                    )))
            ));
    }




}

// SPDX-License-Identifier: MIT
// Copyright (c) 2022 xxxxxx xxxxxxxxxxxx xxx. All Rights Reserved
pragma solidity 0.8.x;

// import "hardhat/console.sol";

import {MetadataGenerator} from "./MetadataGenerator.sol";
import {ERC721} from "solmate/src/tokens/ERC721.sol";

contract TestNft is ERC721, MetadataGenerator{

    constructor() ERC721("TestNft", "TNFT") {
    }

    /**
     * 
     */
    function tokenURI(uint256 tokenId) public override returns (string memory) {
        return _payloadTokenURI(tokenId, name);
    }

    /**
     */
    function mint(address to, uint256 id) public {
        _mint(to, id);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits;
        temp = value;
        while (temp != 0) {
            buffer[--index] = bytes1(uint8(48 + uint256(temp % 10)));
            temp /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    //function tokenURI(uint256 id) public view virtual returns (string memory);
    function tokenURI(uint256 id) public virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}