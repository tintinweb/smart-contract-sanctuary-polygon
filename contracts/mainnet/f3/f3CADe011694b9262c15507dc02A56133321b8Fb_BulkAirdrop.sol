/**
 *Submitted for verification at polygonscan.com on 2022-06-23
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

interface IERC20{
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract BulkAirdrop {
    constructor() {}

        function bulkAirdropERC20(IERC20 _token, address[] calldata _to, uint256[] calldata _vaule) public {
            require(_to. length == _vaule.length, "Receivers and amounts are diffenrent length");
            for (uint256 i =0; i < _to.length; i++) {
                require(_token.transferFrom(msg.sender, _to[i], _vaule[i]));

            } 
        }
    
}