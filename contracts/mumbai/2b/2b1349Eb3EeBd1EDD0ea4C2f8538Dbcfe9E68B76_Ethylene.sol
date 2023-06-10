// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Optimistic Oracle V3 Interface that callers must use to assert truths about the world.
 */
interface OptimisticOracleV3Interface {
    // Struct grouping together the settings related to the escalation manager stored in the assertion.
    struct EscalationManagerSettings {
        bool arbitrateViaEscalationManager; // False if the DVM is used as an oracle (EscalationManager on True).
        bool discardOracle; // False if Oracle result is used for resolving assertion after dispute.
        bool validateDisputers; // True if the EM isDisputeAllowed should be checked on disputes.
        address assertingCaller; // Stores msg.sender when assertion was made.
        address escalationManager; // Address of the escalation manager (zero address if not configured).
    }

    // Struct for storing properties and lifecycle of an assertion.
    struct Assertion {
        EscalationManagerSettings escalationManagerSettings; // Settings related to the escalation manager.
        address asserter; // Address of the asserter.
        uint64 assertionTime; // Time of the assertion.
        bool settled; // True if the request is settled.
        IERC20 currency; // ERC20 token used to pay rewards and fees.
        uint64 expirationTime; // Unix timestamp marking threshold when the assertion can no longer be disputed.
        bool settlementResolution; // Resolution of the assertion (false till resolved).
        bytes32 domainId; // Optional domain that can be used to relate the assertion to others in the escalationManager.
        bytes32 identifier; // UMA DVM identifier to use for price requests in the event of a dispute.
        uint256 bond; // Amount of currency that the asserter has bonded.
        address callbackRecipient; // Address that receives the callback.
        address disputer; // Address of the disputer.
    }

    // Struct for storing cached currency whitelist.
    struct WhitelistedCurrency {
        bool isWhitelisted; // True if the currency is whitelisted.
        uint256 finalFee; // Final fee of the currency.
    }

    /**
     * @notice Returns the default identifier used by the Optimistic Oracle V3.
     * @return The default identifier.
     */
    function defaultIdentifier() external view returns (bytes32);

    /**
     * @notice Fetches information about a specific assertion and returns it.
     * @param assertionId unique identifier for the assertion to fetch information for.
     * @return assertion information about the assertion.
     */
    function getAssertion(bytes32 assertionId) external view returns (Assertion memory);

    /**
     * @notice Asserts a truth about the world, using the default currency and liveness. No callback recipient or
     * escalation manager is enabled. The caller is expected to provide a bond of finalFee/burnedBondPercentage
     * (with burnedBondPercentage set to 50%, the bond is 2x final fee) of the default currency.
     * @dev The caller must approve this contract to spend at least the result of getMinimumBond(defaultCurrency).
     * @param claim the truth claim being asserted. This is an assertion about the world, and is verified by disputers.
     * @param asserter receives bonds back at settlement. This could be msg.sender or
     * any other account that the caller wants to receive the bond at settlement time.
     * @return assertionId unique identifier for this assertion.
     */
    function assertTruthWithDefaults(bytes memory claim, address asserter) external returns (bytes32);

    /**
     * @notice Asserts a truth about the world, using a fully custom configuration.
     * @dev The caller must approve this contract to spend at least bond amount of currency.
     * @param claim the truth claim being asserted. This is an assertion about the world, and is verified by disputers.
     * @param asserter receives bonds back at settlement. This could be msg.sender or
     * any other account that the caller wants to receive the bond at settlement time.
     * @param callbackRecipient if configured, this address will receive a function call assertionResolvedCallback and
     * assertionDisputedCallback at resolution or dispute respectively. Enables dynamic responses to these events. The
     * recipient _must_ implement these callbacks and not revert or the assertion resolution will be blocked.
     * @param escalationManager if configured, this address will control escalation properties of the assertion. This
     * means a) choosing to arbitrate via the UMA DVM, b) choosing to discard assertions on dispute, or choosing to
     * validate disputes. Combining these, the asserter can define their own security properties for the assertion.
     * escalationManager also _must_ implement the same callbacks as callbackRecipient.
     * @param liveness time to wait before the assertion can be resolved. Assertion can be disputed in this time.
     * @param currency bond currency pulled from the caller and held in escrow until the assertion is resolved.
     * @param bond amount of currency to pull from the caller and hold in escrow until the assertion is resolved. This
     * must be >= getMinimumBond(address(currency)).
     * @param identifier UMA DVM identifier to use for price requests in the event of a dispute. Must be pre-approved.
     * @param domainId optional domain that can be used to relate this assertion to others in the escalationManager and
     * can be used by the configured escalationManager to define custom behavior for groups of assertions. This is
     * typically used for "escalation games" by changing bonds or other assertion properties based on the other
     * assertions that have come before. If not needed this value should be 0 to save gas.
     * @return assertionId unique identifier for this assertion.
     */
    function assertTruth(
        bytes memory claim,
        address asserter,
        address callbackRecipient,
        address escalationManager,
        uint64 liveness,
        IERC20 currency,
        uint256 bond,
        bytes32 identifier,
        bytes32 domainId
    ) external returns (bytes32);

    /**
     * @notice Fetches information about a specific identifier & currency from the UMA contracts and stores a local copy
     * of the information within this contract. This is used to save gas when making assertions as we can avoid an
     * external call to the UMA contracts to fetch this.
     * @param identifier identifier to fetch information for and store locally.
     * @param currency currency to fetch information for and store locally.
     */
    function syncUmaParams(bytes32 identifier, address currency) external;

    /**
     * @notice Resolves an assertion. If the assertion has not been disputed, the assertion is resolved as true and the
     * asserter receives the bond. If the assertion has been disputed, the assertion is resolved depending on the oracle
     * result. Based on the result, the asserter or disputer receives the bond. If the assertion was disputed then an
     * amount of the bond is sent to the UMA Store as an oracle fee based on the burnedBondPercentage. The remainder of
     * the bond is returned to the asserter or disputer.
     * @param assertionId unique identifier for the assertion to resolve.
     */
    function settleAssertion(bytes32 assertionId) external;

    /**
     * @notice Settles an assertion and returns the resolution.
     * @param assertionId unique identifier for the assertion to resolve and return the resolution for.
     * @return resolution of the assertion.
     */
    function settleAndGetAssertionResult(bytes32 assertionId) external returns (bool);

    /**
     * @notice Fetches the resolution of a specific assertion and returns it. If the assertion has not been settled then
     * this will revert. If the assertion was disputed and configured to discard the oracle resolution return false.
     * @param assertionId unique identifier for the assertion to fetch the resolution for.
     * @return resolution of the assertion.
     */
    function getAssertionResult(bytes32 assertionId) external view returns (bool);

    /**
     * @notice Returns the minimum bond amount required to make an assertion. This is calculated as the final fee of the
     * currency divided by the burnedBondPercentage. If burn percentage is 50% then the min bond is 2x the final fee.
     * @param currency currency to calculate the minimum bond for.
     * @return minimum bond amount.
     */
    function getMinimumBond(address currency) external view returns (uint256);

    event AssertionMade(
        bytes32 indexed assertionId,
        bytes32 domainId,
        bytes claim,
        address indexed asserter,
        address callbackRecipient,
        address escalationManager,
        address caller,
        uint64 expirationTime,
        IERC20 currency,
        uint256 bond,
        bytes32 indexed identifier
    );

    event AssertionDisputed(bytes32 indexed assertionId, address indexed caller, address indexed disputer);

    event AssertionSettled(
        bytes32 indexed assertionId,
        address indexed bondRecipient,
        bool disputed,
        bool settlementResolution,
        address settleCaller
    );

    event AdminPropertiesSet(IERC20 defaultCurrency, uint64 defaultLiveness, uint256 burnedBondPercentage);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.16;

import "@uma/core/contracts/optimistic-oracle-v3/interfaces/OptimisticOracleV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Ethylene is Ownable {
    OptimisticOracleV3Interface private constant _oov3 =
        OptimisticOracleV3Interface(0x9923D42eF695B5dd9911D05Ac944d4cAca3c4EAB); // GOERLI
    uint64 public defaultLiveness;
    IERC20 public defaultCurrency;
    bytes32 private constant defaultIdentifier = "ASSERT_TRUTH";

    // ========================================
    //     CONSTRUCTOR AND CORE FUNCTIONS
    // ========================================

    /**
     * @notice Constructs the Ethylene contract.
     * @param _currency the currency to use for assertions.
     * @param _liveness the liveness to use for assertions.
     */
    constructor(IERC20 _currency, uint64 _liveness) {
        defaultCurrency = _currency;
        defaultLiveness = _liveness;
    }

    /**
     * @notice Asserts a truth about the world, using a fully custom configuration.
     * @dev The caller must approve this contract to spend at least bond amount of currency.
     * @param claim the truth claim being asserted. This is an assertion about the world, and is verified by disputers.
     * @return assertionId unique identifier for this assertion.
     */
    function assertToOracle(bytes memory claim) public returns (bytes32) {
        bytes32 assertionId = _oov3.assertTruth(
            claim,
            address(this), // asserter
            address(0), // callbackRecipient
            address(0), // escalationManager
            defaultLiveness,
            defaultCurrency,
            _oov3.getMinimumBond(address(defaultCurrency)),
            defaultIdentifier,
            bytes32(0) // domainId
        );

        return assertionId;
    }

    /**
     * @notice Settles the assertion, if it has not been disputed and it has passed the challenge window, and return the result.
     * @param _assertionId the unique identifier for the assertion.
     * @dev This function can only be called once the assertion has been settled, otherwise it reverts.
     * @return result the result of the assertion.
     */
    function settleAndGetAssertionResult(
        bytes32 _assertionId
    ) public returns (bool) {
        return _oov3.settleAndGetAssertionResult(_assertionId);
    }

    // Just return the assertion result. Can only be called once the assertion has been settled.
    /**
     * @notice Returns the result of the assertion.
     * @param _assertionId the unique identifier for the assertion.
     * @dev This function can only be called once the assertion has been settled, otherwise it reverts.
     * @return result the result of the assertion.
     */
    function getAssertionResult(
        bytes32 _assertionId
    ) public view returns (bool) {
        return _oov3.getAssertionResult(_assertionId);
    }

    /**
     * @notice Returns the full assertion object contain all information associated with the assertion.
     * @param _assertionId the unique identifier for the assertion.
     * @dev This function can be called any time, it won't revert if assertion has not been settled.
     * @return assertion the full assertion object.
     */
    function getAssertion(
        bytes32 _assertionId
    ) public view returns (OptimisticOracleV3Interface.Assertion memory) {
        return _oov3.getAssertion(_assertionId);
    }

    // ========================================
    //     ADMIN FUNCTIONS
    // ========================================

    /**
     * @notice Sets the default currency used for assertions.
     * @dev This is used in the assertTruth function to default the currency if it is not specified.
     * @param _currency the currency to use for assertions.
     */
    function setDefaultCurrency(IERC20 _currency) external onlyOwner {
        defaultCurrency = _currency;
    }

    /**
     * @notice Sets the default liveness used for assertions.
     * @dev This is used in the assertTruth function to default the liveness if it is not specified.
     * @param _liveness the liveness to use for assertions.
     */
    function setDefaultLiveness(uint64 _liveness) external onlyOwner {
        defaultLiveness = _liveness;
    }
}