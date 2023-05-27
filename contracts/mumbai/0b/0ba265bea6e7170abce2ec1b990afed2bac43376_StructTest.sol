/**
 *Submitted for verification at polygonscan.com on 2023-05-26
*/

/**
/**
*        \\                                                             //
*         \\\\\\\\                                               ////////
*          \\\\\\\\\\\\\\                                ///////////////
*           \\\\\\\\\\\\\\\\                           ////////////////
*            \\\\\\\\\\\\\\\\                         ////////////////
*             \\\\\\\\\\\\\\\\                       ////////////////
*              \\\\\\\\\\\\\\\\                     ////////////////
*               \\\\\\\\\\\\\\\\                   ////////////////
*       \\\      \\\\\\\\\\\\\\\\                 ////////////////      ///
*         \\\\\\\\\\\\\\\\\\\\\\\\               ////////////////////////
*          \\\\\\\\\\\\\\\\\\\\\\\\             ////////////////////////
*            \\\\\\\\\\\\\\\\\\\\\\\           ///////////////////////
*             \\\\\\\\\\\\\\\\\\\\\\\         ///////////////////////
*               \\\\\\\\\\\\\\\\\\\\\\       //////////////////////
*                \\\\\\\\\\\\\\    \\\\     ////    //////////////
*                  \\\\\\\\\\\\\                   /////////////
*                   \\\\\\\\\\\\\\               //////////////
*                     \\\\\\\\\\\\\             /////////////
*                      \\\\\\\\\\\\\\         //////////////
*                        \\\\\\\\\\\\\       /////////////
*                          \\\\\\\\\\\\\   //////////////
*                           \\\\\\\\\\\\\\/////////////
*                            \\\\\\\\\\\\\////////////
*                              \\\\\\\\\\\//////////
*                               \\\\\\\\\\/////////
*
*
*                     ██╗   ██╗███████╗███╗   ██╗██╗  ██╗   ██╗
*                     ██║   ██║██╔════╝████╗  ██║██║  ╚██╗ ██╔╝
*                     ██║   ██║█████╗  ██╔██╗ ██║██║   ╚████╔╝
*                     ╚██╗ ██╔╝██╔══╝  ██║╚██╗██║██║    ╚██╔╝
*                      ╚████╔╝ ███████╗██║ ╚████║███████╗██║
*                       ╚═══╝  ╚══════╝╚═╝  ╚═══╝╚══════╝╚═╝
*
*
* Copyright (C) 2020 Arkane BV (https://kbopub.economie.fgov.be/kbopub/toonondernemingps.html?lang=en&ondernemingsnummer=704738355)
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*
* SPDX-License-Identifier: MIT
*
*/

pragma solidity ^0.8.17;

contract StructTest {

    uint256 public counter;
    uint256 public tokenId;
    address public contractAddress;
    
    struct TokenIdentifier {
        address contractAddress;
        uint256 tokenId;
    }

    struct BytesUint256 {
        bytes structParam1;
        uint256 structParam2;
    }

    struct Bytes32Address {
        bytes32 structParam1;
        address structParam2;
    }

    
    function setValue(TokenIdentifier calldata tokenIdentifier) public {
        contractAddress = tokenIdentifier.contractAddress;
        tokenId = tokenIdentifier.tokenId;
    }

    function getValue(TokenIdentifier calldata tokenIdentifier) public pure returns (TokenIdentifier calldata) {
        return tokenIdentifier;   
    }

    function getValue(TokenIdentifier[] calldata tokenIdentifiers) public pure returns (TokenIdentifier[] calldata) {
        return tokenIdentifiers;   
    }

    function stringUint256(string calldata param1, uint256 param2) public pure returns (string calldata, uint256) {
        return (param1, param2);
    }
    
    function bytesUint256(bytes calldata param1, uint256 param2) public pure returns (bytes calldata, uint256) {
        return (param1, param2);
    }

    function bytesUint256StructBytes(BytesUint256 calldata param1, bytes calldata param2) public pure returns (BytesUint256 calldata, bytes calldata) {
        return (param1, param2);
    }

    function bytesUint256StructBytes32(BytesUint256 calldata param1, bytes32 param2) public pure returns (BytesUint256 calldata, bytes32) {
        return (param1, param2);
    }

    function bytes32AddressStructAddress(Bytes32Address calldata param1, address param2) public pure returns (Bytes32Address calldata, address) {
        return (param1, param2);
    }

    function writeStringUint256(string calldata param1, uint256 param2) public {
        param1;
        param2;
        counter = counter + 1;
    }
    
    function writeBytesUint256(bytes calldata param1, uint256 param2) public {
        param1;
        param2;
        counter = counter + 1;
    }

    function writeBytesUint256StructBytes(BytesUint256 calldata param1, bytes calldata param2) public {
        param1;
        param2;
        counter = counter + 1;
    }

    function writeBytesUint256StructBytes32(BytesUint256 calldata param1, bytes32 param2) public {
        param1;
        param2;
        counter = counter + 1;
    }

    function writeBytes32AddressStructAddress(Bytes32Address calldata param1, address param2) public {
        param1;
        param2;
        counter = counter + 1;
    }

}