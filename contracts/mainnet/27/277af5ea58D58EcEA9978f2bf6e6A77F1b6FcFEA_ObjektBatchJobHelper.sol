/**
 *Submitted for verification at polygonscan.com on 2023-04-19
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

interface IObjekt {
    function ownerOf(uint256 tokenId) external view returns (address);
    function isObjektTransferrable(uint256 tokenId) external view returns (bool);
}

contract ObjektBatchJobHelper {
    IObjekt public objekt;

    constructor(IObjekt _objekt) {
        objekt = _objekt;
    }

    /**
     * @dev 0x00 = non-transferable, 0x01 = transferable, 0x02 = not minted 
     */
    function getTokenStatusBatch(uint256[] calldata tokenIds) external view returns (bytes memory states) {
        states = new bytes(tokenIds.length);

        for (uint i = 0; i < tokenIds.length; i++) {
            try objekt.ownerOf(tokenIds[i]) returns (address) {
                bool transferable = objekt.isObjektTransferrable(tokenIds[i]);
                states[i] = bytes1(transferable ? 0x01 : 0x00);

            } catch Error(string memory) {
                states[i] = bytes1(0x02);
            }
        }
        return states;
    }
}