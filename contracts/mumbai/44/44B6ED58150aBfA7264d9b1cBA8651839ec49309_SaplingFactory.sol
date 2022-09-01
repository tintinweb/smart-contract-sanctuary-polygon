// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../interfaces/ILoanDeskOwner.sol";
import "../interfaces/IVerificationHub.sol";
import "../interfaces/ISaplingContext.sol";
import "./FactoryBase.sol";
import "./ITokenFactory.sol";
import "./ILoanDeskFactory.sol";
import "./IPoolFactory.sol";

/**
 * @title Sapling Factory
 * @notice Facilitates on-chain deployment and setup of protocol components.
 */
contract SaplingFactory is FactoryBase {
    /// Token factory contract address
    address public tokenFactory;

    /// LoanDesk factory contract address
    address public loanDeskFactory;

    /// Lending pool factory contract address
    address public poolFactory;

    /// Event for when a Lending pool and it"s components are deployed, linked and ready for use.
    event LendingPoolReady(address pool);

    /**
     * @notice Create a new SaplingFactory.
     * @dev Addresses must not be 0.
     * @param _tokenFactory Toke factory address
     * @param _loanDeskFactory LoanDesk factory address
     * @param _poolFactory Lending Pool factory address address
     */
    constructor(
        address _tokenFactory,
        address _loanDeskFactory,
        address _poolFactory
    ) {
        require(_tokenFactory != address(0), "SaplingFactory: invalid token factory address");
        require(_loanDeskFactory != address(0), "SaplingFactory: invalid LoanDesk factory address");
        require(_poolFactory != address(0), "SaplingFactory: invalid pool factory address");

        tokenFactory = _tokenFactory;
        loanDeskFactory = _loanDeskFactory;
        poolFactory = _poolFactory;
    }

    /**
     * @notice Deploys a lending pool and it"s components
     * @dev Caller must be the governance.
     * @param name Token name
     * @param symbol Token symbol
     * @param liquidityToken Liquidity token address
     * @param governance Governance address
     * @param treasury Treasury wallet address
     * @param manager Manager address
     */
    function createLendingPool(
        string memory name,
        string memory symbol,
        address liquidityToken,
        address governance,
        address treasury,
        address manager
    ) external onlyOwner {
        uint8 decimals = IERC20Metadata(liquidityToken).decimals();
        address poolToken = ITokenFactory(tokenFactory).create(string.concat(name, " Token"), symbol, decimals);
        address pool = IPoolFactory(poolFactory).create(poolToken, liquidityToken, address(this), treasury, manager);

        address loanDesk = ILoanDeskFactory(loanDeskFactory).create(pool, governance, treasury, manager, decimals);

        Ownable(poolToken).transferOwnership(pool);
        ILoanDeskOwner(pool).setLoanDesk(loanDesk);
        ISaplingContext(pool).transferGovernance(governance);

        emit LendingPoolReady(pool);
    }

    /**
     * @dev Overrides a pre-shutdown hoot in Factory Base
     */
    function preShutdown() internal override onlyOwner {
        FactoryBase(tokenFactory).shutdown();
        FactoryBase(loanDeskFactory).shutdown();
        FactoryBase(poolFactory).shutdown();
    }
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
pragma solidity ^0.8.15;

/**
 * @title LoanDesk Owner Interface
 * @dev Interface defining functional hooks for LoanDesk, and setup hooks for SaplingFactory.
 */
interface ILoanDeskOwner {

    /**
     * @notice Links a new loan desk for the pool to use. Intended for use upon initial pool deployment.
     * @dev Caller must be the governance.
     * @param _loanDesk New LoanDesk address
     */
    function setLoanDesk(address _loanDesk) external;

    /**
     * @notice Handles liquidity state changes on a loan offer.
     * @dev Hook to be called when a new loan offer is made.
     *      Caller must be the LoanDesk.
     * @param amount Loan offer amount.
     */
    function onOffer(uint256 amount) external;

    /**
     * @dev Hook to be called when a loan offer amount is updated. Amount update can be due to offer update or
     *      cancellation. Caller must be the LoanDesk.
     * @param prevAmount The original, now previous, offer amount.
     * @param amount New offer amount. Cancelled offer must register an amount of 0 (zero).
     */
    function onOfferUpdate(uint256 prevAmount, uint256 amount) external;

    /**
     * @dev Hook for checking if the lending pool can provide liquidity for the total offered loans amount.
     * @param totalOfferedAmount Total sum of offered loan amount including outstanding offers
     * @return True if the pool has sufficient lending liquidity, false otherwise.
     */
    function canOffer(uint256 totalOfferedAmount) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
 * @title Verification Hub Interface
 */
interface IVerificationHub {

    /**
     * @notice Register a new Sapling Lending Pool.
     * @dev Caller must be the SaplingFactory
     * @param pool Address of the new lending pool.
     */
    function registerSaplingPool(address pool) external;

    /**
     * @notice Set an address as ID verified.
     * @dev Caller must be the governance.
     * @param party Address to set as ID verified
     */
    function verify(address party) external;

    /**
     * @notice Unset an address as ID verified.
     * @dev Caller must be the governance.
     * @param party Address to unset as ID verified
     */
    function unverify(address party) external;

    /**
     * @notice Register an address as a bad actor.
     * @dev Caller must be the governance.
     * @param party Address to set as a bad actor
     */
    function registerBadActor(address party) external;

    /**
     * @notice Unregister an address as a bad actor.
     * @dev Caller must be the governance.
     * @param party Address to unset as a bad actor
     */
    function unregisterBadActor(address party) external;

    /**
     * @notice Check if an address is a registered Sapling Lending Pool
     * @param party An address to check
     * @return True if the specified address is registered with this verification hub, false otherwise.
     */
    function isSaplingPool(address party) external view returns (bool);

    /**
     * @notice Check if an address is ID verified.
     * @param party An address to check
     * @return True if the specified address is ID verified, false otherwise.
     */
    function isVerified(address party) external view returns (bool);

    /**
     * @notice Check if an address is a bad actor.
     * @param party An address to check
     * @return True if the specified address is a bad actor, false otherwise.
     */
    function isBadActor(address party) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
 * @title Sapling Context Interface
 */
interface ISaplingContext {

    /**
     * @notice Transfer the governance.
     * @dev Caller must be the governance.
     *      New governance address must not be 0, and must not be one of current non-user addresses.
     * @param _governance New governance address.
     */
    function transferGovernance(address _governance) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";


/**
 * @title Factory base
 * @dev Provides Ownable and shutdown/selfdestruct
 */
contract FactoryBase is Ownable {

    /**
     * @dev permanently shutdown this factory and the sub-factories it manages by self-destructing them.
     */
    function shutdown() external virtual onlyOwner {
        preShutdown();
        selfdestruct(payable(address(0)));
    }

    /**
     * Pre shutdown handler for extending contracts to override
     */
    function preShutdown() internal virtual onlyOwner {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
 * @title Token Factory Interface
 * @dev Interface defining the inter-contract methods of a token factory.
 */
interface ITokenFactory {

    /**
     * @notice Deploys a new instance of PoolToken.
     * @dev Caller must be the owner.
     * @param name Token name
     * @param symbol Token symbol
     * @param decimals Token decimals
     * @return Address of the deployed contract
     */
    function create(string memory name, string memory symbol, uint8 decimals) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
 * @title Loan Desk Factory Interface
 * @dev Interface defining the inter-contract methods of a LoanDesk factory.
 */
interface ILoanDeskFactory {

    /**
     * @notice Deploys a new instance of LoanDesk.
     * @dev Lending pool contract must implement ILoanDeskOwner.
     *      Caller must be the owner.
     * @param pool LendingPool address
     * @param governance Governance address
     * @param protocol Protocol wallet address
     * @param manager Manager address
     * @param decimals Decimals of the tokens used in the pool
     * @return Address of the deployed contract
     */
    function create(
        address pool,
        address governance,
        address protocol,
        address manager,
        uint8 decimals
    )
        external
        returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
 * @title Pool Factory Interface
 * @dev Interface defining the inter-contract methods of a lending pool factory.
 */
interface IPoolFactory {

    /**
     * @notice Deploys a new instance of SaplingLendingPool.
     * @dev Pool token must implement IPoolToken.
     *      Caller must be the owner.
     * @param poolToken LendingPool address
     * @param liquidityToken Liquidity token address
     * @param governance Governance address
     * @param protocol Protocol wallet address
     * @param manager Manager address
     * @return Address of the deployed contract
     */
    function create(
        address poolToken,
        address liquidityToken,
        address governance,
        address protocol,
        address manager
    )
        external
        returns (address);
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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