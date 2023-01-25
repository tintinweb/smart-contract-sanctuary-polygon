/**
 *Submitted for verification at polygonscan.com on 2023-01-25
*/

//https://bearsminers.xyz/
//https://twitter.com/BearsMiners
//https://t.me/BEARSMINERS
// SPDX-License-Identifier: MIT
pragma solidity 0.5.0;

interface BearsMiners {
    function decimals() external view returns(uint256);
    function balanceOf(address _address) external view returns(uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract CrowdfundingTokenSale {
 address owner;
 uint256 price;
 BearsMiners bearsminers;
 uint256 tokenSold;

 event sold(address buyer, uint256 amount);

 constructor (uint256 _price, address _addressContract) public {
     owner = msg.sender;
     price = _price;
     bearsminers = BearsMiners(_addressContract);
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
    uint256 scaledAmount = mul(_numTokens, uint256(10) ** bearsminers.decimals());
    require(bearsminers.balanceOf(address(this)) >= scaledAmount);
    tokenSold += _numTokens;
    require(bearsminers.transfer(msg.sender, scaledAmount));
    emit sold(msg.sender, _numTokens);
}

function endsold() public onlyOwner {
    require(msg.sender == owner);
    require(bearsminers.transfer(owner, bearsminers.balanceOf(address(this))));
    msg.sender.transfer(address(this).balance);
}
}