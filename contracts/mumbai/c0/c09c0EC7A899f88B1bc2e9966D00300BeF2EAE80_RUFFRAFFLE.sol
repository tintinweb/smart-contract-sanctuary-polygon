/**
 *Submitted for verification at polygonscan.com on 2023-06-12
*/

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




contract RUFFRAFFLE {
    using SafeMath for uint256;

    enum RaffleType {Ether, Token, NFT}

    struct Raffle {
        address creator;
        address tokenContract;
        uint256 tokenId;
        uint256 ticketPrice;
        uint256 maxTickets;
        uint256 ticketsSold;
        bool isActive;
        address winner;
        address[] participants;
        uint256 endTime;
        RaffleType raffleType;
    }

    mapping(uint256 => Raffle) public raffles;
    mapping(uint256 => bool) public raffleExists;
    mapping(address => uint256[]) public userRaffles;
    mapping(address => mapping(address => uint256)) public supportedTokens;

    uint256 public raffleIdCounter;
    uint256 public serviceFeePercentage;
    address public admin;

    event RaffleCreated(
        uint256 indexed raffleId,
        address indexed creator,
        address indexed tokenContract,
        uint256 tokenId,
        uint256 ticketPrice,
        uint256 maxTickets
    );

    event RaffleTicketPurchased(uint256 indexed raffleId, address indexed buyer, uint256 numTickets, uint256 totalPrice);
    event RaffleWinnerSelected(uint256 indexed raffleId, address indexed winner);
    event RaffleRemoved(uint256 indexed raffleId);
    event ServiceFeeWithdrawn(address indexed admin, uint256 amount);
    event TokenAdded(address indexed tokenAddress);
    event TokensWithdrawn(address indexed tokenAddress, address indexed recipient, uint256 amount);
    event AllTokensWithdrawn(address indexed recipient);
    event NFTTransferred(uint256 indexed raffleId, address indexed recipient);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier onlyRaffleCreator(uint256 raffleId) {
        require(msg.sender == raffles[raffleId].creator, "Only the raffle creator can call this function.");
        _;
    }

    constructor() {
        admin = msg.sender;
        serviceFeePercentage = 1;
    }

    function createRaffle(
        address tokenContract,
        uint256 tokenId,
        uint256 ticketPrice,
        uint256 maxTickets,
        uint256 durationMinutes,
        RaffleType raffleType
    ) external {
        require(ticketPrice > 0, "Invalid ticket price.");
        require(maxTickets > 0, "Invalid maximum tickets.");
        require(durationMinutes > 0, "Invalid duration.");

        uint256 raffleId = raffleIdCounter++;
        Raffle storage newRaffle = raffles[raffleId];
        newRaffle.creator = msg.sender;
        newRaffle.tokenContract = tokenContract;
        newRaffle.tokenId = tokenId;
        newRaffle.ticketPrice = ticketPrice;
        newRaffle.maxTickets = maxTickets;
        newRaffle.ticketsSold = 0;
        newRaffle.isActive = true;
        newRaffle.raffleType = raffleType;

        uint256 endTime = block.timestamp + (durationMinutes * 1 minutes);
        newRaffle.endTime = endTime;

        raffleExists[raffleId] = true;
        userRaffles[msg.sender].push(raffleId);

        emit RaffleCreated(raffleId, msg.sender, tokenContract, tokenId, ticketPrice, maxTickets);
    }

    function purchaseTickets(uint256 raffleId, uint256 numTickets) external payable {
        require(raffleExists[raffleId], "Raffle does not exist.");
        require(raffles[raffleId].isActive, "Raffle is not active.");
        require(numTickets > 0, "Invalid number of tickets.");

        Raffle storage raffle = raffles[raffleId];
        require(raffle.ticketsSold.add(numTickets) <= raffle.maxTickets, "Not enough tickets available.");

        uint256 totalPrice = raffle.ticketPrice.mul(numTickets);

        if (raffle.raffleType == RaffleType.Ether) {
            require(msg.value == totalPrice, "Incorrect amount of Ether sent.");
        } else if (raffle.raffleType == RaffleType.Token) {
            address tokenContract = raffle.tokenContract;
            uint256 requiredTokens = supportedTokens[tokenContract][msg.sender].mul(totalPrice).div(1e18);
            require(requiredTokens >= totalPrice, "Insufficient tokens approved.");

            IERC20(tokenContract).transferFrom(msg.sender, address(this), totalPrice);
            supportedTokens[tokenContract][msg.sender] = supportedTokens[tokenContract][msg.sender].sub(requiredTokens);
        } else if (raffle.raffleType == RaffleType.NFT) {
            require(msg.value == 0, "Ether not allowed for NFT raffles.");

            IERC721(raffle.tokenContract).transferFrom(msg.sender, address(this), raffle.tokenId);
        }

        for (uint256 i = 0; i < numTickets; i++) {
            raffle.participants.push(msg.sender);
        }

        raffle.ticketsSold = raffle.ticketsSold.add(numTickets);

        emit RaffleTicketPurchased(raffleId, msg.sender, numTickets, totalPrice);
    }

    function selectWinner(uint256 raffleId) external onlyRaffleCreator(raffleId) {
        require(raffleExists[raffleId], "Raffle does not exist.");
        require(raffles[raffleId].isActive, "Raffle is not active.");
        require(raffles[raffleId].ticketsSold > 0, "No tickets sold for the raffle.");

        Raffle storage raffle = raffles[raffleId];
        require(block.timestamp >= raffle.endTime, "Raffle has not ended yet.");

        uint256 winningIndex = generateRandomNumber(raffleId, raffle.ticketsSold);
        address winner = raffle.participants[winningIndex];
        raffle.winner = winner;
        raffle.isActive = false;

        emit RaffleWinnerSelected(raffleId, winner);
    }

    function removeRaffle(uint256 raffleId) external onlyRaffleCreator(raffleId) {
        require(raffleExists[raffleId], "Raffle does not exist.");

        Raffle storage raffle = raffles[raffleId];
        require(raffle.isActive == false, "Raffle is still active.");

        delete raffles[raffleId];
        delete raffleExists[raffleId];

        emit RaffleRemoved(raffleId);
    }

    function withdrawServiceFee(uint256 amount) external onlyAdmin {
        require(amount > 0, "Invalid amount.");

        uint256 serviceFee = amount.mul(serviceFeePercentage).div(100);
        require(serviceFee <= address(this).balance, "Insufficient contract balance.");

        payable(admin).transfer(serviceFee);

        emit ServiceFeeWithdrawn(admin, serviceFee);
    }

    function addToken(address tokenAddress) external onlyAdmin {
        supportedTokens[tokenAddress][admin] = type(uint256).max;

        emit TokenAdded(tokenAddress);
    }

    function withdrawTokens(address tokenAddress, address recipient, uint256 amount) external onlyAdmin {
        require(amount > 0, "Invalid amount.");

        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        require(amount <= balance, "Insufficient token balance.");

        IERC20(tokenAddress).transfer(recipient, amount);

        emit TokensWithdrawn(tokenAddress, recipient, amount);
    }

    function withdrawAllTokens(address recipient) external onlyAdmin {
        require(recipient != address(0), "Invalid recipient.");

        for (uint256 i = 0; i < userRaffles[admin].length; i++) {
            uint256 raffleId = userRaffles[admin][i];
            Raffle storage raffle = raffles[raffleId];
            if (raffle.raffleType == RaffleType.Token) {
                address tokenContract = raffle.tokenContract;
                uint256 balance = IERC20(tokenContract).balanceOf(address(this));
                if (balance > 0) {
                    IERC20(tokenContract).transfer(recipient, balance);
                }
            }
        }

        emit AllTokensWithdrawn(recipient);
    }

    function transferNFT(uint256 raffleId, address recipient) external onlyAdmin {
        require(raffleExists[raffleId], "Raffle does not exist.");
        require(raffles[raffleId].isActive == false, "Raffle is still active.");
        require(raffles[raffleId].raffleType == RaffleType.NFT, "Raffle is not an NFT raffle.");

        Raffle storage raffle = raffles[raffleId];
        IERC721(raffle.tokenContract).transferFrom(address(this), recipient, raffle.tokenId);

        emit NFTTransferred(raffleId, recipient);
    }

    function generateRandomNumber(uint256 raffleId, uint256 upperBound) private view returns (uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(raffleId, block.number, block.timestamp, blockhash(block.number - 1))));
        return seed.mod(upperBound);
    }

    // Utility functions

    function getRaffleCount() external view returns (uint256) {
        return raffleIdCounter;
    }

    function getUserRaffles(address user) external view returns (uint256[] memory) {
        return userRaffles[user];
    }

    function getRaffleParticipants(uint256 raffleId) external view returns (address[] memory) {
        return raffles[raffleId].participants;
    }

    function getRaffleWinner(uint256 raffleId) external view returns (address) {
        return raffles[raffleId].winner;
    }

    function isRaffleActive(uint256 raffleId) external view returns (bool) {
        return raffles[raffleId].isActive;
    }

    function getRaffleEndTime(uint256 raffleId) external view returns (uint256) {
        return raffles[raffleId].endTime;
    }

    function getServiceFeePercentage() external view returns (uint256) {
        return serviceFeePercentage;
    }

    function getSupportedTokens(address tokenAddress) external view returns (uint256) {
        return supportedTokens[tokenAddress][msg.sender];
    }
}