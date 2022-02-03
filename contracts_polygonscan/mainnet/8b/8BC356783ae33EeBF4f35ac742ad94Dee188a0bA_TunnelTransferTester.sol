//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

contract TunnelTransferTester {
    address public destinationWallet;

    function setDestinationWallet(address _wallet) external {
        destinationWallet = _wallet;
    }

    function convertWithTransferETH(uint256 deadline, string memory uref)
        external
        payable
    {
        address payable _destWalllet = payable(destinationWallet);

        (bool sent, bytes memory data) = _destWalllet.call{value: msg.value}(
            ""
        );
        require(sent, "Failed to send Ether");
    }
}