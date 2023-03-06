/**
 *Submitted for verification at polygonscan.com on 2023-03-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Test {
     using SafeMath for uint256;
  
     
    struct User {
        uint256 id;
        address referrer;
        mapping(uint8 => bool) levelActive;
    }


    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;

    mapping(uint8 => uint256) public levelPrice;


    uint256 public lastUserId = 2; 
    
    address public owner; 


    
    event Registration(address indexed investor, address indexed referrer, uint256 indexed investorId, uint256 referrerId);
    event ReferralReward(address  _user, address _from, uint256 reward, uint8 level, uint8 sublevel);
    event BuyNewLevel(address  _user, uint256 userId, uint8 _level, address referrer, uint256 referrerId);
        

    constructor(address ownerAddress) 
    {
        owner = ownerAddress;

        users[ownerAddress].id = 1;
        users[ownerAddress].referrer = address(0);

        idToAddress[1] = ownerAddress;

        for(uint8 i=1; i<8; i++){
            users[ownerAddress].levelActive[i]=true;
        }

        levelPrice[1]=2e18;
        levelPrice[2]=5e18;
        levelPrice[3]=10e18;
        levelPrice[4]=20e18;
        levelPrice[5]=50e18;
        levelPrice[6]=100e18;
        levelPrice[7]=200e18;
    } 
    

     function registrationExt(address referrerAddress) external payable {
        registration(msg.sender, referrerAddress);
    }  
  
    function registration(address userAddress, address referrerAddress) private 
    {
        require(!isUserExists(userAddress), "user exists!");        
        require(isUserExists(referrerAddress), "referrer not exists!");
        require(msg.value==levelPrice[1],"20 Matic Required");

        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        
        require(size == 0, "cannot be a contract!");
        
        users[userAddress].id = lastUserId;
        users[userAddress].referrer = referrerAddress;

        idToAddress[lastUserId] = userAddress;
     
        
        users[userAddress].referrer = referrerAddress;
        users[userAddress].levelActive[1]=true;
 
        lastUserId++;
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }

    function buyLevel(uint8 level) public payable
    {
        require(isUserExists(msg.sender), "user exists!");
        require(level<8, "Max 7 Level!");  
        require(users[msg.sender].levelActive[level-1],"Buy Previous Level First!");
        require(!users[msg.sender].levelActive[level],"Level Already Activated!");
        require(msg.value==levelPrice[level],"Invalid Matic Amount!");
        users[msg.sender].levelActive[level]=true;
        emit BuyNewLevel(msg.sender, users[msg.sender].id, level, users[msg.sender].referrer, users[users[msg.sender].referrer].id);
    }  

   
    function isContract(address _address) public view returns (bool _isContract)
    {
          uint32 size;
          assembly {
            size := extcodesize(_address)
          }
          return (size > 0);
    }   
 
    
    function isUserExists(address user) public view returns (bool) 
    {
        return (users[user].id != 0);
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}