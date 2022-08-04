// SPDX-License-Identifier: unlicensed
pragma solidity ^0.8.4;
 
import "./EBT.sol";
 
contract PolySwap{
    EAGLE_BATTLE token;
    address owner;
    // uint256 public rate;
 
    event TokensPurchased(
        address account,
        address token,
        uint256 amount,
        uint256 rate
    );
 
    event TokensSold(
        address account,
        address token,
        uint amount,
        uint rate
    );
 
 
    constructor(address _token) {
        token = EAGLE_BATTLE(_token);
        owner = msg.sender;
    }
 
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner is allowed");
        _;
    }
 
    function buytokens(uint256 rate) public payable {
        require(msg.sender != owner, "Token Owner can not buy");
        uint256 tokenAmount = msg.value* rate;
        uint256 tokenAmount1 = tokenAmount/100000;
        require(token.balanceOf(address(this)) >= tokenAmount1);
        token.transfer(msg.sender, tokenAmount1);
        emit TokensPurchased(msg.sender, address(token), tokenAmount, tokenAmount1);
    }
 
    function withDrawOwner(uint256 _amount)onlyOwner public returns(bool){
        payable(msg.sender).transfer(_amount);
         return true;
    }

    function sellTokens(uint _amount, uint rate) public {
        require(token.balanceOf(msg.sender) >= _amount, "low _amount");
        uint etherAmount = _amount / rate;
        uint etherAmount1 = etherAmount * 100000;
        payable(msg.sender).transfer(etherAmount1);
        require(token.approve(address(this), _amount), " approve not successed");
        require(token.transferFrom(msg.sender, address(this), _amount), " transfer not confirm");
        emit TokensSold(msg.sender, address(token), _amount, rate);
    }
 
    // function sellTokens(uint _amount, uint rate) public {
    //     require(token.balanceOf(msg.sender) >= _amount, "low _amount");
    //     uint etherAmount = _amount / rate;
    //     uint etherAmount1 = etherAmount*100000;
    //     uint256 allowance = token.allowance(msg.sender, address(this));
    //     require(allowance >= _amount, "Check the token allowance");
    //     require(address(this).balance >= etherAmount1, "low etherAmount1");
    //     token.transferFrom(msg.sender, address(this), _amount);
    //     payable(msg.sender).transfer(etherAmount1);
    //     emit TokensSold(msg.sender, address(token), _amount, rate);
    // }
}