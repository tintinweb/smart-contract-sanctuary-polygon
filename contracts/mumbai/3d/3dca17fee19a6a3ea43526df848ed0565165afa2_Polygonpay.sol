/**
 *Submitted for verification at polygonscan.com on 2023-04-10
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

// File: @openzeppelin/contracts/GSN/Context.sol

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns(address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns(bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns(address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Polygonpay is  Ownable {
    using SafeMath for uint256;
    event regLevelEvent(
        address indexed _user,
        address indexed _referrer,
        uint256 _time
    );
    event buyLevelEvent(address indexed _user, uint256 _level, uint256 _time);

    mapping(uint256 => uint256) public LEVEL_PRICE;
    uint256 REFERRER_1_LEVEL_LIMIT;

    uint256 directpercentage;
    uint256 indirectpercentage;

    struct UserStruct {
        bool isExist;
        uint256 id;
        uint256 referrerID;
        uint256 currentLevel;
        uint256 earnedAmount;
        uint256 totalearnedAmount;
        address[] referral;
        address[] allDirect;
        uint256 childCount;
        uint256 upgradeAmount;
        uint256 upgradePending;
        mapping(uint256 => uint256) levelEarningmissed;
    }

    mapping(address => UserStruct) public users;

    mapping(uint256 => address) public userList;

    uint256 public currUserID;
    uint256 refCompleteDepth;
    uint256 public totalUsers;
    address public ownerWallet;
    uint256 public adminFee;
    address[] public joinedAddress;


      constructor(
          address _ownerAddress
    ) public {
        ownerWallet = _ownerAddress;
        REFERRER_1_LEVEL_LIMIT = 3;
        refCompleteDepth = 1;
        currUserID = 0;
        totalUsers = 1;
        directpercentage = 2000; //20%
        indirectpercentage = 1200; //12%
        adminFee = 10 * 1e18; // 10Matic
    
        LEVEL_PRICE[1] = 10 * 1e18; // 10Matic
        LEVEL_PRICE[2] = 30 * 1e18;
        LEVEL_PRICE[3] = 90 * 1e18;
        LEVEL_PRICE[4] = 1000 * 1e18;
        LEVEL_PRICE[5] = 3000 * 1e18;
        LEVEL_PRICE[6] = 9000 * 1e18;
        LEVEL_PRICE[7] = 25000 * 1e18;
        LEVEL_PRICE[8] = 75000 * 1e18;

        UserStruct memory userStruct;
        currUserID = 1000000;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: 0,
            currentLevel: 8,
            earnedAmount: 0,
            totalearnedAmount: 0,
            referral: new address[](0),
            allDirect : new address[](0),
            childCount: 0,
            upgradeAmount:0,
            upgradePending : 0
        });

        users[ownerWallet] = userStruct;
        users[ownerWallet].levelEarningmissed[1] = 0;
        users[ownerWallet].levelEarningmissed[2] = 0;
        users[ownerWallet].levelEarningmissed[3] = 0;
        users[ownerWallet].levelEarningmissed[4] = 0;
        users[ownerWallet].levelEarningmissed[5] = 0;
        users[ownerWallet].levelEarningmissed[6] = 0;
        users[ownerWallet].levelEarningmissed[7] = 0;
        users[ownerWallet].levelEarningmissed[8] = 0;
        userList[currUserID] = ownerWallet;
    }

    function random(uint256 number) public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        msg.sender
                    )
                )
            ) % number;
    }

    function regUser(address _referrer) public payable {
        require(!users[msg.sender].isExist, "User exist");
        require(users[_referrer].isExist, "Invalid referal");

        uint256 _referrerID = users[_referrer].id;

        require(msg.value == LEVEL_PRICE[1] * 3, "Incorrect Value");

        if (
            users[userList[_referrerID]].referral.length >=
            REFERRER_1_LEVEL_LIMIT
        ) {
            _referrerID = users[findFreeReferrer(userList[_referrerID])].id;
        }

        UserStruct memory userStruct;
        currUserID = random(1000000);
        totalUsers++;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: _referrerID,
            earnedAmount: 0,
            totalearnedAmount: 0,
            referral: new address[](0),
            allDirect: new address[](0),
            currentLevel: 1,
            childCount: 0,
            upgradeAmount : 0,
            upgradePending : 0
        });

        users[msg.sender] = userStruct;
        users[msg.sender].levelEarningmissed[2] = 0;
        users[msg.sender].levelEarningmissed[3] = 0;
        users[msg.sender].levelEarningmissed[4] = 0;
        users[msg.sender].levelEarningmissed[5] = 0;
        users[msg.sender].levelEarningmissed[6] = 0;
        users[msg.sender].levelEarningmissed[7] = 0;
        users[msg.sender].levelEarningmissed[8] = 0;
        userList[currUserID] = msg.sender;
        users[userList[_referrerID]].referral.push(msg.sender);
        joinedAddress.push(msg.sender);
        users[_referrer].allDirect.push(msg.sender);
        users[_referrer].childCount = users[_referrer].childCount.add(1);
        payReferal(_referrer);
        payForLevel(1,msg.sender);
        emit regLevelEvent(msg.sender, userList[_referrerID], now);
    }

    function payReferal(address _referrer) internal {
        uint256 indirectRefId = users[_referrer].referrerID;
        address indirectRefAddr = userList[indirectRefId];
        if (indirectRefAddr == 0x0000000000000000000000000000000000000000) {
            indirectRefAddr = ownerWallet;
        }
        uint256 levelPrice = LEVEL_PRICE[1] * 3;
        uint256 directAmount = (levelPrice* directpercentage) / 10000;
        uint256 indirectAmount = (levelPrice * indirectpercentage) / 10000;
        payable(ownerWallet).transfer(adminFee);
        users[ownerWallet].totalearnedAmount += adminFee;

        if(users[_referrer].currentLevel >= 8){
          users[_referrer].upgradeAmount += directAmount/2;
          users[_referrer].earnedAmount += directAmount/2;
        }else{
          users[_referrer].earnedAmount += directAmount;
        }

        if(users[_referrer].currentLevel >= 8){
          users[indirectRefAddr].upgradeAmount += indirectAmount/2;
          users[indirectRefAddr].earnedAmount += indirectAmount/2;
        }else{
          users[indirectRefAddr].earnedAmount += indirectAmount;
        }
    }

    function payForLevel(uint256 _level, address _user) internal {
        address referer;
        address referer1;
        address referer2;
        address referer3;
        if (_level == 1 || _level == 5) {
            referer = userList[users[_user].referrerID];
        } else if (_level == 2 || _level == 6) {
            referer1 = userList[users[_user].referrerID];
            referer = userList[users[referer1].referrerID];
        } else if (_level == 3 || _level == 7) {
            referer1 = userList[users[_user].referrerID];
            referer2 = userList[users[referer1].referrerID];
            referer = userList[users[referer2].referrerID];
        } else if (_level == 4 || _level == 8) {
            referer1 = userList[users[_user].referrerID];
            referer2 = userList[users[referer1].referrerID];
            referer3 = userList[users[referer2].referrerID];
            referer = userList[users[referer3].referrerID];
        }
        uint256 upgradedAmount = 0;
        if(users[msg.sender].upgradePending >= LEVEL_PRICE[_level]){
          upgradedAmount = LEVEL_PRICE[_level];
          users[msg.sender].upgradePending -= LEVEL_PRICE[_level];
          users[msg.sender].currentLevel =  _level;
        }else{
          upgradedAmount = users[msg.sender].upgradePending;
        }

        if (users[_user].levelEarningmissed[_level] > 0 && users[msg.sender].currentLevel >= _level) {
            users[_user].earnedAmount += users[_user].levelEarningmissed[_level]/2;
            users[_user].upgradeAmount += users[_user].levelEarningmissed[_level]/2;
            users[_user].levelEarningmissed[_level] = 0;
        }

        bool isSend = true;
        if (!users[referer].isExist) {
            isSend = false;
        }
        if (isSend) {
            if (users[referer].currentLevel >= _level) {
                if(users[referer].currentLevel < 8){
                  if(_level == 1){
                    users[referer].upgradeAmount += LEVEL_PRICE[_level];
                  }else{
                    users[referer].upgradeAmount += upgradedAmount/2;
                    users[referer].earnedAmount += upgradedAmount/2;
                  }
                }else{
                  users[referer].earnedAmount += upgradedAmount;
                }
            } else {
                users[referer].levelEarningmissed[_level] += upgradedAmount;
            }
        }else{
          users[ownerWallet].earnedAmount += LEVEL_PRICE[_level];
        }
    }

    function upgradeNextLevel() public {
      require(users[msg.sender].upgradeAmount >= 0,"Insufficient amount");
      uint256 currentLevel = users[msg.sender].currentLevel;
      uint256 nextLevel = currentLevel+1;
      if(nextLevel <= 8){
        users[msg.sender].upgradePending += users[msg.sender].upgradeAmount;
        users[msg.sender].upgradeAmount = 0;
        payForLevel(nextLevel, msg.sender);
      }
    }

    function claimRewards() public {
        uint256 claimAmount = users[msg.sender].earnedAmount;
        if (claimAmount > 0) {
            require(users[msg.sender].upgradeAmount == 0 || users[msg.sender].currentLevel >= 8,"Upgrade first then process claim");
            payable(msg.sender).transfer(claimAmount);
            users[msg.sender].totalearnedAmount += claimAmount;
            users[msg.sender].earnedAmount = 0;
        }
    }

    function findFreeReferrer(address _user) public view returns (address) {
        if (users[_user].referral.length < REFERRER_1_LEVEL_LIMIT) {
            return _user;
        }
        address[] memory referrals = new address[](600);
        referrals[0] = users[_user].referral[0];
        referrals[1] = users[_user].referral[1];
        referrals[2] = users[_user].referral[2];
        address freeReferrer;
        bool noFreeReferrer = true;

        for (uint256 i = 0; i < 600; i++) {
            if (users[referrals[i]].referral.length == REFERRER_1_LEVEL_LIMIT) {
                if (i < 120) {
                    referrals[(i + 1) * 3] = users[referrals[i]].referral[0];
                    referrals[(i + 1) * 3 + 1] = users[referrals[i]].referral[
                        1
                    ];
                    referrals[(i + 1) * 3 + 2] = users[referrals[i]].referral[
                        2
                    ];
                }
            } else {
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }
        require(!noFreeReferrer, "No Free Referrer");
        return freeReferrer;
    }

    function viewUserReferral(
        address _user
    ) public view returns (address[] memory) {
        return users[_user].referral;
    }

    function getmissedvalue(address _userAddress, uint256 _level)
    public
    view
    returns(uint256)
    {
        return users[_userAddress].levelEarningmissed[_level];
    }

    function viewallDirectUserReferral(
        address _user
    ) public view returns (address[] memory) {
        return users[_user].allDirect;
    }
}