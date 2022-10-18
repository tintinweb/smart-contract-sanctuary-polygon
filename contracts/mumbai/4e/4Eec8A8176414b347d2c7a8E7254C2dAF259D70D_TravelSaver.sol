// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// import {IERC20} from "/home/karolsudol/flywallet/TravelSaver/node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

// import "@openzeppelin./";

contract TravelSaver {
    /**
     ***** ***** STRUCTS ***** *****
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

    /**
     ***** ***** STATE-VARIABLES ***** *****
     */

    // modifier onlyOwner() {
    //     require(msg.sender == owner);
    //     _;
    // }

    address public immutable operatorWallet;
    IERC20 public immutable token;

    uint256 travelPlanCount;
    uint256 paymentPlanCount;

    mapping(uint256 => TravelPlan) public travelPlans;
    mapping(uint256 => PaymentPlan) paymentPlans;
    mapping(uint256 => mapping(address => uint256)) public contributedAmount;

    constructor(address ERC20_, address operatorWallet_) {
        token = IERC20(ERC20_);
        operatorWallet = operatorWallet_;
    }

    /**
     ***** ***** VIEW-FUNCTIONS ***** *****
     */

    function getTravelPlanDetails(uint256 ID)
        external
        view
        returns (TravelPlan memory)
    {
        return travelPlans[ID];
    }

    function getPaymentPlanDetails(uint256 ID)
        external
        view
        returns (PaymentPlan memory)
    {
        return paymentPlans[ID];
    }

    /**
     ***** ***** EVENTS ***** *****
     */

    event CreatedTravelPlan(
        uint256 indexed ID,
        address indexed owner,
        TravelPlan travelPlan
    );

    event ContributeToTravelPlan(
        uint256 indexed ID,
        address indexed contributor,
        uint256 amount
    );
    event ClaimTravelPlan(uint256 indexed ID);

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event CreatedPaymentPlan(
        uint256 indexed ID,
        address indexed owner,
        PaymentPlan paymentPlan
    );

    event CancelPaymentPlan(
        uint256 indexed ID,
        address indexed owner,
        PaymentPlan paymentPlan
    );

    event StartPaymentPlanInterval(
        uint256 indexed ID,
        uint256 indexed callableOn,
        uint256 indexed amount,
        uint256 intervalNo
    );
    event PaymentPlanIntervalEnded(
        uint256 indexed ID,
        uint256 indexed intervalNo
    );
    event EndPaymentPlan(
        uint256 indexed ID,
        address indexed owner,
        PaymentPlan paymentPlan
    );

    /**
     ***** ***** STATE-CHANGING-EXTERNAL-FUNCTIONS ***** *****
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

    function createTravelPlan(uint256 operatorPlanID_, uint256 operatorUserID_)
        public
        returns (uint256)
    {
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

    function contributeToTravelPlan(uint256 ID, uint256 amount) external {
        TravelPlan storage plan = travelPlans[ID];
        require(block.timestamp >= plan.createdAt, "doesn't exist");
        require(!plan.claimed, "claimed");

        plan.contributedAmount += amount;

        contributedAmount[ID][msg.sender] += amount;
        token.transferFrom(msg.sender, address(this), amount);

        emit ContributeToTravelPlan(ID, msg.sender, amount);
        emit Transfer(msg.sender, address(this), amount);
    }

    function claimTravelPlan(uint256 ID) external {
        TravelPlan storage plan = travelPlans[ID];
        require(plan.owner == msg.sender, "not owner");
        require(plan.contributedAmount > 0, "nothing saved");
        require(!plan.claimed, "plan claimed");

        token.transfer(operatorWallet, plan.contributedAmount);
        plan.claimed = true;
        plan.claimedAt = block.timestamp;
        emit ClaimTravelPlan(ID);
        emit Transfer(address(this), operatorWallet, plan.contributedAmount);
    }

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
            "IERC20: Insuff Approval"
        );
        uint256 id = ++paymentPlanCount;

        paymentPlans[id] = PaymentPlan({
            travelPlanID: _travelPlanID,
            ID: id,
            totalAmount: totalIntervals * amountPerInterval,
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

    function cancelPaymentPlan(uint256 ID) external {
        require(msg.sender == paymentPlans[ID].sender, "only plan owner");
        _endPaymentPlan(ID);

        emit CancelPaymentPlan(ID, msg.sender, paymentPlans[ID]);
    }

    function runInterval(uint256 ID) external {
        _fulfillPaymentPlanInterval(ID);
    }

    function runIntervals(uint256[] memory IDs) external {
        for (uint256 i = 0; i < IDs.length; i++) {
            _fulfillPaymentPlanInterval(IDs[i]);
        }
    }

    /**
     ***** ***** STATE-CHANGING-PRIVATE-FUNCTIONS ***** *****
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

    function _endPaymentPlan(uint256 ID) internal {
        PaymentPlan memory plan = paymentPlans[ID];
        paymentPlans[ID].alive = false;
        emit EndPaymentPlan(ID, plan.sender, plan);
    }

    function _contributeToTravelPlan(
        uint256 ID,
        uint256 amount,
        address caller
    ) internal {
        TravelPlan storage plan = travelPlans[ID];
        require(block.timestamp >= plan.createdAt, "doesn't exist");
        require(!plan.claimed, "claimed");

        plan.contributedAmount += amount;

        contributedAmount[ID][caller] += amount;
        token.transferFrom(caller, address(this), amount);

        emit ContributeToTravelPlan(ID, caller, amount);
        emit Transfer(caller, address(this), amount);
    }

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