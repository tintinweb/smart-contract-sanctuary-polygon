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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IControllable {

  function isController(address _contract) external view returns (bool);

  function isGovernance(address _contract) external view returns (bool);

  function created() external view returns (uint256);

  function createdBlock() external view returns (uint256);

  function controller() external view returns (address);

  function increaseRevision(address oldLogic) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IController {

  // --- DEPENDENCY ADDRESSES
  function governance() external view returns (address);

  function voter() external view returns (address);

  function liquidator() external view returns (address);

  function forwarder() external view returns (address);

  function investFund() external view returns (address);

  function veDistributor() external view returns (address);

  function platformVoter() external view returns (address);

  // --- VAULTS

  function vaults(uint id) external view returns (address);

  function vaultsList() external view returns (address[] memory);

  function vaultsListLength() external view returns (uint);

  function isValidVault(address _vault) external view returns (bool);

  // --- restrictions

  function isOperator(address _adr) external view returns (bool);


}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
  /**
   * @dev Returns true if this contract implements the interface defined by
   * `interfaceId`. See the corresponding
   * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
   * to learn more about how these ids are created.
   *
   * This function call must use less than 30 000 gas.
   */
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint);

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
  function approve(address spender, uint amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint amount
  ) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity 0.8.17;

import "./IERC20.sol";

/**
 * https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/release-v4.6/contracts/token/ERC20/extensions/IERC20MetadataUpgradeable.sol
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
  /**
   * @dev Returns the name of the token.
     */
  function name() external view returns (string memory);

  /**
   * @dev Returns the symbol of the token.
     */
  function symbol() external view returns (string memory);

  /**
   * @dev Returns the decimals places of the token.
     */
  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity 0.8.17;

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

pragma solidity 0.8.17;

interface IForwarder {

  function tetu() external view returns (address);
  function tetuThreshold() external view returns (uint);

  function tokenPerDestinationLength(address destination) external view returns (uint);

  function tokenPerDestinationAt(address destination, uint i) external view returns (address);

  function amountPerDestination(address token, address destination) external view returns (uint amount);

  function registerIncome(
    address[] memory tokens,
    uint[] memory amounts,
    address vault,
    bool isDistribute
  ) external;

  function distributeAll(address destination) external;

  function distribute(address token) external;

  function setInvestFundRatio(uint value) external;

  function setGaugesRatio(uint value) external;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ISplitter {

  function init(address controller_, address _asset, address _vault) external;

  // *************** ACTIONS **************

  function withdrawAllToVault() external;

  function withdrawToVault(uint256 amount) external;

  function coverPossibleStrategyLoss(uint earned, uint lost) external;

  function doHardWork() external;

  function investAll() external;

  // **************** VIEWS ***************

  function asset() external view returns (address);

  function vault() external view returns (address);

  function totalAssets() external view returns (uint256);

  function isHardWorking() external view returns (bool);

  function strategies(uint i) external view returns (address);

  function strategiesLength() external view returns (uint);

  function HARDWORK_DELAY() external view returns (uint);

  function lastHardWorks(address strategy) external view returns (uint);

  function pausedStrategies(address strategy) external view returns (bool);

  function pauseInvesting(address strategy) external;

  function continueInvesting(address strategy, uint apr) external;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IStrategyV2 {

  function NAME() external view returns (string memory);

  function strategySpecificName() external view returns (string memory);

  function PLATFORM() external view returns (string memory);

  function STRATEGY_VERSION() external view returns (string memory);

  function asset() external view returns (address);

  function splitter() external view returns (address);

  function compoundRatio() external view returns (uint);

  function totalAssets() external view returns (uint);

  /// @dev Usually, indicate that claimable rewards have reasonable amount.
  function isReadyToHardWork() external view returns (bool);

  /// @return strategyLoss Loss should be covered from Insurance
  function withdrawAllToSplitter() external returns (uint strategyLoss);

  /// @return strategyLoss Loss should be covered from Insurance
  function withdrawToSplitter(uint amount) external returns (uint strategyLoss);

  /// @notice Stakes everything the strategy holds into the reward pool.
  /// @param amount_ Amount transferred to the strategy balance just before calling this function
  /// @param updateTotalAssetsBeforeInvest_ Recalculate total assets amount before depositing.
  ///                                       It can be false if we know exactly, that the amount is already actual.
  /// @return strategyLoss Loss should be covered from Insurance
  function investAll(
    uint amount_,
    bool updateTotalAssetsBeforeInvest_
  ) external returns (
    uint strategyLoss
  );

  function doHardWork() external returns (uint earned, uint lost);

  function setCompoundRatio(uint value) external;

  /// @notice Max amount that can be deposited to the strategy (its internal capacity), see SCB-593.
  ///         0 means no deposit is allowed at this moment
  function capacity() external view returns (uint);

  /// @notice {performanceFee}% of total profit is sent to the {performanceReceiver} before compounding
  function performanceReceiver() external view returns (address);

  /// @notice A percent of total profit that is sent to the {performanceReceiver} before compounding
  /// @dev use FEE_DENOMINATOR
  function performanceFee() external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface ITetuLiquidator {

  struct PoolData {
    address pool;
    address swapper;
    address tokenIn;
    address tokenOut;
  }

  function addLargestPools(PoolData[] memory _pools, bool rewrite) external;

  function addBlueChipsPools(PoolData[] memory _pools, bool rewrite) external;

  function getPrice(address tokenIn, address tokenOut, uint amount) external view returns (uint);

  function getPriceForRoute(PoolData[] memory route, uint amount) external view returns (uint);

  function isRouteExist(address tokenIn, address tokenOut) external view returns (bool);

  function buildRoute(
    address tokenIn,
    address tokenOut
  ) external view returns (PoolData[] memory route, string memory errorMessage);

  function liquidate(
    address tokenIn,
    address tokenOut,
    uint amount,
    uint slippage
  ) external;

  function liquidateWithRoute(
    PoolData[] memory route,
    uint amount,
    uint slippage
  ) external;


}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IVaultInsurance.sol";
import "./IERC20.sol";
import "./ISplitter.sol";

interface ITetuVaultV2 {

  function splitter() external view returns (ISplitter);

  function insurance() external view returns (IVaultInsurance);

  function depositFee() external view returns (uint);

  function withdrawFee() external view returns (uint);

  function init(
    address controller_,
    IERC20 _asset,
    string memory _name,
    string memory _symbol,
    address _gauge,
    uint _buffer
  ) external;

  function setSplitter(address _splitter) external;

  function coverLoss(uint amount) external;

  function initInsurance(IVaultInsurance _insurance) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IVaultInsurance {

  function init(address _vault, address _asset) external;

  function vault() external view returns (address);

  function asset() external view returns (address);

  function transferToVault(uint amount) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @title Library for interface IDs
/// @author bogdoslav
library InterfaceIds {

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant INTERFACE_IDS_LIB_VERSION = "1.0.0";

  /// default notation:
  /// bytes4 public constant I_VOTER = type(IVoter).interfaceId;

  /// As type({Interface}).interfaceId can be changed,
  /// when some functions changed at the interface,
  /// so used hardcoded interface identifiers

  bytes4 public constant I_VOTER = bytes4(keccak256("IVoter"));
  bytes4 public constant I_BRIBE = bytes4(keccak256("IBribe"));
  bytes4 public constant I_GAUGE = bytes4(keccak256("IGauge"));
  bytes4 public constant I_VE_TETU = bytes4(keccak256("IVeTetu"));
  bytes4 public constant I_SPLITTER = bytes4(keccak256("ISplitter"));
  bytes4 public constant I_FORWARDER = bytes4(keccak256("IForwarder"));
  bytes4 public constant I_MULTI_POOL = bytes4(keccak256("IMultiPool"));
  bytes4 public constant I_CONTROLLER = bytes4(keccak256("IController"));
  bytes4 public constant I_TETU_ERC165 = bytes4(keccak256("ITetuERC165"));
  bytes4 public constant I_STRATEGY_V2 = bytes4(keccak256("IStrategyV2"));
  bytes4 public constant I_CONTROLLABLE = bytes4(keccak256("IControllable"));
  bytes4 public constant I_TETU_VAULT_V2 = bytes4(keccak256("ITetuVaultV2"));
  bytes4 public constant I_PLATFORM_VOTER = bytes4(keccak256("IPlatformVoter"));
  bytes4 public constant I_VE_DISTRIBUTOR = bytes4(keccak256("IVeDistributor"));
  bytes4 public constant I_TETU_CONVERTER = bytes4(keccak256("ITetuConverter"));
  bytes4 public constant I_VAULT_INSURANCE = bytes4(keccak256("IVaultInsurance"));
  bytes4 public constant I_STRATEGY_STRICT = bytes4(keccak256("IStrategyStrict"));
  bytes4 public constant I_ERC4626 = bytes4(keccak256("IERC4626"));

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @title Library for setting / getting slot variables (used in upgradable proxy contracts)
/// @author bogdoslav
library SlotsLib {

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant SLOT_LIB_VERSION = "1.0.0";

  // ************* GETTERS *******************

  /// @dev Gets a slot as bytes32
  function getBytes32(bytes32 slot) internal view returns (bytes32 result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot as an address
  function getAddress(bytes32 slot) internal view returns (address result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot as uint256
  function getUint(bytes32 slot) internal view returns (uint result) {
    assembly {
      result := sload(slot)
    }
  }

  // ************* ARRAY GETTERS *******************

  /// @dev Gets an array length
  function arrayLength(bytes32 slot) internal view returns (uint result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot array by index as address
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function addressAt(bytes32 slot, uint index) internal view returns (address result) {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      result := sload(pointer)
    }
  }

  /// @dev Gets a slot array by index as uint
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function uintAt(bytes32 slot, uint index) internal view returns (uint result) {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      result := sload(pointer)
    }
  }

  // ************* SETTERS *******************

  /// @dev Sets a slot with bytes32
  /// @notice Check address for 0 at the setter
  function set(bytes32 slot, bytes32 value) internal {
    assembly {
      sstore(slot, value)
    }
  }

  /// @dev Sets a slot with address
  /// @notice Check address for 0 at the setter
  function set(bytes32 slot, address value) internal {
    assembly {
      sstore(slot, value)
    }
  }

  /// @dev Sets a slot with uint
  function set(bytes32 slot, uint value) internal {
    assembly {
      sstore(slot, value)
    }
  }

  // ************* ARRAY SETTERS *******************

  /// @dev Sets a slot array at index with address
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function setAt(bytes32 slot, uint index, address value) internal {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      sstore(pointer, value)
    }
  }

  /// @dev Sets a slot array at index with uint
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function setAt(bytes32 slot, uint index, uint value) internal {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      sstore(pointer, value)
    }
  }

  /// @dev Sets an array length
  function setLength(bytes32 slot, uint length) internal {
    assembly {
      sstore(slot, length)
    }
  }

  /// @dev Pushes an address to the array
  function push(bytes32 slot, address value) internal {
    uint length = arrayLength(slot);
    setAt(slot, length, value);
    setLength(slot, length + 1);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;


library StringLib {

  /// @dev Inspired by OraclizeAPI's implementation - MIT license
  ///      https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
  function toString(uint value) external pure returns (string memory) {
    return _toString(value);
  }

  function _toString(uint value) internal pure returns (string memory) {
    if (value == 0) {
      return "0";
    }
    uint temp = value;
    uint digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }

  function toAsciiString(address x) external pure returns (string memory) {
    return _toAsciiString(x);
  }

  function _toAsciiString(address x) internal pure returns (string memory) {
    bytes memory s = new bytes(40);
    for (uint i = 0; i < 20; i++) {
      bytes1 b = bytes1(uint8(uint(uint160(x)) / (2 ** (8 * (19 - i)))));
      bytes1 hi = bytes1(uint8(b) / 16);
      bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
      s[2 * i] = _char(hi);
      s[2 * i + 1] = _char(lo);
    }
    return string(s);
  }

  function char(bytes1 b) external pure returns (bytes1 c) {
    return _char(b);
  }

  function _char(bytes1 b) internal pure returns (bytes1 c) {
    if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
    else return bytes1(uint8(b) + 0x57);
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity 0.8.17;

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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity 0.8.17;

import "../interfaces/IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
  /**
   * @dev See {IERC165-supportsInterface}.
     */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IERC165).interfaceId;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity 0.8.17;

import "./Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
  /**
   * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
  uint8 private _initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
     */
  bool private _initializing;

  /**
   * @dev Triggered when the contract has been initialized or reinitialized.
     */
  event Initialized(uint8 version);

  /**
   * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
  modifier initializer() {
    bool isTopLevelCall = !_initializing;
    require(
      (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
      "Initializable: contract is already initialized"
    );
    _initialized = 1;
    if (isTopLevelCall) {
      _initializing = true;
    }
    _;
    if (isTopLevelCall) {
      _initializing = false;
      emit Initialized(1);
    }
  }

  /**
   * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
  modifier reinitializer(uint8 version) {
    require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
    _initialized = version;
    _initializing = true;
    _;
    _initializing = false;
    emit Initialized(version);
  }

  /**
   * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
  modifier onlyInitializing() {
    require(_initializing, "Initializable: contract is not initializing");
    _;
  }

  /**
   * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
  function _disableInitializers() internal virtual {
    require(!_initializing, "Initializable: contract is initializing");
    if (_initialized != type(uint8).max) {
      _initialized = type(uint8).max;
      emit Initialized(type(uint8).max);
    }
  }

  /**
   * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
  function _getInitializedVersion() internal view returns (uint8) {
    return _initialized;
  }

  /**
   * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
  function _isInitializing() internal view returns (bool) {
    return _initializing;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity 0.8.17;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
  enum Rounding {
    Down, // Toward negative infinity
    Up, // Toward infinity
    Zero // Toward zero
  }

  /**
   * @dev Returns the largest of two numbers.
     */
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a > b ? a : b;
  }

  /**
   * @dev Returns the smallest of two numbers.
     */
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  /**
   * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
  function average(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b) / 2 can overflow.
    return (a & b) + (a ^ b) / 2;
  }

  /**
   * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
  function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b - 1) / b can overflow on addition, so we distribute.
    return a == 0 ? 0 : (a - 1) / b + 1;
  }

  /**
   * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
  function mulDiv(
    uint256 x,
    uint256 y,
    uint256 denominator
  ) internal pure returns (uint256 result) {
  unchecked {
    // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
    // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
    // variables such that product = prod1 * 2^256 + prod0.
    uint256 prod0; // Least significant 256 bits of the product
    uint256 prod1; // Most significant 256 bits of the product
    assembly {
      let mm := mulmod(x, y, not(0))
      prod0 := mul(x, y)
      prod1 := sub(sub(mm, prod0), lt(mm, prod0))
    }

    // Handle non-overflow cases, 256 by 256 division.
    if (prod1 == 0) {
      return prod0 / denominator;
    }

    // Make sure the result is less than 2^256. Also prevents denominator == 0.
    require(denominator > prod1, "Math: mulDiv overflow");

    ///////////////////////////////////////////////
    // 512 by 256 division.
    ///////////////////////////////////////////////

    // Make division exact by subtracting the remainder from [prod1 prod0].
    uint256 remainder;
    assembly {
    // Compute remainder using mulmod.
      remainder := mulmod(x, y, denominator)

    // Subtract 256 bit number from 512 bit number.
      prod1 := sub(prod1, gt(remainder, prod0))
      prod0 := sub(prod0, remainder)
    }

    // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
    // See https://cs.stackexchange.com/q/138556/92363.

    // Does not overflow because the denominator cannot be zero at this stage in the function.
    uint256 twos = denominator & (~denominator + 1);
    assembly {
    // Divide denominator by twos.
      denominator := div(denominator, twos)

    // Divide [prod1 prod0] by twos.
      prod0 := div(prod0, twos)

    // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
      twos := add(div(sub(0, twos), twos), 1)
    }

    // Shift in bits from prod1 into prod0.
    prod0 |= prod1 * twos;

    // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
    // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
    // four bits. That is, denominator * inv = 1 mod 2^4.
    uint256 inverse = (3 * denominator) ^ 2;

    // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
    // in modular arithmetic, doubling the correct bits in each step.
    inverse *= 2 - denominator * inverse; // inverse mod 2^8
    inverse *= 2 - denominator * inverse; // inverse mod 2^16
    inverse *= 2 - denominator * inverse; // inverse mod 2^32
    inverse *= 2 - denominator * inverse; // inverse mod 2^64
    inverse *= 2 - denominator * inverse; // inverse mod 2^128
    inverse *= 2 - denominator * inverse; // inverse mod 2^256

    // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
    // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
    // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
    // is no longer required.
    result = prod0 * inverse;
    return result;
  }
  }

  /**
   * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
  function mulDiv(
    uint256 x,
    uint256 y,
    uint256 denominator,
    Rounding rounding
  ) internal pure returns (uint256) {
    uint256 result = mulDiv(x, y, denominator);
    if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
      result += 1;
    }
    return result;
  }

  /**
   * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
  function sqrt(uint256 a) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
    //
    // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
    // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
    //
    // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
    // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
    // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
    //
    // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
    uint256 result = 1 << (log2(a) >> 1);

    // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
    // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
    // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
    // into the expected uint128 result.
  unchecked {
    result = (result + a / result) >> 1;
    result = (result + a / result) >> 1;
    result = (result + a / result) >> 1;
    result = (result + a / result) >> 1;
    result = (result + a / result) >> 1;
    result = (result + a / result) >> 1;
    result = (result + a / result) >> 1;
    return min(result, a / result);
  }
  }

  /**
   * @notice Calculates sqrt(a), following the selected rounding direction.
     */
  function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
  unchecked {
    uint256 result = sqrt(a);
    return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
  }
  }

  /**
   * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
  function log2(uint256 value) internal pure returns (uint256) {
    uint256 result = 0;
  unchecked {
    if (value >> 128 > 0) {
      value >>= 128;
      result += 128;
    }
    if (value >> 64 > 0) {
      value >>= 64;
      result += 64;
    }
    if (value >> 32 > 0) {
      value >>= 32;
      result += 32;
    }
    if (value >> 16 > 0) {
      value >>= 16;
      result += 16;
    }
    if (value >> 8 > 0) {
      value >>= 8;
      result += 8;
    }
    if (value >> 4 > 0) {
      value >>= 4;
      result += 4;
    }
    if (value >> 2 > 0) {
      value >>= 2;
      result += 2;
    }
    if (value >> 1 > 0) {
      result += 1;
    }
  }
    return result;
  }

  /**
   * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
  function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
  unchecked {
    uint256 result = log2(value);
    return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
  }
  }

  /**
   * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
  function log10(uint256 value) internal pure returns (uint256) {
    uint256 result = 0;
  unchecked {
    if (value >= 10**64) {
      value /= 10**64;
      result += 64;
    }
    if (value >= 10**32) {
      value /= 10**32;
      result += 32;
    }
    if (value >= 10**16) {
      value /= 10**16;
      result += 16;
    }
    if (value >= 10**8) {
      value /= 10**8;
      result += 8;
    }
    if (value >= 10**4) {
      value /= 10**4;
      result += 4;
    }
    if (value >= 10**2) {
      value /= 10**2;
      result += 2;
    }
    if (value >= 10**1) {
      result += 1;
    }
  }
    return result;
  }

  /**
   * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
  function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
  unchecked {
    uint256 result = log10(value);
    return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
  }
  }

  /**
   * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
  function log256(uint256 value) internal pure returns (uint256) {
    uint256 result = 0;
  unchecked {
    if (value >> 128 > 0) {
      value >>= 128;
      result += 16;
    }
    if (value >> 64 > 0) {
      value >>= 64;
      result += 8;
    }
    if (value >> 32 > 0) {
      value >>= 32;
      result += 4;
    }
    if (value >> 16 > 0) {
      value >>= 16;
      result += 2;
    }
    if (value >> 8 > 0) {
      result += 1;
    }
  }
    return result;
  }

  /**
   * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
  function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
  unchecked {
    uint256 result = log256(value);
    return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
  }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity 0.8.17;

import "../interfaces/IERC20.sol";
import "../interfaces/IERC20Permit.sol";
import "./Address.sol";

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

pragma solidity 0.8.17;

import "../openzeppelin/Initializable.sol";
import "../tools/TetuERC165.sol";
import "../interfaces/IControllable.sol";
import "../interfaces/IController.sol";
import "../lib/SlotsLib.sol";
import "../lib/InterfaceIds.sol";

/// @title Implement basic functionality for any contract that require strict control
/// @dev Can be used with upgradeable pattern.
///      Require call __Controllable_init() in any case.
/// @author belbix
abstract contract ControllableV3 is Initializable, TetuERC165, IControllable {
  using SlotsLib for bytes32;

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant CONTROLLABLE_VERSION = "3.0.0";

  bytes32 internal constant _CONTROLLER_SLOT = bytes32(uint256(keccak256("eip1967.controllable.controller")) - 1);
  bytes32 internal constant _CREATED_SLOT = bytes32(uint256(keccak256("eip1967.controllable.created")) - 1);
  bytes32 internal constant _CREATED_BLOCK_SLOT = bytes32(uint256(keccak256("eip1967.controllable.created_block")) - 1);
  bytes32 internal constant _REVISION_SLOT = bytes32(uint256(keccak256("eip1967.controllable.revision")) - 1);
  bytes32 internal constant _PREVIOUS_LOGIC_SLOT = bytes32(uint256(keccak256("eip1967.controllable.prev_logic")) - 1);

  event ContractInitialized(address controller, uint ts, uint block);
  event RevisionIncreased(uint value, address oldLogic);

  /// @dev Prevent implementation init
  constructor() {
    _disableInitializers();
  }

  /// @notice Initialize contract after setup it as proxy implementation
  ///         Save block.timestamp in the "created" variable
  /// @dev Use it only once after first logic setup
  /// @param controller_ Controller address
  function __Controllable_init(address controller_) internal onlyInitializing {
    require(controller_ != address(0), "Zero controller");
    _requireInterface(controller_, InterfaceIds.I_CONTROLLER);
    require(IController(controller_).governance() != address(0), "Zero governance");
    _CONTROLLER_SLOT.set(controller_);
    _CREATED_SLOT.set(block.timestamp);
    _CREATED_BLOCK_SLOT.set(block.number);
    emit ContractInitialized(controller_, block.timestamp, block.number);
  }

  /// @dev Return true if given address is controller
  function isController(address _value) public override view returns (bool) {
    return _value == controller();
  }

  /// @notice Return true if given address is setup as governance in Controller
  function isGovernance(address _value) public override view returns (bool) {
    return IController(controller()).governance() == _value;
  }

  /// @dev Contract upgrade counter
  function revision() external view returns (uint){
    return _REVISION_SLOT.getUint();
  }

  /// @dev Previous logic implementation
  function previousImplementation() external view returns (address){
    return _PREVIOUS_LOGIC_SLOT.getAddress();
  }

  /// @dev See {IERC165-supportsInterface}.
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == InterfaceIds.I_CONTROLLABLE || super.supportsInterface(interfaceId);
  }

  // ************* SETTERS/GETTERS *******************

  /// @notice Return controller address saved in the contract slot
  function controller() public view override returns (address) {
    return _CONTROLLER_SLOT.getAddress();
  }

  /// @notice Return creation timestamp
  /// @return Creation timestamp
  function created() external view override returns (uint256) {
    return _CREATED_SLOT.getUint();
  }

  /// @notice Return creation block number
  /// @return Creation block number
  function createdBlock() external override view returns (uint256) {
    return _CREATED_BLOCK_SLOT.getUint();
  }

  /// @dev Revision should be increased on each contract upgrade
  function increaseRevision(address oldLogic) external override {
    require(msg.sender == address(this), "Increase revision forbidden");
    uint r = _REVISION_SLOT.getUint() + 1;
    _REVISION_SLOT.set(r);
    _PREVIOUS_LOGIC_SLOT.set(oldLogic);
    emit RevisionIncreased(r, oldLogic);
  }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IStrategyV2.sol";
import "../interfaces/ISplitter.sol";
import "../interfaces/IForwarder.sol";
import "../proxy/ControllableV3.sol";
import "./StrategyLib.sol";

/// @title Abstract contract for base strategy functionality
/// @author belbix
abstract contract StrategyBaseV2 is IStrategyV2, ControllableV3 {
  using SafeERC20 for IERC20;

  // *************************************************************
  //                        CONSTANTS
  // *************************************************************

  /// @dev Version of this contract. Adjust manually on each code modification.
  string public constant STRATEGY_BASE_VERSION = "2.3.0";
  /// @notice 10% of total profit is sent to {performanceReceiver} before compounding
  uint internal constant DEFAULT_PERFORMANCE_FEE = 10_000;
  address internal constant DEFAULT_PERF_FEE_RECEIVER = 0x9Cc199D4353b5FB3e6C8EEBC99f5139e0d8eA06b;

  // *************************************************************
  //                        VARIABLES
  //                Keep names and ordering!
  //                 Add only in the bottom.
  // *************************************************************

  /// @dev Underlying asset
  address public override asset;
  /// @dev Linked splitter
  address public override splitter;
  /// @dev Percent of profit for autocompound inside this strategy.
  uint public override compoundRatio;
  uint private __deprecatedSlot1;

  /// @notice {performanceFee}% of total profit is sent to {performanceReceiver} before compounding
  /// @dev governance by default
  address public override performanceReceiver;

  /// @notice A percent of total profit that is sent to the {performanceReceiver} before compounding
  /// @dev {DEFAULT_PERFORMANCE_FEE} by default, FEE_DENOMINATOR is used
  uint public override performanceFee;
  /// @dev Represent specific name for this strategy. Should include short strategy name and used assets. Uniq across the vault.
  string public override strategySpecificName;

  // *************************************************************
  //                        INIT
  // *************************************************************

  /// @notice Initialize contract after setup it as proxy implementation
  function __StrategyBase_init(
    address controller_,
    address _splitter
  ) internal onlyInitializing {
    _requireInterface(_splitter, InterfaceIds.I_SPLITTER);
    __Controllable_init(controller_);

    require(IControllable(_splitter).isController(controller_), StrategyLib.WRONG_VALUE);

    asset = ISplitter(_splitter).asset();
    splitter = _splitter;

    performanceReceiver = DEFAULT_PERF_FEE_RECEIVER;
    performanceFee = DEFAULT_PERFORMANCE_FEE;
  }

  // *************************************************************
  //                     PERFORMANCE FEE
  // *************************************************************
  /// @notice Set performance fee and receiver
  function setupPerformanceFee(uint fee_, address receiver_) external {
    StrategyLib._checkSetupPerformanceFee(controller(), fee_, receiver_);
    performanceFee = fee_;
    performanceReceiver = receiver_;
  }

  // *************************************************************
  //                        VIEWS
  // *************************************************************

  /// @dev Total amount of underlying assets under control of this strategy.
  function totalAssets() public view override returns (uint) {
    return IERC20(asset).balanceOf(address(this)) + investedAssets();
  }

  /// @dev See {IERC165-supportsInterface}.
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == InterfaceIds.I_STRATEGY_V2 || super.supportsInterface(interfaceId);
  }

  // *************************************************************
  //                   VOTER ACTIONS
  // *************************************************************

  /// @dev PlatformVoter can change compound ratio for some strategies.
  ///      A strategy can implement another logic for some uniq cases.
  function setCompoundRatio(uint value) external virtual override {
    StrategyLib._checkCompoundRatioChanged(controller(), compoundRatio, value);
    compoundRatio = value;
  }

  // *************************************************************
  //                   OPERATOR ACTIONS
  // *************************************************************

  /// @dev The name will be used for UI.
  function setStrategySpecificName(string calldata name) external {
    StrategyLib._checkStrategySpecificNameChanged(controller(), name);
    strategySpecificName = name;
  }

  /// @dev In case of any issue operator can withdraw all from pool.
  function emergencyExit() external {
    // check inside lib call

    _emergencyExitFromPool();
    StrategyLib.sendOnEmergencyExit(controller(), asset, splitter);
  }

  /// @dev Manual claim rewards.
  function claim() external {
    StrategyLib._checkManualClaim(controller());
    _claim();
  }

  // *************************************************************
  //                    DEPOSIT/WITHDRAW
  // *************************************************************

  /// @notice Stakes everything the strategy holds into the reward pool.
  /// amount_ Amount transferred to the strategy balance just before calling this function
  /// @param updateTotalAssetsBeforeInvest_ Recalculate total assets amount before depositing.
  ///                                       It can be false if we know exactly, that the amount is already actual.
  /// @return strategyLoss Loss should be covered from Insurance
  function investAll(
    uint /*amount_*/,
    bool updateTotalAssetsBeforeInvest_
  ) external override returns (
    uint strategyLoss
  ) {
    uint balance = StrategyLib._checkInvestAll(splitter, asset);

    if (balance > 0) {
      strategyLoss = _depositToPool(balance, updateTotalAssetsBeforeInvest_);
    }

    return strategyLoss;
  }

  /// @dev Withdraws all underlying assets to the vault
  /// @return strategyLoss Loss should be covered from Insurance
  function withdrawAllToSplitter() external override returns (uint strategyLoss) {
    address _splitter = splitter;
    address _asset = asset;

    uint balance = StrategyLib._checkSplitterSenderAndGetBalance(_splitter, _asset);

    (uint expectedWithdrewUSD, uint assetPrice, uint _strategyLoss) = _withdrawAllFromPool();

    StrategyLib._withdrawAllToSplitterPostActions(
      _asset,
      balance,
      expectedWithdrewUSD,
      assetPrice,
      _splitter
    );
    return _strategyLoss;
  }

  /// @dev Withdraws some assets to the splitter
  /// @return strategyLoss Loss should be covered from Insurance
  function withdrawToSplitter(uint amount) external override returns (uint strategyLoss) {
    address _splitter = splitter;
    address _asset = asset;

    uint balance = StrategyLib._checkSplitterSenderAndGetBalance(_splitter, _asset);

    if (amount > balance) {
      uint expectedWithdrewUSD;
      uint assetPrice;

      (expectedWithdrewUSD, assetPrice, strategyLoss) = _withdrawFromPool(amount - balance);
      balance = StrategyLib.checkWithdrawImpact(
        _asset,
        balance,
        expectedWithdrewUSD,
        assetPrice,
        _splitter
      );
    }

    StrategyLib._withdrawToSplitterPostActions(
      amount,
      balance,
      _asset,
      _splitter
    );
    return strategyLoss;
  }

  // *************************************************************
  //                       VIRTUAL
  // These functions must be implemented in the strategy contract
  // *************************************************************

  /// @dev Amount of underlying assets invested to the pool.
  function investedAssets() public view virtual returns (uint);

  /// @notice Deposit given amount to the pool.
  /// @param updateTotalAssetsBeforeInvest_ Recalculate total assets amount before depositing.
  ///                                       It can be false if we know exactly, that the amount is already actual.
  /// @return strategyLoss Loss should be covered from Insurance
  function _depositToPool(
    uint amount,
    bool updateTotalAssetsBeforeInvest_
  ) internal virtual returns (
    uint strategyLoss
  );

  /// @dev Withdraw given amount from the pool.
  /// @return expectedWithdrewUSD Sum of USD value of each asset in the pool that was withdrawn, decimals of {asset}.
  /// @return assetPrice Price of the strategy {asset}.
  /// @return strategyLoss Loss should be covered from Insurance
  function _withdrawFromPool(uint amount) internal virtual returns (
    uint expectedWithdrewUSD,
    uint assetPrice,
    uint strategyLoss
  );

  /// @dev Withdraw all from the pool.
  /// @return expectedWithdrewUSD Sum of USD value of each asset in the pool that was withdrawn, decimals of {asset}.
  /// @return assetPrice Price of the strategy {asset}.
  /// @return strategyLoss Loss should be covered from Insurance
  function _withdrawAllFromPool() internal virtual returns (
    uint expectedWithdrewUSD,
    uint assetPrice,
    uint strategyLoss
  );

  /// @dev If pool support emergency withdraw need to call it for emergencyExit()
  ///      Withdraw assets without impact checking.
  function _emergencyExitFromPool() internal virtual;

  /// @dev Claim all possible rewards.
  function _claim() internal virtual returns (address[] memory rewardTokens, uint[] memory amounts);

  /// @dev This empty reserved space is put in place to allow future versions to add new
  ///      variables without shifting down storage in the inheritance chain.
  ///      See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
  uint[43] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../openzeppelin/SafeERC20.sol";
import "../openzeppelin/Math.sol";
import "../interfaces/IController.sol";
import "../interfaces/ITetuVaultV2.sol";
import "../interfaces/ISplitter.sol";

library StrategyLib {
  using SafeERC20 for IERC20;

  // *************************************************************
  //                        CONSTANTS
  // *************************************************************

  /// @dev Denominator for fee calculation.
  uint internal constant FEE_DENOMINATOR = 100_000;

  // *************************************************************
  //                        EVENTS
  // *************************************************************

  event CompoundRatioChanged(uint oldValue, uint newValue);
  event StrategySpecificNameChanged(string name);
  event EmergencyExit(address sender, uint amount);
  event ManualClaim(address sender);
  event InvestAll(uint balance);
  event WithdrawAllToSplitter(uint amount);
  event WithdrawToSplitter(uint amount, uint sent, uint balance);

  // *************************************************************
  //                        ERRORS
  // *************************************************************

  string internal constant DENIED = "SB: Denied";
  string internal constant TOO_HIGH = "SB: Too high";
  string internal constant WRONG_VALUE = "SB: Wrong value";
  /// @dev Denominator for compound ratio
  uint internal constant COMPOUND_DENOMINATOR = 100_000;

  // *************************************************************
  //                        CHECKS AND EMITS
  // *************************************************************

  function _checkCompoundRatioChanged(address controller, uint oldValue, uint newValue) external {
    onlyPlatformVoter(controller);
    require(newValue <= COMPOUND_DENOMINATOR, TOO_HIGH);
    emit CompoundRatioChanged(oldValue, newValue);
  }

  function _checkStrategySpecificNameChanged(address controller, string calldata newName) external {
    onlyOperators(controller);
    emit StrategySpecificNameChanged(newName);
  }

  function _checkManualClaim(address controller) external {
    onlyOperators(controller);
    emit ManualClaim(msg.sender);
  }

  function _checkInvestAll(address splitter, address asset) external returns (uint assetBalance) {
    onlySplitter(splitter);
    assetBalance = IERC20(asset).balanceOf(address(this));
    emit InvestAll(assetBalance);
  }

  // *************************************************************
  //                     RESTRICTIONS
  // *************************************************************

  /// @dev Restrict access only for operators
  function onlyOperators(address controller) public view {
    require(IController(controller).isOperator(msg.sender), DENIED);
  }

  /// @dev Restrict access only for governance
  function onlyGovernance(address controller) public view {
    require(IController(controller).governance() == msg.sender, DENIED);
  }

  /// @dev Restrict access only for platform voter
  function onlyPlatformVoter(address controller) public view {
    require(IController(controller).platformVoter() == msg.sender, DENIED);
  }

  /// @dev Restrict access only for splitter
  function onlySplitter(address splitter) public view {
    require(splitter == msg.sender, DENIED);
  }

  function _checkSetupPerformanceFee(address controller, uint fee_, address receiver_) external view {
    onlyGovernance(controller);
    require(fee_ <= 100_000, TOO_HIGH);
    require(receiver_ != address(0), WRONG_VALUE);
  }

  // *************************************************************
  //                       HELPERS
  // *************************************************************

  /// @notice Calculate withdrawn amount in USD using the {assetPrice}.
  ///         Revert if the amount is different from expected too much (high price impact)
  /// @param balanceBefore Asset balance of the strategy before withdrawing
  /// @param expectedWithdrewUSD Expected amount in USD, decimals are same to {_asset}
  /// @param assetPrice Price of the asset, decimals 18
  /// @return balance Current asset balance of the strategy
  function checkWithdrawImpact(
    address _asset,
    uint balanceBefore,
    uint expectedWithdrewUSD,
    uint assetPrice,
    address _splitter
  ) public view returns (uint balance) {
    balance = IERC20(_asset).balanceOf(address(this));
    if (assetPrice != 0 && expectedWithdrewUSD != 0) {

      uint withdrew = balance > balanceBefore ? balance - balanceBefore : 0;
      uint withdrewUSD = withdrew * assetPrice / 1e18;
      uint priceChangeTolerance = ITetuVaultV2(ISplitter(_splitter).vault()).withdrawFee();
      uint difference = expectedWithdrewUSD > withdrewUSD ? expectedWithdrewUSD - withdrewUSD : 0;
      require(difference * FEE_DENOMINATOR / expectedWithdrewUSD <= priceChangeTolerance, TOO_HIGH);
    }
  }

  function sendOnEmergencyExit(address controller, address asset, address splitter) external {
    onlyOperators(controller);

    uint balance = IERC20(asset).balanceOf(address(this));
    IERC20(asset).safeTransfer(splitter, balance);
    emit EmergencyExit(msg.sender, balance);
  }

  function _checkSplitterSenderAndGetBalance(address splitter, address asset) external view returns (uint balance) {
    onlySplitter(splitter);
    return IERC20(asset).balanceOf(address(this));
  }

  function _withdrawAllToSplitterPostActions(
    address _asset,
    uint balanceBefore,
    uint expectedWithdrewUSD,
    uint assetPrice,
    address _splitter
  ) external {
    uint balance = checkWithdrawImpact(
      _asset,
      balanceBefore,
      expectedWithdrewUSD,
      assetPrice,
      _splitter
    );

    if (balance != 0) {
      IERC20(_asset).safeTransfer(_splitter, balance);
    }
    emit WithdrawAllToSplitter(balance);
  }

  function _withdrawToSplitterPostActions(
    uint amount,
    uint balance,
    address _asset,
    address _splitter
  ) external {
    uint amountAdjusted = Math.min(amount, balance);
    if (amountAdjusted != 0) {
      IERC20(_asset).safeTransfer(_splitter, amountAdjusted);
    }
    emit WithdrawToSplitter(amount, amountAdjusted, balance);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../openzeppelin/ERC165.sol";
import "../interfaces/IERC20.sol";
import "../lib/InterfaceIds.sol";

/// @dev Tetu Implementation of the {IERC165} interface extended with helper functions.
/// @author bogdoslav
abstract contract TetuERC165 is ERC165 {

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == InterfaceIds.I_TETU_ERC165 || super.supportsInterface(interfaceId);
  }

  // *************************************************************
  //                        HELPER FUNCTIONS
  // *************************************************************
  /// @author bogdoslav

  /// @dev Checks what interface with id is supported by contract.
  /// @return bool. Do not throws
  function _isInterfaceSupported(address contractAddress, bytes4 interfaceId) internal view returns (bool) {
    require(contractAddress != address(0), "Zero address");
    // check what address is contract
    uint codeSize;
    assembly {
      codeSize := extcodesize(contractAddress)
    }
    if (codeSize == 0) return false;

    try IERC165(contractAddress).supportsInterface(interfaceId) returns (bool isSupported) {
      return isSupported;
    } catch {
    }
    return false;
  }

  /// @dev Checks what interface with id is supported by contract and reverts otherwise
  function _requireInterface(address contractAddress, bytes4 interfaceId) internal view {
    require(_isInterfaceSupported(contractAddress, interfaceId), "Interface is not supported");
  }

  /// @dev Checks what address is ERC20.
  /// @return bool. Do not throws
  function _isERC20(address contractAddress) internal view returns (bool) {
    require(contractAddress != address(0), "Zero address");
    // check what address is contract
    uint codeSize;
    assembly {
      codeSize := extcodesize(contractAddress)
    }
    if (codeSize == 0) return false;

    bool totalSupplySupported;
    try IERC20(contractAddress).totalSupply() returns (uint) {
      totalSupplySupported = true;
    } catch {
    }

    bool balanceSupported;
    try IERC20(contractAddress).balanceOf(address(this)) returns (uint) {
      balanceSupported = true;
    } catch {
    }

    return totalSupplySupported && balanceSupported;
  }


  /// @dev Checks what interface with id is supported by contract and reverts otherwise
  function _requireERC20(address contractAddress) internal view {
    require(_isERC20(contractAddress), "Not ERC20");
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @notice Keep and provide addresses of all application contracts
interface IConverterController {
  function governance() external view returns (address);

  // ********************* Health factor explanation  ****************
  // For example, a landing platform has: liquidity threshold = 0.85, LTV=0.8, LTV / LT = 1.0625
  // For collateral $100 we can borrow $80. A liquidation happens if the cost of collateral will reduce below $85.
  // We set min-health-factor = 1.1, target-health-factor = 1.3
  // For collateral 100 we will borrow 100/1.3 = 76.92
  //
  // Collateral value   100        77            assume that collateral value is decreased at 100/77=1.3 times
  // Collateral * LT    85         65.45
  // Borrow value       65.38      65.38         but borrow value is the same as before
  // Health factor      1.3        1.001         liquidation almost happens here (!)
  //
  /// So, if we have target factor 1.3, it means, that if collateral amount will decreases at 1.3 times
  // and the borrow value won't change at the same time, the liquidation happens at that point.
  // Min health factor marks the point at which a rebalancing must be made asap.
  // *****************************************************************

  /// @notice min allowed health factor with decimals 2, must be >= 1e2
  function minHealthFactor2() external view returns (uint16);
  function setMinHealthFactor2(uint16 value_) external;

  /// @notice target health factor with decimals 2
  /// @dev If the health factor is below/above min/max threshold, we need to make repay
  ///      or additional borrow and restore the health factor to the given target value
  function targetHealthFactor2() external view returns (uint16);
  function setTargetHealthFactor2(uint16 value_) external;

  /// @notice max allowed health factor with decimals 2
  /// @dev For future versions, currently max health factor is not used
  function maxHealthFactor2() external view returns (uint16);
  /// @dev For future versions, currently max health factor is not used
  function setMaxHealthFactor2(uint16 value_) external;

  /// @notice get current value of blocks per day. The value is set manually at first and can be auto-updated later
  function blocksPerDay() external view returns (uint);
  /// @notice set value of blocks per day manually and enable/disable auto update of this value
  function setBlocksPerDay(uint blocksPerDay_, bool enableAutoUpdate_) external;
  /// @notice Check if it's time to call updateBlocksPerDay()
  /// @param periodInSeconds_ Period of auto-update in seconds
  function isBlocksPerDayAutoUpdateRequired(uint periodInSeconds_) external view returns (bool);
  /// @notice Recalculate blocksPerDay value
  /// @param periodInSeconds_ Period of auto-update in seconds
  function updateBlocksPerDay(uint periodInSeconds_) external;

  /// @notice 0 - new borrows are allowed, 1 - any new borrows are forbidden
  function paused() external view returns (bool);

  /// @notice the given user is whitelisted and is allowed to make borrow/swap using TetuConverter
  function isWhitelisted(address user_) external view returns (bool);

  /// @notice The size of the gap by which the debt should be increased upon repayment
  ///         Such gaps are required by AAVE pool adapters to workaround dust tokens problem
  ///         and be able to make full repayment.
  /// @dev Debt gap is applied as following: toPay = debt * (DEBT_GAP_DENOMINATOR + debtGap) / DEBT_GAP_DENOMINATOR
  function debtGap() external view returns (uint);

  //-----------------------------------------------------
  //        Core application contracts
  //-----------------------------------------------------

  function tetuConverter() external view returns (address);
  function borrowManager() external view returns (address);
  function debtMonitor() external view returns (address);
  function tetuLiquidator() external view returns (address);
  function swapManager() external view returns (address);
  function priceOracle() external view returns (address);

  //-----------------------------------------------------
  //        External contracts
  //-----------------------------------------------------
  /// @notice A keeper to control health and efficiency of the borrows
  function keeper() external view returns (address);
  /// @notice Controller of tetu-contracts-v2, that is allowed to update proxy contracts
  function proxyUpdater() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IConverterControllerProvider {
  function controller() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IPriceOracle {
  /// @notice Return asset price in USD, decimals 18
  function getAssetPrice(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IConverterControllerProvider.sol";

/// @notice Main contract of the TetuConverter application
/// @dev Borrower (strategy) makes all operations via this contract only.
interface ITetuConverter is IConverterControllerProvider {

  /// @notice Find possible borrow strategies and provide "cost of money" as interest for the period for each strategy
  ///         Result arrays of the strategy are ordered in ascending order of APR.
  /// @param entryData_ Encoded entry kind and additional params if necessary (set of params depends on the kind)
  ///                   See EntryKinds.sol\ENTRY_KIND_XXX constants for possible entry kinds
  ///                   0 is used by default
  /// @param amountIn_  The meaning depends on entryData
  ///                   For entryKind=0 it's max available amount of collateral
  /// @param periodInBlocks_ Estimated period to keep target amount. It's required to compute APR
  /// @return converters Array of available converters ordered in ascending order of APR.
  ///                    Each item contains a result contract that should be used for conversion; it supports IConverter
  ///                    This address should be passed to borrow-function during conversion.
  ///                    The length of array is always equal to the count of available lending platforms.
  ///                    Last items in array can contain zero addresses (it means they are not used)
  /// @return collateralAmountsOut Amounts that should be provided as a collateral
  /// @return amountToBorrowsOut Amounts that should be borrowed
  ///                            This amount is not zero if corresponded converter is not zero.
  /// @return aprs18 Interests on the use of {amountIn_} during the given period, decimals 18
  function findBorrowStrategies(
    bytes memory entryData_,
    address sourceToken_,
    uint amountIn_,
    address targetToken_,
    uint periodInBlocks_
  ) external view returns (
    address[] memory converters,
    uint[] memory collateralAmountsOut,
    uint[] memory amountToBorrowsOut,
    int[] memory aprs18
  );

  /// @notice Find best swap strategy and provide "cost of money" as interest for the period
  /// @dev This is writable function with read-only behavior.
  ///      It should be writable to be able to simulate real swap and get a real APR.
  /// @param entryData_ Encoded entry kind and additional params if necessary (set of params depends on the kind)
  ///                   See EntryKinds.sol\ENTRY_KIND_XXX constants for possible entry kinds
  ///                   0 is used by default
  /// @param amountIn_  The meaning depends on entryData
  ///                   For entryKind=0 it's max available amount of collateral
  ///                   This amount must be approved to TetuConverter before the call.
  ///                   For entryKind=2 we don't know amount of collateral before the call,
  ///                   so it's necessary to approve large enough amount (or make infinity approve)
  /// @return converter Result contract that should be used for conversion to be passed to borrow()
  /// @return sourceAmountOut Amount of {sourceToken_} that should be swapped to get {targetToken_}
  ///                         It can be different from the {sourceAmount_} for some entry kinds.
  /// @return targetAmountOut Result amount of {targetToken_} after swap
  /// @return apr18 Interest on the use of {outMaxTargetAmount} during the given period, decimals 18
  function findSwapStrategy(
    bytes memory entryData_,
    address sourceToken_,
    uint amountIn_,
    address targetToken_
  ) external returns (
    address converter,
    uint sourceAmountOut,
    uint targetAmountOut,
    int apr18
  );

  /// @notice Find best conversion strategy (swap or borrow) and provide "cost of money" as interest for the period.
  ///         It calls both findBorrowStrategy and findSwapStrategy and selects a best strategy.
  /// @dev This is writable function with read-only behavior.
  ///      It should be writable to be able to simulate real swap and get a real APR for swapping.
  /// @param entryData_ Encoded entry kind and additional params if necessary (set of params depends on the kind)
  ///                   See EntryKinds.sol\ENTRY_KIND_XXX constants for possible entry kinds
  ///                   0 is used by default
  /// @param amountIn_  The meaning depends on entryData
  ///                   For entryKind=0 it's max available amount of collateral
  ///                   This amount must be approved to TetuConverter before the call.
  ///                   For entryKind=2 we don't know amount of collateral before the call,
  ///                   so it's necessary to approve large enough amount (or make infinity approve)
  /// @param periodInBlocks_ Estimated period to keep target amount. It's required to compute APR
  /// @return converter Result contract that should be used for conversion to be passed to borrow().
  /// @return collateralAmountOut Amount of {sourceToken_} that should be swapped to get {targetToken_}
  ///                             It can be different from the {sourceAmount_} for some entry kinds.
  /// @return amountToBorrowOut Result amount of {targetToken_} after conversion
  /// @return apr18 Interest on the use of {outMaxTargetAmount} during the given period, decimals 18
  function findConversionStrategy(
    bytes memory entryData_,
    address sourceToken_,
    uint amountIn_,
    address targetToken_,
    uint periodInBlocks_
  ) external returns (
    address converter,
    uint collateralAmountOut,
    uint amountToBorrowOut,
    int apr18
  );

  /// @notice Convert {collateralAmount_} to {amountToBorrow_} using {converter_}
  ///         Target amount will be transferred to {receiver_}. No re-balancing here.
  /// @dev Transferring of {collateralAmount_} by TetuConverter-contract must be approved by the caller before the call
  ///      Only whitelisted users are allowed to make borrows
  /// @param converter_ A converter received from findBestConversionStrategy.
  /// @param collateralAmount_ Amount of {collateralAsset_} to be converted.
  ///                          This amount must be approved to TetuConverter before the call.
  /// @param amountToBorrow_ Amount of {borrowAsset_} to be borrowed and sent to {receiver_}
  /// @param receiver_ A receiver of borrowed amount
  /// @return borrowedAmountOut Exact borrowed amount transferred to {receiver_}
  function borrow(
    address converter_,
    address collateralAsset_,
    uint collateralAmount_,
    address borrowAsset_,
    uint amountToBorrow_,
    address receiver_
  ) external returns (
    uint borrowedAmountOut
  );

  /// @notice Full or partial repay of the borrow
  /// @dev A user should transfer {amountToRepay_} to TetuConverter before calling repay()
  /// @param amountToRepay_ Amount of borrowed asset to repay.
  ///        You can know exact total amount of debt using {getStatusCurrent}.
  ///        if the amount exceed total amount of the debt:
  ///           - the debt will be fully repaid
  ///           - remain amount will be swapped from {borrowAsset_} to {collateralAsset_}
  ///        This amount should be calculated with taking into account possible debt gap,
  ///        You should call getDebtAmountCurrent(debtGap = true) to get this amount.
  /// @param receiver_ A receiver of the collateral that will be withdrawn after the repay
  ///                  The remained amount of borrow asset will be returned to the {receiver_} too
  /// @return collateralAmountOut Exact collateral amount transferred to {collateralReceiver_}
  ///         If TetuConverter is not able to make the swap, it reverts
  /// @return returnedBorrowAmountOut A part of amount-to-repay that wasn't converted to collateral asset
  ///                                 because of any reasons (i.e. there is no available conversion strategy)
  ///                                 This amount is returned back to the collateralReceiver_
  /// @return swappedLeftoverCollateralOut A part of collateral received through the swapping
  /// @return swappedLeftoverBorrowOut A part of amountToRepay_ that was swapped
  function repay(
    address collateralAsset_,
    address borrowAsset_,
    uint amountToRepay_,
    address receiver_
  ) external returns (
    uint collateralAmountOut,
    uint returnedBorrowAmountOut,
    uint swappedLeftoverCollateralOut,
    uint swappedLeftoverBorrowOut
  );

  /// @notice Estimate result amount after making full or partial repay
  /// @dev It works in exactly same way as repay() but don't make actual repay
  ///      Anyway, the function is write, not read-only, because it makes updateStatus()
  /// @param user_ user whose amount-to-repay will be calculated
  /// @param amountToRepay_ Amount of borrowed asset to repay.
  ///        This amount should be calculated without possible debt gap.
  ///        In this way it's differ from {repay}
  /// @return collateralAmountOut Total collateral amount to be returned after repay in exchange of {amountToRepay_}
  /// @return swappedAmountOut A part of {collateralAmountOut} that were received by direct swap
  function quoteRepay(
    address user_,
    address collateralAsset_,
    address borrowAsset_,
    uint amountToRepay_
  ) external returns (
    uint collateralAmountOut,
    uint swappedAmountOut
  );

  /// @notice Update status in all opened positions
  ///         After this call getDebtAmount will be able to return exact amount to repay
  /// @param user_ user whose debts will be returned
  /// @param useDebtGap_ Calculate exact value of the debt (false) or amount to pay (true)
  ///        Exact value of the debt can be a bit different from amount to pay, i.e. AAVE has dust tokens problem.
  ///        Exact amount of debt should be used to calculate shared price, amount to pay - for repayment
  /// @return totalDebtAmountOut Borrowed amount that should be repaid to pay off the loan in full
  /// @return totalCollateralAmountOut Amount of collateral that should be received after paying off the loan
  function getDebtAmountCurrent(
    address user_,
    address collateralAsset_,
    address borrowAsset_,
    bool useDebtGap_
  ) external returns (
    uint totalDebtAmountOut,
    uint totalCollateralAmountOut
  );

  /// @notice Total amount of borrow tokens that should be repaid to close the borrow completely.
  /// @param user_ user whose debts will be returned
  /// @param useDebtGap_ Calculate exact value of the debt (false) or amount to pay (true)
  ///        Exact value of the debt can be a bit different from amount to pay, i.e. AAVE has dust tokens problem.
  ///        Exact amount of debt should be used to calculate shared price, amount to pay - for repayment
  /// @return totalDebtAmountOut Borrowed amount that should be repaid to pay off the loan in full
  /// @return totalCollateralAmountOut Amount of collateral that should be received after paying off the loan
  function getDebtAmountStored(
    address user_,
    address collateralAsset_,
    address borrowAsset_,
    bool useDebtGap_
  ) external view returns (
    uint totalDebtAmountOut,
    uint totalCollateralAmountOut
  );

  /// @notice User needs to redeem some collateral amount. Calculate an amount of borrow token that should be repaid
  /// @param user_ user whose debts will be returned
  /// @param collateralAmountRequired_ Amount of collateral required by the user
  /// @return borrowAssetAmount Borrowed amount that should be repaid to receive back following amount of collateral:
  ///                           amountToReceive = collateralAmountRequired_ - unobtainableCollateralAssetAmount
  /// @return unobtainableCollateralAssetAmount A part of collateral that cannot be obtained in any case
  ///                                           even if all borrowed amount will be returned.
  ///                                           If this amount is not 0, you ask to get too much collateral.
  function estimateRepay(
    address user_,
    address collateralAsset_,
    uint collateralAmountRequired_,
    address borrowAsset_
  ) external view returns (
    uint borrowAssetAmount,
    uint unobtainableCollateralAssetAmount
  );

  /// @notice Transfer all reward tokens to {receiver_}
  /// @return rewardTokensOut What tokens were transferred. Same reward token can appear in the array several times
  /// @return amountsOut Amounts of transferred rewards, the array is synced with {rewardTokens}
  function claimRewards(address receiver_) external returns (
    address[] memory rewardTokensOut,
    uint[] memory amountsOut
  );

  /// @notice Swap {amountIn_} of {assetIn_} to {assetOut_} and send result amount to {receiver_}
  ///         The swapping is made using TetuLiquidator with checking price impact using embedded price oracle.
  /// @param amountIn_ Amount of {assetIn_} to be swapped.
  ///                      It should be transferred on balance of the TetuConverter before the function call
  /// @param receiver_ Result amount will be sent to this address
  /// @param priceImpactToleranceSource_ Price impact tolerance for liquidate-call, decimals = 100_000
  /// @param priceImpactToleranceTarget_ Price impact tolerance for price-oracle-check, decimals = 100_000
  /// @return amountOut The amount of {assetOut_} that has been sent to the receiver
  function safeLiquidate(
    address assetIn_,
    uint amountIn_,
    address assetOut_,
    address receiver_,
    uint priceImpactToleranceSource_,
    uint priceImpactToleranceTarget_
  ) external returns (
    uint amountOut
  );

  /// @notice Check if {amountOut_} is too different from the value calculated directly using price oracle prices
  /// @return Price difference is ok for the given {priceImpactTolerance_}
  function isConversionValid(
    address assetIn_,
    uint amountIn_,
    address assetOut_,
    uint amountOut_,
    uint priceImpactTolerance_
  ) external view returns (bool);

  /// @notice Close given borrow and return collateral back to the user, governance only
  /// @dev The pool adapter asks required amount-to-repay from the user internally
  /// @param poolAdapter_ The pool adapter that represents the borrow
  /// @param closePosition Close position after repay
  ///        Usually it should be true, because the function always tries to repay all debt
  ///        false can be used if user doesn't have enough amount to pay full debt
  ///              and we are trying to pay "as much as possible"
  /// @return collateralAmountOut Amount of collateral returned to the user
  /// @return repaidAmountOut Amount of borrow asset paid to the lending platform
  function repayTheBorrow(address poolAdapter_, bool closePosition) external returns (
    uint collateralAmountOut,
    uint repaidAmountOut
  );

  /// @notice Get active borrows of the user with given collateral/borrowToken
  /// @dev Simple access to IDebtMonitor.getPositions
  /// @return poolAdaptersOut The instances of IPoolAdapter
  function getPositions(address user_, address collateralToken_, address borrowedToken_) external view returns (
    address[] memory poolAdaptersOut
  );

  /// @notice Save token from TC-balance to {receiver}
  /// @dev Normally TetuConverter doesn't have any tokens on balance, they can appear there accidentally only
  function salvage(address receiver, address token, uint amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @notice TetuConverter sends callback notifications to its user via this interface
interface ITetuConverterCallback {
  /// @notice Converters calls this function if user should return some amount back.
  ///         f.e. when the health factor is unhealthy and the converter needs more tokens to fix it.
  ///         or when the full repay is required and converter needs to get full amount-to-repay.
  /// @param asset_ Required asset (either collateral or borrow)
  /// @param amount_ Required amount of the {asset_}
  /// @return amountOut Exact amount that borrower has sent to balance of TetuConverter
  function requirePayAmountBack(address asset_, uint amount_) external returns (uint amountOut);

  /// @notice TetuConverter calls this function when it sends any amount to user's balance
  /// @param assets_ Any asset sent to the balance, i.e. inside repayTheBorrow
  /// @param amounts_ Amount of {asset_} that has been sent to the user's balance
  function onTransferAmounts(address[] memory assets_, uint[] memory amounts_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IBasePositionManagerEvents {
  /// @notice Emitted when a token is minted for a given position
  /// @param tokenId the newly minted tokenId
  /// @param poolId poolId of the token
  /// @param liquidity liquidity minted to the position range
  /// @param amount0 token0 quantity needed to mint the liquidity
  /// @param amount1 token1 quantity needed to mint the liquidity
  event MintPosition(
    uint256 indexed tokenId,
    uint80 indexed poolId,
    uint128 liquidity,
    uint256 amount0,
    uint256 amount1
  );

  /// @notice Emitted when a token is burned
  /// @param tokenId id of the token
  event BurnPosition(uint256 indexed tokenId);

  /// @notice Emitted when add liquidity
  /// @param tokenId id of the token
  /// @param liquidity the increase amount of liquidity
  /// @param amount0 token0 quantity needed to increase liquidity
  /// @param amount1 token1 quantity needed to increase liquidity
  /// @param additionalRTokenOwed additional rToken earned
  event AddLiquidity(
    uint256 indexed tokenId,
    uint128 liquidity,
    uint256 amount0,
    uint256 amount1,
    uint256 additionalRTokenOwed
  );

  /// @notice Emitted when remove liquidity
  /// @param tokenId id of the token
  /// @param liquidity the decease amount of liquidity
  /// @param amount0 token0 quantity returned when remove liquidity
  /// @param amount1 token1 quantity returned when remove liquidity
  /// @param additionalRTokenOwed additional rToken earned
  event RemoveLiquidity(
    uint256 indexed tokenId,
    uint128 liquidity,
    uint256 amount0,
    uint256 amount1,
    uint256 additionalRTokenOwed
  );

  /// @notice Emitted when burn position's RToken
  /// @param tokenId id of the token
  /// @param rTokenBurn amount of position's RToken burnt
  event BurnRToken(uint256 indexed tokenId, uint256 rTokenBurn);

  /// @notice Emitted when sync fee growth
  /// @param tokenId id of the token
  /// @param additionalRTokenOwed additional rToken earned
  event SyncFeeGrowth(uint256 indexed tokenId, uint256 additionalRTokenOwed);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import {IERC721Metadata} from '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import {IRouterTokenHelper} from './IRouterTokenHelper.sol';
import {IBasePositionManagerEvents} from './base_position_manager/IBasePositionManagerEvents.sol';

interface IBasePositionManager is IRouterTokenHelper, IBasePositionManagerEvents {
  struct Position {
    // the nonce for permits
    uint96 nonce;
    // the address that is approved for spending this token
    address operator;
    // the ID of the pool with which this token is connected
    uint80 poolId;
    // the tick range of the position
    int24 tickLower;
    int24 tickUpper;
    // the liquidity of the position
    uint128 liquidity;
    // the current rToken that the position owed
    uint256 rTokenOwed;
    // fee growth per unit of liquidity as of the last update to liquidity
    uint256 feeGrowthInsideLast;
  }

  struct PoolInfo {
    address token0;
    uint24 fee;
    address token1;
  }

  /// @notice Params for the first time adding liquidity, mint new nft to sender
  /// @param token0 the token0 of the pool
  /// @param token1 the token1 of the pool
  ///   - must make sure that token0 < token1
  /// @param fee the pool's fee in fee units
  /// @param tickLower the position's lower tick
  /// @param tickUpper the position's upper tick
  ///   - must make sure tickLower < tickUpper, and both are in tick distance
  /// @param ticksPrevious the nearest tick that has been initialized and lower than or equal to
  ///   the tickLower and tickUpper, use to help insert the tickLower and tickUpper if haven't initialized
  /// @param amount0Desired the desired amount for token0
  /// @param amount1Desired the desired amount for token1
  /// @param amount0Min min amount of token 0 to add
  /// @param amount1Min min amount of token 1 to add
  /// @param recipient the owner of the position
  /// @param deadline time that the transaction will be expired
  struct MintParams {
    address token0;
    address token1;
    uint24 fee;
    int24 tickLower;
    int24 tickUpper;
    int24[2] ticksPrevious;
    uint256 amount0Desired;
    uint256 amount1Desired;
    uint256 amount0Min;
    uint256 amount1Min;
    address recipient;
    uint256 deadline;
  }

  /// @notice Params for adding liquidity to the existing position
  /// @param tokenId id of the position to increase its liquidity
  /// @param ticksPrevious the nearest tick that has been initialized and lower than or equal to
  ///   the tickLower and tickUpper, use to help insert the tickLower and tickUpper if haven't initialized
  ///   only needed if the position has been closed and the owner wants to add more liquidity
  /// @param amount0Desired the desired amount for token0
  /// @param amount1Desired the desired amount for token1
  /// @param amount0Min min amount of token 0 to add
  /// @param amount1Min min amount of token 1 to add
  /// @param deadline time that the transaction will be expired
  struct IncreaseLiquidityParams {
    uint256 tokenId;
    int24[2] ticksPrevious;
    uint256 amount0Desired;
    uint256 amount1Desired;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
  }

  /// @notice Params for remove liquidity from the existing position
  /// @param tokenId id of the position to remove its liquidity
  /// @param amount0Min min amount of token 0 to receive
  /// @param amount1Min min amount of token 1 to receive
  /// @param deadline time that the transaction will be expired
  struct RemoveLiquidityParams {
    uint256 tokenId;
    uint128 liquidity;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
  }

  /// @notice Burn the rTokens to get back token0 + token1 as fees
  /// @param tokenId id of the position to burn r token
  /// @param amount0Min min amount of token 0 to receive
  /// @param amount1Min min amount of token 1 to receive
  /// @param deadline time that the transaction will be expired
  struct BurnRTokenParams {
    uint256 tokenId;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
  }

  /// @notice Creates a new pool if it does not exist, then unlocks if it has not been unlocked
  /// @param token0 the token0 of the pool
  /// @param token1 the token1 of the pool
  /// @param fee the fee for the pool
  /// @param currentSqrtP the initial price of the pool
  /// @return pool returns the pool address
  function createAndUnlockPoolIfNecessary(
    address token0,
    address token1,
    uint24 fee,
    uint160 currentSqrtP
  ) external payable returns (address pool);

  function mint(MintParams calldata params)
    external
    payable
    returns (
      uint256 tokenId,
      uint128 liquidity,
      uint256 amount0,
      uint256 amount1
    );

  function addLiquidity(IncreaseLiquidityParams calldata params)
    external
    payable
    returns (
      uint128 liquidity,
      uint256 amount0,
      uint256 amount1,
      uint256 additionalRTokenOwed
    );

  function removeLiquidity(RemoveLiquidityParams calldata params)
    external
    returns (
      uint256 amount0,
      uint256 amount1,
      uint256 additionalRTokenOwed
    );

  function burnRTokens(BurnRTokenParams calldata params)
    external
    returns (
      uint256 rTokenQty,
      uint256 amount0,
      uint256 amount1
    );

  /**
   * @dev Burn the token by its owner
   * @notice All liquidity should be removed before burning
   */
  function burn(uint256 tokenId) external payable;

  function syncFeeGrowth(uint256 tokenId) external returns (uint256 additionalRTokenOwed);

  function positions(uint256 tokenId)
    external
    view
    returns (Position memory pos, PoolInfo memory info);

  function addressToPoolId(address pool) external view returns (uint80);

  function isRToken(address token) external view returns (bool);

  function nextPoolId() external view returns (uint80);

  function nextTokenId() external view returns (uint256);

  /**
   * @dev Returns true if this contract implements the interface defined by
   * `interfaceId`. See the corresponding
   * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
   * to learn more about how these ids are created.
   *
   * This function call must use less than 30 000 gas.
   */
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title KyberSwap v2 factory
/// @notice Deploys KyberSwap v2 pools and manages control over government fees
interface IFactory {
  /// @notice Emitted when a pool is created
  /// @param token0 First pool token by address sort order
  /// @param token1 Second pool token by address sort order
  /// @param swapFeeUnits Fee to be collected upon every swap in the pool, in fee units
  /// @param tickDistance Minimum number of ticks between initialized ticks
  /// @param pool The address of the created pool
  event PoolCreated(
    address indexed token0,
    address indexed token1,
    uint24 indexed swapFeeUnits,
    int24 tickDistance,
    address pool
  );

  /// @notice Emitted when a new fee is enabled for pool creation via the factory
  /// @param swapFeeUnits Fee to be collected upon every swap in the pool, in fee units
  /// @param tickDistance Minimum number of ticks between initialized ticks for pools created with the given fee
  event SwapFeeEnabled(uint24 indexed swapFeeUnits, int24 indexed tickDistance);

  /// @notice Emitted when vesting period changes
  /// @param vestingPeriod The maximum time duration for which LP fees
  /// are proportionally burnt upon LP removals
  event VestingPeriodUpdated(uint32 vestingPeriod);

  /// @notice Emitted when configMaster changes
  /// @param oldConfigMaster configMaster before the update
  /// @param newConfigMaster configMaster after the update
  event ConfigMasterUpdated(address oldConfigMaster, address newConfigMaster);

  /// @notice Emitted when fee configuration changes
  /// @param feeTo Recipient of government fees
  /// @param governmentFeeUnits Fee amount, in fee units,
  /// to be collected out of the fee charged for a pool swap
  event FeeConfigurationUpdated(address feeTo, uint24 governmentFeeUnits);

  /// @notice Emitted when whitelist feature is enabled
  event WhitelistEnabled();

  /// @notice Emitted when whitelist feature is disabled
  event WhitelistDisabled();

  /// @notice Returns the maximum time duration for which LP fees
  /// are proportionally burnt upon LP removals
  function vestingPeriod() external view returns (uint32);

  /// @notice Returns the tick distance for a specified fee.
  /// @dev Once added, cannot be updated or removed.
  /// @param swapFeeUnits Swap fee, in fee units.
  /// @return The tick distance. Returns 0 if fee has not been added.
  function feeAmountTickDistance(uint24 swapFeeUnits) external view returns (int24);

  /// @notice Returns the address which can update the fee configuration
  function configMaster() external view returns (address);

  /// @notice Returns the keccak256 hash of the Pool creation code
  /// This is used for pre-computation of pool addresses
  function poolInitHash() external view returns (bytes32);

  /// @notice Returns the pool oracle contract for twap
  function poolOracle() external view returns (address);

  /// @notice Fetches the recipient of government fees
  /// and current government fee charged in fee units
  function feeConfiguration() external view returns (address _feeTo, uint24 _governmentFeeUnits);

  /// @notice Returns the status of whitelisting feature of NFT managers
  /// If true, anyone can mint liquidity tokens
  /// Otherwise, only whitelisted NFT manager(s) are allowed to mint liquidity tokens
  function whitelistDisabled() external view returns (bool);

  //// @notice Returns all whitelisted NFT managers
  /// If the whitelisting feature is turned on,
  /// only whitelisted NFT manager(s) are allowed to mint liquidity tokens
  function getWhitelistedNFTManagers() external view returns (address[] memory);

  /// @notice Checks if sender is a whitelisted NFT manager
  /// If the whitelisting feature is turned on,
  /// only whitelisted NFT manager(s) are allowed to mint liquidity tokens
  /// @param sender address to be checked
  /// @return true if sender is a whistelisted NFT manager, false otherwise
  function isWhitelistedNFTManager(address sender) external view returns (bool);

  /// @notice Returns the pool address for a given pair of tokens and a swap fee
  /// @dev Token order does not matter
  /// @param tokenA Contract address of either token0 or token1
  /// @param tokenB Contract address of the other token
  /// @param swapFeeUnits Fee to be collected upon every swap in the pool, in fee units
  /// @return pool The pool address. Returns null address if it does not exist
  function getPool(
    address tokenA,
    address tokenB,
    uint24 swapFeeUnits
  ) external view returns (address pool);

  /// @notice Fetch parameters to be used for pool creation
  /// @dev Called by the pool constructor to fetch the parameters of the pool
  /// @return factory The factory address
  /// @return poolOracle The pool oracle for twap
  /// @return token0 First pool token by address sort order
  /// @return token1 Second pool token by address sort order
  /// @return swapFeeUnits Fee to be collected upon every swap in the pool, in fee units
  /// @return tickDistance Minimum number of ticks between initialized ticks
  function parameters()
    external
    view
    returns (
      address factory,
      address poolOracle,
      address token0,
      address token1,
      uint24 swapFeeUnits,
      int24 tickDistance
    );

  /// @notice Creates a pool for the given two tokens and fee
  /// @param tokenA One of the two tokens in the desired pool
  /// @param tokenB The other of the two tokens in the desired pool
  /// @param swapFeeUnits Desired swap fee for the pool, in fee units
  /// @dev Token order does not matter. tickDistance is determined from the fee.
  /// Call will revert under any of these conditions:
  ///     1) pool already exists
  ///     2) invalid swap fee
  ///     3) invalid token arguments
  /// @return pool The address of the newly created pool
  function createPool(
    address tokenA,
    address tokenB,
    uint24 swapFeeUnits
  ) external returns (address pool);

  /// @notice Enables a fee amount with the given tickDistance
  /// @dev Fee amounts may never be removed once enabled
  /// @param swapFeeUnits The fee amount to enable, in fee units
  /// @param tickDistance The distance between ticks to be enforced for all pools created with the given fee amount
  function enableSwapFee(uint24 swapFeeUnits, int24 tickDistance) external;

  /// @notice Updates the address which can update the fee configuration
  /// @dev Must be called by the current configMaster
  function updateConfigMaster(address) external;

  /// @notice Updates the vesting period
  /// @dev Must be called by the current configMaster
  function updateVestingPeriod(uint32) external;

  /// @notice Updates the address receiving government fees and fee quantity
  /// @dev Only configMaster is able to perform the update
  /// @param feeTo Address to receive government fees collected from pools
  /// @param governmentFeeUnits Fee amount, in fee units,
  /// to be collected out of the fee charged for a pool swap
  function updateFeeConfiguration(address feeTo, uint24 governmentFeeUnits) external;

  /// @notice Enables the whitelisting feature
  /// @dev Only configMaster is able to perform the update
  function enableWhitelist() external;

  /// @notice Disables the whitelisting feature
  /// @dev Only configMaster is able to perform the update
  function disableWhitelist() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';

interface IKyberSwapElasticLM {
  struct RewardData {
    address rewardToken;
    uint256 rewardUnclaimed;
  }

  struct LMPoolInfo {
    address poolAddress;
    uint32 startTime;
    uint32 endTime;
    uint256 totalSecondsClaimed; // scaled by (1 << 96)
    RewardData[] rewards;
    uint256 feeTarget;
    uint256 numStakes;
  }

  struct PositionInfo {
    address owner;
    uint256 liquidity;
  }

  struct StakeInfo {
    uint128 secondsPerLiquidityLast;
    uint256[] rewardLast;
    uint256[] rewardPending;
    uint256[] rewardHarvested;
    int256 feeFirst;
    uint256 liquidity;
  }

  // input data in harvestMultiplePools function
  struct HarvestData {
    uint256[] pIds;
  }

  // avoid stack too deep error
  struct RewardCalculationData {
    uint128 secondsPerLiquidityNow;
    int256 feeNow;
    uint256 vestingVolume;
    uint256 totalSecondsUnclaimed;
    uint256 secondsPerLiquidity;
    uint256 secondsClaim; // scaled by (1 << 96)
  }

  // nftId => Position info
  function positions(uint nftId) external view returns (PositionInfo memory);

  function admin() external view returns(address);

  /**
   * @dev Add new pool to LM
   * @param poolAddr pool address
   * @param startTime start time of liquidity mining
   * @param endTime end time of liquidity mining
   * @param rewardTokens reward token list for pool
   * @param rewardAmounts reward amount of list token
   * @param feeTarget fee target for pool
   *
   */
  function addPool(
    address poolAddr,
    uint32 startTime,
    uint32 endTime,
    address[] calldata rewardTokens,
    uint256[] calldata rewardAmounts,
    uint256 feeTarget
  ) external;

  /**
   * @dev Renew a pool to start another LM program
   * @param pId pool id to update
   * @param startTime start time of liquidity mining
   * @param endTime end time of liquidity mining
   * @param rewardAmounts reward amount of list token
   * @param feeTarget fee target for pool
   *
   */
  function renewPool(
    uint256 pId,
    uint32 startTime,
    uint32 endTime,
    uint256[] calldata rewardAmounts,
    uint256 feeTarget
  ) external;

  /**
   * @dev Deposit NFT
   * @param nftIds list nft id
   *
   */
  function deposit(uint256[] calldata nftIds) external;

  /**
   * @dev Deposit NFTs into the pool and join farms if applicable
   * @param pId pool id to join farm
   * @param nftIds List of NFT ids from BasePositionManager, should match with the pId
   *
   */
  function depositAndJoin(uint256 pId, uint256[] calldata nftIds) external;

  /**
   * @dev Withdraw NFT, must exit all pool before call.
   * @param nftIds list nft id
   *
   */
  function withdraw(uint256[] calldata nftIds) external;

  /**
   * @dev Join pools
   * @param pId pool id to join
   * @param nftIds nfts to join
   * @param liqs list liquidity value to join each nft
   *
   */
  function join(uint256 pId, uint256[] calldata nftIds, uint256[] calldata liqs) external;

  /**
   * @dev Exit from pools
   * @param pId pool ids to exit
   * @param nftIds list nfts id
   * @param liqs list liquidity value to exit from each nft
   *
   */
  function exit(uint256 pId, uint256[] calldata nftIds, uint256[] calldata liqs) external;

  /**
   * @dev Claim rewards for a list of pools for a list of nft positions
   * @param nftIds List of NFT ids to harvest
   * @param datas List of pool ids to harvest for each nftId, encoded into bytes
   */
  function harvestMultiplePools(uint256[] calldata nftIds, bytes[] calldata datas) external;

  /**
   * @dev remove liquidity from elastic for a list of nft position, also update on farm
   * @param nftId to remove
   * @param liquidity liquidity amount to remove from nft
   * @param amount0Min expected min amount of token0 should receive
   * @param amount1Min expected min amount of token1 should receive
   * @param deadline deadline of this tx
   * @param isReceiveNative should unwrap native or not
   * @param claimFeeAndRewards also claim LP Fee and farm rewards
   */
  function removeLiquidity(
    uint256 nftId,
    uint128 liquidity,
    uint256 amount0Min,
    uint256 amount1Min,
    uint256 deadline,
    bool isReceiveNative,
    bool[2] calldata claimFeeAndRewards
  ) external;

  /**
   * @dev Claim fee from elastic for a list of nft positions
   * @param nftIds List of NFT ids to claim
   * @param amount0Min expected min amount of token0 should receive
   * @param amount1Min expected min amount of token1 should receive
   * @param poolAddress address of Elastic pool of those nfts
   * @param isReceiveNative should unwrap native or not
   * @param deadline deadline of this tx
   */
  function claimFee(
    uint256[] calldata nftIds,
    uint256 amount0Min,
    uint256 amount1Min,
    address poolAddress,
    bool isReceiveNative,
    uint256 deadline
  ) external;

  /**
   * @dev Operator only. Call to withdraw all reward from list pools.
   * @param rewards list reward address erc20 token
   * @param amounts amount to withdraw
   *
   */
  function emergencyWithdrawForOwner(
    address[] calldata rewards,
    uint256[] calldata amounts
  ) external;

  /**
   * @dev Withdraw NFT, can call any time, reward will be reset. Must enable this func by operator
   * @param pIds list pool to withdraw
   *
   */
  function emergencyWithdraw(uint256[] calldata pIds) external;

  /**
   * @dev get list of pool that this nft joined
   * @param nftId to get
   */
  function getJoinedPools(uint256 nftId) external view returns (uint256[] memory poolIds);

  /**
   * @dev get list of pool that this nft joined, only in a specific range
   * @param nftId to get
   * @param fromIndex index from
   * @param toIndex index to
   */
  function getJoinedPoolsInRange(
    uint256 nftId,
    uint256 fromIndex,
    uint256 toIndex
  ) external view returns (uint256[] memory poolIds);

  /**
   * @dev get user's info (staked info) of a nft in a pool
   * @param nftId to get
   * @param pId to get
   */
  function getUserInfo(
    uint256 nftId,
    uint256 pId
  )
  external
  view
  returns (uint256 liquidity, uint256[] memory rewardPending, uint256[] memory rewardLast);

  /**
   * @dev get pool info
   * @param pId to get
   */
  function getPoolInfo(
    uint256 pId
  )
  external
  view
  returns (
    address poolAddress,
    uint32 startTime,
    uint32 endTime,
    uint256 totalSecondsClaimed,
    uint256 feeTarget,
    uint256 numStakes,
  //index reward => reward data
    address[] memory rewardTokens,
    uint256[] memory rewardUnclaimeds
  );

  /**
   * @dev get list of deposited nfts of an address
   * @param user address of user to get
   */
  function getDepositedNFTs(address user) external view returns (uint256[] memory listNFTs);

  function nft() external view returns (IERC721);

  function poolLength() external view returns (uint256);

  function getRewardCalculationData(
    uint256 nftId,
    uint256 pId
  ) external view returns (RewardCalculationData memory data);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IPoolActions} from './pool/IPoolActions.sol';
import {IPoolEvents} from './pool/IPoolEvents.sol';
import {IPoolStorage} from './pool/IPoolStorage.sol';

interface IPool is IPoolActions, IPoolEvents, IPoolStorage {}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

interface IRouterTokenHelper {
  /// @notice Unwraps the contract's WETH balance and sends it to recipient as ETH.
  /// @dev The minAmount parameter prevents malicious contracts from stealing WETH from users.
  /// @param minAmount The minimum amount of WETH to unwrap
  /// @param recipient The address receiving ETH
  function unwrapWeth(uint256 minAmount, address recipient) external payable;

  /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
  /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
  /// that use ether for the input amount
  function refundEth() external payable;

  /// @notice Transfers the full amount of a token held by this contract to recipient
  /// @dev The minAmount parameter prevents malicious contracts from stealing the token from users
  /// @param token The contract address of the token which will be transferred to `recipient`
  /// @param minAmount The minimum amount of token required for a transfer
  /// @param recipient The destination address of the token
  function transferAllTokens(
    address token,
    uint256 minAmount,
    address recipient
  ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ITicksFeesReader {
  function getTotalFeesOwedToPosition(
    address posManager,
    address pool,
    uint256 tokenId
  ) external view returns (uint256 token0Owed, uint256 token1Owed);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IPoolOracle {
  /// @notice Owner withdrew funds in the pool oracle in case some funds are stuck there
  event OwnerWithdrew(
    address indexed owner,
    address indexed token,
    uint256 indexed amount
  );

  /// @notice Emitted by the Pool Oracle for increases to the number of observations that can be stored
  /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
  /// just before a mint/swap/burn.
  /// @param pool The pool address to update
  /// @param observationCardinalityNextOld The previous value of the next observation cardinality
  /// @param observationCardinalityNextNew The updated value of the next observation cardinality
  event IncreaseObservationCardinalityNext(
    address pool,
    uint16 observationCardinalityNextOld,
    uint16 observationCardinalityNextNew
  );

  /// @notice Initalize observation data for the caller.
  function initializeOracle(uint32 time)
    external
    returns (uint16 cardinality, uint16 cardinalityNext);

  /// @notice Write a new oracle entry into the array
  ///   and update the observation index and cardinality
  /// Read the Oralce.write function for more details
  function writeNewEntry(
    uint16 index,
    uint32 blockTimestamp,
    int24 tick,
    uint128 liquidity,
    uint16 cardinality,
    uint16 cardinalityNext
  )
    external
    returns (uint16 indexUpdated, uint16 cardinalityUpdated);

  /// @notice Write a new oracle entry into the array, take the latest observaion data as inputs
  ///   and update the observation index and cardinality
  /// Read the Oralce.write function for more details
  function write(
    uint32 blockTimestamp,
    int24 tick,
    uint128 liquidity
  )
    external
    returns (uint16 indexUpdated, uint16 cardinalityUpdated);

  /// @notice Increase the maximum number of price observations that this pool will store
  /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
  /// the input observationCardinalityNext.
  /// @param pool The pool address to be updated
  /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
  function increaseObservationCardinalityNext(
    address pool,
    uint16 observationCardinalityNext
  )
    external;

  /// @notice Returns the accumulator values as of each time seconds ago from the latest block time in the array of `secondsAgos`
  /// @dev Reverts if `secondsAgos` > oldest observation
  /// @dev It fetches the latest current tick data from the pool
  /// Read the Oracle.observe function for more details
  function observeFromPool(
    address pool,
    uint32[] memory secondsAgos
  )
    external view
    returns (int56[] memory tickCumulatives);

  /// @notice Returns the accumulator values as the time seconds ago from the latest block time of secondsAgo
  /// @dev Reverts if `secondsAgo` > oldest observation
  /// @dev It fetches the latest current tick data from the pool
  /// Read the Oracle.observeSingle function for more details
  function observeSingleFromPool(
    address pool,
    uint32 secondsAgo
  )
    external view
    returns (int56 tickCumulative);

  /// @notice Return the latest pool observation data given the pool address
  function getPoolObservation(address pool)
    external view
    returns (bool initialized, uint16 index, uint16 cardinality, uint16 cardinalityNext);

  /// @notice Returns data about a specific observation index
  /// @param pool The pool address of the observations array to fetch
  /// @param index The element of the observations array to fetch
  /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
  /// ago, rather than at a specific index in the array.
  /// @return blockTimestamp The timestamp of the observation,
  /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
  /// Returns initialized whether the observation has been initialized and the values are safe to use
  function getObservationAt(address pool, uint256 index)
    external view
    returns (
      uint32 blockTimestamp,
      int56 tickCumulative,
      bool initialized
    );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IPoolActions {
  /// @notice Sets the initial price for the pool and seeds reinvestment liquidity
  /// @dev Assumes the caller has sent the necessary token amounts
  /// required for initializing reinvestment liquidity prior to calling this function
  /// @param initialSqrtP the initial sqrt price of the pool
  /// @param qty0 token0 quantity sent to and locked permanently in the pool
  /// @param qty1 token1 quantity sent to and locked permanently in the pool
  function unlockPool(uint160 initialSqrtP) external returns (uint256 qty0, uint256 qty1);

  /// @notice Adds liquidity for the specified recipient/tickLower/tickUpper position
  /// @dev Any token0 or token1 owed for the liquidity provision have to be paid for when
  /// the IMintCallback#mintCallback is called to this method's caller
  /// The quantity of token0/token1 to be sent depends on
  /// tickLower, tickUpper, the amount of liquidity, and the current price of the pool.
  /// Also sends reinvestment tokens (fees) to the recipient for any fees collected
  /// while the position is in range
  /// Reinvestment tokens have to be burnt via #burnRTokens in exchange for token0 and token1
  /// @param recipient Address for which the added liquidity is credited to
  /// @param tickLower Recipient position's lower tick
  /// @param tickUpper Recipient position's upper tick
  /// @param ticksPrevious The nearest tick that is initialized and <= the lower & upper ticks
  /// @param qty Liquidity quantity to mint
  /// @param data Data (if any) to be passed through to the callback
  /// @return qty0 token0 quantity sent to the pool in exchange for the minted liquidity
  /// @return qty1 token1 quantity sent to the pool in exchange for the minted liquidity
  /// @return feeGrowthInside position's updated feeGrowthInside value
  function mint(
    address recipient,
    int24 tickLower,
    int24 tickUpper,
    int24[2] calldata ticksPrevious,
    uint128 qty,
    bytes calldata data
  )
    external
    returns (
      uint256 qty0,
      uint256 qty1,
      uint256 feeGrowthInside
    );

  /// @notice Remove liquidity from the caller
  /// Also sends reinvestment tokens (fees) to the caller for any fees collected
  /// while the position is in range
  /// Reinvestment tokens have to be burnt via #burnRTokens in exchange for token0 and token1
  /// @param tickLower Position's lower tick for which to burn liquidity
  /// @param tickUpper Position's upper tick for which to burn liquidity
  /// @param qty Liquidity quantity to burn
  /// @return qty0 token0 quantity sent to the caller
  /// @return qty1 token1 quantity sent to the caller
  /// @return feeGrowthInside position's updated feeGrowthInside value
  function burn(
    int24 tickLower,
    int24 tickUpper,
    uint128 qty
  )
    external
    returns (
      uint256 qty0,
      uint256 qty1,
      uint256 feeGrowthInside
    );

  /// @notice Burns reinvestment tokens in exchange to receive the fees collected in token0 and token1
  /// @param qty Reinvestment token quantity to burn
  /// @param isLogicalBurn true if burning rTokens without returning any token0/token1
  ///         otherwise should transfer token0/token1 to sender
  /// @return qty0 token0 quantity sent to the caller for burnt reinvestment tokens
  /// @return qty1 token1 quantity sent to the caller for burnt reinvestment tokens
  function burnRTokens(uint256 qty, bool isLogicalBurn)
    external
    returns (uint256 qty0, uint256 qty1);

  /// @notice Swap token0 -> token1, or vice versa
  /// @dev This method's caller receives a callback in the form of ISwapCallback#swapCallback
  /// @dev swaps will execute up to limitSqrtP or swapQty is fully used
  /// @param recipient The address to receive the swap output
  /// @param swapQty The swap quantity, which implicitly configures the swap as exact input (>0), or exact output (<0)
  /// @param isToken0 Whether the swapQty is specified in token0 (true) or token1 (false)
  /// @param limitSqrtP the limit of sqrt price after swapping
  /// could be MAX_SQRT_RATIO-1 when swapping 1 -> 0 and MIN_SQRT_RATIO+1 when swapping 0 -> 1 for no limit swap
  /// @param data Any data to be passed through to the callback
  /// @return qty0 Exact token0 qty sent to recipient if < 0. Minimally received quantity if > 0.
  /// @return qty1 Exact token1 qty sent to recipient if < 0. Minimally received quantity if > 0.
  function swap(
    address recipient,
    int256 swapQty,
    bool isToken0,
    uint160 limitSqrtP,
    bytes calldata data
  ) external returns (int256 qty0, int256 qty1);

  /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
  /// @dev The caller of this method receives a callback in the form of IFlashCallback#flashCallback
  /// @dev Fees collected are sent to the feeTo address if it is set in Factory
  /// @param recipient The address which will receive the token0 and token1 quantities
  /// @param qty0 token0 quantity to be loaned to the recipient
  /// @param qty1 token1 quantity to be loaned to the recipient
  /// @param data Any data to be passed through to the callback
  function flash(
    address recipient,
    uint256 qty0,
    uint256 qty1,
    bytes calldata data
  ) external;


  /// @notice sync fee of position
  /// @param tickLower Position's lower tick
  /// @param tickUpper Position's upper tick
  function tweakPosZeroLiq(int24 tickLower, int24 tickUpper)
    external returns(uint256 feeGrowthInsideLast);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IPoolEvents {
  /// @notice Emitted only once per pool when #initialize is first called
  /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
  /// @param sqrtP The initial price of the pool
  /// @param tick The initial tick of the pool
  event Initialize(uint160 sqrtP, int24 tick);

  /// @notice Emitted when liquidity is minted for a given position
  /// @dev transfers reinvestment tokens for any collected fees earned by the position
  /// @param sender address that minted the liquidity
  /// @param owner address of owner of the position
  /// @param tickLower position's lower tick
  /// @param tickUpper position's upper tick
  /// @param qty liquidity minted to the position range
  /// @param qty0 token0 quantity needed to mint the liquidity
  /// @param qty1 token1 quantity needed to mint the liquidity
  event Mint(
    address sender,
    address indexed owner,
    int24 indexed tickLower,
    int24 indexed tickUpper,
    uint128 qty,
    uint256 qty0,
    uint256 qty1
  );

  /// @notice Emitted when a position's liquidity is removed
  /// @dev transfers reinvestment tokens for any collected fees earned by the position
  /// @param owner address of owner of the position
  /// @param tickLower position's lower tick
  /// @param tickUpper position's upper tick
  /// @param qty liquidity removed
  /// @param qty0 token0 quantity withdrawn from removal of liquidity
  /// @param qty1 token1 quantity withdrawn from removal of liquidity
  event Burn(
    address indexed owner,
    int24 indexed tickLower,
    int24 indexed tickUpper,
    uint128 qty,
    uint256 qty0,
    uint256 qty1
  );

  /// @notice Emitted when reinvestment tokens are burnt
  /// @param owner address which burnt the reinvestment tokens
  /// @param qty reinvestment token quantity burnt
  /// @param qty0 token0 quantity sent to owner for burning reinvestment tokens
  /// @param qty1 token1 quantity sent to owner for burning reinvestment tokens
  event BurnRTokens(address indexed owner, uint256 qty, uint256 qty0, uint256 qty1);

  /// @notice Emitted for swaps by the pool between token0 and token1
  /// @param sender Address that initiated the swap call, and that received the callback
  /// @param recipient Address that received the swap output
  /// @param deltaQty0 Change in pool's token0 balance
  /// @param deltaQty1 Change in pool's token1 balance
  /// @param sqrtP Pool's sqrt price after the swap
  /// @param liquidity Pool's liquidity after the swap
  /// @param currentTick Log base 1.0001 of pool's price after the swap
  event Swap(
    address indexed sender,
    address indexed recipient,
    int256 deltaQty0,
    int256 deltaQty1,
    uint160 sqrtP,
    uint128 liquidity,
    int24 currentTick
  );

  /// @notice Emitted by the pool for any flash loans of token0/token1
  /// @param sender The address that initiated the flash loan, and that received the callback
  /// @param recipient The address that received the flash loan quantities
  /// @param qty0 token0 quantity loaned to the recipient
  /// @param qty1 token1 quantity loaned to the recipient
  /// @param paid0 token0 quantity paid for the flash, which can exceed qty0 + fee
  /// @param paid1 token1 quantity paid for the flash, which can exceed qty0 + fee
  event Flash(
    address indexed sender,
    address indexed recipient,
    uint256 qty0,
    uint256 qty1,
    uint256 paid0,
    uint256 paid1
  );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {IFactory} from '../IFactory.sol';
import {IPoolOracle} from '../oracle/IPoolOracle.sol';

interface IPoolStorage {
  /// @notice The contract that deployed the pool, which must adhere to the IFactory interface
  /// @return The contract address
  function factory() external view returns (IFactory);

  /// @notice The oracle contract that stores necessary data for price oracle
  /// @return The contract address
  function poolOracle() external view returns (IPoolOracle);

  /// @notice The first of the two tokens of the pool, sorted by address
  /// @return The token contract address
  function token0() external view returns (IERC20);

  /// @notice The second of the two tokens of the pool, sorted by address
  /// @return The token contract address
  function token1() external view returns (IERC20);

  /// @notice The fee to be charged for a swap in basis points
  /// @return The swap fee in basis points
  function swapFeeUnits() external view returns (uint24);

  /// @notice The pool tick distance
  /// @dev Ticks can only be initialized and used at multiples of this value
  /// It remains an int24 to avoid casting even though it is >= 1.
  /// e.g: a tickDistance of 5 means ticks can be initialized every 5th tick, i.e., ..., -10, -5, 0, 5, 10, ...
  /// @return The tick distance
  function tickDistance() external view returns (int24);

  /// @notice Maximum gross liquidity that an initialized tick can have
  /// @dev This is to prevent overflow the pool's active base liquidity (uint128)
  /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
  /// @return The max amount of liquidity per tick
  function maxTickLiquidity() external view returns (uint128);

  /// @notice Look up information about a specific tick in the pool
  /// @param tick The tick to look up
  /// @return liquidityGross total liquidity amount from positions that uses this tick as a lower or upper tick
  /// liquidityNet how much liquidity changes when the pool tick crosses above the tick
  /// feeGrowthOutside the fee growth on the other side of the tick relative to the current tick
  /// secondsPerLiquidityOutside the seconds per unit of liquidity  spent on the other side of the tick relative to the current tick
  function ticks(int24 tick)
    external
    view
    returns (
      uint128 liquidityGross,
      int128 liquidityNet,
      uint256 feeGrowthOutside,
      uint128 secondsPerLiquidityOutside
    );

  /// @notice Returns the previous and next initialized ticks of a specific tick
  /// @dev If specified tick is uninitialized, the returned values are zero.
  /// @param tick The tick to look up
  function initializedTicks(int24 tick) external view returns (int24 previous, int24 next);

  /// @notice Returns the information about a position by the position's key
  /// @return liquidity the liquidity quantity of the position
  /// @return feeGrowthInsideLast fee growth inside the tick range as of the last mint / burn action performed
  function getPositions(
    address owner,
    int24 tickLower,
    int24 tickUpper
  ) external view returns (uint128 liquidity, uint256 feeGrowthInsideLast);

  /// @notice Fetches the pool's prices, ticks and lock status
  /// @return sqrtP sqrt of current price: sqrt(token1/token0)
  /// @return currentTick pool's current tick
  /// @return nearestCurrentTick pool's nearest initialized tick that is <= currentTick
  /// @return locked true if pool is locked, false otherwise
  function getPoolState()
    external
    view
    returns (
      uint160 sqrtP,
      int24 currentTick,
      int24 nearestCurrentTick,
      bool locked
    );

  /// @notice Fetches the pool's liquidity values
  /// @return baseL pool's base liquidity without reinvest liqudity
  /// @return reinvestL the liquidity is reinvested into the pool
  /// @return reinvestLLast last cached value of reinvestL, used for calculating reinvestment token qty
  function getLiquidityState()
    external
    view
    returns (
      uint128 baseL,
      uint128 reinvestL,
      uint128 reinvestLLast
    );

  /// @return feeGrowthGlobal All-time fee growth per unit of liquidity of the pool
  function getFeeGrowthGlobal() external view returns (uint256);

  /// @return secondsPerLiquidityGlobal All-time seconds per unit of liquidity of the pool
  /// @return lastUpdateTime The timestamp in which secondsPerLiquidityGlobal was last updated
  function getSecondsPerLiquidityData()
    external
    view
    returns (uint128 secondsPerLiquidityGlobal, uint32 lastUpdateTime);

  /// @notice Calculates and returns the active time per unit of liquidity until current block.timestamp
  /// @param tickLower The lower tick (of a position)
  /// @param tickUpper The upper tick (of a position)
  /// @return secondsPerLiquidityInside active time (multiplied by 2^96)
  /// between the 2 ticks, per unit of liquidity.
  function getSecondsPerLiquidityInside(int24 tickLower, int24 tickUpper)
    external
    view
    returns (uint128 secondsPerLiquidityInside);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IFarmingStrategy {
  function canFarm() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IRebalancingStrategy {
    function needRebalance() external view returns (bool);
    function rebalance() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @notice List of all errors generated by the application
///         Each error should have unique code TS-XXX and descriptive comment
library AppErrors {
  /// @notice Provided address should be not zero
  string public constant ZERO_ADDRESS = "TS-1 zero address";

  /// @notice A pair of the tokens cannot be found in the factory of uniswap pairs
  string public constant UNISWAP_PAIR_NOT_FOUND = "TS-2 pair not found";

  /// @notice Lengths not matched
  string public constant WRONG_LENGTHS = "TS-4 wrong lengths";

  /// @notice Unexpected zero balance
  string public constant ZERO_BALANCE = "TS-5 zero balance";

  string public constant ITEM_NOT_FOUND = "TS-6 not found";

  string public constant NOT_ENOUGH_BALANCE = "TS-7 not enough balance";

  /// @notice Price oracle returns zero price
  string public constant ZERO_PRICE = "TS-8 zero price";

  string public constant WRONG_VALUE = "TS-9 wrong value";

  /// @notice TetuConvertor wasn't able to make borrow, i.e. borrow-strategy wasn't found
  string public constant ZERO_AMOUNT_BORROWED = "TS-10 zero borrowed amount";

  string public constant WITHDRAW_TOO_MUCH = "TS-11 try to withdraw too much";

  string public constant UNKNOWN_ENTRY_KIND = "TS-12 unknown entry kind";

  string public constant ONLY_TETU_CONVERTER = "TS-13 only TetuConverter";

  string public constant WRONG_ASSET = "TS-14 wrong asset";

  string public constant NO_LIQUIDATION_ROUTE = "TS-15 No liquidation route";

  string public constant PRICE_IMPACT = "TS-16 price impact";

  /// @notice tetuConverter_.repay makes swap internally. It's not efficient and not allowed
  string public constant REPAY_MAKES_SWAP = "TS-17 can not convert back";

  string public constant NO_INVESTMENTS = "TS-18 no investments";

  string public constant INCORRECT_LENGTHS = "TS-19 lengths";

  /// @notice We expect increasing of the balance, but it was decreased
  string public constant BALANCE_DECREASE = "TS-20 balance decrease";

  /// @notice Prices changed and invested assets amount was increased on S, value of S is too high
  string public constant EARNED_AMOUNT_TOO_HIGH = "TS-21 earned too high";

  string public constant GOVERNANCE_ONLY = "TS-22 governance only";
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@tetu_io/tetu-contracts-v2/contracts/interfaces/IERC20.sol";
import "@tetu_io/tetu-contracts-v2/contracts/interfaces/IERC20Metadata.sol";
import "@tetu_io/tetu-contracts-v2/contracts/openzeppelin/SafeERC20.sol";

/// @notice Common internal utils
library AppLib {
  using SafeERC20 for IERC20;

  /// @notice Unchecked increment for for-cycles
  function uncheckedInc(uint i) internal pure returns (uint) {
    unchecked {
      return i + 1;
    }
  }

  /// @notice Make infinite approve of {token} to {spender} if the approved amount is less than {amount}
  /// @dev Should NOT be used for third-party pools
  function approveIfNeeded(address token, uint amount, address spender) internal {
    if (IERC20(token).allowance(address(this), spender) < amount) {
      IERC20(token).safeApprove(spender, 0);
      // infinite approve, 2*255 is more gas efficient then type(uint).max
      IERC20(token).safeApprove(spender, 2 ** 255);
    }
  }

  function balance(address token) internal view returns (uint) {
    return IERC20(token).balanceOf(address(this));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library AppPlatforms {
  string public constant UNIV3 = "UniswapV3";
  string public constant BALANCER = "Balancer";
  string public constant ALGEBRA = "Algebra";
  string public constant KYBER = "Kyber";
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @notice Utils and constants related to entryKind param of ITetuConverter.findBorrowStrategy
library ConverterEntryKinds {
  /// @notice Amount of collateral is fixed. Amount of borrow should be max possible.
  uint constant public ENTRY_KIND_EXACT_COLLATERAL_IN_FOR_MAX_BORROW_OUT_0 = 0;

  /// @notice Split provided source amount S on two parts: C1 and C2 (C1 + C2 = S)
  ///         C2 should be used as collateral to make a borrow B.
  ///         Results amounts of C1 and B (both in terms of USD) must be in the given proportion
  uint constant public ENTRY_KIND_EXACT_PROPORTION_1 = 1;

  /// @notice Borrow given amount using min possible collateral
  uint constant public ENTRY_KIND_EXACT_BORROW_OUT_FOR_MIN_COLLATERAL_IN_2 = 2;

  /// @notice Decode entryData, extract first uint - entry kind
  ///         Valid values of entry kinds are given by ENTRY_KIND_XXX constants above
  function getEntryKind(bytes memory entryData_) internal pure returns (uint) {
    if (entryData_.length == 0) {
      return ENTRY_KIND_EXACT_COLLATERAL_IN_FOR_MAX_BORROW_OUT_0;
    }
    return abi.decode(entryData_, (uint));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./AppErrors.sol";

/// @title Library for clearing / joining token addresses & amounts arrays
/// @author bogdoslav
library TokenAmountsLib {
  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string internal constant TOKEN_AMOUNTS_LIB_VERSION = "1.0.1";

  function uncheckedInc(uint i) internal pure returns (uint) {
    unchecked {
      return i + 1;
    }
  }

  function filterZeroAmounts(
    address[] memory tokens,
    uint[] memory amounts
  ) internal pure returns (
    address[] memory t,
    uint[] memory a
  ) {
    require(tokens.length == amounts.length, AppErrors.INCORRECT_LENGTHS);
    uint len2 = 0;
    uint len = tokens.length;
    for (uint i = 0; i < len; i++) {
      if (amounts[i] != 0) len2++;
    }

    t = new address[](len2);
    a = new uint[](len2);

    uint j = 0;
    for (uint i = 0; i < len; i++) {
      uint amount = amounts[i];
      if (amount != 0) {
        t[j] = tokens[i];
        a[j] = amount;
        j++;
      }
    }
  }

  /// @notice unites three arrays to single array without duplicates, amounts are sum, zero amounts are allowed
  function combineArrays(
    address[] memory tokens0,
    uint[] memory amounts0,
    address[] memory tokens1,
    uint[] memory amounts1,
    address[] memory tokens2,
    uint[] memory amounts2
  ) internal pure returns (
    address[] memory allTokens,
    uint[] memory allAmounts
  ) {
    uint[] memory lens = new uint[](3);
    lens[0] = tokens0.length;
    lens[1] = tokens1.length;
    lens[2] = tokens2.length;

    require(
      lens[0] == amounts0.length && lens[1] == amounts1.length && lens[2] == amounts2.length,
      AppErrors.INCORRECT_LENGTHS
    );

    uint maxLength = lens[0] + lens[1] + lens[2];
    address[] memory tokensOut = new address[](maxLength);
    uint[] memory amountsOut = new uint[](maxLength);
    uint unitedLength;

    for (uint step; step < 3; ++step) {
      uint[] memory amounts = step == 0
        ? amounts0
        : (step == 1
          ? amounts1
          : amounts2);
      address[] memory tokens = step == 0
        ? tokens0
        : (step == 1
          ? tokens1
          : tokens2);
      for (uint i1 = 0; i1 < lens[step]; i1++) {
        uint amount1 = amounts[i1];
        address token1 = tokens[i1];
        bool united = false;

        for (uint i = 0; i < unitedLength; i++) {
          if (token1 == tokensOut[i]) {
            amountsOut[i] += amount1;
            united = true;
            break;
          }
        }

        if (!united) {
          tokensOut[unitedLength] = token1;
          amountsOut[unitedLength] = amount1;
          unitedLength++;
        }
      }
    }

    // copy united tokens to result array
    allTokens = new address[](unitedLength);
    allAmounts = new uint[](unitedLength);
    for (uint i; i < unitedLength; i++) {
      allTokens[i] = tokensOut[i];
      allAmounts[i] = amountsOut[i];
    }

  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@tetu_io/tetu-contracts-v2/contracts/strategy/StrategyBaseV2.sol";
import "@tetu_io/tetu-converter/contracts/interfaces/ITetuConverterCallback.sol";
import "./ConverterStrategyBaseLib.sol";
import "./ConverterStrategyBaseLib2.sol";
import "./DepositorBase.sol";

/////////////////////////////////////////////////////////////////////
///                        TERMS
///  Main asset == underlying: the asset deposited to the vault by users
///  Secondary assets: all assets deposited to the internal pool except the main asset
/////////////////////////////////////////////////////////////////////

/// @title Abstract contract for base Converter strategy functionality
/// @notice All depositor assets must be correlated (ie USDC/USDT/DAI)
/// @author bogdoslav, dvpublic
abstract contract ConverterStrategyBase is ITetuConverterCallback, DepositorBase, StrategyBaseV2 {
  using SafeERC20 for IERC20;

  /////////////////////////////////////////////////////////////////////
  //region DATA TYPES
  /////////////////////////////////////////////////////////////////////

  struct WithdrawUniversalLocal {
    bool all;
    uint[] reservesBeforeWithdraw;
    uint totalSupplyBeforeWithdraw;
    uint depositorLiquidity;
    uint liquidityAmountToWithdraw;
    uint assetPrice;
    uint[] amountsToConvert;
    uint expectedTotalMainAssetAmount;
    uint[] expectedMainAssetAmounts;
    uint investedAssetsAfterWithdraw;
    uint balanceAfterWithdraw;
    address[] tokens;
    address asset;
    uint indexAsset;
    uint balanceBefore;
    uint[] withdrawnAmounts;
    ITetuConverter converter;
  }
  //endregion DATA TYPES

  /////////////////////////////////////////////////////////////////////
  //region CONSTANTS
  /////////////////////////////////////////////////////////////////////

  /// @dev Version of this contract. Adjust manually on each code modification.
  string public constant CONVERTER_STRATEGY_BASE_VERSION = "1.2.0";

  /// @notice 1% gap to cover possible liquidation inefficiency
  /// @dev We assume that: conversion-result-calculated-by-prices - liquidation-result <= the-gap
  uint internal constant GAP_CONVERSION = 1_000;
  uint internal constant DENOMINATOR = 100_000;
  //endregion CONSTANTS

  /////////////////////////////////////////////////////////////////////
  //region VARIABLES
  //                Keep names and ordering!
  // Add only in the bottom and don't forget to decrease gap variable
  /////////////////////////////////////////////////////////////////////

  /// @dev Amount of underlying assets invested to the pool.
  uint internal _investedAssets;

  /// @dev Linked Tetu Converter
  ITetuConverter public converter;

  /// @notice Minimum token amounts that can be liquidated
  mapping(address => uint) public liquidationThresholds;

  /// @notice Percent of asset amount that can be not invested, it's allowed to just keep it on balance
  ///         decimals = {DENOMINATOR}
  /// @dev We need this threshold to avoid numerous conversions of small amounts
  uint public reinvestThresholdPercent;

  /// @notice Ratio to split performance fee on toPerf + toInsurance, [0..100_000]
  ///         100_000 - send full amount toPerf, 0 - send full amount toInsurance.
  uint public performanceFeeRatio;
  //endregion VARIABLES

  /////////////////////////////////////////////////////////////////////
  //region Events
  /////////////////////////////////////////////////////////////////////
  event OnDepositorEnter(uint[] amounts, uint[] consumedAmounts);
  event OnDepositorExit(uint liquidityAmount, uint[] withdrawnAmounts);
  event OnDepositorEmergencyExit(uint[] withdrawnAmounts);
  event OnHardWorkEarnedLost(
    uint investedAssetsNewPrices,
    uint earnedByPrices,
    uint earnedHandleRewards,
    uint lostHandleRewards,
    uint earnedDeposit,
    uint lostDeposit
  );

  /// @notice Recycle was made
  /// @param rewardTokens Full list of reward tokens received from tetuConverter and depositor
  /// @param amountsToForward Amounts to be sent to forwarder
  event Recycle(
    address[] rewardTokens,
    uint[] amountsToForward,
    uint toPerf,
    uint toInsurance
  );
  //endregion Events

  /////////////////////////////////////////////////////////////////////
  //region Initialization and configuration
  /////////////////////////////////////////////////////////////////////

  /// @notice Initialize contract after setup it as proxy implementation
  function __ConverterStrategyBase_init(
    address controller_,
    address splitter_,
    address converter_
  ) internal onlyInitializing {
    __StrategyBase_init(controller_, splitter_);
    converter = ITetuConverter(converter_);

    // 1% by default
    reinvestThresholdPercent = DENOMINATOR / 100;
    emit ConverterStrategyBaseLib2.ReinvestThresholdPercentChanged(DENOMINATOR / 100);
  }

  function setLiquidationThreshold(address token, uint amount) external {
    ConverterStrategyBaseLib2.checkLiquidationThresholdChanged(controller(), token, amount);
    liquidationThresholds[token] = amount;
  }

  /// @param percent_ New value of the percent, decimals = {REINVEST_THRESHOLD_PERCENT_DENOMINATOR}
  function setReinvestThresholdPercent(uint percent_) external {
    ConverterStrategyBaseLib2.checkReinvestThresholdPercentChanged(controller(), percent_);
    reinvestThresholdPercent = percent_;
  }

  /// @notice [0..100_000], 100_000 - send full amount toPerf, 0 - send full amount toInsurance.
  function setPerformanceFeeRatio(uint ratio_) external {
    ConverterStrategyBaseLib2.checkPerformanceFeeRatioChanged(controller(), ratio_);
    performanceFeeRatio = ratio_;
  }
  //endregion Initialization and configuration

  /////////////////////////////////////////////////////////////////////
  //region Deposit to the pool
  /////////////////////////////////////////////////////////////////////

  /// @notice Amount of underlying assets converted to pool assets and invested to the pool.
  function investedAssets() override public view virtual returns (uint) {
    return _investedAssets;
  }

  /// @notice Deposit given amount to the pool.
  function _depositToPool(uint amount_, bool updateTotalAssetsBeforeInvest_) override internal virtual returns (
    uint strategyLoss
  ){
    (uint updatedInvestedAssets, uint earnedByPrices) = _fixPriceChanges(updateTotalAssetsBeforeInvest_);
    (strategyLoss,) = _depositToPoolUniversal(amount_, earnedByPrices, updatedInvestedAssets);
  }

  /// @notice Deposit {amount_} to the pool, send {earnedByPrices_} to insurance.
  ///         totalAsset will decrease on earnedByPrices_ and sharePrice won't change after all recalculations.
  /// @dev We need to deposit {amount_} and withdraw {earnedByPrices_} here
  /// @param amount_ Amount of underlying to be deposited
  /// @param earnedByPrices_ Profit received because of price changing
  /// @param investedAssets_ Invested assets value calculated with updated prices
  /// @return strategyLoss Loss happened on the depositing. It doesn't include any price-changing losses
  /// @return amountSentToInsurance Price-changing-profit that was sent to the insurance
  function _depositToPoolUniversal(uint amount_, uint earnedByPrices_, uint investedAssets_) internal virtual returns (
    uint strategyLoss,
    uint amountSentToInsurance
  ){
    address _asset = asset;

    uint amountToDeposit = amount_ > earnedByPrices_
      ? amount_ - earnedByPrices_
      : 0;

    // skip deposit for small amounts
    if (amountToDeposit > reinvestThresholdPercent * investedAssets_ / DENOMINATOR) {
      if (earnedByPrices_ != 0) {
        amountSentToInsurance = ConverterStrategyBaseLib2.sendToInsurance(
          _asset,
          earnedByPrices_,
          splitter,
          investedAssets_ + AppLib.balance(_asset)
        );
      }
      uint balanceBefore = AppLib.balance(_asset);

      (address[] memory tokens, uint indexAsset) = _getTokens(asset);

      // prepare array of amounts ready to deposit, borrow missed amounts
      uint[] memory amounts = _beforeDeposit(converter, amountToDeposit, tokens, indexAsset);

      // make deposit, actually consumed amounts can be different from the desired amounts
      (uint[] memory consumedAmounts,) = _depositorEnter(amounts);
      emit OnDepositorEnter(amounts, consumedAmounts);

      // update _investedAssets with new deposited amount
      uint updatedInvestedAssetsAfterDeposit = _updateInvestedAssets();
      // after deposit some asset can exist
      uint balanceAfter = AppLib.balance(_asset);
      // we need to compensate difference if during deposit we lost some assets
      if ((updatedInvestedAssetsAfterDeposit + balanceAfter) < (investedAssets_ + balanceBefore)) {
        strategyLoss = (investedAssets_ + balanceBefore) - (updatedInvestedAssetsAfterDeposit + balanceAfter);
      }
    } else if (earnedByPrices_ != 0) {
      // we just skip check of expectedWithdrewUSD here
      uint balance = AppLib.balance(_asset);
      if (balance < earnedByPrices_) {
        (/* expectedWithdrewUSD */,, strategyLoss, amountSentToInsurance) = _withdrawUniversal(0, earnedByPrices_, investedAssets_);
      } else {
        amountSentToInsurance = ConverterStrategyBaseLib2.sendToInsurance(
          _asset,
          earnedByPrices_,
          splitter,
          investedAssets_ + balance
        );
      }
    }

    return (strategyLoss, amountSentToInsurance);
  }
  //endregion Deposit to the pool

  /////////////////////////////////////////////////////////////////////
  //region Convert amounts before deposit
  /////////////////////////////////////////////////////////////////////

  /// @notice Prepare {tokenAmounts} to be passed to depositorEnter
  /// @dev Override this function to customize entry kind
  /// @param amount_ The amount of main asset that should be invested
  /// @param tokens_ Results of _depositorPoolAssets() call (list of depositor's asset in proper order)
  /// @param indexAsset_ Index of main {asset} in {tokens}
  /// @return tokenAmounts Amounts of depositor's assets ready to invest (this array can be passed to depositorEnter)
  function _beforeDeposit(
    ITetuConverter tetuConverter_,
    uint amount_,
    address[] memory tokens_,
    uint indexAsset_
  ) internal virtual returns (
    uint[] memory tokenAmounts
  ) {
    // calculate required collaterals for each token and temporary save them to tokenAmounts
    (uint[] memory weights, uint totalWeight) = _depositorPoolWeights();

    // temporary save collateral to tokensAmounts
    tokenAmounts = ConverterStrategyBaseLib2.getCollaterals(
      amount_,
      tokens_,
      weights,
      totalWeight,
      indexAsset_,
      IPriceOracle(IConverterController(tetuConverter_.controller()).priceOracle())
    );

    // make borrow and save amounts of tokens available for deposit to tokenAmounts, zero result amounts are possible
    tokenAmounts = ConverterStrategyBaseLib.getTokenAmounts(
      tetuConverter_,
      tokens_,
      indexAsset_,
      tokenAmounts,
      liquidationThresholds[tokens_[indexAsset_]]
    );
  }
  //endregion Convert amounts before deposit

  /////////////////////////////////////////////////////////////////////
  //region Withdraw from the pool
  /////////////////////////////////////////////////////////////////////

  function _beforeWithdraw(uint /*amount*/) internal virtual {
    // do nothing
  }

  /// @notice Withdraw given amount from the pool.
  /// @param amount Amount to be withdrawn in terms of the asset in addition to the exist balance.
  /// @return expectedWithdrewUSD The value that we should receive after withdrawing (in USD, decimals of the {asset})
  /// @return assetPrice Price of the {asset} from the price oracle
  /// @return strategyLoss Loss should be covered from Insurance
  function _withdrawFromPool(uint amount) override internal virtual returns (
    uint expectedWithdrewUSD,
    uint assetPrice,
    uint strategyLoss
  ) {
    // calculate profit/loss because of price changes, try to compensate the loss from the insurance
    (uint investedAssetsNewPrices, uint earnedByPrices) = _fixPriceChanges(true);
    (expectedWithdrewUSD, assetPrice, strategyLoss,) = _withdrawUniversal(amount, earnedByPrices, investedAssetsNewPrices);
  }

  /// @notice Withdraw all from the pool.
  /// @return expectedWithdrewUSD The value that we should receive after withdrawing
  /// @return assetPrice Price of the {asset} taken from the price oracle
  /// @return strategyLoss Loss should be covered from Insurance
  function _withdrawAllFromPool() override internal virtual returns (
    uint expectedWithdrewUSD,
    uint assetPrice,
    uint strategyLoss
  ) {
    return _withdrawFromPool(type(uint).max);
  }

  /// @param amount Amount to be trying to withdrawn. Max uint means attempt to withdraw all possible invested assets.
  /// @param earnedByPrices_ Additional amount that should be withdrawn and send to the insurance
  /// @param investedAssets_ Value of invested assets recalculated using current prices
  /// @return expectedWithdrewUSD The value that we should receive after withdrawing in terms of USD value of each asset in the pool
  /// @return __assetPrice Price of the {asset} taken from the price oracle
  /// @return strategyLoss Loss before withdrawing: [new-investedAssets - old-investedAssets]
  /// @return amountSentToInsurance Actual amount of underlying sent to the insurance
  function _withdrawUniversal(uint amount, uint earnedByPrices_, uint investedAssets_) internal returns (
    uint expectedWithdrewUSD,
    uint __assetPrice,
    uint strategyLoss,
    uint amountSentToInsurance
  ) {
    _beforeWithdraw(amount);

    WithdrawUniversalLocal memory v;
    v.all = amount == type(uint).max;
    strategyLoss = 0;

    if ((v.all || amount + earnedByPrices_ != 0) && investedAssets_ != 0) {

      // --- init variables ---
      v.tokens = _depositorPoolAssets();
      v.asset = asset;
      v.converter = converter;
      v.indexAsset = ConverterStrategyBaseLib.getAssetIndex(v.tokens, v.asset);
      v.balanceBefore = AppLib.balance(v.asset);

      v.reservesBeforeWithdraw = _depositorPoolReserves();
      v.totalSupplyBeforeWithdraw = _depositorTotalSupply();
      v.depositorLiquidity = _depositorLiquidity();
      v.assetPrice = ConverterStrategyBaseLib.getAssetPriceFromConverter(v.converter, v.asset);
      // -----------------------

      // calculate how much liquidity we need to withdraw for getting the requested amount
      (v.liquidityAmountToWithdraw, v.amountsToConvert) = ConverterStrategyBaseLib2.getLiquidityAmount(
        v.all ? 0 : amount + earnedByPrices_,
        address(this),
        v.tokens,
        v.indexAsset,
        v.converter,
        investedAssets_,
        v.depositorLiquidity
      );

      if (v.liquidityAmountToWithdraw != 0) {

        // =============== WITHDRAW =====================
        // make withdraw
        v.withdrawnAmounts = _depositorExit(v.liquidityAmountToWithdraw);
        // the depositor is able to use less liquidity than it was asked, i.e. Balancer-depositor leaves some BPT unused
        // use what exactly was withdrew instead of the expectation
        // assume that liquidity cannot increase in _depositorExit
        v.liquidityAmountToWithdraw = v.depositorLiquidity - _depositorLiquidity();
        emit OnDepositorExit(v.liquidityAmountToWithdraw, v.withdrawnAmounts);
        // ==============================================

        // we need to call expectation after withdraw for calculate it based on the real liquidity amount that was withdrew
        // it should be called BEFORE the converter will touch our positions coz we need to call quote the estimations
        // amountsToConvert should contains amounts was withdrawn from the pool and amounts received from the converter
        (v.expectedMainAssetAmounts, v.amountsToConvert) = ConverterStrategyBaseLib.postWithdrawActions(
          v.converter,
          v.tokens,
          v.indexAsset,
          v.reservesBeforeWithdraw,
          v.liquidityAmountToWithdraw,
          v.totalSupplyBeforeWithdraw,
          v.amountsToConvert,
          v.withdrawnAmounts
        );
      } else {
        // we don't need to withdraw any amounts from the pool, available converted amounts are enough for us
        v.expectedMainAssetAmounts = ConverterStrategyBaseLib.postWithdrawActionsEmpty(
          v.converter,
          v.tokens,
          v.indexAsset,
          v.amountsToConvert
        );
      }

      // convert amounts to main asset
      // it is safe to use amountsToConvert from expectation - we will try to repay only necessary amounts
      v.expectedTotalMainAssetAmount += ConverterStrategyBaseLib.makeRequestedAmount(
        v.tokens,
        v.indexAsset,
        v.amountsToConvert,
        v.converter,
        _getLiquidator(controller()),
        v.all ? amount : amount + earnedByPrices_,
        v.expectedMainAssetAmounts,
        liquidationThresholds
      );

      if (earnedByPrices_ != 0) {
        amountSentToInsurance = ConverterStrategyBaseLib2.sendToInsurance(
          v.asset,
          earnedByPrices_,
          splitter,
          investedAssets_ + v.balanceBefore
        );
      }

      v.investedAssetsAfterWithdraw = _updateInvestedAssets();
      v.balanceAfterWithdraw = AppLib.balance(v.asset);

      // we need to compensate difference if during withdraw we lost some assets
      if ((v.investedAssetsAfterWithdraw + v.balanceAfterWithdraw + earnedByPrices_) < (investedAssets_ + v.balanceBefore)) {
        strategyLoss += (investedAssets_ + v.balanceBefore) - (v.investedAssetsAfterWithdraw + v.balanceAfterWithdraw + earnedByPrices_);
      }

      return (
        v.expectedTotalMainAssetAmount * v.assetPrice / 1e18,
        v.assetPrice,
        strategyLoss,
        amountSentToInsurance
      );
    }
    return (0, 0, 0, 0);
  }

  /// @notice If pool supports emergency withdraw need to call it for emergencyExit()
  function _emergencyExitFromPool() override internal virtual {
    uint[] memory withdrawnAmounts = _depositorEmergencyExit();
    emit OnDepositorEmergencyExit(withdrawnAmounts);

    // convert amounts to main asset
    (address[] memory tokens, uint indexAsset) = _getTokens(asset);
    ConverterStrategyBaseLib.closePositionsToGetAmount(
      converter,
      _getLiquidator(controller()),
      indexAsset,
      liquidationThresholds,
      type(uint).max,
      tokens
    );

    // adjust _investedAssets
    _updateInvestedAssets();
  }
  //endregion Withdraw from the pool

  /////////////////////////////////////////////////////////////////////
  //region Claim rewards
  /////////////////////////////////////////////////////////////////////

  /// @notice Claim all possible rewards.
  function _claim() override internal virtual returns (address[] memory rewardTokensOut, uint[] memory amountsOut) {
    // get rewards from the Depositor
    (address[] memory rewardTokens, uint[] memory rewardAmounts, uint[] memory balancesBefore) = _depositorClaimRewards();

    (rewardTokensOut, amountsOut) = ConverterStrategyBaseLib2.claimConverterRewards(
      converter,
      _depositorPoolAssets(),
      rewardTokens,
      rewardAmounts,
      balancesBefore
    );
  }

  /// @dev Call recycle process and send tokens to forwarder.
  ///      Need to be separated from the claim process - the claim can be called by operator for other purposes.
  function _rewardsLiquidation(address[] memory rewardTokens, uint[] memory amounts) internal {
    uint len = rewardTokens.length;
    if (len > 0) {
      uint[] memory amountsToForward = _recycle(rewardTokens, amounts);

      // send forwarder-part of the rewards to the forwarder
      ConverterStrategyBaseLib2.sendTokensToForwarder(controller(), splitter, rewardTokens, amountsToForward);
    }
  }

  /// @notice Recycle the amounts: liquidate a part of each amount, send the other part to the forwarder.
  /// We have two kinds of rewards:
  /// 1) rewards in depositor's assets (the assets returned by _depositorPoolAssets)
  /// 2) any other rewards
  /// All received rewards divided on three parts: to performance receiver+insurance, to forwarder, to compound
  ///   Compound-part of Rewards-2 can be liquidated
  ///   Compound part of Rewards-1 should be just left on the balance
  ///   Performance amounts should be liquidate, result underlying should be sent to performance receiver and insurance.
  ///   All forwarder-parts are returned in amountsToForward and should be transferred to the forwarder outside.
  /// @dev {_recycle} is implemented as separate (inline) function to simplify unit testing
  /// @param rewardTokens_ Full list of reward tokens received from tetuConverter and depositor
  /// @param rewardAmounts_ Amounts of {rewardTokens_}; we assume, there are no zero amounts here
  /// @return amountsToForward Amounts to be sent to forwarder
  function _recycle(address[] memory rewardTokens_, uint[] memory rewardAmounts_) internal returns (
    uint[] memory amountsToForward
  ) {
    address _asset = asset; // save gas

    uint amountPerf; // total amount for the performance receiver and insurance
    (amountsToForward, amountPerf) = ConverterStrategyBaseLib.recycle(
      converter,
      _asset,
      compoundRatio,
      _depositorPoolAssets(),
      _getLiquidator(controller()),
      liquidationThresholds,
      rewardTokens_,
      rewardAmounts_,
      performanceFee
    );

    // send performance-part of the underlying to the performance receiver and insurance
    (uint toPerf, uint toInsurance) = ConverterStrategyBaseLib2.sendPerformanceFee(
      _asset,
      amountPerf,
      splitter,
      performanceReceiver,
      performanceFeeRatio
    );

    emit Recycle(rewardTokens_, amountsToForward, toPerf, toInsurance);
  }
  //endregion Claim rewards

  /////////////////////////////////////////////////////////////////////
  //region Hardwork
  /////////////////////////////////////////////////////////////////////

  /// @notice A virtual handler to make any action before hardwork
  function _preHardWork(bool reInvest) internal virtual {}

  /// @notice A virtual handler to make any action after hardwork
  function _postHardWork() internal virtual {}

  /// @notice Is strategy ready to hard work
  function isReadyToHardWork() override external virtual view returns (bool) {
    // check claimable amounts and compare with thresholds
    return true;
  }

  /// @notice Do hard work with reinvesting
  /// @return earned Earned amount in terms of {asset}
  /// @return lost Lost amount in terms of {asset}
  function doHardWork() override public returns (uint earned, uint lost) {
    require(msg.sender == splitter, StrategyLib.DENIED);
    return _doHardWork(true);
  }

  /// @notice Claim rewards, do _processClaims() after claiming, calculate earned and lost amounts
  function _handleRewards() internal virtual returns (uint earned, uint lost, uint assetBalanceAfterClaim);

  /// @param reInvest Deposit to pool all available amount if it's greater than the threshold
  /// @return earned Earned amount in terms of {asset}
  /// @return lost Lost amount in terms of {asset}
  function _doHardWork(bool reInvest) internal returns (uint earned, uint lost) {
    // ATTENTION! splitter will not cover the loss if it is lower than profit
    (uint investedAssetsNewPrices, uint earnedByPrices) = _fixPriceChanges(true);

    _preHardWork(reInvest);

    // claim rewards and get current asset balance
    uint assetBalance;
    (earned, lost, assetBalance) = _handleRewards();

    // re-invest income
    (, uint amountSentToInsurance) = _depositToPoolUniversal(
      reInvest
      && investedAssetsNewPrices != 0
      && assetBalance > reinvestThresholdPercent * investedAssetsNewPrices / DENOMINATOR
        ? assetBalance
        : 0,
      earnedByPrices,
      investedAssetsNewPrices
    );
    (uint earned2, uint lost2) = ConverterStrategyBaseLib.registerIncome(
      investedAssetsNewPrices + assetBalance, // assets in use before deposit
      _investedAssets + AppLib.balance(asset) + amountSentToInsurance // assets in use after deposit
    );

    _postHardWork();

    emit OnHardWorkEarnedLost(investedAssetsNewPrices, earnedByPrices, earned, lost, earned2, lost2);
    return (earned + earned2, lost + lost2);
  }
  //endregion Hardwork

  /////////////////////////////////////////////////////////////////////
  //region InvestedAssets Calculations
  /////////////////////////////////////////////////////////////////////

  /// @notice Updates cached _investedAssets to actual value
  /// @dev Should be called after deposit / withdraw / claim; virtual - for ut
  function _updateInvestedAssets() internal returns (uint investedAssetsOut) {
    investedAssetsOut = _calcInvestedAssets();
    _investedAssets = investedAssetsOut;
  }

  /// @notice Calculate amount we will receive when we withdraw all from pool
  /// @dev This is writable function because we need to update current balances in the internal protocols.
  /// @return Invested asset amount under control (in terms of {asset})
  function _calcInvestedAssets() internal returns (uint) {
    (address[] memory tokens, uint indexAsset) = _getTokens(asset);
    return ConverterStrategyBaseLib.calcInvestedAssets(
      tokens,
      // quote exit should check zero liquidity
      _depositorQuoteExit(_depositorLiquidity()),
      indexAsset,
      converter
    );
  }

  function calcInvestedAssets() external returns (uint) {
    StrategyLib.onlyOperators(controller());
    return _calcInvestedAssets();
  }

  /// @notice Calculate profit/loss happened because of price changing. Try to cover the loss, send the profit to the insurance
  /// @param updateInvestedAssetsAmount_ If false - just return current value of invested assets
  /// @return investedAssetsOut Updated value of {_investedAssets}
  /// @return earnedOut Profit that was received because of price changes. It should be sent back to insurance.
  ///                   It's to dangerous to get this to try to get this amount here because of the problem "borrow-repay is not allowed in a single block"
  ///                   So, we need to handle it in the caller code.
  function _fixPriceChanges(bool updateInvestedAssetsAmount_) internal returns (uint investedAssetsOut, uint earnedOut) {
    if (updateInvestedAssetsAmount_) {
      uint investedAssetsBefore = _investedAssets;
      investedAssetsOut = _updateInvestedAssets();
      earnedOut = ConverterStrategyBaseLib.coverPossibleStrategyLoss(investedAssetsBefore, investedAssetsOut, splitter);
    } else {
      investedAssetsOut = _investedAssets;
      earnedOut = 0;
    }
  }
  //endregion InvestedAssets Calculations

  /////////////////////////////////////////////////////////////////////
  //region ITetuConverterCallback
  /////////////////////////////////////////////////////////////////////

  /// @notice Converters asks to send some amount back.
  /// @param theAsset_ Required asset (either collateral or borrow)
  /// @param amount_ Required amount of the {theAsset_}
  /// @return amountOut Amount sent to balance of TetuConverter, amountOut <= amount_
  function requirePayAmountBack(address theAsset_, uint amount_) external override returns (uint amountOut) {
    address __converter = address(converter);
    require(msg.sender == __converter, StrategyLib.DENIED);

    // detect index of the target asset
    (address[] memory tokens, uint indexTheAsset) = _getTokens(theAsset_);
    // get amount of target asset available to be sent
    uint balance = AppLib.balance(theAsset_);

    // withdraw from the pool if not enough
    if (balance < amount_) {
      // the strategy doesn't have enough target asset on balance
      // withdraw all from the pool but don't convert assets to underlying
      uint liquidity = _depositorLiquidity();
      if (liquidity != 0) {
        uint[] memory withdrawnAmounts = _depositorExit(liquidity);
        emit OnDepositorExit(liquidity, withdrawnAmounts);
      }
    }

    amountOut = ConverterStrategyBaseLib.swapToGivenAmountAndSendToConverter(
      amount_,
      indexTheAsset,
      tokens,
      __converter,
      controller(),
      asset,
      liquidationThresholds
    );

    // update invested assets anyway, even if we suppose it will be called in other places
    _updateInvestedAssets();
  }

  /// @notice TetuConverter calls this function when it sends any amount to user's balance
  /// @param assets_ Any asset sent to the balance, i.e. inside repayTheBorrow
  /// @param amounts_ Amount of {asset_} that has been sent to the user's balance
  function onTransferAmounts(address[] memory assets_, uint[] memory amounts_) external override {
    require(msg.sender == address(converter), StrategyLib.DENIED);

    uint len = assets_.length;
    require(len == amounts_.length, AppErrors.INCORRECT_LENGTHS);

    // TetuConverter is able two call this function in two cases:
    // 1) rebalancing (the health factor of some borrow is too low)
    // 2) forcible closing of the borrow
    // In both cases we update invested assets value here
    // and avoid fixing any related losses in hardwork
    _updateInvestedAssets();
  }
  //endregion ITetuConverterCallback

  /////////////////////////////////////////////////////////////////////
  //region Others
  /////////////////////////////////////////////////////////////////////

  /// @notice Unlimited capacity by default
  function capacity() external virtual view returns (uint) {
    return 2 ** 255;
    // almost same as type(uint).max but more gas efficient
  }

  function _getTokens(address asset_) internal view returns (address[] memory tokens, uint indexAsset) {
    tokens = _depositorPoolAssets();
    indexAsset = ConverterStrategyBaseLib.getAssetIndex(tokens, asset_);
    require(indexAsset != type(uint).max, StrategyLib.WRONG_VALUE);
  }

  function _getLiquidator(address controller_) internal view returns (ITetuLiquidator) {
    return ITetuLiquidator(IController(controller_).liquidator());
  }
  //endregion Others


  /// @dev This empty reserved space is put in place to allow future versions to add new
  /// variables without shifting down storage in the inheritance chain.
  /// See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
  uint[50 - 5] private __gap; // 50 - count of variables

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@tetu_io/tetu-contracts-v2/contracts/interfaces/ITetuLiquidator.sol";
import "@tetu_io/tetu-contracts-v2/contracts/interfaces/IForwarder.sol";
import "@tetu_io/tetu-contracts-v2/contracts/interfaces/ITetuVaultV2.sol";
import "@tetu_io/tetu-contracts-v2/contracts/interfaces/ISplitter.sol";
import "@tetu_io/tetu-contracts-v2/contracts/strategy/StrategyLib.sol";
import "@tetu_io/tetu-contracts-v2/contracts/openzeppelin/Math.sol";
import "@tetu_io/tetu-converter/contracts/interfaces/IConverterController.sol";
import "@tetu_io/tetu-converter/contracts/interfaces/IPriceOracle.sol";
import "@tetu_io/tetu-converter/contracts/interfaces/ITetuConverter.sol";
import "../libs/AppErrors.sol";
import "../libs/AppLib.sol";
import "../libs/TokenAmountsLib.sol";
import "../libs/ConverterEntryKinds.sol";

library ConverterStrategyBaseLib {
  using SafeERC20 for IERC20;

  /////////////////////////////////////////////////////////////////////
  //region Data types
  /////////////////////////////////////////////////////////////////////
  /// @notice Local vars for {_recycle}, workaround for stack too deep
  struct RecycleLocalParams {
    /// @notice Compound amount + Performance amount
    uint amountCP;
    /// @notice Amount to compound
    uint amountC;
    /// @notice Amount to send to performance and insurance
    uint amountP;
    /// @notice Amount to forwarder + amount to compound
    uint amountFC;
    address rewardToken;
    uint liquidationThresholdAsset;
    uint len;
    uint receivedAmountOut;
  }

  struct OpenPositionLocal {
    uint entryKind;
    address[] converters;
    uint[] collateralsRequired;
    uint[] amountsToBorrow;
    uint collateral;
    uint amountToBorrow;
  }

  struct OpenPositionEntryKind1Local {
    address[] converters;
    uint[] collateralsRequired;
    uint[] amountsToBorrow;
    uint collateral;
    uint amountToBorrow;
    uint c1;
    uint c3;
    uint ratio;
    uint alpha;
  }

  struct CalcInvestedAssetsLocal {
    uint len;
    uint[] prices;
    uint[] decs;
    uint[] debts;
  }

  struct ConvertAfterWithdrawLocal {
    address asset;
    uint collateral;
    uint spent;
    uint received;
    uint balance;
    uint balanceBefore;
    uint len;
  }

  struct SwapToGivenAmountInputParams {
    uint targetAmount;
    address[] tokens;
    uint indexTargetAsset;
    address underlying;
    uint[] amounts;
    ITetuConverter converter;
    ITetuLiquidator liquidator;
    uint liquidationThresholdForTargetAsset;
    /// @notice Allow to swap more then required (i.e. 1_000 => +1%)
    ///         to avoid additional swap if the swap return amount a bit less than we expected
    uint overswap;
  }

  struct SwapToGivenAmountLocal {
    uint len;
    uint[] availableAmounts;
    uint i;
  }

  struct CloseDebtsForRequiredAmountLocal {
    uint len;
    address asset;
    uint collateral;
    uint spentAmountIn;
    uint receivedAmount;
    uint balance;
    uint[] tokensBalancesBefore;

    uint totalDebt;
    uint totalCollateral;

    /// @notice Cost of $1 in terms of the assets, decimals 18
    uint[] prices;
    /// @notice 10**decimal for the assets
    uint[] decs;

    uint newBalance;
  }
  //endregion Data types

  /////////////////////////////////////////////////////////////////////
  //region Constants
  /////////////////////////////////////////////////////////////////////

  /// @notice approx one month for average block time 2 sec
  uint internal constant _LOAN_PERIOD_IN_BLOCKS = 30 days / 2;
  uint internal constant _REWARD_LIQUIDATION_SLIPPAGE = 5_000; // 5%
  uint internal constant COMPOUND_DENOMINATOR = 100_000;
  uint internal constant DENOMINATOR = 100_000;
  uint internal constant _ASSET_LIQUIDATION_SLIPPAGE = 300;
  uint internal constant PRICE_IMPACT_TOLERANCE = 300;
  /// @notice borrow/collateral amount cannot be less than given number of tokens
  uint internal constant DEFAULT_OPEN_POSITION_AMOUNT_IN_THRESHOLD = 10;
  /// @notice Allow to swap more then required (i.e. 1_000 => +1%) inside {swapToGivenAmount}
  ///         to avoid additional swap if the swap will return amount a bit less than we expected
  uint internal constant OVERSWAP = PRICE_IMPACT_TOLERANCE + _ASSET_LIQUIDATION_SLIPPAGE;
  /// @dev Absolute value for any token
  uint internal constant DEFAULT_LIQUIDATION_THRESHOLD = 100_000;
  /// @notice 1% gap to cover possible liquidation inefficiency
  /// @dev We assume that: conversion-result-calculated-by-prices - liquidation-result <= the-gap
  uint internal constant GAP_CONVERSION = 1_000;
  //endregion Constants

  /////////////////////////////////////////////////////////////////////
  //region Events
  /////////////////////////////////////////////////////////////////////
  /// @notice A borrow was made
  event OpenPosition(
    address converter,
    address collateralAsset,
    uint collateralAmount,
    address borrowAsset,
    uint borrowedAmount,
    address recepient
  );

  /// @notice Some borrow(s) was/were repaid
  event ClosePosition(
    address collateralAsset,
    address borrowAsset,
    uint amountRepay,
    address recepient,
    uint returnedAssetAmountOut,
    uint returnedBorrowAmountOut
  );

  /// @notice A liquidation was made
  event Liquidation(
    address tokenIn,
    address tokenOut,
    uint amountIn,
    uint spentAmountIn,
    uint receivedAmountOut
  );

  event ReturnAssetToConverter(address asset, uint amount);

  event FixPriceChanges(uint investedAssetsBefore, uint investedAssetsOut);
  //endregion Events

  /////////////////////////////////////////////////////////////////////
  //region View functions
  /////////////////////////////////////////////////////////////////////

  /// @notice Get amount of assets that we expect to receive after withdrawing
  ///         ratio = amount-LP-tokens-to-withdraw / total-amount-LP-tokens-in-pool
  /// @param reserves_ Reserves of the {poolAssets_}, same order, same length (we don't check it)
  ///                  The order of tokens should be same as in {_depositorPoolAssets()},
  ///                  one of assets must be {asset_}
  /// @param liquidityAmount_ Amount of LP tokens that we are going to withdraw
  /// @param totalSupply_ Total amount of LP tokens in the depositor
  /// @return withdrawnAmountsOut Expected withdrawn amounts (decimals == decimals of the tokens)
  function getExpectedWithdrawnAmounts(
    uint[] memory reserves_,
    uint liquidityAmount_,
    uint totalSupply_
  ) internal pure returns (
    uint[] memory withdrawnAmountsOut
  ) {
    uint ratio = totalSupply_ == 0
      ? 0
      : (liquidityAmount_ >= totalSupply_
        ? 1e18
        : 1e18 * liquidityAmount_ / totalSupply_
      );

    uint len = reserves_.length;
    withdrawnAmountsOut = new uint[](len);

    if (ratio != 0) {
      for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
        withdrawnAmountsOut[i] = reserves_[i] * ratio / 1e18;
      }
    }
  }

  /// @return prices Asset prices in USD, decimals 18
  /// @return decs 10**decimals
  function _getPricesAndDecs(IPriceOracle priceOracle, address[] memory tokens_, uint len) internal view returns (
    uint[] memory prices,
    uint[] memory decs
  ) {
    prices = new uint[](len);
    decs = new uint[](len);
    {
      for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
        decs[i] = 10 ** IERC20Metadata(tokens_[i]).decimals();
        prices[i] = priceOracle.getAssetPrice(tokens_[i]);
      }
    }
  }

  /// @notice Find index of the given {asset_} in array {tokens_}, return type(uint).max if not found
  function getAssetIndex(address[] memory tokens_, address asset_) internal pure returns (uint) {
    uint len = tokens_.length;
    for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
      if (tokens_[i] == asset_) {
        return i;
      }
    }
    return type(uint).max;
  }

  /// @notice Get the price ratio of the two given tokens from the oracle.
  /// @param converter The Tetu converter.
  /// @param tokenA The first token address.
  /// @param tokenB The second token address.
  /// @return The price ratio of the two tokens.
  function getOracleAssetsPrice(ITetuConverter converter, address tokenA, address tokenB) external view returns (uint) {
    IPriceOracle oracle = IPriceOracle(IConverterController(converter.controller()).priceOracle());
    uint priceA = oracle.getAssetPrice(tokenA);
    uint priceB = oracle.getAssetPrice(tokenB);
    return priceB * 1e18 / priceA;
  }
  //endregion View functions

  /////////////////////////////////////////////////////////////////////
  //region Borrow and close positions
  /////////////////////////////////////////////////////////////////////

  /// @notice Make one or several borrow necessary to supply/borrow required {amountIn_} according to {entryData_}
  ///         Max possible collateral should be approved before calling of this function.
  /// @param entryData_ Encoded entry kind and additional params if necessary (set of params depends on the kind)
  ///                   See TetuConverter\EntryKinds.sol\ENTRY_KIND_XXX constants for possible entry kinds
  ///                   0 or empty: Amount of collateral {amountIn_} is fixed, amount of borrow should be max possible.
  /// @param amountIn_ Meaning depends on {entryData_}.
  function openPosition(
    ITetuConverter tetuConverter_,
    bytes memory entryData_,
    address collateralAsset_,
    address borrowAsset_,
    uint amountIn_,
    uint thresholdAmountIn_
  ) external returns (
    uint collateralAmountOut,
    uint borrowedAmountOut
  ) {
    return _openPosition(tetuConverter_, entryData_, collateralAsset_, borrowAsset_, amountIn_, thresholdAmountIn_);
  }

  /// @notice Make one or several borrow necessary to supply/borrow required {amountIn_} according to {entryData_}
  ///         Max possible collateral should be approved before calling of this function.
  /// @param entryData_ Encoded entry kind and additional params if necessary (set of params depends on the kind)
  ///                   See TetuConverter\EntryKinds.sol\ENTRY_KIND_XXX constants for possible entry kinds
  ///                   0 or empty: Amount of collateral {amountIn_} is fixed, amount of borrow should be max possible.
  /// @param amountIn_ Meaning depends on {entryData_}.
  /// @param thresholdAmountIn_ Min value of amountIn allowed for the second and subsequent conversions.
  ///        0 - use default min value
  ///        If amountIn becomes too low, no additional borrows are possible, so
  ///        the rest amountIn is just added to collateral/borrow amount of previous conversion.
  function _openPosition(
    ITetuConverter tetuConverter_,
    bytes memory entryData_,
    address collateralAsset_,
    address borrowAsset_,
    uint amountIn_,
    uint thresholdAmountIn_
  ) internal returns (
    uint collateralAmountOut,
    uint borrowedAmountOut
  ) {
    if (thresholdAmountIn_ == 0) {
      // zero threshold is not allowed because round-issues are possible, see openPosition.dust test
      // we assume here, that it's useless to borrow amount using collateral/borrow amount
      // less than given number of tokens (event for BTC)
      thresholdAmountIn_ = DEFAULT_OPEN_POSITION_AMOUNT_IN_THRESHOLD;
    }
    if (amountIn_ <= thresholdAmountIn_) {
      return (0, 0);
    }

    OpenPositionLocal memory vars;
    // we assume here, that max possible collateral amount is already approved (as it's required by TetuConverter)
    vars.entryKind = ConverterEntryKinds.getEntryKind(entryData_);
    if (vars.entryKind == ConverterEntryKinds.ENTRY_KIND_EXACT_PROPORTION_1) {
      return openPositionEntryKind1(
        tetuConverter_,
        entryData_,
        collateralAsset_,
        borrowAsset_,
        amountIn_,
        thresholdAmountIn_
      );
    } else {
      (vars.converters, vars.collateralsRequired, vars.amountsToBorrow,) = tetuConverter_.findBorrowStrategies(
        entryData_,
        collateralAsset_,
        amountIn_,
        borrowAsset_,
        _LOAN_PERIOD_IN_BLOCKS
      );

      uint len = vars.converters.length;
      if (len > 0) {
        for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
          // we need to approve collateralAmount before the borrow-call but it's already approved, see above comments
          vars.collateral;
          vars.amountToBorrow;
          if (vars.entryKind == ConverterEntryKinds.ENTRY_KIND_EXACT_COLLATERAL_IN_FOR_MAX_BORROW_OUT_0) {
            // we have exact amount of total collateral amount
            // Case ENTRY_KIND_EXACT_PROPORTION_1 is here too because we consider first platform only
            vars.collateral = amountIn_ < vars.collateralsRequired[i]
              ? amountIn_
              : vars.collateralsRequired[i];
            vars.amountToBorrow = amountIn_ < vars.collateralsRequired[i]
              ? vars.amountsToBorrow[i] * amountIn_ / vars.collateralsRequired[i]
              : vars.amountsToBorrow[i];
            amountIn_ -= vars.collateral;
          } else {
            // assume here that entryKind == EntryKinds.ENTRY_KIND_EXACT_BORROW_OUT_FOR_MIN_COLLATERAL_IN_2
            // we have exact amount of total amount-to-borrow
            vars.amountToBorrow = amountIn_ < vars.amountsToBorrow[i]
              ? amountIn_
              : vars.amountsToBorrow[i];
            vars.collateral = amountIn_ < vars.amountsToBorrow[i]
              ? vars.collateralsRequired[i] * amountIn_ / vars.amountsToBorrow[i]
              : vars.collateralsRequired[i];
            amountIn_ -= vars.amountToBorrow;
          }

          if (amountIn_ < thresholdAmountIn_ && amountIn_ != 0) {
            // dust amount is left, just leave it unused
            // we cannot add it to collateral/borrow amounts - there is a risk to exceed max allowed amounts
            amountIn_ = 0;
          }

          if (vars.amountToBorrow != 0) {
            borrowedAmountOut += tetuConverter_.borrow(
              vars.converters[i],
              collateralAsset_,
              vars.collateral,
              borrowAsset_,
              vars.amountToBorrow,
              address(this)
            );
            collateralAmountOut += vars.collateral;
            emit OpenPosition(
              vars.converters[i],
              collateralAsset_,
              vars.collateral,
              borrowAsset_,
              vars.amountToBorrow,
              address(this)
            );
          }

          if (amountIn_ == 0) break;
        }
      }

      return (collateralAmountOut, borrowedAmountOut);
    }
  }

  /// @notice Open position using entry kind 1 - split provided amount on two parts according provided proportions
  /// @param amountIn_ Amount of collateral to be divided on parts. We assume {amountIn_} > 0
  /// @param collateralThreshold_ Min allowed collateral amount to be used for new borrow, > 0
  /// @return collateralAmountOut Total collateral used to borrow {borrowedAmountOut}
  /// @return borrowedAmountOut Total borrowed amount
  function openPositionEntryKind1(
    ITetuConverter tetuConverter_,
    bytes memory entryData_,
    address collateralAsset_,
    address borrowAsset_,
    uint amountIn_,
    uint collateralThreshold_
  ) internal returns (
    uint collateralAmountOut,
    uint borrowedAmountOut
  ) {
    OpenPositionEntryKind1Local memory vars;
    (vars.converters, vars.collateralsRequired, vars.amountsToBorrow,) = tetuConverter_.findBorrowStrategies(
      entryData_,
      collateralAsset_,
      amountIn_,
      borrowAsset_,
      _LOAN_PERIOD_IN_BLOCKS
    );

    uint len = vars.converters.length;
    if (len > 0) {
      // we should split amountIn on two amounts with proportions x:y
      (, uint x, uint y) = abi.decode(entryData_, (uint, uint, uint));
      // calculate prices conversion ratio using price oracle, decimals 18
      // i.e. alpha = 1e18 * 75e6 usdc / 25e18 matic = 3e6 usdc/matic
      vars.alpha = _getCollateralToBorrowRatio(tetuConverter_, collateralAsset_, borrowAsset_);

      for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
        // the lending platform allows to convert {collateralsRequired[i]} to {amountsToBorrow[i]}
        // and give us required proportions in result
        // C = C1 + C2, C2 => B2, B2 * alpha = C3, C1/C3 must be equal to x/y
        // C1 is collateral amount left untouched (x)
        // C2 is collateral amount converted to B2 (y)
        // but if lending platform doesn't have enough liquidity
        // it reduces {collateralsRequired[i]} and {amountsToBorrow[i]} proportionally to fit the limits
        // as result, remaining C1 will be too big after conversion and we need to make another borrow
        vars.c3 = vars.alpha * vars.amountsToBorrow[i] / 1e18;
        vars.c1 = x * vars.c3 / y;
        vars.ratio = (vars.collateralsRequired[i] + vars.c1) > amountIn_
          ? 1e18 * amountIn_ / (vars.collateralsRequired[i] + vars.c1)
          : 1e18;

        vars.collateral = vars.collateralsRequired[i] * vars.ratio / 1e18;
        vars.amountToBorrow = vars.amountsToBorrow[i] * vars.ratio / 1e18;

        // skip any attempts to borrow zero amount or use too little collateral
        if (vars.collateral < collateralThreshold_ || vars.amountToBorrow == 0) {
          if (vars.collateralsRequired[i] + vars.c1 + collateralThreshold_ > amountIn_) {
            // The lending platform has enough resources to make the borrow but amount of the borrow is too low
            // Skip the borrow, leave leftover of collateral untouched
            break;
          } else {
            // The lending platform doesn't have enough resources to make the borrow.
            // We should try to make borrow on the next platform (if any)
            continue;
          }
        }

        require(
          tetuConverter_.borrow(
            vars.converters[i],
            collateralAsset_,
            vars.collateral,
            borrowAsset_,
            vars.amountToBorrow,
            address(this)
          ) == vars.amountToBorrow,
          StrategyLib.WRONG_VALUE
        );
        emit OpenPosition(
          vars.converters[i],
          collateralAsset_,
          vars.collateral,
          borrowAsset_,
          vars.amountToBorrow,
          address(this)
        );

        borrowedAmountOut += vars.amountToBorrow;
        collateralAmountOut += vars.collateral;

        // calculate amount to be borrowed in the next converter
        vars.c3 = vars.alpha * vars.amountToBorrow / 1e18;
        vars.c1 = x * vars.c3 / y;
        amountIn_ = (amountIn_ > vars.c1 + vars.collateral)
          ? amountIn_ - (vars.c1 + vars.collateral)
          : 0;

        // protection against dust amounts, see "openPosition.dust", just leave dust amount unused
        // we CAN NOT add it to collateral/borrow amounts - there is a risk to exceed max allowed amounts
        // we assume here, that collateralThreshold_ != 0, so check amountIn_ != 0 is not required
        if (amountIn_ < collateralThreshold_) break;
      }
    }

    return (collateralAmountOut, borrowedAmountOut);
  }

  /// @notice Get ratio18 = collateral / borrow
  function _getCollateralToBorrowRatio(
    ITetuConverter tetuConverter_,
    address collateralAsset_,
    address borrowAsset_
  ) internal view returns (uint){
    IPriceOracle priceOracle = IPriceOracle(IConverterController(tetuConverter_.controller()).priceOracle());
    uint priceCollateral = priceOracle.getAssetPrice(collateralAsset_);
    uint priceBorrow = priceOracle.getAssetPrice(borrowAsset_);
    return 1e18 * priceBorrow * 10 ** IERC20Metadata(collateralAsset_).decimals()
    / priceCollateral / 10 ** IERC20Metadata(borrowAsset_).decimals();
  }

  /// @notice Close the given position, pay {amountToRepay}, return collateral amount in result
  ///         It doesn't repay more than the actual amount of the debt, so it can use less amount than {amountToRepay}
  /// @param amountToRepay Amount to repay in terms of {borrowAsset}
  /// @return returnedAssetAmountOut Amount of collateral received back after repaying
  /// @return repaidAmountOut Amount that was actually repaid
  function _closePosition(
    ITetuConverter converter_,
    address collateralAsset,
    address borrowAsset,
    uint amountToRepay
  ) internal returns (
    uint returnedAssetAmountOut,
    uint repaidAmountOut
  ) {

    uint balanceBefore = IERC20(borrowAsset).balanceOf(address(this));

    // We shouldn't try to pay more than we actually need to repay
    // The leftover will be swapped inside TetuConverter, it's inefficient.
    // Let's limit amountToRepay by needToRepay-amount
    (uint needToRepay,) = converter_.getDebtAmountCurrent(address(this), collateralAsset, borrowAsset, true);
    uint amountRepay = Math.min(amountToRepay < needToRepay ? amountToRepay : needToRepay, balanceBefore);

    return _closePositionExact(converter_, collateralAsset, borrowAsset, amountRepay, balanceBefore);
  }

  /// @notice Close the given position, pay {amountRepay} exactly and ensure that all amount was accepted,
  /// @param amountRepay Amount to repay in terms of {borrowAsset}
  /// @param balanceBorrowAsset Current balance of the borrow asset
  /// @return collateralOut Amount of collateral received back after repaying
  /// @return repaidAmountOut Amount that was actually repaid
  function _closePositionExact(
    ITetuConverter converter_,
    address collateralAsset,
    address borrowAsset,
    uint amountRepay,
    uint balanceBorrowAsset
  ) internal returns (
    uint collateralOut,
    uint repaidAmountOut
  ) {
    // Make full/partial repayment
    IERC20(borrowAsset).safeTransfer(address(converter_), amountRepay);

    uint notUsedAmount;
    (collateralOut, notUsedAmount,,) = converter_.repay(collateralAsset, borrowAsset, amountRepay, address(this));

    emit ClosePosition(collateralAsset, borrowAsset, amountRepay, address(this), collateralOut, notUsedAmount);
    uint balanceAfter = IERC20(borrowAsset).balanceOf(address(this));

    // we cannot use amountRepay here because AAVE pool adapter is able to send tiny amount back (debt-gap)
    repaidAmountOut = balanceBorrowAsset > balanceAfter
      ? balanceBorrowAsset - balanceAfter
      : 0;

    require(notUsedAmount == 0, StrategyLib.WRONG_VALUE);
  }

  /// @notice Close the given position, pay {amountToRepay}, return collateral amount in result
  /// @param amountToRepay Amount to repay in terms of {borrowAsset}
  /// @return returnedAssetAmountOut Amount of collateral received back after repaying
  /// @return repaidAmountOut Amount that was actually repaid
  function closePosition(
    ITetuConverter tetuConverter_,
    address collateralAsset,
    address borrowAsset,
    uint amountToRepay
  ) external returns (
    uint returnedAssetAmountOut,
    uint repaidAmountOut
  ) {
    return _closePosition(tetuConverter_, collateralAsset, borrowAsset, amountToRepay);
  }
  //endregion Borrow and close positions

  /////////////////////////////////////////////////////////////////////
  //region Liquidation
  /////////////////////////////////////////////////////////////////////

  /// @notice Make liquidation if estimated amountOut exceeds the given threshold
  /// @param spentAmountIn Amount of {tokenIn} has been consumed by the liquidator
  /// @param receivedAmountOut Amount of {tokenOut_} has been returned by the liquidator
  /// @param skipValidation Don't check correctness of conversion using TetuConverter's oracle (i.e. for reward tokens)
  function liquidate(
    ITetuConverter converter,
    ITetuLiquidator liquidator_,
    address tokenIn_,
    address tokenOut_,
    uint amountIn_,
    uint slippage_,
    uint liquidationThresholdTokenOut_,
    bool skipValidation
  ) external returns (
    uint spentAmountIn,
    uint receivedAmountOut
  ) {
    return _liquidate(converter, liquidator_, tokenIn_, tokenOut_, amountIn_, slippage_, liquidationThresholdTokenOut_, skipValidation);
  }

  /// @notice Make liquidation if estimated amountOut exceeds the given threshold
  /// @param spentAmountIn Amount of {tokenIn} has been consumed by the liquidator (== 0 | amountIn_)
  /// @param receivedAmountOut Amount of {tokenOut_} has been returned by the liquidator
  /// @param skipValidation Don't check correctness of conversion using TetuConverter's oracle (i.e. for reward tokens)
  function _liquidate(
    ITetuConverter converter_,
    ITetuLiquidator liquidator_,
    address tokenIn_,
    address tokenOut_,
    uint amountIn_,
    uint slippage_,
    uint liquidationThresholdForTokenOut_,
    bool skipValidation
  ) internal returns (
    uint spentAmountIn,
    uint receivedAmountOut
  ) {
    if (amountIn_ == 0) {
      return (0, 0);
    }

    (ITetuLiquidator.PoolData[] memory route,) = liquidator_.buildRoute(tokenIn_, tokenOut_);

    require(route.length != 0, AppErrors.NO_LIQUIDATION_ROUTE);

    // calculate balance in out value for check threshold
    uint amountOut = liquidator_.getPriceForRoute(route, amountIn_);

    // if the expected value is higher than threshold distribute to destinations
    return amountOut > liquidationThresholdForTokenOut_
      ? (amountIn_, _liquidateWithRoute(converter_, route, liquidator_, tokenIn_, tokenOut_, amountIn_, slippage_, skipValidation))
      : (0, 0);
  }

  /// @notice Make liquidation using given route and check correctness using TetuConverter's price oracle
  /// @param skipValidation Don't check correctness of conversion using TetuConverter's oracle (i.e. for reward tokens)
  function _liquidateWithRoute(
    ITetuConverter converter_,
    ITetuLiquidator.PoolData[] memory route,
    ITetuLiquidator liquidator_,
    address tokenIn_,
    address tokenOut_,
    uint amountIn_,
    uint slippage_,
    bool skipValidation
  ) internal returns (
    uint receivedAmountOut
  ) {
    // we need to approve each time, liquidator address can be changed in controller
    AppLib.approveIfNeeded(tokenIn_, amountIn_, address(liquidator_));

    uint balanceBefore = IERC20(tokenOut_).balanceOf(address(this));
    liquidator_.liquidateWithRoute(route, amountIn_, slippage_);
    uint balanceAfter = IERC20(tokenOut_).balanceOf(address(this));

    require(balanceAfter > balanceBefore, AppErrors.BALANCE_DECREASE);
    receivedAmountOut = balanceAfter - balanceBefore;

    // Oracle in TetuConverter "knows" only limited number of the assets
    // It may not know prices for reward assets, so for rewards this validation should be skipped to avoid TC-4 error
    require(skipValidation || converter_.isConversionValid(tokenIn_, amountIn_, tokenOut_, receivedAmountOut, slippage_), AppErrors.PRICE_IMPACT);
    emit Liquidation(tokenIn_, tokenOut_, amountIn_, amountIn_, receivedAmountOut);
  }
  //endregion Liquidation

  /////////////////////////////////////////////////////////////////////
  //region requirePayAmountBack
  /////////////////////////////////////////////////////////////////////

  /// @param amount_ Amount of the main asset requested by converter
  /// @param indexTheAsset Index of the asset required by converter in the {tokens}
  /// @param asset Main asset or underlying (it can be different from tokens[indexTheAsset])
  /// @return amountOut Amount of the main asset sent to converter
  function swapToGivenAmountAndSendToConverter(
    uint amount_,
    uint indexTheAsset,
    address[] memory tokens,
    address converter,
    address controller,
    address asset,
    mapping(address => uint) storage liquidationThresholds
  ) external returns (
    uint amountOut
  ) {
    // msg.sender == converter; we assume here that it was checked before the call of this function
    address theAsset = tokens[indexTheAsset];

    amountOut = IERC20(theAsset).balanceOf(address(this));

    // convert withdrawn assets to the target asset if not enough
    if (amountOut < amount_) {
      ConverterStrategyBaseLib.swapToGivenAmount(
        amount_ - amountOut,
        tokens,
        indexTheAsset,
        asset, // underlying === main asset
        ITetuConverter(converter),
        ITetuLiquidator(IController(controller).liquidator()),
        liquidationThresholds[theAsset],
        OVERSWAP
      );
      amountOut = IERC20(theAsset).balanceOf(address(this));
    }

    // we should send the asset as is even if it is lower than requested
    // but shouldn't sent more amount than requested
    amountOut = Math.min(amount_, amountOut);
    if (amountOut != 0) {
      IERC20(theAsset).safeTransfer(converter, amountOut);
    }

    // There are two cases of calling requirePayAmountBack by converter:
    // 1) close a borrow: we will receive collateral back and amount of investedAssets almost won't change
    // 2) rebalancing: we have real loss, it will be taken into account at next hard work
    emit ReturnAssetToConverter(theAsset, amountOut);

    // let's leave any leftovers un-invested, they will be reinvested at next hardwork
  }

  /// @notice Swap available amounts of {tokens_} to receive {targetAmount_} of {tokens[indexTheAsset_]}
  /// @param targetAmount_ Required amount of tokens[indexTheAsset_] that should be received by swap(s)
  /// @param tokens_ tokens received from {_depositorPoolAssets}
  /// @param indexTargetAsset_ Index of target asset in tokens_ array
  /// @param underlying_ Index of underlying
  /// @param liquidationThresholdForTargetAsset_ Liquidation thresholds for the target asset
  /// @param overswap_ Allow to swap more then required (i.e. 1_000 => +1%)
  ///                  to avoid additional swap if the swap return amount a bit less than we expected
  /// @return spentAmounts Any amounts spent during the swaps
  function swapToGivenAmount(
    uint targetAmount_,
    address[] memory tokens_,
    uint indexTargetAsset_,
    address underlying_,
    ITetuConverter converter_,
    ITetuLiquidator liquidator_,
    uint liquidationThresholdForTargetAsset_,
    uint overswap_
  ) internal returns (
    uint[] memory spentAmounts,
    uint[] memory receivedAmounts
  ) {
    SwapToGivenAmountLocal memory v;
    v.len = tokens_.length;

    v.availableAmounts = new uint[](v.len);
    for (; v.i < v.len; v.i = AppLib.uncheckedInc(v.i)) {
      v.availableAmounts[v.i] = IERC20(tokens_[v.i]).balanceOf(address(this));
    }

    (spentAmounts, receivedAmounts) = _swapToGivenAmount(
      SwapToGivenAmountInputParams({
        targetAmount: targetAmount_,
        tokens: tokens_,
        indexTargetAsset: indexTargetAsset_,
        underlying: underlying_,
        amounts: v.availableAmounts,
        converter: converter_,
        liquidator: liquidator_,
        liquidationThresholdForTargetAsset: Math.max(liquidationThresholdForTargetAsset_, DEFAULT_LIQUIDATION_THRESHOLD),
        overswap: overswap_
      })
    );
  }

  /// @notice Swap available {amounts_} of {tokens_} to receive {targetAmount_} of {tokens[indexTheAsset_]}
  /// @return spentAmounts Any amounts spent during the swaps
  /// @return receivedAmounts Any amounts received during the swaps
  function _swapToGivenAmount(SwapToGivenAmountInputParams memory p) internal returns (
    uint[] memory spentAmounts,
    uint[] memory receivedAmounts
  ) {
    CalcInvestedAssetsLocal memory v;
    v.len = p.tokens.length;
    receivedAmounts = new uint[](v.len);
    spentAmounts = new uint[](v.len);

    // calculate prices, decimals
    (v.prices, v.decs) = _getPricesAndDecs(
      IPriceOracle(IConverterController(p.converter.controller()).priceOracle()),
      p.tokens,
      v.len
    );

    // we need to swap other assets to the asset
    // at first we should swap NOT underlying.
    // if it would be not enough, we can swap underlying too.

    // swap NOT underlying, initialize {indexUnderlying}
    uint indexUnderlying;
    for (uint i; i < v.len; i = AppLib.uncheckedInc(i)) {
      if (p.underlying == p.tokens[i]) {
        indexUnderlying = i;
        continue;
      }
      if (p.indexTargetAsset == i) continue;

      (uint spent, uint received) = _swapToGetAmount(receivedAmounts[p.indexTargetAsset], p, v, i);
      spentAmounts[i] += spent;
      receivedAmounts[p.indexTargetAsset] += received;

      if (receivedAmounts[p.indexTargetAsset] >= p.targetAmount) break;
    }

    // swap underlying
    if (receivedAmounts[p.indexTargetAsset] < p.targetAmount && p.indexTargetAsset != indexUnderlying) {
      (uint spent, uint received) = _swapToGetAmount(receivedAmounts[p.indexTargetAsset], p, v, indexUnderlying);
      spentAmounts[indexUnderlying] += spent;
      receivedAmounts[p.indexTargetAsset] += received;
    }
  }

  /// @notice Swap a part of amount of asset {tokens[indexTokenIn]} to {targetAsset} to get {targetAmount} in result
  /// @param receivedTargetAmount Already received amount of {targetAsset} in previous swaps
  /// @param indexTokenIn Index of the tokenIn in p.tokens
  function _swapToGetAmount(
    uint receivedTargetAmount,
    SwapToGivenAmountInputParams memory p,
    CalcInvestedAssetsLocal memory v,
    uint indexTokenIn
  ) internal returns (
    uint amountSpent,
    uint amountReceived
  ) {
    if (p.amounts[indexTokenIn] != 0) {
      // we assume here, that p.targetAmount > receivedTargetAmount, see _swapToGivenAmount implementation

      // calculate amount that should be swapped
      // {overswap} allows to swap a bit more
      // to avoid additional swaps if the swap will give us a bit less amount than expected
      uint amountIn = (
        (p.targetAmount - receivedTargetAmount)
        * v.prices[p.indexTargetAsset] * v.decs[indexTokenIn]
        / v.prices[indexTokenIn] / v.decs[p.indexTargetAsset]
      ) * (p.overswap + DENOMINATOR) / DENOMINATOR;

      (amountSpent, amountReceived) = _liquidate(
        p.converter,
        p.liquidator,
        p.tokens[indexTokenIn],
        p.tokens[p.indexTargetAsset],
        Math.min(amountIn, p.amounts[indexTokenIn]),
        _ASSET_LIQUIDATION_SLIPPAGE,
        p.liquidationThresholdForTargetAsset,
        false
      );
    }

    return (amountSpent, amountReceived);
  }
  //endregion requirePayAmountBack

  /////////////////////////////////////////////////////////////////////
  //region Recycle rewards
  /////////////////////////////////////////////////////////////////////

  /// @notice Recycle the amounts: split each amount on tree parts: performance+insurance (P), forwarder (F), compound (C)
  ///         Liquidate P+C, send F to the forwarder.
  /// We have two kinds of rewards:
  /// 1) rewards in depositor's assets (the assets returned by _depositorPoolAssets)
  /// 2) any other rewards
  /// All received rewards divided on three parts: to performance receiver+insurance, to forwarder, to compound
  ///   Compound-part of Rewards-2 can be liquidated
  ///   Compound part of Rewards-1 should be just left on the balance
  ///   All forwarder-parts are returned in amountsToForward and should be transferred to the forwarder outside.
  ///   Performance amounts are liquidated, result amount of underlying is returned in {amountToPerformanceAndInsurance}
  /// @param asset Underlying asset
  /// @param compoundRatio Compound ration in the range [0...COMPOUND_DENOMINATOR]
  /// @param tokens tokens received from {_depositorPoolAssets}
  /// @param rewardTokens Full list of reward tokens received from tetuConverter and depositor
  /// @param rewardAmounts Amounts of {rewardTokens_}; we assume, there are no zero amounts here
  /// @param liquidationThresholds Liquidation thresholds for rewards tokens
  /// @param performanceFee Performance fee in the range [0...FEE_DENOMINATOR]
  /// @return amountsToForward Amounts of {rewardTokens} to be sent to forwarder, zero amounts are allowed here
  /// @return amountToPerformanceAndInsurance Amount of underlying to be sent to performance receiver and insurance
  function recycle(
    ITetuConverter converter_,
    address asset,
    uint compoundRatio,
    address[] memory tokens,
    ITetuLiquidator liquidator,
    mapping(address => uint) storage liquidationThresholds,
    address[] memory rewardTokens,
    uint[] memory rewardAmounts,
    uint performanceFee
  ) external returns (
    uint[] memory amountsToForward,
    uint amountToPerformanceAndInsurance
  ) {
    RecycleLocalParams memory p;

    p.len = rewardTokens.length;
    require(p.len == rewardAmounts.length, AppErrors.WRONG_LENGTHS);

    p.liquidationThresholdAsset = Math.max(liquidationThresholds[asset], DEFAULT_LIQUIDATION_THRESHOLD);

    amountsToForward = new uint[](p.len);

    // rewardAmounts => P + F + C, where P - performance + insurance, F - forwarder, C - compound
    for (uint i; i < p.len; i = AppLib.uncheckedInc(i)) {
      p.amountFC = rewardAmounts[i] * (COMPOUND_DENOMINATOR - performanceFee) / COMPOUND_DENOMINATOR;
      p.amountC = p.amountFC * compoundRatio / COMPOUND_DENOMINATOR;
      p.amountP = rewardAmounts[i] - p.amountFC;
      p.rewardToken = rewardTokens[i];
      p.amountCP = p.amountC + p.amountP;

      if (p.amountCP > 0) {
        if (ConverterStrategyBaseLib.getAssetIndex(tokens, p.rewardToken) != type(uint).max) {
          if (p.rewardToken == asset) {
            // This is underlying, liquidation of compound part is not allowed; just keep on the balance, should be handled later
            amountToPerformanceAndInsurance += p.amountP;
          } else {
            // This is secondary asset, Liquidation of compound part is not allowed, we should liquidate performance part only
            if (p.amountP < Math.max(liquidationThresholds[p.rewardToken], DEFAULT_LIQUIDATION_THRESHOLD)) {
              // performance amount is too small, liquidation is not allowed, we just keep that dust tokens on balance forever
            } else {
              (, p.receivedAmountOut) = _liquidate(
                converter_,
                liquidator,
                p.rewardToken,
                asset,
                p.amountP,
                _REWARD_LIQUIDATION_SLIPPAGE,
                p.liquidationThresholdAsset,
                false // use conversion validation for these rewards
              );
              amountToPerformanceAndInsurance += p.receivedAmountOut;
            }
          }
        } else {
          if (p.amountCP < Math.max(liquidationThresholds[p.rewardToken], DEFAULT_LIQUIDATION_THRESHOLD)) {
            // amount is too small, liquidation is not allowed, we just keep that dust tokens on balance forever
          } else {
            // The asset is not in the list of depositor's assets, its amount is big enough and should be liquidated
            // We assume here, that {token} cannot be equal to {_asset}
            // because the {_asset} is always included to the list of depositor's assets
            (, p.receivedAmountOut) = _liquidate(
              converter_,
              liquidator,
              p.rewardToken,
              asset,
              p.amountCP,
              _REWARD_LIQUIDATION_SLIPPAGE,
              p.liquidationThresholdAsset,
              true // skip conversion validation for rewards becase we can have arbitrary assets here
            );

            amountToPerformanceAndInsurance += p.receivedAmountOut * (rewardAmounts[i] - p.amountFC) / p.amountCP;
          }
        }
      }
      amountsToForward[i] = p.amountFC - p.amountC;
    }
    return (amountsToForward, amountToPerformanceAndInsurance);
  }
  //endregion Recycle rewards

  /////////////////////////////////////////////////////////////////////
  //region calcInvestedAssets
  /////////////////////////////////////////////////////////////////////

  /// @notice Calculate amount we will receive when we withdraw all from pool
  /// @dev This is writable function because we need to update current balances in the internal protocols.
  /// @return amountOut Invested asset amount under control (in terms of {asset})
  function calcInvestedAssets(
    address[] memory tokens,
    uint[] memory depositorQuoteExitAmountsOut,
    uint indexAsset,
    ITetuConverter converter_
  ) external returns (
    uint amountOut
  ) {
    CalcInvestedAssetsLocal memory v;
    v.len = tokens.length;

    // calculate prices, decimals
    (v.prices, v.decs) = _getPricesAndDecs(
      IPriceOracle(IConverterController(converter_.controller()).priceOracle()),
      tokens,
      v.len
    );
    // A debt is registered below if we have X amount of asset, need to pay Y amount of the asset and X < Y
    // In this case: debt = Y - X, the order of tokens is the same as in {tokens} array
    for (uint i; i < v.len; i = AppLib.uncheckedInc(i)) {
      if (i == indexAsset) {
        // Current strategy balance of main asset is not taken into account here because it's add by splitter
        amountOut += depositorQuoteExitAmountsOut[i];
      } else {
        // available amount to repay
        uint toRepay = IERC20(tokens[i]).balanceOf(address(this)) + depositorQuoteExitAmountsOut[i];

        (uint toPay, uint collateral) = converter_.getDebtAmountCurrent(
          address(this),
          tokens[indexAsset],
          tokens[i],
          // investedAssets is calculated using exact debts, debt-gaps are not taken into account
          false
        );
        amountOut += collateral;

        if (toRepay >= toPay) {
          amountOut += (toRepay - toPay) * v.prices[i] * v.decs[indexAsset] / v.prices[indexAsset] / v.decs[i];
        } else {
          // there is not enough amount to pay the debt
          // let's register a debt and try to resolve it later below
          if (v.debts.length == 0) {
            // lazy initialization
            v.debts = new uint[](v.len);
          }

          // to pay the following amount we need to swap some other asset at first
          v.debts[i] = toPay - toRepay;
        }
      }
    }
    if (v.debts.length == v.len) {
      // we assume here, that it would be always profitable to save collateral
      // f.e. if there is not enough amount of USDT on our balance and we have a debt in USDT,
      // it's profitable to change any available asset to USDT, pay the debt and return the collateral back
      for (uint i; i < v.len; i = AppLib.uncheckedInc(i)) {
        if (v.debts[i] == 0) continue;

        // estimatedAssets should be reduced on the debt-value
        // this estimation is approx and do not count price impact on the liquidation
        // we will able to count the real output only after withdraw process
        uint debtInAsset = v.debts[i] * v.prices[i] * v.decs[indexAsset] / v.prices[indexAsset] / v.decs[i];
        if (debtInAsset > amountOut) {
          // The debt is greater than we can pay. We shouldn't try to pay the debt in this case
          amountOut = 0;
        } else {
          amountOut -= debtInAsset;
        }
      }
    }

    return amountOut;
  }
  //endregion calcInvestedAssets

  /////////////////////////////////////////////////////////////////////
  //region getExpectedAmountMainAsset
  /////////////////////////////////////////////////////////////////////

  /// @notice Calculate expected amount of the main asset after withdrawing
  /// @param withdrawnAmounts_ Expected amounts to be withdrawn from the pool
  /// @param amountsToConvert_ Amounts on balance initially available for the conversion
  /// @return amountsOut Expected amounts of the main asset received after conversion withdrawnAmounts+amountsToConvert
  function getExpectedAmountMainAsset(
    address[] memory tokens,
    uint indexAsset,
    ITetuConverter converter,
    uint[] memory withdrawnAmounts_,
    uint[] memory amountsToConvert_
  ) internal returns (
    uint[] memory amountsOut
  ) {
    uint len = tokens.length;
    amountsOut = new uint[](len);
    for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
      if (i == indexAsset) {
        amountsOut[i] = withdrawnAmounts_[i];
      } else {
        uint amount = withdrawnAmounts_[i] + amountsToConvert_[i];
        if (amount != 0) {
          (amountsOut[i],) = converter.quoteRepay(address(this), tokens[indexAsset], tokens[i], amount);
        }
      }
    }

    return amountsOut;
  }
  //endregion getExpectedAmountMainAsset

  /////////////////////////////////////////////////////////////////////
  //region Reduce size of ConverterStrategyBase
  /////////////////////////////////////////////////////////////////////

  /// @notice Make borrow and save amounts of tokens available for deposit to tokenAmounts
  /// @param thresholdMainAsset_ Min allowed value of collateral in terms of main asset, 0 - use default min value
  /// @param tokens_ Tokens received from {_depositorPoolAssets}
  /// @param collaterals_ Amounts of main asset that can be used as collateral to borrow {tokens_}
  /// @param thresholdMainAsset_ Value of liquidation threshold for the main (collateral) asset
  /// @return tokenAmountsOut Amounts available for deposit
  function getTokenAmounts(
    ITetuConverter tetuConverter_,
    address[] memory tokens_,
    uint indexAsset_,
    uint[] memory collaterals_,
    uint thresholdMainAsset_
  ) external returns (
    uint[] memory tokenAmountsOut
  ) {
    // content of tokenAmounts will be modified in place
    uint len = tokens_.length;
    tokenAmountsOut = new uint[](len);

    for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
      if (i != indexAsset_) {
        if (collaterals_[i] != 0) {
          AppLib.approveIfNeeded(tokens_[indexAsset_], collaterals_[i], address(tetuConverter_));
          _openPosition(
            tetuConverter_,
            "", // entry kind = 0: fixed collateral amount, max possible borrow amount
            tokens_[indexAsset_],
            tokens_[i],
            collaterals_[i],
            Math.max(thresholdMainAsset_, DEFAULT_LIQUIDATION_THRESHOLD)
          );

          // zero borrowed amount is possible here (conversion is not available)
          // if it's not suitable for depositor, the depositor should check zero amount in other places
        }
        tokenAmountsOut[i] = IERC20(tokens_[i]).balanceOf(address(this));
      }
    }

    tokenAmountsOut[indexAsset_] = Math.min(
      collaterals_[indexAsset_],
      IERC20(tokens_[indexAsset_]).balanceOf(address(this))
    );
  }

  /// @notice Convert {amountsToConvert_} to the main {asset}
  ///         Swap leftovers (if any) to the main asset.
  ///         If result amount is less than expected, try to close any other available debts (1 repay per block only)
  /// @param tokens_ Results of _depositorPoolAssets() call (list of depositor's asset in proper order)
  /// @param indexAsset_ Index of main {asset} in {tokens}
  /// @param requestedAmount Amount to be withdrawn in terms of the asset in addition to the exist balance.
  ///        Max uint means attempt to withdraw all possible invested assets.
  /// @param amountsToConvert_ Amounts available for conversion after withdrawing from the pool
  /// @param expectedMainAssetAmounts Amounts of main asset that we expect to receive after conversion amountsToConvert_
  /// @return expectedAmount Expected total amount of main asset after all conversions, swaps and repays
  function makeRequestedAmount(
    address[] memory tokens_,
    uint indexAsset_,
    uint[] memory amountsToConvert_,
    ITetuConverter converter_,
    ITetuLiquidator liquidator_,
    uint requestedAmount,
    uint[] memory expectedMainAssetAmounts,
    mapping(address => uint) storage liquidationThresholds
  ) external returns (uint expectedAmount) {
    // get the total expected amount
    for (uint i; i < tokens_.length; i = AppLib.uncheckedInc(i)) {
      expectedAmount += expectedMainAssetAmounts[i];
    }

    // we cannot repay a debt twice
    // suppose, we have usdt = 1 and we need to convert it to usdc, then get additional usdt=10 and make second repay
    // But: we cannot make repay(1) and than repay(10). We MUST make single repay(11)

    if (requestedAmount != type(uint).max
      && expectedAmount > requestedAmount * (GAP_CONVERSION + DENOMINATOR) / DENOMINATOR
    ) {
      // amountsToConvert_ are enough to get requestedAmount
      _convertAfterWithdraw(
        converter_,
        liquidator_,
        indexAsset_,
        liquidationThresholds[tokens_[indexAsset_]],
        tokens_,
        amountsToConvert_
      );
    } else {
      // amountsToConvert_ are NOT enough to get requestedAmount
      // We are allowed to make only one repay per block, so, we shouldn't try to convert amountsToConvert_
      // We should try to close the exist debts instead:
      //    convert a part of main assets to get amount of secondary assets required to repay the debts
      // and only then make conversion.
      expectedAmount = _closePositionsToGetAmount(
        converter_,
        liquidator_,
        indexAsset_,
        liquidationThresholds,
        requestedAmount,
        tokens_
      ) + expectedMainAssetAmounts[indexAsset_];
    }

    return expectedAmount;
  }
  //endregion Reduce size of ConverterStrategyBase

  /////////////////////////////////////////////////////////////////////
  //region Withdraw helpers
  /////////////////////////////////////////////////////////////////////

  /// @notice Add {withdrawnAmounts} to {amountsToConvert}, calculate {expectedAmountMainAsset}
  /// @param amountsToConvert Amounts of {tokens} to be converted, they are located on the balance before withdraw
  /// @param withdrawnAmounts Amounts of {tokens} that were withdrew from the pool
  function postWithdrawActions(
    ITetuConverter converter,
    address[] memory tokens,
    uint indexAsset,

    uint[] memory reservesBeforeWithdraw,
    uint liquidityAmountWithdrew,
    uint totalSupplyBeforeWithdraw,

    uint[] memory amountsToConvert,
    uint[] memory withdrawnAmounts
  ) external returns (
    uint[] memory expectedMainAssetAmounts,
    uint[] memory _amountsToConvert
  ) {
    // estimate expected amount of assets to be withdrawn
    uint[] memory expectedWithdrawAmounts = getExpectedWithdrawnAmounts(
      reservesBeforeWithdraw,
      liquidityAmountWithdrew,
      totalSupplyBeforeWithdraw
    );

    // from received amounts after withdraw calculate how much we receive from converter for them in terms of the underlying asset
    expectedMainAssetAmounts = getExpectedAmountMainAsset(
      tokens,
      indexAsset,
      converter,
      expectedWithdrawAmounts,
      amountsToConvert
    );

    uint len = tokens.length;
    for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
      amountsToConvert[i] += withdrawnAmounts[i];
    }

    return (expectedMainAssetAmounts, amountsToConvert);
  }

  /// @notice return {withdrawnAmounts} with zero values and expected amount calculated using {amountsToConvert_}
  function postWithdrawActionsEmpty(
    ITetuConverter converter,
    address[] memory tokens,
    uint indexAsset,
    uint[] memory amountsToConvert_
  ) external returns (
    uint[] memory expectedAmountsMainAsset
  ) {
    expectedAmountsMainAsset = getExpectedAmountMainAsset(
      tokens,
      indexAsset,
      converter,
      // there are no withdrawn amounts
      new uint[](tokens.length), // array with all zero values
      amountsToConvert_
    );
  }

  //endregion Withdraw helpers

  /////////////////////////////////////////////////////////////////////
  //region convertAfterWithdraw
  /////////////////////////////////////////////////////////////////////

  /// @notice Convert {amountsToConvert_} (available on balance) to the main asset
  ///         Swap leftovers if any.
  ///         Result amount can be less than requested one, we don't try to close any other debts here
  /// @param indexAsset Index of the main asset in {tokens}
  /// @param liquidationThreshold Min allowed amount of main asset to be liquidated in {liquidator}
  /// @param tokens Tokens received from {_depositorPoolAssets}
  /// @param amountsToConvert Amounts to convert, the order of asset is same as in {tokens}
  /// @return collateralOut Total amount of main asset returned after closing positions
  /// @return repaidAmountsOut What amounts were spent in exchange of the {collateralOut}
  function _convertAfterWithdraw(
    ITetuConverter tetuConverter,
    ITetuLiquidator liquidator,
    uint indexAsset,
    uint liquidationThreshold,
    address[] memory tokens,
    uint[] memory amountsToConvert
  ) internal returns (
    uint collateralOut,
    uint[] memory repaidAmountsOut
  ) {
    ConvertAfterWithdrawLocal memory v;
    v.asset = tokens[indexAsset];
    v.balanceBefore = IERC20(v.asset).balanceOf(address(this));
    v.len = tokens.length;

    // Close positions to convert all required amountsToConvert
    repaidAmountsOut = new uint[](tokens.length);
    for (uint i; i < v.len; i = AppLib.uncheckedInc(i)) {
      if (i == indexAsset || amountsToConvert[i] == 0) continue;
      (, repaidAmountsOut[i]) = _closePosition(tetuConverter, v.asset, tokens[i], amountsToConvert[i]);
    }

    // Manually swap remain leftovers
    for (uint i; i < v.len; i = AppLib.uncheckedInc(i)) {
      if (i == indexAsset || amountsToConvert[i] == 0) continue;
      if (amountsToConvert[i] > repaidAmountsOut[i]) {
        (v.spent, v.received) = _liquidate(
          tetuConverter,
          liquidator,
          tokens[i],
          v.asset,
          amountsToConvert[i] - repaidAmountsOut[i],
          _ASSET_LIQUIDATION_SLIPPAGE,
          liquidationThreshold,
          false
        );
        collateralOut += v.received;
        repaidAmountsOut[i] += v.spent;
      }
    }

    // Calculate amount of received collateral
    v.balance = IERC20(v.asset).balanceOf(address(this));
    collateralOut = v.balance > v.balanceBefore
      ? v.balance - v.balanceBefore
      : 0;

    return (collateralOut, repaidAmountsOut);
  }

  /// @notice Close debts (if it's allowed) in converter until we don't have {requestedAmount} on balance
  /// @dev We assume here that this function is called before closing any positions in the current block
  /// @param liquidationThresholds Min allowed amounts-out for liquidations
  /// @param requestedAmount Requested amount of main asset that should be added to the current balance
  /// @return expectedAmount Main asset amount expected to be received on balance after all conversions and swaps
  function closePositionsToGetAmount(
    ITetuConverter converter_,
    ITetuLiquidator liquidator,
    uint indexAsset,
    mapping(address => uint) storage liquidationThresholds,
    uint requestedAmount,
    address[] memory tokens
  ) external returns (
    uint expectedAmount
  ) {
    return _closePositionsToGetAmount(
      converter_,
      liquidator,
      indexAsset,
      liquidationThresholds,
      requestedAmount,
      tokens
    );
  }

  function _closePositionsToGetAmount(
    ITetuConverter converter_,
    ITetuLiquidator liquidator,
    uint indexAsset,
    mapping(address => uint) storage liquidationThresholds,
    uint requestedAmount,
    address[] memory tokens
  ) internal returns (
    uint expectedAmount
  ) {
    if (requestedAmount != 0) {
      CloseDebtsForRequiredAmountLocal memory v;
      v.asset = tokens[indexAsset];
      v.len = tokens.length;
      v.balance = IERC20(v.asset).balanceOf(address(this));

      for (uint i; i < v.len; i = AppLib.uncheckedInc(i)) {
        if (i == indexAsset) continue;

        // we need to increase balance on the following amount: requestedAmount - v.balance;
        // we have following borrow: amount-to-pay and corresponded collateral
        (v.totalDebt, v.totalCollateral) = converter_.getDebtAmountCurrent(address(this), v.asset, tokens[i], true);

        uint tokenBalance = IERC20(tokens[i]).balanceOf(address(this));

        if (v.totalDebt != 0 || tokenBalance != 0) {
          //lazy initialization of the prices and decs
          if (v.prices.length == 0) {
            (v.prices, v.decs) = _getPricesAndDecs(
              IPriceOracle(IConverterController(converter_.controller()).priceOracle()),
              tokens,
              v.len
            );
          }

          // repay the debt if any
          if (v.totalDebt != 0) {
            // what amount of main asset we should sell to pay the debt
            uint toSell = _getAmountToSell(
              requestedAmount,
              v.totalDebt,
              v.totalCollateral,
              v.prices,
              v.decs,
              indexAsset,
              i,
              tokenBalance
            );

            // convert {toSell} amount of main asset to tokens[i]
            if (toSell != 0 && v.balance != 0) {
              toSell = Math.min(toSell, v.balance);
              (toSell,) = _liquidate(
                converter_,
                liquidator,
                v.asset,
                tokens[i],
                toSell,
                _ASSET_LIQUIDATION_SLIPPAGE,
                liquidationThresholds[tokens[i]],
                false
              );
              tokenBalance = IERC20(tokens[i]).balanceOf(address(this));
            }

            // sell {toSell}, repay the debt, return collateral back; we should receive amount > toSell
            expectedAmount += _repayDebt(converter_, v.asset, tokens[i], tokenBalance) - toSell;

            // we can have some leftovers after closing the debt
            tokenBalance = IERC20(tokens[i]).balanceOf(address(this));
          }

          // directly swap leftovers
          if (tokenBalance != 0) {
            (uint spentAmountIn,) = _liquidate(
              converter_,
              liquidator,
              tokens[i],
              v.asset,
              tokenBalance,
              _ASSET_LIQUIDATION_SLIPPAGE,
              liquidationThresholds[v.asset],
              false
            );
            if (spentAmountIn != 0) {
              // spentAmountIn can be zero if token balance is less than liquidationThreshold
              expectedAmount += spentAmountIn * v.prices[i] * v.decs[indexAsset] / v.prices[indexAsset] / v.decs[i];
            }
          }

          // reduce of requestedAmount on the balance increment
          v.newBalance = IERC20(v.asset).balanceOf(address(this));
          require(v.newBalance >= v.balance, AppErrors.BALANCE_DECREASE);

          if (requestedAmount > v.newBalance - v.balance) {
            requestedAmount -= (v.newBalance - v.balance);
            v.balance = v.newBalance;
          } else {
            // we get requestedAmount on the balance and don't need to make any other conversions
            break;
          }
        }
      }
    }

    return expectedAmount;
  }

  /// @notice What amount of collateral should be sold to pay the debt and receive {requestedAmount}
  /// @dev It doesn't allow to sell more than the amount of total debt in the borrow
  /// @param requestedAmount We need to increase balance (of collateral asset) on this amount
  /// @param totalDebt Total debt of the borrow in terms of borrow asset
  /// @param totalCollateral Total collateral of the borrow in terms of collateral asset
  /// @param prices Cost of $1 in terms of the asset, decimals 18
  /// @param decs 10**decimals for each asset
  /// @param indexCollateral Index of the collateral asset in {prices} and {decs}
  /// @param indexBorrowAsset Index of the borrow asset in {prices} and {decs}
  /// @param balanceBorrowAsset Available balance of the borrow asset, it will be used to cover the debt
  function _getAmountToSell(
    uint requestedAmount,
    uint totalDebt,
    uint totalCollateral,
    uint[] memory prices,
    uint[] memory decs,
    uint indexCollateral,
    uint indexBorrowAsset,
    uint balanceBorrowAsset
  ) internal pure returns (
    uint amountOut
  ) {
    if (totalDebt != 0) {
      if (balanceBorrowAsset != 0) {
        // there is some borrow asset on balance
        // it will be used to cover the debt
        // let's reduce the size of totalDebt/Collateral to exclude balanceBorrowAsset
        uint sub = Math.min(balanceBorrowAsset, totalDebt);
        totalCollateral -= totalCollateral * sub / totalDebt;
        totalDebt -= sub;
      }

      // for definiteness: usdc - collateral asset, dai - borrow asset
      // Pc = price of the USDC, Pb = price of the DAI, alpha = Pc / Pb [DAI / USDC]
      // S [USDC] - amount to sell, R [DAI] = alpha * S - amount to repay
      // After repaying R we get: alpha * S * C / R
      // Balance should be increased on: requestedAmount = alpha * S * C / R - S
      // So, we should sell: S = requestedAmount / (alpha * C / R - 1))
      // We can lost some amount on liquidation of S => R, so we need to use some gap = {GAP_AMOUNT_TO_SELL}
      // Same formula: S * h = S + requestedAmount, where h = health factor => s = requestedAmount / (h - 1)
      // h = alpha * C / R
      uint alpha18 = prices[indexCollateral] * decs[indexBorrowAsset] * 1e18
        / prices[indexBorrowAsset] / decs[indexCollateral];

      // if totalCollateral is zero (liquidation happens) we will have zero amount (the debt shouldn't be paid)
      amountOut = totalDebt != 0 && alpha18 * totalCollateral / totalDebt > 1e18
        ? Math.min(requestedAmount, totalCollateral) * 1e18 / (alpha18 * totalCollateral / totalDebt - 1e18)
        : 0;

      if (amountOut != 0) {
        // we shouldn't try to sell amount greater than amount of totalDebt in terms of collateral asset
        // but we always asks +1% because liquidation results can be different a bit from expected
        amountOut = (GAP_CONVERSION + DENOMINATOR) * Math.min(amountOut, totalDebt * 1e18 / alpha18) / DENOMINATOR;
      }
    }

    return amountOut;
  }

  /// @notice Repay {amountIn} and get collateral in return, calculate expected amount
  ///         Take into account possible debt-gap and the fact that the amount of debt may be less than {amountIn}
  /// @param amountToRepay Max available amount of borrow asset that we can repay
  /// @return expectedAmountOut Estimated amount of main asset that should be added to balance = collateral - {toSell}
  function _repayDebt(
    ITetuConverter converter,
    address collateralAsset,
    address borrowAsset,
    uint amountToRepay
  ) internal returns (
    uint expectedAmountOut
  ) {
    uint balanceBefore = IERC20(borrowAsset).balanceOf(address(this));

    // get amount of debt with debt-gap
    (uint needToRepay,) = converter.getDebtAmountCurrent(address(this), collateralAsset, borrowAsset, true);
    uint amountRepay = Math.min(amountToRepay < needToRepay ? amountToRepay : needToRepay, balanceBefore);

    // get expected amount without debt-gap
    uint swappedAmountOut;
    (expectedAmountOut, swappedAmountOut) = converter.quoteRepay(address(this), collateralAsset, borrowAsset, amountRepay);

    if (expectedAmountOut > swappedAmountOut) {
      // Following situation is possible
      //    needToRepay = 100, needToRepayExact = 90 (debt gap is 10)
      //    1) amountRepay = 80
      //       expectedAmountOut is calculated for 80, no problems
      //    2) amountRepay = 99,
      //       expectedAmountOut is calculated for 90 + 9 (90 - repay, 9 - direct swap)
      //       expectedAmountOut must be reduced on 9 here (!)
      expectedAmountOut -= swappedAmountOut;
    }

    // close the debt
    _closePositionExact(converter, collateralAsset, borrowAsset, amountRepay, balanceBefore);

    return expectedAmountOut;
  }
  //endregion convertAfterWithdraw

  /////////////////////////////////////////////////////////////////////
  //region Other helpers
  /////////////////////////////////////////////////////////////////////

  function getAssetPriceFromConverter(ITetuConverter converter, address token) external view returns (uint) {
    return IPriceOracle(IConverterController(converter.controller()).priceOracle()).getAssetPrice(token);
  }

  function registerIncome(uint assetBefore, uint assetAfter) internal pure returns (uint earned, uint lost) {
    if (assetAfter > assetBefore) {
      earned = assetAfter - assetBefore;
    } else {
      lost = assetBefore - assetAfter;
    }
    return (earned, lost);
  }

  /// @notice Register income and cover possible loss
  function coverPossibleStrategyLoss(uint assetBefore, uint assetAfter, address splitter) external returns (uint earned) {
    uint lost;
    (earned, lost) = ConverterStrategyBaseLib.registerIncome(assetBefore, assetAfter);
    if (lost != 0) {
      ISplitter(splitter).coverPossibleStrategyLoss(earned, lost);
    }
    emit FixPriceChanges(assetBefore, assetAfter);
  }

  //endregion Other helpers
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@tetu_io/tetu-contracts-v2/contracts/interfaces/IForwarder.sol";
import "@tetu_io/tetu-contracts-v2/contracts/interfaces/ITetuVaultV2.sol";
import "@tetu_io/tetu-contracts-v2/contracts/interfaces/ISplitter.sol";
import "@tetu_io/tetu-contracts-v2/contracts/strategy/StrategyLib.sol";
import "@tetu_io/tetu-converter/contracts/interfaces/IPriceOracle.sol";
import "@tetu_io/tetu-converter/contracts/interfaces/ITetuConverter.sol";
import "@tetu_io/tetu-contracts-v2/contracts/openzeppelin/Math.sol";
import "@tetu_io/tetu-contracts-v2/contracts/interfaces/ITetuLiquidator.sol";
import "../libs/AppErrors.sol";
import "../libs/AppLib.sol";
import "../libs/TokenAmountsLib.sol";
import "../libs/ConverterEntryKinds.sol";

/// @notice Continuation of ConverterStrategyBaseLib (workaround for size limits)
library ConverterStrategyBaseLib2 {
  using SafeERC20 for IERC20;

  /////////////////////////////////////////////////////////////////////
  ///                        DATA TYPES
  /////////////////////////////////////////////////////////////////////

  /////////////////////////////////////////////////////////////////////
  ///                        CONSTANTS
  /////////////////////////////////////////////////////////////////////

  uint internal constant DENOMINATOR = 100_000;

  /// @dev 0.5% of max profit for strategy TVL
  /// @notice Limit max amount of profit that can be send to insurance after price changing
  uint public constant PRICE_CHANGE_PROFIT_TOLERANCE = 500;

  /////////////////////////////////////////////////////////////////////
  ///                        EVENTS
  /////////////////////////////////////////////////////////////////////

  event OnChangePerformanceFeeRatio(uint newRatio);
  event LiquidationThresholdChanged(address token, uint amount);
  event ReinvestThresholdPercentChanged(uint amount);

  /////////////////////////////////////////////////////////////////////
  ///                        MAIN LOGIC
  /////////////////////////////////////////////////////////////////////

  /// @notice Get balances of the {tokens_} except balance of the token at {indexAsset} position
  function getAvailableBalances(
    address[] memory tokens_,
    uint indexAsset
  ) external view returns (uint[] memory) {
    uint len = tokens_.length;
    uint[] memory amountsToConvert = new uint[](len);
    for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
      if (i == indexAsset) continue;
      amountsToConvert[i] = IERC20(tokens_[i]).balanceOf(address(this));
    }
    return amountsToConvert;
  }

  /// @notice Send {amount_} of {asset_} to {receiver_} and insurance
  /// @param asset_ Underlying asset
  /// @param amount_ Amount of underlying asset to be sent to
  /// @param receiver_ Performance receiver
  /// @param ratio [0..100_000], 100_000 - send full amount to perf, 0 - send full amount to the insurance.
  function sendPerformanceFee(address asset_, uint amount_, address splitter, address receiver_, uint ratio) external returns (
    uint toPerf,
    uint toInsurance
  ) {
    // read inside lib for reduce contract space in the main contract
    address insurance = address(ITetuVaultV2(ISplitter(splitter).vault()).insurance());

    toPerf = amount_ * ratio / DENOMINATOR;
    toInsurance = amount_ - toPerf;

    if (toPerf != 0) {
      IERC20(asset_).safeTransfer(receiver_, toPerf);
    }
    if (toInsurance != 0) {
      IERC20(asset_).safeTransfer(insurance, toInsurance);
    }
  }

  function sendTokensToForwarder(
    address controller_,
    address splitter_,
    address[] memory tokens_,
    uint[] memory amounts_
  ) external {
    uint len = tokens_.length;
    IForwarder forwarder = IForwarder(IController(controller_).forwarder());
    for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
      AppLib.approveIfNeeded(tokens_[i], amounts_[i], address(forwarder));
    }

    (tokens_, amounts_) = TokenAmountsLib.filterZeroAmounts(tokens_, amounts_);
    forwarder.registerIncome(tokens_, amounts_, ISplitter(splitter_).vault(), true);
  }

  /// @notice For each {token_} calculate a part of {amount_} to be used as collateral according to the weights.
  ///         I.e. we have 300 USDC, we need to split it on 100 USDC, 100 USDT, 100 DAI
  ///         USDC is main asset, USDT and DAI should be borrowed. We check amounts of USDT and DAI on the balance
  ///         and return collaterals reduced on that amounts. For main asset, we return full amount always (100 USDC).
  /// @return tokenAmountsOut Length of the array is equal to the length of {tokens_}
  function getCollaterals(
    uint amount_,
    address[] memory tokens_,
    uint[] memory weights_,
    uint totalWeight_,
    uint indexAsset_,
    IPriceOracle priceOracle
  ) external view returns (
    uint[] memory tokenAmountsOut
  ) {
    uint len = tokens_.length;
    tokenAmountsOut = new uint[](len);

    // get token prices and decimals
    uint[] memory prices = new uint[](len);
    uint[] memory decs = new uint[](len);
    for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
      decs[i] = 10 ** IERC20Metadata(tokens_[i]).decimals();
      prices[i] = priceOracle.getAssetPrice(tokens_[i]);
    }

    // split the amount on tokens proportionally to the weights
    for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
      uint amountAssetForToken = amount_ * weights_[i] / totalWeight_;

      if (i == indexAsset_) {
        tokenAmountsOut[i] = amountAssetForToken;
      } else {
        // if we have some tokens on balance then we need to use only a part of the collateral
        uint tokenAmountToBeBorrowed = amountAssetForToken
          * prices[indexAsset_]
          * decs[i]
          / prices[i]
          / decs[indexAsset_];

        uint tokenBalance = IERC20(tokens_[i]).balanceOf(address(this));
        if (tokenBalance < tokenAmountToBeBorrowed) {
          tokenAmountsOut[i] = amountAssetForToken * (tokenAmountToBeBorrowed - tokenBalance) / tokenAmountToBeBorrowed;
        }
      }
    }
  }

  /// @notice Calculate amount of liquidity that should be withdrawn from the pool to get {targetAmount_}
  ///               liquidityAmount = _depositorLiquidity() * {liquidityRatioOut} / 1e18
  ///         User needs to withdraw {targetAmount_} in main asset.
  ///         There are two kinds of available liquidity:
  ///         1) liquidity in the pool - {depositorLiquidity_}
  ///         2) Converted amounts on balance of the strategy - {baseAmounts_}
  ///         To withdraw {targetAmount_} we need
  ///         1) Reconvert converted amounts back to main asset
  ///         2) IF result amount is not necessary - withdraw some liquidity from the pool
  ///            and also convert it to the main asset.
  /// @dev This is a writable function with read-only behavior (because of the quote-call)
  /// @param targetAmount_ Required amount of main asset to be withdrawn from the strategy; 0 - withdraw all
  /// @param strategy_ Address of the strategy
  /// @return resultAmount Amount of liquidity that should be withdrawn from the pool, cannot exceed depositorLiquidity
  /// @return amountsToConvertOut Amounts of {tokens} that should be converted to the main asset
  function getLiquidityAmount(
    uint targetAmount_,
    address strategy_,
    address[] memory tokens,
    uint indexAsset,
    ITetuConverter converter,
    uint investedAssets,
    uint depositorLiquidity
  ) external returns (
    uint resultAmount,
    uint[] memory amountsToConvertOut
  ) {
    bool all = targetAmount_ == 0;

    uint len = tokens.length;
    amountsToConvertOut = new uint[](len);
    for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
      if (i == indexAsset) continue;

      uint balance = IERC20(tokens[i]).balanceOf(address(this));
      if (balance != 0) {
        // let's estimate collateral that we received back after repaying balance-amount
        (uint expectedCollateral,) = converter.quoteRepay(strategy_, tokens[indexAsset], tokens[i], balance);

        if (all || targetAmount_ != 0) {
          // We always repay WHOLE available balance-amount even if it gives us much more amount then we need.
          // We cannot repay a part of it because converter doesn't allow to know
          // what amount should be repaid to get given amount of collateral.
          // And it's too dangerous to assume that we can calculate this amount
          // by reducing balance-amount proportionally to expectedCollateral/targetAmount_
          amountsToConvertOut[i] = balance;
        }

        targetAmount_ = targetAmount_ > expectedCollateral
          ? targetAmount_ - expectedCollateral
          : 0;

        investedAssets = investedAssets > expectedCollateral
          ? investedAssets - expectedCollateral
          : 0;
      }
    }

    uint liquidityRatioOut = all || investedAssets == 0
      ? 1e18
      : ((targetAmount_ == 0)
        ? 0
        : 1e18
        * 101 // add 1% on top...
        * targetAmount_ / investedAssets // a part of amount that we are going to withdraw
        / 100 // .. add 1% on top
      );

    resultAmount = liquidityRatioOut != 0
      ? Math.min(liquidityRatioOut * depositorLiquidity / 1e18, depositorLiquidity)
      : 0;
  }

  /// @notice Claim rewards from tetuConverter, generate result list of all available rewards and airdrops
  /// @dev The post-processing is rewards conversion to the main asset
  /// @param tokens_ tokens received from {_depositorPoolAssets}
  /// @param rewardTokens_ List of rewards claimed from the internal pool
  /// @param rewardTokens_ Amounts of rewards claimed from the internal pool
  /// @param tokensOut List of available rewards - not zero amounts, reward tokens don't repeat
  /// @param amountsOut Amounts of available rewards
  function claimConverterRewards(
    ITetuConverter converter_,
    address[] memory tokens_,
    address[] memory rewardTokens_,
    uint[] memory rewardAmounts_,
    uint[] memory balancesBefore
  ) external returns (
    address[] memory tokensOut,
    uint[] memory amountsOut
  ) {
    // Rewards from TetuConverter
    (address[] memory tokensTC, uint[] memory amountsTC) = converter_.claimRewards(address(this));

    // Join arrays and recycle tokens
    (tokensOut, amountsOut) = TokenAmountsLib.combineArrays(
      rewardTokens_, rewardAmounts_,
      tokensTC, amountsTC,
      // by default, depositor assets have zero amounts here
      tokens_, new uint[](tokens_.length)
    );

    // set fresh balances for depositor tokens
    uint len = tokensOut.length;
    for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
      for (uint j; j < tokens_.length; j = AppLib.uncheckedInc(j)) {
        if (tokensOut[i] == tokens_[j]) {
          amountsOut[i] = IERC20(tokens_[j]).balanceOf(address(this)) - balancesBefore[j];
        }
      }
    }

    // filter zero amounts out
    (tokensOut, amountsOut) = TokenAmountsLib.filterZeroAmounts(tokensOut, amountsOut);
  }

  /// @notice Send given amount of underlying to the insurance
  /// @param strategyBalance Total strategy balance = balance of underlying + current invested assets amount
  /// @return Amount of underlying sent to the insurance
  function sendToInsurance(address asset, uint amount, address splitter, uint strategyBalance) external returns (uint) {
    uint amountToSend = Math.min(amount, IERC20(asset).balanceOf(address(this)));
    if (amountToSend != 0) {
      // max amount that can be send to insurance is limited by PRICE_CHANGE_PROFIT_TOLERANCE

      // Amount limitation should be implemented in the same way as in StrategySplitterV2._coverLoss
      // Revert or cutting amount in both cases

      // amountToSend = Math.min(amountToSend, PRICE_CHANGE_PROFIT_TOLERANCE * strategyBalance / 100_000);
      require(strategyBalance != 0, AppErrors.ZERO_BALANCE);
      require(amountToSend <= PRICE_CHANGE_PROFIT_TOLERANCE * strategyBalance / 100_000, AppErrors.EARNED_AMOUNT_TOO_HIGH);
      IERC20(asset).safeTransfer(address(ITetuVaultV2(ISplitter(splitter).vault()).insurance()), amountToSend);
    }
    return amountToSend;
  }

  //region ---------------------------------------- Setters
  function checkPerformanceFeeRatioChanged(address controller, uint ratio_) external {
    StrategyLib.onlyOperators(controller);
    require(ratio_ <= DENOMINATOR, StrategyLib.WRONG_VALUE);
    emit OnChangePerformanceFeeRatio(ratio_);
  }

  function checkReinvestThresholdPercentChanged(address controller, uint percent_) external {
    StrategyLib.onlyOperators(controller);
    require(percent_ <= DENOMINATOR, StrategyLib.WRONG_VALUE);
    emit ReinvestThresholdPercentChanged(percent_);
  }

  function checkLiquidationThresholdChanged(address controller, address token, uint amount) external {
    StrategyLib.onlyOperators(controller);
    emit LiquidationThresholdChanged(token, amount);
  }
  //endregion ---------------------------------------- Setters

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Abstract base Depositor contract.
/// @notice Converter strategies should inherit xDepositor.
/// @notice All communication with external pools should be done at inherited contract
/// @author bogdoslav
abstract contract DepositorBase {

  /// @notice Returns pool assets
  function _depositorPoolAssets() internal virtual view returns (address[] memory assets);

  /// @notice Returns pool token proportions
  function _depositorPoolWeights() internal virtual view returns (uint[] memory weights, uint total);

  /// @notice Returns pool token reserves
  function _depositorPoolReserves() internal virtual view returns (uint[] memory reserves);

  /// @notice Returns depositor's pool shares / lp token amount
  function _depositorLiquidity() internal virtual view returns (uint);

  //// @notice Total amount of LP tokens in the depositor
  function _depositorTotalSupply() internal view virtual returns (uint);

  /// @notice Deposit given amount to the pool.
  /// @dev Depositor must care about tokens approval by itself.
  function _depositorEnter(uint[] memory amountsDesired_) internal virtual returns (
    uint[] memory amountsConsumed,
    uint liquidityOut
  );

  /// @notice Withdraw given lp amount from the pool.
  /// @param liquidityAmount Amount of liquidity to be converted
  ///                        If requested liquidityAmount >= invested, then should make full exit.
  /// @return amountsOut The order of amounts is the same as in {_depositorPoolAssets}
  function _depositorExit(uint liquidityAmount) internal virtual returns (uint[] memory amountsOut);

  /// @notice Quotes output for given lp amount from the pool.
  /// @dev Write function with read-only behavior. BalanceR's depositor requires not-view.
  /// @param liquidityAmount Amount of liquidity to be converted
  ///                        If requested liquidityAmount >= invested, then should make full exit.
  /// @return amountsOut The order of amounts is the same as in {_depositorPoolAssets}
  function _depositorQuoteExit(uint liquidityAmount) internal virtual returns (uint[] memory amountsOut);

  /// @dev If pool supports emergency withdraw need to call it for emergencyExit()
  /// @return amountsOut The order of amounts is the same as in {_depositorPoolAssets}
  function _depositorEmergencyExit() internal virtual returns (uint[] memory amountsOut) {
    return _depositorExit(_depositorLiquidity());
  }

  /// @notice Claim all possible rewards.
  /// @return rewardTokens Claimed token addresses
  /// @return rewardAmounts Claimed token amounts
  /// @return depositorBalancesBefore Must have the same length as _depositorPoolAssets and represent balances before claim in the same order
  function _depositorClaimRewards() internal virtual returns (
    address[] memory rewardTokens,
    uint[] memory rewardAmounts,
    uint[] memory depositorBalancesBefore
  );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../ConverterStrategyBase.sol";
import "./KyberDepositor.sol";
import "./KyberConverterStrategyLogicLib.sol";
import "../../libs/AppPlatforms.sol";
import "../../interfaces/IRebalancingStrategy.sol";
import "../../interfaces/IFarmingStrategy.sol";
import "./KyberStrategyErrors.sol";


contract KyberConverterStrategy is KyberDepositor, ConverterStrategyBase, IRebalancingStrategy, IFarmingStrategy {

  /////////////////////////////////////////////////////////////////////
  ///                CONSTANTS
  /////////////////////////////////////////////////////////////////////

  string public constant override NAME = "Kyber Converter Strategy";
  string public constant override PLATFORM = AppPlatforms.KYBER;
  string public constant override STRATEGY_VERSION = "1.0.1";

  /////////////////////////////////////////////////////////////////////
  ///                INIT
  /////////////////////////////////////////////////////////////////////

  /// @notice Initialize the strategy with the given parameters.
  /// @param controller_ The address of the controller.
  /// @param splitter_ The address of the splitter.
  /// @param converter_ The address of the converter.
  /// @param pool_ The address of the pool.
  /// @param tickRange_ The tick range for the liquidity position.
  /// @param rebalanceTickRange_ The tick range for rebalancing.
  function init(
    address controller_,
    address splitter_,
    address converter_,
    address pool_,
    int24 tickRange_,
    int24 rebalanceTickRange_,
    bool isStablePool,
    uint pId
  ) external initializer {
    __ConverterStrategyBase_init(controller_, splitter_, converter_);
    KyberConverterStrategyLogicLib.initStrategyState(
      state,
      controller_,
      converter_,
      pool_,
      tickRange_,
      rebalanceTickRange_,
      ISplitter(splitter_).asset(),
      isStablePool
    );

    state.pId = pId;

    // setup specific name for UI
    strategySpecificName = KyberConverterStrategyLogicLib.createSpecificName(state);
    emit StrategyLib.StrategySpecificNameChanged(strategySpecificName);
  }

  /////////////////////////////////////////////////////////////////////
  ///                OPERATOR ACTIONS
  /////////////////////////////////////////////////////////////////////

  /// @notice Disable fuse for the strategy.
  function disableFuse() external {
    StrategyLib.onlyOperators(controller());
    state.isFuseTriggered = false;
    state.lastPrice = ConverterStrategyBaseLib.getOracleAssetsPrice(converter, state.tokenA, state.tokenB);

    KyberConverterStrategyLogicLib.emitDisableFuse();
  }

  function changePId(uint pId) external {
    StrategyLib.onlyOperators(controller());
    require(!state.staked, KyberStrategyErrors.NOT_UNSTAKED);
    state.pId = pId;
  }

  /// @notice Set the fuse threshold for the strategy.
  /// @param newFuseThreshold The new fuse threshold value.
  function setFuseThreshold(uint newFuseThreshold) external {
    StrategyLib.onlyOperators(controller());
    state.fuseThreshold = newFuseThreshold;

    KyberConverterStrategyLogicLib.emitNewFuseThreshold(newFuseThreshold);
  }

  function setStrategyProfitHolder(address strategyProfitHolder) external {
    StrategyLib.onlyOperators(controller());
    state.strategyProfitHolder = strategyProfitHolder;
  }

  /////////////////////////////////////////////////////////////////////
  ///                   METRIC VIEWS
  /////////////////////////////////////////////////////////////////////

  /// @notice Check if the strategy needs rebalancing.
  /// @return A boolean indicating if the strategy needs rebalancing.
  function needRebalance() public view returns (bool) {
    (bool needStake, bool needUnstake) = KyberConverterStrategyLogicLib.needRebalanceStaking(state);
    return KyberConverterStrategyLogicLib.needRebalance(state) || needStake || needUnstake;
  }

  /// @return swapAtoB, swapAmount
  function quoteRebalanceSwap() external returns (bool, uint) {
    return KyberConverterStrategyLogicLib.quoteRebalanceSwap(state, converter);
  }

  function canFarm() external view returns (bool) {
    return !KyberConverterStrategyLogicLib.isFarmEnded(state.pId);
  }

  /////////////////////////////////////////////////////////////////////
  ///                   CALLBACKS
  /////////////////////////////////////////////////////////////////////

  function onERC721Received(
    address,
    address,
    uint256,
    bytes memory
  ) external pure returns (bytes4) {
    return this.onERC721Received.selector;
  }

  /////////////////////////////////////////////////////////////////////
  ///                   REBALANCE
  /////////////////////////////////////////////////////////////////////

  /// @dev The rebalancing functionality is the core of this strategy.
  ///      Swap method is used.
  function rebalance() external {
    (uint profitToCover, uint oldTotalAssets, address _controller) = _startRebalance();

    // _depositorEnter(tokenAmounts) if length == 2
    uint[] memory tokenAmounts = KyberConverterStrategyLogicLib.rebalance(
      state,
      converter,
      _controller,
      oldTotalAssets,
      profitToCover,
      splitter
    );

    if (tokenAmounts.length == 2) {
      _depositorEnter(tokenAmounts);
    }

    //updating investedAssets based on new baseAmounts
    _updateInvestedAssets();
  }

  function rebalanceSwapByAgg(bool direction, uint amount, address agg, bytes memory swapData) external {
    (uint profitToCover, uint oldTotalAssets,) = _startRebalance();

    // _depositorEnter(tokenAmounts) if length == 2
    uint[] memory tokenAmounts = KyberConverterStrategyLogicLib.rebalanceSwapByAgg(
      state,
      converter,
      oldTotalAssets,
      KyberConverterStrategyLogicLib.RebalanceSwapByAggParams(
        direction,
        amount,
        agg,
        swapData
      ),
      profitToCover,
      splitter
    );

    if (tokenAmounts.length == 2) {
      _depositorEnter(tokenAmounts);
    }

    //updating investedAssets based on new baseAmounts
    _updateInvestedAssets();
  }

  /////////////////////////////////////////////////////////////////////
  ///                   INTERNAL LOGIC
  /////////////////////////////////////////////////////////////////////

  function _startRebalance() internal returns(uint profitToCover, uint oldTotalAssets,  address _controller) {
    _controller = controller();
    StrategyLib.onlyOperators(_controller);

    require(needRebalance(), KyberStrategyErrors.NO_REBALANCE_NEEDED);

    (, profitToCover) = _fixPriceChanges(true);
    oldTotalAssets = totalAssets() - profitToCover;

    KyberConverterStrategyLogicLib.claimRewardsBeforeExitIfRequired(state);

    /// withdraw all liquidity from pool with adding calculated fees to rebalanceEarned0, rebalanceEarned1
    /// after disableFuse() liquidity is zero
    if (state.totalLiquidity > 0) {
      _depositorEmergencyExit();
    }
  }

  function _beforeDeposit(
    ITetuConverter tetuConverter_,
    uint amount_,
    address[] memory /*tokens_*/,
    uint /*indexAsset_*/
  ) override internal virtual returns (
    uint[] memory tokenAmounts
  ) {
    require(!needRebalance(), KyberStrategyErrors.NEED_REBALANCE);

    tokenAmounts = new uint[](2);
    uint spentCollateral;

    bytes memory entryData = KyberConverterStrategyLogicLib.getEntryData(
      state.pool,
      state.lowerTick,
      state.upperTick,
      state.depositorSwapTokens
    );

    AppLib.approveIfNeeded(state.tokenA, amount_, address(tetuConverter_));
    (spentCollateral, tokenAmounts[1]) = ConverterStrategyBaseLib.openPosition(
      tetuConverter_,
      entryData,
      state.tokenA,
      state.tokenB,
      amount_,
      0
    );

    tokenAmounts[0] = amount_ - spentCollateral;
  }

  /// @notice Claim rewards, do _processClaims() after claiming, calculate earned and lost amounts
  /// @return earned The amount of earned rewards.
  /// @return lost The amount of lost rewards.
  /// @return assetBalanceAfterClaim The asset balance after claiming rewards.
  function _handleRewards() override internal virtual returns (uint earned, uint lost, uint assetBalanceAfterClaim) {
    (address[] memory rewardTokens, uint[] memory amounts) = _claim();
    earned = KyberConverterStrategyLogicLib.calcEarned(state.tokenA, controller(), rewardTokens, amounts);
    _rewardsLiquidation(rewardTokens, amounts);
    return (earned, lost, AppLib.balance(asset));
  }

  /// @notice Deposit given amount to the pool.
  /// @param amount_ The amount to be deposited.
  /// @param updateTotalAssetsBeforeInvest_ A boolean indicating if the total assets should be updated before investing.
  /// @return strategyLoss Loss should be covered from Insurance
  function _depositToPool(uint amount_, bool updateTotalAssetsBeforeInvest_) override internal virtual returns (
    uint strategyLoss
  ) {
    if (state.isFuseTriggered) {
      uint[] memory tokenAmounts = new uint[](2);
      tokenAmounts[0] = amount_;
      emit OnDepositorEnter(tokenAmounts, tokenAmounts);
      return 0;
    } else {
      return super._depositToPool(amount_, updateTotalAssetsBeforeInvest_);
    }
  }

  function _beforeWithdraw(uint /*amount*/) internal view override {
    require(!needRebalance(), KyberStrategyErrors.NEED_REBALANCE);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./KyberLib.sol";
import "./KyberDebtLib.sol";
import "./KyberStrategyErrors.sol";
import "@tetu_io/tetu-contracts-v2/contracts/lib/StringLib.sol";
import "@tetu_io/tetu-contracts-v2/contracts/openzeppelin/SafeERC20.sol";

library KyberConverterStrategyLogicLib {
  using SafeERC20 for IERC20;

  //////////////////////////////////////////
  //            CONSTANTS
  //////////////////////////////////////////

  uint internal constant LIQUIDATOR_SWAP_SLIPPAGE_STABLE = 300;
  uint internal constant LIQUIDATOR_SWAP_SLIPPAGE_VOLATILE = 500;
  /// @dev 0.5% by default
  uint internal constant DEFAULT_FUSE_THRESHOLD = 5e15;
  IBasePositionManager internal constant KYBER_NFT = IBasePositionManager(0xe222fBE074A436145b255442D919E4E3A6c6a480);
  IKyberSwapElasticLM internal constant FARMING_CENTER = IKyberSwapElasticLM(0x7D5ba536ab244aAA1EA42aB88428847F25E3E676);
  ITicksFeesReader internal constant TICKS_FEES_READER = ITicksFeesReader(0x8Fd8Cb948965d9305999D767A02bf79833EADbB3);
  address public constant KNC = 0x1C954E8fe737F99f68Fa1CCda3e51ebDB291948C;

  //////////////////////////////////////////
  //            EVENTS
  //////////////////////////////////////////

  event FuseTriggered();
  event Rebalanced(uint loss, uint coveredByRewards);
  event DisableFuse();
  event NewFuseThreshold(uint newFuseThreshold);
  event KyberFeesClaimed(uint fee0, uint fee1);
  event KyberRewardsClaimed(uint reward);

  //////////////////////////////////////////
  //            STRUCTURES
  //////////////////////////////////////////

  struct State {
    address strategyProfitHolder;
    address tokenA;
    address tokenB;
    IPool pool;
    int24 tickSpacing;
    bool isStablePool;
    int24 lowerTick;
    int24 upperTick;
    int24 rebalanceTickRange;
    bool depositorSwapTokens;
    uint128 totalLiquidity;
    bool isFuseTriggered;
    uint fuseThreshold;
    uint lastPrice;
    uint tokenId;
    // farming
    uint pId;
    bool staked;
  }

  struct RebalanceSwapByAggParams {
    bool direction;
    uint amount;
    address agg;
    bytes swapData;
  }

  struct RebalanceLocalVariables {
    int24 upperTick;
    int24 lowerTick;
    int24 tickSpacing;
    IPool pool;
    address tokenA;
    address tokenB;
    uint lastPrice;
    uint fuseThreshold;
    bool depositorSwapTokens;
    uint notCoveredLoss;
    int24 newLowerTick;
    int24 newUpperTick;
    bool isStablePool;
    uint newPrice;
    uint newTotalAssets;
    bool needRebalance;
  }

  struct EnterLocalVariables {
    IPool pool;
    int24 upperTick;
    int24 lowerTick;
    uint tokenId;
    uint pId;
  }

  struct ExitLocalVariables {
    address strategyProfitHolder;
    uint pId;
    address tokenA;
    address tokenB;
  }

  //////////////////////////////////////////
  //            HELPERS
  //////////////////////////////////////////

  function emitDisableFuse() external {
    emit DisableFuse();
  }

  function emitNewFuseThreshold(uint value) external {
    emit NewFuseThreshold(value);
  }

  /// @notice Check if the fuse is enabled based on the price difference and fuse threshold.
  /// @param oldPrice The old price.
  /// @param newPrice The new price.
  /// @param fuseThreshold The fuse threshold.
  /// @return A boolean indicating if the fuse is enabled.
  function isEnableFuse(uint oldPrice, uint newPrice, uint fuseThreshold) internal pure returns (bool) {
    return oldPrice > newPrice ? (oldPrice - newPrice) > fuseThreshold : (newPrice - oldPrice) > fuseThreshold;
  }

  function initStrategyState(
    State storage state,
    address controller_,
    address converter,
    address pool,
    int24 tickRange,
    int24 rebalanceTickRange,
    address asset_,
    bool isStablePool
  ) external {
    require(pool != address(0), AppErrors.ZERO_ADDRESS);
    state.pool = IPool(pool);

    state.isStablePool = isStablePool;

    state.rebalanceTickRange = rebalanceTickRange;

    _setInitialDepositorValues(
      state,
      IPool(pool),
      tickRange,
      rebalanceTickRange,
      asset_
    );

    address liquidator = IController(controller_).liquidator();
    address tokenA = state.tokenA;
    address tokenB = state.tokenB;
    IERC20(tokenA).approve(liquidator, type(uint).max);
    IERC20(tokenB).approve(liquidator, type(uint).max);
    IERC20(tokenA).approve(address(KYBER_NFT), type(uint).max);
    IERC20(tokenB).approve(address(KYBER_NFT), type(uint).max);
    IERC721(address(KYBER_NFT)).setApprovalForAll(address(FARMING_CENTER), true);

    if (isStablePool) {
      /// for stable pools fuse can be enabled
      state.fuseThreshold = DEFAULT_FUSE_THRESHOLD;
      emit NewFuseThreshold(DEFAULT_FUSE_THRESHOLD);
      state.lastPrice = ConverterStrategyBaseLib.getOracleAssetsPrice(ITetuConverter(converter), tokenA, tokenB);
    }
  }

  function createSpecificName(State storage state) external view returns (string memory) {
    return string(abi.encodePacked("Kyber ", IERC20Metadata(state.tokenA).symbol(), "/", IERC20Metadata(state.tokenB).symbol()));
  }

  function getPoolReserves(State storage state) external view returns (uint[] memory reserves) {
    reserves = new uint[](2);
    (uint160 sqrtRatioX96, , ,) = state.pool.getPoolState();

    (reserves[0], reserves[1]) = KyberLib.getAmountsForLiquidity(
      sqrtRatioX96,
      state.lowerTick,
      state.upperTick,
      state.totalLiquidity
    );

    if (state.depositorSwapTokens) {
      (reserves[0], reserves[1]) = (reserves[1], reserves[0]);
    }
  }

  /// @dev Gets the liquidator swap slippage based on the pool type (stable or volatile).
  /// @return The liquidator swap slippage percentage.
  function _getLiquidatorSwapSlippage(bool isStablePool) internal pure returns (uint) {
    return isStablePool ? LIQUIDATOR_SWAP_SLIPPAGE_STABLE : LIQUIDATOR_SWAP_SLIPPAGE_VOLATILE;
  }

  //////////////////////////////////////////
  //            Pool info
  //////////////////////////////////////////

  function getEntryData(
    IPool pool,
    int24 lowerTick,
    int24 upperTick,
    bool depositorSwapTokens
  ) public view returns (bytes memory entryData) {
    return KyberDebtLib.getEntryData(pool, lowerTick, upperTick, depositorSwapTokens);
  }

  //////////////////////////////////////////
  //            CALCULATIONS
  //////////////////////////////////////////

  /// @notice Calculate and set the initial values for a QuickSwap V3 pool Depositor.
  /// @param state Depositor storage state struct
  /// @param pool The QuickSwap V3 pool to get the initial values from.
  /// @param tickRange_ The tick range for the pool.
  /// @param rebalanceTickRange_ The rebalance tick range for the pool.
  /// @param asset_ Underlying asset of the depositor.
  function _setInitialDepositorValues(
    State storage state,
    IPool pool,
    int24 tickRange_,
    int24 rebalanceTickRange_,
    address asset_
  ) internal {
    int24 tickSpacing = KyberLib.getTickSpacing(pool);
    if (tickRange_ != 0) {
      require(tickRange_ == tickRange_ / tickSpacing * tickSpacing, KyberStrategyErrors.INCORRECT_TICK_RANGE);
      require(rebalanceTickRange_ == rebalanceTickRange_ / tickSpacing * tickSpacing, KyberStrategyErrors.INCORRECT_REBALANCE_TICK_RANGE);
    }
    state.tickSpacing = tickSpacing;
    (state.lowerTick, state.upperTick) = KyberDebtLib.calcTickRange(pool, tickRange_, tickSpacing);
    address token0 = address(pool.token0());
    address token1 = address(pool.token1());
    require(asset_ == token0 || asset_ == token1, KyberStrategyErrors.INCORRECT_ASSET);
    if (asset_ == token0) {
      state.tokenA = token0;
      state.tokenB = token1;
      state.depositorSwapTokens = false;
    } else {
      state.tokenA = token1;
      state.tokenB = token0;
      state.depositorSwapTokens = true;
    }
  }

  //////////////////////////////////////////
  //            Joins to the pool
  //////////////////////////////////////////

  function enter(
    State storage state,
    uint[] memory amountsDesired_
  ) external returns (uint[] memory amountsConsumed, uint liquidityOut) {
    EnterLocalVariables memory vars = EnterLocalVariables({
      pool: state.pool,
      lowerTick : state.lowerTick,
      upperTick : state.upperTick,
      tokenId : state.tokenId,
      pId : state.pId
    });
    bool depositorSwapTokens = state.depositorSwapTokens;
    (address token0, address token1) = depositorSwapTokens ? (state.tokenB, state.tokenA) : (state.tokenA, state.tokenB);
    if (depositorSwapTokens) {
      (amountsDesired_[0], amountsDesired_[1]) = (amountsDesired_[1], amountsDesired_[0]);
    }
    amountsConsumed = new uint[](2);
    uint128 liquidity;

    if (vars.tokenId > 0) {
      (IBasePositionManager.Position memory pos,) = KYBER_NFT.positions(vars.tokenId);
      if (pos.tickLower != vars.lowerTick || pos.tickUpper != vars.upperTick) {
        KYBER_NFT.burn(vars.tokenId);
        vars.tokenId = 0;
      }
    }

    if (vars.tokenId == 0) {
      (vars.tokenId, liquidity, amountsConsumed[0], amountsConsumed[1]) = KYBER_NFT.mint(IBasePositionManager.MintParams(
        token0,
        token1,
        state.pool.swapFeeUnits(),
        vars.lowerTick,
        vars.upperTick,
        KyberLib.getPreviousTicks(vars.pool, vars.lowerTick, vars.upperTick),
        amountsDesired_[0],
        amountsDesired_[1],
        0,
        0,
        address(this),
        block.timestamp
      ));

      state.tokenId = vars.tokenId;

      {
        if (!isFarmEnded(vars.pId)) {
          uint[] memory nftIds = new uint[](1);
          nftIds[0] = vars.tokenId;
          uint[] memory liqs = new uint[](1);
          liqs[0] = uint(liquidity);
          FARMING_CENTER.deposit(nftIds);
          state.staked = true;
          FARMING_CENTER.join(vars.pId, nftIds, liqs);
        }
      }
    } else {
      (liquidity, amountsConsumed[0], amountsConsumed[1],) = KYBER_NFT.addLiquidity(IBasePositionManager.IncreaseLiquidityParams(
        vars.tokenId,
        KyberLib.getPreviousTicks(vars.pool, vars.lowerTick, vars.upperTick),
        amountsDesired_[0],
        amountsDesired_[1],
        0,
        0,
        block.timestamp
      ));

      if (!isFarmEnded(vars.pId)) {
        uint[] memory nftIds = new uint[](1);
        nftIds[0] = vars.tokenId;
        if (state.totalLiquidity == 0) {
          FARMING_CENTER.deposit(nftIds);
          state.staked = true;
        }

        uint[] memory liqs = new uint[](1);
        liqs[0] = uint(liquidity);
        FARMING_CENTER.join(vars.pId, nftIds, liqs);
      }
    }

    state.totalLiquidity += liquidity;
    liquidityOut = uint(liquidity);
  }

  //////////////////////////////////////////
  //            Exit from the pool
  //////////////////////////////////////////

  function exit(
    State storage state,
    uint128 liquidityAmountToExit
  ) external returns (uint[] memory amountsOut) {
    amountsOut = new uint[](2);

    ExitLocalVariables memory vars = ExitLocalVariables({
      strategyProfitHolder : state.strategyProfitHolder,
      pId : state.pId,
      tokenA : state.tokenA,
      tokenB : state.tokenB
    });

    uint128 liquidity = state.totalLiquidity;

    require(liquidity >= liquidityAmountToExit, KyberStrategyErrors.WRONG_LIQUIDITY);

    bool staked = state.staked;

    uint[] memory nftIds = new uint[](1);
    nftIds[0] = state.tokenId;
    uint[] memory liqs = new uint[](1);
    uint feeA;
    uint feeB;

    // get rewards
    if (staked) {
      uint reward = _harvest(nftIds[0], vars.pId);
      // send to profit holder
      if (reward > 0) {
        IERC20(KNC).safeTransfer(vars.strategyProfitHolder, reward);
      }

      // get fees
      // when exiting, fees are collected twice so as not to lose anything when rebalancing (the position goes out of range)
      (feeA, feeB) = _claimFees(state);

      liqs[0] = uint(liquidity);

      FARMING_CENTER.exit(vars.pId, nftIds, liqs);

      // withdraw
      FARMING_CENTER.withdraw(nftIds);
      state.staked = false;
    }

    // burn liquidity
    uint rTokensOwed;
    (amountsOut[0], amountsOut[1], rTokensOwed) = KYBER_NFT.removeLiquidity(IBasePositionManager.RemoveLiquidityParams(nftIds[0], liquidityAmountToExit, 0, 0, block.timestamp));

    if (rTokensOwed > 0) {
      KYBER_NFT.syncFeeGrowth(nftIds[0]);
      (,uint amount0, uint amount1) = KYBER_NFT.burnRTokens(IBasePositionManager.BurnRTokenParams(nftIds[0], 0, 0, block.timestamp));
      if (state.depositorSwapTokens) {
        feeA += amount1;
        feeB += amount0;
        emit KyberFeesClaimed(amount1, amount0);
      } else {
        feeA += amount0;
        feeB += amount1;
        emit KyberFeesClaimed(amount0, amount1);
      }
    }

    // transfer tokens
    KYBER_NFT.transferAllTokens(vars.tokenA, 0, address(this));
    KYBER_NFT.transferAllTokens(vars.tokenB, 0, address(this));

    // send fees to profit holder
    if (feeA > 0) {
      IERC20(vars.tokenA).safeTransfer(vars.strategyProfitHolder, feeA);
    }
    if (feeB > 0) {
      IERC20(vars.tokenB).safeTransfer(vars.strategyProfitHolder, feeB);
    }

    liquidity -= liquidityAmountToExit;
    state.totalLiquidity = liquidity;

    if (liquidity > 0 && !isFarmEnded(vars.pId)) {
      liqs[0] = uint(liquidity);
      FARMING_CENTER.deposit(nftIds);
      state.staked = true;
      FARMING_CENTER.join(vars.pId, nftIds, liqs);
    }
  }

  function quoteExit(
    State storage state,
    uint128 liquidityAmountToExit
  ) public view returns (uint[] memory amountsOut) {
    (uint160 sqrtRatioX96, , ,) = state.pool.getPoolState();
    amountsOut = new uint[](2);
    (amountsOut[0], amountsOut[1]) = KyberLib.getAmountsForLiquidity(
      sqrtRatioX96,
      state.lowerTick,
      state.upperTick,
      liquidityAmountToExit
    );
    if (state.depositorSwapTokens) {
      (amountsOut[0], amountsOut[1]) = (amountsOut[1], amountsOut[0]);
    }
  }

  //////////////////////////////////////////
  //            Rewards
  //////////////////////////////////////////

  function claimRewardsBeforeExitIfRequired(State storage state) external {
    (,bool needUnstake) = needRebalanceStaking(state);
    if (needUnstake) {
      claimRewards(state);
    }
  }

  function claimRewards(State storage state) public returns (
    address[] memory tokensOut,
    uint[] memory amountsOut,
    uint[] memory balancesBefore
  ) {
    address strategyProfitHolder = state.strategyProfitHolder;
    uint tokenId = state.tokenId;
    tokensOut = new address[](3);
    tokensOut[0] = state.tokenA;
    tokensOut[1] = state.tokenB;
    tokensOut[2] = KNC;

    balancesBefore = new uint[](3);
    for (uint i; i < tokensOut.length; i++) {
      balancesBefore[i] = AppLib.balance(tokensOut[i]);
    }

    amountsOut = new uint[](3);
    if (tokenId > 0 && state.totalLiquidity > 0) {
      (amountsOut[0], amountsOut[1]) = _claimFees(state);
      amountsOut[2] = _harvest(tokenId, state.pId);
    }

    for (uint i; i < tokensOut.length; ++i) {
      uint b = IERC20(tokensOut[i]).balanceOf(strategyProfitHolder);
      if (b > 0) {
        IERC20(tokensOut[i]).transferFrom(strategyProfitHolder, address(this), b);
        amountsOut[i] += b;
      }
    }
  }

  function _claimFees(State storage state) internal returns (uint amountA, uint amountB) {
    uint[] memory nftIds = new uint[](1);
    nftIds[0] = state.tokenId;
    address tokenA = state.tokenA;
    address tokenB = state.tokenB;
    uint bABefore = AppLib.balance(tokenA);
    uint bBBefore = AppLib.balance(tokenB);

    (uint token0Owed, uint token1Owed) = TICKS_FEES_READER.getTotalFeesOwedToPosition(address(KYBER_NFT), address(state.pool), nftIds[0]);
    if (token0Owed > 0 || token1Owed > 0) {
      FARMING_CENTER.claimFee(nftIds, 0, 0, address(state.pool), false, block.timestamp);

      amountA = AppLib.balance(tokenA) - bABefore;
      amountB = AppLib.balance(tokenB) - bBBefore;
      emit KyberFeesClaimed(amountA, amountB);
    }
  }

  function _harvest(uint tokenId, uint pId) internal returns (uint amount) {
    uint[] memory nftIds = new uint[](1);
    nftIds[0] = tokenId;
    uint[] memory pids = new uint[](1);
    pids[0] = pId;
    IKyberSwapElasticLM.HarvestData memory data = IKyberSwapElasticLM.HarvestData({
      pIds: pids
    });
    bytes[] memory datas = new bytes[](1);
    datas[0] = abi.encode(data);
    uint bBefore = AppLib.balance(KNC);
    FARMING_CENTER.harvestMultiplePools(nftIds, datas);
    amount = AppLib.balance(KNC) - bBefore;
    if (amount > 0) {
      emit KyberRewardsClaimed(amount);
    }
  }

  function calcEarned(address asset, address controller, address[] memory rewardTokens, uint[] memory amounts) external view returns (uint) {
    ITetuLiquidator liquidator = ITetuLiquidator(IController(controller).liquidator());
    uint len = rewardTokens.length;
    uint earned;
    for (uint i; i < len; ++i) {
      address token = rewardTokens[i];
      if (token == asset) {
        earned += amounts[i];
      } else {
        earned += liquidator.getPrice(rewardTokens[i], asset, amounts[i]);
      }
    }

    return earned;
  }

  //////////////////////////////////////////
  //            Rebalance
  //////////////////////////////////////////

  function needRebalance(State storage state) public view returns (bool) {
    if (state.isFuseTriggered) {
      return false;
    }

    (, int24 tick, ,) = state.pool.getPoolState();
    int24 upperTick = state.upperTick;
    int24 lowerTick = state.lowerTick;
    if (upperTick - lowerTick == state.tickSpacing) {
      return tick < lowerTick || tick >= upperTick;
    } else {
      int24 halfRange = (upperTick - lowerTick) / 2;
      int24 oldMedianTick = lowerTick + halfRange;
      if (tick > oldMedianTick) {
        return tick - oldMedianTick >= state.rebalanceTickRange;
      }
      return oldMedianTick - tick > state.rebalanceTickRange;
    }
  }

  function needRebalanceStaking(State storage state) public view returns (bool needStake, bool needUnstake) {
    bool farmEnded = isFarmEnded(state.pId);
    bool haveLiquidity = state.totalLiquidity > 0;
    bool staked = state.staked;
    needStake = haveLiquidity && !farmEnded && !staked;
    needUnstake = haveLiquidity && farmEnded && staked;
  }

  function isFarmEnded(uint pId) public view returns(bool) {
    (,,uint endTime,,,,,) = FARMING_CENTER.getPoolInfo(pId);
    return endTime < block.timestamp;
  }

  function quoteRebalanceSwap(State storage state, ITetuConverter converter) external returns (bool, uint) {
    address tokenA = state.tokenA;
    address tokenB = state.tokenB;
    uint debtAmount = KyberDebtLib.getDebtTotalDebtAmountOut(converter, tokenA, tokenB);

    if (
      !needRebalance(state)
      || !KyberDebtLib.needCloseDebt(debtAmount, converter, tokenB)
    ) {
      return (false, 0);
    }

    uint[] memory amountsOut = quoteExit(state, state.totalLiquidity);
    amountsOut[0] += AppLib.balance(tokenA);
    amountsOut[1] += AppLib.balance(tokenB);

    if (amountsOut[1] < debtAmount) {
      uint tokenBprice = KyberLib.getPrice(address(state.pool), tokenB);
      uint needToSellTokenA = tokenBprice * (debtAmount - amountsOut[1]) / 10 ** IERC20Metadata(tokenB).decimals();
      // add 1% gap for price impact
      needToSellTokenA += needToSellTokenA / KyberDebtLib.SELL_GAP;
      if (amountsOut[0] > 0) {
        needToSellTokenA = Math.min(needToSellTokenA, amountsOut[0] - 1);
      } else {
        needToSellTokenA = 0;
      }
      return (true, needToSellTokenA);
    } else {
      return (false, amountsOut[1] - debtAmount);
    }
  }

  function rebalance(
    State storage state,
    ITetuConverter converter,
    address controller,
    uint oldTotalAssets,
    uint profitToCover,
    address splitter
  ) external returns (
    uint[] memory tokenAmounts // _depositorEnter(tokenAmounts) if length == 2
  ) {
    uint loss;
    tokenAmounts = new uint[](0);

    RebalanceLocalVariables memory vars = RebalanceLocalVariables({
      upperTick: state.upperTick,
      lowerTick: state.lowerTick,
      tickSpacing: state.tickSpacing,
      pool: state.pool,
      tokenA: state.tokenA,
      tokenB: state.tokenB,
      lastPrice: state.lastPrice,
      fuseThreshold: state.fuseThreshold,
      depositorSwapTokens: state.depositorSwapTokens,
    // setup initial values
      notCoveredLoss: 0,
      newLowerTick: 0,
      newUpperTick: 0,
      isStablePool: state.isStablePool,
      newPrice: 0,
      newTotalAssets: 0,
      needRebalance : needRebalance(state)
    });

    if (vars.needRebalance) {
      vars.newPrice = ConverterStrategyBaseLib.getOracleAssetsPrice(converter, vars.tokenA, vars.tokenB);

      if (vars.isStablePool && isEnableFuse(vars.lastPrice, vars.newPrice, vars.fuseThreshold)) {
        /// enabling fuse: close debt and stop providing liquidity
        state.isFuseTriggered = true;
        emit FuseTriggered();

        KyberDebtLib.closeDebt(
          converter,
          controller,
          vars.pool,
          vars.tokenA,
          vars.tokenB,
          _getLiquidatorSwapSlippage(vars.isStablePool),
          profitToCover,
          oldTotalAssets,
          splitter
        );
      } else {
        /// rebalancing debt
        /// setting new tick range
        KyberDebtLib.rebalanceDebt(
          converter,
          controller,
          state,
          _getLiquidatorSwapSlippage(vars.isStablePool),
          profitToCover,
          oldTotalAssets,
          splitter
        );

        tokenAmounts = new uint[](2);
        tokenAmounts[0] = AppLib.balance(vars.tokenA);
        tokenAmounts[1] = AppLib.balance(vars.tokenB);

        address[] memory tokens = new address[](2);
        tokens[0] = vars.tokenA;
        tokens[1] = vars.tokenB;
        uint[] memory amounts = new uint[](2);
        amounts[0] = tokenAmounts[0];
        vars.newTotalAssets = ConverterStrategyBaseLib.calcInvestedAssets(tokens, amounts, 0, converter);
        if (vars.newTotalAssets < oldTotalAssets) {
          loss = oldTotalAssets - vars.newTotalAssets;
        }
      }

      // need to update last price only for stables coz only stables have fuse mechanic
      if (vars.isStablePool) {
        state.lastPrice = vars.newPrice;
      }

      uint covered;
      if (loss > 0) {
        covered = KyberDebtLib.coverLossFromRewards(loss, state.strategyProfitHolder, vars.tokenA, vars.tokenB, address(vars.pool));
        uint notCovered = loss - covered;
        if (notCovered > 0) {
          ISplitter(splitter).coverPossibleStrategyLoss(0, notCovered);
        }
      }

      emit Rebalanced(loss, covered);
    } else {
      tokenAmounts = new uint[](2);
      tokenAmounts[0] = AppLib.balance(vars.tokenA);
      tokenAmounts[1] = AppLib.balance(vars.tokenB);
    }
  }

  function rebalanceSwapByAgg(
    State storage state,
    ITetuConverter converter,
    uint oldTotalAssets,
    RebalanceSwapByAggParams memory aggParams,
    uint profitToCover,
    address splitter
  ) external returns (
    uint[] memory tokenAmounts // _depositorEnter(tokenAmounts) if length == 2
  ) {
    uint loss;
    tokenAmounts = new uint[](0);

    RebalanceLocalVariables memory vars = RebalanceLocalVariables({
      upperTick: state.upperTick,
      lowerTick: state.lowerTick,
      tickSpacing: state.tickSpacing,
      pool: state.pool,
      tokenA: state.tokenA,
      tokenB: state.tokenB,
      lastPrice: state.lastPrice,
      fuseThreshold: state.fuseThreshold,
      depositorSwapTokens: state.depositorSwapTokens,
    // setup initial values
      notCoveredLoss: 0,
      newLowerTick: 0,
      newUpperTick: 0,
      isStablePool: state.isStablePool,
      newPrice: 0,
      newTotalAssets: 0,
      needRebalance : needRebalance(state)
    });

    if (vars.needRebalance) {
      vars.newPrice = ConverterStrategyBaseLib.getOracleAssetsPrice(converter, vars.tokenA, vars.tokenB);

      if (vars.isStablePool && isEnableFuse(vars.lastPrice, vars.newPrice, vars.fuseThreshold)) {
        /// enabling fuse: close debt and stop providing liquidity
        state.isFuseTriggered = true;
        emit FuseTriggered();

        KyberDebtLib.closeDebtByAgg(
          converter,
          vars.tokenA,
          vars.tokenB,
          _getLiquidatorSwapSlippage(vars.isStablePool),
          aggParams,
          profitToCover,
          oldTotalAssets,
          splitter
        );
      } else {
        /// rebalancing debt
        /// setting new tick range
        KyberDebtLib.rebalanceDebtSwapByAgg(
          converter,
          state,
          _getLiquidatorSwapSlippage(vars.isStablePool),
          aggParams,
          profitToCover,
          oldTotalAssets,
          splitter
        );

        if (oldTotalAssets > 0) {
          tokenAmounts = new uint[](2);
          tokenAmounts[0] = AppLib.balance(vars.tokenA);
          tokenAmounts[1] = AppLib.balance(vars.tokenB);

          address[] memory tokens = new address[](2);
          tokens[0] = vars.tokenA;
          tokens[1] = vars.tokenB;
          uint[] memory amounts = new uint[](2);
          amounts[0] = tokenAmounts[0];
          vars.newTotalAssets = ConverterStrategyBaseLib.calcInvestedAssets(tokens, amounts, 0, converter);
          if (vars.newTotalAssets < oldTotalAssets) {
            loss = oldTotalAssets - vars.newTotalAssets;
          }
        }
      }

      // need to update last price only for stables coz only stables have fuse mechanic
      if (vars.isStablePool) {
        state.lastPrice = vars.newPrice;
      }

      uint covered;
      if (loss > 0) {
        covered = KyberDebtLib.coverLossFromRewards(loss, state.strategyProfitHolder, vars.tokenA, vars.tokenB, address(vars.pool));
        uint notCovered = loss - covered;
        if (notCovered > 0) {
          ISplitter(splitter).coverPossibleStrategyLoss(0, notCovered);
        }
      }

      emit Rebalanced(loss, covered);
    } else {
      tokenAmounts = new uint[](2);
      tokenAmounts[0] = AppLib.balance(vars.tokenA);
      tokenAmounts[1] = AppLib.balance(vars.tokenB);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../ConverterStrategyBaseLib.sol";
import "../ConverterStrategyBaseLib2.sol";
import "./KyberLib.sol";
import "./KyberStrategyErrors.sol";
import "./KyberConverterStrategyLogicLib.sol";

library KyberDebtLib {
  using SafeERC20 for IERC20;

  uint public constant SELL_GAP = 100;
  address internal constant ONEINCH = 0x1111111254EEB25477B68fb85Ed929f73A960582; // 1inch router V5
  address internal constant OPENOCEAN = 0x6352a56caadC4F1E25CD6c75970Fa768A3304e64; // OpenOceanExchangeProxy

  function calcTickRange(IPool pool, int24 tickRange, int24 tickSpacing) public view returns (int24 lowerTick, int24 upperTick) {
    (, int24 tick, ,) = pool.getPoolState();
    if (tick < 0 && tick / tickSpacing * tickSpacing != tick) {
      lowerTick = ((tick - tickRange) / tickSpacing - 1) * tickSpacing;
    } else {
      lowerTick = (tick - tickRange) / tickSpacing * tickSpacing;
    }
    upperTick = tickRange == 0 ? lowerTick + tickSpacing : lowerTick + tickRange * 2;
  }

  function getEntryData(
    IPool pool,
    int24 lowerTick,
    int24 upperTick,
    bool depositorSwapTokens
  ) public view returns (bytes memory entryData) {
    address token1 = address(pool.token1());
    uint token1Price = KyberLib.getPrice(address(pool), token1);

    uint token1Decimals = IERC20Metadata(token1).decimals();

    uint token0Desired = token1Price;
    uint token1Desired = 10 ** token1Decimals;

    // calculate proportions
    (uint consumed0, uint consumed1,) = KyberLib.addLiquidityPreview(address(pool), lowerTick, upperTick, token0Desired, token1Desired);

    if (depositorSwapTokens) {
      entryData = abi.encode(1, consumed1 * token1Price / token1Desired, consumed0);
    } else {
      entryData = abi.encode(1, consumed0, consumed1 * token1Price / token1Desired);
    }
  }

  /// @dev Closes the debt positions for the given token pair.
  /// @param tetuConverter The ITetuConverter instance.
  /// @param controller The controller address.
  /// @param pool The IUniswapV3Pool instance.
  /// @param tokenA The address of tokenA.
  /// @param tokenB The address of tokenB.
  function closeDebt(
    ITetuConverter tetuConverter,
    address controller,
    IPool pool,
    address tokenA,
    address tokenB,
    uint liquidatorSwapSlippage,
    uint profitToCover,
    uint totalAssets,
    address splitter
  ) public {
    _closeDebt(tetuConverter, controller, pool, tokenA, tokenB, liquidatorSwapSlippage);
    if (profitToCover > 0) {
      ConverterStrategyBaseLib2.sendToInsurance(tokenA, profitToCover, splitter, totalAssets);
    }
  }

  function closeDebtByAgg(
    ITetuConverter tetuConverter,
    address tokenA,
    address tokenB,
    uint liquidatorSwapSlippage,
    KyberConverterStrategyLogicLib.RebalanceSwapByAggParams memory aggParams,
    uint profitToCover,
    uint totalAssets,
    address splitter
  ) public {
    _closeDebtByAgg(tetuConverter, tokenA, tokenB, liquidatorSwapSlippage, aggParams);
    if (profitToCover > 0) {
      ConverterStrategyBaseLib2.sendToInsurance(tokenA, profitToCover, splitter, totalAssets);
    }
  }

  /// @dev Rebalances the debt by either filling up or closing and reopening debt positions. Sets new tick range.
  function rebalanceDebt(
    ITetuConverter tetuConverter,
    address controller,
    KyberConverterStrategyLogicLib.State storage state,
    uint liquidatorSwapSlippage,
    uint profitToCover,
    uint totalAssets,
    address splitter
  ) external {
    IPool pool = state.pool;
    address tokenA = state.tokenA;
    address tokenB = state.tokenB;
    bool depositorSwapTokens = state.depositorSwapTokens;
    _closeDebt(tetuConverter, controller, pool, tokenA, tokenB, liquidatorSwapSlippage);
    if (profitToCover > 0) {
      ConverterStrategyBaseLib2.sendToInsurance(tokenA, profitToCover, splitter, totalAssets);
    }
    (int24 newLowerTick, int24 newUpperTick) = _calcNewTickRange(pool, state.lowerTick, state.upperTick, state.tickSpacing);
    bytes memory entryData = getEntryData(pool, newLowerTick, newUpperTick, depositorSwapTokens);
    _openDebt(tetuConverter, tokenA, tokenB, entryData);
    state.lowerTick = newLowerTick;
    state.upperTick = newUpperTick;
  }

  function rebalanceDebtSwapByAgg(
    ITetuConverter tetuConverter,
    KyberConverterStrategyLogicLib.State storage state,
    uint liquidatorSwapSlippage,
    KyberConverterStrategyLogicLib.RebalanceSwapByAggParams memory aggParams,
    uint profitToCover,
    uint totalAssets,
    address splitter
  ) external {
    IPool pool = state.pool;
    address tokenA = state.tokenA;
    address tokenB = state.tokenB;
    bool depositorSwapTokens = state.depositorSwapTokens;
    _closeDebtByAgg(tetuConverter, tokenA, tokenB, liquidatorSwapSlippage, aggParams);
    if (profitToCover > 0) {
      ConverterStrategyBaseLib2.sendToInsurance(tokenA, profitToCover, splitter, totalAssets);
    }
    (int24 newLowerTick, int24 newUpperTick) = _calcNewTickRange(pool, state.lowerTick, state.upperTick, state.tickSpacing);
    bytes memory entryData = getEntryData(pool, newLowerTick, newUpperTick, depositorSwapTokens);
    _openDebt(tetuConverter, tokenA, tokenB, entryData);
    state.lowerTick = newLowerTick;
    state.upperTick = newUpperTick;
  }

  /// @dev Returns the total debt amount out for the given token pair.
  /// @param tetuConverter The ITetuConverter instance.
  /// @param tokenA The address of tokenA.
  /// @param tokenB The address of tokenB.
  /// @return totalDebtAmountOut The total debt amount out for the token pair.
  function getDebtTotalDebtAmountOut(ITetuConverter tetuConverter, address tokenA, address tokenB) public returns (uint totalDebtAmountOut) {
    (totalDebtAmountOut,) = tetuConverter.getDebtAmountCurrent(address(this), tokenA, tokenB, true);
  }

  /// @dev we close debt only if it is more than $0.1
  function needCloseDebt(uint debtAmount, ITetuConverter tetuConverter, address tokenB) public view returns (bool) {
    IPriceOracle priceOracle = IPriceOracle(IConverterController(tetuConverter.controller()).priceOracle());
    return debtAmount * priceOracle.getAssetPrice(tokenB) / 10 ** IERC20Metadata(tokenB).decimals() > 1e17;
  }

  function coverLossFromRewards(uint loss, address strategyProfitHolder, address tokenA, address tokenB, address pool) external returns (uint covered) {
    uint bA = IERC20Metadata(tokenA).balanceOf(strategyProfitHolder);
    uint bB = IERC20Metadata(tokenB).balanceOf(strategyProfitHolder);

    if (loss <= bA) {
      IERC20(tokenA).safeTransferFrom(strategyProfitHolder, address(this), loss);
      covered = loss;
    } else {
      uint needToCoverA = loss;
      if (bA > 0) {
        IERC20(tokenA).safeTransferFrom(strategyProfitHolder, address(this), bA);
        needToCoverA -= bA;
      }
      if (bB > 0) {
        uint needTransferB = KyberLib.getPrice(pool, tokenA) * needToCoverA / 10 ** IERC20Metadata(tokenA).decimals();
        uint canTransferB = Math.min(needTransferB, bB);
        IERC20(tokenB).safeTransferFrom(strategyProfitHolder, address(this), canTransferB);
        needToCoverA -= needToCoverA * canTransferB / needTransferB;
      }
      covered = loss - needToCoverA;
    }
  }

  /// @notice Calculate the new tick range for a Kyber pool.
  /// @param pool The Kyber pool to calculate the new tick range for.
  /// @param lowerTick The current lower tick value for the pool.
  /// @param upperTick The current upper tick value for the pool.
  /// @param tickSpacing The tick spacing for the pool.
  /// @return lowerTickNew The new lower tick value for the pool.
  /// @return upperTickNew The new upper tick value for the pool.
  function _calcNewTickRange(
    IPool pool,
    int24 lowerTick,
    int24 upperTick,
    int24 tickSpacing
  ) internal view returns (int24 lowerTickNew, int24 upperTickNew) {
    int24 fullTickRange = upperTick - lowerTick;
    (lowerTickNew, upperTickNew) = calcTickRange(pool, fullTickRange == tickSpacing ? int24(0) : fullTickRange / 2, tickSpacing);
  }

  /// @dev Opens a new debt position using entry data.
  /// @param tetuConverter The TetuConverter contract.
  /// @param tokenA The address of token A.
  /// @param tokenB The address of token B.
  /// @param entryData The data required to open a position.
  function _openDebt(
    ITetuConverter tetuConverter,
    address tokenA,
    address tokenB,
    bytes memory entryData/*,
    uint feeA*/
  ) internal {
    ConverterStrategyBaseLib.openPosition(
      tetuConverter,
      entryData,
      tokenA,
      tokenB,
      AppLib.balance(tokenA)/* - feeA*/,
      0
    );
  }

  /// @notice Closes debt by liquidating tokens as necessary.
  ///         This function helps ensure that the converter strategy maintains the appropriate balances
  ///         and debt positions for token A and token B, while accounting for potential price impacts.
  function _closeDebt(
    ITetuConverter tetuConverter,
    address controller,
    IPool pool,
    address tokenA,
    address tokenB,
    uint liquidatorSwapSlippage
  ) internal {
    uint debtAmount = getDebtTotalDebtAmountOut(tetuConverter, tokenA, tokenB);

    if (needCloseDebt(debtAmount, tetuConverter, tokenB)) {
      uint availableBalanceTokenA = AppLib.balance(tokenA);
      uint availableBalanceTokenB = AppLib.balance(tokenB);

      if (availableBalanceTokenB < debtAmount) {
        uint tokenBprice = KyberLib.getPrice(address(pool), tokenB);
        uint needToSellTokenA = tokenBprice * (debtAmount - availableBalanceTokenB) / 10 ** IERC20Metadata(tokenB).decimals();
        // add 1% gap for price impact
        needToSellTokenA += needToSellTokenA / SELL_GAP;

        ConverterStrategyBaseLib.liquidate(tetuConverter, ITetuLiquidator(IController(controller).liquidator()), tokenA, tokenB, Math.min(needToSellTokenA, availableBalanceTokenA), liquidatorSwapSlippage, 0, false);
        availableBalanceTokenB = AppLib.balance(tokenB);
      }

      ConverterStrategyBaseLib.closePosition(
        tetuConverter,
        tokenA,
        tokenB,
        Math.min(debtAmount, availableBalanceTokenB)
      );

      availableBalanceTokenB = AppLib.balance(tokenB);
      ConverterStrategyBaseLib.liquidate(tetuConverter, ITetuLiquidator(IController(controller).liquidator()), tokenB, tokenA, availableBalanceTokenB, liquidatorSwapSlippage, 0, false);
    }
  }

  function _closeDebtByAgg(
    ITetuConverter tetuConverter,
    address tokenA,
    address tokenB,
    uint liquidatorSwapSlippage,
    KyberConverterStrategyLogicLib.RebalanceSwapByAggParams memory aggParams
  ) internal {
    _checkSwapRouter(aggParams.agg);

    uint debtAmount = getDebtTotalDebtAmountOut(tetuConverter, tokenA, tokenB);

    if (needCloseDebt(debtAmount, tetuConverter, tokenB)) {
      uint balanceTokenABefore = AppLib.balance(tokenA);
      uint balanceTokenBBefore = AppLib.balance(tokenB);

      address tokenIn = aggParams.direction ? tokenA : tokenB;

      AppLib.approveIfNeeded(tokenIn, aggParams.amount, aggParams.agg);

      {
        (bool success, bytes memory result) = aggParams.agg.call(aggParams.swapData);
        require(success, string(result));
      }

      uint availableBalanceTokenA = AppLib.balance(tokenA);
      uint availableBalanceTokenB = AppLib.balance(tokenB);

      require(
        tetuConverter.isConversionValid(
          tokenIn,
          aggParams.amount,
          aggParams.direction ? tokenB : tokenA,
          aggParams.direction ? availableBalanceTokenB - balanceTokenBBefore : availableBalanceTokenA - balanceTokenABefore,
          liquidatorSwapSlippage
        ), AppErrors.PRICE_IMPACT);

      ConverterStrategyBaseLib.closePosition(
        tetuConverter,
        tokenA,
        tokenB,
        Math.min(debtAmount, availableBalanceTokenB)
      );

      availableBalanceTokenB = AppLib.balance(tokenB);
    }
  }

  function _checkSwapRouter(address router) internal pure {
    require(router == ONEINCH || router == OPENOCEAN, KyberStrategyErrors.UNKNOWN_SWAP_ROUTER);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@tetu_io/tetu-contracts-v2/contracts/openzeppelin/Initializable.sol";
import "../DepositorBase.sol";
import "./KyberStrategyErrors.sol";
import "./KyberConverterStrategyLogicLib.sol";


abstract contract KyberDepositor is DepositorBase, Initializable {
  using SafeERC20 for IERC20;

  /////////////////////////////////////////////////////////////////////
  ///                CONSTANTS
  /////////////////////////////////////////////////////////////////////

  /// @dev Version of this contract. Adjust manually on each code modification.
  string public constant KYBER_DEPOSITOR_VERSION = "1.0.0";

  /////////////////////////////////////////////////////////////////////
  ///                VARIABLES
  /////////////////////////////////////////////////////////////////////

  /// @dev State variable to store the current state of the whole strategy
  KyberConverterStrategyLogicLib.State internal state;

  /////////////////////////////////////////////////////////////////////
  ///                       View
  /////////////////////////////////////////////////////////////////////

  /// @notice Returns the current state of the contract.
  function getState() external view returns (
    address tokenA,
    address tokenB,
    address profitHolder,
    IPool pool,
    uint128 totalLiquidity,
    uint fuseThreshold,
    int24[] memory ticks,
    uint[] memory profitHolderBalances,
    bool[] memory flags
  ) {
    tokenA = state.tokenA;
    tokenB = state.tokenB;
    pool = state.pool;
    ticks = new int24[](4);
    ticks[0] = state.lowerTick;
    ticks[1] = state.upperTick;
    ticks[2] = state.tickSpacing;
    ticks[3] = state.rebalanceTickRange;
    totalLiquidity = state.totalLiquidity;
    fuseThreshold = state.fuseThreshold;
    profitHolder = state.strategyProfitHolder;
    profitHolderBalances = new uint[](3);
    profitHolderBalances[0] = IERC20(tokenA).balanceOf(profitHolder);
    profitHolderBalances[1] = IERC20(tokenB).balanceOf(profitHolder);
    profitHolderBalances[2] = IERC20(KyberConverterStrategyLogicLib.KNC).balanceOf(profitHolder);
    flags = new bool[](4);
    flags[0] = state.isFuseTriggered;
    flags[1] = state.staked;
    (flags[2], flags[3]) = KyberConverterStrategyLogicLib.needRebalanceStaking(state);
  }

  /// @notice Returns the pool assets.
  /// @return poolAssets An array containing the addresses of the pool assets.
  function _depositorPoolAssets() override internal virtual view returns (address[] memory poolAssets) {
    poolAssets = new address[](2);
    poolAssets[0] = state.tokenA;
    poolAssets[1] = state.tokenB;
  }

  /// @notice Returns the pool weights and the total weight.
  /// @return weights An array containing the weights of the pool assets, and totalWeight the sum of the weights.
  function _depositorPoolWeights() override internal virtual view returns (uint[] memory weights, uint totalWeight) {
    weights = new uint[](2);
    weights[0] = 1;
    weights[1] = 1;
    totalWeight = 2;
  }

  /// @notice Returns the pool reserves.
  /// @return reserves An array containing the reserves of the pool assets.
  function _depositorPoolReserves() override internal virtual view returns (uint[] memory reserves) {
    return KyberConverterStrategyLogicLib.getPoolReserves(state);
  }

  /// @notice Returns the current liquidity of the depositor.
  /// @return The current liquidity of the depositor.
  function _depositorLiquidity() override internal virtual view returns (uint) {
    return uint(state.totalLiquidity);
  }

  /// @notice Returns the total supply of the depositor.
  /// @return In UniV3 we can not calculate the total supply of the wgole pool. Return only ourself value.
  function _depositorTotalSupply() override internal view virtual returns (uint) {
    return uint(state.totalLiquidity);
  }

  /////////////////////////////////////////////////////////////////////
  ///             Enter, exit
  /////////////////////////////////////////////////////////////////////

  /// @notice Handles the deposit operation.
  function _depositorEnter(uint[] memory amountsDesired_) override internal virtual returns (uint[] memory amountsConsumed, uint liquidityOut) {
    (amountsConsumed, liquidityOut) = KyberConverterStrategyLogicLib.enter(state, amountsDesired_);
  }

  /// @notice Handles the withdrawal operation.
  /// @param liquidityAmount The amount of liquidity to be withdrawn.
  /// @return amountsOut The amounts of the tokens withdrawn.
  function _depositorExit(uint liquidityAmount) override internal virtual returns (uint[] memory amountsOut) {
    amountsOut = KyberConverterStrategyLogicLib.exit(state, uint128(liquidityAmount));
  }

  /// @notice Returns the amount of tokens that would be withdrawn based on the provided liquidity amount.
  /// @param liquidityAmount The amount of liquidity to quote the withdrawal for.
  /// @return amountsOut The amounts of the tokens that would be withdrawn.
  function _depositorQuoteExit(uint liquidityAmount) override internal virtual returns (uint[] memory amountsOut) {
    amountsOut = KyberConverterStrategyLogicLib.quoteExit(state, uint128(liquidityAmount));
  }

  /////////////////////////////////////////////////////////////////////
  ///             Claim rewards
  /////////////////////////////////////////////////////////////////////

  /// @notice Claims all possible rewards.
  /// @return tokensOut An array containing the addresses of the reward tokens,
  /// @return amountsOut An array containing the amounts of the reward tokens.
  function _depositorClaimRewards() override internal virtual returns (
    address[] memory tokensOut,
    uint[] memory amountsOut,
    uint[] memory balancesBefore
  ) {
    return KyberConverterStrategyLogicLib.claimRewards(state);
  }

  /// @dev This empty reserved space is put in place to allow future versions to add new
  /// variables without shifting down storage in the inheritance chain.
  /// See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
  uint[50 - 1] private __gap; // 50 - count of variables

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../integrations/kyber/IPool.sol";
import "../../integrations/kyber/IBasePositionManager.sol";
import "../../integrations/kyber/IKyberSwapElasticLM.sol";
import "../../integrations/kyber/ITicksFeesReader.sol";
import "@tetu_io/tetu-contracts-v2/contracts/interfaces/IERC20Metadata.sol";

library KyberLib {
  uint8 internal constant RESOLUTION = 96;
  uint internal constant Q96 = 0x1000000000000000000000000;
  uint private constant TWO_96 = 2 ** 96;
  /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
  uint160 private constant MIN_SQRT_RATIO = 4295128739 + 1;
  /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
  uint160 private constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342 - 1;
  /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
  int24 internal constant MIN_TICK = - 887272;
  /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
  int24 internal constant MAX_TICK = - MIN_TICK;

  function getPreviousTicks(IPool pool, int24 tickLower, int24 tickUpper) external view returns (int24[2] memory ticks) {
    (ticks[0],) = _getNearestInitializedTicks(pool, tickLower);
    (ticks[1],) = _getNearestInitializedTicks(pool, tickUpper);
  }

  function _getNearestInitializedTicks(IPool pool, int24 tick) internal view returns (int24 previous, int24 next) {
    require(MIN_TICK <= tick && tick <= MAX_TICK, 'tick not in range');
    // if queried tick already initialized, fetch and return values
    (previous, next) = pool.initializedTicks(tick);
    if (previous != 0 || next != 0) return (previous, next);

    // search downtick from MAX_TICK
    if (tick > 0) {
      previous = MAX_TICK;
      while (previous > tick) {
        (previous, ) = pool.initializedTicks(previous);
      }
      (, next) = pool.initializedTicks(previous);
    } else {
      // search uptick from MIN_TICK
      next = MIN_TICK;
      while (next < tick) {
        (, next) = pool.initializedTicks(next);
      }
      (previous, ) = pool.initializedTicks(next);
    }
  }

  function getTickSpacing(IPool pool) external view returns (int24) {
    return pool.tickDistance();
  }

  function addLiquidityPreview(address pool_, int24 lowerTick_, int24 upperTick_, uint amount0Desired_, uint amount1Desired_) external view returns (uint amount0Consumed, uint amount1Consumed, uint128 liquidityOut) {
    IPool pool = IPool(pool_);
    (uint160 sqrtRatioX96, , ,) = pool.getPoolState();
    liquidityOut = getLiquidityForAmounts(sqrtRatioX96, lowerTick_, upperTick_, amount0Desired_, amount1Desired_);
    (amount0Consumed, amount1Consumed) = getAmountsForLiquidity(sqrtRatioX96, lowerTick_, upperTick_, liquidityOut);
  }

  /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
  /// pool prices and the prices at the tick boundaries
  function getLiquidityForAmounts(
    uint160 sqrtRatioX96,
    int24 lowerTick,
    int24 upperTick,
    uint amount0,
    uint amount1
  ) public pure returns (uint128 liquidity) {
    uint160 sqrtRatioAX96 = _getSqrtRatioAtTick(lowerTick);
    uint160 sqrtRatioBX96 = _getSqrtRatioAtTick(upperTick);
    if (sqrtRatioAX96 > sqrtRatioBX96) {
      (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
    }

    if (sqrtRatioX96 <= sqrtRatioAX96) {
      liquidity = _getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
    } else if (sqrtRatioX96 < sqrtRatioBX96) {
      uint128 liquidity0 = _getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
      uint128 liquidity1 = _getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);
      liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
    } else {
      liquidity = _getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
    }
  }

  /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
  /// pool prices and the prices at the tick boundaries
  function getAmountsForLiquidity(
    uint160 sqrtRatioX96,
    int24 lowerTick,
    int24 upperTick,
    uint128 liquidity
  ) public pure returns (uint amount0, uint amount1) {
    uint160 sqrtRatioAX96 = _getSqrtRatioAtTick(lowerTick);
    uint160 sqrtRatioBX96 = _getSqrtRatioAtTick(upperTick);

    if (sqrtRatioAX96 > sqrtRatioBX96) {
      (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
    }

    if (sqrtRatioX96 <= sqrtRatioAX96) {
      amount0 = _getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
    } else if (sqrtRatioX96 < sqrtRatioBX96) {
      amount0 = _getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
      amount1 = _getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
    } else {
      amount1 = _getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
    }
  }

  /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint or denominator == 0
  /// @param a The multiplicand
  /// @param b The multiplier
  /// @param denominator The divisor
  /// @return result The 256-bit result
  /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
  function mulDiv(
    uint a,
    uint b,
    uint denominator
  ) public pure returns (uint result) {
    unchecked {
      // 512-bit multiply [prod1 prod0] = a * b
      // Compute the product mod 2**256 and mod 2**256 - 1
      // then use the Chinese Remainder Theorem to reconstruct
      // the 512 bit result. The result is stored in two 256
      // variables such that product = prod1 * 2**256 + prod0
      uint prod0;
      // Least significant 256 bits of the product
      uint prod1;
      // Most significant 256 bits of the product
      assembly {
        let mm := mulmod(a, b, not(0))
        prod0 := mul(a, b)
        prod1 := sub(sub(mm, prod0), lt(mm, prod0))
      }

      // Handle non-overflow cases, 256 by 256 division
      if (prod1 == 0) {
        require(denominator > 0);
        assembly {
          result := div(prod0, denominator)
        }
        return result;
      }

      // Make sure the result is less than 2**256.
      // Also prevents denominator == 0
      require(denominator > prod1);

      ///////////////////////////////////////////////
      // 512 by 256 division.
      ///////////////////////////////////////////////

      // Make division exact by subtracting the remainder from [prod1 prod0]
      // Compute remainder using mulmod
      uint remainder;
      assembly {
        remainder := mulmod(a, b, denominator)
      }
      // Subtract 256 bit number from 512 bit number
      assembly {
        prod1 := sub(prod1, gt(remainder, prod0))
        prod0 := sub(prod0, remainder)
      }

      // Factor powers of two out of denominator
      // Compute largest power of two divisor of denominator.
      // Always >= 1.
      // EDIT for 0.8 compatibility:
      // see: https://ethereum.stackexchange.com/questions/96642/unary-operator-cannot-be-applied-to-type-uint
      uint twos = denominator & (~denominator + 1);

      // Divide denominator by power of two
      assembly {
        denominator := div(denominator, twos)
      }

      // Divide [prod1 prod0] by the factors of two
      assembly {
        prod0 := div(prod0, twos)
      }
      // Shift in bits from prod1 into prod0. For this we need
      // to flip `twos` such that it is 2**256 / twos.
      // If twos is zero, then it becomes one
      assembly {
        twos := add(div(sub(0, twos), twos), 1)
      }
      prod0 |= prod1 * twos;

      // Invert denominator mod 2**256
      // Now that denominator is an odd number, it has an inverse
      // modulo 2**256 such that denominator * inv = 1 mod 2**256.
      // Compute the inverse by starting with a seed that is correct
      // correct for four bits. That is, denominator * inv = 1 mod 2**4
      uint inv = (3 * denominator) ^ 2;
      // Now use Newton-Raphson iteration to improve the precision.
      // Thanks to Hensel's lifting lemma, this also works in modular
      // arithmetic, doubling the correct bits in each step.
      inv *= 2 - denominator * inv;
      // inverse mod 2**8
      inv *= 2 - denominator * inv;
      // inverse mod 2**16
      inv *= 2 - denominator * inv;
      // inverse mod 2**32
      inv *= 2 - denominator * inv;
      // inverse mod 2**64
      inv *= 2 - denominator * inv;
      // inverse mod 2**128
      inv *= 2 - denominator * inv;
      // inverse mod 2**256

      // Because the division is now exact we can divide by multiplying
      // with the modular inverse of denominator. This will give us the
      // correct result modulo 2**256. Since the precoditions guarantee
      // that the outcome is less than 2**256, this is the final result.
      // We don't need to compute the high bits of the result and prod1
      // is no longer required.
      result = prod0 * inv;
      return result;
    }
  }

  /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint or denominator == 0
  /// @param a The multiplicand
  /// @param b The multiplier
  /// @param denominator The divisor
  /// @return result The 256-bit result
  function mulDivRoundingUp(
    uint a,
    uint b,
    uint denominator
  ) internal pure returns (uint result) {
    result = mulDiv(a, b, denominator);
    if (mulmod(a, b, denominator) > 0) {
      require(result < type(uint).max);
      result++;
    }
  }

  /// @notice Calculates price in pool
  function getPrice(address pool_, address tokenIn) public view returns (uint) {
    IPool pool = IPool(pool_);
    address token0 = address(pool.token0());
    address token1 = address(pool.token1());

    uint tokenInDecimals = tokenIn == token0 ? IERC20Metadata(token0).decimals() : IERC20Metadata(token1).decimals();
    uint tokenOutDecimals = tokenIn == token1 ? IERC20Metadata(token0).decimals() : IERC20Metadata(token1).decimals();
    (uint160 sqrtPriceX96,,,) = pool.getPoolState();

    uint divider = tokenOutDecimals < 18 ? _max(10 ** tokenOutDecimals / 10 ** tokenInDecimals, 1) : 1;

    uint priceDigits = _countDigits(uint(sqrtPriceX96));
    uint purePrice;
    uint precision;
    if (tokenIn == token0) {
      precision = 10 ** ((priceDigits < 29 ? 29 - priceDigits : 0) + tokenInDecimals);
      uint part = uint(sqrtPriceX96) * precision / TWO_96;
      purePrice = part * part;
    } else {
      precision = 10 ** ((priceDigits > 29 ? priceDigits - 29 : 0) + tokenInDecimals);
      uint part = TWO_96 * precision / uint(sqrtPriceX96);
      purePrice = part * part;
    }
    return purePrice / divider / precision / (precision > 1e18 ? (precision / 1e18) : 1);
  }

  /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
  /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower)).
  /// @param sqrtRatioAX96 A sqrt price
  /// @param sqrtRatioBX96 Another sqrt price
  /// @param amount0 The amount0 being sent in
  /// @return liquidity The amount of returned liquidity
  function _getLiquidityForAmount0(uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint amount0) internal pure returns (uint128 liquidity) {
    if (sqrtRatioAX96 > sqrtRatioBX96) {
      (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
    }
    uint intermediate = mulDiv(sqrtRatioAX96, sqrtRatioBX96, Q96);
    return _toUint128(mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
  }

  /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
  /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
  /// @param sqrtRatioAX96 A sqrt price
  /// @param sqrtRatioBX96 Another sqrt price
  /// @param amount1 The amount1 being sent in
  /// @return liquidity The amount of returned liquidity
  function _getLiquidityForAmount1(uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint amount1) internal pure returns (uint128 liquidity) {
    if (sqrtRatioAX96 > sqrtRatioBX96) {
      (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
    }
    return _toUint128(mulDiv(amount1, Q96, sqrtRatioBX96 - sqrtRatioAX96));
  }

  /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
  /// @param sqrtRatioAX96 A sqrt price
  /// @param sqrtRatioBX96 Another sqrt price
  /// @param liquidity The liquidity being valued
  /// @return amount0 The amount0
  function _getAmount0ForLiquidity(uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint128 liquidity) internal pure returns (uint amount0) {
    if (sqrtRatioAX96 > sqrtRatioBX96) {
      (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
    }
    return mulDivRoundingUp(1, mulDivRoundingUp(uint(liquidity) << RESOLUTION, sqrtRatioBX96 - sqrtRatioAX96, sqrtRatioBX96), sqrtRatioAX96);
  }

  /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
  /// @param sqrtRatioAX96 A sqrt price
  /// @param sqrtRatioBX96 Another sqrt price
  /// @param liquidity The liquidity being valued
  /// @return amount1 The amount1
  function _getAmount1ForLiquidity(uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint128 liquidity) internal pure returns (uint amount1) {
    if (sqrtRatioAX96 > sqrtRatioBX96) {
      (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
    }
    return mulDivRoundingUp(liquidity, sqrtRatioBX96 - sqrtRatioAX96, Q96);
  }

  function _countDigits(uint n) internal pure returns (uint) {
    if (n == 0) {
      return 0;
    }
    uint count = 0;
    while (n != 0) {
      n = n / 10;
      ++count;
    }
    return count;
  }

  function _min(uint a, uint b) internal pure returns (uint) {
    return a < b ? a : b;
  }

  function _max(uint a, uint b) internal pure returns (uint) {
    return a > b ? a : b;
  }

  function _toUint128(uint x) private pure returns (uint128 y) {
    require((y = uint128(x)) == x);
  }

  /// @notice Calculates sqrt(1.0001^tick) * 2^96
  /// @dev Throws if |tick| > max tick
  /// @param tick The input tick for the above formula
  /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
  /// at the given tick
  function _getSqrtRatioAtTick(int24 tick)
  internal
  pure
  returns (uint160 sqrtPriceX96)
  {
    uint256 absTick =
      tick < 0 ? uint256(- int256(tick)) : uint256(int256(tick));

    // EDIT: 0.8 compatibility
    require(absTick <= uint256(int256(MAX_TICK)), "T");

    uint256 ratio =
      absTick & 0x1 != 0
        ? 0xfffcb933bd6fad37aa2d162d1a594001
        : 0x100000000000000000000000000000000;
    if (absTick & 0x2 != 0)
      ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
    if (absTick & 0x4 != 0)
      ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
    if (absTick & 0x8 != 0)
      ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
    if (absTick & 0x10 != 0)
      ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
    if (absTick & 0x20 != 0)
      ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
    if (absTick & 0x40 != 0)
      ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
    if (absTick & 0x80 != 0)
      ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
    if (absTick & 0x100 != 0)
      ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
    if (absTick & 0x200 != 0)
      ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
    if (absTick & 0x400 != 0)
      ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
    if (absTick & 0x800 != 0)
      ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
    if (absTick & 0x1000 != 0)
      ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
    if (absTick & 0x2000 != 0)
      ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
    if (absTick & 0x4000 != 0)
      ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
    if (absTick & 0x8000 != 0)
      ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
    if (absTick & 0x10000 != 0)
      ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
    if (absTick & 0x20000 != 0)
      ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
    if (absTick & 0x40000 != 0)
      ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
    if (absTick & 0x80000 != 0)
      ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

    if (tick > 0) ratio = type(uint256).max / ratio;

    // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
    // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
    // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
    sqrtPriceX96 = uint160(
      (ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1)
    );
  }

  /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
  /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
  /// ever return.
  /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
  /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
  function _getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
    // second inequality must be < because the price can never reach the price at the max tick
    require(
      sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO,
      "R"
    );
    uint256 ratio = uint256(sqrtPriceX96) << 32;

    uint256 r = ratio;
    uint256 msb = 0;

    assembly {
      let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
      msb := or(msb, f)
      r := shr(f, r)
    }
    assembly {
      let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
      msb := or(msb, f)
      r := shr(f, r)
    }
    assembly {
      let f := shl(5, gt(r, 0xFFFFFFFF))
      msb := or(msb, f)
      r := shr(f, r)
    }
    assembly {
      let f := shl(4, gt(r, 0xFFFF))
      msb := or(msb, f)
      r := shr(f, r)
    }
    assembly {
      let f := shl(3, gt(r, 0xFF))
      msb := or(msb, f)
      r := shr(f, r)
    }
    assembly {
      let f := shl(2, gt(r, 0xF))
      msb := or(msb, f)
      r := shr(f, r)
    }
    assembly {
      let f := shl(1, gt(r, 0x3))
      msb := or(msb, f)
      r := shr(f, r)
    }
    assembly {
      let f := gt(r, 0x1)
      msb := or(msb, f)
    }

    if (msb >= 128) r = ratio >> (msb - 127);
    else r = ratio << (127 - msb);

    int256 log_2 = (int256(msb) - 128) << 64;

    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(63, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(62, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(61, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(60, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(59, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(58, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(57, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(56, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(55, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(54, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(53, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(52, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(51, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(50, f))
    }

    tick = _getFinalTick(log_2, sqrtPriceX96);
  }

  function _getFinalTick(int256 log_2, uint160 sqrtPriceX96) internal pure returns (int24 tick) {
    // 128.128 number
    int256 log_sqrt10001 = log_2 * 255738958999603826347141;

    int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
    int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

    tick = (tickLow == tickHi)
      ? tickLow
      : (_getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library KyberStrategyErrors {

  string public constant NEED_REBALANCE = "KS-1 Need rebalance";
  string public constant WRONG_BALANCE = "KS-2 Wrong balance";
  string public constant INCORRECT_TICK_RANGE = "KS-3 Incorrect tickRange";
  string public constant INCORRECT_REBALANCE_TICK_RANGE = "KS-4 Incorrect rebalanceTickRange";
  string public constant INCORRECT_ASSET = "KS-5 Incorrect asset";
  string public constant WRONG_FEE = "KS-6 Wrong fee";
  string public constant WRONG_LIQUIDITY = "KS-7 Wrong liquidity";
  string public constant NO_REBALANCE_NEEDED = "KS-9 No rebalance needed";
  string public constant BALANCE_LOWER_THAN_FEE = "KS-10 Balance lower than fee";
  string public constant NOT_CALLBACK_CALLER = "KS-11 Not callback caller";
  string public constant UNKNOWN_SWAP_ROUTER = "KS-12 Unknown router";
  string public constant ZERO_PROFIT_HOLDER = "KS-13 Zero strategy profit holder";
  string public constant NOT_UNSTAKED = "KS-14 Liquidity must be unstaked";
}