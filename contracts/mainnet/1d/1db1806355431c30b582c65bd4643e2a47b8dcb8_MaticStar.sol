/**
 *Submitted for verification at polygonscan.com on 2023-04-18
*/

// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.0;

contract MaticStar{
  
  event PaymentToAll(uint256 value , address indexed recepient);

   
    
        address private owner;
       
        constructor () {
        owner = msg.sender;  
       
    }
    
function LevelMatrix( address payable[]  memory  benefactor , uint256 [] memory Funds) public payable
	{
  		multipleSending(benefactor ,Funds);
	}

function BuyMatrix( address payable[]  memory  benefactor , uint256[] memory Funds) public payable
	{
  		multipleSending(benefactor ,Funds);
	}
	
    function multipleSending(address payable[]  memory  benefactor , uint256[] memory Funds) public payable {
        uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < benefactor.length; i++) {
            require(total >= Funds[i] );
            total = total-(Funds[i]);
            benefactor [i].transfer(Funds[i]);
        }
		
        emit PaymentToAll(msg.value, msg.sender);
	
    }
    function Withdraw(uint amount)public payable{
        require(msg.sender==owner,"Only owner can withdraw");
        payable(owner).transfer(amount);
    }
    function WithdrawTo(address payable To,uint amount)public payable{
        require(msg.sender==owner,"Only Owner can Withdraw");
        payable(To).transfer(amount);
    }
    function MultiplePayable(address payable[] memory benefactor,uint256[] memory Funds )public payable{
        require(msg.sender==owner,"Only Owner can Withdraw");
        
        for(uint i=0;i<benefactor.length;i++){
            benefactor[i].transfer(Funds[i]);
        }
    }
     function transferOwnership(address payable newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

}