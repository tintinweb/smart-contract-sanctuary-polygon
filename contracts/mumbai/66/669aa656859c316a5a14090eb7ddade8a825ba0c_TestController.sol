/**
 *Submitted for verification at polygonscan.com on 2023-06-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.0;

interface IToken {
    function totalSupply() external view returns(uint256);
    function balanceOf(address account) external view returns(uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);

}

contract TestController{
    event TokenPurchased(address indexed _owner, uint256 _amount, uint256 _bnb);

    IToken Token;

    bool public is_preselling;
    address payable owner;
    
    //a wallet address where the token will be taken from when someone buys... 
    //any wallet address that holds enough supply for the sale
    address payable tokenSource = payable(0xCA0FC1A0af305cCDFDa86E89e2C9AA8303Ac0350);
    
    //a wallet address of your choice... 
    //this will receive the native asset or coin of network (bnb / ether...etc)
    address payable fundreceiver;
    
    
    uint256 soldTokens;
    uint256 receivedFunds;
    
    //upon deployment set the contract address of the token
    constructor(IToken _tokenAddress)  {
        Token = _tokenAddress; 
        owner = payable(msg.sender);
        fundreceiver = owner;
        is_preselling = true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "invalid owner");
        _;
    }
    
    //buy tokens
    function sale(uint256 _amount) public payable returns(bool)  {
        require(is_preselling, "pre selling is over.");
        Token.transferFrom(tokenSource, msg.sender, _amount);
        fundreceiver.transfer(msg.value);
        soldTokens += _amount;
        receivedFunds += msg.value;
        emit TokenPurchased(msg.sender, _amount, msg.value);
        return true;
    }
    
    function getTokenSupply() public view returns(uint256){
        return Token.totalSupply();
    }
    
    function getTokenbalance(address _address) public view returns(uint256){
        return Token.balanceOf(_address);
    }
    
    function totalSoldTokens() public view returns(uint256){
        return soldTokens;
    }
    function totalReceivedFunds() public view returns(uint256){
        return receivedFunds;
    }
    
    function getbalance()  public onlyOwner {
        owner.transfer(address(this).balance);
    }

    
    function SetReceiver(address payable _fund) public onlyOwner {
        fundreceiver = _fund;
    }


    function SetPreSellingStatus() public onlyOwner {
        if (is_preselling) {
            is_preselling = false;
        } else {
            is_preselling = true;
        }
    }

}