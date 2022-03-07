/**
 *Submitted for verification at polygonscan.com on 2022-03-07
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

interface IERC20 {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract BulkTransfer {
    function send(
        address _token,
        address[] memory _to,
        uint256[] memory amount
    ) external {
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < _to.length; i++) {
            totalAmount += amount[i];
        }

        IERC20 token = IERC20(_token);
        token.transferFrom(msg.sender, address(this), totalAmount);
        for (uint256 i = 0; i < _to.length; i++) {
            token.transfer(_to[i], amount[i]);
        }
    }
}