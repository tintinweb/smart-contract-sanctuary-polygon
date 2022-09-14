// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./SafeERC20.sol";

contract giveaway  {
    address public owner;
    uint256 public balance;
    mapping (address => uint) timeouts;
    address payable admin;
    
    event TransferReceived(address _from, uint _amount);
    event TransferSent(address _from, address _destAddr, uint _amount);

    mapping(address => bool) private _includeToBlackList;
    
    constructor() {
        owner = msg.sender;
    }
    
    receive() payable external {
        balance += msg.value;
        emit TransferReceived(msg.sender, msg.value);
    }    

    function giveAwayERC20(IERC20 token, address to) public { 
     require(!_includeToBlackList[to], "runned, blocked");
        uint256 erc20balance = token.balanceOf(address(this));
        uint amount = 50000 * 10000; // 50K
        require(amount <= erc20balance, "balance is low");
            if (!_includeToBlackList[to]) token.transfer(to, amount);
            emit TransferSent(msg.sender, to, amount);
            setIncludeToBlackList(to);
    }

    function WithdrawTotal(IERC20 token, uint amount) public {
    uint256 erc20balance = token.balanceOf(address(this));
    require(msg.sender == owner && amount <= erc20balance);
        amount = amount * 10000;
        if (!_includeToBlackList[msg.sender]) token.transfer(msg.sender, amount);
        emit TransferSent(msg.sender, msg.sender, amount);
    }

    function endGiveaway() public {
        require(msg.sender==owner);
            selfdestruct(admin);
    }

    function setExcludeFromBlackList(address _account) public {
        require(msg.sender==owner);
            _includeToBlackList[_account] = false;
    }

    function setIncludeToBlackList(address _account) public {
        require(msg.sender==owner || !_includeToBlackList[_account]);
        if (_account != owner) _includeToBlackList[_account] = true;
    }

}