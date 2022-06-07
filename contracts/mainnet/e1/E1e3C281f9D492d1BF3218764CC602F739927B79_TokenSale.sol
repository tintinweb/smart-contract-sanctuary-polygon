/**
 *Submitted for verification at polygonscan.com on 2022-06-06
*/

// SPDX-License-Identifier:MIT
pragma solidity ^0.7.5;

interface myToken
{
    function balanceOf(address _address) external view returns(uint256);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function decimals() external view returns (uint8);
}

contract TokenSale
{ 
    address public owner;
    uint256 public price;
    myToken myTokenContract;

    constructor(uint256 _AddrContract)
    {
        owner=msg.sender;
        price=1000000000000000;
        myTokenContract=myToken(_AddrContract);
    }

    modifier only_owner()
    {
        require(msg.sender==owner);
        _;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256)
    {
        if(a==0)
        {
            return 0;
        }
        uint256 c=a*b;
        require((c/a)==b);
        return(c);
    }

    function buy(uint256 _numTokens) public payable
    {
        require(msg.value==mul(_numTokens,price));
        uint256 scaledAmount=mul(_numTokens,uint256(10)**myTokenContract.decimals());
        require( myTokenContract.balanceOf(address(this)) >=scaledAmount );
        require( myTokenContract.transfer(msg.sender, scaledAmount) );
        emit Sold(msg.sender,_numTokens);
    }
    
    function endSold() only_owner public
    {
        require( myTokenContract.transfer(owner, myTokenContract.balanceOf(address(this))) );
        msg.sender.transfer(address(this).balance);
    }

    event Sold(address buyer, uint256 amount);

}