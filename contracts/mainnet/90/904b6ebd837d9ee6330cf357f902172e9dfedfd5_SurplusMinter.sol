// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../utils/Ownable.sol";
import "../interfaces/IMintableERC20.sol";
import "../interfaces/IBurnableERC20.sol";
import "../interfaces/IERC677Receiver.sol";

/**
 * @title SurplusMinter
 * Managing realized and unrealized BOB surplus from debt-minting use-cases.
 */
contract SurplusMinter is IERC677Receiver, Ownable {
    address public immutable token;

    mapping(address => bool) public isMinter;

    uint256 public surplus; // unrealized surplus

    event UpdateMinter(address indexed minter, bool enabled);
    event WithdrawSurplus(address indexed to, uint256 realized, uint256 unrealized);
    event AddSurplus(address indexed from, uint256 unrealized);

    constructor(address _token) {
        token = _token;
    }

    /**
     * @dev Updates surplus mint permissions for the given address.
     * Callable only by the contract owner.
     * @param _account managed minter account address.
     * @param _enabled true, if enabling surplus minting, false otherwise.
     */
    function setMinter(address _account, bool _enabled) external onlyOwner {
        isMinter[_account] = _enabled;

        emit UpdateMinter(_account, _enabled);
    }

    /**
     * @dev Records potential unrealized surplus.
     * Callable only by the pre-approved surplus minter.
     * Once unrealized surplus is realized, it should be transferred to this contract via transferAndCall.
     * @param _surplus unrealized surplus to add.
     */
    function add(uint256 _surplus) external {
        require(isMinter[msg.sender], "SurplusMinter: not a minter");

        surplus += _surplus;

        emit AddSurplus(msg.sender, _surplus);
    }

    /**
     * @dev ERC677 callback. Converts previously recorded unrealized surplus into the realized one.
     * If converted amount exceeds unrealized surplus, remainder is burnt to account for unrealized interest withdrawn in advance.
     * Callable by anyone.
     * @param _from tokens sender.
     * @param _amount amount of tokens corresponding to realized interest.
     * @param _data optional extra data, encoded uint256 amount of unrealized surplus to convert. Defaults to _amount.
     */
    function onTokenTransfer(address _from, uint256 _amount, bytes calldata _data) external override returns (bool) {
        require(msg.sender == token, "SurplusMinter: invalid caller");

        uint256 unrealized = _amount;
        if (_data.length == 32) {
            unrealized = abi.decode(_data, (uint256));
            require(unrealized <= _amount, "SurplusMinter: invalid value");
        }

        uint256 currentSurplus = surplus;
        if (currentSurplus >= unrealized) {
            unchecked {
                surplus = currentSurplus - unrealized;
            }
        } else {
            IBurnableERC20(token).burn(unrealized - currentSurplus);
            unrealized = currentSurplus;
            surplus = 0;
        }
        emit WithdrawSurplus(address(this), 0, unrealized);

        return true;
    }

    /**
     * @dev Burns potential unrealized surplus.
     * Callable only by the contract owner.
     * Intended to be used for cancelling mistakenly accounted surplus.
     * @param _surplus unrealized surplus to cancel.
     */
    function burn(uint256 _surplus) external onlyOwner {
        require(_surplus <= surplus, "SurplusMinter: exceeds surplus");
        unchecked {
            surplus -= _surplus;
        }
        emit WithdrawSurplus(address(0), 0, _surplus);
    }

    /**
     * @dev Withdraws surplus.
     * Callable only by the contract owner.
     * Withdrawing realized surplus is prioritised, unrealized surplus is minted only
     * if realized surplus is not enough to cover the requested amount.
     * @param _surplus surplus amount to withdraw/mint.
     */
    function withdraw(address _to, uint256 _surplus) external onlyOwner {
        uint256 realized = IERC20(token).balanceOf(address(this));

        if (_surplus > realized) {
            uint256 unrealized = _surplus - realized;
            require(unrealized <= surplus, "SurplusMinter: exceeds surplus");
            unchecked {
                surplus -= unrealized;
            }

            IERC20(token).transfer(_to, realized);
            IMintableERC20(token).mint(_to, unrealized);

            emit WithdrawSurplus(_to, realized, unrealized);
        } else {
            IERC20(token).transfer(_to, _surplus);

            emit WithdrawSurplus(_to, _surplus, 0);
        }
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol" as OZOwnable;

/**
 * @title Ownable
 */
contract Ownable is OZOwnable.Ownable {
    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view override {
        require(_isOwner(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Tells if caller is the contract owner.
     * @return true, if caller is the contract owner.
     */
    function _isOwner() internal view virtual returns (bool) {
        return owner() == _msgSender();
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

interface IMintableERC20 {
    function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

interface IBurnableERC20 {
    function burn(uint256 amount) external;
    function burnFrom(address user, uint256 amount) external;
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

interface IERC677Receiver {
    function onTokenTransfer(address from, uint256 value, bytes calldata data) external returns (bool);
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