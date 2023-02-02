/**
 *Submitted for verification at polygonscan.com on 2023-02-02
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Lumst {
    struct CommissionData {
       uint id;
       address Sender;
       address Receiver;
       uint commissionAmount;
    }
    uint commissionCount=0;
    mapping(uint=>CommissionData) commissionDataById;
    CommissionData[] public CommissionRecord; //Storing CommissionRecord

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    string public constant name = "Libyan university of modern science and technology";   
    string public constant symbol = "LUMST";
    uint8 public constant decimals = 18;
    address public owner;
    address public liquidityWallet = 0x9c6A295664dE416a52A245c0Ffe255d554e128B0;  // Liquidity pool wallet address
    uint256 public liquidityTaxPercentage=5;
    uint256 public burningTax = 1;

    mapping(address => uint256) balances;
    uint256 totalSupply_;
    uint constant TotalSupply=10000000000 * (10 ** uint256(decimals));
   
    constructor(address _newOwner) {
        totalSupply_ = TotalSupply;
        balances[_newOwner] = totalSupply_;
        owner=_newOwner;
        emit Transfer(address (0x0), _newOwner, totalSupply_);
    }

    function getAllCommissionData() public view returns(uint[] memory, address[] memory, address[] memory,uint[] memory){
        uint[] memory id = new uint[](commissionCount);
        address[] memory _sender = new address[](commissionCount);
        address[] memory _receiver = new address[](commissionCount);
        uint[] memory _value = new uint[](commissionCount);
        for (uint i = 0; i < commissionCount; i++) {
                CommissionData storage member = CommissionRecord[i];
                id[i] = member.id;
                _sender[i] = member.Sender;
                _receiver[i] = member.Receiver;
                _value[i] = member.commissionAmount;
            }
            return (id,_sender,_receiver,_value);
    }

    function totalSupply() public view returns (uint256) {  
       return totalSupply_;                   
    }
  
    function balanceOf(address tokenOwner) public view returns (uint) {  
       return balances[tokenOwner];         
    }

    function mintToken(address _target, uint _mintedAmount ) public {
        require(msg.sender==owner, "Unauthorized access, only owner is allowed");
        balances[_target]+=_mintedAmount;
        totalSupply_+=_mintedAmount;
        emit Transfer(address (0x0), _target, _mintedAmount);
    }

    function burnToken(address _Address, uint _token) internal {
       require(_Address!=address(0x0));
       require(_token>0);
       balances[_Address]-=_token;
       totalSupply_-=_token;
       emit Transfer(_Address, address(0x0), _token);
    }
  
    function transfer(address _to, uint256 _value) public  {
        uint liquidityTax= (_value*liquidityTaxPercentage)/100; 
        uint256 BurningTax = (burningTax*_value)/100;                               
        require(liquidityTax+_value < balances[msg.sender],"Not Enough Balance");
        require (balances[msg.sender] > _value) ;                          
        require (balances[_to] + _value > balances[_to]);                
        balances[msg.sender] -= _value;  
        balances[msg.sender]-=liquidityTax;  
        balances[liquidityWallet]+=liquidityTax; 
        emit Transfer(msg.sender,liquidityWallet,liquidityTax); 
        balances[_to] += (_value);
        emit Transfer(msg.sender,_to,_value);
        burnToken(msg.sender,BurningTax);
        commissionCount++; 
        setCommissionData(commissionCount, msg.sender, _to, liquidityTax);
    }

    function ownerBalance() public view returns(uint){
       return balances[owner];
    }

    function setCommissionData(uint _id, address sender_Address, address receiver_Address, uint _commissionAmount) internal {
        CommissionRecord.push(CommissionData({
            id:_id,
            Sender:sender_Address,
            Receiver:receiver_Address,
            commissionAmount:_commissionAmount
        }));
    }

    function setliquidityTaxPercentage(uint taxPercentage)public {
        require(msg.sender==owner,"Unauthorized access, only owner is allowed");
        require(taxPercentage!=liquidityTaxPercentage,"Kindly mentioned the new percentage value");
        require(msg.sender==owner,"Unauthorized access, only owner is allowed");
        require(taxPercentage>=1);
        require(taxPercentage<100);
        liquidityTaxPercentage = taxPercentage;
    }

    function setBurnPercentage(uint burn_percentage) public {
        require(msg.sender==owner,"Unauthorized access, only owner is allowed");
        burningTax = burn_percentage;
    }

    function setliquidityWalletAddress(address newLiquidityWallet_Address) public {
        require(msg.sender==owner,"Unauthorized access");
        require(newLiquidityWallet_Address!=address(0x0),"Invalid address");
        liquidityWallet=newLiquidityWallet_Address;
    }

    function transferOwnership(address _new_Owner) public returns (bool status) {
        require(_new_Owner != address(0x0),"Invalid Address");
        require(msg.sender == owner,"unauthorized access");
        owner = _new_Owner;
        return status = true;
    }
}