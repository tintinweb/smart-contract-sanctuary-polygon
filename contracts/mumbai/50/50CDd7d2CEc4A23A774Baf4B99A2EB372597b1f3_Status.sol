// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Token.sol';

contract Status {

    Token _token;
    mapping(address => uint256) internal balances;

    constructor(address _t) {
        _token = Token(_t);
    }

    function status(address _holder) public view returns (uint256) {
        if (balances[_holder] >= 100000 * 10 ** _token.decimals()) return 4;
        if (balances[_holder] >= 30000 * 10 ** _token.decimals()) return 3;
        if (balances[_holder] >= 5000 * 10 ** _token.decimals()) return 2;
        if (balances[_holder] >= 2500 * 10 ** _token.decimals()) return 1;

        return 0;
    }

    function balance(address _address) public view returns (uint256) {
        return balances[_address];
    }

    function put(uint256 _amount) public {
        require(_token.balanceOf(msg.sender) >= _amount);
        require(_token.allowance(msg.sender, address(this)) >= _amount);

        assert(_token.transferFrom(msg.sender, address(this), _amount));
        balances[msg.sender] += _amount;
    }

    function pick(uint256 _amount) public {
        require(balances[msg.sender] >= _amount);
        assert(_token.transfer(msg.sender, _amount));
        balances[msg.sender] -= _amount;
    }
}