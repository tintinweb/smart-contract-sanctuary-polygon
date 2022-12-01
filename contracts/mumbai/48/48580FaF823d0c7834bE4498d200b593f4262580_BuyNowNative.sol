// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import "./IBuyNowNative.sol";
import "./base/BuyNowBase.sol";

/**
 * @title Escrow Contract for Payments in BuyNow mode, in Native Cryptocurrency.
 * @author Freeverse.io, www.freeverse.io
 * @notice Full contract documentation in IBuyNowNative
 */

contract BuyNowNative is IBuyNowNative, BuyNowBase {

    address public sender;
    uint256 public value;
    uint256 internal _TINYBAR_TO_WEI = 10000000000;
    
    constructor(string memory currencyDescriptor, address eip712) BuyNowBase(currencyDescriptor, eip712) {}

    /// @inheritdoc IBuyNowNative
    function buyNow(
        BuyNowInput memory buyNowInp,
        bytes calldata operatorSignature,
        bytes calldata sellerSignature
    ) external payable {
        require(
            msg.sender == buyNowInp.buyer,
            "BuyNowNative::buyNow: only buyer can execute this function"
        );
        address operator = universeOperator(buyNowInp.universeId);
        require(
            IEIP712VerifierBuyNow(_eip712).verifyBuyNow(buyNowInp, operatorSignature, operator),
            "BuyNowNative::buyNow: incorrect operator signature"
        );
        buyNowInp.amount = (buyNowInp.amount / _TINYBAR_TO_WEI);
        // The following requirement avoids possible mistakes in building the TX's msg.value.
        // While the funds provided can be less than the asset price (in case of buyer having local balance),
        // there is no reason for providing more funds than the asset price.
        require(
            (msg.value <= buyNowInp.amount),
            "BuyNowNative::buyNow: new funds provided must be less than bid amount"
        );
        _processBuyNow(buyNowInp, operator, sellerSignature);
    }

    // PRIVATE & INTERNAL FUNCTIONS

    /**
     * @dev Updates buyer's local balance, re-using it if possible, and adding excess of provided funds, if any.
     *  It is difficult to predict the exact msg.value required at the moment of submitting a payment,
     *  because localFunds may have just increased due to an asynchronously finished sale by the buyer.
     *  Any possible excess of provided funds is moved to buyer's local balance.
     * @param buyer The address executing the payment
     * @param newFundsNeeded The elsewhere computed minimum amount of funds required to be provided by the buyer,
     *  having possible re-use of local funds into account
     * @param localFunds The elsewhere computed amount of funds available to the buyer in this contract that will be
     *  re-used in the payment
     */
    function _updateBuyerBalanceOnPaymentReceived(
        address buyer,
        uint256 newFundsNeeded,
        uint256 localFunds
    ) internal override {
        require(
            (msg.value >= newFundsNeeded),
            "BuyNowNative::_updateBuyerBalanceOnPaymentReceived: new funds provided are not within required range"
        );
        // The next operation can never underflow due to the previous constraint,
        // and to the fact that splitFundingSources guarantees that _balanceOf[buyer] >= localFunds
        _balanceOf[buyer] = (_balanceOf[buyer] + msg.value) - newFundsNeeded - localFunds;
    }

    /**
     * @dev Transfers the specified amount to the specified address.
     *  Requirements and effects (e.g. balance updates) are performed
     *  before calling this function.
     * @param to The address that must receive the funds.
     * @param amount The amount to transfer.
    */
    function _transfer(address to, uint256 amount) internal override {
        (bool success, ) = to.call{value: amount}("");
        require(success, "BuyNowNative::_transfer: unable to send value, recipient may have reverted");
    }

    // VIEW FUNCTIONS

    /**
     * @notice Returns the amount available to a buyer outside this contract
     * @param buyer The address for which funds are queried
     * @return the external funds available
     */
    function externalBalance(address buyer) public view override returns (uint256) {
        return buyer.balance;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Management of Operators.
 * @author Freeverse.io, www.freeverse.io
 * @dev The Operator role is to execute the actions required when
 * payments arrive to this contract, and then either
 * confirm the success of those actions, or confirm the failure.
 * All parties agree explicitly on a specific address to
 * act as an Operator for each individual payment process.
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
   * @param prevOperator The previous value of operator
   */
  event DefaultOperator(address indexed operator, address indexed prevOperator);

  /**
   * @dev Event emitted on change of a specific universe operator
   * @param universeId The id of the universe
   * @param operator The address of the new universe operator
   * @param prevOperator The previous value of operator
   */
  event UniverseOperator(
    uint256 indexed universeId,
    address indexed operator,
    address indexed prevOperator
  );

  /// @dev The address of the default operator:
  address private _defaultOperator;

  /// @dev The mapping from universeId to specific universe operator:
  mapping(uint256 => address) private _universeOperators;

  constructor() {
    setDefaultOperator(msg.sender);
  }

  /**
   * @dev Sets a new default operator
   * @param operator The address of the new default operator
   */
  function setDefaultOperator(address operator) public onlyOwner {
    emit DefaultOperator(operator, _defaultOperator);
    _defaultOperator = operator;
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
    emit UniverseOperator(universeId, operator, universeOperator(universeId));
    _universeOperators[universeId] = operator;
  }

  /**
   * @dev Removes a specific universe operator
   * @notice The universe will then be operated by _defaultOperator
   * @param universeId The id of the universe
   */
  function removeUniverseOperator(uint256 universeId) external onlyOwner {
    emit UniverseOperator(
      universeId,
      _defaultOperator,
      _universeOperators[universeId]
    );
    delete _universeOperators[universeId];
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
  function universeOperator(uint256 universeId) public view returns (address) {
    address storedOperator = _universeOperators[universeId];
    return storedOperator == address(0) ? _defaultOperator : storedOperator;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";

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
   * @param prevFeesCollector The previous value of feesCollector
   */
  event DefaultFeesCollector(
    address indexed feesCollector,
    address indexed prevFeesCollector
  );

  /**
   * @dev Event emitted on change of a specific universe feesCollector
   * @param universeId The id of the universe
   * @param feesCollector The address of the new universe feesCollector
   * @param prevFeesCollector The previous value of feesCollector
   */
  event UniverseFeesCollector(
    uint256 indexed universeId,
    address indexed feesCollector,
    address indexed prevFeesCollector
  );

  /// @dev The address of the default feesCollector:
  address private _defaultFeesCollector;

  /// @dev The mapping from universeId to specific universe feesCollector:
  mapping(uint256 => address) private _universeFeesCollectors;

  constructor() {
    setDefaultFeesCollector(msg.sender);
  }

  /**
   * @dev Sets a new default feesCollector
   * @param feesCollector The address of the new default feesCollector
   */
  function setDefaultFeesCollector(address feesCollector) public onlyOwner {
    emit DefaultFeesCollector(feesCollector, _defaultFeesCollector);
    _defaultFeesCollector = feesCollector;
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
    emit UniverseFeesCollector(
      universeId,
      feesCollector,
      universeFeesCollector(universeId)
    );
    _universeFeesCollectors[universeId] = feesCollector;
  }

  /**
   * @dev Removes a specific universe feesCollector
   * @notice The universe will then have fees collected by _defaultFeesCollector
   * @param universeId The id of the universe
   */
  function removeUniverseFeesCollector(uint256 universeId) external onlyOwner {
    emit UniverseFeesCollector(
      universeId,
      _defaultFeesCollector,
      _universeFeesCollectors[universeId]
    );
    delete _universeFeesCollectors[universeId];
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
pragma solidity =0.8.14;

/**
 * @title Interface for structs required in MetaTXs using EIP712.
 * @author Freeverse.io, www.freeverse.io
 * @dev This contract defines 2 structures (BuyNowInput, AssetTransferResult),
 *  required for the BuyNow processes. These structures require a separate implementation
 *  of their corresponding EIP712-verifying functions.
 */

interface ISignableStructsBuyNow {
    /**
     * @notice The main struct that characterizes a buyNow
     * @dev Used as input to the buyNow method
     * @dev it needs to be signed following EIP712
     */
    struct BuyNowInput {
        // the unique Id that identifies a payment,
        // common to both Auctions and BuyNows,
        // obtained from hashing params related to the listing,
        // including a sufficiently large source of entropy.
        bytes32 paymentId;

        // the price of the asset, an integer expressed in the
        // lowest unit of the currency.
        uint256 amount;

        // the fee that will be charged by the feeOperator,
        // expressed as percentage Basis Points (bps), applied to amount.
        // e.g. feeBPS = 500 applies a 5% fee.
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
pragma solidity =0.8.14;

import "./ISignableStructsBuyNow.sol";

/**
 * @title Interface to Verification of MetaTXs for BuyNows.
 * @author Freeverse.io, www.freeverse.io
 * @dev This contract defines the interface to the two verifying functions
 *  for the structs defined in ISignableStructsBuyNow (BuyNowInput, AssetTransferResult),
 *  used within the BuyNow process, as well as to the function that verifies
 *  the seller signature agreeing to list the asset.
 *  Potential future changes in any of these signing methods can be handled by having
 *  the main contract redirect to a different verifier contract.
 */

interface IEIP712VerifierBuyNow is ISignableStructsBuyNow {
    /**
     * @notice Verifies that the provided BuyNowInput struct has been signed
     *  by the provided signer.
     * @param buyNowInp The provided BuyNowInput struct
     * @param signature The provided signature of the input struct
     * @param signer The signer's address that we want to verify
     * @return Returns true if the signature corresponds to the
     *  provided signer having signed the input struct
     */
    function verifyBuyNow(
        BuyNowInput calldata buyNowInp,
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

    /**
     * @notice Verifies the seller signature showing agreement
     *  to list the asset as ruled by this explicit paymentId.
     * @dev To anticipate for future potential differences in verifiers for
     *  BuyNow/Auction listings, the interfaces to verifiers for both flows are
     *  kept separate, accepting the entire respective structs as input.
     *  For the same reason, the interface declares the method as 'view', prepared
     *  to use EIP712 flows, even if the initial implementation can be 'pure'.
     * @param sellerSignature the signature of the seller agreeing to list the asset as ruled by
     *  this explicit paymentId
     * @param buyNowInp The provided BuyNowInput struct
     * @return Returns true if the seller signature is correct
     */
    function verifySellerSignature(
        bytes calldata sellerSignature,
        BuyNowInput calldata buyNowInp
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import "./ISignableStructsBuyNow.sol";

/**
 * @title Interface to base Escrow Contract for Payments in BuyNow mode.
 * @author Freeverse.io, www.freeverse.io
 * @dev The contract that implements this interface only operates the BuyNow path of a payment;
 * it derives from previously audited code, except for minimal method name changes and
 * several methods changed from 'private' to 'internal'
 * The contract that implements this interface can be inherited to:
 * - conduct buyNows in either native crypto or ERC20 tokens
 * - add more elaborated payment processes (such as Auctions)
 *
 * The contract that implements this interface operates as an escrow
 * for paying for assets in BuyNow mode: the first buyer that
 * executes the buyNow method gets the asset.
 *
 * ROLES: Buyers/bidders explicitly sign the agreement to let the specified Operator address
 * act as an Oracle, responsible for signing the success or failure of the asset transfer,
 * which is conducted outside this contract upon reception of funds.
 *
 * If no confirmation is received from the Operator during the PaymentWindow,
 * all funds received from the buyer are made available to him/her for refund.
 * Throughout the contract, this moment is labeled as 'expirationTime'.
 *
 * To start a payment, signatures of both the buyer and the Operator are required, and they
 * are checked in the contracts that inherit from this one.
 *
 * The contract that implements this interface maintains the balances of all users,
 * which can be withdrawn via explicit calls to the various 'withdraw' methods.
 * If a buyer has a non-zero local balance at the moment of starting a new payment,
 * the contract reuses it, and only requires the provision of the remainder funds required (if any).
 *
 * Each BuyNow has the following State Machine:
 * - NOT_STARTED -> ASSET_TRANSFERRING, triggered by buyNow
 * - ASSET_TRANSFERRING -> PAID, triggered by relaying assetTransferSuccess signed by Operator
 * - ASSET_TRANSFERRING -> REFUNDED, triggered by relaying assetTransferFailed signed by Operator
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
 *    if the payment seller has previously executed the registerAsSeller method.
 * - If _isSellerRegistrationRequired = false, this feature is disabled, and payments can be initiated
 *    regardless of any previous call to the registerAsSeller method.
 *
 * NOTE: Following audits suggestions, the EIP712 contract, which uses OpenZeppelin's implementation,
 * is not inherited; it is separately deployed, so that it can be upgraded should the standard evolve in the future.
 *
 */

interface IBuyNowBase is ISignableStructsBuyNow {
    /**
     * @dev Event emitted on change of EIP712 verifier contract address
     * @param eip712address The address of the new EIP712 verifier contract
     * @param prevEip712address The previous value of eip712address
     */

    event EIP712(address eip712address, address prevEip712address);

    /**
     * @dev Event emitted on change of payment window
     * @param window The new amount of time after the arrival of a payment for which,
     *  in absence of confirmation of asset transfer success, a buyer is allowed to refund
     * @param prevWindow The previous value of window
     */
    event PaymentWindow(uint256 window, uint256 prevWindow);

    /**
     * @dev Event emitted on change of maximum fee BPS that can be accepted in any payment
     * @param maxFeeBPS the max fee (in BPS units) that can be accepted in any payment
     *  despite operator and buyer having signed a larger amount;
     *  a value of 10000 BPS would correspond to 100% (no limit at all)
     * @param prevMaxFeeBPS The previous value of maxFeeBPS
     */
    event MaxFeeBPS(uint256 maxFeeBPS, uint256 prevMaxFeeBPS);

    /**
     * @dev Event emitted when a user executes the registerAsSeller method
     * @param seller The address of the newly registeredAsSeller user.
     */
    event NewSeller(address indexed seller);

    /**
     * @dev Event emitted when a user sets a value of onlyUserCanWithdraw
     *  - if true: only the user can execute withdrawals of his/her local balance
     *  - if false: any address can help and execute the withdrawals on behalf of the user
     *   (the funds still go straight to the user, but the helper address covers gas costs
     *    and the hassle of executing the transaction)
     * @param user The address of the user.
     * @param onlyUserCanWithdraw true if only the user can execute withdrawals of his/her local balance
     * @param prevOnlyUserCanWithdraw the previous value, overwritten by 'onlyUserCanWithdraw'
     */
    event OnlyUserCanWithdraw(address indexed user, bool onlyUserCanWithdraw, bool prevOnlyUserCanWithdraw);

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
    event BuyNow(
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
     * @param amount The amount withdrawn, in lowest units of the currency
     */
    event Withdraw(address indexed user, uint256 amount);

    /**
     * @dev The enum characterizing the possible states of an payment process
     */
    enum State {
        NotStarted,
        AssetTransferring,
        Refunded,
        Paid,
        Auctioning
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

        // the id of the universe that the asset belongs to.
        uint256 universeId;

        // The address of the feesCollector of this payment
        address feesCollector;

        // The timestamp after which, in absence of confirmation of
        // asset transfer success, a buyer is allowed to refund
        uint256 expirationTime;

        // the percentage fee expressed in Basis Points (bps), typical in finance
        // Examples:  2.5% = 250 bps, 10% = 1000 bps, 100% = 10000 bps
        uint256 feeBPS;

        // the price of the asset, an integer expressed in the
        // lowest unit of the currency.
        uint256 amount;
    }

    /**
     * @notice Registers msg.sender as seller so that, if the contract has set
     *  _isSellerRegistrationRequired = true, then payments will be accepted with
     *  msg.sender as seller.
    */
    function registerAsSeller() external;

    /**
     * @notice Sets the value of onlyUserCanWithdraw for the user with msg.sender address:
     *  - if true: only the user can execute withdrawals of his/her local balance
     *  - if false: any address can help and execute the withdrawals on behalf of the user
     *   (the funds still go straight to the user, but the helper address covers gas costs
     *    and the hassle of executing the transaction)
     * @param onlyUserCan true if only the user can execute withdrawals of his/her local balance
     */
    function setOnlyUserCanWithdraw(bool onlyUserCan) external;

    /**
     * @notice Relays the operator signature declaring that the asset transfer was successful or failed,
     *  and updates local balances of seller or buyer, respectively.
     * @dev Can be executed by anyone, but the operator signature must be included as input param.
     *  Seller or Buyer's local balances are updated, allowing explicit withdrawal.
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
     *  updates balances of seller or buyer, respectively, and proceeds to withdraw all funds
     *  in this contract available to the rightful recipient of the paymentId:
     *  the seller if transferResult.wasSuccessful == true, the buyer otherwise.
     * @dev If recipient has set onlyUserCanWithdraw == true, then msg.sender must the recipient;
     *  otherwise, anyone can execute this method, with funds arriving to the recipient too, but with a
     *  helping 3rd party covering gas costs and TX sending hassle.
     *  The operator signature must be included as input param.
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
     * @notice Executes refund and withdraw to the buyer in one transaction.
     * @dev If the buyer has set onlyUserCanWithdraw == true, then msg.sender must the recipient;
     *  otherwise, anyone can execute this method, with funds arriving to the buyer too, but with a
     *  helping 3rd party covering gas costs and TX sending hassle.
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
     * @notice Transfers funds avaliable in this
     *  contract's balanceOf[recipient] to recipient.
     *  The funds still go to straight the recipient, as if he/she
     *  has executed the withdrawal() method, but the msg.sender
     *  covers gas costs and the hassle of executing the transaction.
     *  Users can always opt out from this feature, using the setOnlyUserCanWithdraw method.
     */
    function relayedWithdraw(address recipient) external;

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
     *  checking acceptsRefunds to check if it has gone beyond expirationTime.
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
     * @notice Returns the max fee (in BPS units) that can be accepted in any payment
     *  despite operator and buyer having signed a larger amount;
     *  a value of 10000 BPS would correspond to 100% (no limit at all)
     * @return the max fee (in BPS units)
     */
    function maxFeeBPS() external view returns (uint256);

    /**
     * @notice Returns a descriptor about the currency that this contract accepts
     * @return the string describing the currency
     */
    function currencyLongDescriptor() external view returns (string memory);

    /**
     * @notice Splits the funds required to provide 'amount' into two sources:
     *  - externalFunds: the funds required to be transferred from the external buyer balance
     *  - localFunds: the funds required from the buyer's already available balance in this contract.
     * @param buyer The address for which the amount is to be split
     * @param amount The amount to be split
     * @return externalFunds The funds required to be transferred from the external buyer balance
     * @return localFunds The amount of local funds that will be used.
     */
    function splitFundingSources(address buyer, uint256 amount)
        external
        view
        returns (uint256 externalFunds, uint256 localFunds);

    /**
     * @notice Returns true if the 'amount' required for a payment is available to this contract.
     * @dev In more detail: returns true if the sum of the buyer's local balance in this contract,
     *  plus the external available balance, is larger or equal than 'amount'
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
     *  plus the available external balance.
     * @param buyer The address for which funds are queried
     * @return the max funds available
     */
    function maxFundsAvailable(address buyer) external view returns (uint256);

    /**
     * @notice Reverts unless the requirements for a BuyNowInput are fulfilled.
     * @param buyNowInp The BuyNowInput struct
     */
    function assertBuyNowInputsOK(BuyNowInput calldata buyNowInp) external view;

    /**
     * @notice Returns the value of onlyUserCanWithdraw for a given user
     * @param user The address of the user
     */
    function onlyUserCanWithdraw(address user) external view returns (bool);

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
pragma solidity =0.8.14;

import "./IBuyNowBase.sol";
import "../../roles/Operators.sol";
import "../../roles/FeesCollectors.sol";
import "./IEIP712VerifierBuyNow.sol";

/**
 * @title Base Escrow Contract for Payments in BuyNow mode.
 * @author Freeverse.io, www.freeverse.io
 * @notice Full contract documentation in IBuyNowBase
 */

abstract contract BuyNowBase is IBuyNowBase, FeesCollectors, Operators {
    // the address of the deployed EIP712 verifier contract
    address internal _eip712;

    // a human readable long descripton of the accepted currency
    // (be it native or ERC20), e.g. "USDC on Polygon PoS"
    string private _currencyLongDescriptor;

    //  the amount of seconds that a payment can remain
    //  in ASSET_TRANSFERRING state without positive
    //  or negative confirmation by the operator
    uint256 internal _paymentWindow;

    //  the max fee (in BPS units) that can be accepted in any payment
    //  despite operator and buyer having signed a larger amount;
    //  a value of 10000 BPS would correspond to 100% (no limit at all)
    uint256 internal _maxFeeBPS;

    // whether sellers need to be registered to be able to accept payments
    bool internal _isSellerRegistrationRequired;

    // mapping from seller address to whether seller is registered
    mapping(address => bool) internal _isRegisteredSeller;

    // mapping from user address to a bool:
    // - if true: only the user can execute withdrawals of his/her local balance
    // - if false: any address can help and execute the withdrawals on behalf of the user
    //   (the funds still go straight to the user, but the helper address covers gas costs
    //    and the hassle of executing the transaction)
    mapping(address => bool) internal _onlyUserCanWithdraw;

    // mapping from paymentId to payment struct describing the entire payment process
    mapping(bytes32 => Payment) internal _payments;

    // mapping from user address to local balance in this contract
    mapping(address => uint256) internal _balanceOf;

    constructor(string memory currencyDescriptor, address eip712) {
        setEIP712(eip712);
        _currencyLongDescriptor = currencyDescriptor;
        setPaymentWindow(30 days);
        _isSellerRegistrationRequired = false;
        setMaxFeeBPS(3000); // 30%
    }

    /**
     * @notice Sets the address of the EIP712 verifier contract.
     * @dev This upgradable pattern is required in case that the
     *  EIP712 spec/code changes in the future
     * @param eip712address The address of the new EIP712 contract.
     */
    function setEIP712(address eip712address) public onlyOwner {
        emit EIP712(eip712address, _eip712);
        _eip712 = eip712address;
    }

    /**
     * @notice Sets the amount of time available to the operator, after the payment starts,
     *  to confirm either the success or the failure of the asset transfer.
     *  After this time, the payment moves to FAILED, allowing buyer to withdraw.
     * @param window The amount of time available, in seconds.
     */
    function setPaymentWindow(uint256 window) public onlyOwner {
        require(
            (window < 60 days) && (window > 3 hours),
            "BuyNowBase::setPaymentWindow: payment window outside limits"
        );
        emit PaymentWindow(window, _paymentWindow);
        _paymentWindow = window;
    }

    /**
     * @notice Sets the max fee (in BPS units) that can be accepted in any payment
     *  despite operator and buyer having signed a larger amount;
     *  a value of 10000 BPS would correspond to 100% (no limit at all)
     * @param feeBPS The new max fee (in BPS units)
     */
    function setMaxFeeBPS(uint256 feeBPS) public onlyOwner {
        require(
            (feeBPS <= 10000) && (feeBPS >= 0),
            "BuyNowBase::setMaxFeeBPS: maxFeeBPS outside limits"
        );
        emit MaxFeeBPS(feeBPS, _maxFeeBPS);
        _maxFeeBPS = feeBPS;
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

    /// @inheritdoc IBuyNowBase
    function registerAsSeller() external {
        require(
            !_isRegisteredSeller[msg.sender],
            "BuyNowBase::registerAsSeller: seller already registered"
        );
        _isRegisteredSeller[msg.sender] = true;
        emit NewSeller(msg.sender);
    }

    /// @inheritdoc IBuyNowBase
    function setOnlyUserCanWithdraw(bool onlyUserCan) external {
        emit OnlyUserCanWithdraw(msg.sender, onlyUserCan, _onlyUserCanWithdraw[msg.sender]);
        _onlyUserCanWithdraw[msg.sender] = onlyUserCan;
    }

    /// @inheritdoc IBuyNowBase
    function finalize(
        AssetTransferResult calldata transferResult,
        bytes calldata operatorSignature
    ) external {
        _finalize(transferResult, operatorSignature);
    }

    /// @inheritdoc IBuyNowBase
    function finalizeAndWithdraw(
        AssetTransferResult calldata transferResult,
        bytes calldata operatorSignature
    ) external {
        address recipient = transferResult.wasSuccessful
            ? _payments[transferResult.paymentId].seller
            : _payments[transferResult.paymentId].buyer;
        if (_onlyUserCanWithdraw[recipient]) require(
            msg.sender == recipient,
            "BuyNowBase::finalizeAndWithdraw: tx sender not authorized to withdraw on recipients behalf"
        );
        _finalize(transferResult, operatorSignature);
        // withdrawal cannot fail due to zero balance, since
        // balance has just been increased when finalizing the payment:
        _withdrawAmount(recipient, _balanceOf[recipient]);
    }

    /// @inheritdoc IBuyNowBase
    function refund(bytes32 paymentId) public {
        _refund(paymentId);
    }

    /// @inheritdoc IBuyNowBase
    function refundAndWithdraw(bytes32 paymentId) external {
        address recipient = _payments[paymentId].buyer;
        if (_onlyUserCanWithdraw[recipient]) require(
            msg.sender == recipient,
            "BuyNowBase::refundAndWithdraw: tx sender not authorized to withdraw on recipients behalf"
        );
        _refund(paymentId);
        // withdrawal cannot fail due to zero balance, since
        // balance has just been increased when refunding:
        _withdrawAmount(recipient, _balanceOf[recipient]);
    }

    /// @inheritdoc IBuyNowBase
    function withdraw() external {
        _withdraw();
    }

    /// @inheritdoc IBuyNowBase
    function relayedWithdraw(address recipient) external {
        require(
            !_onlyUserCanWithdraw[recipient] || (msg.sender == recipient),
            "BuyNowBase::relayedWithdraw: tx sender not authorized to withdraw on recipients behalf"
        );
        _withdrawAmount(recipient, _balanceOf[recipient]);
    }

    /// @inheritdoc IBuyNowBase
    function withdrawAmount(uint256 amount) external {
        _withdrawAmount(msg.sender, amount);
    }

    // PRIVATE & INTERNAL FUNCTIONS

    /**
     * @dev Interface to method that must update buyer's local balance on arrival of a payment,
     *  re-using local balance if available. In ERC20 payments, it transfers to this contract
     *  the required amount; in case of native crypto, it must add excess of provided funds, if any, to local balance.
     * @param buyer The address of the buyer
     * @param newFundsNeeded The elsewhere computed minimum amount of funds required to be provided by the buyer,
     *  having possible re-use of local funds into account
     * @param localFunds The elsewhere computed amount of funds available to the buyer in this contract, that will be
     *  re-used in the payment
     */
    function _updateBuyerBalanceOnPaymentReceived(
        address buyer,
        uint256 newFundsNeeded,
        uint256 localFunds
    ) internal virtual;

    /**
     * @dev Asserts correcteness of buyNow input parameters,
     *  transfers required funds from external contract (in case of ERC20 Payments),
     *  reuses buyer's local balance (if any),
     *  and stores the payment data in contract's storage.
     *  Moves the payment to AssetTransferring state
     * @param buyNowInp The BuyNowInput struct
     * @param operator The address of the operator of this payment.
     */
    function _processBuyNow(
        BuyNowInput memory buyNowInp,
        address operator,
        bytes calldata sellerSignature
    ) internal {
        require(
            IEIP712VerifierBuyNow(_eip712).verifySellerSignature(
                sellerSignature,
                buyNowInp
            ),
            "BuyNowBase::_processBuyNow: incorrect seller signature"
        );
        assertBuyNowInputsOK(buyNowInp);
        assertSeparateRoles(operator, buyNowInp.buyer, buyNowInp.seller);
        (uint256 newFundsNeeded, uint256 localFunds) = splitFundingSources(
            buyNowInp.buyer,
            buyNowInp.amount
        );
        _updateBuyerBalanceOnPaymentReceived(buyNowInp.buyer, newFundsNeeded, localFunds);
        _payments[buyNowInp.paymentId] = Payment(
            State.AssetTransferring,
            buyNowInp.buyer,
            buyNowInp.seller,
            buyNowInp.universeId,
            universeFeesCollector(buyNowInp.universeId),
            block.timestamp + _paymentWindow,
            buyNowInp.feeBPS,
            buyNowInp.amount
        );
        emit BuyNow(buyNowInp.paymentId, buyNowInp.buyer, buyNowInp.seller);
    }

    /**
     * @dev (private) Moves the payment funds to the buyer's local balance
     *  The buyer still needs to withdraw afterwards.
     *  Moves the payment to REFUNDED state
     * @param paymentId The unique ID that identifies the payment.
     */
    function _refund(bytes32 paymentId) private {
        require(
            acceptsRefunds(paymentId),
            "BuyNowBase::_refund: payment does not accept refunds at this stage"
        );
        _refundToLocalBalance(paymentId);
    }

    /**
     * @dev (private) Uses the operator signed msg regarding asset transfer success to update
     *  the balances of seller (on success) or buyer (on failure).
     *  They still need to withdraw afterwards.
     *  Moves the payment to either PAID (on success) or REFUNDED (on failure) state
     * @param transferResult The asset transferResult struct signed by the operator.
     * @param operatorSignature The operator signature of transferResult
     */
    function _finalize(
        AssetTransferResult calldata transferResult,
        bytes calldata operatorSignature
    ) private {
        Payment memory payment = _payments[transferResult.paymentId];
        require(
            paymentState(transferResult.paymentId) == State.AssetTransferring,
            "BuyNowBase::_finalize: payment not initially in asset transferring state"
        );
        require(
            IEIP712VerifierBuyNow(_eip712).verifyAssetTransferResult(
                transferResult,
                operatorSignature,
                universeOperator(payment.universeId)
            ),
            "BuyNowBase::_finalize: only the operator can sign an assetTransferResult"
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
        _withdrawAmount(msg.sender, _balanceOf[msg.sender]);
    }

    /**
     * @dev (private) Transfers the specified amount of
     *  funds in this contract's balanceOf[recipient] to the recipient address.
     *  Follows standard Checks-Effects-Interactions pattern
     *  to protect against re-entrancy attacks.
     * @param recipient The address of to transfer funds from the local contract
     * @param amount The amount to withdraw.
    */
    function _withdrawAmount(address recipient, uint256 amount) private {
        // requirements:
        //  1. check that there is enough balance
        uint256 currentBalance = _balanceOf[recipient];
        require(
            currentBalance >= amount,
            "BuyNowBase::_withdrawAmount: not enough balance to withdraw specified amount"
        );
        //  2. prevent dummy withdrawals with 0 amount to avoid useless events
        require(
            amount > 0,
            "BuyNowBase::_withdrawAmount: cannot withdraw zero amount"
        );
        // effect:
        _balanceOf[recipient] = currentBalance - amount;
        // interaction:
        _transfer(recipient, amount);
        emit Withdraw(recipient, amount);
    }

    /**
     * @dev Interface to method that transfers the specified amount to the specified address.
     *  Requirements and effects are checked before calling this function.
     *  Implementations can deal with native crypto transfers, with ERC20 token transfers, etc.
     * @param to The address that must receive the funds.
     * @param amount The amount to transfer.
    */
    function _transfer(address to, uint256 amount) internal virtual;

    // VIEW FUNCTIONS

    /// @inheritdoc IBuyNowBase
    function isSellerRegistrationRequired() external view returns (bool) {
        return _isSellerRegistrationRequired;
    }

    /// @inheritdoc IBuyNowBase
    function isRegisteredSeller(address addr) external view returns (bool) {
        return _isRegisteredSeller[addr];
    }

    /// @inheritdoc IBuyNowBase
    function balanceOf(address addr) external view returns (uint256) {
        return _balanceOf[addr];
    }

    /// @inheritdoc IBuyNowBase
    function paymentInfo(bytes32 paymentId)
        external
        view
        returns (Payment memory)
    {
        return _payments[paymentId];
    }

    /// @inheritdoc IBuyNowBase
    function paymentState(bytes32 paymentId) public view virtual returns (State) {
        return _payments[paymentId].state;
    }

    /// @inheritdoc IBuyNowBase
    function acceptsRefunds(bytes32 paymentId) public view returns (bool) {
        return
            (paymentState(paymentId) == State.AssetTransferring) &&
            (block.timestamp > _payments[paymentId].expirationTime);
    }

    /// @inheritdoc IBuyNowBase
    function EIP712Address() external view returns (address) {
        return _eip712;
    }

    /// @inheritdoc IBuyNowBase
    function paymentWindow() external view returns (uint256) {
        return _paymentWindow;
    }

    /// @inheritdoc IBuyNowBase
    function maxFeeBPS() external view returns (uint256) {
        return _maxFeeBPS;
    }

    /// @inheritdoc IBuyNowBase
    function currencyLongDescriptor() external view returns (string memory) {
        return _currencyLongDescriptor;
    }

    /// @inheritdoc IBuyNowBase
    function assertBuyNowInputsOK(BuyNowInput memory buyNowInp) public view {
        require(
            buyNowInp.amount > 0,
            "BuyNowBase::assertBuyNowInputsOK: payment amount cannot be zero"
        );
        require(
            buyNowInp.feeBPS <= _maxFeeBPS,
            "BuyNowBase::assertBuyNowInputsOK: fee cannot be larger than maxFeeBPS"
        );
        require(
            paymentState(buyNowInp.paymentId) == State.NotStarted,
            "BuyNowBase::assertBuyNowInputsOK: payment in incorrect current state"
        );
        require(
            block.timestamp <= buyNowInp.deadline,
            "BuyNowBase::assertBuyNowInputsOK: payment deadline expired"
        );
        if (_isSellerRegistrationRequired)
            require(
                _isRegisteredSeller[buyNowInp.seller],
                "BuyNowBase::assertBuyNowInputsOK: seller not registered"
            );
    }

    /// @inheritdoc IBuyNowBase
    function enoughFundsAvailable(address buyer, uint256 amount)
        public
        view
        returns (bool)
    {
        return maxFundsAvailable(buyer) >= amount;
    }

    /// @inheritdoc IBuyNowBase
    function maxFundsAvailable(address buyer) public view returns (uint256) {
        return _balanceOf[buyer] + externalBalance(buyer);
    }

    /**
     * @notice Interface to method that must return the amount available to a buyer outside this contract
     * @dev If the contract that implements this interface deals with native crypto, then it must return buyer.balance;
     *  if dealing with ERC20, it must return the available balance in the external ERC20 contract.
     * @param buyer The address for which funds are queried
     * @return the external funds available
     */
    function externalBalance(address buyer) public view virtual returns (uint256);

    /// @inheritdoc IBuyNowBase
    function splitFundingSources(address buyer, uint256 amount)
        public
        view
        returns (uint256 externalFunds, uint256 localFunds)
    {
        uint256 localBalance = _balanceOf[buyer];
        localFunds = (amount > localBalance) ? localBalance : amount;
        externalFunds = (amount > localBalance) ? amount - localBalance : 0;
    }

    /// @inheritdoc IBuyNowBase
    function onlyUserCanWithdraw(address user) public view returns (bool) {
        return _onlyUserCanWithdraw[user];
    }

    // PURE FUNCTIONS

    /**
     * @dev Reverts if either of the following addresses coincide: operator, buyer, seller
     *  On the one hand, the operator must be an observer.
     *  On the other hand, the seller cannot act on his/her already owned assets.
     * @param operator The address of the operator
     * @param buyer The address of the buyer
     * @param seller The address of the seller
    */
    function assertSeparateRoles(address operator, address buyer, address seller)
        internal pure {
        require(
            (operator != buyer) && (operator != seller),
            "BuyNowBase::assertSeparateRoles: operator must be an observer"
        );
        require(
            (buyer != seller),
            "BuyNowBase::assertSeparateRoles: buyer and seller cannot coincide"
        );
    }

    /// @inheritdoc IBuyNowBase
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
pragma solidity =0.8.14;

import "./base/IBuyNowBase.sol";

/**
 * @title Interface to Escrow Contract for Payments in BuyNow mode, in native cryptocurrency.
 * @author Freeverse.io, www.freeverse.io
 * @dev The contract that implements this interface adds an entry point for BuyNow payments,
 * which are defined and documented in the inherited IBuyNowBase.
 * - in the 'buyNow' method, the buyer is the msg.sender (the buyer therefore signs the TX),
 *   and the operator's EIP712-signature of the BuyNowInput struct is provided as input to the call.
 */

interface IBuyNowNative is IBuyNowBase {
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
     * @param buyNowInp The struct containing all required payment data
     * @param operatorSignature The signature of 'buyNowInp' by the operator
     * @param sellerSignature the signature of the seller agreeing to list the asset
     */
    function buyNow(
        BuyNowInput calldata buyNowInp,
        bytes calldata operatorSignature,
        bytes calldata sellerSignature
    ) external payable;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}