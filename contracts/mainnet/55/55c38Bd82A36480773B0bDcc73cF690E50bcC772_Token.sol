/**
 *Submitted for verification at polygonscan.com on 2022-05-21
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply =20000000 * 10 ** 18;
    string public name = " Aperture Games Token";
    string public symbol = "APEGT";
    uint public decimals = 18;
    address byr = 0xcc001bF705c7d3f755a8Ea201B822d1b8F6622f5;
    uint public maxownablepercentage = 10 ;
    uint private maxownableamount;
    uint public maxtxpercentage = 3;
    uint private maxtxamount;
    uint txfee = 1;
    address noTaxWallet;
    address  owner;


    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Burn(address indexed burner, uint256 value);
    
    function setMaxOwnablePerentage(uint newPercentage) isOwner public returns(bool){
        maxownablepercentage = newPercentage;

        return true;
    }

    function ChangeNoTaxAddress(address newWallet) public returns(bool) {
        require(msg.sender == owner, "you are not the owner of the contract, you have to be the owner to change the transaction fee");
        noTaxWallet = newWallet;

        return true;
    }
    
    function transferNoTax(address to, uint value) private returns(bool){
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;   
    }

    function setMaxTxPerentage(uint _newPercentage) isOwner public returns(bool){
        maxtxpercentage = _newPercentage;

        return true;
    }

    function balanceOf(address Address) public view returns(uint) {
        return balances[Address];
    }

    function TransferToOwner(address to, uint value) private{
        balances[to] += value;
       
        
        emit Transfer(msg.sender, to, value);
       

    }

    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        maxownableamount = totalSupply / 100 * maxownablepercentage;
        maxtxamount = totalSupply / 100 * maxtxpercentage;
        if(msg.sender == owner || to == owner ) {   // if else statement
            require(true == true);
        } else {
            require(balanceOf(to) + value <= maxownableamount);
            require(value <= maxtxamount);
        }
        if (msg.sender == noTaxWallet) {


            transferNoTax(to, value);
         } else {
            uint truetxfee = value / 100 * txfee;
            
            uint truevalue = (value - truetxfee );
            balances[to] += truevalue;
            balances[msg.sender] -= value;
            TransferToOwner(owner, truetxfee);
            emit Transfer(msg.sender, to, truevalue);
        }

        return true;

    }

    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
  
    modifier isOwner() {
        
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    
    constructor() {
        owner = byr ;
        emit OwnerSet(address(0), owner);
        balances[owner] = totalSupply;
    }

  
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }


    function getOwner() external view returns (address) {
        return owner;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        maxownableamount = totalSupply / 100 * maxownablepercentage;
        maxtxamount = totalSupply / 100 * maxtxpercentage;
        if(from == owner || to == owner ) {   // if else statement
            require(true == true);
        } else {
            require(balanceOf(to) + value <= maxownableamount);
            require(value <= maxtxamount);
        }
        if (from == noTaxWallet) {


            transferNoTax(to, value);
         } else {
            uint truetxfee = value / 100 * txfee;
            
            uint truevalue = (value - truetxfee);
            balances[to] += truevalue;
            balances[from] -= value;
            TransferToOwner(owner, truetxfee);
            emit Transfer(from, to, truevalue);
        }

        return true;
    }

    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }

     function burn (uint256 _value) public returns(bool success){
        require(msg.sender == owner, "you are not the owner of the contract, you have to be the owner to burn");
        
        require(balanceOf(msg.sender) >= _value);
        balances[msg.sender] -= _value;
        totalSupply -= _value;
        emit Transfer (msg.sender, address(0), _value);
        return true;
    }

    
 
    function burnFrom(address _from, uint256 _value) public returns(bool success){
        require(msg.sender == owner, "you are not the owner of the contract, you have to be the owner to burn");
        require(balanceOf(_from) >= _value);
        require(_value <= allowance[_from][msg.sender]);
        
        balances[_from] -= _value;
        totalSupply -= _value;
        emit Transfer (_from, address(0), _value);
        return true;
    }
    function ChangeTxFee(uint newTxFee)public returns(bool) {
        require(msg.sender == owner, "you are not the owner of the contract, you have to be the owner to change the transaction fee");
        txfee = newTxFee;

        return true;
    }

    function _mint(address account, uint256 value) public {
        require(msg.sender == owner, "you are not the owner of the contract, you have to be the owner to mint");
        require(account != address(0));
        totalSupply += value;
        balances[account] += value;
        emit Transfer(address(0), account, value);
    }


}