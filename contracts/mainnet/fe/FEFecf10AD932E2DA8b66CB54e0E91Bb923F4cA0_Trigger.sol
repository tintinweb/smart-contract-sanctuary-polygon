// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;

import "./interfaces/IERC2771Recipient.sol";

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Implementation
 *
 * @notice Note that this contract was called `BaseRelayRecipient` in the previous revision of the GSN.
 *
 * @notice A base contract to be inherited by any contract that want to receive relayed transactions.
 *
 * @notice A subclass must use `_msgSender()` instead of `msg.sender`.
 */
abstract contract ERC2771Recipient is IERC2771Recipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @notice Method is not a required method to allow Recipients to trust multiple Forwarders. Not recommended yet.
     * @return forwarder The address of the Forwarder contract that is being used.
     */
    function getTrustedForwarder() public virtual view returns (address forwarder){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /// @inheritdoc IERC2771Recipient
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Declarations
 *
 * @notice A contract must implement this interface in order to support relayed transaction.
 *
 * @notice It is recommended that your contract inherits from the ERC2771Recipient contract.
 */
abstract contract IERC2771Recipient {

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @param forwarder The address of the Forwarder contract that is being used.
     * @return isTrustedForwarder `true` if the Forwarder is trusted to forward relayed transactions by this Recipient.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * @notice Use this method the contract anywhere instead of msg.sender to support relayed transactions.
     * @return sender The real sender of this call.
     * For a call that came through the Forwarder the real sender is extracted from the last 20 bytes of the `msg.data`.
     * Otherwise simply returns `msg.sender`.
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * @notice Use this method in the contract instead of `msg.data` when difference matters (hashing, signature, etc.)
     * @return data The real `msg.data` of this call.
     * For a call that came through the Forwarder, the real sender address was appended as the last 20 bytes
     * of the `msg.data` - so this method will strip those 20 bytes off.
     * Otherwise (if the call was made directly and not through the forwarder) simply returns `msg.data`.
     */
    function _msgData() internal virtual view returns (bytes calldata);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Actions {
    address aave = 0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf;

    function executeSwap(
        address tokenToSwap,
        uint256 amountToSwap,
        address receiver
    ) public returns (bool) {
        require(msg.sender == address(this), "UNAUTHORIZED");
        string memory connectorName = "UNISWAP-V3-SWAP-A";
        // bytes memory targetData =
        // Transfer amountToSwap from user to ID DSA
        //  Note the target asset balance here
        // Ask the DSA to swap
        // Swap complete
        // Note the target asset swap again
        // send the diff to the action owner
    }

    function makeDeposit(
        address tokenToDeposit,
        uint256 amountToDeposit,
        address behalfOf,
        address caller
    ) public returns (bool) {
        require(msg.sender == address(this), "UNAUTHORIZED");

        IERC20(tokenToDeposit).transferFrom(
            caller,
            address(this),
            amountToDeposit
        );

        bytes4 basicDeposit = bytes4(
            keccak256("deposit(address,uint256,address,uint16)")
        );
        bytes memory targetData = abi.encodeWithSelector(
            basicDeposit,
            tokenToDeposit,
            amountToDeposit,
            behalfOf,
            0
        );

        address(aave).call(targetData);

        return true;
        // Transfer amountToDeposit from user to ID DSA
        // Ask the DSA to deposit
        // That's it
    }

    function sendToken(
        address token,
        address sender,
        address receiver,
        uint256 amount
    ) public returns (bool) {
        return IERC20(token).transferFrom(sender, receiver, amount);
    }

    function approve(address tokenAddress) public {
        IERC20(tokenAddress).approve(aave, type(uint256).max);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

interface IUniswapV3PoolState {
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );
}

interface ILendingPool {
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );
}

contract Conditions {
    address public aaveLendingPool = 0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf;

    // Some default conditions
    function conditionIsGreaterTimestamp(uint256 timestamp)
        public
        view
        returns (bool)
    {
        return block.timestamp > timestamp;
    }

    function conditionIsLessGasFee(uint256 gasFee) public view returns (bool) {
        return block.basefee < gasFee;
    }

    // Returns if the token0 price of a pool is <= desired price
    // Returns how much 1 token0 is worth in token1
    // Target price must be decimal diff aware
    /// @notice hardcoded for WETH-USDC Pool
    /// @notice returns how much 1 usdc can buy in WETH
    /// @notice targetPrice is desired price * (10 ** 12)

    // If target price is 1 ETH = 1282 USDC
    // Then the target price needed is 1 USDC = 0.00078
    // Target price that needs to be passed is (0.00078 * (10 ** 12))
    function conditionIsLessPrice(address poolAddress, uint256 targetPrice)
        public
        view
        returns (bool)
    {
        IUniswapV3PoolState pool = IUniswapV3PoolState(poolAddress);
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        uint256 rootPrice = (sqrtPriceX96 / (2**96));
        uint256 token0Price = rootPrice * rootPrice;

        return token0Price <= targetPrice;
    }

    function conditionIsLessHealthFactor(
        address userAddress,
        uint256 targetHealthFactor
    ) public view returns (bool) {
        ILendingPool pool = ILendingPool(aaveLendingPool);
        (, , , , , uint256 hf) = pool.getUserAccountData(userAddress);

        return hf <= targetHealthFactor;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;
import "../structs/types.sol";

abstract contract ITrigger {
    event TransactionAdded(bytes32 indexed txHash, address indexed user);
    event TransactionExecuted(bytes32 indexed txHash, address indexed executor);
    event TransactionCanceled(bytes32 indexed txHash, address indexed user);

    function addTransaction(
        TriggerTypes.Action calldata transaction,
        TriggerTypes.Condition calldata triggerCondition,
        TriggerTypes.Payout calldata payout
    ) public virtual returns (bool);

    function executeTransaction(bytes32 txHash) public virtual returns (bool);

    function checkTriggerCondition(bytes32 txHash)
        public
        view
        virtual
        returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

contract TriggerTypes {
    enum PayoutType {
        FIXED,
        GASMULTIPLE
    }

    enum TransactionStatus {
        QUEUED,
        EXECUTED,
        CANCELLED
    }

    struct Action {
        address to;
        bytes data;
    }

    struct Condition {
        address to;
        bytes data;
        bytes output;
    }

    // Payout to the miner
    // pType fixed means the value to pay is value in WETH
    // pType gas multiple means, the value is multiple of gasPrice in WETH
    // tokenAddress fixed to WETH
    // from is fixed to user that added the transaction

    struct Payout {
        PayoutType pType;
        address tokenAddress;
        // Value 150 for gas multiple type is 1.5 times the prev block gasPrice
        uint256 value;
        address from;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "@opengsn/contracts/src/ERC2771Recipient.sol";
import "./structs/types.sol";
import "./interface/ITrigger.sol";
import "./TriggerLogic.sol";

contract Trigger is ITrigger, TriggerLogic, ERC2771Recipient {
    constructor(address _trustedForwarder) {
        _setTrustedForwarder(_trustedForwarder);
    }

    function addTransaction(
        TriggerTypes.Action calldata transaction,
        TriggerTypes.Condition calldata triggerCondition,
        TriggerTypes.Payout calldata payout
    ) public override returns (bool) {
        bytes32 txHash = keccak256(abi.encode(transaction, nonce));

        transactions[txHash] = transaction;
        triggerConditions[txHash] = triggerCondition;
        transactionPayouts[txHash] = payout;
        transactionPayouts[txHash].from = _msgSender();

        transactionStatus[txHash] = TriggerTypes.TransactionStatus.QUEUED;
        transactionOwner[txHash] = _msgSender();

        nonce++;

        emit TransactionAdded(txHash, _msgSender());

        return true;
    }

    // view, doesn't depend on meta txns
    function checkTriggerCondition(bytes32 txHash)
        public
        view
        override
        returns (bool)
    {
        checkTransactionExists(txHash);
        TriggerTypes.Condition memory condition = triggerConditions[txHash];
        checkCondition(condition);
        return true;
    }

    // Is not a meta transaction
    function executeTransaction(bytes32 txHash) public override returns (bool) {
        uint256 initGas = gasleft();
        checkTransactionExists(txHash);
        TriggerTypes.Action memory transaction = transactions[txHash];
        TriggerTypes.Condition memory condition = triggerConditions[txHash];
        TriggerTypes.Payout memory payout = transactionPayouts[txHash];

        // Check condition
        checkCondition(condition);
        // Execute transaction
        executeAction(transaction);
        // Send payout
        sendPayout(payout, _msgSender(), initGas - gasleft() + 30_000); // Add 30_000 for sendPayout function

        emit TransactionExecuted(txHash, _msgSender());

        return true;
    }

    function cancelTransaction(bytes32 txHash) public returns (bool) {
        require(_msgSender() == transactionOwner[txHash], "UNAUTHORIZED");
        checkTransactionExists(txHash);
        delete transactions[txHash];

        emit TransactionCanceled(txHash, _msgSender());
        return true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;
import "./structs/types.sol";
import "./Conditions.sol";
import "./Actions.sol";

contract TriggerLogic is Conditions, Actions {
    uint256 public nonce;
    mapping(bytes32 => TriggerTypes.Action) public transactions;
    mapping(bytes32 => address) public transactionOwner;
    mapping(bytes32 => TriggerTypes.Condition) public triggerConditions;
    mapping(bytes32 => TriggerTypes.Payout) public transactionPayouts;
    mapping(bytes32 => TriggerTypes.TransactionStatus) public transactionStatus;

    function checkCondition(TriggerTypes.Condition memory condition)
        internal
        view
        returns (bool)
    {
        (bool success, bytes memory output) = address(condition.to).staticcall(
            condition.data
        );

        require(success, "CONDITION_CALL_FAILED");
        require(
            keccak256(output) == keccak256(condition.output),
            "CONDITION_NOT_PASSED"
        );

        return true;
    }

    function executeAction(TriggerTypes.Action memory action)
        internal
        returns (bool)
    {
        (bool success, ) = address(action.to).call(action.data);
        require(success, "TRANSACTION_FAILED");

        return true;
    }

    function calculatePayout(
        TriggerTypes.Payout memory payout,
        uint256 expectedGas
    ) public view returns (uint256) {
        if (payout.pType == TriggerTypes.PayoutType.GASMULTIPLE) {
            uint256 premiumGas = (block.basefee * payout.value) / 100;
            uint256 payoutValue = (premiumGas * expectedGas);
            return payoutValue;
        }
        return payout.value;
    }

    function sendPayout(
        TriggerTypes.Payout memory payout,
        address benefactor,
        uint256 gasUsed
    ) internal returns (bool) {
        uint256 payoutValue = calculatePayout(payout, gasUsed);

        bool success = IERC20(payout.tokenAddress).transferFrom(
            payout.from,
            benefactor,
            payoutValue
        );

        require(success, "PAYOUT_FAILED");
        return true;
    }

    function checkTransactionExists(bytes32 txHash) public view {
        require(transactions[txHash].to != address(0), "TXN_NON_EXISTENT");
    }
}