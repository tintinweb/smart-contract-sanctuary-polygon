/**
 *Submitted for verification at polygonscan.com on 2022-09-15
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract Dbank
{
    constructor(uint8 fee_)
    {
        owner = msg.sender; // the contract deployer
        contract_ = address(this); // this contract address (bank address)
        fee = fee_ ; // 1 fee_ = 0.01 %
        //one thousandth of the persentage of transactions saves for owner
    }
    modifier Owner(){ //khow owner (contract deployer)
        require (msg.sender == owner , "you're not owner");
        _;
    }
    modifier know(){
        require(C[msg.sender].khow , "please first sign in");
        _;
    }
    modifier locktime(){
        require(block.timestamp >= C[msg.sender].deposit_time + 86400*C[msg.sender].lock_days , 
        "after lock days you can whitdraw your balance");
        _;
    }



    struct costumer {
        address addres;
        string name;
        bytes password;
        uint bank_balance;
        uint lock_days;
        uint deposit_time;
        bool khow;
    } 


    mapping (address => costumer) public C; //costumer


    address private owner;
    address private contract_;
    uint private fee;
    bytes ddd;
    




    function signup(string memory name_,string memory password) public {
        require(check_password_safe(password),"the password not secure enter more than 4 characters");
        C[msg.sender] = costumer(msg.sender,name_,bytes(password),0,0,0,true);
    }
    function check_password_safe(string memory password) private pure returns(bool security){
        if( bytes(password).length >= 4){ return true;}
    }
    function enter_password (string memory pass) private view returns (bool suuccess) {
        bytes memory pasword = bytes(pass);
        if(pasword.length != C[msg.sender].password.length) return false;
        for(uint i=0; i < C[msg.sender].password.length; i++){
            if (pasword[i] != C[msg.sender].password[i]) return false;
        }
        return true;
    }
    function deposit_to_bank (uint amount, string memory password, uint lock_days) public payable know() returns (bool) {
        require(enter_password(password),"wrong password");
        require(msg.value == amount, "Value is over or under price.");
        C[msg.sender].bank_balance += amount;        
        if(lock_days > C[msg.sender].lock_days)C[msg.sender].lock_days = lock_days;
        C[msg.sender].deposit_time = block.timestamp;
        return true;
    }
    function whitdraw_from_bank (uint amount, string memory password) public payable know() locktime() returns (bool) {
        require(enter_password(password),"wrong password");
        require(amount <= C[msg.sender].bank_balance ,"its more than your balance");
        _withdraw(msg.sender , amount - amount/(fee*1000));
        C[msg.sender].bank_balance -= amount;
        return true;       

    }
    function bank_balance () public view returns (uint){
        return contract_.balance;
    }
    function _withdraw(address _address, uint256 _amount) private returns (bool) {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
        return true;
    }

    function change_fee (uint fee_) public Owner {
        fee = fee_;

    }
    function clime_owner () public Owner payable {
        _withdraw(owner,contract_.balance);

    }
    

}