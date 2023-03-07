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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MultiSig is Ownable {
    address public signer1;
    address public signer2;

    address prevSigner;
    address token;
    uint256 amount;
    address to;
    uint8 status = 0; // 1 => pending, 2 => approved, 3=> rejected;
    uint8 change_admin_status = 0;

    address new_signer1;
    address new_signer2;

    constructor(address _signer1, address _signer2) {
        signer1 = _signer1;
        signer2 = _signer2;
    }

    modifier onlyOwners() {
        require(msg.sender == signer1 || msg.sender == signer2);
        _;
    }

    function requestTokenTransaction(address _token, uint256 _amount, address _to) public onlyOwners {
        require(status != 1, "Current transaction is not approved or rejected");
        require(exists(_token) == true, "this is not token address");
        require(IERC20(_token).balanceOf(address(this)) >= _amount, "Insufficient balance");
        prevSigner = msg.sender;
        token = _token;
        amount = _amount;
        to = _to;
        status = 1;
    }

    function approveTransaction() public onlyOwners {
        require(prevSigner != msg.sender, "You are first signer for this transaction");
        require(status == 1, "This transaction was already approved or rejected (there is no requested transaction)");

        IERC20(token).transfer(to, amount);
        status = 2;
    }

    function rejectTransaction() public onlyOwners {
        require(status == 1, "This transaction was already approved or rejected (there is no requested transaction)");
        status = 3;
    }

    function exists(address what) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(what)
        }

        return size > 0;
    }

    function getCurrentTranscaction()
        public
        view
        returns (address _prevSigner, address _token, uint256 _amount, address _to, uint8 _status)
    {
        return (prevSigner, token, amount, to, status);
    }

    function requestChangeSigners(address _signer1, address _signer2) public onlyOwners {
        require(change_admin_status != 1, "Current transaction is not approved or rejected");

        prevSigner = msg.sender;
        new_signer1 = _signer1;
        new_signer2 = _signer2;

        change_admin_status = 1;
    }

    function approveChangeSigners() public onlyOwners {
        require(prevSigner != msg.sender, "You are first signer for this transaction");
        require(
            change_admin_status == 1,
            "This transaction was already approved or rejected (there is no requested transaction)"
        );

        signer1 = new_signer1;
        signer2 = new_signer2;

        change_admin_status = 2;
    }

    function rejectChangeSigners() public onlyOwners {
        require(
            change_admin_status == 1,
            "This transaction was already approved or rejected (there is no requested transaction)"
        );
        change_admin_status = 3;
    }

    function getCurrentChangeAdminStatus()
        public
        view
        returns (address _new_signer1, address _new_signer2, uint8 _status)
    {
        return (_new_signer1, _new_signer2, change_admin_status);
    }
}