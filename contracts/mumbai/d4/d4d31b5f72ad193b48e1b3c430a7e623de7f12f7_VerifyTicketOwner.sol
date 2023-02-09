// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
pragma solidity ^0.8.17;

import "./interfaces/INFTicket.sol";
/* Signature Verification

How to Sign and Verify
# Signing
1. Create message to sign
2. Hash the message
3. Sign the hash (off chain, keep your private key secret)

# Verify
1. Recreate hash from the original message
2. Recover signer from signature and hash
3. Compare recovered signer to claimed signer*/

contract VerifyTicketOwner {
    address immutable nfticket;

    constructor(address nfticket_) {
        nfticket = nfticket_;
    }

    /* 1. Unlock MetaMask account
    ethereum.enable()
    */

    /* 2. Get message hash to sign
    getMessageHash(
        1234
    )

    hash = "0xcf36ac4f97dc10d91fc2cbb20d718e94a8cbfe0f82eaedc6a4aa38946fb797cd"
    */
    function getMessageHash(uint256 ticketId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(ticketId));
    }

    /* 3. Sign message hash
    # using browser
    account = "copy paste account of signer here"
    ethereum.request({ method: "personal_sign", params: [account, hash]}).then(console.log)

    # using web3
    web3.personal.sign(hash, web3.eth.defaultAccount, console.log)

    Signature will be different for different accounts
    0x993dab3dd91f5c6dc28e17439be475478f5635c92a56e17e82349d3fb2f166196f466c0b4e0c146f285204f0dcb13e5ae67bc33f4b888ec32dfe0a063e8f3f781b
    */
    function getEthSignedMessageHash(bytes32 messageHash) public pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
    }

    /* 4. Verify signature
    signer = 0xB273216C05A8c0D4F0a4Dd0d7Bae1D2EfFE636dd
    ticketId = 1234
    signature =
        0x993dab3dd91f5c6dc28e17439be475478f5635c92a56e17e82349d3fb2f166196f466c0b4e0c146f285204f0dcb13e5ae67bc33f4b888ec32dfe0a063e8f3f781b
    */
    function verify(address signer, uint256 ticketId, bytes memory signature) public view returns (bool) {
        bytes32 messageHash = getMessageHash(ticketId);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return
            recoverSigner(ethSignedMessageHash, signature) == signer && INFTicket(nfticket).ownerOf(ticketId) == signer;
    }

    function recoverSigner(bytes32 ethSignedMessageHash, bytes memory signature) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);

        return ecrecover(ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface INFTicket is IERC721 {
    struct EventData {
        bytes32 merkleTreeRoot;
        address organiser;
        uint96 royaltyFee;
        uint256 ticketSellStartTime;
        uint256 ticketSellEndTime;
        uint256 maxTicketNumberPerAccount;
        address tokenAddress;
        bool blockTicketSellFlag;
        bool allowToSetTicketSoldFlag;
        uint96 protocolSellTicketFee;
        uint96 protocolResellTicketFee;
    }

    struct TicketPriceData {
        uint256 price;
        bool isFree;
    }

    struct TokenData {
        bool exist;
        bool isActive;
    }

    struct TicketSellTimeRange {
        uint256 startTime;
        uint256 endTime;
    }

    struct TicketPair {
        uint256 ticketId;
        bytes32[] ticketProof;
    }

    /// @dev Error thrown when organasirAccessControl contract is zero address
    error OrganiserAccessControlIsZeroAddress();

    /// @dev Error thrown when only admin allowed to execute the transaction
    error OnlyAdminAllowed();

    /// @dev Error thrown when only admin or SET_TICKET_FLAG_ROLE role allowed to execute the transaction
    error OnlyAdminOrSetTicketFlagAllowed();

    /// @dev Error thrown when organiser is not in approved status
    error OrganiserNotInApprovedStatus();

    /// @dev Error thrown when event with already exist
    error EventAlreadyExist();

    /// @dev Error thrown when event is not exist
    error EventIsNotExist();

    /// @dev Error thrown when token already added
    error TokenAlreadyExist();

    /// @dev Error thrown when token does not exist
    error TokenDoesNotExist();

    /// @dev Error thrown when event organiser is not msg.sender
    error MsgSenderIsNotEventOrganiser();

    /// @dev Error thrown when ticket sell is already started
    error TicketSellAlreadyStarted();

    /// @dev Error thrown when ticket sell start is not in future
    error TicketSellStartMustBeInFuture();

    /// @dev Error thrown when ticket sell start is after ticket sell end
    error TicketSellStartIsAfterTicketSellEnd();

    /// @dev Error thrown when maximum ticket number per account is 0
    error MaxTicketNumberPerAccountIsZero();

    /// @dev Error thrown when token is not active
    error TokenIsNotActive();

    /// @dev Error thrown when organiser ID is not correct
    error OrganiserIdIsNotCorrect();

    /// @dev Error thrown when setup price arrays are not same length
    error SetupPriceArraysAreNotSameLength();

    /// @dev Error thrown when mint arrays are not same length
    error MintArraysAreNotSameLength();

    /// @dev Error thrown when only event organiser has allowed to run transaction
    error OnlyEventOrganiserAllowed();

    /// @dev Error thrown when ticket with this ticketId and proof does not exist in event
    error TicketDoesNotExist();

    /// @dev Error thrown when ticket is set as sold
    error TicketIsSetAsSold();

    /// @dev Error thrown when ticket sell is not yet start
    error TicketSellIsNotStart();

    /// @dev Error thrown when ticket sell is finished
    error TicketSellIsFinished();

    /// @dev Error thrown when ticket sell is blocked
    error TicketSellIsBlocked();

    /// @dev Error thrown when ticket price is not set
    error TicketPriceIsNotSet();

    /// @dev Error thrown when account reach maximum number of tickets for an event
    error AccountReachMaxNumberOfTickets();

    /// @dev Error thrown when ticket already minted (sold)
    error TicketAlreadyMinted();

    /// @dev Error thrown when set ticket sold flag not allowed
    error SetTicketSoldFlagNotAllowed();

    /// @dev Error thrown when there is no enough requested amount in this token
    error NoEnoughRequestedAmountForThisToken();

    /// @dev Error thrown because there is more than 8 levels
    error MoreThanEightLevels();

    /// @dev Error thrown when fee is greater than allowed maximum which is 50%
    error FeeIsGreaterThanAllowedMaximum();

    event SetProtocolFees(uint96 protocolSellTicketFee, uint96 protocolResellTicketFee);

    event AddToken(address indexed tokenAddress);

    event ChangeTokenActiveStatus(address indexed tokenAddress, bool isActive);

    event CreateEvent(
        uint64 indexed eventId,
        uint96 royaltyFee,
        bytes32 merkleTreeRoot,
        uint256 ticketSellStartTime,
        uint256 ticketSellEndTime,
        uint256 maxTicketNumberPerAccount,
        address tokenAddress,
        bool allowToSetTicketSoldFlag,
        uint96 protocolSellTicketFee,
        uint96 protocolResellTicketFee
    );

    event UpdateEvent(
        uint64 indexed eventId,
        uint96 royaltyFee,
        bytes32 merkleTreeRoot,
        uint256 ticketSellStartTime,
        uint256 ticketSellEndTime,
        uint256 maxTicketNumberPerAccount,
        address tokenAddress,
        bool allowToSetTicketSoldFlag
    );

    event UpdateRoyalty(uint64 indexed eventId, uint96 royaltyFee);

    event UpdateMerkleTreeRoot(uint64 indexed eventId, bytes32 merkleTreeRoot);

    event UpdateTicketSellTimes(uint64 indexed eventId, uint256 ticketSellStartTime, uint256 ticketSellEndTime);

    event UpdateMaxTicketNumberPerAccount(uint64 indexed eventId, uint256 maxTicketNumberPerAccount);

    event UpdateTokenAddress(uint64 indexed eventId, address tokenAddress);

    event SetBlockTicketSellFlagOnEvent(uint64 indexed eventId, bool blockTicketSellFlag);

    event SetTicketSoldFlag(uint256 indexed ticketId, bool ticketSoldFlag);

    event SetupTicketPrice(uint256 indexed ticketLevel, uint256 price);

    event Mint(address indexed to, uint256 indexed ticketId);

    event Withdraw(address indexed to, address tokenAddress, uint256 amount);

    event WithdrawProtocolSellFee(address indexed to, address tokenAddress, uint256 amount);

    /// @dev Get event data for a specific event ID
    /// @param eventId Event ID for which is event data requested
    function events(uint64 eventId)
        external
        view
        returns (bytes32, address, uint96, uint256, uint256, uint256, address, bool, bool, uint96, uint96);

    /// @dev Get address for organiser access control contract
    function organiserAccessControl() external view returns (address);

    /// @dev Get ticket levels price for a specific @param ticketLevel
    /// @param ticketLevel Ticket level for which is ticket price requested
    function ticketLevelsPrice(uint256 ticketLevel) external view returns (uint256, bool);

    /// @dev Get information about the token (token is set per event and in that token ticket could be bought/sold/resell)
    /// @param tokenAddress Address of an ERC20 token for which is getting base information
    function tokens(address tokenAddress) external view returns (bool, bool);

    /// @dev Get organiser balance per token
    /// @param organiser Organiser address
    /// @param tokenAddress Address of an ERC20 token in which gets paid
    function organisersBalance(address organiser, address tokenAddress) external view returns (uint256);

    /// @dev Get information if a ticket with @param ticketId sold on some other platform or not
    /// @param ticketId TicketID which is checked
    function soldTickets(uint256 ticketId) external view returns (bool);

    /// @dev Get number of tickets per user per event
    /// @param eventId Event ID for which is geting information about number of tickets for user
    /// @param account An account address for which is geting information about number of tickets
    function numberOfTicketsPerUserPerEvent(uint64 eventId, address account) external view returns (uint256);

    /// @dev Fee in the percent that protocol will get for every ticket sell directly from organiser(mint ticket)
    function protocolSellTicketFee() external view returns (uint96);

    /// @dev Fee in the percent that protocol will get for every ticket resell through NFTicketMarket
    function protocolResellTicketFee() external view returns (uint96);

    /// @dev The total fee of protocol amount for sell fees
    function protocolSellFeeAmount() external view returns (uint256);

    /// @dev Set fees in percent that protocol will get
    /// @param sellTicketFee Fee in the percent that protocol will get for every ticket sell directly from organiser(mint ticket)
    /// @param resellTicketFee Fee in the percent that protocol will get for every ticket resell through NFTicketMarket
    function setProtocolFees(uint96 sellTicketFee, uint96 resellTicketFee) external;

    /// @dev Add ERC20 token in a mapping
    /// @param tokenAddress Address of an ERC20 token which is adding in a mapping
    function addToken(address tokenAddress) external;

    /// @dev Change ERC20 token active status
    /// @param tokenAddress Address of an ERC20 token for which is changing active status
    /// @param isActive New active status
    function changeTokenActiveStatus(address tokenAddress, bool isActive) external;

    /// @dev Create event with a specific parameters
    /// @param eventId Event ID for which is creating an event
    /// @param royaltyFee Royalty fraction that will get organiser for every ticket resell for this event
    /// @param merkleTreeRoot The Merkle tree root hash value which is generated for a tree with all tickets
    /// @param ticketSellTimeRange.startTime Timestamp which tells when is allowed to start ticket sell
    /// @param ticketSellTimeRange.endTime Timestamp which tells when is finished ticket sell
    /// @param maxTicketNumberPerAccount Maximum number of tickets that one account could buy
    /// @param tokenAddress Address of an ERC20 token in which event tickets will be bought/sold/resell
    /// @param allowToSetTicketSoldFlag The event owner allows/does not allow to contract owner to set a ticket as sold
    /// @param randomTicketForCheck Random ticket with ticket ID and proof for that ticket ID
    ///         which is using for check @param eventId and @param merkleTreeRoot validity
    function createEvent(
        uint64 eventId,
        uint96 royaltyFee,
        bytes32 merkleTreeRoot,
        TicketSellTimeRange calldata ticketSellTimeRange,
        uint256 maxTicketNumberPerAccount,
        address tokenAddress,
        bool allowToSetTicketSoldFlag,
        TicketPair calldata randomTicketForCheck
    ) external;

    /// @dev Update event with a specific parameters
    /// @param eventId Event ID for which is updating an event
    /// @param royaltyFee Royalty fraction that will get organiser for every ticket resell for this event
    /// @param merkleTreeRoot The Merkle tree root hash value which is generated for a tree with all tickets
    /// @param ticketSellTimeRange.startTime Timestamp which tells when is allowed to start ticket sell
    /// @param ticketSellTimeRange.endTime Timestamp which tells when is finished ticket sell
    /// @param maxTicketNumberPerAccount Maximum number of tickets that one account could buy
    /// @param tokenAddress Address of an ERC20 token in which event tickets will be bought/sold/resell
    /// @param allowToSetTicketSoldFlag The event owner allows/does not allow to contract owner to set a ticket as sold
    /// @param randomTicketForCheck Random ticket with ticket ID and proof for that ticket ID
    ///         which is using for check @param eventId and @param merkleTreeRoot validity
    function updateEvent(
        uint64 eventId,
        uint96 royaltyFee,
        bytes32 merkleTreeRoot,
        TicketSellTimeRange calldata ticketSellTimeRange,
        uint256 maxTicketNumberPerAccount,
        address tokenAddress,
        bool allowToSetTicketSoldFlag,
        TicketPair calldata randomTicketForCheck
    ) external;

    /// @dev Update royalty for a @param eventId
    /// @param eventId Event ID for which will be @param royaltyFee updated
    /// @param royaltyFee Royalty fraction that will get organiser for every ticket resell for this event
    function updateRoyalty(uint64 eventId, uint96 royaltyFee) external;

    /// @dev Update merkle tree root for a @param eventId
    /// @param eventId Event ID for which will be @param merkleTreeRoot updated
    /// @param merkleTreeRoot The Merkle tree root hash value which is generated for a tree with all tickets
    function updateMerkleTreeRoot(uint64 eventId, bytes32 merkleTreeRoot) external;

    /// @dev Update ticket sell times
    /// @param eventId Event ID for which will be @param ticketSellStartTime and @param ticketSellEndTime updated
    /// @param ticketSellStartTime Timestamp which tells when is allowed to start ticket sell
    /// @param ticketSellEndTime Timestamp which tells when is finished ticket sell
    function updateTicketSellTimes(uint64 eventId, uint256 ticketSellStartTime, uint256 ticketSellEndTime) external;

    /// @dev Update maximum number of tickets that one account could buy
    /// @param eventId Event ID for which will be @param maxTicketNumberPerAccount updated
    /// @param maxTicketNumberPerAccount Maximum number of tickets that one account could buy
    function updateMaxTicketNumberPerAccount(uint64 eventId, uint256 maxTicketNumberPerAccount) external;

    /// @dev Update token address
    /// @param eventId Event ID for which will be @param tokenAddress updated
    /// @param tokenAddress Address of an ERC20 token in which event tickets will be bought/sold/resell
    function updateTokenAddress(uint64 eventId, address tokenAddress) external;

    /// @dev Update block ticket sell flag on event
    /// @param eventId Event ID for which will be @param blockTicketSellFlag updated
    /// @param blockTicketSellFlag true/false values if the ticket sell should be blocked
    function setBlockTicketSellFlagOnEvent(uint64 eventId, bool blockTicketSellFlag) external;

    /// @dev Set that ticketID is sell / not sell on some other platform
    /// @param ticketId TicketID which is set
    /// @param proof An array of hash values which are packed in an array and represent proof that @param ticketId exists in the event
    /// @param ticketSoldFlag `true` if we want to set that ticketID is was sold on other platform, `false` if we reset that
    function setTicketSoldFlag(uint256 ticketId, bytes32[] calldata proof, bool ticketSoldFlag) external;

    /// @dev Mint a NFT (ticket)
    /// @param ticketId TicketID which is buying (mint)
    /// @param proof An array of hash values which are packed in an array and represent proof that @param ticketId exists in the event
    function mint(uint256 ticketId, bytes32[] calldata proof) external;

    /// @dev Mint a NFT (ticket)
    /// @param ticketId Array of TicketIDs which is buying (mint)
    /// @param proof Array of an array of hash values which are packed in an array and represent proof that @param ticketId exists in the event
    function mint(uint256[] calldata ticketId, bytes32[][] calldata proof) external;

    /// @dev Withdraw ERC20 token from organiser side
    /// @param tokenAddress Address of an ERC20 token which withdrawing
    /// @param amount Amount that is withdrawing
    function withdraw(address tokenAddress, uint256 amount) external;

    /// @dev Withdraw ERC20 token from protocol side
    /// @param tokenAddress Address of an ERC20 token which withdrawing
    /// @param amount Amount that is withdrawing
    function withdrawProtocolSellFee(address tokenAddress, uint256 amount) external;

    /// @dev Set up ticket price for a ticket level
    /// @param ticketLevel Ticket level for which is set price
    /// @param price Price that is set for a ticket level
    function setupTicketPrice(uint256 ticketLevel, uint256 price) external;

    /// @dev Set up ticket prices for a ticket levels
    /// @param ticketLevels Ticket levels for which is set price
    /// @param ticketPrices Prices that is set for a ticket levels
    function setupTicketPrice(uint256[] calldata ticketLevels, uint256[] calldata ticketPrices) external;

    /// @dev Fee denominator value
    function feeDenominator() external pure returns (uint96);

    /// @dev Check is @param account has administrator role
    /// @param account The account address which will be checked
    function isAdminRole(address account) external view returns (bool);

    /// @dev Check is @param account has SET_TICKET_FLAG_ROLE role
    /// @param account The account address which will be checked
    function isSetTicketFlagRole(address account) external view returns (bool);

    /// @dev Encode levels array into ticket ID
    /// @param levels The array of levels that should be encoded into ticketId
    //                  (max is 8 levels, the first level is event id)
    function encodeTicketID(uint32[] calldata levels) external pure returns (uint256);

    /// @dev Decode ticket ID into array of levels
    /// @param ticketId The ticketId that should be decoded into levels
    function decodeTicketID(uint256 ticketId) external pure returns (uint32[] memory);

    /// @dev Check if a ticket with @param ticketId exist (could be generated)
    ///         For this check is used MerkleTree.verify function
    /// @param ticketId Ticket ID which is check
    /// @param proof An array of hash values which are packed in an array and represent proof that @param ticketId exists in the event
    function isTicketExist(uint256 ticketId, bytes32[] calldata proof) external view returns (bool);

    /// @dev Check if a ticket with @param ticketId exist (could be generated)
    ///         For this check is used MerkleTree.verify function
    /// @param ticketId Ticket ID which is check
    /// @param proof An array of hash values which are packed in an array and represent proof that @param ticketId exists in the event
    /// @param merkleTreeRoot The Merkle tree root hash value which is generated for a tree with all tickets
    ///         and it is using to check if ticket exist
    function isTicketExist(uint256 ticketId, bytes32[] calldata proof, bytes32 merkleTreeRoot)
        external
        pure
        returns (bool);
    /// @dev Get organiser ID from ticket ID
    /// @param ticketId Ticket ID from which is getting organiser ID
    function getOrganiserIdFromTicketId(uint256 ticketId) external pure returns (uint32);

    /// @dev Get event ID from ticket ID
    /// @param ticketId Ticket ID from which is getting event ID
    function getEventIdFromTicketId(uint256 ticketId) external pure returns (uint64);

    /// @dev Get ticket price for @param ticketId
    /// @param ticketId Ticket ID for which is getting ticket price
    function getTicketPrice(uint256 ticketId) external view returns (TicketPriceData memory);
}