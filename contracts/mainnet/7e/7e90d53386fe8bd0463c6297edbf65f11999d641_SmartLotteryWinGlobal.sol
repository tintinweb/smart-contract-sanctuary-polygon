/**
 *Submitted for verification at polygonscan.com on 2023-05-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract SmartLotteryWinGlobal {
    using SafeMath for uint256;
    address payable public contractOwner;
    uint public BASIC_PRICE;
    uint public LEVEL_PRICE;
    uint public ADMIN_FEE;
    uint public POOL_FEE;
    
    bool public _tradingOpen = false;
    uint[] public depositors;
    uint8[2] internal selectedDepositors;
    uint256 public lastDraw;
    uint256 public totalPoolCollection;
    uint256 public overflowCollection;
    uint256 public monthlyPoolCollection;
    uint256 public totalTicketsPurchased; 
    uint256 public cappingLimit;
    

     struct User {
        uint id;
        address referrer;
        uint partnersCount;
        uint activePartnersCount;
        uint totalTeamCount;
        uint poolBonus;
        uint levelBonus;
        uint superBonus;
        uint x3Earnings;
        uint x6Earnings;
        uint withdrawn;
        
        mapping(uint8 => bool) activeX3Levels;
        mapping(uint8 => bool) activeX6Levels;
        
        mapping(uint8 => X3) x3Matrix;
        mapping(uint8 => X6) x6Matrix;
    }

    struct UserRecord {
        uint star2Bonus;
        uint poolBonus;
        uint levelBonus;
        uint superBonus;
        uint x3Bonus;
        uint x6Bonus;
    }

     struct X3 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint members;
        uint reinvestCount;
    }
    
    struct X6 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        uint members;
        bool blocked;
        uint reinvestCount;

        address closedPart;
    }

    uint8 public LAST_LEVEL;
    uint40[30] public LEVEL_INCOME;
    uint8[4] public SUPER_SPONSER_INCOME;
    
    mapping(address => User) public users;
    mapping(address => UserRecord) public usersRecord;
    
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
    mapping(address => uint) public balances; 

    uint public lastUserId;
    address public id1;    
    mapping(uint8 => uint) public levelPrice;

    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event EnterIntoPool(uint256 indexed user_id);
    event PoolReward(address indexed user, uint _amount, uint collection);
    event MatchPayout(address indexed to, address indexed from, uint256 _amount);
    event SuperSponsorPayout(address indexed to, address indexed from, uint256 _amount);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
    event Withdrawn(address indexed user, uint _amount);
    

    constructor(address payable owner) public {
        contractOwner = owner;
        address _ownerAddress = contractOwner;

        BASIC_PRICE = 10e18; 
        LAST_LEVEL = 10;
        ADMIN_FEE = 1e18;
        LEVEL_PRICE = 2e18;
        POOL_FEE = 5e18;
        cappingLimit = 50000e18;
        
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            levelPrice[i] = LEVEL_PRICE;
        }

        LEVEL_INCOME = [20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5];
        SUPER_SPONSER_INCOME = [20, 15, 10, 5];

        id1 = _ownerAddress;

        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0),
            activePartnersCount: uint(0),
            totalTeamCount: uint(0),
            poolBonus: uint(0),
            levelBonus: uint(0),
            superBonus: uint(0),
            x3Earnings: uint(0),
            x6Earnings: uint(0),
            withdrawn: uint(0)
        });
        
        users[_ownerAddress] = user;
        idToAddress[1] = _ownerAddress;

        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[_ownerAddress].activeX3Levels[i] = true;
            users[_ownerAddress].activeX6Levels[i] = true;
        }
        
        userIds[1] = _ownerAddress;
        lastUserId = 2;
    }

    modifier onlyContractOwner() { 
        require(msg.sender == contractOwner, "onlyOwner"); 
        _; 
    }

    receive() external payable {}

    fallback() external {
        if(msg.data.length == 0) {
            return registration(msg.sender, id1);
        }
        
        registration(msg.sender, bytesToAddress(msg.data));
    }

    function registrationExt(address referrerAddress) external {
        registration(msg.sender, referrerAddress);
    }

    function buyNewLevel(uint8 level) external payable {
        _buyNewLevel(msg.sender, level);
    }

    function RegisterBy(address _userAddress, address referrerAddress) external onlyContractOwner {
        registration(_userAddress, referrerAddress);
    }

    function isInPool(uint user_id) public view returns (bool) {
        for (uint i = 0; i < depositors.length; i++) {
            if (depositors[i] == user_id) {
                return true;
            }
        }
        return false;
    }

    function _buyNewLevel(address _userAddress, uint8 level) internal {
        require(_tradingOpen == true, "Registration phase is going on");
        require(isUserExists(_userAddress), "user is not exists. Register first.");

        require(msg.value >= BASIC_PRICE, "Lottery ticket price is 10 Matic");
        require(level >= 1 && level <= LAST_LEVEL, "invalid level");
        require(!users[_userAddress].activeX3Levels[level], "level already activated");

        if(level > 1) {
            require(users[_userAddress].activeX3Levels[level-1], "buy previous level first");

            if (users[_userAddress].x3Matrix[level-1].blocked) {
                users[_userAddress].x3Matrix[level-1].blocked = false;
            }
        }

        address freeX3Referrer = findFreeX3Referrer(_userAddress, level);
        users[_userAddress].x3Matrix[level].currentReferrer = freeX3Referrer;
        users[_userAddress].activeX3Levels[level] = true;

        totalTicketsPurchased++;

        updateX3Referrer(_userAddress, freeX3Referrer, level);
        emit Upgrade(_userAddress, freeX3Referrer, 1, level);
        
        require(!users[_userAddress].activeX6Levels[level], "level already activated");

        if(level > 1) {
            require(users[_userAddress].activeX6Levels[level-1], "buy previous level first");

            if (users[_userAddress].x6Matrix[level-1].blocked) {
                users[_userAddress].x6Matrix[level-1].blocked = false;
            }
        }

        address freeX6Referrer = findFreeX6Referrer(_userAddress, level);
        users[_userAddress].activeX6Levels[level] = true;
        
        updateX6Referrer(_userAddress, freeX6Referrer, level);
        
        emit Upgrade(_userAddress, freeX3Referrer, 2, level);

        if(level == 1) {
            address _upline = users[_userAddress].referrer;
            users[_upline].activePartnersCount++;
        }

        address feeReceiver = findFreeX3Referrer(_userAddress, LAST_LEVEL);

        if(feeReceiver == address(0)) {
            contractOwner.transfer(ADMIN_FEE);
        } else {
            payable(feeReceiver).transfer(ADMIN_FEE);
            usersRecord[feeReceiver].star2Bonus = usersRecord[feeReceiver].star2Bonus.add(ADMIN_FEE); //2 star bonus
        }
        
        distribute_pool_award(users[_userAddress].id, POOL_FEE);
    }

    function registration(address userAddress, address referrerAddress) private {
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");

        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }

        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0,
            activePartnersCount: 0,
            totalTeamCount: 0,
            poolBonus: 0,
            levelBonus: 0,
            superBonus: 0,
            x3Earnings: 0,
            x6Earnings: 0,
            withdrawn: 0
        });

        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;

        users[userAddress].referrer = referrerAddress;

        userIds[lastUserId] = userAddress;
        lastUserId++;

        users[referrerAddress].partnersCount++;
        address _uplines = users[userAddress].referrer;

        for (uint8 i = 1; i < LEVEL_INCOME.length; i++) {
            if(_uplines == address(0)) break;
            users[_uplines].totalTeamCount++;

             _uplines = users[_uplines].referrer;
        }

        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }

    function distribute_pool_award(uint256 _userID, uint256 _amount) private {
        depositors.push(_userID);
        emit EnterIntoPool(_userID);

        uint256 totalCollection = monthlyPoolCollection + _amount;

        if(totalCollection > cappingLimit) {
            overflowCollection = overflowCollection.add(_amount);
        } else {
            monthlyPoolCollection = monthlyPoolCollection.add(_amount);
        }

        totalPoolCollection = totalPoolCollection.add(_amount);

        if(block.timestamp >= lastDraw + 720 hours) {
            lastDraw = block.timestamp;
            drawPool(); 
        }
    }


    function drawPool() private {
        uint256 lotteryPrice = monthlyPoolCollection * 10 / 100;
        for(uint8 i = 0; i <= 1; i++) {
            if (idToAddress[selectedDepositors[i]] == address(0)) break;
            users[idToAddress[selectedDepositors[i]]].poolBonus = users[idToAddress[selectedDepositors[i]]].poolBonus.add(lotteryPrice);
            usersRecord[idToAddress[selectedDepositors[i]]].poolBonus = usersRecord[idToAddress[selectedDepositors[i]]].poolBonus.add(lotteryPrice);
            emit PoolReward(idToAddress[selectedDepositors[i]], lotteryPrice, monthlyPoolCollection);
            distributeLevelIncome(idToAddress[selectedDepositors[i]], lotteryPrice);
            distributeSuperBonus(idToAddress[selectedDepositors[i]], lotteryPrice);
        }
        monthlyPoolCollection = 0;

        if(overflowCollection > 0) { 
            if(overflowCollection > cappingLimit) {
                overflowCollection = overflowCollection.sub(cappingLimit); 
                monthlyPoolCollection = monthlyPoolCollection.add(cappingLimit); 
            } else {
                monthlyPoolCollection = monthlyPoolCollection.add(overflowCollection);
                overflowCollection = 0;
            }   
        }
        depositors = new uint256[](0);
    }

    function selectedDepositorsArr(uint8[2] memory _selected_depositors) external onlyContractOwner{
        for(uint8 i = 0; i <= 1; i++) {
            selectedDepositors[i] = _selected_depositors[i];
        }
    }

    function distributeLevelIncome(address _userAddress, uint256 _amount) private {
        address up = users[_userAddress].referrer;
        for(uint8 i = 0; i < LEVEL_INCOME.length; i++) {
            if (up == address(0)) break;
            
            bool is_in_pool = isInPool(users[up].id);
            if(users[up].activeX3Levels[2] || is_in_pool) {
                uint256 bonus = _amount * LEVEL_INCOME[i] / 100;
                users[up].levelBonus = users[up].levelBonus.add(bonus);
                usersRecord[up].levelBonus = usersRecord[up].levelBonus.add(bonus);
                emit MatchPayout(up, _userAddress, bonus);
            }
            up = users[up].referrer;
        }
    }

    function distributeSuperBonus(address _userAddress, uint256 _amount) private {
        uint i = 0;

        address up = users[_userAddress].referrer;
        
        while (true) {
            if (up == address(0)) break;
            
            if ( (users[up].activeX3Levels[LAST_LEVEL] && users[up].activePartnersCount >= 20 )) {
                if(i <= 3) {
                    uint256 bonus = _amount * SUPER_SPONSER_INCOME[i] / 100;
                    users[up].superBonus = users[up].superBonus.add(bonus);
                    usersRecord[up].superBonus = usersRecord[up].superBonus.add(bonus);
                    emit SuperSponsorPayout(up, _userAddress, bonus);
                }

                if(i == 4) {
                  break;
                }

                i++;
            }
            up = users[up].referrer;
        }
    }


    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function withdraw() public {
        User storage user = users[msg.sender];
        uint256 totalAmount;
        //Super Bonus
        uint256 superBonus = user.superBonus;
        if (superBonus > 0) {
            user.superBonus = 0;
            totalAmount = totalAmount.add(superBonus);
        }

        //Pool Bonus
        uint256 poolBonus = user.poolBonus;
        if (poolBonus > 0) {
            user.poolBonus = 0;
            totalAmount = totalAmount.add(poolBonus);
        }

        //Level Bonus
        uint256 levelBonus = user.levelBonus;
        if (levelBonus > 0) {
            user.levelBonus = 0;
            totalAmount = totalAmount.add(levelBonus);
        }

        require(totalAmount > 0, "User has no dividends");

        uint256 contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }

        user.withdrawn = user.withdrawn.add(totalAmount);
        msg.sender.transfer(totalAmount);
        emit Withdrawn(msg.sender, totalAmount);
    }

    function updateX3Referrer(address userAddress, address referrerAddress, uint8 level) private {
        users[referrerAddress].x3Matrix[level].members++;
        users[referrerAddress].x3Matrix[level].referrals.push(userAddress);

        if (users[referrerAddress].x3Matrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length));
            return sendETHDividends(referrerAddress, userAddress, 1, level);
        }
        
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3);
        users[referrerAddress].x3Matrix[level].referrals = new address[](0);

        if (referrerAddress != id1) {
            address freeReferrerAddress = findFreeX3Referrer(referrerAddress, level);
            if (users[referrerAddress].x3Matrix[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].x3Matrix[level].currentReferrer = freeReferrerAddress;
            }
            
            users[referrerAddress].x3Matrix[level].reinvestCount++;
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
            updateX3Referrer(referrerAddress, freeReferrerAddress, level);

        } else {
            sendETHDividends(id1, userAddress, 1, level);
            users[id1].x3Matrix[level].reinvestCount++;
            emit Reinvest(id1, address(0), userAddress, 1, level);
        }
    }

    function updateX6Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeX6Levels[level], "500. Referrer level is inactive");
        users[referrerAddress].x6Matrix[level].members++;
        
        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].firstLevelReferrals.length));
            
            users[userAddress].x6Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == id1) {
                return sendETHDividends(referrerAddress, userAddress, 2, level);
            }
            
            address ref = users[referrerAddress].x6Matrix[level].currentReferrer;            
            users[ref].x6Matrix[level].secondLevelReferrals.push(userAddress); 
            
            uint len = users[ref].x6Matrix[level].firstLevelReferrals.length;
            
            if ((len == 2) && 
                (users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 3);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 4);
                }
            } else if (len == 2 && users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }

            return updateX6ReferrerSecondLevel(userAddress, ref, level);
        }
        
        users[referrerAddress].x6Matrix[level].secondLevelReferrals.push(userAddress);

        if (users[referrerAddress].x6Matrix[level].closedPart != address(0)) {
            if ((users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]) &&
                (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].x6Matrix[level].closedPart)) {

                updateX6(userAddress, referrerAddress, level, true);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].x6Matrix[level].closedPart) {
                updateX6(userAddress, referrerAddress, level, true);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else {
                updateX6(userAddress, referrerAddress, level, false);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            }
        }

        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[1] == userAddress) {
            updateX6(userAddress, referrerAddress, level, false);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
        } else if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == userAddress) {
            updateX6(userAddress, referrerAddress, level, true);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
        }
        
        if (users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length <= 
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length) {
            updateX6(userAddress, referrerAddress, level, false);
        } else {
            updateX6(userAddress, referrerAddress, level, true);
        }
        
        updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
    }

    function updateX6(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        if (!x2) {
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[0], 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 2 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length));
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[1], 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 4 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length));
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[1];
        }
    }
    
    function updateX6ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if (users[referrerAddress].x6Matrix[level].secondLevelReferrals.length < 4) {
            return sendETHDividends(referrerAddress, userAddress, 2, level);
        }
        
        address[] memory x6 = users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].firstLevelReferrals;
        
        if (x6.length == 2) {
            if (x6[0] == referrerAddress ||
                x6[1] == referrerAddress) {
                users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].closedPart = referrerAddress;
            } else if (x6.length == 1) {
                if (x6[0] == referrerAddress) {
                    users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].closedPart = referrerAddress;
                }
            }
        }
        
        users[referrerAddress].x6Matrix[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].x6Matrix[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].x6Matrix[level].closedPart = address(0);

        users[referrerAddress].x6Matrix[level].reinvestCount++;
        
        if (referrerAddress != id1) {
            address freeReferrerAddress = findFreeX6Referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            updateX6Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(id1, address(0), userAddress, 2, level);
            sendETHDividends(id1, userAddress, 2, level);
        }
    }
    
    function findFreeX3Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX3Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }

    function findFreeX6Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX6Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
        
    function usersActiveX3Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX3Levels[level];
    }

    function usersActiveX6Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX6Levels[level];
    }

    function usersX3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool, uint) {
        return (users[userAddress].x3Matrix[level].currentReferrer,
                users[userAddress].x3Matrix[level].referrals,
                users[userAddress].x3Matrix[level].blocked,
                users[userAddress].x3Matrix[level].reinvestCount);
    }

    function usersX6Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool, address, uint) {
        return (users[userAddress].x6Matrix[level].currentReferrer,
                users[userAddress].x6Matrix[level].firstLevelReferrals,
                users[userAddress].x6Matrix[level].secondLevelReferrals,
                users[userAddress].x6Matrix[level].blocked,
                users[userAddress].x6Matrix[level].closedPart,
                users[userAddress].x6Matrix[level].reinvestCount);
    }

    function usersInfo(address userAddress, uint8 level) public view returns(uint, uint) {
        return (users[userAddress].x3Matrix[level].members,
                users[userAddress].x6Matrix[level].members);
    }

    function findEthReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 1) {
            while (true) {
                if (users[receiver].x3Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 1, level);
                    isExtraDividends = true;
                    receiver = users[receiver].x3Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } else {
            while (true) {
                if (users[receiver].x6Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 2, level);
                    isExtraDividends = true;
                    receiver = users[receiver].x6Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
    }

    function sendETHDividends(address userAddress, address _from, uint8 matrix, uint8 level) private {
        (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, matrix, level);

        payable(receiver).transfer(levelPrice[level]);

        if(matrix == 1) {
            users[receiver].x3Earnings = users[receiver].x3Earnings.add(levelPrice[level]);
            usersRecord[receiver].x3Bonus = usersRecord[receiver].x3Bonus.add(levelPrice[level]);
        } else {
            users[receiver].x6Earnings = users[receiver].x6Earnings.add(levelPrice[level]);
            usersRecord[receiver].x6Bonus = usersRecord[receiver].x6Bonus.add(levelPrice[level]);
        }
        
        if (isExtraDividends) {
            emit SentExtraEthDividends(_from, receiver, matrix, level);
        }
    }

    function countDepositors() view external returns (uint256) {
        return depositors.length;
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
    
    function withdraw(uint256 _amount) public onlyContractOwner {
        contractOwner.transfer(_amount);
    }

    function updateLevels(uint8 _levelsLength, uint _amount) public onlyContractOwner {
        LAST_LEVEL = _levelsLength;

        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            levelPrice[i] = _amount;
            users[contractOwner].activeX3Levels[i] = true;
            users[contractOwner].activeX6Levels[i] = true;
        }
    }

    function startTrading() external onlyContractOwner {
        _tradingOpen = true;
        lastDraw = block.timestamp;
    }

    function radishTrading() external onlyContractOwner {
        _tradingOpen = false;
    }
}