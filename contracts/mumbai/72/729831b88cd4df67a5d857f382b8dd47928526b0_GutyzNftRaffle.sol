/**
 *Submitted for verification at polygonscan.com on 2023-05-19
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function setApprovalForAll(address operator, bool _approved) external;

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

// File: GutyzNFT.sol


pragma solidity ^0.8.0;




contract GutyzNftRaffle is ReentrancyGuard {
    // Struct for storing raffle details
    struct Raffle {
        address owner;          // The owner of the NFT
        uint256 tokenId;        // The ID of the NFT
        uint256 ticketPrice;    // The price per ticket
        uint256 totalTickets;   // The total number of tickets
        uint256 totalSold;      // The total number of tickets sold
        uint256 endTime;        // The end time of the raffle
        address[] participants; // Array of participants
        mapping(address => uint256) tickets; // Mapping of participants to tickets purchased
    }

    // Mapping of raffle IDs to raffle details
    mapping(uint256 => Raffle) public raffles;

    // Mapping of raffle IDs to winner
    mapping(uint256 => address) public winners;

    // Mapping of raffle IDs to boolean indicating if raffle has ended
    mapping(uint256 => bool) public raffleEnded;

    // ERC20 token used for payment
    IERC20 public paymentToken;

    // Events
    event RaffleCreated(address indexed owner, uint256 indexed tokenId, uint256 ticketPrice, uint256 totalTickets, uint256 endTime);
    event RaffleParticipated(address indexed participant, uint256 indexed raffleId, uint256 tickets);
    event RaffleEnded(uint256 indexed raffleId, address indexed winner);

    constructor(address _paymentToken) {
        paymentToken = IERC20(_paymentToken);
    }

    function createRaffle(uint256 _tokenId, uint256 _ticketPrice, uint256 _totalTickets, uint256 _endTime) external {
        require(_ticketPrice > 0, "NftRaffle: ticket price must be greater than 0");
        require(_totalTickets > 0, "NftRaffle: total tickets must be greater than 0");
        require(_endTime > block.timestamp, "NftRaffle: end time must be in the future");

        // Transfer NFT to contract
        IERC721(msg.sender).transferFrom(msg.sender, address(this), _tokenId);

        // Create new raffle
        uint256 raffleId = uint256(keccak256(abi.encodePacked(msg.sender, _tokenId, block.number)));
        Raffle storage raffle = raffles[raffleId];
        raffle.owner = msg.sender;
        raffle.tokenId = _tokenId;
        raffle.ticketPrice = _ticketPrice;
        raffle.totalTickets = _totalTickets;
        raffle.endTime = _endTime;

        emit RaffleCreated(msg.sender, _tokenId, _ticketPrice, _totalTickets, _endTime);
    }

    function participateInRaffle(uint256 _raffleId, uint256 _tickets) external nonReentrant {
        require(!raffleEnded[_raffleId], "NftRaffle: raffle has ended");
        Raffle storage raffle = raffles[_raffleId];
        require(block.timestamp < raffle.endTime, "NftRaffle: raffle has ended");
        require(raffle.totalSold + _tickets <= raffle.totalTickets, "NftRaffle: not enough tickets left");
        // Check if user has enough funds
        uint256 totalCost = raffle.ticketPrice * _tickets;
        require(paymentToken.allowance(msg.sender, address(this)) >= totalCost, "NftRaffle: user has not approved enough funds");

        // Check if total tickets sold will not exceed total tickets available
        uint256 remainingTickets = raffle.totalTickets - raffle.totalSold;
        require(_tickets <= remainingTickets, "NftRaffle: not enough tickets remaining");

        // Transfer payment tokens to contract
        paymentToken.transferFrom(msg.sender, address(this), totalCost);

        // Update raffle details
        raffle.totalSold += _tickets;
        raffle.tickets[msg.sender] += _tickets;

        // Add participant to array
        if (raffle.tickets[msg.sender] == _tickets) {
            raffle.participants.push(msg.sender);
        }

        emit RaffleParticipated(msg.sender, _raffleId, _tickets);

        // Check if all tickets have been sold and end raffle if true
        if (raffle.totalSold == raffle.totalTickets) {
            endRaffle(_raffleId);
        }
    }

    function endRaffle(uint256 _raffleId) private {
        Raffle storage raffle = raffles[_raffleId];
        require(!raffleEnded[_raffleId], "NftRaffle: raffle has already ended");

        // Select winner
        uint256 winnerIndex = uint256(keccak256(abi.encodePacked(_raffleId, block.number))) % raffle.participants.length;
        address winner = raffle.participants[winnerIndex];

        // Transfer NFT to winner
        IERC721(msg.sender).transferFrom(address(this), winner, raffle.tokenId);

        // Transfer payment tokens to owner
        uint256 totalCost = raffle.ticketPrice * raffle.totalTickets;
        paymentToken.transfer(raffle.owner, totalCost);

        // Update raffle details
        winners[_raffleId] = winner;
        raffleEnded[_raffleId] = true;

        emit RaffleEnded(_raffleId, winner);
    }

    
}