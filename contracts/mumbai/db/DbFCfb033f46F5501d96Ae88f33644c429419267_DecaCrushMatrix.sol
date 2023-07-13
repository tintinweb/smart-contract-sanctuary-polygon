// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DecaCrushMatrix {
    address public ownerWallet;
    address public devAddress;
    using SafeMath for uint256;
    IERC20 decacrush = IERC20(0xe38597dF6458004e874b5de985666EF8Eed0A344);

    struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
        address[] referral;
        mapping(uint256 => uint256) noOfPayments;
        uint256 cycle;
        uint256 initialId;
        uint256 earning;
    }

    struct UserEarning {
        address referrer;
        uint256 earning;
    }

    uint REFERRER_1_LEVEL_LIMIT = 2;

    mapping(uint => uint) public LEVEL_PRICE;

    mapping(address => mapping(uint256 => UserStruct)) public users;
    mapping(address => UserEarning) public userEarnings;
    mapping(uint => mapping(uint => address)) public userList;
    uint[11] public currUserID;
    uint256[] payments = [5, 15, 20, 30, 30];

    event Registration(
        address indexed user,
        address indexed referrer,
        uint indexed userId,
        uint referrerId
    );
    event Reinvest(
        address indexed user,
        address indexed currentReferrer,
        address indexed caller,
        uint256 matrix,
        uint256 level,
        uint256 reinvestCount
    );
    event Upgrade(
        address indexed user,
        address indexed referrer,
        uint8 matrix,
        uint256 level
    );
    event NewUserPlace(
        address indexed user,
        address indexed referrer,
        address indexed currentReferrer,
        uint256 matrix,
        uint256 level,
        uint256 depth,
        uint256 reinvestcount
    );

    event CoinReceived(address indexed from, uint256 amount);

    event EarningsMatrix(
        address indexed user,
        uint256 amount,
        uint8 matrix,
        uint256 level
    );

    constructor(address _ownerAddress, address _devAddress) {
        ownerWallet = _ownerAddress;
        devAddress = _devAddress;

        LEVEL_PRICE[1] = 0.005 ether;
        LEVEL_PRICE[2] = 0.010 ether;
        LEVEL_PRICE[3] = 0.020 ether;
        LEVEL_PRICE[4] = 0.040 ether;
        LEVEL_PRICE[5] = 0.080 ether;
        LEVEL_PRICE[6] = 0.120 ether;
        LEVEL_PRICE[7] = 0.240 ether;
        LEVEL_PRICE[8] = 0.480 ether;
        LEVEL_PRICE[9] = 0.960 ether;
        LEVEL_PRICE[10] = 1.920 ether;

        for (uint256 i = 1; i <= 10; i++) {
            currUserID[i]++;
            users[ownerWallet][i].isExist = true;
            users[ownerWallet][i].id = currUserID[i];
            userEarnings[ownerWallet].referrer = ownerWallet;
            users[ownerWallet][i].initialId = currUserID[i];
            userList[i][currUserID[i]] = ownerWallet;
        }
    }

    function regUser(address _referer) public payable {
        uint _referrerID = users[_referer][1].id;
        require(!users[msg.sender][1].isExist, "User exist");
        require(
            _referrerID > 0 && _referrerID <= currUserID[1],
            "Incorrect referrer Id"
        );
        require(msg.value == LEVEL_PRICE[1], "Incorrect Value");

        if (
            users[userList[1][_referrerID]][1].referral.length >=
            REFERRER_1_LEVEL_LIMIT
        )
            _referrerID = users[findFreeReferrer(userList[1][_referrerID], 1)][
                1
            ].id;

        currUserID[1]++;
        users[msg.sender][1].isExist = true;
        users[msg.sender][1].id = currUserID[1];
        users[msg.sender][1].referrerID = _referrerID;
        userEarnings[msg.sender].referrer = _referer;
        userList[1][currUserID[1]] = msg.sender;
        users[msg.sender][1].initialId = currUserID[1];

        users[userList[1][_referrerID]][1].referral.push(msg.sender);

        payForLevel(1, msg.sender, 1, msg.sender);
        payable(_referer).transfer(LEVEL_PRICE[1].mul(40).div(100));
        emit EarningsMatrix(_referer, LEVEL_PRICE[1].mul(40).div(100), 1, 1);

        payable(ownerWallet).transfer(LEVEL_PRICE[1].mul(10).div(100));
        payable(devAddress).transfer(LEVEL_PRICE[1].mul(10).div(100));

        decacrush.transfer(msg.sender, LEVEL_PRICE[1]);
        emit CoinReceived(msg.sender, LEVEL_PRICE[1]);

        emit Registration(
            msg.sender,
            userList[1][_referrerID],
            currUserID[1],
            block.timestamp
        );
    }

    function buyLevel(uint256 _slot) public payable {
        require(users[msg.sender][1].isExist, "User not exist");
        require(!users[msg.sender][_slot].isExist, "User allready exist");
        uint _referrerID = users[userEarnings[msg.sender].referrer][_slot].id;
        if (_referrerID == 0) {
            _referrerID = 1;
        }
        require(msg.value == LEVEL_PRICE[_slot], "Incorrect Value");

        if (
            users[userList[_slot][_referrerID]][_slot].referral.length >=
            REFERRER_1_LEVEL_LIMIT
        )
            _referrerID = users[
                findFreeReferrer(userList[_slot][_referrerID], _slot)
            ][_slot].id;

        currUserID[_slot]++;
        users[msg.sender][_slot].isExist = true;
        users[msg.sender][_slot].id = currUserID[_slot];
        users[msg.sender][_slot].referrerID = _referrerID;
        userList[_slot][currUserID[_slot]] = msg.sender;
        users[msg.sender][_slot].initialId = currUserID[_slot];

        users[userList[_slot][_referrerID]][_slot].referral.push(msg.sender);

        payForLevel(1, msg.sender, _slot, msg.sender);

        payable(ownerWallet).transfer(LEVEL_PRICE[_slot].mul(5).div(100));
        payable(devAddress).transfer(LEVEL_PRICE[_slot].mul(5).div(100));

        payable(userList[_slot][_referrerID]).transfer(
            LEVEL_PRICE[_slot].mul(40).div(100)
        );
        emit EarningsMatrix(
            userList[_slot][_referrerID],
            LEVEL_PRICE[_slot].mul(40).div(100),
            1,
            _slot
        );

        decacrush.transfer(msg.sender, LEVEL_PRICE[_slot]);
        emit CoinReceived(msg.sender, LEVEL_PRICE[_slot]);

        emit Upgrade(msg.sender, userList[_slot][_referrerID], 3, _slot);
    }

    function reinvest(address _user, uint256 _slot) internal {
        if (_user == ownerWallet) {
            users[_user][_slot].referral.pop();
            users[_user][_slot].referral.pop();
            users[_user][_slot].cycle++;
            emit Reinvest(
                _user,
                _user,
                _user,
                3,
                _slot,
                users[_user][_slot].cycle
            );
        } else {
            uint256 _referrerID = users[userEarnings[_user].referrer][_slot].id;

            if (
                users[userList[_slot][_referrerID]][_slot].referral.length >=
                REFERRER_1_LEVEL_LIMIT
            )
                _referrerID = users[
                    findFreeReferrer(userList[_slot][_referrerID], 1)
                ][_slot].id;
            currUserID[_slot]++;
            users[_user][_slot].id = currUserID[_slot];
            users[_user][_slot].referrerID = _referrerID;
            userList[_slot][currUserID[_slot]] = _user;
            users[userList[_slot][_referrerID]][_slot].referral.push(_user);
            users[_user][_slot].noOfPayments[1] = 0;
            users[_user][_slot].noOfPayments[2] = 0;
            users[_user][_slot].noOfPayments[3] = 0;
            users[_user][_slot].noOfPayments[4] = 0;
            users[_user][_slot].noOfPayments[5] = 0;
            users[_user][_slot].cycle++;
            users[_user][_slot].referral = new address[](0);
            emit Reinvest(
                _user,
                userList[_slot][_referrerID],
                _user,
                3,
                _slot,
                users[_user][_slot].cycle
            );
            payForLevel(1, _user, _slot, _user);
        }
    }

    function payForLevel(
        uint _level,
        address _referrer,
        uint256 _slot,
        address _user
    ) internal {
        address referer = userList[_slot][users[_referrer][_slot].referrerID];

        if (!users[referer][_slot].isExist) {
            referer = userList[_slot][1];
            for (uint256 i = _level; i <= 3; i++) {
                uint256 comm = ((LEVEL_PRICE[_slot] / 2) * (payments[i - 1])) /
                    100;
                payable(referer).transfer(comm);
                users[referer][_slot].earning += comm;
                userEarnings[referer].earning += comm;
            }
        } else {
            users[referer][_slot].noOfPayments[_level]++;
            emit NewUserPlace(
                msg.sender,
                userList[_slot][users[_user][_slot].referrerID],
                referer,
                3,
                _slot,
                _level,
                users[referer][_slot].cycle
            );
            if (
                _level == 3 && users[referer][_slot].noOfPayments[_level] == 8
            ) {
                reinvest(referer, _slot);
            } else {
                uint256 comm = (
                    (LEVEL_PRICE[_slot].div(2)).mul(payments[_level - 1])
                ).div(100);
                payable(referer).transfer(comm);
                users[referer][_slot].earning += comm;
                userEarnings[referer].earning += comm;
                emit EarningsMatrix(referer, comm, 3, _slot);
            }

            if (_level < 3) {
                payForLevel(_level + 1, referer, _slot, _user);
            }
        }
    }

    function findFreeReferrer(
        address _user,
        uint256 _slot
    ) public view returns (address) {
        if (users[_user][_slot].referral.length < REFERRER_1_LEVEL_LIMIT)
            return _user;

        address[] memory referrals = new address[](14);
        referrals[0] = users[_user][_slot].referral[0];
        referrals[1] = users[_user][_slot].referral[1];

        address freeReferrer;
        bool noFreeReferrer = true;

        for (uint i = 0; i < 14; i++) {
            if (
                users[referrals[i]][_slot].referral.length ==
                REFERRER_1_LEVEL_LIMIT
            ) {
                if (i < 7) {
                    referrals[(i + 1) * 2] = users[referrals[i]][_slot]
                        .referral[0];
                    referrals[(i + 1) * 2 + 1] = users[referrals[i]][_slot]
                        .referral[1];
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
        return users[_user][1].referral;
    }

    function bytesToAddress(
        bytes memory bys
    ) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function getUserInfoPayment(
        address _user,
        uint256 _slot
    ) external view returns (uint256[6] memory noOfPayments) {
        for (uint256 i = 1; i <= 5; i++) {
            noOfPayments[i] = users[_user][_slot].noOfPayments[i];
        }

        return noOfPayments;
    }
}