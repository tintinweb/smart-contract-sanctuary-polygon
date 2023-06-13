/**
 *Submitted for verification at polygonscan.com on 2023-06-13
*/

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


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: contracts/raffle.sol


pragma solidity ^0.8.0;





contract RUFFRAFFLE is Ownable {
    using SafeMath for uint256;

    struct RaffleInfo {
        address creator;
        bool isActive;
        uint256 ticketPrice;
        uint256 maxTickets;
        uint256 ticketsSold;
        address[] participants;
        address winner;
        address tokenContract;
        uint256 tokenId;
    }

    mapping(uint256 => RaffleInfo) public raffles;
    mapping(uint256 => bool) public raffleExists;
    mapping(address => uint256[]) private userRaffles;
    mapping(address => mapping(address => uint256)) private supportedTokens;

    uint256 private raffleIdCounter;
    uint256 private serviceFeePercentage;

    event RaffleCreated(uint256 indexed raffleId, address indexed creator);
    event RaffleTicketPurchased(uint256 indexed raffleId, address indexed participant, uint256 numTickets, uint256 totalCost);
    event RaffleWinnerSelected(uint256 indexed raffleId, address indexed winner);
    event ServiceFeeWithdrawn(address indexed admin, uint256 amount);
    event TokenAdded(address indexed tokenAddress);
    event TokensWithdrawn(address indexed tokenAddress, address indexed recipient, uint256 amount);
    event NFTTransferred(uint256 indexed raffleId, address indexed recipient);
    event AllTokensWithdrawn(address indexed recipient);
    event RaffleRemoved(uint256 indexed raffleId);

    modifier onlyRaffleCreator(uint256 raffleId) {
        require(raffleExists[raffleId], "Raffle does not exist.");
        require(msg.sender == raffles[raffleId].creator, "Only raffle creator can call this function.");
        _;
    }

    constructor() {
        serviceFeePercentage = 2;
    }

    function createRaffle(
        address tokenContract,
        uint256 tokenId,
        uint256 ticketPrice,
        uint256 maxTickets
    ) external {
        require(ticketPrice > 0, "Ticket price should be greater than zero.");
        require(maxTickets > 0, "Max tickets should be greater than zero.");

        raffles[raffleIdCounter] = RaffleInfo(
            msg.sender,
            true,
            ticketPrice,
            maxTickets,
            0,
            new address[](0),
            address(0),
            tokenContract,
            tokenId
        );

        raffleExists[raffleIdCounter] = true;
        userRaffles[msg.sender].push(raffleIdCounter);

        emit RaffleCreated(raffleIdCounter, msg.sender);

        raffleIdCounter++;
    }

    function purchaseRaffleTicket(uint256 raffleId, uint256 numTickets, address tokenAddress) external payable {
        require(raffleExists[raffleId], "Raffle does not exist.");
        require(raffles[raffleId].isActive, "Raffle is not active.");
        require(numTickets > 0, "Number of tickets should be greater than zero.");
        require(raffles[raffleId].ticketsSold.add(numTickets) <= raffles[raffleId].maxTickets, "Exceeded maximum tickets.");

        uint256 totalCost = raffles[raffleId].ticketPrice.mul(numTickets);

        if (tokenAddress == address(0)) {
            require(msg.value >= totalCost, "Insufficient Ether sent.");
            // Send any excess Ether back to the sender
            if (msg.value > totalCost) {
                payable(msg.sender).transfer(msg.value.sub(totalCost));
            }
        } else {
            require(supportedTokens[msg.sender][tokenAddress] >= totalCost, "Insufficient tokens balance.");
            supportedTokens[msg.sender][tokenAddress] = supportedTokens[msg.sender][tokenAddress].sub(totalCost);
        }

        raffles[raffleId].participants.push(msg.sender);
        raffles[raffleId].ticketsSold = raffles[raffleId].ticketsSold.add(numTickets);

        emit RaffleTicketPurchased(raffleId, msg.sender, numTickets, totalCost);

        // Check if all tickets are sold
        if (raffles[raffleId].ticketsSold == raffles[raffleId].maxTickets) {
            _selectWinner(raffleId);
        }
    }

    function _selectWinner(uint256 raffleId) private {
        require(raffles[raffleId].isActive, "Raffle is not active.");
        require(raffles[raffleId].ticketsSold == raffles[raffleId].maxTickets, "All tickets are not sold yet.");

        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1)))) % raffles[raffleId].maxTickets;
        address winner = raffles[raffleId].participants[randomNumber];
        raffles[raffleId].winner = winner;
        raffles[raffleId].isActive = false;

        emit RaffleWinnerSelected(raffleId, winner);
    }

    function withdrawServiceFee(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount should be greater than zero.");
        require(amount <= address(this).balance, "Insufficient contract balance.");

        payable(owner()).transfer(amount);

        emit ServiceFeeWithdrawn(owner(), amount);
    }

    function addSupportedToken(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0), "Invalid token address.");

        supportedTokens[owner()][tokenAddress] = 0;

        emit TokenAdded(tokenAddress);
    }

    function withdrawTokens(address tokenAddress, address recipient, uint256 amount) external onlyOwner {
        require(tokenAddress != address(0), "Invalid token address.");
        require(recipient != address(0), "Invalid recipient address.");
        require(amount > 0, "Amount should be greater than zero.");
        require(amount <= supportedTokens[owner()][tokenAddress], "Insufficient token balance.");

        supportedTokens[owner()][tokenAddress] = supportedTokens[owner()][tokenAddress].sub(amount);

        IERC20(tokenAddress).transfer(recipient, amount);

        emit TokensWithdrawn(tokenAddress, recipient, amount);
    }

    function transferNFT(uint256 raffleId, address recipient) external onlyRaffleCreator(raffleId) {
        require(!raffles[raffleId].isActive, "Raffle is still active.");
        require(raffles[raffleId].winner != address(0), "Winner is not selected.");

        IERC721(raffles[raffleId].tokenContract).transferFrom(address(this), recipient, raffles[raffleId].tokenId);

        emit NFTTransferred(raffleId, recipient);
    }

    function withdrawAllTokens(address recipient) external onlyOwner {
    require(recipient != address(0), "Invalid recipient address.");

    address[] memory tokens = getSupportedTokens(msg.sender);
    uint256[] memory balances = getSupportedTokensBalance(msg.sender);

    for (uint256 i = 0; i < tokens.length; i++) {
        address tokenAddress = tokens[i];
        uint256 tokenBalance = balances[i];

        require(tokenBalance > 0, "Token balance is zero.");

        supportedTokens[msg.sender][tokenAddress] = 0;
        IERC20(tokenAddress).transfer(recipient, tokenBalance);

        emit TokensWithdrawn(tokenAddress, recipient, tokenBalance);
    }

    emit AllTokensWithdrawn(recipient);
}

    function removeRaffle(uint256 raffleId) external onlyRaffleCreator(raffleId) {
        require(raffleExists[raffleId], "Raffle does not exist.");

        delete raffles[raffleId];
        delete raffleExists[raffleId];

        for (uint256 i = 0; i < userRaffles[msg.sender].length; i++) {
            if (userRaffles[msg.sender][i] == raffleId) {
                userRaffles[msg.sender][i] = userRaffles[msg.sender][userRaffles[msg.sender].length - 1];
                userRaffles[msg.sender].pop();
                break;
            }
        }

        emit RaffleRemoved(raffleId);
    }

    function getRaffleCount(address creator) external view returns (uint256) {
        return userRaffles[creator].length;
    }

    function getRaffleId(address creator, uint256 index) external view returns (uint256) {
        require(index < userRaffles[creator].length, "Invalid index.");
        return userRaffles[creator][index];
    }

    function getRaffleParticipants(uint256 raffleId) external view returns (address[] memory) {
        require(raffleExists[raffleId], "Raffle does not exist.");
        return raffles[raffleId].participants;
    }

    function getSupportedTokens(address user) public view returns (address[] memory) {
    uint256 tokenCount = 0;

    for (uint256 i = 0; i < userRaffles[user].length; i++) {
        uint256 raffleId = userRaffles[user][i];
        if (raffles[raffleId].isActive) {
            tokenCount++;
        }
    }

    address[] memory tokens = new address[](tokenCount);

    uint256 tokenIndex = 0;

    for (uint256 i = 0; i < userRaffles[user].length; i++) {
        uint256 raffleId = userRaffles[user][i];
        if (raffles[raffleId].isActive) {
            tokens[tokenIndex] = raffles[raffleId].tokenContract;
            tokenIndex++;
        }
    }

    return tokens;
}

    function getSupportedTokensBalance(address user) public view returns (uint256[] memory) {
        uint256 tokenCount = 0;

        for (uint256 i = 0; i < userRaffles[user].length; i++) {
            uint256 raffleId = userRaffles[user][i];
            if (raffles[raffleId].isActive) {
                tokenCount++;
            }
        }

        uint256[] memory balances = new uint256[](tokenCount);

        uint256 tokenIndex = 0;

        for (uint256 i = 0; i < userRaffles[user].length; i++) {
            uint256 raffleId = userRaffles[user][i];
            if (raffles[raffleId].isActive) {
                balances[tokenIndex] = supportedTokens[user][raffles[raffleId].tokenContract];
                tokenIndex++;
            }
        }

        return balances;
    }

}