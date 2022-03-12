//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface ERC20Interface {
    function balanceOf(address who) external view returns (uint256);
}

contract BalanceReader {
    function allBalances(address[] memory _tokens, address _who) external view returns (uint256[] memory balances) {
        balances = new uint256[](_tokens.length);
        for (uint i = 0; i < _tokens.length; i++) {
            balances[i] = ERC20Interface(_tokens[i]).balanceOf(_who);
        }
    }
}