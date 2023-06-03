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
pragma solidity ^0.8.10;

/// @title IRegistry
/// @notice An interface for interacting with the agreement registry
interface IRegistry {
    /// @notice Get the payment data for a specific agreement
    /// @param agreementHash The unique identifier for the agreement
    /// @return offerer The address of the offerer in the agreement
    /// @return promisor The address of the promisor in the agreement
    /// @return paymentAmount The amount to be paid in the agreement
    /// @return start The start time of the agreement
    /// @return expiration The expiration time of the agreement
    function getPaymentData(
        bytes32 agreementHash
    )
        external
        view
        returns (
            address offerer,
            address promisor,
            uint256 paymentAmount,
            uint256 start,
            uint256 expiration
        );
}

/// @title Agreement
/// @notice A struct representing an agreement
struct Agreement {
    string contractName;
    uint128 id;
    address offerer;
    address promisor;
    address[] terms;
    address assetAddress;
    uint256 tokenId;
    address validatorModule;
    uint256 expiration;
    uint256 paymentAmount;
    address[] signers;
    string dynamicData;
    uint256 nonce;
    uint256 chainId;
}

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IRegistry.sol";

/// @title OneTimePaymentValidator
/// @notice Validates a one-time payment for an agreement
/// @dev This contract interacts with a token contract and a registry contract
contract OneTimePaymentValidator {
    /// @notice ERC20 token used for payments
    IERC20 public paymentToken;
    /// @notice The registry of all agreements
    IRegistry public registry;
    /// @notice The payment time for each agreement
    mapping(bytes32 => uint256) public paymentTime;
    /// @notice The total amount paid for each agreement
    mapping(bytes32 => uint256) public totalPaid;

    /// @notice Constructs a new OneTimePaymentValidator
    /// @param _paymentToken The address of the ERC20 token used for payments
    /// @param _registry The address of the registry of agreements
    constructor(address _paymentToken, address _registry) {
        paymentToken = IERC20(_paymentToken);
        registry = IRegistry(_registry);
    }

    /// @notice Pay the one-time fee for an agreement
    /// @param agreementHash The unique identifier for the agreement
    function pay(bytes32 agreementHash) public {
        // Fetch the Agreement from the Registry
        (, address promisor, uint256 _paymentAmount, uint256 start, uint256 expiration) = registry.getPaymentData(agreementHash);
        
        require(
            block.timestamp <= start + 2 weeks,
            "Payment period expired"
        );

        require(
            paymentToken.transferFrom(msg.sender, promisor, _paymentAmount),
            "Failed to send payment"
        );

        // Update the paymentTime and totalPaid
        updatePaymentTime(agreementHash);
        totalPaid[agreementHash] += _paymentAmount;
    }

    /// @notice Update the payment time for an agreement
    /// @param agreementHash The unique identifier for the agreement
    function updatePaymentTime(bytes32 agreementHash) internal {
        paymentTime[agreementHash] = block.timestamp;
    }

    /// @notice Validate whether the correct amount has been paid for an agreement
    /// @param agreementHash The unique identifier for the agreement
    /// @return bool Whether the correct amount has been paid
    function validate(bytes32 agreementHash) public view returns (bool) {
        (,,uint256 _paymentAmount,,) = registry.getPaymentData(agreementHash);
        return totalPaid[agreementHash] >= _paymentAmount;
    }

    /// @notice Get the amount owed for an agreement
    /// @param agreementHash The unique identifier for the agreement
    /// @return uint256 The amount owed
    function amountOwed(bytes32 agreementHash) public view returns (uint256) {
        (,,uint256 _paymentAmount,,) = registry.getPaymentData(agreementHash);

        uint256 actualPaid = totalPaid[agreementHash];

        if (actualPaid >= _paymentAmount) {
            return 0;
        } else {
            return _paymentAmount - actualPaid;
        }
    }
}