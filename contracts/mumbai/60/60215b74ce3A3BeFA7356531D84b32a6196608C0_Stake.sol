// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface IFuseBlock {
    function getAuraAmount(uint256 _tokenId) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function transferFrom(address from, address to, uint256 tokenId) external;
}
contract Stake is Ownable {
    struct TokenInfo {
        uint256 tokenId;
        address staker;
        uint256 stakedAt;
    }
    mapping(address => mapping(uint256 => TokenInfo)) users;
    mapping(address => uint256[]) tokenIds;
    address fuseBlockAddress;
    address auraAddress;
    uint256 rewardInterval = 1 hours;

    address royaltyReceiver;
    uint256 royaltyFraction;
    uint256 constant FEE_DENOMINATOR = 10000;

    constructor (address _fuseBlockAddress, address _auraAddress)  {
        fuseBlockAddress = _fuseBlockAddress;
        auraAddress = _auraAddress;
    }

    function updateRewardsInterval(uint256 _interval) external onlyOwner {
        rewardInterval = _interval;
    }

    function getStakedIds() external view returns(uint256[] memory) {
        return _getStakedIds(msg.sender);
    }

    function _getStakedIds(address _staker) private view returns(uint256[] memory) {
        return tokenIds[_staker];
    }

    function getAuraAmount() external view returns(uint256) {
        uint256[] memory stakedIds = _getStakedIds(msg.sender);
        uint256 totalAmount;
        uint256 len = stakedIds.length;

        for(uint256 i = 0; i < len; i ++) {
            totalAmount += IFuseBlock(fuseBlockAddress).getAuraAmount(stakedIds[i]);
        }

        return totalAmount;
    }

    function stake(uint256 _tokenId) external {
        require(IFuseBlock(fuseBlockAddress).ownerOf(_tokenId) == msg.sender, "not owner of token");
        IFuseBlock(fuseBlockAddress).transferFrom(msg.sender, address(this), _tokenId);

        TokenInfo memory token;
        token.tokenId = _tokenId;
        token.staker = msg.sender;
        token.stakedAt = block.timestamp;

        users[msg.sender][_tokenId] = token;
        tokenIds[msg.sender].push(_tokenId);
    }

    function unstake(uint256 _tokenId) external {
        uint256 tokenIndex = findTokenId(msg.sender, _tokenId);
        require(tokenIndex != type(uint256).max, "no exist");
        require(users[msg.sender][_tokenId].staker == msg.sender, "incorrect staker");
        IFuseBlock(fuseBlockAddress).transferFrom(address(this), msg.sender, _tokenId);
        delete users[msg.sender][_tokenId];

        tokenIds[msg.sender][tokenIndex] = tokenIds[msg.sender][tokenIds[msg.sender].length - 1];
        tokenIds[msg.sender].pop();
    }

    function findTokenId(address _staker, uint256 _tokenId) public view returns(uint256) {
        uint256[] memory _tokenIds = tokenIds[_staker];
        uint256 len = _tokenIds.length;
        require(len > 0, "no staked ids");

        for (uint256 i = 0; i < len; i ++) {
            if (_tokenIds[i] == _tokenId) {
                return i;
            }
        }
        return type(uint256).max;
    }

    function calculateRewards(address _staker) public view returns(uint256) {
        uint256[] memory _tokenIds = tokenIds[_staker];
        uint256 len = _tokenIds.length;
        TokenInfo memory token;
        uint256 auraAmount;
        uint256 rewards;
        
        for(uint256 i = 0; i < len; i ++) {
            token = users[msg.sender][_tokenIds[i]];
            auraAmount = IFuseBlock(fuseBlockAddress).getAuraAmount(_tokenIds[i]);
            rewards += auraAmount * ((block.timestamp - token.stakedAt) / rewardInterval);
        }

        return rewards;
    }

    function claimRewards() public {
        uint256 rewards = calculateRewards(msg.sender);
        require(IERC20(auraAddress).balanceOf(address(this)) >= rewards, "insufficient balance");

        uint256 royaltyFee;
        if (royaltyReceiver != address(0)) {
            royaltyFee = rewards * royaltyFraction / FEE_DENOMINATOR;
            IERC20(auraAddress).transfer(royaltyReceiver, royaltyFee);
            IERC20(auraAddress).transfer(msg.sender, rewards - royaltyFee);
        } else {
            IERC20(auraAddress).transfer(msg.sender, rewards);
        }
    }

    function setRoyalyInfo(address _receiver, uint256 _feeFraction) external onlyOwner {
        require(_feeFraction > 0 && _feeFraction < 10000, "invalid fee fraction");
        require(_receiver != address(0), "invalid address");
        royaltyReceiver = _receiver;
        royaltyFraction = _feeFraction;
    }

    function getRoyaltyInfo() external view returns(address, uint256) {
        return (royaltyReceiver, royaltyFraction);
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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