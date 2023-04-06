/**
 *Submitted for verification at polygonscan.com on 2023-04-06
*/

//https://bitcereal.com/
//https://twitter.com/BitCerealmining
//https://t.me/BitCereal
// SPDX-License-Identifier: MIT
pragma solidity 0.5.0;

interface BitCereal {
    function decimals() external view returns(uint256);
    function balanceOf(address _address) external view returns(uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Markets2 {
 address owner;
 uint256 price;
 BitCereal bitCereal;
 uint256 tokenSold;

 event sold(address buyer, uint256 amount);

 constructor (uint256 _price, address _addressContract) public {
     owner = msg.sender;
     price = _price;
    bitCereal = BitCereal(_addressContract);
 }

  modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
        return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
}

function buy(uint256 _numTokens) public payable {
    require(msg.value == mul(price, _numTokens));
    uint256 scaledAmount = mul(_numTokens, uint256(10) ** bitCereal.decimals());
    require(bitCereal.balanceOf(address(this)) >= scaledAmount);
    tokenSold += _numTokens;
    require(bitCereal.transfer(msg.sender, scaledAmount));
    emit sold(msg.sender, _numTokens);
}

function endsold() public onlyOwner {
    require(msg.sender == owner);
    require(bitCereal.transfer(owner, bitCereal.balanceOf(address(this))));
    msg.sender.transfer(address(this).balance);
}
}