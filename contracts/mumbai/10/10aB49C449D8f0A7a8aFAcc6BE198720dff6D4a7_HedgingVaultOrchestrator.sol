// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable-4.7.3/token/ERC1155/IERC1155Upgradeable.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total overall supply on top of the
 *      per-id supply tracking of ERC1155SupplyUpgradeable.
 *
 * Used to implement the ERC-4626 tokenized vault with shares tied to investment rounds.
 *
 * @author Roberto Cano <robercano>
 */
interface IERC1155FullSupplyUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Total amount of tokens in existence for all minted ids
     */
    function totalSupplyAll() external view returns (uint256);

    /**
     * @dev Total amount of tokens in existence with a given id.
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @dev Returns the sum of amounts of all ids owned by `account`
     */
    function balanceOfAll(address account) external view returns (uint256);

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) external view returns (bool);
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import { IPotionBuyAction } from "../interfaces/IPotionBuyAction.sol";
import { ISwapToUSDCAction } from "../interfaces/ISwapToUSDCAction.sol";
import { IVault } from "../interfaces/IVault.sol";
import { IRoundsInputVault } from "../interfaces/IRoundsInputVault.sol";
import { IRoundsOutputVault } from "../interfaces/IRoundsOutputVault.sol";
import { PotionBuyInfo } from "../interfaces/IPotionBuyInfo.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IUniswapV3Oracle } from "../interfaces/IUniswapV3Oracle.sol";
import { IPotionProtocolOracle } from "../interfaces/IPotionProtocolOracle.sol";
import { ILifecycleStates } from "../interfaces/ILifecycleStates.sol";
import "../interfaces/IHedgingVaultOrchestrator.sol";

/**  
    @title HedgingVaultOrchestrator

    @author Roberto Cano <robercano>

    @notice Helper contract to allow the operator to enter and exit a position of a hedging vault using only
    one transaction. The Hedging Vault is an investment vault using the PotionBuyAction strategy. The helper
    talks to both the vault and the action separately to configure the necessary swap routes and potion buy
    counterparties, and then enters the position. This also allows to minimize the amount of slippage in the
    Uniswap V3 swap and the Potion Protocol buy.
 */
contract HedgingVaultOrchestrator is Ownable, IHedgingVaultOrchestrator {
    IVault public investmentVault;
    IPotionBuyAction public potionBuyAction;
    ISwapToUSDCAction public swapToUSDCAction;
    IRoundsInputVault public roundsInputVault;
    IRoundsOutputVault public roundsOutputVault;

    IVaultV0.Strategy private _potionBuyStrategy;
    IVaultV0.Strategy private _swapToUSDCStrategy;

    /// CONSTRUCTOR

    /**
        @notice Constructor for the HedgingVaultOrchestrator contract

        @param potionBuyStrategy_ The default strategy to buy potions
        @param swapToUSDCStrategy_ The fallback strategy to swap to USDC
     */
    constructor(IVaultV0.Strategy memory potionBuyStrategy_, IVaultV0.Strategy memory swapToUSDCStrategy_) {
        _potionBuyStrategy = potionBuyStrategy_;
        _swapToUSDCStrategy = swapToUSDCStrategy_;
    }

    // STATE MODIFIERS

    /**
        @inheritdoc IHedgingVaultOrchestrator
    */
    function setSystemAddresses(
        address investmentVault_,
        address potionBuyAction_,
        address swapToUSDCAction_,
        address roundsInputVault_,
        address roundsOutputVault_
    ) external onlyOwner {
        investmentVault = IVault(investmentVault_);
        potionBuyAction = IPotionBuyAction(potionBuyAction_);
        swapToUSDCAction = ISwapToUSDCAction(swapToUSDCAction_);
        roundsInputVault = IRoundsInputVault(roundsInputVault_);
        roundsOutputVault = IRoundsOutputVault(roundsOutputVault_);
    }

    /**
        @inheritdoc IHedgingVaultOrchestrator

        @dev Disabling unused return because the return value of `exitPosition` is only used for composability
     */
    // slither-disable-next-line unused-return
    function nextRound(
        IUniswapV3Oracle.SwapInfo calldata potionBuyExitSwapInfo,
        PotionBuyInfo calldata potionBuyEnterBuyInfo,
        IUniswapV3Oracle.SwapInfo calldata potionBuyEnterSwapInfo,
        IUniswapV3Oracle.SwapInfo calldata swapToUSDCExitSwapInfo,
        IUniswapV3Oracle.SwapInfo calldata swapToUSDCEnterSwapInfo
    ) external onlyOwner {
        ILifecycleStates.LifecycleState vaultState = investmentVault.getLifecycleState();

        if (vaultState == ILifecycleStates.LifecycleState.Locked) {
            // Exit position
            potionBuyAction.setSwapInfo(potionBuyExitSwapInfo);
            swapToUSDCAction.setSwapInfo(swapToUSDCExitSwapInfo);

            // Return value is ignored on purpose, as the value is only returned for composability
            investmentVault.exitPosition();
        }

        // The order of operation here should not be of importance: the ratio of
        // assets/shares remains the same after either of these operations
        roundsInputVault.nextRound();
        roundsOutputVault.nextRound();

        // Enter position
        potionBuyAction.setPotionBuyInfo(potionBuyEnterBuyInfo);
        potionBuyAction.setSwapInfo(potionBuyEnterSwapInfo);
        swapToUSDCAction.setSwapInfo(swapToUSDCEnterSwapInfo);

        // Main strategy
        investmentVault.enterPositionWith(_potionBuyStrategy);
    }

    /// GETTERS

    /**
        @inheritdoc IHedgingVaultOrchestrator
     */
    function canEnterNextRound() external view returns (bool) {
        return investmentVault.canPositionBeExited();
    }

    /**
        @inheritdoc IHedgingVaultOrchestrator
     */
    function potionBuyStrategy() external view returns (IVaultV0.Strategy memory) {
        return _potionBuyStrategy;
    }

    /**
        @inheritdoc IHedgingVaultOrchestrator
     */
    function swapToUSDCStrategy() external view returns (IVaultV0.Strategy memory) {
        return _swapToUSDCStrategy;
    }
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

/**  
    @title IAction

    @author Roberto Cano <robercano>

    @notice Interface for the investment actions executed on each investment cycle

    @dev An IAction represents an investment action that can be executed by an external caller.
    This caller will typically be a Vault, but it could also be used in other strategies.

    @dev An Action receives a loan from its caller so it can perform a specific investment action.
    The asset and amount of the loan is indicated in the `enterPosition` call, and the Action can transfer
    up to the indicated amount from the caller for the specified asset, and use it in the investment.
    Once the action indicates that the investment cycle is over, by signaling it through the
    `canPositionBeExited` call, the  caller can call `exitPosition` to exit the position. Upon this call,
    the action will transfer to the caller what's remaining of the loan, and will also return this amount
    as the return value of the `exitPotision` call.

    @dev The Actions does not need to transfer all allowed assets to itself if it is not needed. It could,
    for example, transfer a small amount which is enough to cover the cost of the investment. However,
    when returning the remaining amount, it must take into account the whole amount for the loan. For
    example:
        - The Action enters a position with a loan of 100 units of asset A
        - The Action transfers 50 units of asset A to itself
        - The Action exits the position with 65 units of asset A
        - Because it was allowed to get 100 units of asset A, and it made a profit of 15,
          the returned amount in the `exitPosition` call is 115 units of asset A (100 + 15).
        - If instead of 65 it had made a loss of 30 units, the returned amount would be
          70 units of asset A (100 - 30)

    @dev The above logic helps the caller easily track the profit/loss for the last investment cycle

 */
interface IAction {
    /// EVENTS
    event ActionPositionEntered(address indexed investmentAsset, uint256 amountToInvest);
    event ActionPositionExited(address indexed investmentAsset, uint256 amountReturned);

    /// FUNCTIONS
    /**
        @notice Function called to enter the investment position

        @param investmentAsset The asset available to the action contract for the investment 
        @param amountToInvest The amount of the asset that the action contract is allowed to use in the investment

        @dev When called, the action should have been approved for the given amount
        of asset. The action will retrieve the required amount of asset from the caller
        and invest it according to its logic
     */
    function enterPosition(address investmentAsset, uint256 amountToInvest) external;

    /**
        @notice Function called to exit the investment position

        @param investmentAsset The asset reclaim from the investment position

        @return amountReturned The amount of asset that the action contract received from the caller
        plus the profit or minus the loss of the investment cycle

        @dev When called, the action must transfer all of its balance for `asset` to the caller,
        and then return the total amount of asset that it received from the caller, plus/minus
        the profit/loss of the investment cycle.

        @dev See { IAction } description for more information on `amountReturned`
     */
    function exitPosition(address investmentAsset) external returns (uint256 amountReturned);

    /**
        @notice It inficates if the position can be entered or not

        @param investmentAsset The asset for which position can be entered or not

        @return canEnter true if the position can be entered, false otherwise

        @dev The function checks if the position can be entered for the current block. If it returns
        true then it indicates that the position can be entered at any moment from the current block.
        This invariant only takes into account the current state of the action itself and not any external
        dependendencies that the action may have
     */
    function canPositionBeEntered(address investmentAsset) external view returns (bool canEnter);

    /**
        @notice It indicates if the position can be exited or not

        @param investmentAsset The asset for which position can be exited or not

        @return canExit true if the position can be exited, false otherwise

        @dev The function checks if the position can be exited for the current block. If it returns
        true then it indicates that the position can be exited at any moment from the current block.
        This invariant only takes into account the current state of the action itself and not any external
        dependendencies that the action may have
     */
    function canPositionBeExited(address investmentAsset) external view returns (bool canExit);
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import "../interfaces/IEmergencyLock.sol";
import "../interfaces/IRefundsHelper.sol";
import "../interfaces/IRolesManager.sol";
import "../interfaces/IVaultDeferredOperationUpgradeable.sol";

/**
    @title BaseRoundsVaultUpgradeable

    @notice Provides a way of investing in a target tokenized vault that has investment periods in 
    which the vault is locked. During these locked periods, the vault does not accept deposits, so
    investors need to be on the lookout for the unlocked period to deposit their funds.

    Instead this contract allows investors to deposit their funds at any point in time. In exchange
    they receive a tokenized receipt that is tied to the investment round and contains the amount of
    assets deposited.

    On each round transition, this contract will use the available funds to deposit them into the
    target vault, getting an exchange asset in return. This exchange asset is typically the target
    vault shares when the underlying asset of this vault is the same as the underlying asset of the
    target vault. Otherwise, the exchange asset is the target vault underlying asset.

    The receipts belonging to the current round can always be redeemed immediately for the underlying
    token. 

    The user can also decide to exchange the receipts belonging to previous rounds for the ERC-20 exchange
    asset kept in this contract. The exchange asset can be immediately witdrawn by burning the corresponding
    receipts.

    This contract tracks the current round and also stores the shares price of the each finished round. This
    share price is used to calculate the amount of shares that the user will receive when redeeming a receipt
    for a finished round
            
    @author Roberto Cano <robercano>
 */

// TODO: We are having hierarchy linearization issues here because of the interfaces. Remove them and
// TODO: wait for the next release of the compiler to fix it
interface IBaseRoundsVault is IVaultDeferredOperationUpgradeable {
    // EVENTS
    event NextRound(uint256 indexed newRoundNumber, uint256 prevRoundExchangeRate);
    event WithdrawExchangeAsset(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 exchangeAssetAmount,
        uint256 receiptId,
        uint256 receiptAmount
    );
    event WithdrawExchangeAssetBatch(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 exchangeAssetAmount,
        uint256[] receiptIds,
        uint256[] receiptAmounts
    );

    // PUBLIC FUNCTIONS

    /**
        @notice Stores the exchange rate for the last round, operates to push or pull from
        the target vault starts a new round
     
        @dev Only the operator can call this function
     */
    function nextRound() external;

    /**
        @notice Redeems a receipt for a certain amount of target vault shares. The amount of shares is
                calculated based on the receipt's round share price and the amount of underlying tokens
                that the receipt represents

        @param id The id of the receipt to be redeemed
        @param amount The amount of the receipt to be redeemed
        @param receiver The address that will receive the target vault shares
        @param owner The address that owns the receipt, in case the caller is not the owner
     */
    function redeemExchangeAsset(
        uint256 id,
        uint256 amount,
        address receiver,
        address owner
    ) external returns (uint256);

    /**
        @notice Same functionality as { redeemForShares } but for multiple receipts at the once

        @dev See { redeemForShares } for more details
     */
    function redeemExchangeAssetBatch(
        uint256[] calldata ids,
        uint256[] calldata amounts,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    /**
        @notice Returns the current round number
     */
    function getCurrentRound() external view returns (uint256);

    /**
        @notice Returns the asset used for the exchange
     */
    function exchangeAsset() external view returns (address);

    /**
        @notice Returns the exchange rate for the underlying to the exchange asset for a given round

        @dev It gives the amount of exchange asset that can be obtained for 1 underlying token, with the
        exchange asset decimals
     */
    function getExchangeRate(uint256 round) external view returns (uint256);
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

// TODO: Add a description of the interface
interface ICriteriaManager {
    struct Criteria {
        address underlyingAsset;
        address strikeAsset;
        bool isPut;
        uint256 maxStrikePercent;
        uint256 maxDurationInDays; // Must be > 0 for valid criteria. Doubles as existence flag.
    }
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

/**
 * @title ICurveManager
 * @notice Keeps a registry of all Curves that are known to the Potion protocol
 */
interface ICurveManager {
    struct Curve {
        int256 a_59x18;
        int256 b_59x18;
        int256 c_59x18;
        int256 d_59x18;
        int256 max_util_59x18;
    }
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

/**
    @title EmergencyLock

    @author Roberto Cano <robercano>
    
    @notice Helper contract that allows the Admin to pause all the functionality of the vault in case
    of an emergency
 */

interface IEmergencyLock {
    // FUNCTIONS

    /**
        @notice Pauses the contract
     */
    function pause() external;

    /**
        @notice Unpauses the contract
     */
    function unpause() external;
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

/**
    @title IFeeManager

    @author Roberto Cano <robercano>
    
    @notice Handles the fees that the vault fees payment to the configured recipients

    @dev The contract uses PercentageUtils to handle the fee percentages. See { PercentageUtils } for
    more information on the format and precision of the percentages.
 */

interface IFeeManager {
    /// EVENTS
    event ManagementFeeChanged(uint256 oldManagementFee, uint256 newManagementFee);
    event PerformanceFeeChanged(uint256 oldPerformanceFee, uint256 newPerformanceFee);
    event FeesRecipientChanged(address indexed oldFeeRecipient, address indexed newFeeRecipient);
    event FeesSent(
        address indexed recipient,
        address indexed token,
        uint256 managementAmount,
        uint256 performanceAmount
    );
    event FeesETHSent(address indexed recipient, uint256 managementAmount, uint256 performanceAmount);

    /// FUNCTIONS

    /**
        @notice Sets the new management fee

        @param newManagementFee The new management fee in fixed point format (See { PercentageUtils })
     */
    function setManagementFee(uint256 newManagementFee) external;

    /**
        @notice Sets the new performance fee

        @param newPerformanceFee The new performance fee in fixed point format (See { PercentageUtils })
     */
    function setPerformanceFee(uint256 newPerformanceFee) external;

    /**
        @notice Returns the current management fee

        @return The current management fee in fixed point format (See { PercentageUtils })
     */
    function getManagementFee() external view returns (uint256);

    /**
        @notice Returns the current performance fee

        @return The current performance fee in fixed point format (See { PercentageUtils })
     */
    function getPerformanceFee() external view returns (uint256);

    /**
        @notice Sets the new fees recipient
     */
    function setFeesRecipient(address payable newFeesRecipient) external;

    /**
        @notice Returns the current fees recipient
     */
    function getFeesRecipient() external view returns (address);
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import { PotionBuyInfo } from "../interfaces/IPotionBuyInfo.sol";
import { IVaultV0 } from "../interfaces/IVaultV0.sol";
import { IUniswapV3Oracle } from "../interfaces/IUniswapV3Oracle.sol";

/**  
    @title IHedgingVaultOrchestrator

    @author Roberto Cano <robercano>

    @notice Helper contract to allow the operator to enter and exit a position of a hedging vault using only
    one transaction. The Hedging Vault is an investment vault using the PotionBuyAction strategy. This contract
    helps orchestrate the Hedging Vault and the Rounds Vault in order to transition from one round to the next.

    @dev The `nextRound` function should be called once the previous round has ended and the payout is available.
 */
interface IHedgingVaultOrchestrator {
    /// STATE MODIFIERS

    /**
        @notice Sets the addresses of the vault and the action to be used to enter and exit the position.

        @param hedgingVault The vault to be used to enter and exit the position.
        @param potionBuyAction The action to be used to enter and exit the position.
        @param swapToUSDCAction The action to be used to swap to USDC.
        @param roundsInputVault The rounds input vault to be used to enter and exit the position.
        @param roundsOutputVault The rounds output vault to be used to enter and exit the position.
    */
    function setSystemAddresses(
        address hedgingVault,
        address potionBuyAction,
        address swapToUSDCAction,
        address roundsInputVault,
        address roundsOutputVault
    ) external;

    /**
        @notice Cycles the hedging vault system and goes to the next round. If it is the very first round (i.e. the vault
        is not locked), it just notifies the rounds vaults for the next round and enters the position.

        If it is not the very first round, it exits the position, notifies the rounds vaults for the next round, and then
        enters the position again.

        @param prevRoundExitSwapInfo The Uniswap V3 route to swap the received pay-out from USDC back to the hedged asset
        @param nextRoundPotionBuyInfo List of counterparties to use for the Potion Protocol buy
        @param nextRoundEnterSwapInfo The Uniswap V3 route to swap some hedged asset for USDC to pay the Potion Protocol premium
        @param swapToUSDCExitSwapInfo The Uniswap V3 route to swap back the full investment amount from USDC in case the Potion Buy
                                      action reverted on the last round
        @param swapToUSDCEnterSwapInfo The Uniswap V3 route to swap the full investment amount for USDC in case the Potion Buy action
                                       reverts

        @dev Only the owner of the contract (i.e. the Operator) can call this function
     */
    function nextRound(
        IUniswapV3Oracle.SwapInfo calldata prevRoundExitSwapInfo,
        PotionBuyInfo calldata nextRoundPotionBuyInfo,
        IUniswapV3Oracle.SwapInfo calldata nextRoundEnterSwapInfo,
        IUniswapV3Oracle.SwapInfo calldata swapToUSDCExitSwapInfo,
        IUniswapV3Oracle.SwapInfo calldata swapToUSDCEnterSwapInfo
    ) external;

    /// GETTERS

    /**
        @notice Convenience function to know if the next round can be entered or not

        @dev This checks if the position can be exited. This cannot account for the possibility of the position
        to be entered as this information is not made available until the position is exited
     */
    function canEnterNextRound() external view returns (bool);

    /**
        @notice Returns the strategy for buying potions
     */
    function potionBuyStrategy() external view returns (IVaultV0.Strategy memory);

    /**
        @notice Returns the strategy for swapping to USDC
     */
    function swapToUSDCStrategy() external view returns (IVaultV0.Strategy memory);
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

/**
    @title ILifecycleStates

    @author Roberto Cano <robercano>
    
    @notice Handles the lifecycle of the hedging vault and provides the necessary modifiers
    to scope functions that must only work in certain states. It also provides a getter
    to query the current state and an internal setter to change the state
 */

interface ILifecycleStates {
    /// STATES

    /**
        @notice States defined for the vault. Although the exact meaning of each state is
        dependent on the HedgingVault contract, the following assumptions are made here:
            - Unlocked: the vault accepts immediate deposits and withdrawals and the specific
            configuration of the next investment strategy is not yet known.
            - Committed: the vault accepts immediate deposits and withdrawals but the specific
            configuration of the next investment strategy is already known
            - Locked: the vault is locked and cannot accept immediate deposits or withdrawals. All
            of the assets managed by the vault are locked in it. It could accept deferred deposits
            and withdrawals though
     */
    enum LifecycleState {
        Unlocked,
        Committed,
        Locked
    }

    /// EVENTS
    event LifecycleStateChanged(LifecycleState indexed prevState, LifecycleState indexed newState);

    /// FUNCTIONS

    /**
        @notice Function to get the current state of the vault
        @return The current state of the vault
     */
    function getLifecycleState() external view returns (LifecycleState);
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

// TODO: Add a description of the interface
interface IOtoken {
    function underlyingAsset() external view returns (address);

    function strikeAsset() external view returns (address);

    function collateralAsset() external view returns (address);

    function strikePrice() external view returns (uint256);

    function expiryTimestamp() external view returns (uint256);

    function isPut() external view returns (bool);

    function init(
        address _addressBook,
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external;

    function getOtokenDetails()
        external
        view
        returns (
            address,
            address,
            address,
            uint256,
            uint256,
            bool
        );

    function mintOtoken(address account, uint256 amount) external;

    function burnOtoken(address account, uint256 amount) external;
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import "./IAction.sol";
import "./IUniswapV3Oracle.sol";
import "./IPotionProtocolOracle.sol";

/**
    @title IPotionBuyAction

    @author Roberto Cano <robercano>

    @dev See { PotionBuyAction }
    @dev See { PotionBuyActionV0 }

    @dev This interface is not inherited by PotionBuyAction itself and only serves to expose the functions
    that are used by the Operator to configure parameters. In particular it is used by { HedgingVaultOrchestrator }
    to aid in the operation of the vault
    
 */
/* solhint-disable-next-line no-empty-blocks */
interface IPotionBuyAction is IAction, IUniswapV3Oracle, IPotionProtocolOracle {
    // Empty on purpose
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import { IPotionLiquidityPool } from "../interfaces/IPotionLiquidityPool.sol";

/**    
    @title IPotionBuyInfo
        
    @author Roberto Cano <robercano>

    @notice Structure for the PotionBuyInfo
 */

/**
        @notice The information required to buy a specific potion with a specific maximum premium requirement

        @custom:member sellers The list of liquidity providers that will be used to buy the potion
        @custom:member targetPotionAddress The address of the potion (otoken) to buy
        @custom:member underlyingAsset The address of the underlying asset of the potion (otoken) to buy
        @custom:member strikePriceInUSDC The strike price of the potion (otoken) to buy, in USDC, with 8 decimals
        @custom:member expirationTimestamp The expiration timestamp of the potion (otoken) to buy
        @custom:member expectedPremiumInUSDC The expected premium to be paid for the given order size
                       and the given sellers, in USDC
     */
struct PotionBuyInfo {
    IPotionLiquidityPool.CounterpartyDetails[] sellers;
    address targetPotionAddress;
    address underlyingAsset;
    uint256 strikePriceInUSDC;
    uint256 expirationTimestamp;
    uint256 expectedPremiumInUSDC;
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import "./ICurveManager.sol";
import "./ICriteriaManager.sol";

import "./IOtoken.sol";

// TODO: Add a description of the interface
interface IPotionLiquidityPool {
    /*
        @notice The details of a given counterparty that will be used to buy a potion

        @custom:member lp The LP to buy from
        @custom:member poolId The pool (belonging to LP) that will colalteralize the otoken
        @custom:member curve The curve used to calculate the otoken premium
        @custom:member criteria The criteria associated with this curve, which matches the otoken
        @custom:member orderSizeInOtokens The number of otokens to buy from this particular counterparty
    */
    struct CounterpartyDetails {
        address lp;
        uint256 poolId;
        ICurveManager.Curve curve;
        ICriteriaManager.Criteria criteria;
        uint256 orderSizeInOtokens;
    }

    /**
        @notice The data associated with a given pool of capital, belonging to one LP

        @custom:member total The total (locked or unlocked) of capital in the pool, denominated in collateral tokens
        @custom:member locked The amount of locked capital in the pool, denominated in collateral tokens
        @custom:member curveHash Identifies the curve to use when pricing the premiums charged for any otokens
                                 sold (& collateralizated) by this pool
        @custom:member criteriaSetHash Identifies the set of otokens that this pool is willing to sell (& collateralize)
    */
    struct PoolOfCapital {
        uint256 total;
        uint256 locked;
        bytes32 curveHash;
        bytes32 criteriaSetHash;
    }

    /**
        @notice The keys required to identify a given pool of capital in the lpPools map.

        @custom:member lp The LP that owns the pool
        @custom:member poolId The ID of the pool
    */
    struct PoolIdentifier {
        address lp;
        uint256 poolId;
    }

    /**
       @notice Buy a OTokens from the specified list of sellers.
       
       @param _otoken The identifier (address) of the OTokens being bought.
       @param _sellers The LPs to buy the new OTokens from. These LPs will charge a premium to collateralize the otoken.
       @param _maxPremium The maximum premium that the buyer is willing to pay, denominated in collateral tokens (wei) and aggregated across all sellers
       
       @return premium The aggregated premium paid.
     */
    function buyOtokens(
        IOtoken _otoken,
        CounterpartyDetails[] memory _sellers,
        uint256 _maxPremium
    ) external returns (uint256 premium);

    /**
        @notice Creates a new otoken, and then buy it from the specified list of sellers.
     
        @param underlyingAsset A property of the otoken that is to be created.
        @param strikeAsset A property of the otoken that is to be created.
        @param collateralAsset A property of the otoken that is to be created.
        @param strikePrice A property of the otoken that is to be created.
        @param expiry A property of the otoken that is to be created.
        @param isPut A property of the otoken that is to be created.
        @param sellers The LPs to buy the new otokens from. These LPs will charge a premium to collateralize the otoken.
        @param maxPremium The maximum premium that the buyer is willing to pay, denominated in collateral tokens (wei) and aggregated across all sellers
        
        @return premium The total premium paid.
     */
    function createAndBuyOtokens(
        address underlyingAsset,
        address strikeAsset,
        address collateralAsset,
        uint256 strikePrice,
        uint256 expiry,
        bool isPut,
        CounterpartyDetails[] memory sellers,
        uint256 maxPremium
    ) external returns (uint256 premium);

    /**
       @notice Retrieve unused collateral from Opyn into this contract. Does not redistribute it to our (unbounded number of) LPs.
               Redistribution can be done by calling redistributeSettlement(addresses).

       @param _otoken The identifier (address) of the expired OToken for which unused collateral should be retrieved.
     */
    function settleAfterExpiry(IOtoken _otoken) external;

    /**
       @notice Retrieve unused collateral from Opyn, and redistribute it to the specified LPs.
       
       @param _otoken The identifier (address) of the expired otoken for which unused collateral should be retrieved.
       @param _pools The pools of capital to which the collateral should be redistributed. These pools must be (a subset of) the pools that provided collateral for the specified otoken.
     */
    function settleAndRedistributeSettlement(IOtoken _otoken, PoolIdentifier[] calldata _pools) external;

    /**
        @notice Get the ID of the existing Opyn vault that Potion uses to collateralize a given OToken.
        
        @param _otoken The identifier (token contract address) of the OToken. Not checked for validity in this view function.
        
        @return The unique ID of the vault, > 0. If no vault exists, the returned value will be 0
     */
    function getVaultId(IOtoken _otoken) external view returns (uint256);

    /**
        @dev Returns the data about the pools of capital, indexed first by LP
             address and then by an (arbitrary) numeric poolId

        @param lpAddress The address of the LP that owns the pool
        @param poolId The ID of the pool owned by the LP

        @return The data about the pool of capital
    */
    function lpPools(address lpAddress, uint256 poolId) external view returns (PoolOfCapital memory);
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import { IPotionLiquidityPool } from "./IPotionLiquidityPool.sol";
import { PotionBuyInfo } from "./IPotionBuyInfo.sol";

/**
    @title IPotionProtocolOracle

    @notice Oracle contract for the Potion Protocol potion buy. It takes care of holding the information
    about the counterparties that will be used to buy a particular potion (potion) with a maximum allowed
    premium

    @dev It is very basic and it just aims to abstract the idea of an Oracle into a separate contract
    but it is still very coupled with PotionProtocolHelperUpgradeable
 */
interface IPotionProtocolOracle {
    /// FUNCTIONS

    /**
        @notice Sets the potion buy information for a specific potion

        @param info The information required to buy a specific potion with a specific maximum premium requirement

        @dev Only the Operator can call this function
     */
    function setPotionBuyInfo(PotionBuyInfo calldata info) external;

    /**
        @notice Gets the potion buy information for a given OToken

        @param underlyingAsset The address of the underlying token of the potion
        @param expirationTimestamp The timestamp when the potion expires

        @return The Potion Buy information for the given potion

        @dev See { PotionBuyInfo }

     */
    function getPotionBuyInfo(address underlyingAsset, uint256 expirationTimestamp)
        external
        view
        returns (PotionBuyInfo memory);
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

/**
    @title IRefundsHelper

    @author Roberto Cano <robercano>
    
    @notice Helper contract that allows the Admin to refund tokens or ETH sent to the vault
    by mistake. At construction time it receives the list of tokens that cannot be refunded.
    Those tokens are typically the asset managed by the vault and any intermediary tokens
    that the vault may use to manage the asset.
 */
interface IRefundsHelper {
    /// FUNCTIONS

    /**
        @notice Refunds the given amount of tokens to the given address
        @param token address of the token to be refunded
        @param amount amount of tokens to be refunded
        @param recipient address to which the tokens will be refunded
     */
    function refund(
        address token,
        uint256 amount,
        address recipient
    ) external;

    /**
        @notice Refunds the given amount of ETH to the given address
        @param amount amount of tokens to be refunded
        @param recipient address to which the tokens will be refunded
     */
    function refundETH(uint256 amount, address payable recipient) external;

    /// GETTERS

    /**
        @notice Returns whether the given token is refundable or not

        @param token address of the token to be checked

        @return true if the token is refundable, false otherwise
     */
    function canRefund(address token) external view returns (bool);

    /**
        @notice Returns whether the ETH is refundable or not

        @return true if ETH is refundable, false otherwise
     */
    function canRefundETH() external view returns (bool);
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable-4.7.3/access/IAccessControlEnumerableUpgradeable.sol";

/**
    @title IRolesManager

    @author Roberto Cano <robercano>
    
    @notice The RolesManager contract is a helper contract that provides a three access roles: Admin,
    Strategist and Operator. The scope of the different roles is as follows:
      - Admin: The admin role is the only role that can change the other roles, including the Admin
      role itself. 
      - Strategist: The strategist role is the one that can change the vault and action parameters
      related to the investment strategy. Things like slippage percentage, maximum premium, principal
      percentages, etc...
      - Operator: The operator role is the one that can cycle the vault and the action through its
      different states

    @dev The Admin can always change the Strategist address, Operator address and also change the Admin address.
    The Strategist and Operator roles have no special access except the access given explcitiely by their
    respective modifiers `onlyStrategist` and `onlyOperator`.
 */

/* solhint-disable-next-line no-empty-blocks */
interface IRolesManager is IAccessControlEnumerableUpgradeable {
    // Empty on purpose
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import "./IBaseRoundsVault.sol";

/**
    @title IRoundsInputVault

    @notice The IRoundsInputVault contract allows users to deposit funds into this contract while the
    target vault is locked, and receipts are minted to the users for this deposits. Upon round completion, the
    funds are transferred to the target vault and the corresponding shares are collected.

    Users can then exchange their receipts from previous rounds for the corresponding shares held in this vault.

    @author Roberto Cano <robercano>
 */
interface IRoundsInputVault is IBaseRoundsVault {
    // EVENTS
    event AssetsDeposited(uint256 indexed roundId, address indexed account, uint256 assets, uint256 shares);
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import "./IBaseRoundsVault.sol";

/**
    @title IRoundsOutputVault

    @notice The IRoundsOutputVault contract allows users to deposit shares from the target vault into
    this contract while the  target vault is locked, and receipts are minted to the users for this deposits. Upon
    round completion, the shares are redeemed in the target vault and the corresponding funds are collected.

    Users can then exchange their receipts from previous rounds for the corresponding funds held in this vault.

    @author Roberto Cano <robercano>
 */
interface IRoundsOutputVault is IBaseRoundsVault {
    // EVENTS
    event SharesRedeemed(uint256 indexed roundId, address indexed account, uint256 shares, uint256 assets);
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import "./IAction.sol";
import "./IUniswapV3Oracle.sol";

/**
    @title ISwapToUSDCAction

    @author Roberto Cano <robercano>

    @dev See { SwapToUSDCAction }
    @dev See { SwapToUSDCActionV0 }

    @dev This interface is not inherited by SwapToUSDCAction itself and only serves to expose the functions
    that are used by the Operator to configure parameters. In particular it is used by { HedgingVaultOrchestrator }
    to aid in the operation of the vault
    
 */
/* solhint-disable-next-line no-empty-blocks */
interface ISwapToUSDCAction is IAction, IUniswapV3Oracle {
    // Empty on purpose
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

/**
    @title IUniswapV3Oracle

    @notice Oracle contract for Uniswap V3 swaps. It takes care of holding information about the
    path to use for a specific swap, and the expected price for a that swap.
 */
interface IUniswapV3Oracle {
    /**
        @notice The information required to perform a safe swap

        @custom:member inputToken The address of the input token in the swap
        @custom:member outputToken The address of the output token in the swap
        @custom:member expectedPriceRate The expected price of the swap as a fixed point SD59x18 number
        @custom:member swapPath The path to use for the swap as an ABI encoded array of bytes

        @dev See [Multi-hop Swaps](https://docs.uniswap.org/protocol/guides/swaps/multihop-swaps) for
        more information on the `swapPath` format
     */
    struct SwapInfo {
        address inputToken;
        address outputToken;
        uint256 expectedPriceRate;
        bytes swapPath;
    }

    /// FUNCTIONS

    /**
        @notice Sets the swap information for an input/output token pair. The information
        includes the swap path and the expected swap price

        @param info The swap information for the pair

        @dev Only the Keeper role can call this function

        @dev See { SwapInfo }
     */
    function setSwapInfo(SwapInfo calldata info) external;

    /**
        @notice Gets the swap information for the given input/output token pair

        @param inputToken The address of the input token in the swap
        @param outputToken The address of the output token in the swap

        @return The swap information for the pair

     */
    function getSwapInfo(address inputToken, address outputToken) external view returns (SwapInfo memory);
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import { IRolesManager } from "../interfaces/IRolesManager.sol";
import { ILifecycleStates } from "../interfaces/ILifecycleStates.sol";
import { IEmergencyLock } from "../interfaces/IEmergencyLock.sol";
import { IRefundsHelper } from "../interfaces/IRefundsHelper.sol";
import { IFeeManager } from "../interfaces/IFeeManager.sol";
import { IVaultV0 } from "../interfaces/IVaultV0.sol";

/**  
    @title IVault

    @author Roberto Cano <robercano>

    @notice Interface for the a vault that executes investment actions on each investment cycle

    @dev An IVault represents a vault that contains a set of investment actions. When entering the
    position, all the actions in the vault are executed in order, one after the other. If all
    actions succeed, then the position is entered. Once the position can be exited, the investment
    actions are also exited and the profit/loss of the investment cycle is realized.
 */
/* solhint-disable-next-line no-empty-blocks */
interface IVault is IRolesManager, ILifecycleStates, IEmergencyLock, IRefundsHelper, IFeeManager, IVaultV0 {
    // Empty on purpose
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./IVaultWithReceiptsUpgradeable.sol";

/**
 * @notice Interface of the ERC4626 "Tokenized Vault Standard", modified to emit ERC-1155 share tokens
 *         When depositing, the user of this contract must indicate for which id they are depositing. The
 *         emitted ERC-1155 token will be minted used that id, thus generating a receipt for the deposit
 *
 * @dev The `withdraw` function, along with the `previewWithdraw` and `maxWithdraw` functions
 *      have been removed because the only way to implement them is to support enumeration
 *      for the ERC-1155 tokens, which is quite heavy in gas costs.
 *
 * @author Roberto Cano <robercano>
 */
interface IVaultDeferredOperationUpgradeable is IVaultWithReceiptsUpgradeable {
    /**
     * @dev Returns the target vault for which this vault is accepting deposits
     */
    function vault() external view returns (address vaultAddress);
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import { IRolesManager } from "../interfaces/IRolesManager.sol";
import { ILifecycleStates } from "../interfaces/ILifecycleStates.sol";
import { IEmergencyLock } from "../interfaces/IEmergencyLock.sol";
import { IRefundsHelper } from "../interfaces/IRefundsHelper.sol";
import { IFeeManager } from "../interfaces/IFeeManager.sol";

/**  
    @title IVault

    @author Roberto Cano <robercano>

    @notice Interface for the V0 of the vault that executes investment actions on each investment
            cycle
 */
interface IVaultV0 {
    /// STRUCTS

    /**
        @notice Strategy to execute when entering the position

        @custom:member actionsIndexes The indexes of the actions to be executed for the strategy
        @custom:member principalPercentages The percentage of the total amount to be invested in each action

        @dev It consists of a list of actions indexes to be executed in the order indicated in the array
             upon entering the position. This can be used to select the specific actions to be executed
             when implementing fallback strategies
     */
    struct Strategy {
        uint256[] actionsIndexes;
        uint256[] principalPercentages;
    }

    /// EVENTS
    event VaultPositionEntered(uint256 totalPrincipalAmount, uint256 principalAmountInvested, Strategy strategy);
    event VaultPositionExited(uint256 newPrincipalAmount, Strategy strategy);

    /// ERRORS
    error InvestmentTotalTooHigh(uint256 actualAmountInvested, uint256 maxAmountToInvest);
    error PrincipalPercentagesMismatch(uint256 actionsLength, uint256 percentagesLength);
    error PrincipalPercentageOutOfRange(Strategy strategy, uint256 index);
    error PrincipalPercentagesSumMoreThan100(Strategy strategy);

    /// FUNCTIONS

    /**
        @notice Function called to enter the investment position

        @dev When called, the vault will enter the position of all configured actions. For each action
        it will approve each action for the configured principal percentage so each action can access
        the funds in order to execute the specific investment strategy

        @dev Once the Vault enters the investment position no more immediate deposits or withdrawals
        are allowed
     */
    function enterPosition() external;

    /**
        @notice Function called to enter the investment position

        @param strategy Strategy to execute when entering the position, as a list of actions indexes

        @dev See { enterPosition } for more details

        @dev This variation of enter position allows to specify a strategy to execute when entering, as a list
             of actions indexes to be executed in the order indicated in the array. This can be used to select
                the specific actions to be executed when implementing fallback strategies
     */
    function enterPositionWith(Strategy calldata strategy) external;

    /**
        @notice Function called to exit the investment position

        @return newPrincipalAmount The final amount of principal that is in the vault after the actions
        have exited their positions

        @dev When called, the vault will exit the position of all configured actions. Each action will send
        back the remaining funds (including profit or loss) to the vault
     */
    function exitPosition() external returns (uint256 newPrincipalAmount);

    /**
        @notice It indicates if the position can be entered or not

        @return canEnter true if the position can be entered, false otherwise

        @dev The function checks if the position can be entered for the current block. If it returns
        true then it indicates that the position can be entered at any moment from the current block.
        This invariant only takes into account the current state of the vault itself and not any external
        dependendencies that the vault or the actions may have
     */
    function canPositionBeEntered() external view returns (bool canEnter);

    /**
        @notice It indicates if the position can be entered or not with the given strategy

        @return canEnter true if the position can be entered, false otherwise

        @dev The function checks if the position can be entered for the current block and the given set of
        action indexes. If it returns true then it indicates that the position can be entered at any moment
        from the current block. This invariant only takes into account the current state of the vault itself
        and not any external dependendencies that the vault or the actions may have
     */
    function canPositionBeEnteredWith(Strategy calldata strategy) external view returns (bool canEnter);

    /**
        @notice It indicates if the position can be exited or not

        @return canExit true if the position can be exited, false otherwise

        @dev The function checks if the position can be exited for the current block. If it returns
        true then it indicates that the position can be exited at any moment from the current block.
        This invariant only takes into account the current state of the vault itself and not any external
        dependendencies that the vault or the actions may have
     */
    function canPositionBeExited() external view returns (bool canExit);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable-4.7.3/token/ERC1155/IERC1155Upgradeable.sol";
import "../extensions/interfaces/IERC1155FullSupplyUpgradeable.sol";

/**
    @notice Interface of the ERC4626 "Tokenized Vault Standard", modified to emit ERC-1155 receipts.
    When depositing a receipt is generated using an id provided by implementor of this interface.
    The receipt should contain the deposit amount. The id can be used freely to identify extra information
    about the deposit.
    
    @dev The `withdraw` function, along with the `previewWithdraw` and `maxWithdraw` functions
    have been removed because the only way to implement them is to support enumeration
    for the ERC-1155 tokens, which is quite heavy in gas costs.

    @dev Although the only withdrawal functions are `redeem` and `reedeemBatch` the events have been
    kept with the original names `Withdraw` and `WithdrawBatch` for backwards consistency.
 
    @dev This interface is a copy-paste of OpenZeppelin's `IERC4626Upgradeable.sol` with some modifications to
    support the ERC-1155 receipts.

    @author Roberto Cano <robercano>
 */
interface IVaultWithReceiptsUpgradeable is IERC1155FullSupplyUpgradeable {
    event DepositWithReceipt(address indexed caller, address indexed receiver, uint256 id, uint256 assets);

    event RedeemReceipt(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 id,
        uint256 amount
    );
    event RedeemReceiptBatch(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256[] ids,
        uint256[] amounts
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Mints shares Vault shares with the given id to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(
        uint256 sharesId,
        uint256 sharesAmount,
        address receiver,
        address owner
    ) external returns (uint256 assets);

    /**
     * @dev Burns each batch of shares and the specific amounts and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the WithdrawBatch event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeemBatch(
        uint256[] memory sharesIds,
        uint256[] memory sharesAmounts,
        address receiver,
        address owner
    ) external returns (uint256 assets);
}