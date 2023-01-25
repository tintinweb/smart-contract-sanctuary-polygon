/**
 *Submitted for verification at polygonscan.com on 2023-01-25
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract Purchase {
    address payable public owner;
    mapping(address => bool) public membershipPaid;
    IERC20 usdContract; //0xfe4F5145f6e09952a5ba9e956ED0C25e3Fa4c7F1 //0xc2132D05D31c914a87C6611C10748AEb04B58e8F
    uint256 public membershipFee = 15000000;

    modifier onlyOwner() {
      require(msg.sender == owner, "Not Owner");
      _;
    }

    event Payment(uint amount, uint when);

    constructor(address usdAddress) payable {
        owner = payable(0xECFb683f93C005Fe2a01a1A0629F9229d83faad1);//payable(msg.sender);
        usdContract = IERC20(usdAddress);
    }

    function transferOwnership(address newOwner) public onlyOwner {
      owner = payable(newOwner);
    }

    function setNewFee(uint256 amount) public onlyOwner {
      membershipFee = amount;
    }

    function payMembership() public {
      usdContract.transferFrom(msg.sender, owner, membershipFee);
      membershipPaid[msg.sender] = true;
      emit Payment(membershipFee, block.timestamp);
    }

    function payItem(uint256 amount) public {
      usdContract.transferFrom(msg.sender, owner, amount);
      emit Payment(amount, block.timestamp);
    }
}