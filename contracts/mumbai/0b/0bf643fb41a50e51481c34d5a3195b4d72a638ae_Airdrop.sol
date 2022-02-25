// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC20.sol";

contract Airdrop {
    address public owner;
    mapping(address => uint256) public balances;

    constructor() {
        owner = msg.sender;
    }

    function transferBatch(IERC20 _token, address[] memory _targets, uint256[] memory _amounts)  external {
        require(msg.sender == owner);
        uint256 length = _targets.length;
        require(length == _amounts.length);
        for (uint256 i = 0; i < length; i++) {
            address target = _targets[i];
            uint256 amount = _amounts[i];
            require(balances[target] == 0);
            require(_token.transfer(target, amount));
            balances[target] = amount;
        }
    }
}