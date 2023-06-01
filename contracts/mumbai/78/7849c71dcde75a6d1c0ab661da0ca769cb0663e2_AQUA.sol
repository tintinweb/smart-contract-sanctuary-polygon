/**
 *Submitted for verification at polygonscan.com on 2023-05-31
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract AQUA {

    string public name = "AQUA";

    uint8 public decimals = 18;

    string public symbol = "AQUA";

    uint256 public totalSupply = 100000000 * (10 ** decimals);


    mapping(address => uint256) private balances;




    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);




    constructor() {

        balances[msg.sender] = totalSupply;

        emit Transfer(address(0), msg.sender, totalSupply);

    }




    function balanceOf(address account) public view returns (uint256) {

        return balances[account];

    }




    function transfer(address recipient, uint256 amount) public returns (bool) {

        _transfer(msg.sender, recipient, amount);

        return true;

    }


    function _transfer(address sender, address recipient, uint256 amount) private {

        require(sender != address(0), "AQUA: transfer from the zero address");

        require(recipient != address(0), "AQUA: transfer to the zero address");

        require(amount <= balances[sender], "AQUA: transfer amount exceeds balance");

        

        balances[sender] -= amount;

        balances[recipient] += amount;

        

        emit Transfer(sender, recipient, amount);

    }




    function mint(address account, uint256 amount) public {

        require(account != address(0), "AQUA: mint to the zero address");

        

        totalSupply += amount;

        balances[account] += amount;

        

        emit Transfer(address(0), account, amount);

    }

    

    function burn(uint256 amount) public {

        require(amount <= balances[msg.sender], "AQUA: burn amount exceeds balance");

        

        totalSupply -= amount;

        balances[msg.sender] -= amount;

        

        emit Transfer(msg.sender, address(0), amount);

    }

}