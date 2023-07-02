/**
 *Submitted for verification at polygonscan.com on 2023-07-01
*/

// Sources flattened with hardhat v2.16.1 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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

// File @openzeppelin/contracts/access/[email protected]

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// File @openzeppelin/contracts/utils/introspection/[email protected]

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

// File @openzeppelin/contracts/token/ERC1155/[email protected]

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/IERC1155.sol)

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
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

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
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

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
    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

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
    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

// File @openzeppelin/contracts/token/ERC721/[email protected]

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(
        uint256 tokenId
    ) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);
}

// File @openzeppelin/contracts/token/ERC20/[email protected]

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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

// File contracts/ARandomness.sol

// contracts//ARandomness.sol
pragma solidity 0.8.7;

abstract contract ARandomness {
    function _verify(
        uint256 prime,
        uint256 iterations,
        uint256 proof,
        uint256 seed
    ) internal pure returns (bool) {
        for (uint256 i = 0; i < iterations; ) {
            proof = mulmod(proof, proof, prime);
            unchecked {
                ++i;
            }
        }
        seed %= prime;
        if (seed == proof) return true;
        if (prime - seed == proof) return true;
        return false;
    }
}

// File contracts/interfaces/IRandora.sol

pragma solidity 0.8.7;

interface IRandora {
    // Events
    event NewClient(address indexed clientAddress);
    event RaffleCreated(address indexed owner, bytes32 indexed id);
    event RaffleActivated(address indexed owner, bytes32 indexed id);
    event RaffleResumed(address indexed owner, bytes32 indexed id);
    event RafflePaused(address indexed owner, bytes32 indexed id);
    event RaffleCanceled(address indexed owner, bytes32 indexed id);
    event RaffleClosed(address indexed owner, bytes32 indexed id);
    event RaffleDrawed(address indexed owner, bytes32 indexed id);
    event RaffleCompleted(address indexed owner, bytes32 indexed id);
    event NewRaffleParticipant(
        address indexed owner,
        bytes32 indexed id,
        address indexed participant
    );

    // structs
    enum RaffleStatus {
        UNDEFINED,
        PENDING_ACTIVATION,
        ACTIVE,
        PAUSED,
        PENDING_DRAW,
        PENDING_CONFIRMATION,
        COMPLETED,
        CANCELED
    }

    struct RaffleView {
        uint256 prime;
        uint256 seed;
        uint256 startTime;
        uint256 endTime;
        uint256 minReqNativeTokenBalance;
        uint256 minReqTokenBalance;
        uint256 requiredTokenId;
        uint16 iterations;
        uint16 maxParticipants;
        uint16 participantCount;
        uint8 numOfWLSpots;
        uint8 status;
        bytes32 requiredTokenName;
        bytes4 requiredTokenType;
        address requiredTokenAddress;
        string logo;
        string banner;
        string description;
        string website;
    }

    struct Raffle {
        RaffleView data;
        uint16 index;
        mapping(address => bool) participantChecks;
        mapping(address => bool) winnerChecks;
        address[] participants;
        address[] winners;
        uint16[] ids;
    }

    // RAFFLE OWNER OPERATIONS

    /// @notice Create a new Raffle or Edit the Metadata of a Raffle.
    /// @dev once the raffle activated, this method can not be called anymore
    /// @param id bytes32 encoded raffle name
    /// @param maxParticipants Maximum number of participants
    /// @param numOfWLSpots Number of Allowlist Spots
    /// @param minReqNativeTokenBalance required native token balance to participate (could be zero - means no native token required)
    /// @param logo Logo image url used in public raffle entry page
    /// @param banner Logo banner url used in public raffle entry page
    /// @param description Description shown in public raffle entry page
    /// @param website website shown in public raffle entry page
    function create(
        bytes32 id,
        uint16 maxParticipants,
        uint8 numOfWLSpots,
        uint256 minReqNativeTokenBalance,
        string calldata logo,
        string calldata banner,
        string calldata description,
        string calldata website
    ) external;

    /// @notice Edit non-critical raffle data
    /// @dev this method can be called when the raffle active or paused
    /// @param id bytes32 encoded raffle name
    /// @param minReqNativeTokenBalance required native token balance to participate (could be zero - means no native token required)
    /// @param logo Logo image url used in public raffle entry page
    /// @param banner Logo banner url used in public raffle entry page
    /// @param description Description shown in public raffle entry page
    /// @param website website shown in public raffle entry page
    function edit(
        bytes32 id,
        uint256 minReqNativeTokenBalance,
        string calldata logo,
        string calldata banner,
        string calldata description,
        string calldata website
    ) external;

    /// @notice Set token requirements of the raffle
    /// @dev token can be openzeppelin IERC20, IERC721 or IERC1155
    /// @param id bytes32 encoded raffle name
    /// @param tokenType 0x36372b07 for IERC20, 0x80ac58cd for IERC721, 0xd9b67a26 for IERC1155
    /// @param tokenAddress Token contract address
    /// @param minTokenBalance The token amount that participant should hold
    /// @param tokenName token name - not need to be match with the actual token name
    /// @param tokenId token id for IERC1155 token
    function setTokenReq(
        bytes32 id,
        bytes4 tokenType,
        address tokenAddress,
        uint256 minTokenBalance,
        bytes32 tokenName,
        uint256 tokenId
    ) external;

    /// @notice Activate raffle
    /// @dev big prime and iterations validity need to be checked before by generating proof with them
    /// @param id bytes32 encoded raffle name
    /// @param prime big prime number
    /// @param iterations number of iterations in proof calculation
    /// @param proof VDF result, which should be calculated in more than current blockchain finality time
    /// @param startTime Start datetime of the raffle
    /// @param endTime End datetime of the raffle, set 0 for no end datetime
    function activate(
        bytes32 id,
        uint256 prime,
        uint16 iterations,
        uint256 proof,
        uint256 startTime,
        uint256 endTime
    ) external;

    /// @notice Make paused raffle active again
    /// @param id bytes32 encoded raffle name
    function resume(bytes32 id) external;

    /// @notice Make active raffle paused
    /// @param id bytes32 encoded raffle name
    function pause(bytes32 id) external;

    /// @notice Close raffle
    /// @dev should be called when the raffle active or paused. if raffle has end date, this method should called after end date
    /// @param id bytes32 encoded raffle name
    function close(bytes32 id) external;

    /// @notice Cancel raffle
    /// @dev if raffle canceled, it can not be re-opened again, use it for real cancel raffle scenarios
    /// @param id bytes32 encoded raffle name
    function cancel(bytes32 id) external;

    /// @notice Draw Step 1
    /// @dev random number generated here, proof will be verified in next step
    /// @param id bytes32 encoded raffle name
    function draw(bytes32 id) external payable;

    /// @notice Draw Step 2
    /// @dev random number generated here, proof will be verified in next step
    /// @param id bytes32 encoded raffle name
    /// @param proof vdf function result
    function confirm(bytes32 id, uint256 proof) external;

    // RAFFLE PARTICIPANT OPERATIONS

    /// @notice Participant entry method
    /// @dev random number generated here, proof will be verified in next step
    /// @param ownerAddress raffle owner address
    /// @param id bytes32 encoded raffle name
    function enter(address ownerAddress, bytes32 id) external;

    // CONTRACT OWNER OPERATIONS

    /// @notice Update Draw Price
    /// @dev this price helping the security of randomness
    /// @param newDrawPrice draw operation price for the raffles
    function updateDrawPrice(uint256 newDrawPrice) external;

    /// @notice Withdraw whole balance of the contract
    function withdraw() external;

    /// @notice  terminate contract
    function terminate() external;

    // RAFFLE OWNER VIEWS

    /// @notice returns the list of the raffle id's of the caller
    /// @param ownerAddress raffle owner address
    function getRaffles(
        address ownerAddress
    ) external view returns (bytes32[] memory);

    // RAFFLE PARTICIPANT VIEWS

    /// @notice returns the raffle enter status of the participant
    /// @param ownerAddress raffle owner address
    /// @param id bytes32 encoded raffle name
    /// @param participantAddress raffle participant address
    function isEntered(
        address ownerAddress,
        bytes32 id,
        address participantAddress
    ) external view returns (bool);

    /// @notice returns the raffle result of participant
    /// @param ownerAddress raffle owner address
    /// @param id bytes32 encoded raffle name
    /// @param participantAddress raffle participant address
    function isAllowed(
        address ownerAddress,
        bytes32 id,
        address participantAddress
    ) external view returns (bool);

    // SHARED VIEWS

    function getDrawPrice() external view returns (uint256);

    /// @notice returns the specified raffle of the called
    /// @param ownerAddress raffle owner address
    /// @param id bytes32 encoded raffle name
    function getRaffle(
        address ownerAddress,
        bytes32 id
    ) external view returns (RaffleView memory);

    /// @notice returns the winner list of the raffle
    /// @param ownerAddress raffle owner address
    /// @param id bytes32 encoded raffle name
    function winners(
        address ownerAddress,
        bytes32 id
    ) external view returns (address[] memory);

    /// @notice erc20 balance of the caller
    /// @dev method is defined as external, I need to wrap it in try/catch block to get the proper error in frontend
    function getERC20Balance(
        address tokenAddress,
        address ownerAddress
    ) external view returns (uint256 result, bool success);

    /// @notice erc721 balance of the caller
    /// @dev method is defined as external, I need to wrap it in try/catch block to get the proper error in frontend
    function getERC721Balance(
        address tokenAddress,
        address ownerAddress
    ) external view returns (uint256 result, bool success);

    /// @notice erc1155 balance of the caller
    /// @dev method is defined as external, I need to wrap it in try/catch block to get the proper error in frontend
    function getERC1155Balance(
        address tokenAddress,
        uint256 tokenId,
        address ownerAddress
    ) external view returns (uint256 result, bool success);

    // PUBLIC VIEWS

    /// @notice return if the caller is owner of this contract
    function isOwner() external view returns (bool);
}

// File contracts/libraries/Randomness.sol

pragma solidity 0.8.7;

library Randomness {
    // memory struct for rand
    struct RNG {
        uint256 seed;
        uint256 nonce;
    }

    /// @dev get a random number
    function getRandom(
        RNG storage rng
    ) external returns (uint256 randomness, uint256 random) {
        return _getRandom(rng, 0, 2 ** 256 - 1, rng.seed);
    }

    /// @dev get a random number
    function getRandom(
        RNG storage rng,
        uint256 randomness
    ) external returns (uint256 randomness_, uint256 random) {
        return _getRandom(rng, randomness, 2 ** 256 - 1, rng.seed);
    }

    /// @dev get a random number passing in a custom seed
    function getRandom(
        RNG storage rng,
        uint256 randomness,
        uint256 seed
    ) external returns (uint256 randomness_, uint256 random) {
        return _getRandom(rng, randomness, 2 ** 256 - 1, seed);
    }

    /// @dev get a random number in range (0, _max)
    function getRandomRange(
        RNG storage rng,
        uint256 max
    ) external returns (uint256 randomness, uint256 random) {
        return _getRandom(rng, 0, max, rng.seed);
    }

    /// @dev get a random number in range (0, _max)
    function getRandomRange(
        RNG storage rng,
        uint256 randomness,
        uint256 max
    ) external returns (uint256 randomness_, uint256 random) {
        return _getRandom(rng, randomness, max, rng.seed);
    }

    /// @dev get a random number in range (0, _max) passing in a custom seed
    function getRandomRange(
        RNG storage rng,
        uint256 randomness,
        uint256 max,
        uint256 seed
    ) external returns (uint256 randomness_, uint256 random) {
        return _getRandom(rng, randomness, max, seed);
    }

    /// @dev fullfill a random number request for the given inputs, incrementing the nonce, and returning the random number
    function _getRandom(
        RNG storage rng,
        uint256 randomness,
        uint256 max,
        uint256 seed
    ) internal returns (uint256 randomness_, uint256 random) {
        // if the randomness is zero, we need to fill it
        if (randomness <= 0) {
            // increment the nonce in case we roll over
            unchecked {
                rng.nonce++;
            }
            randomness = uint256(
                keccak256(
                    abi.encodePacked(
                        seed,
                        rng.nonce,
                        block.timestamp,
                        msg.sender,
                        blockhash(block.number - 1)
                    )
                )
            );
        }
        // mod to the requested range
        random = randomness % max;
        // shift bits to the right to get a new random number
        randomness_ = randomness >>= 4;
    }
}

// File contracts/Randora.sol

// SPDX-License-Identifier: MIT
// contracts//Randora.sol
pragma solidity 0.8.7;

/// @title Randora
/// @author darthitect
/// @notice With this contract, you can organize a allowlist raffle for your NFT projects
/// @dev almost secure, on-chain randomness is used in this contract to distribute allowlist spots to participants
contract Randora is Ownable, ARandomness, IRandora {
    using Randomness for Randomness.RNG;
    Randomness.RNG internal rng;
    mapping(address => bytes32[]) private raffleIds;
    mapping(address => mapping(bytes32 => Raffle)) private raffles;
    address[] private clients;
    uint256 private draw_price = 0 ether;

    // ctor
    constructor(uint256 newDrawPrice) {
        draw_price = newDrawPrice;
    }

    // External Functions

    /// @notice standart receive function
    receive() external payable {
        (bool success, ) = payable(owner()).call{value: msg.value}("");
        require(success);
    }

    /// @notice standart fallback function
    fallback() external payable {
        (bool success, ) = payable(owner()).call{value: msg.value}("");
        require(success);
    }

    // Raffle Owner Operations

    /// @notice Create a new Raffle or Edit the Metadata of a Raffle.
    /// @dev once the raffle activated, this method can not be called anymore
    /// @param id bytes32 encoded raffle name
    /// @param maxParticipants Maximum number of participants
    /// @param numOfWLSpots Number of Allowlist Spots
    /// @param minReqNativeTokenBalance required native token balance to participate (could be zero - means no native token required)
    /// @param logo Logo image url used in public raffle entry page
    /// @param banner Logo banner url used in public raffle entry page
    /// @param description Description shown in public raffle entry page
    /// @param website website shown in public raffle entry page
    function create(
        bytes32 id,
        uint16 maxParticipants,
        uint8 numOfWLSpots,
        uint256 minReqNativeTokenBalance,
        string calldata logo,
        string calldata banner,
        string calldata description,
        string calldata website
    ) external override {
        require(id != "", "empty id");
        require(numOfWLSpots > 0, "invalid numOfWLSpots");
        require(maxParticipants >= numOfWLSpots, "invalid maxParticipants");
        uint256 clientRaffleCount = raffleIds[msg.sender].length;
        require(clientRaffleCount < 10, "max raffle count reached");
        RaffleView storage raffle = raffles[msg.sender][id].data;
        require(
            raffle.status == uint8(RaffleStatus.UNDEFINED) ||
                raffle.status == uint8(RaffleStatus.PENDING_ACTIVATION),
            "already created"
        );
        if (raffle.status == uint8(RaffleStatus.UNDEFINED)) {
            if (clientRaffleCount == 0) {
                clients.push(msg.sender);
                emit NewClient(msg.sender);
            }
            raffleIds[msg.sender].push(id);
            emit RaffleCreated(msg.sender, id);
        }
        raffle.logo = logo;
        raffle.banner = banner;
        raffle.description = description;
        raffle.website = website;
        raffle.maxParticipants = maxParticipants;
        raffle.numOfWLSpots = numOfWLSpots;
        raffle.minReqNativeTokenBalance = minReqNativeTokenBalance;
        raffle.status = uint8(RaffleStatus.PENDING_ACTIVATION);
        (, raffle.seed) = rng.getRandom();
        if (raffle.seed == 1) {
            raffle.seed = 2;
        }
    }

    /// @notice Edit non-critical raffle data
    /// @dev this method can be called when the raffle active or paused
    /// @param id bytes32 encoded raffle name
    /// @param minReqNativeTokenBalance required native token balance to participate (could be zero - means no native token required)
    /// @param logo Logo image url used in public raffle entry page
    /// @param banner Logo banner url used in public raffle entry page
    /// @param description Description shown in public raffle entry page
    /// @param website website shown in public raffle entry page
    function edit(
        bytes32 id,
        uint256 minReqNativeTokenBalance,
        string calldata logo,
        string calldata banner,
        string calldata description,
        string calldata website
    ) external override {
        RaffleView storage raffle = raffles[msg.sender][id].data;
        require(
            raffle.status == uint8(RaffleStatus.ACTIVE) ||
                raffle.status == uint8(RaffleStatus.PAUSED),
            "incorrect state"
        );
        raffle.logo = logo;
        raffle.banner = banner;
        raffle.description = description;
        raffle.website = website;
        raffle.minReqNativeTokenBalance = minReqNativeTokenBalance;
    }

    /// @notice Set token requirements of the raffle
    /// @dev token can be openzeppelin IERC20, IERC721 or IERC1155
    /// @param id bytes32 encoded raffle name
    /// @param tokenType 0x36372b07 for IERC20, 0x80ac58cd for IERC721, 0xd9b67a26 for IERC1155
    /// @param tokenAddress Token contract address
    /// @param minTokenBalance The token amount that participant should hold
    /// @param tokenName token name - not need to be match with the actual token name
    /// @param tokenId token id for IERC1155 token
    function setTokenReq(
        bytes32 id,
        bytes4 tokenType,
        address tokenAddress,
        uint256 minTokenBalance,
        bytes32 tokenName,
        uint256 tokenId
    ) external override {
        RaffleView storage raffle = raffles[msg.sender][id].data;
        require(
            raffle.status == uint8(RaffleStatus.PENDING_ACTIVATION) ||
                raffle.status == uint8(RaffleStatus.ACTIVE) ||
                raffle.status == uint8(RaffleStatus.PAUSED),
            "incorrect state"
        );

        if (minTokenBalance == 0) {
            delete raffle.requiredTokenType;
            delete raffle.requiredTokenAddress;
            delete raffle.minReqTokenBalance;
            delete raffle.requiredTokenName;
            delete raffle.requiredTokenId;
        } else {
            (, bool success, string memory errorMessage) = _getTokenBalance(
                tokenType,
                tokenAddress,
                tokenId,
                msg.sender
            );
            require(success, errorMessage);
            raffle.requiredTokenAddress = tokenAddress;
            raffle.requiredTokenType = tokenType;
            raffle.minReqTokenBalance = minTokenBalance;
            raffle.requiredTokenId = tokenId;
            raffle.requiredTokenName = tokenName;
        }
    }

    /// @notice Activate raffle
    /// @dev big prime and iterations validity need to be checked before by generating proof with them
    /// @param id bytes32 encoded raffle name
    /// @param prime big prime number
    /// @param iterations number of iterations in proof calculation
    /// @param proof VDF result, which should be calculated in more than current blockchain finality time
    /// @param startTime Start datetime of the raffle
    /// @param endTime End datetime of the raffle, set 0 for no end datetime
    function activate(
        bytes32 id,
        uint256 prime,
        uint16 iterations,
        uint256 proof,
        uint256 startTime,
        uint256 endTime
    ) external override {
        require(prime > 2 ** 128, "invalid prime");
        require(iterations > 2 ** 13, "invalid iterations");
        require(proof > 1, "proof should be gt 1");
        require(startTime > block.timestamp, "invalid startTime");
        if (endTime > 0) {
            require(endTime > startTime + 10 minutes, "invalid endTime");
        }
        RaffleView storage raffle = raffles[msg.sender][id].data;
        require(
            raffle.status == uint8(RaffleStatus.PENDING_ACTIVATION),
            "incorrect state"
        );
        require(raffle.seed > 1, "invalid seed");
        // test if prime and iterations works correctly (prime and iterations will be used later for draw op)
        require(
            _verify(prime, iterations, proof, raffle.seed),
            "invalid proof"
        );
        raffle.prime = prime;
        raffle.iterations = iterations;
        raffle.startTime = startTime;
        raffle.endTime = endTime;
        raffle.status = uint8(RaffleStatus.ACTIVE);
        emit RaffleActivated(msg.sender, id);
    }

    /// @notice Make paused raffle active again
    /// @param id bytes32 encoded raffle name
    function resume(bytes32 id) external override {
        RaffleView storage raffle = raffles[msg.sender][id].data;
        require(raffle.status == uint8(RaffleStatus.PAUSED), "incorrect state");
        raffle.status = uint8(RaffleStatus.ACTIVE);
        emit RaffleResumed(msg.sender, id);
    }

    /// @notice Make active raffle paused
    /// @param id bytes32 encoded raffle name
    function pause(bytes32 id) external override {
        RaffleView storage raffle = raffles[msg.sender][id].data;
        require(raffle.status == uint8(RaffleStatus.ACTIVE), "incorrect state");
        if (raffle.endTime > 0) {
            require(block.timestamp < raffle.endTime, "already expired");
        }
        raffle.status = uint8(RaffleStatus.PAUSED);
        emit RafflePaused(msg.sender, id);
    }

    /// @notice Close raffle
    /// @dev should be called when the raffle active or paused. if raffle has end date, this method should called after end date
    /// @param id bytes32 encoded raffle name
    function close(bytes32 id) external override {
        Raffle storage raffle = raffles[msg.sender][id];
        require(
            raffle.data.status == uint8(RaffleStatus.ACTIVE) ||
                raffle.data.status == uint8(RaffleStatus.PAUSED),
            "incorrect state"
        );
        if (raffle.data.endTime > 0) {
            require(block.timestamp > raffle.data.endTime, "not expired yet");
        }
        if (raffle.participants.length > 0) {
            raffle.data.status = uint8(RaffleStatus.PENDING_DRAW);
        } else {
            raffle.data.status = uint8(RaffleStatus.COMPLETED);
        }
        emit RaffleClosed(msg.sender, id);
    }

    /// @notice Cancel raffle
    /// @dev if raffle canceled, it can not be re-opened again, use it for real cancel raffle scenarios
    /// @param id bytes32 encoded raffle name
    function cancel(bytes32 id) external override {
        uint8 _status = raffles[msg.sender][id].data.status;
        require(
            _status != uint8(RaffleStatus.UNDEFINED) &&
                _status != uint8(RaffleStatus.CANCELED) &&
                _status != uint8(RaffleStatus.COMPLETED),
            "incorrect state"
        );
        raffles[msg.sender][id].data.status = uint8(RaffleStatus.CANCELED);
        emit RaffleCanceled(msg.sender, id);
    }

    /// @notice Draw Step 1
    /// @dev random number generated here, proof will be verified in next step
    /// @param id bytes32 encoded raffle name
    function draw(bytes32 id) external payable override {
        require(msg.value == draw_price, "invalid payment");
        Raffle storage raffle = raffles[msg.sender][id];
        require(
            raffle.data.status == uint8(RaffleStatus.PENDING_DRAW),
            "incorrect state"
        );

        // distribute directly
        // if there are not enough participants
        if (raffle.participants.length <= raffle.data.numOfWLSpots) {
            raffle.winners = raffle.participants;
            for (uint256 i = 0; i < raffle.winners.length; i++) {
                raffle.winnerChecks[raffle.winners[i]] = true;
            }
            raffle.data.status = uint8(RaffleStatus.COMPLETED);
            emit RaffleCompleted(msg.sender, id);
        } else {
            // otherwise generate random seed for the next step
            (, raffle.data.seed) = rng.getRandom();
            raffle.data.status = uint8(RaffleStatus.PENDING_CONFIRMATION);
            emit RaffleDrawed(msg.sender, id);
        }
    }

    /// @notice Draw Step 2
    /// @dev random number generated here, proof will be verified in next step
    /// @param id bytes32 encoded raffle name
    /// @param proof vdf function result
    function confirm(bytes32 id, uint256 proof) external override {
        require(proof > 1, "proof should be gt 1");
        Raffle storage raffle = raffles[msg.sender][id];
        require(
            raffle.data.status == uint8(RaffleStatus.PENDING_CONFIRMATION),
            "incorrect state"
        );
        require(raffle.data.seed > 1, "invalid seed");
        require(
            _verify(
                raffle.data.prime,
                raffle.data.iterations,
                proof,
                raffle.data.seed
            ),
            "invalid proof"
        );

        // distribute wl's here
        uint256 _randomness = proof;
        uint256 _random;
        uint256 _numOfParticipants = raffle.participants.length;
        uint8 _numOfSlots = raffle.data.numOfWLSpots;
        raffle.ids = new uint16[](_numOfSlots);
        raffle.index = 0;
        address[] memory _winners = new address[](_numOfSlots);
        for (uint8 i = 0; i < _numOfSlots; ) {
            (_randomness, _random) = rng.getRandomRange(
                _randomness,
                _numOfParticipants,
                raffle.data.seed
            );
            uint256 _nextId = _pickRandomUniqueId(raffle, _random, _numOfSlots);
            _winners[i] = raffle.participants[_nextId];
            raffle.winnerChecks[raffle.participants[_nextId]] = true;
            unchecked {
                ++i;
            }
        }
        raffle.winners = _winners;
        raffle.data.status = uint8(RaffleStatus.COMPLETED);
        emit RaffleCompleted(msg.sender, id);
    }

    /// @notice Participant entry method
    /// @dev random number generated here, proof will be verified in next step
    /// @param ownerAddress raffle owner address
    /// @param id bytes32 encoded raffle name
    function enter(address ownerAddress, bytes32 id) external override {
        Raffle storage raffle = raffles[ownerAddress][id];
        require(
            raffle.data.status == uint8(RaffleStatus.ACTIVE),
            "raffle is not active"
        );
        require(raffle.data.startTime < block.timestamp, "not started yet");
        if (raffle.data.endTime > 0) {
            require(raffle.data.endTime > block.timestamp, "expired");
        }
        require(
            raffle.participants.length < raffle.data.maxParticipants,
            "max candidates reached"
        );
        require(
            payable(msg.sender).balance >= raffle.data.minReqNativeTokenBalance,
            "insufficient balance"
        );

        if (raffle.data.minReqTokenBalance > 0) {
            (
                uint256 balance,
                bool success,
                string memory errorMessage
            ) = _getTokenBalance(
                    raffle.data.requiredTokenType,
                    raffle.data.requiredTokenAddress,
                    raffle.data.requiredTokenId,
                    msg.sender
                );
            require(success, errorMessage);
            if (raffle.data.requiredTokenType == type(IERC20).interfaceId) {
                require(
                    balance >= raffle.data.minReqTokenBalance,
                    "insufficient ERC20"
                );
            } else if (
                raffle.data.requiredTokenType == type(IERC721).interfaceId
            ) {
                require(
                    balance >= raffle.data.minReqTokenBalance,
                    "insufficient ERC721"
                );
            } else if (
                raffle.data.requiredTokenType == type(IERC1155).interfaceId
            ) {
                require(
                    balance >= raffle.data.minReqTokenBalance,
                    "insufficient ERC1155"
                );
            } else {
                revert("unsupported token type");
            }
        }

        // re-entrancy check
        require(!raffle.participantChecks[msg.sender], "already entered");
        raffle.participantChecks[msg.sender] = true;
        raffle.participants.push(msg.sender);
        if (raffle.data.maxParticipants == raffle.participants.length) {
            raffle.data.status = uint8(RaffleStatus.PENDING_DRAW);
        }
        emit NewRaffleParticipant(ownerAddress, id, msg.sender);
    }

    // Contract Owner Operations

    /// @notice Update Draw Price
    /// @dev this price helping the security of randomness
    /// @param newDrawPrice draw operation price for the raffles
    function updateDrawPrice(uint256 newDrawPrice) external override onlyOwner {
        draw_price = newDrawPrice;
    }

    /// @notice Withdraw whole balance of the contract
    function withdraw() external override onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success);
    }

    /// @notice  terminate contract
    function terminate() external override onlyOwner {
        selfdestruct(payable(owner()));
    }

    // Views

    // Raffle Owner Views

    /// @notice  returns the list of the raffle id's of the caller
    /// @param ownerAddress raffle owner address
    function getRaffles(
        address ownerAddress
    ) external view override returns (bytes32[] memory) {
        return raffleIds[ownerAddress];
    }

    // Raffle Participant Views

    /// @notice  returns the raffle enter status of the participant
    /// @param ownerAddress raffle owner address
    /// @param id bytes32 encoded raffle name
    /// @param participantAddress raffle participant address
    function isEntered(
        address ownerAddress,
        bytes32 id,
        address participantAddress
    ) external view override returns (bool) {
        Raffle storage raffle = raffles[ownerAddress][id];
        return raffle.participantChecks[participantAddress];
    }

    /// @notice  returns the raffle result of participant
    /// @param ownerAddress raffle owner address
    /// @param id bytes32 encoded raffle name
    /// @param participantAddress raffle participant address
    function isAllowed(
        address ownerAddress,
        bytes32 id,
        address participantAddress
    ) external view override returns (bool) {
        Raffle storage raffle = raffles[ownerAddress][id];
        require(
            raffle.data.status == uint8(RaffleStatus.COMPLETED),
            "raffle not completed"
        );
        return raffle.winnerChecks[participantAddress];
    }

    // Shared Views

    /// @notice  returns the draw price of raffles
    function getDrawPrice() external view override returns (uint256) {
        return draw_price;
    }

    /// @notice  returns the specified raffle of the called
    /// @param ownerAddress raffle owner address
    /// @param id bytes32 encoded raffle name
    function getRaffle(
        address ownerAddress,
        bytes32 id
    ) external view override returns (RaffleView memory) {
        Raffle storage raffle = raffles[ownerAddress][id];
        RaffleView memory _raffleView = RaffleView({
            prime: raffle.data.prime,
            seed: raffle.data.seed,
            startTime: raffle.data.startTime,
            endTime: raffle.data.endTime,
            minReqNativeTokenBalance: raffle.data.minReqNativeTokenBalance,
            minReqTokenBalance: raffle.data.minReqTokenBalance,
            iterations: raffle.data.iterations,
            maxParticipants: raffle.data.maxParticipants,
            participantCount: uint16(raffle.participants.length),
            numOfWLSpots: raffle.data.numOfWLSpots,
            status: raffle.data.status,
            requiredTokenAddress: raffle.data.requiredTokenAddress,
            requiredTokenType: raffle.data.requiredTokenType,
            requiredTokenName: raffle.data.requiredTokenName,
            requiredTokenId: raffle.data.requiredTokenId,
            logo: raffle.data.logo,
            banner: raffle.data.banner,
            description: raffle.data.description,
            website: raffle.data.website
        });
        return _raffleView;
    }

    /// @notice  returns the winner list of the raffle
    /// @param ownerAddress raffle owner address
    /// @param id bytes32 encoded raffle name
    function winners(
        address ownerAddress,
        bytes32 id
    ) external view override returns (address[] memory) {
        Raffle storage raffle = raffles[ownerAddress][id];
        require(
            raffle.data.status == uint8(RaffleStatus.COMPLETED),
            "not completed"
        );
        return raffle.winners;
    }

    /// @notice erc20 balance of the caller
    /// @dev method is defined as external, I need to wrap it in try/catch block to get the proper error in frontend
    function getERC20Balance(
        address tokenAddress,
        address ownerAddress
    ) external view override returns (uint256 result, bool success) {
        IERC20 tokenContract = IERC20(tokenAddress);
        try tokenContract.balanceOf(ownerAddress) returns (uint256 balance) {
            return (balance, true);
        } catch {
            return (0, false);
        }
    }

    /// @notice erc721 balance of the caller
    /// @dev method is defined as external, I need to wrap it in try/catch block to get the proper error in frontend
    function getERC721Balance(
        address tokenAddress,
        address ownerAddress
    ) external view override returns (uint256 result, bool success) {
        IERC721 tokenContract = IERC721(tokenAddress);
        try tokenContract.balanceOf(ownerAddress) returns (uint256 balance) {
            return (balance, true);
        } catch {
            return (0, false);
        }
    }

    /// @notice erc1155 balance of the caller
    /// @dev method is defined as external, I need to wrap it in try/catch block to get the proper error in frontend
    function getERC1155Balance(
        address tokenAddress,
        uint256 tokenId,
        address ownerAddress
    ) external view override returns (uint256 result, bool success) {
        IERC1155 tokenContract = IERC1155(tokenAddress);
        try tokenContract.balanceOf(ownerAddress, tokenId) returns (
            uint256 balance
        ) {
            return (balance, true);
        } catch {
            return (0, false);
        }
    }

    // Public functions

    // public views

    /// @notice return if the caller is owner of this contract
    function isOwner() public view override returns (bool) {
        return owner() == _msgSender();
    }

    // Private functions

    /// @notice returns the token balance of the called
    /// @dev this method is public for only wrapping it in try/catch block to get proper error in frontend
    /// @param tokenType 0x36372b07 for IERC20, 0x80ac58cd for IERC721, 0xd9b67a26 for IERC1155
    /// @param tokenAddress Token contract address
    /// @param tokenId token id for IERC1155 token
    function _getTokenBalance(
        bytes4 tokenType,
        address tokenAddress,
        uint256 tokenId,
        address ownerAddress
    )
        private
        view
        returns (uint256 result, bool success, string memory errorMessage)
    {
        if (tokenAddress != address(0x0) && tokenAddress.code.length > 0) {
            if (tokenType == type(IERC20).interfaceId) {
                try this.getERC20Balance(tokenAddress, ownerAddress) returns (
                    uint256 _result,
                    bool _success
                ) {
                    return (_result, _success, "ERC20 balance failed");
                } catch {
                    return (0, false, "ERC20 balance failed");
                }
            } else if (tokenType == type(IERC721).interfaceId) {
                try this.getERC721Balance(tokenAddress, ownerAddress) returns (
                    uint256 _result,
                    bool _success
                ) {
                    return (_result, _success, "ERC721 balance failed");
                } catch {
                    return (0, false, "ERC721 balance failed");
                }
            } else if (tokenType == type(IERC1155).interfaceId) {
                try
                    this.getERC1155Balance(tokenAddress, tokenId, ownerAddress)
                returns (uint256 _result, bool _success) {
                    return (_result, _success, "ERC1155 balance failed");
                } catch {
                    return (0, false, "ERC1155 balance failed");
                }
            } else {
                return (0, false, "unsupported token type");
            }
        } else {
            return (0, false, "invalid token address");
        }
    }

    /// @dev non-repeating random selection from range
    function _pickRandomUniqueId(
        Raffle storage raffle,
        uint256 _random,
        uint256 _numberOfSlots
    ) private returns (uint256 id) {
        uint256 len = _numberOfSlots - raffle.index++;
        require(len > 0, "no ids left");
        uint256 randomIndex = uint256(_random % len);
        id = raffle.ids[randomIndex] != 0
            ? raffle.ids[randomIndex]
            : randomIndex;
        raffle.ids[randomIndex] = uint16(
            raffle.ids[len - 1] == 0 ? len - 1 : raffle.ids[len - 1]
        );
        raffle.ids[len - 1] = 0;
    }
}