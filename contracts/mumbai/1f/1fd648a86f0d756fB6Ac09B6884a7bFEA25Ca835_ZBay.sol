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
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
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
pragma solidity ^0.8.0;

/**
 * @title Library for encoding and decoding ancillary data for DVM price requests.
 * @notice  We assume that on-chain ancillary data can be formatted directly from bytes to utf8 encoding via
 * web3.utils.hexToUtf8, and that clients will parse the utf8-encoded ancillary data as a comma-delimitted key-value
 * dictionary. Therefore, this library provides internal methods that aid appending to ancillary data from Solidity
 * smart contracts. More details on UMA's ancillary data guidelines below:
 * https://docs.google.com/document/d/1zhKKjgY1BupBGPPrY_WOJvui0B6DMcd-xDR8-9-SPDw/edit
 */
library AncillaryData {
    // This converts the bottom half of a bytes32 input to hex in a highly gas-optimized way.
    // Source: the brilliant implementation at https://gitter.im/ethereum/solidity?at=5840d23416207f7b0ed08c9b.
    function toUtf8Bytes32Bottom(bytes32 bytesIn) private pure returns (bytes32) {
        unchecked {
            uint256 x = uint256(bytesIn);

            // Nibble interleave
            x = x & 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff;
            x = (x | (x * 2**64)) & 0x0000000000000000ffffffffffffffff0000000000000000ffffffffffffffff;
            x = (x | (x * 2**32)) & 0x00000000ffffffff00000000ffffffff00000000ffffffff00000000ffffffff;
            x = (x | (x * 2**16)) & 0x0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff;
            x = (x | (x * 2**8)) & 0x00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff;
            x = (x | (x * 2**4)) & 0x0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f;

            // Hex encode
            uint256 h = (x & 0x0808080808080808080808080808080808080808080808080808080808080808) / 8;
            uint256 i = (x & 0x0404040404040404040404040404040404040404040404040404040404040404) / 4;
            uint256 j = (x & 0x0202020202020202020202020202020202020202020202020202020202020202) / 2;
            x = x + (h & (i | j)) * 0x27 + 0x3030303030303030303030303030303030303030303030303030303030303030;

            // Return the result.
            return bytes32(x);
        }
    }

    /**
     * @notice Returns utf8-encoded bytes32 string that can be read via web3.utils.hexToUtf8.
     * @dev Will return bytes32 in all lower case hex characters and without the leading 0x.
     * This has minor changes from the toUtf8BytesAddress to control for the size of the input.
     * @param bytesIn bytes32 to encode.
     * @return utf8 encoded bytes32.
     */
    function toUtf8Bytes(bytes32 bytesIn) internal pure returns (bytes memory) {
        return abi.encodePacked(toUtf8Bytes32Bottom(bytesIn >> 128), toUtf8Bytes32Bottom(bytesIn));
    }

    /**
     * @notice Returns utf8-encoded address that can be read via web3.utils.hexToUtf8.
     * Source: https://ethereum.stackexchange.com/questions/8346/convert-address-to-string/8447#8447
     * @dev Will return address in all lower case characters and without the leading 0x.
     * @param x address to encode.
     * @return utf8 encoded address bytes.
     */
    function toUtf8BytesAddress(address x) internal pure returns (bytes memory) {
        return
            abi.encodePacked(toUtf8Bytes32Bottom(bytes32(bytes20(x)) >> 128), bytes8(toUtf8Bytes32Bottom(bytes20(x))));
    }

    /**
     * @notice Converts a uint into a base-10, UTF-8 representation stored in a `string` type.
     * @dev This method is based off of this code: https://stackoverflow.com/a/65707309.
     */
    function toUtf8BytesUint(uint256 x) internal pure returns (bytes memory) {
        if (x == 0) {
            return "0";
        }
        uint256 j = x;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (x != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(x - (x / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            x /= 10;
        }
        return bstr;
    }

    function appendKeyValueBytes32(
        bytes memory currentAncillaryData,
        bytes memory key,
        bytes32 value
    ) internal pure returns (bytes memory) {
        bytes memory prefix = constructPrefix(currentAncillaryData, key);
        return abi.encodePacked(currentAncillaryData, prefix, toUtf8Bytes(value));
    }

    /**
     * @notice Adds "key:value" to `currentAncillaryData` where `value` is an address that first needs to be converted
     * to utf8 bytes. For example, if `utf8(currentAncillaryData)="k1:v1"`, then this function will return
     * `utf8(k1:v1,key:value)`, and if `currentAncillaryData` is blank, then this will return `utf8(key:value)`.
     * @param currentAncillaryData This bytes data should ideally be able to be utf8-decoded, but its OK if not.
     * @param key Again, this bytes data should ideally be able to be utf8-decoded, but its OK if not.
     * @param value An address to set as the value in the key:value pair to append to `currentAncillaryData`.
     * @return Newly appended ancillary data.
     */
    function appendKeyValueAddress(
        bytes memory currentAncillaryData,
        bytes memory key,
        address value
    ) internal pure returns (bytes memory) {
        bytes memory prefix = constructPrefix(currentAncillaryData, key);
        return abi.encodePacked(currentAncillaryData, prefix, toUtf8BytesAddress(value));
    }

    /**
     * @notice Adds "key:value" to `currentAncillaryData` where `value` is a uint that first needs to be converted
     * to utf8 bytes. For example, if `utf8(currentAncillaryData)="k1:v1"`, then this function will return
     * `utf8(k1:v1,key:value)`, and if `currentAncillaryData` is blank, then this will return `utf8(key:value)`.
     * @param currentAncillaryData This bytes data should ideally be able to be utf8-decoded, but its OK if not.
     * @param key Again, this bytes data should ideally be able to be utf8-decoded, but its OK if not.
     * @param value A uint to set as the value in the key:value pair to append to `currentAncillaryData`.
     * @return Newly appended ancillary data.
     */
    function appendKeyValueUint(
        bytes memory currentAncillaryData,
        bytes memory key,
        uint256 value
    ) internal pure returns (bytes memory) {
        bytes memory prefix = constructPrefix(currentAncillaryData, key);
        return abi.encodePacked(currentAncillaryData, prefix, toUtf8BytesUint(value));
    }

    /**
     * @notice Helper method that returns the left hand side of a "key:value" pair plus the colon ":" and a leading
     * comma "," if the `currentAncillaryData` is not empty. The return value is intended to be prepended as a prefix to
     * some utf8 value that is ultimately added to a comma-delimited, key-value dictionary.
     */
    function constructPrefix(bytes memory currentAncillaryData, bytes memory key) internal pure returns (bytes memory) {
        if (currentAncillaryData.length > 0) {
            return abi.encodePacked(",", key, ":");
        } else {
            return abi.encodePacked(key, ":");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

enum ZBayProductState {
    Created,
    Paid,
    Dispatched,
    Delivered,
    Disputed,
    Resolved,
    Cancelled
}

/// @dev Struct to store the details of a product
struct ZBayProduct {
    uint256 id;
    uint256 price; // in _token
    address seller;
    address buyer;
    ZBayProductState state;
    uint256 attestation;
    bytes32 assertionId;
    bytes cid;
    uint256 coef;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

interface OptimisticOracleV3CallbackRecipientInterface {
    /**
     * @notice Callback function that is called by Optimistic Oracle V3 when an assertion is resolved.
     * @param assertionId The identifier of the assertion that was resolved.
     * @param assertedTruthfully Whether the assertion was resolved as truthful or not.
     */
    function assertionResolvedCallback(bytes32 assertionId, bool assertedTruthfully) external;

    /**
     * @notice Callback function that is called by Optimistic Oracle V3 when an assertion is disputed.
     * @param assertionId The identifier of the assertion that was disputed.
     */
    function assertionDisputedCallback(bytes32 assertionId) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

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

    function defaultCurrency() external view returns (IERC20);

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

    /**
     * @notice Disputes an assertion. Depending on how the assertion was configured, this may either escalate to the UMA
     * DVM or the configured escalation manager for arbitration.
     * @dev The caller must approve this contract to spend at least bond amount of currency for the associated assertion.
     * @param assertionId unique identifier for the assertion to dispute.
     * @param disputer receives bonds back at settlement.
     */
    function disputeAssertion(bytes32 assertionId, address disputer) external;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IZBayVerifier {
    function verify(bytes calldata proof, uint256[] calldata signals) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC2771Context, Context } from "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { AncillaryData } from "@uma/core/contracts/common/implementation/AncillaryData.sol";
import { OptimisticOracleV3Interface } from "./vendor/OptimisticOracleV3Interface.sol";
import { OptimisticOracleV3CallbackRecipientInterface } from "./vendor/OptimisticOracleV3CallbackRecipientInterface.sol";

import "./verifiers/IZBayVerifier.sol";
import "./Structs.sol";

contract ZBay is ERC2771Context, Ownable, OptimisticOracleV3CallbackRecipientInterface {
    error InvalidProof();
    error InvalidState();
    error NotImplemented();

    event ProductCreated(uint256 indexed id, address indexed seller, uint256 indexed price, bytes cid);
    event ProductPurchased(uint256 indexed id, address indexed buyer);
    event ProductDispatched(uint256 indexed id);
    event ProductDelivered(uint256 indexed id);
    event ProductDisputed(uint256 indexed id);
    event ProductResolved(uint256 indexed id, bool indexed successfully);
    event ProductCancelled(uint256 indexed id);

    /// @dev Will be used to resolve disputes on the delivery
    OptimisticOracleV3Interface private _disputeOracle;

    /// @dev ERC20 token used for payments
    IERC20 private _token;

    /// @dev Mapping of product id to product details
    mapping(uint256 => ZBayProduct) private _products;

    /// @dev Mapping of assertion to productId
    mapping(bytes32 => uint256) private _assertionToProductId;

    /// @dev Product counter
    uint256 private _counter;

    /// @dev Mapping of address to verification score
    mapping(address => uint32) private _verificationScore;

    /// @dev Mapping of verifier scores
    mapping(address => uint32) private _verifierScores;

    /// @dev Mapping of verifiers
    mapping(uint256 => address) private _verifiers;

    uint256 constant DEFAULT_SECURITY_MULTIPLIER = 150; // /100
    uint256 constant DEFAULT_TREASURY_PERCENT = 50; // 50 = 0.5% = 0.005 (/10000)
    uint256 constant MAX_INT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    constructor(address trustedForwarer_, OptimisticOracleV3Interface disputeOracle_, IERC20 token_)
        Ownable()
        ERC2771Context(trustedForwarer_)
    {
        _disputeOracle = disputeOracle_;
        _token = token_;
    }

    /// @dev get product details
    function getProduct(uint256 id) external view returns (ZBayProduct memory) {
        return _products[id];
    }

    function getScore(address account) external view returns (uint32) {
        return _verificationScore[account];
    }

    /// @dev verify
    function submitVerification(uint256 verifierId, bytes calldata proof, uint256[] calldata signals) external {
        address verifierAddress = _verifiers[verifierId];
        require(verifierAddress != address(0), "Verifier not found");

        IZBayVerifier verifier = IZBayVerifier(verifierAddress);
        uint32 score = _verifierScores[verifierAddress];

        if (verifier.verify(proof, signals)) {
            _verificationScore[_msgSender()] += score;
        }
    }

    /// @dev create a new product
    function createProduct(uint256 price, bytes calldata cid) external {
        require(_verificationScore[_msgSender()] >= 100, "Seller not verified");

        _products[_counter] = ZBayProduct({
            id: _counter,
            cid: cid,
            price: price,
            seller: _msgSender(),
            buyer: address(0),
            state: ZBayProductState.Created,
            attestation: 0,
            assertionId: bytes32(0),
            coef: 0
        });

        emit ProductCreated(_counter, _msgSender(), price, cid);

        _counter += 1;
    }

    /// @dev purchase a product
    function purchase(uint256 id, bytes calldata securityCoefProof) external {
        ZBayProduct storage product = _products[id];

        uint256 securityMultiplier = DEFAULT_SECURITY_MULTIPLIER;
        if (securityCoefProof.length > 0) {
            // TODO: more elaborate verification
            securityMultiplier = abi.decode(securityCoefProof, (uint256));
        }

        uint256 amountToLock = product.price * securityMultiplier / 100;

        require(product.seller != _msgSender(), "Cannot buy your own product");
        require(product.state == ZBayProductState.Created, "Invalid state");
        require(_token.balanceOf(_msgSender()) >= amountToLock, "Insufficient balance");

        _token.transferFrom(_msgSender(), address(this), amountToLock);

        product.state = ZBayProductState.Paid;
        product.buyer = _msgSender();
        product.coef = securityMultiplier;

        emit ProductPurchased(id, _msgSender());
    }

    function cancel(uint256 id) external {
        ZBayProduct storage product = _products[id];

        require(product.seller == _msgSender(), "Only seller can cancel");
        require(product.state == ZBayProductState.Created || product.state == ZBayProductState.Paid, "Invalid state");

        product.state = ZBayProductState.Cancelled;

        if (product.state == ZBayProductState.Paid) {
            uint256 amountToUnlock = product.price * product.coef / 100;
            _token.transfer(product.buyer, amountToUnlock);
        }

        emit ProductCancelled(id);
    }

    /// @dev dispatch a product
    function dispatch(uint256 id, uint256 attestation) external {
        ZBayProduct storage product = _products[id];

        require(product.seller == _msgSender(), "Only seller can dispatch");
        require(product.state == ZBayProductState.Paid, "Invalid state");

        product.state = ZBayProductState.Dispatched;
        product.attestation = attestation;

        // some networks don't have uma oracles
        if (address(_disputeOracle) != address(0)) {
            bytes memory assertedClaim = abi.encodePacked(
                "Product was dispatched 0x",
                AncillaryData.toUtf8BytesUint(product.id),
                " with metadata at ",
                product.cid,
                " seller 0x",
                AncillaryData.toUtf8BytesAddress(product.seller),
                " buyer ",
                AncillaryData.toUtf8BytesAddress(product.buyer),
                " for price 0x",
                AncillaryData.toUtf8BytesUint(product.price)
            );
            IERC20 bondCurrency = _disputeOracle.defaultCurrency();
            uint256 bondAmount = _disputeOracle.getMinimumBond(address(bondCurrency));
            if (bondAmount > 0) {
                bondCurrency.approve(address(_disputeOracle), bondAmount);
            }
            product.assertionId = _disputeOracle.assertTruth(
                assertedClaim,
                _msgSender(),
                address(this), // callback recipient
                address(0), // escalation manager
                30 days,
                bondCurrency,
                bondAmount,
                _disputeOracle.defaultIdentifier(),
                bytes32(0)
            );
            _assertionToProductId[product.assertionId] = product.id;
        }

        emit ProductDispatched(id);
    }

    /// @dev confirm delivery of a product
    function confirmDelivery(uint256 id, bytes calldata proof) external {
        ZBayProduct storage product = _products[id];

        require(product.buyer == _msgSender(), "Only buyer can confirm delivery");
        require(product.state == ZBayProductState.Dispatched, "Invalid state");

        // 0 is reserved for the attestation verifier
        uint256[] memory signals = new uint256[](2);
        signals[0] = product.attestation;
        signals[1] = uint160(_msgSender());
        bool verified = IZBayVerifier(_verifiers[0]).verify(proof, signals);
        require(verified, "Invalid proof");

        _confirmDelivery(product);

        // if (address(_disputeOracle) != address(0)) {
        //     _disputeOracle.settleAssertion(product.assertionId);
        // }
    }

    /// @dev Dispute delivery
    function disputeDelivery(uint256 id) external {
        ZBayProduct storage product = _products[id];

        require(product.buyer == _msgSender(), "Only buyer can dispute delivery");
        require(product.state == ZBayProductState.Dispatched, "Invalid state");

        product.state = ZBayProductState.Disputed;

        if (address(_disputeOracle) != address(0)) {
            _disputeOracle.disputeAssertion(product.assertionId, _msgSender());
        }

        emit ProductDisputed(id);
    }

    /// @dev UMA assertions callback
    function assertionResolvedCallback(bytes32 assertionId, bool assertedTruthfully) external {
        require(msg.sender == address(_disputeOracle));

        uint256 productId = _assertionToProductId[assertionId];
        ZBayProduct storage product = _products[productId];
        require(product.state == ZBayProductState.Dispatched || product.state == ZBayProductState.Disputed, "Invalid state");

        if (assertedTruthfully) {
            _confirmDelivery(product);
            emit ProductResolved(productId, true);
        } else {
            product.state = ZBayProductState.Cancelled;
            uint256 amountToUnLock = product.price * product.coef / 100;
            _token.transfer(product.buyer, amountToUnLock);
            emit ProductResolved(productId, false);
        }
    }

    /// @dev UMA dispute callback
    function assertionDisputedCallback(bytes32 assertionId) external {
        require(msg.sender == address(_disputeOracle));
        uint256 productId = _assertionToProductId[assertionId];
        ZBayProduct storage product = _products[productId];

        require(product.state == ZBayProductState.Dispatched, "Invalid state");
        product.state = ZBayProductState.Disputed;
        emit ProductDisputed(productId);
    }

    function _confirmDelivery(ZBayProduct storage product) internal {
        product.state = ZBayProductState.Delivered;

        uint256 amountToRelease = product.price * product.coef / 100 - product.price;
        uint256 amountToTreasury = product.price * DEFAULT_TREASURY_PERCENT / 10000; // will be left at the contract
        uint256 amountToSeller = product.price - amountToTreasury;

        _token.transfer(product.seller, amountToSeller);
        _token.transfer(product.buyer, amountToRelease);

        emit ProductDelivered(product.id);
    }

    /// @dev required override
    function _msgData()
        internal view
        override(Context, ERC2771Context)
        returns (bytes calldata)
    {
        return ERC2771Context._msgData();
    }

    /// @dev required override
    function _msgSender()
        internal view
        override(Context, ERC2771Context)
        returns (address)
    {
        return ERC2771Context._msgSender();
    }

    function updateVerifiers(uint256[] calldata ids, address[] calldata verifiers, uint32[] calldata scores)
        external
        onlyOwner
    {
        require(ids.length == verifiers.length, "Invalid input");
        require(ids.length == scores.length, "Invalid input");

        for (uint256 i = 0; i < ids.length; i++) {
            _verifiers[ids[i]] = verifiers[i];
            _verifierScores[verifiers[i]] = scores[i];
        }
    }
}