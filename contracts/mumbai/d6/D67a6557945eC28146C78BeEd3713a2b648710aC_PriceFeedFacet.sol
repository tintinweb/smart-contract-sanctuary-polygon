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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

import "../libraries/AppStorage.sol";

contract PriceFeedFacet {
    AppStorage s;

    // mapping(address => uint) public tokenPrice;

    function setPrice(address _token, uint _price) external {
        s.tokenPrice[_token] = _price;
    }

    function getPrice(address _token) external view returns (uint price) {
        price = s.tokenPrice[_token];
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

/**
 * @title Activated Stoa Token Interface
 * @author stoa.money
 * @notice
 *  Interface that provides functions for interacting with activated Stoa tokens.
 */
interface IActivated {
    function mint(address _account, uint _amount) external;

    function burn(address _account, uint _amount) external;

    function transfer(address _to, uint256 _value) external returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint _value
    ) external returns (bool);

    function convertToAssets(uint _creditBalance) external view returns (uint);

    function convertToCredits(uint _tokenBalance) external view returns (uint);

    function changeSupply(uint _newTotalSupply) external;

    function rebaseOptIn() external;

    function rebaseOptOut() external;

    function rebasingCreditsPerToken() external view returns (uint);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ERC4626 Interface
 * @author yearn.finance
 */
interface IERC4626 is IERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposit(
        address indexed caller,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    function asset() external view returns (address);

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, address receiver)
        external
        returns (uint256 shares); /* {
        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }*/

    /**
     * @dev Addition for depositing on behalf of depositor.
     */
    function deposit(
        uint256 assets,
        address receiver,
        address depositor
    ) external returns (uint256 shares);

    function mint(uint256 shares, address receiver)
        external
        returns (uint256 assets); /* {
        assets = previewMint(shares); // No need to check for rounding error, previewMint rounds up.

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }*/

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares); /* {
        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }*/

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets); /* {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }*/

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalAssets() external view returns (uint256);

    function convertToShares(uint256 assets) external view returns (uint256); /* {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }*/

    function convertToAssets(uint256 shares) external view returns (uint256); /* {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }*/

    function previewDeposit(uint256 assets) external view returns (uint256); /* {
        return convertToShares(assets);
    }*/

    function previewMint(uint256 shares) external view returns (uint256); /* {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }*/

    function previewWithdraw(uint256 assets) external view returns (uint256); /* {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
    }*/

    function previewRedeem(uint256 shares) external view returns (uint256); /* {
        return convertToAssets(shares);
    }*/

    /*//////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address) external view returns (uint256); /* {
        return type(uint256).max;
    }*/

    function maxMint(address) external view returns (uint256); /* {
        return type(uint256).max;
    }*/

    function maxWithdraw(address owner) external view returns (uint256); /* {
        return convertToAssets(balanceOf[owner]);
    }*/

    function maxRedeem(address owner) external view returns (uint256); /* {
        return balanceOf[owner];
    }*/

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/
    /*
    function beforeWithdraw(uint256 assets, uint256 shares) internal {}

    function afterDeposit(uint256 assets, uint256 shares) internal {}
    */
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

interface ISafeManager {
    function getSafeInit(address _owner, uint _index)
        external
        view
        returns (
            address,
            address,
            address
        );

    function getSafeVal(address _owner, uint _index)
        external
        view
        returns (
            uint,
            uint,
            uint,
            uint
        );

    function getSafeStatus(address _owner, uint _index)
        external
        view
        returns (uint);

    function initializeSafe(
        address _owner,
        address _activeToken,
        uint _amount,
        // Leave fees for now, however not part of demo
        uint _mintFeeApplied,
        uint _redemptionFeeApplied
    ) external;

    function adjustSafeBal(
        address _owner,
        uint _index,
        uint _amount,
        // uint _mintFeeApplied,
        // uint _redemptionFeeApplied,
        bool _add
    ) external;

    function adjustSafeDebt(
        address _owner,
        uint _index,
        address _debtToken,
        uint _amount,
        uint _fee,
        bool _add
    ) external;

    function setSafeStatus(
        address _owner,
        uint _index,
        address _activeToken,
        uint _num
    ) external;

    function initializeBorrow(
        address _owner,
        uint _index,
        // address _activeToken,
        // uint _toLock,
        address _debtToken
        // uint _amount,
        // uint _fee
    ) external;

    function getActiveToDebtTokenMCR(address _activeToken, address _debtToken)
        external
        view
        returns (uint _MCR);

    function getUnactiveCounterpart(address _activeToken)
        external
        view
        returns (address unactiveToken);

    function getActivePool(address _token)
        external
        view
        returns (address activePool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

interface ITreasury {
    function adjustAPTokenBal(address _activePool, uint _amount) external;

    function adjustBackingReserve(
        address _wildToken,
        address _backingToken,
        int _amount
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

/**
 * @title Unactivated Stoa Token Interface
 * @author stoa.money
 * @notice
 *  Interface that provides functions for interacting with unactivated Stoa tokens.
 */
interface IUnactivated {
    function mint(address _to, uint _amount) external;

    function burn(address _from, uint _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "../interfaces/IERC4626.sol";
import "../interfaces/ITreasury.sol";
import "../interfaces/IActivated.sol";
import "../interfaces/IUnactivated.sol";
import "../interfaces/ISafeManager.sol";

struct ActivatorAccount {
    // The total number of unexchanged tokens that an account has deposited into the system
    uint256 unexchangedBalance;
    // The total number of exchanged tokens that an account has had credited
    uint256 exchangedBalance;
}

// struct UpgradeActivatorAccount {
//     // The owner address whose account will be modified
//     address user;
//     // The amount to change the account's unexchanged balance by
//     int256 unexchangedBalance;
//     // The amount to change the account's exchanged balance by
//     int256 exchangedBalance;
// }

struct AppStorage {
    //Activator Facet
    // @dev the synthetic token to be exchanged
    address syntheticToken;
    // @dev the underlyinToken token to be received
    address underlyingToken;
    // @dev contract pause state
    bool isPaused;
    mapping(address => ActivatorAccount) accounts;
    // ControllerFacet
    address safeManager;
    // /**
    //  * @notice
    //  *  Collects fees, backing tokens (+ yield) and
    //  *  liquidation gains.
    //  *  Allocates as necessary (e.g., depositing USDST backing
    //  *  tokens into the Curve USDST AcivePool).
    //  */
    address treasury;
    address activeToken;
    address unactiveToken;
    address inputToken;
    // PriceFeedFacet
    mapping(address => uint) tokenPrice;
    // SafeOperationsFacet

    mapping(address => address) tokenToController;
    /**
     * @dev
     *  Later use for self-repaying loan logic.
     */
    mapping(address => bool) isActiveToken;
    mapping(address => address) activeToInputToken;
    mapping(address => uint) originationFeesCollected;
    // TreasuryFacet

    /**
     * @notice Amount of apTokens of a given ActivePool owned by the Treasury.
     */
    mapping(address => mapping(address => int)) backingReserve;
    mapping(address => uint) apTokens;
}