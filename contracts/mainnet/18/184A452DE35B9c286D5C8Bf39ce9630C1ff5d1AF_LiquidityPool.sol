pragma solidity 0.8.13;

import {AccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ILiquidityPool} from "./ILiquidityPool.sol";
import {RegistrySatellite, YoloRegistry, CoreCommon} from "./RegistrySatellite.sol";
import {YoloShareTokens} from "../tokens/YoloShareTokens.sol";
import {YoloWallet} from "./YoloWallet.sol";
import {IYoloGame} from "../game/IYoloGame.sol";
import {USDC_TOKEN, YOLO_SHARES, YOLO_WALLET, ADMIN_ROLE, USDC_DECIMALS_FACTOR} from "../utils/constants.sol";
import {ZAA_USDCToken, ZAA_YoloWallet} from "../utils/errors.sol";

// import "hardhat/console.sol";

/**
 * @title LiquidityPool
 * @author Garen Vartanian (@cryptokiddies)
 * @author Yogesh Srihari(@yogeshgo05)
 * @dev :
 *  - grant a minter role to this contract from admin that allows for token minting
 *  - ability for holders to burn (destroy) their tokens
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} via {RegistrySatellite} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 */
contract LiquidityPool is ILiquidityPool, YoloShareTokens, RegistrySatellite {
    using SafeERC20 for IERC20;

    uint256 constant TWO_THOUSAND_TOKENS = 2000 * USDC_DECIMALS_FACTOR;

    // immutable because if either contract changes, a new LP cntct should be deployed anyway, so token migration can commence in clear, sequential steps
    IERC20 public immutable stablecoinTokenContract;
    YoloWallet public immutable walletContract;

    uint256 public protectionFactor;
    uint256 public marketLimit;
    uint256 public minimumDepositAmount;

    event MarketLimitUpdate(uint256 newLimitValue);

    error TotalSharesExceeded();
    error BurnRequirementNotMet();
    error DepositMinimumShortfall(
        uint256 cumulativeDepositAmount,
        uint256 minimumDepositAmount
    );

    modifier whenNotLPBalance() {
        require(totalSupply() == 0, "LP tokens are in circulation");
        _;
    }

    modifier whenLPBalance() {
        require(totalSupply() != 0, "must mint initial LP tokens");
        _;
    }

    modifier gtMinimumDepositBalance(uint256 depositAmount) {
        uint256 totalSupply = totalSupply();

        uint256 previousBalance = totalSupply > 0
            ? (balanceOf(msg.sender) * walletContract.balances(address(this))) /
                totalSupply
            : 0;

        uint256 cumulativeDepositAmount = depositAmount + previousBalance;

        if (cumulativeDepositAmount < minimumDepositAmount) {
            revert DepositMinimumShortfall(
                cumulativeDepositAmount,
                minimumDepositAmount
            );
        }
        _;
    }

    constructor(address registryContractAddress_)
        RegistrySatellite(registryContractAddress_)
    {
        YoloRegistry yoloRegistryContract = YoloRegistry(
            registryContractAddress_
        );

        address usdcTokenAddress = yoloRegistryContract.getContractAddress(
            USDC_TOKEN
        );

        if (usdcTokenAddress == address(0)) revert ZAA_USDCToken();

        address yoloWalletAddress = yoloRegistryContract.getContractAddress(
            YOLO_WALLET
        );

        if (yoloWalletAddress == address(0)) revert ZAA_YoloWallet();

        stablecoinTokenContract = IERC20(usdcTokenAddress);
        walletContract = YoloWallet(yoloWalletAddress);

        protectionFactor = 1000;
        minimumDepositAmount = 400 * USDC_DECIMALS_FACTOR;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlEnumerable, YoloShareTokens)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Check how many USDC tokens can be redeemed in exchange for burning LP shares. If burn value is greater than total share amount, call will fail.
     * @param burnAmount Amount of LP share to burn for USDC withdrawal.
     **/
    function getTokensRedeemed(uint256 burnAmount)
        external
        view
        returns (uint256 tokenTransferAmount)
    {
        uint256 sharesTotalSupply = totalSupply();
        if (burnAmount > sharesTotalSupply) {
            revert TotalSharesExceeded();
        }

        tokenTransferAmount =
            (burnAmount * walletContract.balances(address(this))) /
            sharesTotalSupply;
    }

    /**
     * @notice Sets `protectionFactor` value as part of additional guard layer on higher frequency `marketLimit` adjustments. See: `setMarketLimit` below.
     * @dev This value should float between ~500-20000 and updated only on big pool swings.
     * @param newFactor Simple factor to denominate acceptable marketLimit value in `setMarketLimit`.
     **/
    function setProtectionFactor(uint256 newFactor)
        external
        onlyAuthorized(ADMIN_ROLE)
    {
        protectionFactor = newFactor;
    }

    /**
     * @notice Sets `minimumDepositAmount` value regulatory mechanism on liquidity provision.
     * @dev This value should be denominated with 6 decimal places per USDC contract.
     * @param newMinimum Minimum USDC maintenance amount for liquidity provision.
     **/
    function setMinimumDepositAmount(uint256 newMinimum)
        external
        onlyAuthorized(ADMIN_ROLE)
    {
        minimumDepositAmount = newMinimum;
    }

    /**
     * @notice Mints initial LP shares if none exist.
     * @dev Contract will be in paused state as expected. Minting initial shares will add to contract USDC token balance
     * and unpause contract state. IF a minimum amount of 1000 is transferred from LP mint to zero address as guard against "donation" dilution gaming of LP contract, it is intended to prevent LP token dominance by transferring a bunch of USDC token after initial LP minting. If not, LP should be minted 1:1 with USDC token deposit amount. There is a slim possibility this is called more than once, in which case the caller will inherit USDC token dust.
     * @param initialAmount Amount of USDC deposited when no shares exist.
     **/
    function mintInitialShares(uint256 initialAmount)
        external
        whenNotLPBalance
        gtMinimumDepositBalance(initialAmount)
    {
        address sender = msg.sender;

        stablecoinTokenContract.safeTransferFrom(
            sender,
            address(walletContract),
            initialAmount
        );

        uint256 adjustmentFactor = 10**decimals() / USDC_DECIMALS_FACTOR;

        _mint(sender, initialAmount * adjustmentFactor);

        walletContract.updateLiquidityPoolBalance(initialAmount);
    }

    /**
     * @notice Mints LP shares on USDC token deposit.
     * @dev Contract must be in unpaused state. note: an issue addressed by Uniswap V2 whitepaper is dilution attack (dumping large amounts of token to LP contract directly via token contract), which is mitigated by subtracting and transferring 1000 wei of share tokens on initial mint to zero address. Not likely necessary.
     * @param depositAmount Amount of USDC deposited to contract.
     **/
    function mintLpShares(uint256 depositAmount)
        external
        whenLPBalance
        gtMinimumDepositBalance(depositAmount)
    {
        address sender = msg.sender;

        stablecoinTokenContract.safeTransferFrom(
            sender,
            address(walletContract),
            depositAmount
        );

        // should be 1:1 with current implementation
        uint256 newShareAmount = (totalSupply() * depositAmount) /
            walletContract.balances(address(this));

        _mint(sender, newShareAmount);

        walletContract.updateLiquidityPoolBalance(depositAmount);
    }

    /**
     * @notice Burns LP shares in exchange for share of pool USDC tokens. If provider balance remaining in pool is less than current `minimumDepositAmount`, then all LP tokens must be burned for redemption.
     * @dev  Will require share token approval from sender to contract to burn. Redemption amount check is to prevent minimum deposit circumvention.
     * @param burnAmount Amount of LP share to burn for USDC withdrawal.
     **/
    function burnLpShares(uint256 burnAmount) external {
        address sender = msg.sender;
        // !!! must call supply before burn
        uint256 sharesTotalSupply = totalSupply();
        uint256 senderTotalLP = balanceOf(sender);

        uint256 tokenTransferAmount = (burnAmount *
            walletContract.balances(address(this))) / sharesTotalSupply;

        if (burnAmount != senderTotalLP) {
            uint256 currentAccount = (senderTotalLP *
                walletContract.balances(address(this))) / sharesTotalSupply;

            if (currentAccount - tokenTransferAmount < minimumDepositAmount) {
                revert BurnRequirementNotMet();
            }
        }

        _burn(sender, burnAmount);

        // transfer comes from {YoloWallet} contract
        walletContract.reduceLiquidityPoolBalance(sender, tokenTransferAmount);
    }

    /**
     * @notice Set a market limit based on a small fraction of total USDC token balance and no more than 2,000 USDC tokens.
     * @dev  Query `marketLimit` regularly to adjust.
     * @param newLimitValue
     **/
    function setMarketLimit(uint256 newLimitValue)
        external
        onlyAuthorized(ADMIN_ROLE)
    {
        require(
            newLimitValue < TWO_THOUSAND_TOKENS &&
                newLimitValue <
                walletContract.balances(address(this)) / protectionFactor,
            "new limit val exceeds constraint"
        );

        marketLimit = newLimitValue;

        emit MarketLimitUpdate(newLimitValue);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

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
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity 0.8.13;

interface ILiquidityPool {
    // **** restricted ****
    function setProtectionFactor(uint256 newFactor) external;

    function setMarketLimit(uint256 newLimitValue) external;

    // ********

    function mintInitialShares(uint256 initialAmount) external;

    function mintLpShares(uint256 depositAmount) external;

    function burnLpShares(uint256 burnAmount) external;
}

pragma solidity 0.8.13;

import {CoreCommon} from "./CoreCommon.sol";
import {YoloRegistry} from "./YoloRegistry.sol";
import {ADMIN_ROLE} from "../utils/constants.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {ZAA_YoloRegistry} from "../utils/errors.sol";

/**
 * @title RegistrySatellite
 * @author Garen Vartanian (@cryptokiddies)
 * @dev Base contract for all Yolo contracts that depend on {YoloRegistry} for references on other contracts (particularly their active addresses), supported assets (and their token addresses if applicable), registered game contracts, and master admins
 */
abstract contract RegistrySatellite is CoreCommon {
    // TODO: make `yoloRegistryContract` a constant hard-coded value after registry deployment

    YoloRegistry public immutable yoloRegistryContract;

    constructor(address yoloRegistryAddress_) {
        if (yoloRegistryAddress_ == address(0)) revert ZAA_YoloRegistry();

        yoloRegistryContract = YoloRegistry(yoloRegistryAddress_);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    event AddressSet(
        bytes32 indexed contractIdentifier,
        address indexed contractAddress
    );

    /**
     * @notice Check for authorization on local contract and fallback to {YoloRegistry} for additional checks.
     * @dev !!! should we simplify and replace access control on satellite contracts to simple owner address role, i.e., replace first check `hasRole(role, msg.sender)` with `msg.sender == owner`? Or do we move all role checks into registry contract?
     * @param role Role key to check authorization on.
     **/
    modifier onlyAuthorized(bytes32 role) {
        _checkAuthorization(role);
        _;
    }

    function _checkAuthorization(bytes32 role) internal view {
        if (
            !hasRole(role, msg.sender) &&
            !yoloRegistryContract.hasRole(role, msg.sender)
        ) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(msg.sender), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @notice Check for authorization on {GameInstance} contract registered in {YoloRegistry}.
     * @dev important to audit security on this call
     **/
    modifier onlyGameContract() {
        require(
            yoloRegistryContract.registeredGames(msg.sender),
            "caller isnt approved game cntrct"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import {ERC20Burnable, ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Pausable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import {LIQUIDITY_POOL_TOKENS_NAME, LIQUIDITY_POOL_TOKENS_SYMBOL, MINTER_ROLE, PAUSER_ROLE} from "../utils/constants.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This abstract contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles.
 */
abstract contract YoloShareTokens is AccessControlEnumerable, ERC20Pausable {
    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    constructor()
        ERC20(LIQUIDITY_POOL_TOKENS_NAME, LIQUIDITY_POOL_TOKENS_SYMBOL)
    {
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC20).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements: the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(
            hasRole(PAUSER_ROLE, msg.sender),
            "ERC20PresetMinterPauser: must have pauser role to pause"
        );
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(
            hasRole(PAUSER_ROLE, msg.sender),
            "ERC20PresetMinterPauser: must have pauser role to unpause"
        );
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}

pragma solidity 0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {YoloRegistry} from "./YoloRegistry.sol";
import {RegistrySatellite} from "./RegistrySatellite.sol";
import {LiquidityPool} from "./LiquidityPool.sol";

import {LIQUIDITY_POOL, USDC_TOKEN, ADMIN_ROLE} from "../utils/constants.sol";
import {ZAA_USDCToken, ZAA_treasuryAddress, ZAA_LiquidityPool} from "../utils/errors.sol";

/**
 * @title YoloWallet
 * @author Garen Vartanian (@cryptokiddies)
 * @dev Important contract as it pools both user and liquidity pool (market maker) USDC token deposits into Yolo market system. Also maps addresses to usernames.
 */
contract YoloWallet is RegistrySatellite {
    using SafeERC20 for IERC20;

    uint256 constant BASIS_FEE_FACTOR = 10000;

    uint256 treasuryFeeBP;
    address lpAddress;
    address treasuryAddress;

    IERC20 stablecoinTokenContract;

    mapping(address => uint256) public balances; // balances in USDC
    // TODO: username struct bytes 31 & bool
    mapping(address => bytes32) public userNames;
    mapping(bytes32 => bool) public userNameChecks;

    event UsernameSet(
        bytes32 indexed previousUsername,
        address indexed sender,
        bytes32 indexed newUsername
    );
    event LiquidityReturn(address lpAddress, uint256 amount);
    event LiquidityReturnWithSplit(
        address lpAddress,
        uint256 lpAmount,
        address treasuryAddress,
        uint256 treasuryAmount,
        uint256 treasuryFeeBP
    );
    event TreasurySplitUpdate(
        address indexed treasuryAddress,
        uint256 newSplit
    );
    event TreasuryAddressUpdate(address indexed treasuryAddress);

    error CallerNotLPContract();

    constructor(address registryContractAddress_)
        RegistrySatellite(registryContractAddress_)
    {
        YoloRegistry registryContract = YoloRegistry(registryContractAddress_);

        address stablecoinTokenContractAddress = registryContract
            .getContractAddress(USDC_TOKEN);

        if (stablecoinTokenContractAddress == address(0))
            revert ZAA_USDCToken();

        stablecoinTokenContract = IERC20(stablecoinTokenContractAddress);
    }

    function setTreasuryAddress(address newTreasuryAddress)
        external
        onlyAuthorized(ADMIN_ROLE)
    {
        if (newTreasuryAddress == address(0)) revert ZAA_treasuryAddress();

        treasuryAddress = newTreasuryAddress;

        emit TreasuryAddressUpdate(newTreasuryAddress);
    }

    function removeTreasuryAddress() external onlyAuthorized(ADMIN_ROLE) {
        treasuryAddress = address(0);

        emit TreasuryAddressUpdate(address(0));
    }

    function setTreasurySplit(uint256 newBasisPoints)
        external
        onlyAuthorized(ADMIN_ROLE)
    {
        require(
            newBasisPoints < BASIS_FEE_FACTOR / 4,
            "must be l.t. quarter lp fee"
        );
        treasuryFeeBP = newBasisPoints;

        emit TreasurySplitUpdate(treasuryAddress, newBasisPoints);
    }

    /**
     * @notice Set a 32 ascii character username. Can only set a name that has not been claimed by another user. Cannot set to 0x00 aka "null".
     * @dev Can set name of sender address. If the name already exists, revert. If the user had a previous name, remove that exclusive claim.
     * @param userName New username.
     **/
    function setUserNames(bytes32 userName) external {
        address sender = msg.sender;

        require(userName != bytes32(0), "username cannot be null value");

        require(userNameChecks[userName] == false, "username already exists");

        bytes32 previousUsername = userNames[sender];

        if (previousUsername != bytes32(0)) {
            userNameChecks[previousUsername] = false;
        }

        userNames[sender] = userName;
        userNameChecks[userName] = true;

        emit UsernameSet(previousUsername, sender, userName);
    }

    /**
     * @notice Set {LiquidityPool} address.
     * @dev Required before any liquidity can be deposited with mint functions in {LiquidityPool}. Can make it a one-time call for absolute security.
     **/
    function setLiquidityPool() external onlyAuthorized(ADMIN_ROLE) {
        address lpAddr = yoloRegistryContract.getContractAddress(
            LIQUIDITY_POOL
        );

        if (lpAddr == address(0)) {
            revert ZAA_LiquidityPool();
        }

        lpAddress = lpAddr;

        _grantRole(LIQUIDITY_POOL, lpAddr);
    }

    /**
     * @notice {LiquidityPool} invoked function to increase liquidity pool wallet balance.
     * @dev This will not work unless `setMarketMakerRole` is called first.
     * @param amount The amount of USDC token to increase the liquidity pool account by.
     **/
    function updateLiquidityPoolBalance(uint256 amount)
        external
        onlyAuthorized(LIQUIDITY_POOL)
    {
        if (lpAddress == address(0)) {
            revert ZAA_LiquidityPool();
        }

        balances[lpAddress] += amount;
    }

    /**
     * @notice {LiquidityPool} invoked function to decrease liquidity pool wallet balance when providers burn YLP tokens in exchange for USDC tokens transfer.
     * @param amount The amount of USDC token to increase the liquidity pool account by.
     **/
    function reduceLiquidityPoolBalance(address receiver, uint256 amount)
        external
        onlyAuthorized(LIQUIDITY_POOL)
    {
        if (lpAddress == address(0)) revert ZAA_LiquidityPool();

        if (msg.sender != lpAddress) revert CallerNotLPContract();

        balances[lpAddress] -= amount;

        stablecoinTokenContract.safeTransfer(receiver, amount);
    }

    // TODO: adjust modifiers or design to allow a `SPECIAL_MIGRATOR_ROLE` to migrate tokens and user balances to future versions of {YoloWallet} contract. "Migration debt" mapping pattern.
    /**
     * @notice Game invoked internal transaction to batch update user balances, intended mainly for game settlements.
     * @dev should avoid loss altogether and try to reduce user balances on every user action instead. Additionally a try catch to handle balances that go below zero, as that is a serious error state.
     * @param user User address.
     * @param amount Amount to increase user balances by.
     **/
    /// @custom:scribble #if_succeeds balances[user] >= old(balances[user]);
    function gameUpdateUserBalance(address user, uint256 amount)
        external
        onlyGameContract
    {
        balances[user] += amount;
    }

    /**
     * @notice Game invoked internal transaction to update single user balance, mainly during game bids.
     * @dev Critical audits and reviews of this function (and contract) required.
     * @param user User addresses.
     * @param amount Updated balance amounts. Typically to reduce balane by bid amount.
     **/
    /// @custom:scribble #if_succeeds balances[user] <= old(balances[user]);
    function gameReduceUserBalance(address user, uint256 amount)
        external
        onlyGameContract
    {
        balances[user] -= amount;
    }

    /**
     * @notice Game invoked internal call to transfer USDC ({IERC20}) balance from the game to {LiquidityPool} address as fees.
     * @dev Critical audits and reviews of this function (and contract) required.
     * @param recipient Pool address.
     * @param lpReturn Amount of funds returned from settlement minus fees.
     * @param fees Fees drawn during round settlement.
     **/
    function returnLiquidity(
        address recipient,
        uint256 lpReturn,
        uint256 fees
    ) external onlyGameContract {
        uint256 splitFee = treasuryFeeBP;
        address treasuryAddr = treasuryAddress;

        if (splitFee > 0 && treasuryAddress != address(0)) {
            uint256 lpAmount = (fees * (BASIS_FEE_FACTOR - splitFee)) /
                BASIS_FEE_FACTOR +
                lpReturn;
            uint256 treasuryAmount = (fees * splitFee) / BASIS_FEE_FACTOR;

            balances[recipient] += lpAmount;
            balances[treasuryAddr] += treasuryAmount;
            emit LiquidityReturnWithSplit(
                recipient,
                lpAmount,
                treasuryAddr,
                treasuryAmount,
                splitFee
            );
        } else {
            uint256 lpAmount = lpReturn + fees;
            balances[recipient] += lpAmount;
            emit LiquidityReturn(recipient, lpAmount);
        }
    }

    /**
     * @notice Users call to withdraw USDC ({IERC20}) tokens from the {YoloWallet} contract to user's sender address.
     * @dev Critical audits and reviews of this function (and contract) required.
     * @param amount Amount of token transfer to sender.
     **/
    function withdraw(uint256 amount) external {
        address sender = msg.sender;

        require(amount > 0, "amount must be greater than 0");
        require(amount <= balances[sender], "withdraw amount exceeds balance");

        balances[sender] -= amount;

        stablecoinTokenContract.safeTransfer(sender, amount);
    }

    /**
     * @notice Auxiliary function to deposit USDC ({IERC20}) tokens to the {YoloWallet} contract from user's sender address.
     * @dev Useful for testing. Not a useful call for user as game instance will auto transfer any shortfall in funds directly.
     * @param amount Amount of token transfer to sender.
     **/
    function deposit(uint256 amount) external {
        address sender = msg.sender;
        require(amount > 0, "amount must be greater than 0");

        stablecoinTokenContract.safeTransferFrom(sender, address(this), amount);

        balances[sender] += amount;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

interface IYoloGame {
    function updateLpFee(uint256 newFee) external;

    function bidInYolo(
        uint96 amount,
        bool isUp,
        uint72 bidRound
    ) external;

    function makeMarketBid(uint256 bidRound, uint128[2] calldata amounts)
        external;

    function processRound(
        uint112 startTime,
        uint128 settlementPrice,
        uint128 nextStrikePrice
    ) external;
}

// contract names
bytes32 constant USDC_TOKEN = keccak256("USDC_TOKEN");
bytes32 constant YOLO_NFT = keccak256("YOLO_NFT");
bytes32 constant YOLO_SHARES = keccak256("YOLO_SHARES");
bytes32 constant YOLO_WALLET = keccak256("YOLO_WALLET");
bytes32 constant LIQUIDITY_POOL = keccak256("LIQUIDITY_POOL");
// bytes32 constant BETA_NFT_TRACKER = keccak256("BETA_NFT_TRACKER");
bytes32 constant NFT_TRACKER = keccak256("NFT_TRACKER");
bytes32 constant YOLO_NFT_PACK = keccak256("YOLO_NFT_PACK");
bytes32 constant BIDDERS_REWARDS = keccak256("BIDDERS_REWARDS");
bytes32 constant BIDDERS_REWARDS_FACTORY = keccak256("BIDDERS_REWARDS_FACTORY");
bytes32 constant LIQUIDITY_REWARDS = keccak256("LIQUIDITY_REWARDS");
bytes32 constant GAME_FACTORY = keccak256("GAME_FACTORY");

// game pairs
bytes32 constant ETH_USD = keccak256("ETH_USD");
bytes32 constant TSLA_USD = keccak256("TSLA_USD");
bytes32 constant DOGE_USD = keccak256("DOGE_USD");

// access control roles
bytes32 constant GAME_ADMIN_ROLE = keccak256("GAME_ADMIN_ROLE");
bytes32 constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");
bytes32 constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
bytes32 constant REWARDER_ROLE = keccak256("REWARDER_ROLE");
bytes32 constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
bytes32 constant MARKET_MAKER_ROLE = keccak256("MARKET_MAKER_ROLE");

// assets config
uint256 constant USDC_DECIMALS_FACTOR = 10**6;

// global parameters
bytes32 constant FEE_RATE_MIN = keccak256("FEE_RATE_MIN"); // in basis points
bytes32 constant FEE_RATE_MAX = keccak256("FEE_RATE_MAX"); // basis points

// Token Names and Symbols
string constant LIQUIDITY_POOL_TOKENS_NAME = "Yolo Liquidity Provider Shares";
string constant LIQUIDITY_POOL_TOKENS_SYMBOL = "BYLP";

pragma solidity 0.8.13;

/// @dev ZAA meaning Zero Address Assignment. {YLPToken} same as {LiquidityPool}.
error ZAA_YoloRegistry();
error ZAA_NFTTracker();
error ZAA_YoloNFTPack();
error ZAA_LiquidityPool();
error ZAA_MinterRole();
error ZAA_USDCToken();
error ZAA_YLPToken();
error ZAA_YoloWallet();
error ZAA_BiddersRewards();
error ZAA_BiddersRewardsFactory();

error ZAA_rewardsAdmin();
error ZAA_receiver();
error ZAA_treasuryAddress();
error ZAA_gameAdmin();

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
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
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

pragma solidity 0.8.13;

import {AccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import {ADMIN_ROLE} from "../utils/constants.sol";

/**
 * @title CoreCommon
 * @author Garen Vartanian (@cryptokiddies)
 * @dev pulling in {CoreCommon} will also bring in {AccessControlEnumerable},
 * {AccessControl}, {ERC165} and {Context} contracts/libraries. {ERC165} will support IAccessControl and IERC165 interfaces.
 */
abstract contract CoreCommon is AccessControlEnumerable {
    /**
     * @notice used to restrict critical method calls to admin only
     * @dev consider removing `ADMIN_ROLE` altogether, although it may be useful in near future for assigning roles.
     */
    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
                hasRole(ADMIN_ROLE, msg.sender),
            "Must have admin role to invoke"
        );
        _;
    }
}

pragma solidity 0.8.13;

import {CoreCommon} from "./CoreCommon.sol";
import {ADMIN_ROLE} from "../utils/constants.sol";

/**
 * @title YoloRegistry
 * @author Garen Vartanian (@cryptokiddies)
 * @dev Controller contract which keeps track of critical yolo contracts info, including latest contract addresses and versions, and access control, incl. multisignature calls
 * review access control of satellites to simplify process. also review contract address management in line with contract version and instance deprecation pattern
 *
 */
contract YoloRegistry is CoreCommon {
    /**
     * @dev ContractDetails struct handles information for recognized contracts in the Yolo ecosystem.
     */
    struct ContractDetails {
        address contractAddress;
        uint48 version;
        uint48 latestVersion;
    }

    struct ContractArchiveDetails {
        bytes32 identifier;
        uint48 version;
    }

    bytes32 constant EMPTY_BYTES_HASH =
        0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    // recognized contracts in the Yolo ecosystem
    mapping(bytes32 => ContractDetails) contractRegistry;
    // game instances preapproved for factory minting
    mapping(address => bool) public registeredGames;
    // values used by system, e.g., min (or max) fee required in game/market
    mapping(bytes32 => uint256) public globalParameters;
    // game paused state statuses
    mapping(address => bool) public activeGames;
    // all contracts including those that have been rescinded or replaced mapped to their respective version numbers
    mapping(address => ContractArchiveDetails) public contractsArchive;

    event ContractRegistry(
        bytes32 indexed identifier,
        address indexed newAddress,
        address indexed oldAddress,
        uint96 newVersion
    );

    event ContractAddressRegistryRemoval(
        bytes32 indexed indentifier,
        address indexed rescindedAddress,
        uint96 version
    );

    event GameApproval(address indexed gameAddress, bool hasApproval);

    event GlobalParameterAssignment(bytes32 indexed paramName, uint256 value);

    modifier onlyGameContract() {
        require(registeredGames[msg.sender], "only game can set");
        _;
    }

    /**
     * @dev Note: Most critical role. Only give to the most trusted managers as they can revoke or destroy all control setting random values to management fields in AccessControl role mappings
     */
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Used mainly by satellite contract constructors to grab registered addresses.
     */
    function getContractAddress(bytes32 identifier)
        public
        view
        returns (address)
    {
        return contractRegistry[identifier].contractAddress;
    }

    /**
     * @dev No internal uses at the moment. Necessary for handling migrations.
     */
    function getContractVersion(bytes32 identifier)
        public
        view
        returns (uint96)
    {
        return contractRegistry[identifier].version;
    }

    /**
     * @notice Setting registered contracts (described above).
     * @dev This is for contracts OTHER THAN {GameInstance} types; game factory should call `setApprovedGame`
     **/
    function setContract(bytes32 identifier, ContractDetails calldata newData)
        external
        onlyAdmin
    {
        bytes32 codehash = newData.contractAddress.codehash;

        require(
            codehash != EMPTY_BYTES_HASH && codehash != 0,
            "addr must be contract"
        );

        ContractDetails storage oldRegister = contractRegistry[identifier];

        require(!registeredGames[newData.contractAddress], "is game contract");

        ContractArchiveDetails memory contractArchive = contractsArchive[
            newData.contractAddress
        ];

        if (contractArchive.identifier != bytes32(0)) {
            require(
                identifier == contractArchive.identifier,
                "reinstating identifier mismatch"
            );

            require(
                newData.version == contractArchive.version,
                "reinstating version mismatch"
            );
        } else {
            require(
                newData.version == oldRegister.latestVersion + 1,
                "new version val must be 1 g.t."
            );

            oldRegister.latestVersion += 1;

            contractsArchive[newData.contractAddress] = ContractArchiveDetails(
                identifier,
                newData.version
            );
        }

        address oldAddress = oldRegister.contractAddress;

        oldRegister.contractAddress = newData.contractAddress;
        oldRegister.version = newData.version;

        emit ContractRegistry(
            identifier,
            newData.contractAddress,
            oldAddress,
            newData.version
        );
    }

    /**
     * @notice Removing a registered contract address.
     * @dev The contract, though unregistered, is maintained in the `contractsArchive` mapping.
     **/
    function removeContractAddress(bytes32 identifier) external onlyAdmin {
        ContractDetails storage registryStorage = contractRegistry[identifier];
        ContractDetails memory oldRegister = registryStorage;

        require(
            oldRegister.contractAddress != address(0),
            "identifier is not registered"
        );

        registryStorage.contractAddress = address(0);
        registryStorage.version = 0;

        emit ContractAddressRegistryRemoval(
            identifier,
            oldRegister.contractAddress,
            oldRegister.version
        );
    }

    /**
     * @notice Use this to preapprove factory games with create2 and a nonce salt: keccak hash of `abi.encodePacked(gameId, gameLength)`. `gameId` is itself a hash of the game pair, e.g. "ETH_USD"
     * @dev Can use EXTCODEHASH opcode whitelisting in future iterations. (Its usage forces redesigns for factory-spawned game contracts with immutable vars, given that their initialized values end up in the deployed bytecode.)
     **/
    function setApprovedGame(address gameAddress, bool hasApproval)
        external
        onlyAdmin
    {
        registeredGames[gameAddress] = hasApproval;

        emit GameApproval(gameAddress, hasApproval);
    }

    function setGameActive() external onlyGameContract {
        activeGames[msg.sender] = true;
    }

    function setGameInactive() external onlyGameContract {
        activeGames[msg.sender] = false;
    }

    /**
     * @notice Values used by system, e.g., min (or max) fee required in game/market. Good for setting boundary values and flags.
     * @dev For a bool, substitute 0 and 1 for false and true, respectively.
     **/
    function setGlobalParameters(bytes32 paramName, uint256 value)
        external
        onlyAdmin
    {
        globalParameters[paramName] = value;

        emit GlobalParameterAssignment(paramName, value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}