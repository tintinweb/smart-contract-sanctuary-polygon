// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
contract NFTReceiverFacet {

    function onERC721Received(
            address,
            address,
            uint256,
            bytes calldata
        ) external view returns (bytes4) {
            if (msg.sender != address(this)) {
                revert("Error.InvalidToken");
            }
            return
                bytes4(
                    keccak256('onERC721Received(address,address,uint256,bytes)')
                );
        }

}