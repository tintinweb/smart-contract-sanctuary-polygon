/**
 *Submitted for verification at polygonscan.com on 2023-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

 
contract owned {
    address  public owner;
    address  public levelAddress;
    address  internal newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

   
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address  _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


 interface tokenInterface
 {
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
 }


contract MPOWER is owned
{
    uint public lastIDCount;
    uint public defaultRefID = 1;
    uint[11] public levelPrice;
     uint[11] public matrixPrice;
    address public tokenAddress;
    address holderContract = address(this);
    struct userInfo {
        bool joined;
        uint id;
        uint origRef;
        address referralname;
        uint levelBought;
        uint currentPool;
        address[] referral;
    }

    mapping (address => userInfo) public userInfos;
    mapping (uint => address ) public userAddressByID;

    event userIncome(address indexed useraddress,address fromUser,uint256 incomeAmt,uint level,string incomeType,uint256 levelAmt);
    event Registration(address useraddress,address referral,uint refrralId);
    event GlobalPool(address useraddress,uint256 currentpool);
    event LevelUpgrade(address useraddress,uint8 level,uint256 levelAmt);
    constructor(address token,address _levelAddress)  {
        owner = msg.sender;
        tokenAddress = token;
        levelAddress=_levelAddress;
        uint multiply = 10 ** 18;

        levelPrice[1] = (125 * multiply)/10;
        levelPrice[2] = (250 * multiply)/10;
        levelPrice[3] = (500 * multiply)/10;
        levelPrice[4] = (1000 * multiply)/10;
        levelPrice[5] = (2000 * multiply)/10;

        matrixPrice[1]=5;
        matrixPrice[2]=10;
        matrixPrice[3]=20;

 
        lastIDCount++;
        userInfos[owner].joined = true;
        userInfos[owner].id = lastIDCount;
        userInfos[owner].origRef = lastIDCount;
        userInfos[owner].referralname = address(0);
        userInfos[owner].levelBought =5;
        userInfos[owner].referral = new address[](0);
        userInfos[owner].currentPool=3;
        userAddressByID[lastIDCount] = owner;
     }

    function setTokenaddress(address newTokenaddress) onlyOwner public returns(bool)
    {
        tokenAddress = newTokenaddress;
        return true;
    }

    function setLeveladdress(address newLeveladdress) onlyOwner public returns(bool)
    {
        levelAddress = newLeveladdress;
        return true;
    }

    
    function regUser(address ref) public returns(bool)
    {
 
        address _refAddress = ref;        
        if(!userInfos[_refAddress].joined) _refAddress = owner;
        
        uint256 prc = levelPrice[1];
        tokenInterface(tokenAddress).transferFrom(msg.sender, address(this), prc);
        regUser_(msg.sender, _refAddress);
        return true;
    }

   function regUser_(address msgsender, address _refAddress) internal returns(bool)
    {
        require(!userInfos[msgsender].joined, "already joined");
   
        address origRef = _refAddress;
        uint _referrerID = userInfos[_refAddress].id;
        emit Registration(msgsender,_refAddress,_referrerID);
 
        lastIDCount++;
        userInfos[msgsender].joined = true;
        userInfos[msgsender].id = lastIDCount;
        userInfos[msgsender].origRef = userInfos[_refAddress].id;
        userInfos[msgsender].referralname = _refAddress;
        userInfos[msgsender].levelBought =1;
        userInfos[msgsender].currentPool=0;
        userInfos[msgsender].referral = new address[](0);
        emit LevelUpgrade(msgsender,1,levelPrice[1]);

        userAddressByID[lastIDCount] = msgsender;
        userInfos[origRef].referral.push(msgsender);
        userInfos[msgsender].referral.push(_refAddress);       
       
        if(userInfos[origRef].currentPool==0)
        {
            userInfos[origRef].currentPool+=1;
            emit GlobalPool(origRef,5);
        }
        else
        {
            uint256 directIncome = levelPrice[1]*40/100;    
            tokenInterface(tokenAddress).transfer(address(uint160(origRef)), directIncome);
            emit userIncome(origRef,msg.sender,directIncome,1,'DIRECT INCOME',levelPrice[1]);
        }
       //For Level Income
        uint256 levelIncome = (levelPrice[1]*18/100)/9;  
        address upline=_refAddress;
        for(uint a=2;a<=9;a++)
        {
            upline = userInfos[upline].referralname;
            if(upline != address(0))
            {
            tokenInterface(tokenAddress).transfer(address(uint160(upline)), levelIncome);
            emit userIncome(upline,msg.sender,levelIncome,a,'LEVEL INCOME',levelPrice[1]);
            }
        }

        return true;
    }

    function buyLevel(uint8 _level) public returns(bool)
    {
       
        require(_level > 1 && _level <=5, "invalid level");
        require(userInfos[msg.sender].joined, "User Not joined");
        uint prc = levelPrice[_level];
        tokenInterface(tokenAddress).transferFrom(msg.sender, address(this), prc);
        require(userInfos[msg.sender].levelBought + 1 == _level, "please buy previous level first");
        userInfos[msg.sender].levelBought = _level; 
        address _refAddress=userInfos[msg.sender].referralname;

         emit LevelUpgrade(msg.sender,_level,levelPrice[_level]);
      
        
        if(_level<=3)
        {
            if(userInfos[_refAddress].currentPool + 1 ==_level)
            {
                userInfos[_refAddress].currentPool+=1;
                emit GlobalPool(_refAddress,matrixPrice[_level]);
            }
            else{
            uint256 Refincome_ = levelPrice[_level]*40/100;    
            tokenInterface(tokenAddress).transfer(_refAddress, Refincome_);
            emit userIncome(_refAddress,msg.sender,Refincome_,1,'DIRECT INCOME',levelPrice[_level]);
            }
        }
        else
        {
                uint256 Refincome_ = levelPrice[_level]*40/100;    
                tokenInterface(tokenAddress).transfer(_refAddress, Refincome_);
                emit userIncome(_refAddress,msg.sender,Refincome_,1,'DIRECT INCOME',levelPrice[_level]);

        }
       //For Level Income
        address upline = _refAddress;
        uint256 levelIncome_ = (levelPrice[_level]*18/100)/9;  
        for(uint a=2;a<=9;a++)
        {
           
            upline=userInfos[upline].referralname;
            if(upline != address(0))
            {
            tokenInterface(tokenAddress).transfer(address(uint160(upline)), levelIncome_);
            emit userIncome(upline,msg.sender,levelIncome_,a,'LEVEL INCOME',levelPrice[_level]);
             }
        }

        return true;
    }

    function setContract(address _contract) public onlyOwner returns(bool)
    {
        holderContract = _contract;
        return true;
    }
    function payForIncome(uint256 amt,address payable msgSender) public payable {
        require(msg.sender==levelAddress,"Only Owner");
        require(userInfos[msgSender].joined, "User Not joined");
        tokenInterface(tokenAddress).transfer(msgSender, amt);
    }
       function payForIncome(address _levelAddress) public payable onlyOwner {
        levelAddress=_levelAddress;
    }
}