// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Travel Saving Vault with Recurring Payments Scheduler
 */
contract TravelSaver {
    // ***** ***** EVENTS ***** *****

    /**
     * @notice Emitted when a TravelPlan is created
     *
     * @param ID uniqe plan's ID
     * @param owner user who created it
     * @param travelPlan a plan's details
     */
    event CreatedTravelPlan(
        uint256 indexed ID,
        address indexed owner,
        TravelPlan travelPlan
    );

    /**
     * @notice Emitted when a token transfer is made to each TravelPlan
     *
     * @param ID uniqe plan's ID
     * @param contributor address that made a transfer
     * @param amount an ERC20 unit as per its decimals
     */
    event ContributeToTravelPlan(
        uint256 indexed ID,
        address indexed contributor,
        uint256 amount
    );

    /**
     * @notice Emitted when a user makes a withdrawl towards a booking
     *
     * @param ID uniqe plan's ID
     * @param owner address that received a transfer
     * @param amount an ERC20 unit as per its decimals
     */
    event ClaimTravelPlan(uint256 indexed ID, address owner, uint256 amount);

    /**
     * @notice Emitted when a user makes a withdrawl towards a booking
     *
     * @param from address that made a transfer
     * @param to address that received a transfer
     * @param amount an ERC20 unit as per its decimals
     */
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /**
     * @notice Emitted when a PaymentPlan is created
     *
     * @param ID uniqe plan's ID
     * @param owner user who created it
     * @param paymentPlan a plan's details
     */
    event CreatedPaymentPlan(
        uint256 indexed ID,
        address indexed owner,
        PaymentPlan paymentPlan
    );

    /**
     * @notice Emitted when a PaymentPlan is cancelled before scheduled payments are made
     *
     * @param ID uniqe plan's ID
     * @param owner user who created it
     * @param paymentPlan a plan's details
     */
    event CancelPaymentPlan(
        uint256 indexed ID,
        address indexed owner,
        PaymentPlan paymentPlan
    );

    /**
     * @notice Emitted when a PaymentPlan scheduled payment has been sucessfully made
     *
     * @param ID uniqe plan's ID
     * @param callableOn unix TS of next scheduled payment
     * @param amount an ERC20 unit as per its decimals
     * @param intervalNo sequential scheduled payment count
     */
    event StartPaymentPlanInterval(
        uint256 indexed ID,
        uint256 indexed callableOn,
        uint256 indexed amount,
        uint256 intervalNo
    );

    /**
     * @notice Emitted when a PaymentPlan scheduled payment has been sucessfully made
     *
     * @param ID uniqe plan's ID
     * @param intervalNo sequential scheduled payment count
     */
    event PaymentPlanIntervalEnded(
        uint256 indexed ID,
        uint256 indexed intervalNo
    );

    /**
     * @notice Emitted when a PaymentPlan has ended as scheduled, after last payment
     *
     * @param ID uniqe plan's ID
     * @param owner user who created it
     * @param paymentPlan a plan's details
     */
    event EndPaymentPlan(
        uint256 indexed ID,
        address indexed owner,
        PaymentPlan paymentPlan
    );
    // ***** ***** STRUCTS ***** *****

    /**
     * @notice TravelPlan is a vault where users funds are retained until the booking
     *
     * @param owner user's wallet address, plan creator, who can transfer money out to operators wallet -> make a booking
     * @param ID unique identifier within the contract generated sequencially
     * @param operatorPlanID operator's reference booking identifier
     * @param operatorUserID operator's reference user identifier
     * @param contributedAmount current ammount available for a whithdrawal
     * @param createdAt the creation date
     * @param claimedAt last clamied date
     * @param claimed true if it has been clamimed in the past
     */
    struct TravelPlan {
        address owner;
        uint256 ID;
        uint256 operatorPlanID;
        uint256 operatorUserID;
        uint256 contributedAmount;
        uint256 createdAt;
        uint256 claimedAt;
        bool claimed;
    }

    /**
     * @notice PaymentPlan is a recurring payments scheduler that must target specific TravelPlan
     *
     * @param travelPlanID id reference to a vault id where funds will be sent to
     * @param ID unique identifier within the contract generated sequencially
     * @param totalAmount the planned value of a total savings to be scheduled
     * @param amountSent the current state of all payments made
     * @param amountPerInterval unit value of a specific ERC-20 token to be sent per each scheduled payment
     * @param totalIntervals total number of scheduled payments
     * @param intervalsProcessed cuurent number of processed payments
     * @param nextTransferOn unix secs TS of a next scheduled payment due at
     * @param interval current interval count
     * @param sender the owner of the plan - might be different to the TravelPlan
     * @param alive determined whether plan is active or cancelled
     */
    struct PaymentPlan {
        uint256 travelPlanID;
        uint256 ID;
        uint256 totalAmount;
        uint256 amountSent;
        uint256 amountPerInterval;
        uint256 totalIntervals;
        uint256 intervalsProcessed;
        uint256 nextTransferOn;
        uint256 interval;
        address sender;
        bool alive;
    }

    // ***** ***** STATE-VARIABLES ***** *****

    address public immutable operatorWallet; // hardcoded address of the operator wallet where funds are send from travel-plan as external multisg wallet that is opearated and solely responsible for by the ticket issuer

    using SafeERC20 for IERC20;
    IERC20 public immutable token; // hardcoded address of the ERC20 EUR/USD PEGGED and NON DEFLACTIONARY token that serves a currency of the contract

    uint256 travelPlanCount; // current number of contract's created travel-plans
    uint256 paymentPlanCount; // current number of contract's created payment-plans

    mapping(uint256 => TravelPlan) public travelPlans; // TravelPlan reference by ID, returns Plans state

    mapping(uint256 => PaymentPlan) public paymentPlans; // PaymentPlan referenced by ID, returns Plans state

    // mapping(uint256 => mapping(address => uint256)) public contributedAmount; // ID

    /**
     * @param ERC20_ EUR or USD PEGGED, STABLE and NON DEFLACTIONARY tokens ONLY
     *
     * @param operatorWallet_ an external multisg wallet that is opearated and solely responsible for by the ticket issuer,
     * user is to be guaranteed that once claimed funds to that address -> off chain purchase or refund must be processed by contract issuing party
     */
    constructor(address ERC20_, address operatorWallet_) {
        token = IERC20(ERC20_);
        operatorWallet = operatorWallet_;
    }

    /**
     ***** ***** STATE-CHANGING-EXTERNAL-FUNCTIONS ***** *****
     */

    /**
     * @dev create Travel Plan and New Payment Plan attached to it in one go
     *
     * @param operatorPlanID_ The plan id provided by the operator.
     * @param operatorUserID_ The user id provided by the operator.
     * @param amountPerInterval unit value of a specific ERC-20 token to be sent per each scheduled payment
     * @param totalIntervals total number of payments to be scheduled
     * @param intervalLength time distance between each payments in seconds
     *
     * @return travelPlanID paymentPlanID new sequential count based UUIDs
     *
     * Emits a {CreatedTravelPlan, CreatedPaymentPlan} event.
     */
    function createTravelPaymentPlan(
        uint256 operatorPlanID_,
        uint256 operatorUserID_,
        uint256 amountPerInterval,
        uint256 totalIntervals,
        uint256 intervalLength
    ) external returns (uint256 travelPlanID, uint256 paymentPlanID) {
        travelPlanID = createTravelPlan(operatorPlanID_, operatorUserID_);
        paymentPlanID = createPaymentPlan(
            travelPlanID,
            amountPerInterval,
            totalIntervals,
            intervalLength
        );
        return (travelPlanID, paymentPlanID);
    }

    /**
     * @dev create Travel Plan where user will store his/hers savings until the booking date
     *
     * @param operatorPlanID_ The plan id provided by the operator.
     * @param operatorUserID_ The user id provided by the operator.
     *
     * @return travelPlanCount  a new sequential count based UUID
     *
     * Emits a {CreatedTravelPlan} event.
     */
    function createTravelPlan(
        uint256 operatorPlanID_,
        uint256 operatorUserID_
    ) public returns (uint256) {
        travelPlanCount += 1;

        travelPlans[travelPlanCount] = TravelPlan({
            owner: msg.sender,
            ID: travelPlanCount,
            operatorPlanID: operatorPlanID_,
            operatorUserID: operatorUserID_,
            contributedAmount: 0,
            createdAt: block.timestamp,
            claimedAt: 0,
            claimed: false
        });

        emit CreatedTravelPlan(
            travelPlanCount,
            msg.sender,
            travelPlans[travelPlanCount]
        );
        return travelPlanCount;
    }

    /**
     * @dev allows to transfer ERC20 token to specific TravelPlan by anyone
     *
     * @param ID TravelPlan existing UUID
     * @param amount ERC20 token value defined by its decimals
     *
     * Emits a {ContributeToTravelPlan, Transfer} event.
     */
    function contributeToTravelPlan(uint256 ID, uint256 amount) external {
        TravelPlan storage plan = travelPlans[ID];
        require(plan.ID == ID, "doesn't exist");

        plan.contributedAmount += amount;

        token.safeTransferFrom(msg.sender, address(this), amount);

        emit ContributeToTravelPlan(ID, msg.sender, amount);
        emit Transfer(msg.sender, address(this), amount);
    }

    /**
     * @dev allows to transfer ERC20 token from specific TravelPlan to operators wallet to make a booking only by the user/owner
     *
     * @param ID TravelPlan existing UUID
     * @param value ERC20 token value defined by its decimals
     *
     * Emits a {ClaimTravelPlan, Transfer} event.
     */
    function claimTravelPlan(uint256 ID, uint256 value) external {
        TravelPlan storage plan = travelPlans[ID];
        require(plan.ID == ID, "doesn't exist");
        require(plan.owner == msg.sender, "not owner");
        require(plan.contributedAmount >= value, "insufficient funds");
        plan.contributedAmount -= value;
        token.safeTransfer(operatorWallet, value);
        plan.claimed = true;
        plan.claimedAt = block.timestamp;
        emit ClaimTravelPlan(ID, msg.sender, value);
        emit Transfer(address(this), operatorWallet, value);
    }

    /**
     * @dev creates a new payment plan targeting existing travel-plan along with its sheduled payments details
     *
     * @param _travelPlanID The plan id provided by the operator.
     * @param amountPerInterval unit value of a specific ERC-20 token to be sent per each scheduled payment
     * @param totalIntervals total number of payments to be scheduled
     * @param intervalLength time distance between each payments in seconds
     *
     * @return id  a new sequential count based UUID
     *
     * Emits a {CreatedPaymentPlan} event.
     */
    function createPaymentPlan(
        uint256 _travelPlanID,
        uint256 amountPerInterval,
        uint256 totalIntervals,
        uint256 intervalLength
    ) public returns (uint256) {
        uint256 totalToTransfer = amountPerInterval * totalIntervals;
        require(
            IERC20(token).allowance(msg.sender, address(this)) >=
                totalToTransfer,
            "ERC20: insufficient allowance"
        );
        TravelPlan memory plan = travelPlans[_travelPlanID];
        require(plan.ID == _travelPlanID, "doesn't exist");
        uint256 id = ++paymentPlanCount;

        paymentPlans[id] = PaymentPlan({
            travelPlanID: _travelPlanID,
            ID: id,
            totalAmount: totalToTransfer,
            amountSent: 0,
            amountPerInterval: amountPerInterval,
            totalIntervals: totalIntervals,
            intervalsProcessed: 0,
            nextTransferOn: 0,
            interval: intervalLength,
            sender: msg.sender,
            alive: true
        });
        _startInterval(id);

        emit CreatedPaymentPlan(id, msg.sender, paymentPlans[id]);

        return id;
    }

    /**
     * @dev cancelPaymentPlan cancels existing payment schedule before its plannned due date
     *
     * @param ID TravelPlan existing UUID
     *
     * Emits a {CancelPaymentPlan} event.
     */
    function cancelPaymentPlan(uint256 ID) external {
        require(msg.sender == paymentPlans[ID].sender, "only plan owner");
        _endPaymentPlan(ID);

        emit CancelPaymentPlan(ID, msg.sender, paymentPlans[ID]);
    }

    /**
     * @dev runInterval executes scheduled payment
     *
     * @param ID PaymentPlan existing UUID
     */
    function runInterval(uint256 ID) external {
        _fulfillPaymentPlanInterval(ID);
    }

    /**
     ***** ***** STATE-CHANGING-PRIVATE-FUNCTIONS ***** *****
     */

    /**
     * @dev _startInterval sets new payment schedule
     *
     * @param ID PaymentPlan existing UUIDs
     *
     * Emits a {StartPaymentPlanInterval} event.
     */
    function _startInterval(uint256 ID) internal {
        PaymentPlan memory plan = paymentPlans[ID];
        uint256 callableOn = paymentPlans[ID].interval + block.timestamp;
        uint256 intervalNumber = plan.intervalsProcessed + 1;
        paymentPlans[ID].nextTransferOn = callableOn;

        emit StartPaymentPlanInterval(
            ID,
            callableOn,
            plan.amountPerInterval,
            intervalNumber
        );
    }

    /**
     * @dev _endPaymentPlan ends payment plan
     *
     * @param ID PaymentPlan existing UUIDs
     *
     * Emits a {EndPaymentPlan} event.
     */
    function _endPaymentPlan(uint256 ID) internal {
        PaymentPlan memory plan = paymentPlans[ID];
        paymentPlans[ID].alive = false;
        emit EndPaymentPlan(ID, plan.sender, plan);
    }

    /**
     * @dev _contributeToTravelPlan executes scheduled payments internaly by transfering tokens from user to the vault - used by a off chain worker
     *
     * @param ID PaymentPlan existing UUIDs
     * @param amount ERC20 token value defined by its decimals
     * @param caller address of a contract that executes transaction on behalf of the user
     *
     * Emits a {ContributeToTravelPlan, Transfer} event.
     */
    function _contributeToTravelPlan(
        uint256 ID,
        uint256 amount,
        address caller
    ) internal {
        TravelPlan storage plan = travelPlans[ID];
        // require(block.timestamp >= plan.createdAt, "doesn't exist");
        require(plan.ID == ID, "doesn't exist");

        plan.contributedAmount += amount;

        // contributedAmount[ID][caller] += amount;
        token.safeTransferFrom(caller, address(this), amount);

        emit ContributeToTravelPlan(ID, caller, amount);
        emit Transfer(caller, address(this), amount);
    }

    /**
     * @dev _fulfillPaymentPlanInterval executes scheduled payments internaly
     *
     * @param ID PaymentPlan existing UUIDs
     *
     * Emits a {PaymentPlanIntervalEnded} event.
     */
    function _fulfillPaymentPlanInterval(uint256 ID) internal {
        PaymentPlan memory plan = paymentPlans[ID];

        uint256 amountToTransfer = plan.amountPerInterval;
        address sender = plan.sender;
        uint256 interval = plan.intervalsProcessed + 1;
        require(plan.nextTransferOn <= block.timestamp, "too early");
        require(plan.alive, "plan ended");

        // Check conditions here with an if clause instead of require, so that integrators dont have to keep track of balances
        if (
            token.balanceOf(sender) >= amountToTransfer &&
            token.allowance(sender, address(this)) >= amountToTransfer
        ) {
            _contributeToTravelPlan(
                plan.travelPlanID,
                amountToTransfer,
                sender
            );

            paymentPlans[ID].amountSent += amountToTransfer;
            paymentPlans[ID].intervalsProcessed = interval;

            emit PaymentPlanIntervalEnded(ID, interval);

            if (interval < plan.totalIntervals) {
                _startInterval(ID);
            } else {
                _endPaymentPlan(ID);
            }
        }
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}