/**
 *Submitted for verification at polygonscan.com on 2022-12-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract LiterDex {
    event Bought(uint256 amount);
    event Sold(uint256 amount);
    IERC20 public token;
    address onwer;
    uint256 num;
    constructor(address addr,uint256 harga) {
        token = IERC20(addr);
        onwer = msg.sender;
        num = harga ;
    }
    modifier onlyOwner() {
        require(onwer == msg.sender , "Ownable: caller is not the owner");
        _;
    }

    function buy() public payable {
        uint256 dexBalance = token.balanceOf(address(this));
        uint256 amountTobuy = msg.value * dexBalance / num ;
        require(amountTobuy > 0, "You need to send some ether");
        require(amountTobuy <= dexBalance, "Not enough tokens in the reserve");
        uint256 fee = amountTobuy * 1 / 100;
        token.transfer(msg.sender, amountTobuy - fee);
        token.transfer(onwer, fee);
        emit Bought(amountTobuy);
    }

    function sell(uint256 amount) public {
        uint256 dexBalance = token.balanceOf(address(this));
        require(amount > 0, "You need to sell at least some tokens");
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        token.transferFrom(msg.sender, address(this), amount);
        uint256 hasil = amount * num / dexBalance ;
        uint256 fee = hasil * 1 /100;
        payable(msg.sender).transfer(hasil - fee);
        payable(onwer).transfer(fee);
        emit Sold(amount);
    }

    function getprice() public view returns(uint256){
        uint256 dexBalance = token.balanceOf(address(this));
        uint256 price = 1 ether * dexBalance / num;
        return  price;
    }

    function getnum() public view returns(uint256){
        return num;
    }

    function Endliquidity() public payable onlyOwner {
    (bool os, ) = payable(onwer).call{value: address(this).balance}("");
    require(os);
    uint256 dexBalance = token.balanceOf(address(this));
    token.transfer(msg.sender, dexBalance);
    }

    function Addliquidity() public payable onlyOwner{
        require(msg.value > 0, "add value");
    }

    function setnum(uint256 _num) public onlyOwner {
    num = _num;
  }

}