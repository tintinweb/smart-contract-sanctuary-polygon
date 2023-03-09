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
// Copyright (c) 2023 Upshot Technologies Inc. All Rights Reserved
pragma solidity 0.8.x;

import {MetadataInfo} from "./MetadataInfo.sol";
import {Base64} from "./Base64.sol";
import {Strings} from "../../../../lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import {IERC20Metadata} from "../../../../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract MetadataGenerator {

    string[] _assetDay;
    string[] _assetNight;

    // constructor(string[] memory assetDay_, string[] memory assetNight_) {
    //     _assetDay = assetDay_;
    //     _assetNight = assetNight_;
    // }

    constructor() {}

    function setAsset(string calldata asset, bool day) external {
        if(day){
            _assetDay.push(asset);
        } else {
            _assetNight.push(asset);
        }
    }

    /**
     */
    function _getPseudoRandomNumber(uint256 max, uint256 tokenId, address pool, address token) public pure returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        tokenId,
                        pool,
                        token
                    )
                )
            ) % max;
    }

    /**

     */
    function generateImage(MetadataInfo memory input, 
                           string memory nft_,
                           string memory xymbol_,
                           uint256 tokenId, address pool, address token
    ) view internal returns (string memory) {

        //get a number, if it's even, it's day, if it's odd, it's night
        bool day;
        string memory bg;
        string memory alt;
        uint256 pseudoRandomNumber0 = _getPseudoRandomNumber(2, tokenId, pool, token);
        uint256 pseudoRandomNumber1 = _getPseudoRandomNumber(5, tokenId, pool, token);

        if(pseudoRandomNumber0 == 0){
            day = true;
            bg = "#00A0FF";
            alt = "#FFC600";
        } else {
            day = false;
            bg = "#20F";
            alt = "#FF583E";
        }

        string memory svg = string(abi.encodePacked(
            _getComponent00(input, bg, alt),
            _getComponent01(input),
            _getComponent02(input, nft_, xymbol_, pseudoRandomNumber0, pseudoRandomNumber1)
        ));
        return svg;
    }

    function _getComponent00(MetadataInfo memory input, string memory bg, string memory alt) public pure returns (string memory) {
        string memory svg00 = string(abi.encodePacked(
            '<?xml version="1.0" encoding="UTF-8"?><svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 768 768"><defs><style>.gray{fill:#e5e5e5;}.strokes{stroke:#000;stroke-miterlimit:10;stroke-width:1.5px;}.bg{fill:',
            bg,
            ';}.alt{fill:',
            alt,
            ';}</style></defs><rect width="768" height="768" class="gray"/><g class="strokes"><rect class="bg" x="19.22" y="19.73" width="355.16" height="355.16" rx="40" ry="40"/><rect class="bg" x="19.22" y="394.11" width="355.16" height="355.16" rx="40" ry="40"/><path class="alt" d="m337.92,218.48c19.07-42.5,2.47-92.89-44.59-63.49-39.9,24.92-61.99-11.56-73.34-31.1-16.84-28.99-33.68-6.94-56.68,5.48-28.19,15.22-36.69-17.26-75.39-17.17-28.21.07-33.61,20.35-19.59,38.52,21.95,28.45,3.57,60.1-9.15,87.67-12.54,27.19-14.6,39.87-6.04,50.22,10.63,12.84,34.6,8.03,54.48-5.43,32.2-21.8,38.94-32.11,58.45-39.68,64.49-25.02,50.41,31.79,76.03,41.7,42.55,16.47,81.58-34.99,95.82-66.72Z"/><path class="gray" d="m116.47,221.75c1.36-2.28,2.35-5.13,2.97-8.57.62-3.44.93-7.58.93-12.43,0-4.31-.37-7.95-1.11-10.95-.74-2.99-1.79-5.44-3.16-7.35s-3.09-3.4-5.19-4.49c-2.1-1.09-4.6-1.84-7.5-2.26-2.9-.42-6.17-.63-9.83-.63h-15.31c1.83,17.69-6.13,35.8-14.14,52.79-.03.97-.06,1.94-.1,2.88h29.17c4.06,0,7.57-.28,10.54-.85,2.97-.57,5.49-1.5,7.57-2.78,2.08-1.29,3.8-3.07,5.16-5.34Zm-19.26-14.51c-.15,1.41-.38,2.57-.71,3.49-.32.92-.75,1.65-1.3,2.19s-1.2.9-1.97,1.08c-.77.17-1.6.26-2.49.26-.64,0-1.25-.01-1.82-.04-.57-.02-1.15-.06-1.74-.11-.09,0-.17-.02-.26-.03-.02-1.46-.04-3.12-.04-4.98v-11.69c0-1.73.01-3.5.04-5.31,0-.76.02-1.49.04-2.21.06,0,.12-.01.18-.01,1.16-.07,2.34-.11,3.53-.11,1.04,0,1.93.09,2.67.26.74.17,1.37.49,1.89.97.52.47.93,1.14,1.23,2,.3.87.53,2.03.71,3.49.17,1.46.26,3.25.26,5.38s-.07,3.97-.22,5.38Z"/><path class="gray" d="m151.15,218.14c-.05-2.3-.07-4.69-.07-7.16v-16.4c0-2.52.02-4.9.07-7.12.05-2.23.09-4.35.11-6.38.02-2.03.04-4.03.04-6.01h-23.68c.15,1.98.23,3.98.26,6.01.02,2.03.04,4.17.04,6.42v30.73c0,2.25-.01,4.4-.04,6.46s-.11,4.07-.26,6.05h23.68c.05-1.98.05-4,0-6.05-.05-2.05-.1-4.23-.15-6.53Z"/><path class="gray" d="m139.7,146.86c-3.76,0-6.53.88-8.31,2.63-1.78,1.76-2.67,4.24-2.67,7.46,0,3.27.89,5.76,2.67,7.5,1.78,1.73,4.55,2.6,8.31,2.6,3.56,0,6.21-.88,7.94-2.64,1.73-1.76,2.6-4.24,2.6-7.46,0-3.37-.87-5.89-2.6-7.57-1.73-1.68-4.38-2.52-7.94-2.52Z"/><path class="gray" d="m192.35,230.8c-.05-.79-.07-2-.07-3.64s-.04-3.59-.11-5.86c-.07-2.28-.11-4.81-.11-7.61s-.01-5.76-.04-8.91c-.02-2.85-.03-5.75-.04-8.7.68,0,1.34.01,2.04.02,2.65.02,5.33.09,8.05.19-.05-1.58-.09-3.36-.11-5.34-.02-1.98-.04-3.81-.04-5.49,0-1.83.01-3.7.04-5.6.02-1.9.06-3.5.11-4.79h-44.53c.1,1.29.15,2.88.15,4.79v11.17c0,1.98-.05,3.74-.15,5.27,3.49-.13,6.87-.2,10.16-.23,0,2.99-.03,5.91-.07,8.73-.05,3.14-.1,6.12-.15,8.94-.05,2.82-.07,5.36-.07,7.61s-.03,4.21-.07,5.86c-.05,1.66-.07,2.86-.07,3.6,1.19-.1,2.49-.17,3.9-.22,1.41-.05,2.89-.06,4.45-.04,1.56.02,2.96.04,4.19.04s2.68-.01,4.19-.04,3.01-.01,4.49.04c1.48.05,2.77.12,3.86.22Z"/><path class="gray" d="m243.38,230.8c-.05-.79-.07-2-.07-3.64s-.04-3.59-.11-5.86c-.07-2.28-.11-4.81-.11-7.61s-.01-5.76-.04-8.91c-.02-2.85-.03-5.75-.04-8.7.68,0,1.34.01,2.04.02,2.65.02,5.33.09,8.05.19-.05-1.58-.09-3.36-.11-5.34-.02-1.98-.04-3.81-.04-5.49,0-1.83.01-3.7.04-5.6.02-1.9.06-3.5.11-4.79h-44.53c.1,1.29.15,2.88.15,4.79v11.17c0,1.98-.05,3.74-.15,5.27,3.49-.13,6.87-.2,10.16-.23,0,2.99-.03,5.91-.07,8.73-.05,3.14-.1,6.12-.15,8.94-.05,2.82-.07,5.36-.07,7.61s-.03,4.21-.07,5.86c-.05,1.66-.07,2.86-.07,3.6,1.19-.1,2.49-.17,3.9-.22,1.41-.05,2.89-.06,4.45-.04,1.56.02,2.96.04,4.19.04s2.68-.01,4.19-.04,3.01-.01,4.49.04c1.48.05,2.77.12,3.86.22Z"/><path class="gray" d="m262.88,182.85c-1.58,2.13-2.75,4.74-3.49,7.83-.74,3.09-1.11,6.69-1.11,10.8,0,4.45.33,8.3,1,11.54.67,3.24,1.74,6.05,3.23,8.42s3.38,4.33,5.68,5.86c2.3,1.53,5.06,2.65,8.28,3.34,3.22.69,6.95,1.04,11.21,1.04s8.05-.35,11.25-1.04c3.19-.69,5.97-1.81,8.35-3.34,2.37-1.53,4.33-3.49,5.86-5.86,1.53-2.38,2.67-5.18,3.42-8.42.74-3.24,1.11-7.09,1.11-11.54,0-5.24-.62-9.61-1.86-13.1-1.24-3.49-3.12-6.3-5.64-8.42-2.52-2.13-5.67-3.64-9.43-4.53-3.76-.89-8.09-1.34-12.99-1.34-4.06,0-7.65.27-10.76.82-3.12.54-5.85,1.47-8.2,2.78-2.35,1.31-4.32,3.03-5.9,5.16Zm27.54,7.5c.79.3,1.45.9,1.97,1.82.52.92.9,2.15,1.15,3.71.25,1.56.37,3.45.37,5.68,0,2.43-.12,4.47-.37,6.12-.25,1.66-.63,2.98-1.15,3.97-.52.99-1.16,1.7-1.93,2.12-.77.42-1.67.63-2.71.63-1.09,0-2.03-.21-2.82-.63-.79-.42-1.44-1.11-1.93-2.08-.49-.97-.87-2.28-1.11-3.93-.25-1.66-.37-3.72-.37-6.2,0-2.27.14-4.18.41-5.71.27-1.53.64-2.76,1.11-3.67.47-.92,1.1-1.52,1.89-1.82.79-.3,1.73-.45,2.82-.45.99,0,1.88.15,2.67.45Z"/><path class="gray" d="m326.28,212.54c-1.68,1.73-2.52,4.38-2.52,7.94,0,3.76.88,6.53,2.63,8.31,1.28,1.3,2.94,2.11,4.99,2.47,2.54-4.46,4.74-8.78,6.54-12.78.98-2.18,1.86-4.38,2.65-6.58-1.69-1.3-3.93-1.95-6.71-1.95-3.37,0-5.89.87-7.57,2.6Z"/></g><path fill="transparent" id="rect-path-0" d="m39.39,166.08v-101.2c0-13.81,11.19-25,25-25h264.84c13.81,0,25,11.19,25,25v101.2"/><text font-family="monospace" font-size="1em" class="gray"><textPath xlink:href="#rect-path-0" dominant-baseline="text-after-edge" startOffset="50%" text-anchor="middle">',
            input.pool //Pool: 0x00000000000000000000000000000000DeaDBeef
        ));
        return svg00;
    }

    function _getComponent01(MetadataInfo memory input) public pure returns (string memory) {
        string memory svg00 = string(abi.encodePacked(
            '</textPath></text><path fill="transparent" id="rect-path" d="m39.39,226.05v101.2c0,13.81,11.19,25,25,25h264.84c13.81,0,25-11.19,25-25v-101.2"/><text font-family="monospace" font-size="1em" class="gray"><textPath xlink:href="#rect-path" dominant-baseline="hanging" startOffset="50%" text-anchor="middle">',
            input.admin, //Admin: 0x0C19069F36594D93Adfa5794546A8D6A9C1b9e23
            '</textPath></text><g transform="translate(-60,0)"><path d="m114.98,507.47h-26.84v-26.91h26.84v26.91Zm-25.55-1.3h24.25v-24.31h-24.25v24.31Z" class="gray"/><path d="m114.27,481.15c0,5.71,0,18.74-13.36,23.6-1.75.65-3.7,1.1-5.97,1.43-1.88.26-3.96.39-6.22.39v.13h25.61l-.06-25.55h0Z" class="gray"/><text transform="translate(126.2 500.58)" font-family="monospace" class="gray" font-size="1.75em">',
            input.curve, //Curve: Exp
            '</text><polygon points="114.33 538.4 88.79 538.4 101.56 512.85 114.33 538.4" class="gray"/><text transform="translate(126.18 532.21)" font-family="monospace" class="gray" font-size="1.75em">',
            input.delta //Delta: 0.05%
        ));
        return svg00;
    }

    function _getComponent02(MetadataInfo memory input, 
                           string memory nft_,
                           string memory xymbol_,
                           uint256 pseudoRandomNumber0,
                           uint256 pseudoRandomNumber1) public view returns (string memory) {
        string memory svg01 = string(abi.encodePacked(
            '</text><ellipse class="gray" cx="101.56" cy="549.7" rx="13.42" ry="3.81"/><path class="gray" d="m88.14,553.1v15.83c0,2.1,6.01,3.81,13.42,3.81s13.42-1.71,13.42-3.81v-15.83c-2.78,2.14-9.21,2.78-13.42,2.78s-10.64-.64-13.42-2.78Z"/><text transform="translate(126.88 563.83)" font-family="monospace" class="gray" font-size="1.75em">',
            input.fee, //Fee: 0.05%
            '</text><rect x="88.79" y="603.76" width="25.61" height="25.61" class="gray"/><text transform="translate(126.18 623.14)" font-family="monospace" class="gray" font-size="1.75em">',
            nft_, //BAYC: 32
            '</text><path d="m101.56,637.28h0c7.07,0,12.77,5.71,12.77,12.77h0c0,7.07-5.71,12.77-12.77,12.77h0c-7.07,0-12.77-5.71-12.77-12.77h0c0-7.07,5.71-12.77,12.77-12.77Z" class="gray"/><text transform="translate(126.18 655.52)" font-family="monospace" class="gray" font-size="1.75em">',
            xymbol_, //WETH: 21.63
            '</text></g><image width="100%" height="100%" xlink:href="data:image/svg+xml;base64,',
            pseudoRandomNumber0 == 0 ? _assetDay[pseudoRandomNumber1]: _assetNight[pseudoRandomNumber1], //Base64 encoded svg (REPLACE_ME Function)
            '"/></svg>'
            '</text>'));
        return svg01;
    }

    /**
     */
    function _substring(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory ) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }

    /**
     * 
     */
    function payloadTokenUri(MetadataInfo memory input, uint256 tokenId_, address pool, address token) view public returns (string memory) {
        string memory description = 'Upshot Swap is an NFT AMM that allows for autonomously providing liquidity and trading NFTs completely on-chain, without an off-chain orderbook. '
                                    'Liquidity providers deposit NFTs into Upshot Swap pools and are given NFT LP tokens to track their ownership of that liquidity. '
                                    'These NFT LP tokens represent liquidity in the AMM. '
                                    'When withdrawing liquidity, liquidity providers burn their NFT LP token(s) and are sent back the corresponding liquidity from the pool.'; 

        string memory nftSymbol;
        if(bytes(input.nftSymbol).length > 13){
            nftSymbol = _substring(input.nftSymbol, 0, 13);
        }
        string memory nft = string(abi.encodePacked(nftSymbol, ': ', Strings.toString(input.nftValue)));

        string memory xymbol;
        if(address(input.token) == address(0)) {

            uint256 valueEth = input.tokenValue/(1 ether);
            xymbol = string(abi.encodePacked('ETH: ', Strings.toString(valueEth)));
        } else {

            uint256 decimals = IERC20Metadata(address(input.token)).decimals();
            decimals = decimals == 0 ? 18 : decimals;
            uint256 valueUnit = input.tokenValue/(10**decimals);

            string memory tokenSymbol = IERC20Metadata(input.token).symbol();
            if(bytes(tokenSymbol).length > 13){
                tokenSymbol = _substring(tokenSymbol, 0, 13);
            }
            xymbol = string(abi.encodePacked(tokenSymbol, ': ', Strings.toString(valueUnit)));
        }

        return
            string(abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(bytes(abi.encodePacked(
                        '{"name":"',
                            string(abi.encodePacked('Upshot Swap #', Strings.toString(tokenId_))),
                        '", "description":"',
                            description,
                        '", "image": "',
                            'data:image/svg+xml;base64,',
                            Base64.encode(bytes(generateImage(input, nft, xymbol, tokenId_, pool, token))),
                        '"}'
                    )))
            ));
    }




}

// SPDX-License-Identifier: MIT
// Copyright (c) 2023 Upshot Technologies Inc. All Rights Reserved
pragma solidity 0.8.x;

struct MetadataInfo {
    string curve;
    string delta;
    string fee;
    string nftSymbol;
    uint256 nftValue;
    address token;
    string tokenSymbol;
    uint256 tokenValue;
    string admin; 
    string pool; 
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}