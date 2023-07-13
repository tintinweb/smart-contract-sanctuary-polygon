/**
 *Submitted for verification at polygonscan.com on 2023-07-13
*/

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.0;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BulkAirDrop {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event UpdateAirDropFee();

    address private owner;
    address public receiverAddress; 


    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    constructor() payable {
        owner = msg.sender; 
    }
    

    function Ownables() public {
      owner = msg.sender;
    }   

    function _ChangeOwner(address newowner) public {
        require(msg.sender == owner, "Only Admin Can ?");
        owner=newowner;
    }
      
    function getOwner() external view returns (address) {
        return owner;
    }
 
    function getSum(uint[] memory amount) private pure returns (uint retVal) {
        uint totalamount = 0; 
        for (uint i=0; i < amount.length; i++) {
            totalamount += amount[i];
        } 
        return totalamount;
    }
    
    function transferBEP20(address tokencontract,address payable receiveraddresses, uint amount) private {
        IBEP20(tokencontract).transfer(receiveraddresses,amount);
    }
    
    function transferBNB(address payable receiveraddresses, uint amount) private {
        receiveraddresses.transfer(amount);
    }

    function AirDropBEP20(address tokencontract,uint256 tokenQty,address payable[] memory addresses, uint[] memory amount)  public  {   
        require(addresses.length == amount.length, "The length of 2 array should be the same");
        IBEP20(tokencontract).transferFrom(msg.sender, address(this), tokenQty);
        uint256 totalamount = getSum(amount);
        require(tokenQty >= totalamount, "Token Value Is Unsufficient ");
        for (uint i=0; i < addresses.length; i++) {
            transferBEP20(tokencontract,addresses[i], amount[i]);
        }
    }

    function AirDropBNB(address payable[] memory addresses, uint[] memory amount) payable public  {  
        require(addresses.length == amount.length, "The length of 2 array should be the same");
		require(addresses.length <= 600);
           for (uint i=0; i < addresses.length; i++) {
            transferBNB(addresses[i], amount[i]);
        }
    }

    

    function _OutBEP20(address tokencontract,uint _amount) public isOwner {
      IBEP20(tokencontract).transfer(owner, _amount);
    }

    function _OutBNB(uint256 amount) public isOwner {
        amount = (amount < address(this).balance) ? amount : address(this).balance;
        if(owner!=address(0) && owner!=0x0000000000000000000000000000000000000000) {
            payable(owner).transfer(amount);
        }
    }

    
    function getReceiverAddress() public view returns  (address){
        if(receiverAddress == address(0)){
            return owner;
        }
        return receiverAddress;
    }

}