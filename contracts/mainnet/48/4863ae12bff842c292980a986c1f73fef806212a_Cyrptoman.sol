// SPDX-License-Identifier: Unlicensed

import "./IERC20.sol";

pragma solidity ^0.8.17;

contract Cyrptoman {
    IERC20 public usdc = IERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
    address[4] public users = [0x4266595D99Bb03EB4111ca82Ee0D5394b61e535A, 0x1b587AACAce73628ebfA0bdc9ec9bA4423c4E6e4, 0xB1Cd2E0Ea0bA010011aC614F1ED6ACBaa8ba6168, 0xC278192895aaeAC19E7BF2423D48b6589f8e0D7e];

    function distribute() external {
        uint256 _bal = usdc.balanceOf(address(this));
        usdc.transfer(users[0], _bal/6);
        usdc.transfer(users[1], _bal/6);
        _bal -= _bal/3;
        usdc.transfer(users[2], _bal/2);
        usdc.transfer(users[3], _bal/2);
    }

    function changeToken(address _new) external {
        require(msg.sender == users[0] || msg.sender == users[2], "Not Authorized");
        usdc = IERC20(_new);
    }
}