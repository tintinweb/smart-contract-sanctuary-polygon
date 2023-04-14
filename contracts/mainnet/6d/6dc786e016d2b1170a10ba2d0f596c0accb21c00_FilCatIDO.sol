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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

contract FilCatIDO is Ownable {

    uint256 constant public amount = 200e18;

    struct User {
        address addr;
        address ref;
        uint256 inviteAmount;
        uint256 catAmount;
        uint256 debtCatAmount;
        bool isCat;
    }

    struct Sys {
        uint256 usersLen;
        uint256 usersLevel1Len;
        uint256 balance;
        uint256 catsAmount;
        uint256 totalAmount;
    }

    address public immutable defaultRef;

    address public immutable admin;

    mapping(address => User) private userRefs;
    address[] public users;

    address[] private userCats;

    IERC20 private immutable fil;

    uint256 public invitePercent = 15; // /100
    uint256 public catPercent = 10; // /100

    address[] public defaultLevel1;

    function getUser(address addr) external view returns(User memory) {
        return userRefs[addr];
    }

    constructor(address owner,address fil_, address default_){
        if (address(0) == fil_) {
            fil_ = 0x0D8Ce2A99Bb6e3B7Db580eD848240e4a0F9aE153;
        }

        if (address(0) == default_) {
            default_ = 0x83dc171BC7dD79dfb718868e97eFeE25898A25C3;
        }
        defaultRef = default_;

        if (address(0) == owner) {
            owner = 0x83dc171BC7dD79dfb718868e97eFeE25898A25C3;
        }
        admin = owner;

        fil = IERC20(fil_);

        _transferOwnership(owner);
    }

    function deposit(address ref_) external {
        require(msg.sender != defaultRef, "default err");
        require(userRefs[msg.sender].ref == address(0),"IDOed err");
        require(userRefs[ref_].ref != address(0) || ref_ == defaultRef, "ref err");

        bool success = fil.transferFrom(msg.sender, address(this), amount);
        require(success,"transferFrom failed");


        userRefs[msg.sender].addr = msg.sender;
        userRefs[msg.sender].ref = ref_;

        uint256 inviteAmount = amount * invitePercent / 100;
        uint256 catAmount = amount * catPercent / 100;

        fil.transfer(ref_,inviteAmount);
        fil.transfer(admin,amount - inviteAmount - catAmount);

        address catAddr = selectCat(msg.sender);
        if (catAddr == defaultRef) {
            fil.transfer(admin,catAmount);
        } else {
            userCats.push(catAddr);
            userRefs[catAddr].catAmount = userRefs[catAddr].catAmount + catAmount;
        }

        userRefs[ref_].inviteAmount += inviteAmount;

        if (ref_ == defaultRef) {
            defaultLevel1.push(msg.sender);
        }
        users.push(msg.sender);
    }

    function selectCat(address addr) public view returns(address) {
        address catAdr = addr;
        for (uint i = 0; i<users.length; i++) {
            catAdr = userRefs[catAdr].ref;
            if (catAdr == defaultRef) {
                return catAdr;
            }
            if (userRefs[catAdr].isCat) {
                return catAdr;
            }
        }
        return catAdr;
    }

    function setCat(address addr,bool isCat) external onlyOwner{
        userRefs[addr].isCat = isCat;
    }

    function distribute() external onlyOwner {
        for (uint i =0; i < userCats.length; i++) {
            uint256 amountCat = userRefs[userCats[i]].catAmount - userRefs[userCats[i]].debtCatAmount;
            if (amountCat > 0) {
                userRefs[userCats[i]].debtCatAmount = userRefs[userCats[i]].catAmount;
                fil.transfer(userRefs[userCats[i]].addr,amountCat);
            }
        }
        address[] memory userCatNull;
        userCats = userCatNull;
    }

    function getCatsAmount() public view returns (uint256 totalAmount) {
        for (uint i =0; i < userCats.length; i++) {
            uint256 amountCat = userRefs[userCats[i]].catAmount - userRefs[userCats[i]].debtCatAmount;
            totalAmount += amountCat;
        }
        return totalAmount;
    }

    function getDefaultLevel1() external view returns (address[] memory) {
        return defaultLevel1;
    }

    function usersAddr() external view returns(address[] memory) {
        return users;
    }

    function getUserCats() external view returns(address[] memory) {
        return userCats;
    }

    function getSys() external view returns(Sys memory) {
        Sys memory sys = Sys(0,0,0,0,0);
        sys.balance = fil.balanceOf(address(this));
        sys.catsAmount = getCatsAmount();
        sys.usersLen = users.length;
        sys.usersLevel1Len = defaultLevel1.length;
        sys.totalAmount = users.length * amount;
        return sys;
    }

}