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





contract RuffRaffle is Ownable {
    using SafeMath for uint256;

    struct RaffleInfo {
    address creator;
    address tokenContract;
    uint256 ticketPrice;
    uint256 totalTickets;
    uint256 ticketsSold;
    bool isActive;
    address[] participants;
    address nftContract;
    uint256 nftTokenId;
    mapping(address => uint256) ticketsBought;
}

    mapping(uint256 => RaffleInfo) private raffles;
    mapping(uint256 => bool) private raffleExists;
    mapping(address => uint256[]) private userRaffles;
    mapping(address => mapping(address => uint256)) private supportedTokens;
    uint256 private serviceFeePercentage;

    event SupportedTokenAdded(address indexed tokenContract);
    event RaffleCreated(uint256 indexed raffleId, address indexed creator);
    event RaffleParticipated(uint256 indexed raffleId, address indexed participant, uint256 ticketsBought);
    event TokensDeposited(address indexed tokenAddress, address indexed sender, uint256 amount);
    event TokensWithdrawn(address indexed tokenAddress, address indexed recipient, uint256 amount);
    event AllTokensWithdrawn(address indexed recipient);
    event RaffleRemoved(uint256 indexed raffleId);
    event NFTSent(uint256 indexed raffleId, address indexed recipient, uint256 tokenId);

    modifier onlyActiveRaffle(uint256 raffleId) {
        require(raffleExists[raffleId], "Raffle does not exist.");
        require(raffles[raffleId].isActive, "Raffle is not active.");
        _;
    }

    modifier onlyRaffleCreator(uint256 raffleId) {
        require(raffleExists[raffleId], "Raffle does not exist.");
        require(raffles[raffleId].creator == msg.sender, "Only the raffle creator can perform this action.");
        _;
    }

    constructor() {
        serviceFeePercentage = 10; // 10% service fee by default
    }

    function createRaffle(
    address tokenContract,
    uint256 ticketPrice,
    uint256 totalTickets,
    address nftContract,
    uint256 nftTokenId
) external {
    require(tokenContract != address(0), "Invalid token contract address.");
    require(ticketPrice > 0, "Ticket price should be greater than zero.");
    require(totalTickets > 0, "Total tickets should be greater than zero.");
    require(nftContract != address(0), "Invalid NFT contract address.");

    uint256 raffleId = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp)));

    RaffleInfo storage raffle = raffles[raffleId]; // Temporary variable declaration

    raffle.creator = msg.sender;
    raffle.tokenContract = tokenContract;
    raffle.ticketPrice = ticketPrice;
    raffle.totalTickets = totalTickets;
    raffle.ticketsSold = 0;
    raffle.isActive = true;
    raffle.participants = new address[](0);
    raffle.nftContract = nftContract;
    raffle.nftTokenId = nftTokenId;

    raffleExists[raffleId] = true;
    userRaffles[msg.sender].push(raffleId);

    emit RaffleCreated(raffleId, msg.sender);
}

    function participate(uint256 raffleId, uint256 tickets) external onlyActiveRaffle(raffleId) {
        require(tickets > 0, "Number of tickets should be greater than zero.");

        RaffleInfo storage raffle = raffles[raffleId];
        uint256 totalCost = tickets.mul(raffle.ticketPrice);

        require(totalCost > 0, "Total cost should be greater than zero.");
        require(raffle.ticketsSold.add(tickets) <= raffle.totalTickets, "Insufficient tickets available.");

        IERC20 token = IERC20(raffle.tokenContract);
        require(token.balanceOf(msg.sender) >= totalCost, "Insufficient token balance.");

        raffle.ticketsBought[msg.sender] = raffle.ticketsBought[msg.sender].add(tickets);
        raffle.ticketsSold = raffle.ticketsSold.add(tickets);
        raffle.participants.push(msg.sender);

        token.transferFrom(msg.sender, address(this), totalCost);

        emit RaffleParticipated(raffleId, msg.sender, tickets);
    }

    function depositTokens(address tokenContract, uint256 amount) external {
        require(tokenContract != address(0), "Invalid token contract address.");
        require(amount > 0, "Amount should be greater than zero.");

        IERC20 token = IERC20(tokenContract);
        uint256 allowance = token.allowance(msg.sender, address(this));

        require(allowance >= amount, "Insufficient token allowance.");

        token.transferFrom(msg.sender, address(this), amount);

        supportedTokens[msg.sender][tokenContract] = supportedTokens[msg.sender][tokenContract].add(amount);

        emit TokensDeposited(tokenContract, msg.sender, amount);
    }

    function withdrawTokens(address tokenContract, uint256 amount) external {
        require(tokenContract != address(0), "Invalid token contract address.");
        require(amount > 0, "Amount should be greater than zero.");

        uint256 balance = supportedTokens[msg.sender][tokenContract];

        require(balance >= amount, "Insufficient token balance.");

        IERC20 token = IERC20(tokenContract);

        token.transfer(msg.sender, amount);

        supportedTokens[msg.sender][tokenContract] = supportedTokens[msg.sender][tokenContract].sub(amount);

        emit TokensWithdrawn(tokenContract, msg.sender, amount);
    }

    function withdrawAllTokens() external {
        require(address(this).balance > 0, "Contract has no balance.");

        for (uint256 i = 0; i < userRaffles[msg.sender].length; i++) {
            uint256 raffleId = userRaffles[msg.sender][i];
            require(!raffles[raffleId].isActive, "Cannot withdraw tokens while there are active raffles.");
        }

        uint256 balance;

        for (uint256 i = 0; i < userRaffles[msg.sender].length; i++) {
            uint256 raffleId = userRaffles[msg.sender][i];
            for (uint256 j = 0; j < raffles[raffleId].participants.length; j++) {
                if (raffles[raffleId].participants[j] == msg.sender) {
                    balance = balance.add(raffles[raffleId].ticketPrice.mul(raffles[raffleId].ticketsBought[msg.sender]));
                }
            }
        }

        require(balance > 0, "No tokens to withdraw.");

        for (uint256 i = 0; i < userRaffles[msg.sender].length; i++) {
            uint256 raffleId = userRaffles[msg.sender][i];
            delete raffles[raffleId].ticketsBought[msg.sender];
        }

        address[] memory userTokenContracts = new address[](userRaffles[msg.sender].length);
        for (uint256 i = 0; i < userRaffles[msg.sender].length; i++) {
            uint256 raffleId = userRaffles[msg.sender][i];
            userTokenContracts[i] = raffles[raffleId].tokenContract;
            delete supportedTokens[msg.sender][raffles[raffleId].tokenContract];
        }

        IERC20 token = IERC20(userTokenContracts[0]);

        token.transfer(msg.sender, balance);

        emit AllTokensWithdrawn(msg.sender);
    }

    function removeRaffle(uint256 raffleId) external onlyRaffleCreator(raffleId) {
        require(!raffles[raffleId].isActive, "Cannot remove an active raffle.");

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

    function setServiceFeePercentage(uint256 percentage) external onlyOwner {
        require(percentage > 0 && percentage <= 100, "Invalid percentage value.");

        serviceFeePercentage = percentage;
    }

    function getServiceFeePercentage() external view returns (uint256) {
        return serviceFeePercentage;
    }

    function getRaffleInfo(uint256 raffleId) external view returns (
        address creator,
        address tokenContract,
        uint256 ticketPrice,
        uint256 totalTickets,
        uint256 ticketsSold,
        bool isActive,
        address[] memory participants
    ) {
        require(raffleExists[raffleId], "Raffle does not exist.");

        RaffleInfo storage raffle = raffles[raffleId];

        return (
            raffle.creator,
            raffle.tokenContract,
            raffle.ticketPrice,
            raffle.totalTickets,
            raffle.ticketsSold,
            raffle.isActive,
            raffle.participants
        );
    }

    function getUserRaffles(address user) external view returns (uint256[] memory) {
        return userRaffles[user];
    }

    function getSupportedTokens(address user) external view returns (address[] memory) {
        address[] memory tokens = new address[](userRaffles[user].length);

        for (uint256 i = 0; i < userRaffles[user].length; i++) {
            tokens[i] = raffles[userRaffles[user][i]].tokenContract;
        }

        return tokens;
    }

    function addSupportedToken(address tokenContract) external onlyOwner {
        require(tokenContract != address(0), "Invalid token contract address.");

        supportedTokens[owner()][tokenContract] = 1;

        emit SupportedTokenAdded(tokenContract);
    }

    function sendNFTToWinner(uint256 raffleId, address winner, uint256 tokenId) external onlyOwner {
        require(raffleExists[raffleId], "Raffle does not exist.");
        require(raffles[raffleId].isActive == false, "Cannot send NFT while raffle is active.");

        IERC721 token = IERC721(raffles[raffleId].tokenContract);
        token.transferFrom(address(this), winner, tokenId);

        emit NFTSent(raffleId, winner, tokenId);
    }
}