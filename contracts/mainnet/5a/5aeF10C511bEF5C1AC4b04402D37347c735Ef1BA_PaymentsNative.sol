// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

import "./Operators.sol";
import "./FeesCollectors.sol";
import "./IEIP712Verifier.sol";
import "./IPaymentsNative.sol";

/**
 * @title Payments Contract in Native Cryptocurencies.
 * @author Freeverse.io, www.freeverse.io
 * @dev Upon transfer of cryptocurrency to this contract, it remains
 * locked until an Operator confirms the success or failure of the
 * asset transfer required to fulfil this payment.
 *
 * If no confirmation is received from the operator during the PaymentWindow,
 * all funds received from the buyer are made available to the buyer for refund.
 *
 * To start a payment, signatures of both the buyer and the Operator are required:
 * - the buyer is the msg.sender (the buyer therefore signs the TX), 
 * - the operator's EIP712-signature of the PaymentInput struct is provided as input to the call.
 *
 * This contract maintains the balances of all users, it does not transfer them automatically.
 * Users need to explicitly call the 'withdraw' method, which withdraws balanceOf[msg.sender]
 * If a buyer has a non-zero local balance at the moment of starting a new payment,
 * the contract reuses it, and only requires the provision of the
 * remainder required (if any) as msg.value
 *
 * Each payment has the following State Machine:
 * - NOT_STARTED -> ASSET_TRANSFERRING, triggered by pay
 * - ASSET_TRANSFERRING -> PAID, triggered by relaying assetTransferSuccess signed by operator
 * - ASSET_TRANSFERRING -> REFUNDED, triggered by relaying assetTransferFailed signed by operator
 * - ASSET_TRANSFERRING -> REFUNDED, triggered by a refund request after expirationTime
 *
 * NOTE: To ensure that the payment process proceeds as expected when the payment starts,
 * upon acceptance of a payment, the following data: {operator, feesCollector, expirationTime}
 * is stored in the payment struct, and used throughout the payment, regardless of
 * any possible modifications to the contract's storage.
 *
 * NOTE: The contract allows a feature, 'Seller Registration', that can be used in the scenario that
 * applications want users to prove that they have enough crypto know-how (obtain native crypto,
 * pay for gas using a web3 wallet, etc.) to interact by themselves with this smart contract before selling,
 * so that they are less likely to require technical help in case they need to withdraw funds. 
 * - If _isSellerRegistrationRequired = true, this feature is enabled, and payments can only be initiated
 *    if the payment seller has previously exectuted the registerAsSeller method.
 * - If _isSellerRegistrationRequired = false, this feature is disabled, and payments can be initiated
 *    regardless of any previous call to the registerAsSeller method.
 */

contract PaymentsNative is IPaymentsNative, FeesCollectors, Operators {
    address private _eip712;
    string private _acceptedCurrency;
    uint256 private _paymentWindow;
    bool private _isSellerRegistrationRequired;
    mapping(address => bool) private _isRegisteredSeller;
    mapping(bytes32 => Payment) private _payments;
    mapping(address => uint256) private _balanceOf;

    constructor(string memory currencyDescriptor, address eip712) {
        _eip712 = eip712;
        _acceptedCurrency = currencyDescriptor;
        _paymentWindow = 30 days;
        _isSellerRegistrationRequired = false;
    }

    /**
     * @notice Sets the address of the EIP712 verifier contract.
     * @dev This upgradable pattern is required in case that the 
     *  EIP712 spec/code changes in the future
     * @param eip712address The address of the new EIP712 contract.
     */
    function setEIP712(address eip712address) external onlyOwner {
        _eip712 = eip712address;
        emit EIP712(eip712address);
    }

    /**
     * @notice Sets the amount of time available to the operator, after the payment starts,
     *  to confirm either the success or the failure of the asset transfer.
     *  After this time, the payment moves to FAILED, allowing buyer to withdraw.
     * @param window The amount of time available, in seconds.
     */
    function setPaymentWindow(uint256 window) external onlyOwner {
        require(
            (window < 60 days) && (window > 3 hours),
            "payment window outside limits"
        );
        _paymentWindow = window;
        emit PaymentWindow(window);
    }

    /**
     * @notice Sets whether sellers are required to register in this contract before being
     *  able to accept payments.
     * @param isRequired (bool) if true, registration is required.
     */
    function setIsSellerRegistrationRequired(bool isRequired)
        external
        onlyOwner
    {
        _isSellerRegistrationRequired = isRequired;
    }

    /// @inheritdoc IPaymentsNative
    function registerAsSeller() external {
        require(!_isRegisteredSeller[msg.sender], "seller already registered");
        _isRegisteredSeller[msg.sender] = true;
        emit NewSeller(msg.sender);
    }

    /// @inheritdoc IPaymentsNative
    function pay(PaymentInput calldata payInput, bytes calldata operatorSignature)
        external
        payable
    {
        require(
            msg.sender == payInput.buyer,
            "only buyer can execute this function"
        );
        checkPaymentInputs(payInput);
        address operator = universeOperator(payInput.universeId);
        require(
            IEIP712Verifier(_eip712).verifyPayment(payInput, operatorSignature, operator),
            "incorrect operator signature"
        );
        require(
            (operator != payInput.buyer) && (operator != payInput.seller),
            "operator must be an observer"
        );
        (uint256 newFunds, uint256 localFunds) = splitFundingSources(
            payInput.buyer,
            payInput.amount
        );
        require(
            msg.value == newFunds,
            "new funds provided does not match expected value"
        );
        _payments[payInput.paymentId] = Payment(
            State.AssetTransferring,
            payInput.buyer,
            payInput.seller,
            operator,
            universeFeesCollector(payInput.universeId),
            block.timestamp + _paymentWindow,
            payInput.feeBPS,
            payInput.amount
        );
        _balanceOf[payInput.buyer] -= localFunds;
        emit PayIn(payInput.paymentId, payInput.buyer, payInput.seller);
    }

    /// @inheritdoc IPaymentsNative
    function finalize(
        AssetTransferResult calldata transferResult,
        bytes calldata operatorSignature
    ) external {
        _finalize(transferResult, operatorSignature);
    }

    /// @inheritdoc IPaymentsNative
    function finalizeAndWithdraw(
        AssetTransferResult calldata transferResult,
        bytes calldata operatorSignature
    ) external {
        _finalize(transferResult, operatorSignature);
        _withdraw();
    }

    /// @inheritdoc IPaymentsNative
    function refund(bytes32 paymentId) public {
        _refund(paymentId);
    }

    /// @inheritdoc IPaymentsNative
    function refundAndWithdraw(bytes32 paymentId) external {
        _refund(paymentId);
        _withdraw();
    }

    /// @inheritdoc IPaymentsNative
    function withdraw() external {
        _withdraw();
    }

    /// @inheritdoc IPaymentsNative
    function withdrawAmount(uint256 amount) external {
        uint256 balance = _balanceOf[msg.sender];
        require(balance >= amount, "not enough balance to withdraw specified amount");
        _withdrawAmount(amount, balance - amount);
    }

    // PRIVATE FUNCTIONS

    /**
     * @dev (private) Moves the payment funds to the buyer's local balance
     *  The buyer still needs to withdraw afterwards.
     *  Moves the payment to REFUNDED state
     * @param paymentId The unique ID that identifies the payment.
     */
    function _refund(bytes32 paymentId) private {
        require(
            acceptsRefunds(paymentId),
            "payment does not accept refunds at this stage"
        );
        _refundToLocalBalance(paymentId);
    }

    /**
     * @dev (private) Uses the operator signed msg regarding asset transfer success to update
     *  the balances of seller (on success) or buyer (on failure).
     *  They still need to withdraw afterwards.
     *  Moves the payment to either PAID (on success) or REFUNDED (on failure) state
     * @param transferResult The asset transfer transferResult struct signed by the operator.
     * @param operatorSignature The operator signature of transferResult
     */
    function _finalize(
        AssetTransferResult calldata transferResult,
        bytes calldata operatorSignature
    ) private {
        Payment memory payment = _payments[transferResult.paymentId];
        require(
            payment.state == State.AssetTransferring,
            "payment not initially in asset transferring state"
        );
        require(
            IEIP712Verifier(_eip712).verifyAssetTransferResult(transferResult, operatorSignature, payment.operator),
            "only the operator can sign an assetTransferResult"
        );
        if (transferResult.wasSuccessful) {
            _finalizeSuccess(transferResult.paymentId, payment);
        } else {
            _finalizeFailed(transferResult.paymentId);
        }
    }

    /**
     * @dev (private) Updates the balance of the seller on successful asset transfer
     *  Moves the payment to PAID
     * @param paymentId The unique ID that identifies the payment.
     * @param payment The payment struct corresponding to paymentId
     */
    function _finalizeSuccess(bytes32 paymentId, Payment memory payment) private {
        _payments[paymentId].state = State.Paid;
        uint256 feeAmount = computeFeeAmount(payment.amount, payment.feeBPS);
        _balanceOf[payment.seller] += (payment.amount - feeAmount);
        _balanceOf[payment.feesCollector] += feeAmount;
        emit Paid(paymentId);
    }

    /**
     * @dev (private) Updates the balance of the buyer on failed asset transfer
     *  Moves the payment to REFUNDED
     * @param paymentId The unique ID that identifies the payment.
     */
    function _finalizeFailed(bytes32 paymentId) private {
        _refundToLocalBalance(paymentId);
    }

    /**
     * @dev (private) Executes refund, moves to REFUNDED state
     * @param paymentId The unique ID that identifies the payment.
     */
    function _refundToLocalBalance(bytes32 paymentId) private {
        _payments[paymentId].state = State.Refunded;
        Payment memory payment = _payments[paymentId];
        _balanceOf[payment.buyer] += payment.amount;
        emit BuyerRefunded(paymentId, payment.buyer);
    }

    /**
     * @dev (private) Transfers funds available in this
     *  contract's balanceOf[msg.sender] to msg.sender
     *  Follows standard Checks-Effects-Interactions pattern
     *  to protect against re-entrancy attacks.
     */
    function _withdraw() private {
        _withdrawAmount(_balanceOf[msg.sender], 0);
    }

    /**
     * @dev (private) Transfers the specified amount of 
     *  funds in this contract's balanceOf[msg.sender] to msg.sender
     *  The checks that enough amount is available, and the computation
     *  of the final balance need to be done before calling this function.
     *  Follows standard Checks-Effects-Interactions pattern
     *  to protect against re-entrancy attacks.
     * @param amount The amount to withdraw.
     * @param finalBalance The final balance of msg.sender after withdrawal.
    */
    function _withdrawAmount(uint256 amount, uint256 finalBalance) private {
        require(amount > 0, "cannot withdraw zero amount");
        _balanceOf[msg.sender] = finalBalance;
        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    // VIEW FUNCTIONS

    /// @inheritdoc IPaymentsNative
    function isSellerRegistrationRequired() external view returns (bool) {
        return _isSellerRegistrationRequired;
    }

    /// @inheritdoc IPaymentsNative
    function isRegisteredSeller(address addr) external view returns (bool) {
        return _isRegisteredSeller[addr];
    }

    /// @inheritdoc IPaymentsNative
    function balanceOf(address addr) external view returns (uint256) {
        return _balanceOf[addr];
    }

    /// @inheritdoc IPaymentsNative
    function paymentInfo(bytes32 paymentId)
        external
        view
        returns (Payment memory)
    {
        return _payments[paymentId];
    }

    /// @inheritdoc IPaymentsNative
    function paymentState(bytes32 paymentId) public view returns (State) {
        return _payments[paymentId].state;
    }

    /// @inheritdoc IPaymentsNative
    function acceptsRefunds(bytes32 paymentId) public view returns (bool) {
        return
            (paymentState(paymentId) == State.AssetTransferring) &&
            (block.timestamp > _payments[paymentId].expirationTime);
    }

    /// @inheritdoc IPaymentsNative
    function EIP712Address() external view returns (address) {
        return _eip712;
    }

    /// @inheritdoc IPaymentsNative
    function paymentWindow() external view returns (uint256) {
        return _paymentWindow;
    }

    /// @inheritdoc IPaymentsNative
    function acceptedCurrency() external view returns (string memory) {
        return _acceptedCurrency;
    }

    function enoughFundsAvailable(address buyer, uint256 amount)
        public
        view
        returns (bool)
    {
        return maxFundsAvailable(buyer) >= amount;
    }

    /// @inheritdoc IPaymentsNative
    function maxFundsAvailable(address buyer) public view returns (uint256) {
        return _balanceOf[buyer] + buyer.balance;
    }

    /// @inheritdoc IPaymentsNative
    function splitFundingSources(address buyer, uint256 amount)
        public
        view
        returns (uint256 externalFunds, uint256 localFunds)
    {
        uint256 localBalance = _balanceOf[buyer];
        localFunds = (amount > localBalance) ? localBalance : amount;
        externalFunds = (amount > localBalance) ? amount - localBalance : 0;
    }

    /// @inheritdoc IPaymentsNative
    function checkPaymentInputs(PaymentInput calldata payInput) public view {
        require(payInput.feeBPS <= 10000, "fee cannot be larger than 100 percent");
        require(
            paymentState(payInput.paymentId) == State.NotStarted,
            "payment in incorrect curent state"
        );
        require(block.timestamp <= payInput.deadline, "payment deadline expired");
        if (_isSellerRegistrationRequired)
            require(_isRegisteredSeller[payInput.seller], "seller not registered");
    }

    // PURE FUNCTIONS

    /// @inheritdoc IPaymentsNative
    function computeFeeAmount(uint256 amount, uint256 feeBPS)
        public
        pure
        returns (uint256)
    {
        uint256 feeAmount = (amount * feeBPS) / 10000;
        return (feeAmount <= amount) ? feeAmount : amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

import "openzeppelin-solidity/contracts/access/Ownable.sol";

/**
 * @title Management of Operators.
 * @author Freeverse.io, www.freeverse.io
 * @dev The Operator role is to execute the actions required when
 * payments arrive to this contract, and then either
 * confirm the success of those actions, or confirm the failure.
 *
 * The constructor sets a defaultOperator = deployer.
 * The owner of the contract can change the defaultOperator.
 *
 * The owner of the contract can assign explicit operators to each universe.
 * If a universe does not have an explicitly assigned operator,
 * the default operator is used.
 */

contract Operators is Ownable {
    /**
     * @dev Event emitted on change of default operator
     * @param operator The address of the new default operator
     */
    event DefaultOperator(address indexed operator);

    /**
     * @dev Event emitted on change of a specific universe operator
     * @param universeId The id of the universe
     * @param operator The address of the new universe operator
     */
    event UniverseOperator(uint256 indexed universeId, address indexed operator);

    /// @dev The address of the default operator:
    address private _defaultOperator;

    /// @dev The mapping from universeId to specific universe operator:
    mapping(uint256 => address) private _universeOperators;

    constructor() {
        _defaultOperator = msg.sender;
        emit DefaultOperator(msg.sender);
    }

    /**
     * @dev Sets a new default operator
     * @param operator The address of the new default operator
     */
    function setDefaultOperator(address operator) external onlyOwner {
        _defaultOperator = operator;
        emit DefaultOperator(operator);
    }

    /**
     * @dev Sets a new specific universe operator
     * @param universeId The id of the universe
     * @param operator The address of the new universe operator
     */
    function setUniverseOperator(uint256 universeId, address operator)
        external
        onlyOwner
    {
        _universeOperators[universeId] = operator;
        emit UniverseOperator(universeId, operator);
    }

    /**
     * @dev Removes a specific universe operator
     * @notice The universe will then be operated by _defaultOperator
     * @param universeId The id of the universe
     */
    function removeUniverseOperator(uint256 universeId) external onlyOwner {
        delete _universeOperators[universeId];
        emit UniverseOperator(universeId, _defaultOperator);
    }

    /**
     * @dev Returns the default operator
     */
    function defaultOperator() external view returns (address) {
        return _defaultOperator;
    }

    /**
     * @dev Returns the operator of a specific universe
     * @param universeId The id of the universe
     */
    function universeOperator(uint256 universeId)
        public
        view
        returns (address)
    {
        address storedOperator = _universeOperators[universeId];
        return storedOperator == address(0) ? _defaultOperator : storedOperator;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

/**
 * @title Interface for Structs required in MetaTXs using EIP712.
 * @author Freeverse.io, www.freeverse.io
 * @dev This contract defines two structures (PaymentInput, AssetTransferResult),
 *  required for the payment process. Both structures require a separate implementation
 *  of their corresponding EIP712-verifying functions.
 */

interface ISignableStructs {

    /**
    * @notice The main struct that characterizes a payment
    * @dev used as input to the pay method
    * @dev it needs to be signed following EIP712
    */
    struct PaymentInput {
        // the unique Id that identifies a payment,
        // obtained from a sufficiently large source of entropy.
        bytes32 paymentId;

        // the price of the asset, an integer expressed in the
        // lowest unit of the native cryptocurrency.
        uint256 amount;

        // the fee that will be charged by the feeOperator,
        // expressed as percentage Basis Points (bps), applied to amount.
        uint256 feeBPS;

        // the id of the universe that the asset belongs to.
        uint256 universeId;

        // the deadline for the payment to arrive to this
        // contract, otherwise it will be rejected.
        uint256 deadline;

        // the buyer, providing the required funds, who shall receive
        // the asset on a successful payment.
        address buyer;

        // the seller of the asset, who shall receive the funds
        // (subtracting fees) on a successful payment.
        address seller;
    }

    /**
    * @notice The struct that specifies the success or failure of an asset transfer
    * @dev It needs to be signed by the operator following EIP712
    * @dev Must arrive when the asset is in ASSET_TRANSFERING state, to then move to PAID or REFUNDED
    */
    struct AssetTransferResult {
        // the unique Id that identifies a payment previously initiated in this contract.
        bytes32 paymentId;

        // a bool set to true if the asset was successfully transferred, false otherwise
        bool wasSuccessful;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

import "./ISignableStructs.sol";

/**
 * @title Interface to Payments Contract in Native Cryptocurencies.
 * @author Freeverse.io, www.freeverse.io
 * @dev Upon transfer of cryptocurrency to this contract, it remains
 * locked until an Operator confirms the success or failure of the
 * asset transfer required to fulfil this payment.
 *
 * If no confirmation is received from the operator during the PaymentWindow,
 * all funds received from the buyer are made available to the buyer for refund.
 *
 * To start a payment, signatures of both the buyer and the Operator are required:
 * - the buyer is the msg.sender (the buyer therefore signs the TX), 
 * - the operator's EIP712-signature of the PaymentInput struct is provided as input to the call.
 *
 * This contract maintains the balances of all users, it does not transfer them automatically.
 * Users need to explicitly call the 'withdraw' method, which withdraws balanceOf[msg.sender]
 * If a buyer has a non-zero local balance at the moment of starting a new payment,
 * the contract reuses it, and only requires the provision of the
 * remainder required (if any) as msg.value
 *
 * Each payment has the following State Machine:
 * - NOT_STARTED -> ASSET_TRANSFERRING, triggered by pay
 * - ASSET_TRANSFERRING -> PAID, triggered by relaying assetTransferSuccess signed by operator
 * - ASSET_TRANSFERRING -> REFUNDED, triggered by relaying assetTransferFailed signed by operator
 * - ASSET_TRANSFERRING -> REFUNDED, triggered by a refund request after expirationTime
 *
 * NOTE: To ensure that the payment process proceeds as expected when the payment starts,
 * upon acceptance of a payment, the following data: {operator, feesCollector, expirationTime}
 * is stored in the payment struct, and used throughout the payment, regardless of
 * any possible modifications to the contract's storage.
 *
 */

interface IPaymentsNative is ISignableStructs {
    /**
     * @dev Event emitted on change of EIP712 verifier contract address
     * @param eip712address The address of the new EIP712 verifier contract
     */

    event EIP712(address eip712address);

    /**
     * @dev Event emitted on change of payment window
     * @param window The new amount of time after the arrival of a payment for which, 
     *  in absence of confirmation of asset transfer success, a buyer is allowed to refund
     */
    event PaymentWindow(uint256 window);

    /**
     * @dev Event emitted when a user executes the registerAsSeller method
     * @param seller The address of the newly registeredAsSeller user.
     */
    event NewSeller(address indexed seller);

    /**
     * @dev Event emitted when a buyer is refunded for a given payment process
     * @param paymentId The id of the already initiated payment 
     * @param buyer The address of the refunded buyer
     */
    event BuyerRefunded(bytes32 indexed paymentId, address indexed buyer);

    /**
     * @dev Event emitted when funds for a given payment arrive to this contract
     * @param paymentId The unique id identifying the payment 
     * @param buyer The address of the buyer providing the funds
     * @param seller The address of the seller of the asset
     */
    event PayIn(
        bytes32 indexed paymentId,
        address indexed buyer,
        address indexed seller
    );

    /**
     * @dev Event emitted when a payment process arrives at the PAID 
     *  final state, where the seller receives the funds.
     * @param paymentId The id of the already initiated payment 
     */
    event Paid(bytes32 indexed paymentId);

    /**
     * @dev Event emitted when user withdraws funds from this contract
     * @param user The address of the user that withdraws
     * @param amount The amount withdrawn, in lowest units of the native cryptocurrency
     */
    event Withdraw(address indexed user, uint256 amount);

    /**
     * @dev The enum characterizing the possible states of a payment process
     */
    enum State {
        NotStarted,
        AssetTransferring,
        Refunded,
        Paid
    }

    /**
     * @notice Main struct stored with every payment.
     *  All variables of the struct remain immutable throughout a payment process
     *  except for `state`.
     */
    struct Payment {
        // the current state of the payment process
        State state;

        // the buyer, providing the required funds, who shall receive
        // the asset on a successful payment.
        address buyer;

        // the seller of the asset, who shall receive the funds
        // (subtracting fees) on a successful payment.        
        address seller;

        // The address of the operator of this payment
        address operator;

        // The address of the feesCollector of this payment
        address feesCollector;

        // The timestamp after which, in absence of confirmation of 
        // asset transfer success, a buyer is allowed to refund
        uint256 expirationTime;

        // the percentage fee expressed in Basis Points (bps), typical in finance
        // Examples:  2.5% = 250 bps, 10% = 1000 bps, 100% = 10000 bps
        uint256 feeBPS;

        // the price of the asset, an integer expressed in the
        // lowest unit of the ERC20 token.
        uint256 amount;
    }

    /**
     * @notice Registers msg.sender as seller so that, if the contract has set
     *  _isSellerRegistrationRequired = true, then payments will be accepted with
     *  msg.sender as seller.
    */
    function registerAsSeller() external;

    /**
     * @notice Starts Payment process by the buyer.
     * @dev Executed by the buyer, who relays the MetaTX with the operator's signature.
     *  The buyer must provide the correct amount via msg.value.
     *  If all requirements are fulfilled, it stores the data relevant
     *  for the next steps of the payment, and it locks the funds
     *  in this contract.
     *  Follows standard Checks-Effects-Interactions pattern
     *  to protect against re-entrancy attacks.
     *  Moves payment to ASSET_TRANSFERRING state.
     * @param payInput The struct containing all required payment data
     * @param operatorSignature The signature of 'payInput' by the operator
     */
    function pay(PaymentInput calldata payInput, bytes calldata operatorSignature)
        external
        payable;

    /**
     * @notice Relays the operator signature declaring that the asset transfer was successful or failed,
     *  and updates balances of seller or buyer, respectively.
     * @dev Can be executed by anyone, but the operator signature must be included as input param.
     *  Seller or Buyer's balances are updated, allowing explicit withdrawal.
     *  Moves payment to PAID or REFUNDED state on transfer success/failure, respectively.
     * @param transferResult The asset transfer result struct signed by the operator.
     * @param operatorSignature The operator signature of transferResult
     */
    function finalize(
        AssetTransferResult calldata transferResult,
        bytes calldata operatorSignature
    ) external;

    /**
     * @notice Relays the operator signature declaring that the asset transfer was successful or failed,
     *  updates balances of seller or buyer, respectively,
     *  and proceeds to withdraw all funds in this contract available to msg.sender.
     * @dev Can be executed by anyone, but the operator signature must be included as input param.
     *  It is, however, expected to be executed by the seller, in case of a successful asset transfer,
     *  or the buyer, in case of a failed asset transfer.
     *  Moves payment to PAID or REFUNDED state on transfer success/failure, respectively.
     * @param transferResult The asset transfer result struct signed by the operator.
     * @param operatorSignature The operator signature of transferResult
     */
    function finalizeAndWithdraw(
        AssetTransferResult calldata transferResult,
        bytes calldata operatorSignature
    ) external;

    /**
     * @notice Moves buyer's provided funds to buyer's balance.
     * @dev Anybody can call this function.
     *  Requires acceptsRefunds == true to proceed.
     *  After updating buyer's balance, he/she can later withdraw.
     *  Moves payment to REFUNDED state.
     * @param paymentId The unique ID that identifies the payment.
     */
    function refund(bytes32 paymentId) external;

    /**
     * @notice Executes refund and withdraw in one transaction.
     * @dev Anybody can call this function.
     *  Requires acceptsRefunds == true to proceed.
     *  All of msg.sender's balance in the contract is withdrawn,
     *  not only the part that was locked in this particular paymentId
     *  Moves payment to REFUNDED state.
     * @param paymentId The unique ID that identifies the payment.
     */
    function refundAndWithdraw(bytes32 paymentId) external;

    /**
     * @notice Transfers funds avaliable in this
     *  contract's balanceOf[msg.sender] to msg.sender
     */
    function withdraw() external;

    /**
     * @notice Transfers only the specified amount
     *  from this contract's balanceOf[msg.sender] to msg.sender.
     *  Reverts if balanceOf[msg.sender] < amount.
     * @param amount The required amount to withdraw
     */
    function withdrawAmount(uint256 amount) external;

    // VIEW FUNCTIONS

    /**
     * @notice Returns whether sellers need to be registered to be able to accept payments
     * @return Returns true if sellers need to be registered to be able to accept payments
     */
    function isSellerRegistrationRequired() external view returns (bool);

    /**
     * @notice Returns true if the address provided is a registered seller
     * @param addr the address that is queried
     * @return Returns whether the address is registered as seller
     */
    function isRegisteredSeller(address addr) external view returns (bool);

    /**
     * @notice Returns the local balance of the provided address that is stored in this
     *  contract, and hence, available for withdrawal.
     * @param addr the address that is queried
     * @return the local balance
     */
    function balanceOf(address addr) external view returns (uint256);

    /**
     * @notice Returns all data stored in a payment
     * @param paymentId The unique ID that identifies the payment.
     * @return the struct stored for the payment
     */
    function paymentInfo(bytes32 paymentId)
        external
        view
        returns (Payment memory);

    /**
     * @notice Returns the state of a payment.
     * @dev If payment is in ASSET_TRANSFERRING, it may be worth
     *  checking acceptsRefunds ot check if it has gone beyond expirationTime.
     * @param paymentId The unique ID that identifies the payment.
     * @return the state of the payment.
     */
    function paymentState(bytes32 paymentId) external view returns (State);

    /**
     * @notice Returns true if the payment accepts a refund to the buyer
     * @dev The payment must be in ASSET_TRANSFERRING and beyond expirationTime.
     * @param paymentId The unique ID that identifies the payment.
     * @return true if the payment accepts a refund to the buyer.
     */
    function acceptsRefunds(bytes32 paymentId) external view returns (bool);

    /**
     * @notice Returns the address of the of the contract containing
     *  the implementation of the EIP712 verifying functions
     * @return the address of the EIP712 verifier contract
     */
    function EIP712Address() external view returns (address);

    /**
     * @notice Returns the amount of seconds that a payment
     *  can remain in ASSET_TRANSFERRING state without positive
     *  or negative confirmation by the operator
     * @return the payment window in secs
     */
    function paymentWindow() external view returns (uint256);

    /**
     * @notice Returns a descriptor about the currency that this contract accepts
     * @return the string describing the currency
     */
    function acceptedCurrency() external view returns (string memory);

    /**
     * @notice Returns true if the 'amount' required for a payment is available to this contract.
     * @dev In more detail: returns true if the sum of the buyer's local balance in this contract,
     *  plus the external balance in the native crypto, are larger or equal than 'amount'
     * @param buyer The address for which funds are queried
     * @param amount The amount that is queried
     * @return Returns true if enough funds are available
     */
    function enoughFundsAvailable(address buyer, uint256 amount)
        external
        view
        returns (bool);

    /**
     * @notice Returns the maximum amount of funds available to a buyer
     * @dev In more detail: returns the sum of the buyer's local balance in this contract,
     *  plus the external balance in the native crypto.
     * @param buyer The address for which funds are queried
     * @return the max funds available
     */
    function maxFundsAvailable(address buyer) external view returns (uint256);

    /**
     * @notice Splits the funds required to pay 'amount' into two sources:
     *  - externalFunds: the amount of crypto required to be transferred from the external buyer balance
     *  - localFunds: the amount of crypto required from the buyer's already available balance in this contract.
     * @param buyer The address for which the amount is to be split
     * @param amount The amount to be split
     * @return externalFunds The amount of funds required to be transferred from the external buyer balance
     * @return localFunds The amount of local funds that will be used.
     */
    function splitFundingSources(address buyer, uint256 amount)
        external
        view
        returns (uint256 externalFunds, uint256 localFunds);

    /**
     * @notice Reverts unless the requirements for a PaymentInput are fulfilled.
     * @param payInput The PaymentInput struct
     */
    function checkPaymentInputs(PaymentInput calldata payInput) external view;

    // PURE FUNCTIONS

    /**
     * @notice Safe computation of fee amount for a provided amount, feeBPS pair
     * @dev Must return a value that is guaranteed to be less or equal to the provided amount
     * @param amount The amount
     * @param feeBPS The percentage fee expressed in Basis Points (bps).
     *  feeBPS examples:  2.5% = 250 bps, 10% = 1000 bps, 100% = 10000 bps
     * @return The fee amount
     */
    function computeFeeAmount(uint256 amount, uint256 feeBPS)
        external
        pure
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

import "./ISignableStructs.sol";

/**
 * @title Interface to Verification of MetaTXs for Payments using EIP712.
 * @author Freeverse.io, www.freeverse.io
 * @dev This contract defines the interface to the two verifying functions
 *  for the structs defined in ISignableStructs (PaymentInput, AssetTransferResult),
 *  used within the payment process.
 */

interface IEIP712Verifier is ISignableStructs {

    /**
     * @notice Verifies that the provided PaymentInput struct has been signed
     *  by the provided signer.
     * @param payInput The provided PaymentInput struct
     * @param signature The provided signature of the input struct
     * @param signer The signer's address that we want to verify
     * @return Returns true if the signature corresponds to the
     *  provided signer having signed the input struct
     */
    function verifyPayment(
        PaymentInput calldata payInput,
        bytes calldata signature,
        address signer
    ) external view returns (bool);

    /**
     * @notice Verifies that the provided AssetTransferResult struct
     *  has been signed by the provided signer.
     * @param transferResult The provided AssetTransferResult struct
     * @param signature The provided signature of the input struct
     * @param signer The signer's address that we want to verify
     * @return Returns true if the signature corresponds to the signer
     *  having signed the input struct
     */
    function verifyAssetTransferResult(
        AssetTransferResult calldata transferResult,
        bytes calldata signature,
        address signer
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

import "openzeppelin-solidity/contracts/access/Ownable.sol";

/**
 * @title Management of Fees Collectors.
 * @author Freeverse.io, www.freeverse.io
 * @dev FeesCollectors are just the addresses to which fees
 * are paid when payments are successfully completed.
 *
 * The constructor sets a defaultFeesCollector = deployer.
 * The owner of the contract can change the defaultFeesCollector.
 *
 * The owner of the contract can assign explicit feesCollectors to each universe.
 * If a universe does not have an explicitly assigned feesCollector,
 * the default feesCollector is used.
 */

contract FeesCollectors is Ownable {
    /**
     * @dev Event emitted on change of default feesCollector
     * @param feesCollector The address of the new default feesCollector
     */
    event DefaultFeesCollector(address indexed feesCollector);

    /**
     * @dev Event emitted on change of a specific universe feesCollector
     * @param universeId The id of the universe
     * @param feesCollector The address of the new universe feesCollector
     */
    event UniverseFeesCollector(uint256 indexed universeId, address indexed feesCollector);

    /// @dev The address of the default feesCollector:
    address private _defaultFeesCollector;

    /// @dev The mapping from universeId to specific universe feesCollector:
    mapping(uint256 => address) private _universeFeesCollectors;

    constructor() {
        _defaultFeesCollector = msg.sender;
        emit DefaultFeesCollector(msg.sender);
    }

    /**
     * @dev Sets a new default feesCollector
     * @param feesCollector The address of the new default feesCollector
     */
    function setDefaultFeesCollector(address feesCollector) external onlyOwner {
        _defaultFeesCollector = feesCollector;
        emit DefaultFeesCollector(feesCollector);
    }

    /**
     * @dev Sets a new specific universe feesCollector
     * @param universeId The id of the universe
     * @param feesCollector The address of the new universe feesCollector
     */
    function setUniverseFeesCollector(uint256 universeId, address feesCollector)
        external
        onlyOwner
    {
        _universeFeesCollectors[universeId] = feesCollector;
        emit UniverseFeesCollector(universeId, feesCollector);
    }

    /**
     * @dev Removes a specific universe feesCollector
     * @notice The universe will then have fees collected by _defaultFeesCollector
     * @param universeId The id of the universe
     */
    function removeUniverseFeesCollector(uint256 universeId)
        external
        onlyOwner
    {
        delete _universeFeesCollectors[universeId];
        emit UniverseFeesCollector(universeId, _defaultFeesCollector);
    }

    /**
     * @dev Returns the default feesCollector
     */
    function defaultFeesCollector() external view returns (address) {
        return _defaultFeesCollector;
    }

    /**
     * @dev Returns the feesCollector of a specific universe
     * @param universeId The id of the universe
     */
    function universeFeesCollector(uint256 universeId)
        public
        view
        returns (address)
    {
        address storedFeesCollector = _universeFeesCollectors[universeId];
        return
            storedFeesCollector == address(0)
                ? _defaultFeesCollector
                : storedFeesCollector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}