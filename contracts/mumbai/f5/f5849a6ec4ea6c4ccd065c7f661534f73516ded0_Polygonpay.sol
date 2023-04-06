/**
 *Submitted for verification at polygonscan.com on 2023-04-05
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

abstract contract Initializable {
    bool private _initialized;
    bool private _initializing;

    modifier initializer() {
        require(
            _initializing || !_initialized,
            "Initializable: contract is already initialized"
        );

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {}

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    uint256[49] private __gap;
}

contract Polygonpay is Initializable, OwnableUpgradeable {
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

    function initialize(address _ownerAddress) public initializer {
        __Ownable_init();
        ownerWallet = _ownerAddress;
        REFERRER_1_LEVEL_LIMIT = 3;
        refCompleteDepth = 1;
        currUserID = 0;
        totalUsers = 1;
        directpercentage = 2000; //20%
        indirectpercentage = 1200; //12%
      //  adminFee = 10 * 1e18; // 10Matic
        adminFee = 33*1e13; // 10Matic

        LEVEL_PRICE[1] = 1e15; // 0.001
        LEVEL_PRICE[2] = 3e15;
        LEVEL_PRICE[3] = 9e15;
        LEVEL_PRICE[4] = 1e16;
        LEVEL_PRICE[5] = 3e16;
        LEVEL_PRICE[6] = 9e16;
        LEVEL_PRICE[7] = 9e16;
        LEVEL_PRICE[8] = 9e16;
        // LEVEL_PRICE[1] = 10 * 1e18; // 0.001
        // LEVEL_PRICE[2] = 30 * 1e18;
        // LEVEL_PRICE[3] = 90 * 1e18;
        // LEVEL_PRICE[4] = 1000 * 1e18;
        // LEVEL_PRICE[5] = 3000 * 1e18;
        // LEVEL_PRICE[6] = 9000 * 1e18;
        // LEVEL_PRICE[7] = 25000 * 1e18;
        // LEVEL_PRICE[8] = 75000 * 1e18;

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
            upgradeAmount:0
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
            upgradeAmount : 0
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

    // function nextLevelUpdate(address _referrer, uint _level) internal {
    //     address referalList = users[_referrer].referral;
    // }

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
        payable(_referrer).transfer(directAmount);
        payable(indirectRefAddr).transfer(indirectAmount);


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

        if (users[_user].levelEarningmissed[_level] > 0) {
            users[_user].earnedAmount += users[_user].levelEarningmissed[_level]/2;
            users[_user].upgradeAmount += users[_user].levelEarningmissed[_level]/2;
            users[_user].totalearnedAmount += users[_user].levelEarningmissed[
                _level
            ];
            users[_user].levelEarningmissed[_level] = 0;
        }

        bool isSend = true;
        if (!users[referer].isExist) {
            isSend = false;
        }
        if (isSend) {
            if (users[referer].currentLevel >= _level) {
                users[referer].upgradeAmount += LEVEL_PRICE[_level]/2;
                users[referer].earnedAmount += LEVEL_PRICE[_level]/2;
                users[referer].totalearnedAmount += LEVEL_PRICE[_level];
                if(users[referer].upgradeAmount >= LEVEL_PRICE[_level+1] && users[referer].currentLevel < _level+1){
                  autoupgrade(referer,_level+1);
                }
            } else {
                users[referer].levelEarningmissed[_level] += LEVEL_PRICE[
                    _level
                ];
            }


        }
    }

    function autoupgrade(address _referrer,uint256 _level) internal {
      users[_referrer].currentLevel = _level;
      payForLevel(_level, _referrer);
    }

    function claimRewards() public {
        uint256 claimAmount = users[msg.sender].earnedAmount;
        if (claimAmount > 0) {
            payable(msg.sender).transfer(claimAmount);
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

    function safeWithDrawbnb(
        uint256 _amount,
        address payable addr
    ) public onlyOwner {
        addr.transfer(_amount);
    }

    function viewUserReferral(
        address _user
    ) public view returns (address[] memory) {
        return users[_user].referral;
    }

    function viewallDirectUserReferral(
        address _user
    ) public view returns (address[] memory) {
        return users[_user].allDirect;
    }



}