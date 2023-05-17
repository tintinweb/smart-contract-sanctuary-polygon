/**
 *Submitted for verification at polygonscan.com on 2023-05-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}
pragma solidity ^0.6.11;

interface PolygonPayContract {
     function users(address) external view returns (bool,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256);
}



contract MaticBank {
  using SafeMath for uint256;
  event regLevelEvent(
      address indexed _user,
      address indexed _referrer,
      uint256 _time
  );

  uint256 REFERRER_1_LEVEL_LIMIT;


  struct UserStruct {
      bool isExist;
      uint256 id;
      address userAddress;
      uint256 referrerID;
      address parentAddress;
      address[] referral;
      uint256[] childIds;
      uint256 userJoined;
   }

  mapping(uint256 => UserStruct) public users;
  mapping(address => uint256) public userList;
  mapping(address => uint256) public totalearnedAmount;
  mapping(address => address[]) public allChilds;
  mapping(address => uint256[]) public allIds;

  mapping(uint256 => bool) public userRefComplete;
  PolygonPayContract public Polygonpay;

    uint256 public currUserID;
    uint256 refCompleteDepth;
    uint256 public totalUsers;
    address public ownerWallet;
    uint256 public adminFee;
    uint256 public JoinAmount;
    uint256 public parentAmount;
    uint256 public uplineAmount;
    uint256 public totalProfit;
    address[] public joinedAddress;
    constructor() public {
        ownerWallet = address(0xF24362C2be0E2d397d0fb7D5fb4269A2DBd0b8B2);
        Polygonpay = PolygonPayContract(0x3d570Becac836Fcd3B8b619BADbBF2F13a84d1Aa);
        REFERRER_1_LEVEL_LIMIT = 2;
        currUserID = 1;
        totalUsers = 1;
        parentAmount = 5 * 1e18;
        uplineAmount = 35 * 1e18;
        adminFee = 10 * 1e18;
        JoinAmount = 50 * 1e18;
        refCompleteDepth = 1;

        UserStruct memory userStruct;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            userAddress : msg.sender,
            referrerID: 0,
            parentAddress : address(0),
            referral: new address[](0),
            childIds : new uint256[](0),
            userJoined : block.timestamp
        });
        users[currUserID] = userStruct;
        userList[msg.sender] = currUserID;
        allIds[msg.sender].push(currUserID);
    }

    function regUser(address _referrer) public payable {
       uint256 _userId = userList[msg.sender];
       uint256 _parentId = userList[_referrer];
       PolygonPayContract polygonReg = Polygonpay;
       (bool isExist ,  ,  ,  , , , , , ) = polygonReg.users(_referrer);
       require(isExist,"Referrer not exit in Polygonpay site");
       require(!users[_userId].isExist, "User Exist");
       require(users[_parentId].isExist, "Invalid referal");
       uint256 _referrerID = users[_parentId].id;
       if (users[_parentId].isExist) {
            _referrerID = users[_parentId].id;
        } else if (_referrer == address(0)) {
            _referrerID = findFirstFreeReferrer();
            refCompleteDepth = _referrerID;
        } else {
            revert("Incorrect referrer");
        }

       require(msg.value == JoinAmount, "Incorrect Value");

       if (
           users[_referrerID].referral.length >=
           REFERRER_1_LEVEL_LIMIT
       ) {
           _referrerID = users[findFreeReferrer(_referrerID)].id;
       }

       if (users[_referrerID].referral.length == REFERRER_1_LEVEL_LIMIT) {
            userRefComplete[_referrerID] = true;
        }
       UserStruct memory userStruct;
       currUserID++;
       totalUsers++;

       userStruct = UserStruct({
           isExist: true,
           id: currUserID,
           userAddress : msg.sender,
           referrerID: _referrerID,
           childIds : new uint256[](0),
           parentAddress : _referrer,
           referral: new address[](0),
           userJoined : block.timestamp
       });

       users[currUserID] = userStruct;

       uint256 parentNewId = users[_referrerID].id;
       users[parentNewId].referral.push(msg.sender);
       users[parentNewId].childIds.push(currUserID);
       joinedAddress.push(msg.sender);
       userList[msg.sender] = currUserID;
       payForUser(msg.sender);
       allChilds[_referrer].push(msg.sender);
       allIds[msg.sender].push(currUserID);
   }

   function reJoin() public payable {
       uint256 _userId = userList[msg.sender];
       require(users[_userId].isExist, "User Not exist");
       require(users[_userId].referral.length >= 2,"You are not eligible for rejoin");
       uint256 _referrerID = _userId;
       address parentAddress = users[_userId].parentAddress;
       require(msg.value == JoinAmount, "Incorrect Value");
       _referrerID = users[findFreeReferrer(_referrerID)].id;
       UserStruct memory userStruct;
       currUserID++;
       totalUsers++;
       userStruct = UserStruct({
           isExist: true,
           id: currUserID,
           userAddress : msg.sender,
           referrerID: _referrerID,
           childIds : new uint256[](0),
           parentAddress : parentAddress,
           referral: new address[](0),
           userJoined : block.timestamp
       });
       users[currUserID] = userStruct;
       uint256 parentNewId = users[_referrerID].id;
       users[parentNewId].referral.push(msg.sender);
       users[parentNewId].childIds.push(currUserID);
       joinedAddress.push(msg.sender);
       userList[msg.sender] = currUserID;
       payForUser(msg.sender);
       allIds[msg.sender].push(currUserID);
   }


   function payForUser(address _user) internal {

        // admin Amount
      payable(ownerWallet).transfer(adminFee);
      totalearnedAmount[ownerWallet] += adminFee;
      totalProfit += adminFee;

       uint256 _userId = userList[_user];
      // parent Amount
      address parent = users[_userId].parentAddress;
      if(parent == address(0)){
          parent = ownerWallet;
      }
      payable(parent).transfer(parentAmount);
      totalearnedAmount[parent] += parentAmount;
      totalProfit += parentAmount;

      // upline Amount
      address upline = users[users[_userId].referrerID].userAddress;
      if(upline == address(0)){
          upline = ownerWallet;
      }
      payable(upline).transfer(uplineAmount);
      totalearnedAmount[upline] += uplineAmount;
      totalProfit += uplineAmount;
   }

    function findFreeReferrer(uint256 _userId) public view returns(uint256) {

        if (users[_userId].referral.length < REFERRER_1_LEVEL_LIMIT) {
            return _userId;
        }
        uint256[] memory referrals = new uint256[](600);
        referrals[0] = users[_userId].childIds[0];
        referrals[1] = users[_userId].childIds[1];
        uint256 freeReferrer;
        bool noFreeReferrer = true;

        for (uint256 i = 0; i < 600; i++) {
            if (users[referrals[i]].referral.length == REFERRER_1_LEVEL_LIMIT) {
                if (i < 120) {
                    referrals[(i + 1) * 2] = users[referrals[i]].childIds[0];
                    referrals[(i + 1) * 2 + 1] = users[referrals[i]].childIds[1];
                }
            } else {
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }
        if (noFreeReferrer) {
            freeReferrer = users[findFirstFreeReferrer()].id;
            require(freeReferrer != 0);
        }
        return freeReferrer;
    }

    function findFirstFreeReferrer() public view returns(uint256) {
        for (uint256 i = refCompleteDepth; i < 500 + refCompleteDepth; i++) {
            if (!userRefComplete[i]) {
                return i;
            }
        }
    }

    function getUsersJoinedLast24Hours() external view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < totalUsers; i++) {
            if (users[i].userJoined != 0 && block.timestamp - users[i].userJoined <= 86400) {
                count++;
            }
        }
        return count;
    }


    function viewallUserIdByAddress(
        address _user
    ) public view returns (uint256[] memory) {
        return allIds[_user];
    }

    function viewallDirectAddress(
        address _user
    ) public view returns (address[] memory) {
        return allChilds[_user];
    }

    function viewChildByID(
        uint256 _userID
    ) public view returns (uint256[] memory) {
        return users[_userID].childIds;
    }

    function viewallrefferalByID(
        uint256 _userID
    ) public view returns (address[] memory) {
        return users[_userID].referral;
    }


    function emergencySafe(uint256 _amount) public {
        require(msg.sender == ownerWallet, "Not an Owner");
        payable(ownerWallet).transfer(_amount);
    }

}