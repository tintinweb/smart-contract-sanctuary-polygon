/**
 *Submitted for verification at polygonscan.com on 2023-07-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Wallet {
    address public receiver;
    string public tokenName;
    constructor (address _addr ) {
        receiver = _addr;
    }
    receive() external payable {
        
        payable(receiver).transfer(msg.value);
    }
}


contract ContractAddress
{
    address payable owner;
    uint256 Totaldeposited;
    uint256 Totalwithdrawal;
    uint256 private _salt;
    address[] public _wallets; 
    address payable _subowner;



    mapping(address => mapping (uint256 => address)) public subOwner;
    mapping (address => uint256) public subOwner1;
    
    
    constructor()  
    {
        owner = payable(msg.sender);
    }
    
    event TransferAmount(address indexed from, address indexed to, uint256 value,uint256 time);
    event TransferFromOwner(address indexed SubOwneraddress,address indexed from, address indexed to, uint256 value,uint256 time);

    modifier SubOwner()
    {
        require(msg.sender==owner || msg.sender==subOwner[owner][1]|| msg.sender==subOwner[owner][2]|| msg.sender==subOwner[owner][3]|| msg.sender==subOwner[owner][4]|| msg.sender==subOwner[owner][5], "you are not subowner");
        _;
    }

    modifier onlyOwner()
    {
        require(msg.sender==owner,"you are not owner " );
        _;
    }
    




         receive() external payable{}


     function Deposite() public payable
    {
        Totaldeposited = Totaldeposited + msg.value;
        emit TransferAmount (msg.sender,address(this),msg.value,block.timestamp);
    }


//.........................................................................onlySubowner...................................



  function createContract() external SubOwner  
  {  
    Wallet newWallet = new Wallet
    {
        salt: bytes32(++_salt)
    }(address(this));

    _wallets.push(address(newWallet));
  }
    function multisendToken( address[] calldata _contributors, uint256[] calldata _balances) external  SubOwner 
    {
        uint8 i = 0;
        for (i; i < _contributors.length; i++) {
         payable(_contributors[i]).transfer( _balances[i]);
        }
    }




//.........................................................................onlyowner...................................


    function withdrawa(uint256 amount) public onlyOwner 
    {
        require(amount <= address(this).balance , "not have Balance");
        require(amount >= 0 , "not have Balance");
        owner.transfer(amount*(10**6));
        Totalwithdrawal +=  amount;
    }

    function setSubOwner(address payable _addr)external onlyOwner {
          _subowner=_addr;
    }
    function RemoveSubOwner()external onlyOwner {
          _subowner= payable (address(0));
    }
    function SetSubOwner(address sunowner,uint256 id) public onlyOwner
    {
        require(id > 0 && id < 6 ," wrong Id");
        subOwner[msg.sender][id] = sunowner;
        subOwner1[msg.sender] = id;
    }

    function RemoveSubOwner(uint256 id) public onlyOwner
    {
        require(id > 0 && id < 6 ," wrong Id");
        subOwner[msg.sender][id] = owner;
    }

//.........................................................................Read Function..........................    

    function ChecksubOwner(uint256 _id) public view returns(address _subOwner)
    {
        //require(_id <= 5 && _id > 0,"wrong id");
        return subOwner[owner][_id];
    }

    function CheckTotalwithdrawal() public view  returns(uint256)
    {
        return  Totalwithdrawal;
    }
    
    function CheckTotaldeposited() public view  returns(uint256)
    {
        return  Totaldeposited;
    }
    
    function CheckBalance(address account) public view  returns(uint256)
    {
        return  address(account).balance;
    }

    
    function CheckContractBalance() public view  returns(uint256)
    {
        return  address(this).balance;
    }    

   function last_generated_address() public view returns(address){
       uint256 a = (_wallets.length)-1;
       return _wallets[a];
   }



}