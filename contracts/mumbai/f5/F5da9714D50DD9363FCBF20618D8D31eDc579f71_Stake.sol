// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface IFuseBlock {
    function getAuraAmount(uint256 _tokenId) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function getRequirementStatus(uint256 _tokenId) external view returns(bool);
}

interface IItem {
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function getAuraAmount(uint256 _tokenId) external view returns (uint256);
    function getFuseBlockIdFromItemId(uint256 _itemId) external view returns(uint256);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;
}
contract Stake is Ownable, IERC1155Receiver {
    event StakeNFT(address indexed staker, address indexed tokenAddress, uint256 tokenId, uint256 amount);
    event UnStakeNFT(address indexed staker, address indexed tokenAddress, uint256 tokenId, uint256 amount);
    struct TokenInfo {
        uint256 tokenId;
        address tokenAddress;
        address staker;
        uint256 amount;
        uint256 stakedAt;
    }
    // mapping(address => mapping(uint256 => TokenInfo)) users;
    mapping(address => TokenInfo[]) stakes;

    // tokenAddress => id => index of stakes
    mapping(address => mapping(uint256 => uint256)) stakeIndexes;

    // user => tokenAddress => ids
    mapping(address => mapping(address => uint256[])) tokenIds;

    address public fuseBlockAddress;
    address public itemAddress;
    address public auraAddress;
    uint256 rewardInterval = 1 hours;

    address royaltyReceiver;
    uint256 royaltyFraction;
    uint256 constant FEE_DENOMINATOR = 10000;

    constructor (address _fuseBlockAddress, address _itemAddress, address _auraAddress)  {
        fuseBlockAddress = _fuseBlockAddress;
        itemAddress = _itemAddress;
        auraAddress = _auraAddress;
    }

    modifier onlySupportToken(address _tokenAddress) {
        require(_tokenAddress == fuseBlockAddress || _tokenAddress == itemAddress, "invalid token");
        _;
    }

    function updateRewardsInterval(uint256 _interval) external onlyOwner {
        rewardInterval = _interval;
    }

    function getStakedIds(address _tokenAddress) external view returns(uint256[] memory) {
        return tokenIds[msg.sender][_tokenAddress];
    }

    // function _getStakedIds(address _staker) private view returns(uint256[] memory) {
    //     return tokenIds[_staker];
    // }

    function getAuraAmount() external view returns(uint256) {
        TokenInfo[] memory tokens = stakes[msg.sender];
        uint256 totalAmount;
        uint256 len = tokens.length;

        for(uint256 i = 0; i < len; i ++) {
            if (fuseBlockAddress == tokens[i].tokenAddress) {
                totalAmount += IFuseBlock(fuseBlockAddress).getAuraAmount(tokens[i].tokenId);
            } else {
                totalAmount += IItem(itemAddress).getAuraAmount(tokens[i].tokenId);
            }
            
        }

        return totalAmount;
    }

    function stake(address _tokenAddress, uint256 _tokenId, uint256 _amount) external onlySupportToken(_tokenAddress) {
        require(_amount > 0, "invalid amount");
        if (_tokenAddress == fuseBlockAddress) {
            require(IFuseBlock(fuseBlockAddress).ownerOf(_tokenId) == msg.sender, "not owner of token");
            require(_amount == 1, "invalid amount");
            IFuseBlock(fuseBlockAddress).transferFrom(msg.sender, address(this), _tokenId);
        } else {
            require(IItem(itemAddress).balanceOf(msg.sender, _tokenId) >= _amount, "insufficient balance");
            IItem(itemAddress).safeTransferFrom(msg.sender, address(this), _tokenId, _amount, "");
        }
        
        TokenInfo memory token;
        token.tokenId = _tokenId;
        token.tokenAddress = _tokenAddress;
        token.staker = msg.sender;
        token.amount = _amount;
        token.stakedAt = block.timestamp;
        
        stakeIndexes[_tokenAddress][_tokenId] = stakes[msg.sender].length + 1;
        stakes[msg.sender].push(token);

        tokenIds[msg.sender][_tokenAddress].push(_tokenId);

        emit StakeNFT(msg.sender, _tokenAddress, _tokenId, _amount);
    }

    function unstake(address _tokenAddress, uint256 _tokenId, uint256 _amount) external onlySupportToken(_tokenAddress) {
        require(_amount > 0, "invalid amount");
        uint256 stakeIndex = stakeIndexes[_tokenAddress][_tokenId];
        require(stakeIndex > 0, "no staked tokenId");

        TokenInfo memory token = stakes[msg.sender][stakeIndex - 1];
        require(token.staker == msg.sender, "incorrect staker");

        if (_tokenAddress == fuseBlockAddress) {
            require(_amount == 1, "invalid amount");
            IFuseBlock(fuseBlockAddress).transferFrom(address(this), msg.sender, _tokenId);
        } else {
            require(token.amount >= _amount, "insufficient balance");
            IItem(itemAddress).safeTransferFrom(address(this), msg.sender, _tokenId, _amount, "");
        }

        if (token.amount == _amount) {
            delete stakes[msg.sender][stakeIndex - 1];
            stakeIndexes[_tokenAddress][_tokenId] = 0;
            uint256 tokenIndex = findTokenId(msg.sender, _tokenAddress, _tokenId);

            require(tokenIndex != type(uint256).max, "no exist");

            tokenIds[msg.sender][_tokenAddress][tokenIndex] = tokenIds[msg.sender][_tokenAddress][tokenIds[msg.sender][_tokenAddress].length - 1];
            tokenIds[msg.sender][_tokenAddress].pop();
        } else {
            stakes[msg.sender][stakeIndex - 1].amount = token.amount - _amount;
        }

        emit UnStakeNFT(msg.sender, _tokenAddress, _tokenId, _amount);
    }

    function findTokenId(address _staker, address _tokenAddress ,uint256 _tokenId) public view returns(uint256) {
        uint256[] memory _tokenIds = tokenIds[_staker][_tokenAddress];
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
        TokenInfo[] memory tokens = stakes[_staker];
        uint256 len = tokens.length;
       
        uint256 auraAmount;
        uint256 rewards;
        
        for(uint256 i = 0; i < len; i ++) {
            if (tokens[i].tokenAddress == fuseBlockAddress) {
                auraAmount = IFuseBlock(fuseBlockAddress).getAuraAmount(tokens[i].tokenId);
            } else {
                auraAmount = IItem(itemAddress).getAuraAmount(tokens[i].tokenId) * tokens[i].amount;
            }

            rewards += auraAmount * ((block.timestamp - tokens[i].stakedAt) / rewardInterval);
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

    function updateAuraAddress(address _newAddress) external onlyOwner {
        auraAddress = _newAddress;
    }

    function updateFuseBlockAddress(address _newAddress) external onlyOwner {
        fuseBlockAddress = _newAddress;
    }

    function updateItemAddress(address _newAddress) external onlyOwner {
        itemAddress = _newAddress;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual override returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual override returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) external virtual override view returns (bool){
        return interfaceId == type(IERC165).interfaceId;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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