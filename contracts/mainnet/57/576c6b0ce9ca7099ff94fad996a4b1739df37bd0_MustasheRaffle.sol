/**
 *Submitted for verification at polygonscan.com on 2023-07-01
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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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

// File: testing.sol


pragma solidity ^0.8.7;






abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    // YES, CONTRACT WILL HAVE NO OWNER!
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract MustasheRaffle is ERC721Holder, Ownable {
    using SafeMath for uint256;

    address public tokenAddress = 0x8865BC57c58Be23137ACE9ED1Ae1A05fE5c8B209; // $AMBER token contract address
    address public feeAddress = 0x5CEe0e6D261dA886aa4F02FB47f45E1E9fa4991b; // RuffBuff fee wallet address

    struct Raffle {
        uint256 id; // Raffle Id
        uint256 ticketPrice; // Raffle 1 ticket price ( in $AMBER )
        uint256 ticketSupply; // Raffle ticket supply
        uint256 ticketSold; // Raffle tickets sold
        uint256 endTime; // Raffle end time
        uint256 winnerTicket; // Number of winner ticket
        address creator; // Raffle Creator address
        bool ended; // Raffle ended: true / false
        address nftContract; // Nft Contract address
        uint256 nftId; // Nft Id
        uint256 maxTicketsPerAddress; // Max tickets per wallet
    }

    mapping(uint256 => Raffle) public raffles;
    mapping(uint256 => mapping(uint256 => address)) public tickets;
    mapping(uint256 => address[]) public participants;
    uint256 public raffleCount;

    uint256 private constant TOKEN_DECIMALS = 10**18;
    uint256 private constant FEE_PERCENTAGE = 2;

    event RaffleCreated(
        uint256 id,
        uint256 ticketPrice,
        uint256 ticketSupply,
        address creator,
        address nftContract,
        uint256 nftId
    );

     mapping(address => bool) public allowedNftCollections;

    event NftCollectionAllowed(address nftCollection);
    event NftCollectionBlocked(address nftCollection);

    event RaffleParticipated(uint256 id, uint256 ticketCount, address participant);

    event RaffleEnded(uint256 id, uint256 winnerTicket, address winner);

    constructor() {}

   function createRaffle(
        uint256 ticketPrice,
        uint256 ticketSupply,
        address nftContract,
        uint256 nftId,
        uint256 duration,
        uint256 maxTicketsPerAddress
    ) external {
        require(ticketPrice > 0, "Ticket price must be greater than zero");
        require(ticketSupply > 0, "Ticket supply must be greater than zero");
        require(isNftCollectionAllowed(nftContract), "NFT collection not allowed");

        uint256 endTime = block.timestamp + duration;

        raffleCount++;
        raffles[raffleCount] = Raffle(
            raffleCount,
            ticketPrice,
            ticketSupply,
            0,
            endTime,
            0,
            msg.sender,
            false,
            nftContract,
            nftId,
            maxTicketsPerAddress
        );

        IERC721 nft = IERC721(nftContract);
        nft.safeTransferFrom(msg.sender, address(this), nftId);

        emit RaffleCreated(raffleCount, ticketPrice, ticketSupply, msg.sender, nftContract, nftId);
    }

    modifier onlyAllowedNftCollections() {
            require(allowedNftCollections[msg.sender], "NFT collection not allowed");
            _;
        }

        function allowNftCollection(address nftCollection) external onlyOwner {
            allowedNftCollections[nftCollection] = true;
            emit NftCollectionAllowed(nftCollection);
        }

        function blockNftCollection(address nftCollection) external onlyOwner {
            allowedNftCollections[nftCollection] = false;
            emit NftCollectionBlocked(nftCollection);
        }

        function isNftCollectionAllowed(address nftCollection) public view returns (bool) {
            return allowedNftCollections[nftCollection];
        }

    function participateRaffle(uint256 raffleId, uint256 ticketCount) external {
        require(raffles[raffleId].id > 0, "Raffle does not exist");
        require(!raffles[raffleId].ended, "Raffle has ended");
        require(ticketCount > 0, "Ticket count must be greater than zero");
        require(
            raffles[raffleId].ticketSold.add(ticketCount) <= raffles[raffleId].ticketSupply,
            "Not enough tickets available"
        );
        require(
            getParticipantTicketCount(raffleId, msg.sender).add(ticketCount) <= raffles[raffleId].maxTicketsPerAddress,
            "Exceeded maximum tickets per address"
        );
        require(raffles[raffleId].creator != msg.sender, "Creators are not allowed to participate");

        uint256 totalPrice = raffles[raffleId].ticketPrice.mul(ticketCount).mul(TOKEN_DECIMALS);
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(msg.sender) >= totalPrice, "Insufficient token balance");
        require(token.allowance(msg.sender, address(this)) >= totalPrice, "Insufficient token allowance");

        token.transferFrom(msg.sender, address(this), totalPrice);

        for (uint256 i = 0; i < ticketCount; i++) {
            raffles[raffleId].ticketSold++;
            tickets[raffleId][raffles[raffleId].ticketSold] = msg.sender;
        }

        participants[raffleId].push(msg.sender);

        emit RaffleParticipated(raffleId, ticketCount, msg.sender);
    }

    function endRaffle(uint256 raffleId) public {
        require(raffles[raffleId].id > 0, "Raffle does not exist");
        require(!raffles[raffleId].ended, "Raffle has already ended");
        require(raffles[raffleId].ticketSold == raffles[raffleId].ticketSupply, "Raffle is not fully sold out");
        require(raffles[raffleId].creator == msg.sender, "Only the creator can end the raffle");

        raffles[raffleId].ended = true;

        uint256 winningTicket = generateRandomNumber(raffleId, raffles[raffleId].ticketSupply);
        raffles[raffleId].winnerTicket = winningTicket;

        address winner = tickets[raffleId][winningTicket];

        IERC721 nft = IERC721(raffles[raffleId].nftContract);
        nft.safeTransferFrom(address(this), winner, raffles[raffleId].nftId);

        IERC20 token = IERC20(tokenAddress);
        uint256 prizeAmount = raffles[raffleId].ticketPrice.mul(raffles[raffleId].ticketSupply).mul(TOKEN_DECIMALS);
        uint256 feeAmount = prizeAmount.mul(FEE_PERCENTAGE).div(100);
        uint256 burnAmount = prizeAmount.mul(3).div(100); // 3% BURNS FOREVER!
        uint256 creatorAmount = prizeAmount.sub(feeAmount).sub(burnAmount);

        token.transfer(raffles[raffleId].creator, creatorAmount);
        token.transfer(feeAddress, feeAmount);
        token.transfer(address(0), burnAmount);

        emit RaffleEnded(raffleId, winningTicket, winner);
    }

    function endRaffleAfterExpiry(uint256 raffleId) external {
        require(raffles[raffleId].id > 0, "Raffle does not exist");
        require(raffles[raffleId].ended == false, "Raffle has already ended");
        require(raffles[raffleId].endTime > 0 && block.timestamp > raffles[raffleId].endTime, "Raffle has not expired yet");
        require(raffles[raffleId].ticketSold < raffles[raffleId].ticketSupply, "Raffle is fully sold out");
        require(raffles[raffleId].creator == msg.sender, "Only the creator can end the raffle after expiry");

        IERC20 token = IERC20(tokenAddress);
        uint256 ticketPrice = raffles[raffleId].ticketPrice;

        for (uint256 i = 0; i < participants[raffleId].length; i++) {
            address participant = participants[raffleId][i];
            uint256 participantTicketCount = getParticipantTicketCount(raffleId, participant);
            uint256 refundAmount = participantTicketCount.mul(ticketPrice).mul(TOKEN_DECIMALS);
            // feeAmount = 0;
            // refundAmount = refundAmount.sub(feeAmount); 
            token.transfer(participant, refundAmount);
        }

        IERC721 nft = IERC721(raffles[raffleId].nftContract);
        nft.safeTransferFrom(address(this), raffles[raffleId].creator, raffles[raffleId].nftId);

        delete raffles[raffleId];
        delete participants[raffleId];

        emit RaffleEnded(raffleId, 0, address(0));
    }

    function getParticipantTicketCount(uint256 raffleId, address participant) private view returns (uint256) {
        uint256 ticketCount = 0;

        for (uint256 i = 1; i <= raffles[raffleId].ticketSold; i++) {
            if (tickets[raffleId][i] == participant) {
                ticketCount++;
            }
        }

        return ticketCount;
    }

    function generateRandomNumber(uint256 raffleId, uint256 seed) private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, seed, raffleId))) %
            raffles[raffleId].ticketSupply +
            1;
    }

    function getActiveRaffles() public view returns (Raffle[] memory) {
        uint256 activeRaffleCount = 0;

        for (uint256 i = 1; i <= raffleCount; i++) {
            if (!raffles[i].ended) {
                activeRaffleCount++;
            }
        }

        Raffle[] memory activeRaffles = new Raffle[](activeRaffleCount);
        uint256 index = 0;

        for (uint256 i = 1; i <= raffleCount; i++) {
            if (!raffles[i].ended) {
                activeRaffles[index] = raffles[i];
                index++;
            }
        }

        return activeRaffles;
    }

    function getActiveRaffleParticipants(uint256 raffleId) public view returns (address[] memory, uint256[] memory) {
        require(raffles[raffleId].id > 0, "Raffle does not exist");
        require(!raffles[raffleId].ended, "Raffle has ended");

        uint256 participantCount = participants[raffleId].length;

        address[] memory participantAddresses = new address[](participantCount);
        uint256[] memory ticketCounts = new uint256[](participantCount);

        for (uint256 i = 0; i < participantCount; i++) {
            address participant = participants[raffleId][i];
            uint256 count = getParticipantTicketCount(raffleId, participant);
            participantAddresses[i] = participant;
            ticketCounts[i] = count;
        }

        return (participantAddresses, ticketCounts);
    }

}