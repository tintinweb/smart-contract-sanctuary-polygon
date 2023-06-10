//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./libraries/SafeMath.sol";

contract Timelock {

    using SafeMath for uint;

    event TransactionQueued(address[] targets, string[] signatures, bytes[] _calldatas, uint eta);
    event TransactionExecuted(address[] targets, string[] signatures, bytes[] _calldatas, 
    uint eta, uint timestamp);

    error ExecutionFailed(address target, string signature, bytes _calldata, uint eta);

    ///@notice transcation needs to be executed before current block.timestamp is less than eta + GRACE_PERIOD
    uint public constant GRACE_PERIOD = 4 days;

    ///@notice the amount of minimum days after which proposal should be executed
    uint public constant MINIMUM_DELAY = 10;
    
    ///@notice the amount of maximum days before which proposal should be executed
    uint public constant MAXIMUM_DELAY = 15 days;

    ///@notice address of the governance contract
    address public governanceAddress;

    address public owner;

    uint public delay;

    bytes32[] public currentlyQueuedTransactions;

    constructor(address _owner, uint _delay) {
        require(_delay >= MINIMUM_DELAY, "CLAMP: DELAY MUST EXCEED MINIMUM DELAY");
        require(_delay <= MAXIMUM_DELAY, "CLAMP: DELAY MUST NOT EXCEED MAXIMUM DELAY");

        owner = _owner;
        delay = _delay; //3days
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "CLAMP: NOT OWNER");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == governanceAddress && governanceAddress != address(0), "CLAMP: ONLY GOVERNANCE CONTRACT IS ALLOWED");
        _;
    }

    function getTxId(address _target, string memory _signature, bytes memory _calldata, 
    uint eta) public pure returns(bytes32 txId){

        return keccak256(abi.encode(_target, _signature, _calldata, eta));
    }

    ///@notice queues the transcation to be executed in future
    ///@notice only 1 transaction can be queued at a time
    function queueTransaction(address[] calldata _targets, string[] memory _signatures, bytes[] memory _calldatas, 
    uint eta) external onlyGovernance returns(bytes32[] memory) {
        require(eta >= block.timestamp.add(delay), "CLAMP: ESTIMATED EXECUTION BLOCK MUST SATISFY DELAY");
        require(currentlyQueuedTransactions.length == 0, "CLAMP: TRANSACTIONS ALREADY QUEUED");

        for(uint i =0; i<_targets.length;) {

            bytes32 txHash = getTxId(_targets[i], _signatures[i], _calldatas[i], eta);
            currentlyQueuedTransactions.push(txHash);
        
            unchecked {
                ++i;
            }
        }

        emit TransactionQueued(_targets, _signatures, _calldatas, eta);

        return currentlyQueuedTransactions;
    }

    ///@notice marks the transaction as executed
    ///@notice onlyGovernance contract is allowed to call this function
    ///@notice this should be marked as executed by owner only after they executes the proposal
    function executeTransaction(address[] calldata _targets, string[] memory _signatures, bytes[] memory _calldatas,
    uint eta) external onlyGovernance{
        require(currentlyQueuedTransactions.length == _targets.length, "CLAMP: INVALID NUMBER OF QUEUED TRANSACTION");
        require(block.timestamp >= eta, "CLAMP: TRANSACTION HAS NOT SURPASSED TIME LOCK");
        require(block.timestamp <= eta.add(GRACE_PERIOD), "CLAMP: TRANSACTION IS STALE");

        for(uint i = 0; i < currentlyQueuedTransactions.length; ) {

            bytes32 txHash = getTxId(_targets[i], _signatures[i], _calldatas[i], eta);
            if(currentlyQueuedTransactions[i] != txHash) {
                revert ExecutionFailed(_targets[i], _signatures[i], _calldatas[i], eta);
            }

            unchecked {
                ++i;
            }
        }

        delete currentlyQueuedTransactions;

        emit TransactionExecuted(_targets, _signatures, _calldatas, eta, block.timestamp);

    }

    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function initializeGovernanceContract(address _governanceAddress) external onlyOwner {
        governanceAddress = _governanceAddress;
    }

    function updateDelay(uint256 _delay) external onlyOwner {
        require(_delay >= MINIMUM_DELAY, "CLAMP: DELAY MUST EXCEED MINIMUM DELAY");
        require(_delay <= MAXIMUM_DELAY, "CLAMP: DELAY MUST NOT EXCEED MAXIMUM DELAY");

        delay = _delay;
    }
}

//SPDX-License-Identifier: MIT

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}