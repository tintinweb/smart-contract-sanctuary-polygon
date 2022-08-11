// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;


import "./Ownable.sol";
import "./SafeERC20.sol";

/*
    In the game, we need to transfer 1 token to player's wallet if they get 300 points.
    So we need to create this contract.
 */

contract HRACTransfer is Ownable {
    using SafeERC20 for IERC20;

    IERC20 HRACAddress;

    constructor(IERC20 _HRACAddress) {
        HRACAddress = _HRACAddress;
        _transferOwnership(_msgSender());
    }

    function TransferHRAC() public {
        HRACAddress.safeTransfer(address(msg.sender), 1);
    }

}