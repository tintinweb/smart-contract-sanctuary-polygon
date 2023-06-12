/**
 *Submitted for verification at polygonscan.com on 2023-06-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AvocadoBridge {
    function processBridge(
        bytes32 routeId,
        uint256 sourceChainId,
        address token,
        uint256 amount,
        address to
    ) public  {
        // if (token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
        //     // Address.sendValue(to, amount);
        // } else {
        //     IERC20(token).safeTransfer(to, amount);
        // }

        emit AvoBridgeProcessed(routeId, to, sourceChainId, token, amount);
    }

    function bridge(
        bytes32 routeId,
        address avo,
        uint256 destinationChainId,
        address signer,
        address token,
        uint256 amount
    ) public payable {
        // if (bridges[routeId]) revert;
        // if (token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
        //     require(amount == msg.value, "msg.value should be equal to amount");
        // } else {
        //     IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        // }
        // bridges[routeId] = true;
        emit AvoBridge(routeId, avo, destinationChainId, signer, token, amount);
    }

    // function pause() public onlyOwner {
    //     _pause();
    // }

    // function unpause() public onlyOwner {
    //     _unpause();
    // }

    event AvoBridge(
        bytes32 indexed routeId,
        address indexed avocadoAddress,
        uint256 indexed destinationChainId,
        address signer,
        address token,
        uint256 amount
    );

    event AvoBridgeProcessed(
        bytes32 indexed routeId,
        address indexed to,
        uint256 indexed sourceChainId,
        address token,
        uint256 amount
    );
}