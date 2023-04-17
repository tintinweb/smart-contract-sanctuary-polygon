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

pragma solidity ^0.8.17;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Temple (common/access/Governable.sol)

import {GovernableBase} from "contracts/common/access/GovernableBase.sol";

/// @notice Enable a contract to be governable (eg by a Timelock contract)
abstract contract Governable is GovernableBase {
    
    constructor(address initialGovernor) {
        _init(initialGovernor);
    }

}

pragma solidity ^0.8.17;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Temple (common/access/GovernableBase.sol)

import {CommonEventsAndErrors} from "contracts/common/CommonEventsAndErrors.sol";

/// @notice Base contract to enable a contract to be governable (eg by a Timelock contract)
/// @dev Either implement a constructor or initializer (upgradable proxy) to set the 
abstract contract GovernableBase {
    address internal _gov;
    address internal _proposedNewGov;

    event NewGovernorProposed(address indexed previousGov, address indexed previousProposedGov, address indexed newProposedGov);
    event NewGovernorAccepted(address indexed previousGov, address indexed newGov);

    error NotGovernor();

    function _init(address initialGovernor) internal {
        if (_gov != address(0)) revert NotGovernor();
        if (initialGovernor == address(0)) revert CommonEventsAndErrors.InvalidAddress(address(0));
        _gov = initialGovernor;
    }

    /**
     * @dev Returns the address of the current governor.
     */
    function gov() external view returns (address) {
        return _gov;
    }

    /**
     * @dev Proposes a new Governor.
     * Can only be called by the current governor.
     */
    function proposeNewGov(address newProposedGov) external onlyGov {
        if (newProposedGov == address(0)) revert CommonEventsAndErrors.InvalidAddress(newProposedGov);
        emit NewGovernorProposed(_gov, _proposedNewGov, newProposedGov);
        _proposedNewGov = newProposedGov;
    }

    /**
     * @dev Caller accepts the role as new Governor.
     * Can only be called by the proposed governor
     */
    function acceptGov() external {
        if (msg.sender != _proposedNewGov) revert CommonEventsAndErrors.InvalidAddress(msg.sender);
        emit NewGovernorAccepted(_gov, msg.sender);
        _gov = msg.sender;
        delete _proposedNewGov;
    }

    /**
     * @dev Throws if called by any account other than the governor.
     */
    modifier onlyGov() {
        if (msg.sender != _gov) revert NotGovernor();
        _;
    }

}

pragma solidity ^0.8.17;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Temple (common/CommonEventsAndErrors.sol)

/// @notice A collection of common errors thrown within the Temple contracts
library CommonEventsAndErrors {
    error InsufficientBalance(address token, uint256 required, uint256 balance);
    error InvalidToken(address token);
    error InvalidParam();
    error InvalidAddress(address addr);
    error InvalidAmount(address token, uint256 amount);
    error ExpectedNonZero();
    error Slippage(uint256 minAmountExpected, uint256 acutalAmount);
    error IsPaused();
    error UnknownExecuteError(bytes returndata);
    event TokenRecovered(address indexed to, address indexed token, uint256 amount);
}

pragma solidity ^0.8.17;
// SPDX-License-Identifier: AGPL-3.0-or-later

import { ITempleDebtToken } from "contracts/interfaces/v2/ITempleDebtToken.sol";
import { Governable } from "contracts/common/access/Governable.sol";

contract TempleDebtTokenTestnetAdmin {

    ITempleDebtToken public immutable dUSD;

    constructor(address _dUSD) {
        dUSD = ITempleDebtToken(_dUSD);
    }

    function addMinter(address account) external {
        dUSD.addMinter(account);
    }

    function removeMinter(address account) external {
        dUSD.removeMinter(account);
    }

    function mint(address to, uint256 amount) external {
        dUSD.mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        dUSD.burn(from, amount);
    }

    function setBaseInterestRate(uint256 _rate) external {
        dUSD.setBaseInterestRate(_rate);
    }

    function setRiskPremiumInterestRate(address _debtor, uint256 _rate) external {
        dUSD.setRiskPremiumInterestRate(_debtor, _rate);
    }

    function proposeNewGov(address newProposedGov) external {
        Governable(address(dUSD)).proposeNewGov(newProposedGov);
    }

    function acceptGov() external {
        Governable(address(dUSD)).acceptGov();
    }
}

pragma solidity ^0.8.17;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Temple (interfaces/v2/ITempleDebtToken.sol)

import { IERC20, IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface ITempleDebtToken is IERC20, IERC20Metadata {
    error NonTransferrable();
    error BurnExceedsBalance(uint256 availableToBurn, uint256 amount);
    error CannotMintOrBurn(address caller);

    event BaseInterestRateSet(uint256 rate);
    event RiskPremiumInterestRateSet(address indexed debtor, uint256 rate);
    event AddedMinter(address indexed account);
    event RemovedMinter(address indexed account);

    /**
     * @notice Track the deployed version of this contract. 
     */
    function version() external view returns (string memory);

    /**
     * @notice The current (base rate) interest common for all users. This can be updated by governance
     * @dev 1e18 format, where 0.01e18 = 1%
     */
    function baseRate() external view returns (uint256);

    /**
     * @notice The (base rate) total number of shares allocated out to users for internal book keeping
     */
    function baseShares() external view returns (uint256);

    /**
     * @notice The (base rate) total principal and interest owed across all debtors as of the latest checkpoint
     */
    function baseCheckpoint() external view returns (uint256);

    /**
     * @notice The last checkpoint time of the (base rate) principal and interest checkpoint
     */
    function baseCheckpointTime() external view returns (uint256);

    /// @dev byte packed into two slots.
    struct Debtor {
        /// @notice The current principal owed by this debtor
        uint128 principal;

        /// @notice The number of this shares this debtor is allocated of the base interest.
        uint128 baseShares;

        /// @notice The current (risk premium) interest rate specific to this debtor. This can be updated by governance
        /// @dev 1e18 format, where 0.01e18 = 1%
        /// uint64 => max 18.45e18 => 1845%
        uint64 rate;

        /// @notice The debtor's (risk premium) interest (no principal) owed as of the last checkpoint
        uint160 checkpoint;

        /// @notice The last checkpoint time of this debtor's (risk premium) interest
        /// @dev uint32 => max time of Feb 7 2106
        uint32 checkpointTime;
    }

    /**
     * @notice Per address status of debt
     */
    function debtors(address account) external view returns (
        /// @notice The current principal owed by this debtor
        uint128 principal,

        /// @notice The number of this shares this debtor is allocated of the base interest.
        uint128 baseShares,

        /// @notice The current (risk premium) interest rate specific to this debtor. This can be updated by governance
        /// @dev 1e18 format, where 0.01e18 = 1%
        uint64 rate,

        /// @notice The debtor's (risk premium) interest (no principal) owed as of the last checkpoint
        uint160 checkpoint,

        /// @notice The last checkpoint time of this debtor's (risk premium) interest
        uint32 checkpointTime
    );

    /**
     * @notice The net amount of principal amount of debt minted across all users.
     */
    function totalPrincipal() external view returns (uint256);

    /**
     * @notice The latest estimate of the (risk premium) interest (no principal) owed.
     * @dev Indicative only. This total is only updated on a per strategy basis when that strategy gets 
     * checkpointed (on borrow/repay rate change).
     * So it is generally always going to be out of date as each strategy will accrue interest independently 
     * on different rates.
     */
    function estimatedTotalRiskPremiumInterest() external view returns (uint256);

    /// @notice A set of addresses which are approved to mint/burn
    function minters(address account) external view returns (bool);

    /**
     * @notice Governance can add an address which is able to mint or burn debt
     * positions on behalf of users.
     */
    function addMinter(address account) external;

    /**
     * @notice Governance can remove an address which is able to mint or burn debt
     * positions on behalf of users.
     */
    function removeMinter(address account) external;

    /**
     * @notice Governance can update the continuously compounding (base) interest rate of all debtors, from this block onwards.
     */
    function setBaseInterestRate(uint256 _rate) external;

    /**
     * @notice Governance can update the continuously compounding (risk premium) interest rate for a given debtor, from this block onwards
     */
    function setRiskPremiumInterestRate(address _debtor, uint256 _rate) external;

    /**
     * @notice Approved Minters can add a new debt position on behalf of a user.
     * @param _debtor The address of the debtor who is issued new debt
     * @param _mintAmount The notional amount of debt tokens to issue.
     */
    function mint(address _debtor, uint256 _mintAmount) external;

    /**
     * @notice Approved Minters can burn debt on behalf of a user.
     * @dev Interest is repaid in preference:
     *   1/ Firstly to the higher interest rate of (baseRate, debtor risk premium rate)
     *   2/ Any remaining of the repayment is then paid of the other interest amount.
     *   3/ Finally if there is still some repayment amount unallocated, 
     *      then the principal will be paid down. This is like a new debt is issued for the lower balance,
     *      where interest accrual starts fresh.
     * @param _debtor The address of the debtor
     * @param _burnAmount The notional amount of debt tokens to repay.
     */
    function burn(address _debtor, uint256 _burnAmount) external;

    /**
     * @notice Approved Minters can burn the entire debt on behalf of a user.
     * @param _debtor The address of the debtor
     */
    function burnAll(address _debtor) external;

    /**
     * @notice Checkpoint the base interest owed by all debtors up to this block.
     */
    function checkpointBaseInterest() external returns (uint256);

    /**
     * @notice Checkpoint a debtor's (risk premium) interest (no principal) owed up to this block.
     */
    function checkpointDebtorInterest(address debtor) external returns (uint256);

    /**
     * @notice Checkpoint multiple accounts (risk premium) interest (no principal) owed up to this block.
     * @dev Provided in case there needs to be block synchronisation on the total debt.
     */
    function checkpointDebtorsInterest(address[] memory _debtors) external;

    /**
     * @notice The current debt for a given user split out by
     * principal, base interest, risk premium (per debtor) interest
     */
    function currentDebtOf(address _debtor) external view returns (
        uint256 principal, 
        uint256 baseInterest, 
        uint256 riskPremiumInterest
    );

    /**
      * @notice The current total principal + total base interest, total (estimate) debtor specific risk premium interest owed by all debtors.
      * @dev Note the (total principal + total base interest) portion is up to date.
      * However the (debtor specific risk premium interest) portion is likely stale.
      * The `estimatedTotalDebtorInterest` is only updated when each debtor checkpoints, so it's going to be out of date.
      * For more up to date current totals, off-chain aggregation of balanceOf() will be required - eg via subgraph.
      */
    function currentTotalDebt() external view returns (
        uint256 principal,
        uint256 baseInterest, 
        uint256 estimatedRiskPremiumInterest
    );

    /**
     * @notice Convert a (base interest) debt amount into proportional amount of shares
     */
    function baseDebtToShares(uint256 debt) external view returns (uint256);

    /**
     * @notice Convert a number of (base interest) shares into proportional amount of debt
     */
    function baseSharesToDebt(uint256 shares) external view returns (uint256);
}