// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**

TODO 

- Manage Bot that will
1. Claim & Withdraw GLTR => FROM SWAPPER CONTRACT
2. Withdraw GHST (include fees) => FROM SWAPPER CONTRACT
3. Call private swapper contract (use quickswap)

in SWAPPER :
function swapToMaticAndUsdc() external onlySwapperBotOrOwner {
    IStaking(stakingAddress).withdrawGltrAndGhst(address(this));
    _swapGltrToGhst(gltrAmount);
    _swapGhstToMatic(ghstAmount / 3);
    _swapGhstToUsdc(ghstAmount / 3);
    IERC20(Matic).transfer(petter, allBalance);
    IERC20(USDC).transfer(owner, allBalance);
    IERC20(GHST).transfer(owner, allBalance);
}

 */

interface IGHST {
    function stakeGhst(uint256 _ghstValue) external;

    function withdrawGhstStake(uint256 _ghstValue) external;

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(address _spender, uint256 _value)
        external
        returns (bool success);

    function transfer(address _to, uint256 _value)
        external
        returns (bool success);

    function balanceOf(address _owner) external view returns (uint256 balance);
}

interface IGltrStaking {
    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function harvest(uint256 _pid) external;
}

interface IWrapper {
    function enterWithUnderlying(uint256 assets)
        external
        returns (uint256 shares);

    function leaveToUnderlying(uint256 shares)
        external
        returns (uint256 assets);
}

contract Staking is Ownable {
    address ghst = 0x385Eeac5cB85A38A9a07A70c73e0a3271CfB54A7;
    address wapGhst = 0x73958d46B7aA2bc94926d8a215Fa560A5CdCA3eA;
    address gltrStaking = 0x1fE64677Ab1397e20A1211AFae2758570fEa1B8c;
    address gltr = 0x3801C3B3B5c98F88a9c9005966AA96aa440B9Afc;

    uint256 private constant STAKING_AMOUNT = 99 * 10**18;
    uint256 private constant FEES = 10**18;
    uint256 constant MAX_INT =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;

    address[] private users;
    mapping(address => uint256) private usersToIndex;

    mapping(address => uint256) private ghstBalance;
    mapping(address => uint256) private sharesBalance;

    mapping(address => bool) private isApproved;

    constructor() {
        // This contract approves the wapGhst contract to move GHST
        IERC20(ghst).approve(wapGhst, MAX_INT);

        // This contract approves the deposit contract to move wapGhst
        IERC20(wapGhst).approve(gltrStaking, MAX_INT);

        // Mandatory, index 0 cannot be empty
        _addUser(0x86935F11C86623deC8a25696E1C19a8659CbF95d);

        // Add owner as approved
        isApproved[msg.sender] = true;
    }

    modifier onlyApproved() {
        require(
            msg.sender == owner() || isApproved[msg.sender],
            "Staking: Not Approved"
        );
        _;
    }

    function getIsSignedUp(address _address) external view returns (bool) {
        return usersToIndex[_address] > 0;
    }

    function getIsApproved(address _address) external view returns (bool) {
        return isApproved[_address];
    }

    function getUsers() external view returns (address[] memory) {
        return users;
    }

    function getUsersIndexed(uint256 _pointer, uint256 _amount)
        external
        view
        returns (address[] memory)
    {
        address[] memory addresses = new address[](_amount);
        for (uint256 i = 0; i < _amount; i++) {
            uint256 pointer = _pointer + i;
            if (pointer > users.length) break;
            addresses[i] = users[pointer];
        }
        return addresses;
    }

    function getUsersToIndex(address _user) external view returns (uint256) {
        return usersToIndex[_user];
    }

    function getUserGhstBalance(address _user) external view returns (uint256) {
        return ghstBalance[_user];
    }

    function getUserShares(address _user) external view returns (uint256) {
        return sharesBalance[_user];
    }

    function signUp() external {
        // Make sure user is not already staking
        require(ghstBalance[msg.sender] == 0, "Staking: Already staking");

        // Get the ghst from the account to the contract
        IGHST(ghst).transferFrom(msg.sender, address(this), STAKING_AMOUNT);

        // Remove 1 GHST Fees
        uint256 stakingAmount = STAKING_AMOUNT - FEES;

        // wrap the GHST
        uint256 shares = IWrapper(wapGhst).enterWithUnderlying(stakingAmount);

        // deposit wrapped ghst
        IGltrStaking(gltrStaking).deposit(0, shares);

        // Update the Balance of the user
        ghstBalance[msg.sender] = stakingAmount;
        sharesBalance[msg.sender] = shares;

        // Add to the user array
        _addUser(msg.sender);
    }

    function leave() external {
        // Check if the account has ghst staked
        require(ghstBalance[msg.sender] > 0, "Staking: Nothing to unstake");

        // Save balance of the user
        uint256 tempBalance = ghstBalance[msg.sender];
        uint256 tempShares = sharesBalance[msg.sender];

        // Update the balances of the user
        ghstBalance[msg.sender] = 0;
        sharesBalance[msg.sender] = 0;

        // Withdraw wapGhst
        IGltrStaking(gltrStaking).withdraw(0, tempShares);

        // Unwrap ghst
        IWrapper(wapGhst).leaveToUnderlying(tempShares);

        // Send back the ghst to the user
        IGHST(ghst).transfer(msg.sender, tempBalance);

        // Remove from user array
        _removeUser(msg.sender);
    }

    /**
        Internal 
    */

    function _addUser(address _newUser) private {
        // No need to add twice the same account
        require(usersToIndex[_newUser] == 0, "staking: user already added");

        // Get the index where the new user is in the array (= last position)
        usersToIndex[_newUser] = users.length;

        // Add the user in the array
        users.push(_newUser);
    }

    function _removeUser(address _addressLeaver) private {
        // Cant remove an account that is not a user
        require(
            usersToIndex[_addressLeaver] != 0,
            "Staking: user already removed"
        );

        // Get the index of the leaver
        uint256 _indexLeaver = usersToIndex[_addressLeaver];

        // Get last index
        uint256 lastElementIndex = users.length - 1;

        // Get Last address in array
        address lastAddressInArray = users[lastElementIndex];

        // Move the last address in the position of the leaver
        users[_indexLeaver] = users[lastElementIndex];

        // Change the moved address' index to the new one
        usersToIndex[lastAddressInArray] = _indexLeaver;

        // Remove last entry in the array and reduce length
        users.pop();
        usersToIndex[_addressLeaver] = 0;
    }

    /**
        Admin 
    */

    /**
     * @dev GLTR is claimed when a user leaves
     */
    function claimGltr() external {
        IGltrStaking(gltrStaking).harvest(0);
    }

    function withdrawGltr(address _tokenReceiver) external onlyApproved {
        uint256 amount = IERC20(gltr).balanceOf(address(this));
        IERC20(gltr).transfer(_tokenReceiver, amount);
    }

    /**
     * @notice Can't withdraw user fund with this function
     * User funds are, at all time, staked in the Aavegotchi contract
     */
    function withdrawGhst(address _tokenReceiver) external onlyApproved {
        uint256 amount = IERC20(ghst).balanceOf(address(this));
        IERC20(ghst).transfer(_tokenReceiver, amount);
    }

    function withdrawGltrAndGhst(address _tokenReceiver) external onlyApproved {
        IGltrStaking(gltrStaking).harvest(0);
        uint256 amountGltr = IERC20(gltr).balanceOf(address(this));
        if (amountGltr > 0) IERC20(gltr).transfer(_tokenReceiver, amountGltr);

        uint256 amountGhst = IERC20(ghst).balanceOf(address(this));
        if (amountGhst > 0) IERC20(ghst).transfer(_tokenReceiver, amountGhst);
    }

    function setIsApproved(address _address, bool _isApproved)
        external
        onlyOwner
    {
        isApproved[_address] = _isApproved;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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