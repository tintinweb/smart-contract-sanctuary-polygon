// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import {Ownable} from "./Ownable.sol";

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns(bool);
    function balanceOf(address account) external view returns (uint256);
}

contract GasLimitCheck is Ownable {
    address public token;

    constructor(address _tokenAddress) {
        token = _tokenAddress;
    }

    function checkTransfer(uint256 loops) public payable {
        bool shouldDoTransfer = false;
        for (uint256 i = 0 ; i < loops ; i++) {
            shouldDoTransfer = i % 2 == 0;
        }
        if (shouldDoTransfer) {
            IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
        }
        return;
    }
}