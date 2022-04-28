/**
 *Submitted for verification at polygonscan.com on 2022-04-27
*/

// File: contracts/IRewardsToken.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.7;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IRewardsToken {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function rewardsMint(address to, uint256 _amount) external;
    function rewardsBurn(address from, uint256 _amount) external;


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;



/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// File: contracts/NFTStaker.sol


pragma solidity ^0.8.7;






abstract contract ReentrancyGuard { 
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
   _status = _ENTERED;

        _;
        _status = _NOT_ENTERED;
    }
}
contract NftStaker is Ownable, ReentrancyGuard{
    using SafeMath for uint256;
    IERC1155 private nft;
    IRewardsToken private rewardsToken;
    bool public canStake = false;
    //allow/disallow staking for tokenID
    mapping (uint256 => bool) public canDeposit;

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }


    uint256 public stakedTotal;    
    uint256 public rewardsTokenAmount = 10 ether;

    // stake weight for tokenId
    // rewardsTokenAmount * stakeWeight
    mapping (uint256 => uint256) public stakeWeight; // tokenId => weight, weight is in wei

    // stakingTime for tokenId
    uint256 public stakingTime = 300; // stakingtime is in seconds
    mapping (uint256 => uint256) public minimum_stakingTime; // tokenId => time, time is in seconds
    

    struct NFTDeposit {
        uint256 id; // array index
        address depositOwner; // deposited user address - nft owner address
        uint256 tokenId; // deposited nft token id
        uint256 amount; // deposited nft amount
        bool isWithdrawn; // status if this value is true, in this case user can't withdraw, and false, user can withdraw
        uint256 depositTime; // deposit time(block.time current)
        uint256 timeLockInSeconds; // minimum staking time for tokenID
        uint256 rewardsEarned; // all earned rewards amount via staking
        uint256 rewardsReleased; // released earned rewards amount
    }

    NFTDeposit[] public nftDeposits;

    event NFTDepositLog(
        uint256 depositId,
        address depositOwner,
        uint256 tokenId,
        uint256 amount,
        bool isWithdrawn,
        uint256 depositTime,
        uint256 timeLockInSeconds,
        uint256 rewardsEarned,
        uint256 rewardsReleased
    );

    event NFTWithdrawLog(
        uint256 depositId,
        address depositOwner,
        uint256 tokenId,
        uint256 amount,
        uint256 withdrawTime,
        bool forceWithdraw,
        uint256 rewardsEarned,
        uint256 rewardsReleased
    );

    event RewardsWithdrawLog(
        uint256 depositId,
        address depositOwner,
        uint256 tokenId,
        uint256 amount,
        uint256 withdrawTime,
        uint256 rewardsEarned,
        uint256 rewardsReleased
    );
    

    constructor(IERC1155 _nft, IRewardsToken _rewardsToken) {        
        nft = _nft;
        rewardsToken = _rewardsToken;
        canStake = true;
    }

    function pause() external onlyOwner{
        canStake = false;
    }

    function unpause() external onlyOwner{
        canStake = true;
    }

    function setCanDeposit(uint256 tokenId, bool value) external onlyOwner {
        canDeposit[tokenId] = value;
    }

    function setMinimumStakingTime(uint256 tokenId, uint256 _minimumStakingTime) external onlyOwner{
        minimum_stakingTime[tokenId] = _minimumStakingTime;
    }

    function setStakingTime(uint256 _stakingTime) external onlyOwner{
        stakingTime = _stakingTime;
    }

    function setRewardsTokenAmount(uint256 _newRewardsTokenAmount) external onlyOwner {
        rewardsTokenAmount = _newRewardsTokenAmount;
    }

    function setStakeWeight(uint256 _tokenId, uint256 _weight) external onlyOwner {
        stakeWeight[_tokenId] = _weight;
    }

    function stake(uint256 tokenId, uint256 amount) public {        
        _stake(tokenId, amount);
    }

    function stakeBatch(uint256[] memory tokenIds, uint256[] memory amounts) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {            
            _stake(tokenIds[i], amounts[i]);
        }
    }

    function _stake(uint256 _tokenId,uint256 _amount) internal {
        require(canStake = true, "Staking is temporarily disabled");   
        require(canDeposit[_tokenId], "You can't stake for this tokenId");     
        require(nft.balanceOf(msg.sender, _tokenId) != 0, "User must be the owner of the staked nft");
        if (_tokenId == 1)
        {
            require(_amount == 1, 'You can only stake one FREE NFT');
            // check if tokenID 1 is already staked before.
            for (uint256 i = 0; i < nftDeposits.length; i++)
            {
                if (nftDeposits[i].depositOwner == msg.sender && nftDeposits[i].tokenId == _tokenId)
                {
                    require(nftDeposits[i].isWithdrawn == true, 'Please unstake first');
                }
            }            
        }   

        uint256 newItemId = nftDeposits.length;
        nftDeposits.push(
            NFTDeposit(
                newItemId,
                msg.sender,
                _tokenId,
                _amount,
                false,
                block.timestamp,
                minimum_stakingTime[_tokenId],
                0,
                0
            )
        );

        nft.safeTransferFrom(msg.sender, address(this), _tokenId, _amount, "");

        stakedTotal = stakedTotal + _amount;

        emit NFTDepositLog(
            newItemId,
            msg.sender,
            _tokenId,
            _amount,
            false,
            block.timestamp,
            minimum_stakingTime[_tokenId],
            0,
            0
        );
    }    

    function _restake(uint256 depositId) internal {

        require(depositId <= nftDeposits.length);
        require(nftDeposits[depositId].depositOwner == msg.sender, "You can only withdraw your own deposits.");
        require((block.timestamp - nftDeposits[depositId].depositTime) >= nftDeposits[depositId].timeLockInSeconds + stakingTime, "You can't yet unlock this deposit.  please use emergencyUnstake instead");
        require(rewardsTokenAmount > 0, "Smart contract owner hasn't defined reward for your deposit. Please contact support team.");  
        nftDeposits[depositId].depositTime = block.timestamp;     
        uint256 rewardMultiplier = ((block.timestamp - nftDeposits[depositId].depositTime -nftDeposits[depositId].timeLockInSeconds) / stakingTime) * stakeWeight[nftDeposits[depositId].tokenId] ;
        nftDeposits[depositId].rewardsEarned += rewardsTokenAmount * rewardMultiplier;

        emit NFTDepositLog(
            depositId,
            msg.sender,
            nftDeposits[depositId].tokenId,
            nftDeposits[depositId].amount,
            false,
            block.timestamp,
            minimum_stakingTime[nftDeposits[depositId].tokenId],
            nftDeposits[depositId].rewardsEarned,
            nftDeposits[depositId].rewardsReleased
        );
    }

  

    // Unstake without caring about rewards. EMERGENCY ONLY.
    function emergencyUnstake(uint256 depositId) public {      

        require(depositId <= nftDeposits.length);

        require(nftDeposits[depositId].depositOwner == msg.sender, "Only the sender can withdraw this deposit");

        require(nftDeposits[depositId].isWithdrawn == false, "This deposit has already been withdrawn.");

        // nft.safeTransferFrom(address(this), msg.sender, nftDeposits[depositId].tokenId);

        stakedTotal = stakedTotal - nftDeposits[depositId].amount;

        nftDeposits[depositId].isWithdrawn = true;

        emit NFTWithdrawLog(
            depositId,
            msg.sender,
            nftDeposits[depositId].tokenId,
            nftDeposits[depositId].amount,
            block.timestamp,
            true,
            nftDeposits[depositId].rewardsEarned,
            nftDeposits[depositId].rewardsReleased
        );
    }

    function unstake(uint256 depositId) public {

        require(depositId <= nftDeposits.length, "Deposit id is not valid");
        require(nftDeposits[depositId].isWithdrawn == false, "This deposit has already been withdrawn.");
        require(nftDeposits[depositId].depositOwner == msg.sender, "You can only withdraw your own deposits.");
        require((block.timestamp - nftDeposits[depositId].depositTime) >= nftDeposits[depositId].timeLockInSeconds + stakingTime, "You can't yet unlock this deposit.  please use emergencyUnstake instead");
        require(rewardsTokenAmount > 0, "Smart contract owner hasn't defined reward for your deposit. Please contact support team.");
        nft.safeTransferFrom(address(this), msg.sender, nftDeposits[depositId].tokenId, nftDeposits[depositId].amount, "");        
        stakedTotal = stakedTotal - nftDeposits[depositId].amount;
        nftDeposits[depositId].isWithdrawn = true;
        uint256 rewardMultiplier = ((block.timestamp - nftDeposits[depositId].depositTime -nftDeposits[depositId].timeLockInSeconds) / stakingTime) * stakeWeight[nftDeposits[depositId].tokenId];
        nftDeposits[depositId].rewardsEarned += rewardsTokenAmount * rewardMultiplier;
        emit NFTWithdrawLog(
            depositId,
            msg.sender,
            nftDeposits[depositId].tokenId,
            nftDeposits[depositId].amount,
            block.timestamp,
            false,
            nftDeposits[depositId].rewardsEarned,
            nftDeposits[depositId].rewardsReleased
        );
    }

    function withdrawRewards(uint256 depositId) public nonReentrant{
        require(depositId <= nftDeposits.length);
        require(nftDeposits[depositId].rewardsEarned  > 0, "Amount should be greater than zero");
        rewardsToken.rewardsMint(msg.sender, nftDeposits[depositId].rewardsEarned );
        nftDeposits[depositId].rewardsReleased += nftDeposits[depositId].rewardsEarned;
        nftDeposits[depositId].rewardsEarned = 0;

        emit RewardsWithdrawLog(
            depositId,
            msg.sender,
            nftDeposits[depositId].tokenId,
            nftDeposits[depositId].amount,
            block.timestamp,
            0,
            nftDeposits[depositId].rewardsReleased
        );
    }

    function withdrawAllRewards() public nonReentrant{
        for(uint256 i = 0; i < nftDeposits.length; i++) {
            if(nftDeposits[i].rewardsEarned > 0 && nftDeposits[i].depositOwner == msg.sender) {
                rewardsToken.rewardsMint(msg.sender, nftDeposits[i].rewardsEarned );
                nftDeposits[i].rewardsReleased += nftDeposits[i].rewardsEarned;
                nftDeposits[i].rewardsEarned = 0;
                emit RewardsWithdrawLog(
                    i,
                    msg.sender,
                    nftDeposits[i].tokenId,
                    nftDeposits[i].amount,
                    block.timestamp,
                    0,
                    nftDeposits[i].rewardsReleased
                );
            }
        }
    }

    function getItemIndexByNFT(uint256 tokenId) external view returns (uint256) {
        uint256 depositId;
        for(uint256 i = 0; i < nftDeposits.length; i ++){
            if(tokenId == nftDeposits[i].tokenId){
                depositId = nftDeposits[i].id;
            }
        }
        return depositId;
    }
    
    function getRewardsAmount(uint256 depositId) external view returns (uint256, uint256) {
        require(depositId <= nftDeposits.length, "Deposit id is not valid");        
        require(rewardsTokenAmount > 0, "Smart contract owner hasn't defined reward for this depositId. Please contact support team.");  
        if ((block.timestamp - nftDeposits[depositId].depositTime) >= nftDeposits[depositId].timeLockInSeconds+stakingTime) {
            uint256 rewardMultiplier = ((block.timestamp - nftDeposits[depositId].depositTime -nftDeposits[depositId].timeLockInSeconds) / stakingTime) * stakeWeight[nftDeposits[depositId].tokenId] ;
            uint256 rewardAmount = nftDeposits[depositId].rewardsEarned + rewardsTokenAmount * rewardMultiplier;          
            return (rewardAmount, nftDeposits[depositId].rewardsReleased);
        } else {
            return (nftDeposits[depositId].rewardsEarned, nftDeposits[depositId].rewardsReleased);
        }
    }


    function getAllRewardsAmount(address _stakerAddres) external view returns(uint256, uint256) {
        uint256 totalRewardsEarned = 0;
        uint256 totalRewardsReleased = 0;
        for (uint256 i = 0; i < nftDeposits.length; i++) {
            if (nftDeposits[i].depositOwner==_stakerAddres){
                if ((block.timestamp - nftDeposits[i].depositTime) >= nftDeposits[i].timeLockInSeconds+stakingTime) {
                    uint256 rewardMultiplier = ((block.timestamp - nftDeposits[i].depositTime- nftDeposits[i].timeLockInSeconds) / stakingTime) * stakeWeight[nftDeposits[i].tokenId];
                    uint256 rewardAmount = nftDeposits[i].rewardsEarned + rewardsTokenAmount * rewardMultiplier;
                    totalRewardsEarned += rewardAmount;
                    totalRewardsReleased += nftDeposits[i].rewardsReleased;
                } else {
                    totalRewardsEarned += nftDeposits[i].rewardsEarned;
                    totalRewardsReleased += nftDeposits[i].rewardsReleased;
                }
            }
        }
        return (totalRewardsEarned, totalRewardsReleased);
    }

    function getActivityLogs(address _walletAddress) external view returns (NFTDeposit[] memory) {
        address walletAddress = _walletAddress;
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for(uint256 i = 0; i < nftDeposits.length; i ++){
            if(walletAddress == nftDeposits[i].depositOwner){
                itemCount += 1;
            }
        }
        NFTDeposit[] memory items = new NFTDeposit[](itemCount);
        for (uint256 i = 0; i < nftDeposits.length; i++) {
            if(walletAddress == nftDeposits[i].depositOwner){
                NFTDeposit storage item = nftDeposits[i];
                items[currentIndex] = item;
                currentIndex += 1;
            }
        }
        return items;
    }
}