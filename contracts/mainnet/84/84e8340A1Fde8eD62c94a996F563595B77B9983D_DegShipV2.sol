// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/IERC20.sol";
import "./libraries/SafeMath.sol";
import "./interfaces/IDegCrew.sol";
import "./interfaces/IDegShipCommanderV2.sol";
import "./interfaces/IDegShipV2.sol";

contract DegShipV2 is IDegShipV2 {
    using SafeMath for uint256; 

    string public shipName;
    IDegCrew public crewAddress;
    uint public startTime;

    address public factory;
    string public shipSerial;

    struct OrderInfo {
        uint256 amount; 
        uint256 start;
        uint256 unfreeze; 
        bool isUnfreezed;
    }

    mapping(address => OrderInfo[]) public orderInfos;

    address[] public depositors;

    uint256 public dayPerCycle = 1 days;

    uint256 public dayRewardPercents = 1; // static reward

    IDegShipCommanderV2 public commander;

    bool public stopped = false;

    constructor() {
        factory = msg.sender;
    }

    event EventInitialShip(address indexed _commander, string _name, address _crew, uint _percent, uint _perCycle);

    function initialize(address _commander,
        string memory _serial, 
        string memory _name, uint256 _dayReward, uint256 _perCycle) external {
        require(msg.sender == factory, 'DegShip Factory: FORBIDDEN'); // sufficient check
        shipName = _name;
        shipSerial = _serial;
        commander = IDegShipCommanderV2(_commander);
        crewAddress = IDegCrew(commander.crewAddress());
        
        startTime = block.timestamp;
        dayRewardPercents = _dayReward;
        dayPerCycle = _perCycle;
        emit EventInitialShip(_commander, shipName, address(crewAddress), dayRewardPercents, dayPerCycle);
    }

    event ShipLaunched(address indexed _from, bool _shipStatus, uint256 _amount);

    function afterLaunch(address from, uint256 amount) private {
        stopped = commander.checkShipStop(address(this));
        emit ShipLaunched(from, stopped, amount);
    }

    // start
    function launch(address from, uint256 _amount, uint orderIndex) external {
        require(msg.sender == address(commander), "Invalid commander");
        crewAddress.deposit(from, _amount);
        // _unfreezeFundAndUpdateReward(from, orderIndex);
        uint nowTime = block.timestamp;
        if (nowTime < commander.startTime()) {
            nowTime = commander.startTime();
        }
        uint256 unfreezeTime = nowTime.add(dayPerCycle);
        orderInfos[from].push(OrderInfo(
            _amount, 
            nowTime, 
            unfreezeTime,
            false
        ));
        depositors.push(from);
        crewAddress.updateUserDepositShipOid(from, address(this), orderIndex + 1);
        afterLaunch(from, _amount);
    }

    function reLaunch(address from, uint orderIndex) external {
        require(msg.sender == address(commander), "Invalid commander");
        OrderInfo storage order = orderInfos[from][orderIndex - 1];
        crewAddress.reDeposit(from, address(this), order.amount, orderIndex);
        _unfreezeFundQuit(from, order.amount);
        
        uint nowTime = block.timestamp;
        uint256 _unfreezeTime = nowTime.add(dayPerCycle);
        order.start = nowTime;
        order.unfreeze = _unfreezeTime;

        afterLaunch(from, order.amount);
    }

    function destroyUserOrder(address _user, uint _orderIndex) external {
        require(msg.sender == address(commander), "Invalid commander");
        require(block.timestamp >= orderInfos[_user][_orderIndex].unfreeze, "Order is still running" );
        orderInfos[_user][_orderIndex].isUnfreezed = true;
    }

    function getOrderLength(address _user) public view returns(uint256) {
        return orderInfos[_user].length;
    }

    function getDepositorsLength() public view returns(uint256) {
        return depositors.length;
    }

    function orderAmountById(address _user, uint _orderIndex) public view returns (uint256){
        return orderInfos[_user][_orderIndex].amount;
    }

    function orderAmountByUnfreezeId(address _user, uint _orderIndex) public view returns (uint256){
        if(orderInfos[_user][_orderIndex].isUnfreezed == false){
            return orderAmountById(_user, _orderIndex);
        }
        return 0;
    }

    function checkOrderCondition(address _user, uint _index, uint256 _amount) public view returns (bool){
        if(_amount >= orderInfos[_user][_index].amount && block.timestamp >= orderInfos[_user][_index].unfreeze){
            return true;
        }
        return false;
    }

    function _unfreezeFundQuit(address _user, uint256 _amount) private {
        uint256 staticReward = _amount.mul(dayRewardPercents).div(100);
        commander.shipOutcome(address(this), _user, _amount.add(staticReward));
    }

    // function _unfreezeFundAndUpdateReward(address _user, uint256 _nowLen) private {
    //     if(_nowLen > 0){
    //         OrderInfo storage order = orderInfos[_user][_nowLen - 1];
    //         if(order.isUnfreezed == false){
    //             order.isUnfreezed = true;
    //             _unfreezeFundQuit(_user, order.amount);
    //         }
    //     }
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IDegCrew {
    function register(address from, address refer) external;
    function deposit(address, uint256) external;
    function reDeposit(address from, address ship, uint256 _amount, uint _orderIndex) external;
    function updateLevel(address) external;
    function isCaller(address) external view returns (bool);

    function checkRefer(address user) external view returns (address);
    function userRevenue(address user) external view returns (uint256);
    
    function addUserPointBalance(address _user, uint256 _amount) external;
    function subUserPointBalance(address _user, uint256 _amount) external;
    function balanceOfPoint(address _user) external view returns (uint256);
    function updateUserDepositShipOid(address _user, address _ship, uint _oid) external;
    function userTakeOrderInShip(address _user, address _ship) external view returns (uint);

    function pointDividend(address _user, address _ship) external;
    function myPointAvailable(address _user, uint _day) external view returns (uint256 _bonus);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IDegShipCommanderV2 {
    function crewAddress() external view returns (address);
    function shipOutcome(address, address, uint256) external;
    function checkShipStop(address) external view returns (bool);
    function shipReleaseAmountToStop(address _ship) external view returns (uint256);

    function getDay() external view returns (uint);
    function startTime() external view returns (uint);
    function dayRecordPool(uint _day) external view returns (uint256);
    function dayInvestTotal(uint _day) external view returns (uint256);
    function dayUserInvestTotal(uint _day, address _address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IDegShipV2 {
    function initialize(address _commander,string calldata _serial, string calldata _name, uint256 _percent, uint256 _perCycle) external;

    function dayPerCycle() external view returns (uint256);
    function dayRewardPercents() external view returns (uint256);

    function checkOrderCondition(address _user,uint _index, uint256 _amount) external view returns (bool);
    function orderAmountById(address _user, uint _orderIndex) external view returns (uint256);
    function orderAmountByUnfreezeId(address _user, uint _orderIndex) external view returns (uint256);
    function getOrderLength(address _user) external view returns(uint256);

    function depositors(uint) external view returns(address);
    function getDepositorsLength() external view returns(uint256);

    function destroyUserOrder(address from, uint orderIndex) external;
    function launch(address from, uint256 amount, uint orderIndex) external;
    function reLaunch(address from, uint orderIndex) external;
    function stopped() external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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