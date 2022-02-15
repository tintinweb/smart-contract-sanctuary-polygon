/**
 *Submitted for verification at polygonscan.com on 2022-02-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IERC20 {
  function symbol() external view returns (string memory);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Bridge {
    address public owner;
    IERC20 public token;
    uint public initBlock;

    modifier restricted() {
        require(msg.sender == owner, "Restricted to owner");
        _;
    }

    event Upload(address indexed sender, uint256 amount, string target);
    event Dispense(address indexed sender, uint256 amount);
    event TransferOwnership(address indexed previousOwner, address indexed newOwner);

    function upload(uint256 amount, string memory target) public returns (bool success) {
        token.transferFrom(msg.sender, address(this), amount);
        emit Upload(msg.sender, amount, target);
        return true;
    }

    function dispense(address recipient, uint256 _amount) public restricted returns (bool success) {
        token.transfer(recipient, _amount);
        emit Dispense(recipient, _amount);
        return true;
    }

    function transferOwnership(address _newOwner) public restricted {
        require(_newOwner != address(0), "Address should not be 0x0");
        emit TransferOwnership(owner, _newOwner);
        owner = _newOwner;
    }

    function infoBundle(address user) external view returns (IERC20 tok, uint256 all, uint256 bal) {
        return (token, token.allowance(user, address(this)), token.balanceOf(user));
    }

    function getInitBlock() public view returns (uint) {
        return initBlock;
    }

    constructor(IERC20 t) {
        token = t;
        owner = msg.sender;
        initBlock = block.number;
    }
}