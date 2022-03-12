// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// interfaces
import "./ICardAuction.sol";
import "@lukso/universalprofile-smart-contracts/contracts/LSP7DigitalAsset/ILSP7DigitalAsset.sol";

// modules
import "@openzeppelin/contracts/utils/Context.sol";
import "@lukso/universalprofile-smart-contracts/contracts/LSP8IdentifiableDigitalAsset/LSP8IdentifiableDigitalAsset.sol";

contract CardAuction is Context, ICardAuction {
    //
    // --- Constants
    //

    uint256 private constant AUCTION_MIN_DURATION = 1 days;
    uint256 private constant AUCTION_MAX_DURATION = 30 days;

    //
    // --- Storage
    //

    mapping(address => mapping(bytes32 => CardAuctionState))
        private auctionStateForTokenId;
    mapping(address => mapping(address => uint256))
        private claimableAmountsForAccount;

    //
    // --- Auction queries
    //

    function auctionDurationRange()
        public
        pure
        override
        returns (uint256, uint256)
    {
        return (AUCTION_MIN_DURATION, AUCTION_MAX_DURATION);
    }

    function auctionFor(address lsp8Contract, bytes32 tokenId)
        public
        view
        override
        returns (CardAuctionState memory)
    {
        CardAuctionState storage auction = auctionStateForTokenId[lsp8Contract][
            tokenId
        ];
        require(auction.minimumBid > 0, "CardAuction: no auction for tokenId");

        return auction;
    }

    //
    // --- Auction logic
    //

    function openAuctionFor(
        address lsp8Contract,
        bytes32 tokenId,
        address acceptedToken,
        uint256 minimumBid,
        uint256 duration
    ) public override {
        address seller = _msgSender();
        CardAuctionState storage auction = auctionStateForTokenId[lsp8Contract][
            tokenId
        ];
        require(
            auction.minimumBid == 0,
            "CardAuction: auction exists for tokenId"
        );
        require(minimumBid > 0, "CardAuction: minimumBid must be set");
        require(
            duration >= AUCTION_MIN_DURATION &&
                duration <= AUCTION_MAX_DURATION,
            "CardAuction: invalid duration"
        );

        // solhint-disable-next-line not-rely-on-time
        uint256 endTime = block.timestamp + duration;
        auctionStateForTokenId[lsp8Contract][tokenId] = CardAuctionState({
            seller: seller,
            lsp8Contract: lsp8Contract,
            acceptedToken: acceptedToken,
            minimumBid: minimumBid,
            endTime: endTime,
            activeBidder: address(0),
            activeBidAmount: 0
        });

        ILSP8IdentifiableDigitalAsset(lsp8Contract).transfer(
            seller,
            address(this),
            tokenId,
            true,
            ""
        );

        emit AuctionOpen(
            lsp8Contract,
            tokenId,
            acceptedToken,
            minimumBid,
            endTime
        );
    }

    function submitBid(
        address lsp8Contract,
        bytes32 tokenId,
        uint256 bidAmount
    ) public payable override {
        address bidder = _msgSender();
        CardAuctionState memory auction = auctionStateForTokenId[lsp8Contract][
            tokenId
        ];
        require(auction.minimumBid > 0, "CardAuction: no auction for tokenId");
        require(
            // TODO: assuming we want to use minimumBid as the threshold step between bids
            auction.activeBidAmount + auction.minimumBid <= bidAmount,
            "CardAuction: bid amount less than minimum bid"
        );
        require(
            // solhint-disable-next-line not-rely-on-time
            auction.endTime > block.timestamp,
            "CardAuction: auction is not active"
        );

        if (auction.activeBidAmount > 0) {
            _updateClaimableAmount(
                auction.acceptedToken,
                auction.activeBidder,
                auction.activeBidAmount
            );
        }

        // update auctions active bid
        auctionStateForTokenId[lsp8Contract][tokenId]
            .activeBidAmount = bidAmount;
        auctionStateForTokenId[lsp8Contract][tokenId].activeBidder = bidder;

        if (auction.acceptedToken == address(0)) {
            require(
                msg.value == bidAmount,
                "CardAuction: bid amount incorrect"
            );
        } else {
            require(
                msg.value == 0,
                "CardAuction: bid with token included native coin"
            );
            ILSP7DigitalAsset(auction.acceptedToken).transfer(
                bidder,
                address(this),
                bidAmount,
                true,
                ""
            );
        }

        emit AuctionBidSubmit(lsp8Contract, tokenId, bidder, bidAmount);
    }

    function cancelAuctionFor(address lsp8Contract, bytes32 tokenId)
        public
        override
    {
        CardAuctionState memory auction = auctionStateForTokenId[lsp8Contract][
            tokenId
        ];
        require(auction.minimumBid > 0, "CardAuction: no auction for tokenId");
        require(
            auction.seller == _msgSender(),
            "CardAuction: can not cancel auction for someone else"
        );
        require(
            auction.activeBidder == address(0),
            "CardAuction: can not cancel auction with bidder"
        );

        delete auctionStateForTokenId[lsp8Contract][tokenId];

        ILSP8IdentifiableDigitalAsset(auction.lsp8Contract).transfer(
            address(this),
            auction.seller,
            tokenId,
            true,
            ""
        );

        emit AuctionCancel(lsp8Contract, tokenId);
    }

    function closeAuctionFor(address lsp8Contract, bytes32 tokenId)
        public
        override
    {
        CardAuctionState memory auction = auctionStateForTokenId[lsp8Contract][
            tokenId
        ];
        require(auction.minimumBid > 0, "CardAuction: no auction for tokenId");
        require(
            // solhint-disable-next-line not-rely-on-time
            auction.endTime <= block.timestamp,
            "CardAuction: auction is active"
        );

        delete auctionStateForTokenId[lsp8Contract][tokenId];

        if (auction.activeBidAmount > 0) {
            _updateClaimableAmount(
                auction.acceptedToken,
                auction.seller,
                auction.activeBidAmount
            );

            ILSP8IdentifiableDigitalAsset(auction.lsp8Contract).transfer(
                address(this),
                auction.activeBidder,
                tokenId,
                true,
                ""
            );
        }

        emit AuctionClose(
            lsp8Contract,
            tokenId,
            auction.activeBidder,
            auction.activeBidAmount
        );
    }

    function _updateClaimableAmount(
        address token,
        address account,
        uint256 amount
    ) private {
        claimableAmountsForAccount[account][token] =
            claimableAmountsForAccount[account][token] +
            amount;
    }

    //
    // --- Claimable queries
    //

    function claimableAmountsFor(address account, address token)
        public
        view
        override
        returns (uint256)
    {
        return claimableAmountsForAccount[account][token];
    }

    //
    // --- Claimable logic
    //

    function claimToken(address account, address token)
        public
        override
        returns (uint256)
    {
        uint256 amount = claimableAmountsForAccount[account][token];
        require(amount > 0, "CardAuction: no claimable amount");

        delete claimableAmountsForAccount[account][token];

        if (token == address(0)) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = payable(account).call{ value: amount }("");
            require(success, "CardAuction: transfer failed");
        } else {
            ILSP7DigitalAsset(token).transfer(
                address(this),
                account,
                amount,
                true,
                ""
            );
        }

        return amount;
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface ICardAuction {
    //
    // --- Structs
    //

    struct CardAuctionState {
        address seller;
        address lsp8Contract;
        address acceptedToken;
        uint256 minimumBid;
        uint256 endTime;
        address activeBidder;
        uint256 activeBidAmount;
    }

    //
    // --- Events
    //

    event AuctionOpen(
        address indexed lsp8Contract,
        bytes32 indexed tokenId,
        address indexed acceptedToken,
        uint256 minimumBid,
        uint256 endTime
    );

    event AuctionBidSubmit(
        address indexed lsp8Contract,
        bytes32 indexed tokenId,
        address indexed bidder,
        uint256 bidAmount
    );

    event AuctionCancel(address indexed lsp8Contract, bytes32 indexed tokenId);

    event AuctionClose(
        address indexed lsp8Contract,
        bytes32 indexed tokenId,
        address indexed auctionWinner,
        uint256 bidAmount
    );

    //
    // --- Auction queries
    //

    function auctionDurationRange() external returns (uint256, uint256);

    function auctionFor(address lsp8Contract, bytes32 tokenId)
        external
        returns (CardAuctionState memory);

    //
    // --- Auction logic
    //

    function openAuctionFor(
        address lsp8Contract,
        bytes32 tokenId,
        address acceptedToken,
        uint256 minimumBid,
        uint256 duration
    ) external;

    function submitBid(
        address lsp8Contract,
        bytes32 tokenId,
        uint256 amount
    ) external payable;

    function cancelAuctionFor(address lsp8Contract, bytes32 tokenId) external;

    function closeAuctionFor(address lsp8Contract, bytes32 tokenId) external;

    //
    // --- Claimable queries
    //

    function claimableAmountsFor(address account, address token)
        external
        view
        returns (uint256);

    //
    // --- Claimable logic
    //

    function claimToken(address account, address token)
        external
        returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// interfaces
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@erc725/smart-contracts/contracts/interfaces/IERC725Y.sol";

/**
 * @dev Required interface of a LSP8 compliant contract.
 */
interface ILSP7DigitalAsset is IERC165, IERC725Y {
    // --- Events

    /**
     * @dev Emitted when `amount` tokens is transferred from `from` to `to`.
     * @param operator The address of operator sending tokens
     * @param from The address which tokens are sent
     * @param to The receiving address
     * @param amount The amount of tokens transferred
     * @param force When set to TRUE, `to` may be any address but
     * when set to FALSE `to` must be a contract that supports LSP1 UniversalReceiver
     * @param data Additional data the caller wants included in the emitted event, and sent in the hooks to `from` and `to` addresses
     */
    event Transfer(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bool force,
        bytes data
    );

    /**
     * @dev Emitted when `tokenOwner` enables `operator` for `amount` tokens.
     * @param operator The address authorized as an operator
     * @param tokenOwner The token owner
     * @param amount The amount of tokens `operator` address has access to from `tokenOwner`
     */
    event AuthorizedOperator(
        address indexed operator,
        address indexed tokenOwner,
        uint256 indexed amount
    );

    /**
     * @dev Emitted when `tokenOwner` disables `operator` for `amount` tokens.
     * @param operator The address revoked from operating
     * @param tokenOwner The token owner
     */
    event RevokedOperator(address indexed operator, address indexed tokenOwner);

    // --- Token queries

    /**
     * @dev Returns the number of decimals used to get its user representation
     * If the contract represents a NFT then 0 SHOULD be used, otherwise 18 is the common value
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {balanceOf} and {transfer}.
     */
    function decimals() external view returns (uint256);

    /**
     * @dev Returns the number of existing tokens.
     * @return The number of existing tokens
     */
    function totalSupply() external view returns (uint256);

    // --- Token owner queries

    /**
     * @dev Returns the number of tokens owned by `tokenOwner`.
     * @param tokenOwner The address to query
     * @return The number of tokens owned by this address
     */
    function balanceOf(address tokenOwner) external view returns (uint256);

    // --- Operator functionality

    /**
     * @param operator The address to authorize as an operator.
     * @param amount The amount of tokens operator has access to.
     * @dev Sets `amount` as the amount of tokens `operator` address has access to from callers tokens.
     *
     * See {isOperatorFor}.
     *
     * Requirements
     *
     * - `operator` cannot be the zero address.
     *
     * Emits an {AuthorizedOperator} event.
     */
    function authorizeOperator(address operator, uint256 amount) external;

    /**
     * @param operator The address to revoke as an operator.
     * @dev Removes `operator` address as an operator of callers tokens.
     *
     * See {isOperatorFor}.
     *
     * Requirements
     *
     * - `operator` cannot be the zero address.
     *
     * Emits a {RevokedOperator} event.
     */
    function revokeOperator(address operator) external;

    /**
     * @param operator The address to query operator status for.
     * @param tokenOwner The token owner.
     * @return The amount of tokens `operator` address has access to from `tokenOwner`.
     * @dev Returns amount of tokens `operator` address has access to from `tokenOwner`.
     * Operators can send and burn tokens on behalf of their owners. The tokenOwner is their own
     * operator.
     */
    function isOperatorFor(address operator, address tokenOwner)
        external
        view
        returns (uint256);

    // --- Transfer functionality

    /**
     * @param from The sending address.
     * @param to The receiving address.
     * @param amount The amount of tokens to transfer.
     * @param force When set to TRUE, to may be any address but
     * when set to FALSE to must be a contract that supports LSP1 UniversalReceiver
     * @param data Additional data the caller wants included in the emitted event, and sent in the hooks to `from` and `to` addresses.
     *
     * @dev Transfers `amount` of tokens from `from` to `to`. The `force` parameter will be used
     * when notifying the token sender and receiver.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `amount` tokens must be owned by `from`.
     * - If the caller is not `from`, it must be an operator for `from` with access to at least
     * `amount` tokens.
     *
     * Emits a {Transfer} event.
     */
    function transfer(
        address from,
        address to,
        uint256 amount,
        bool force,
        bytes memory data
    ) external;

    /**
     * @param from The list of sending addresses.
     * @param to The list of receiving addresses.
     * @param amount The amount of tokens to transfer.
     * @param force When set to TRUE, to may be any address but
     * when set to FALSE to must be a contract that supports LSP1 UniversalReceiver
     * @param data Additional data the caller wants included in the emitted event, and sent in the hooks to `from` and `to` addresses.
     *
     * @dev Transfers many tokens based on the list `from`, `to`, `amount`. If any transfer fails
     * the call will revert.
     *
     * Requirements:
     *
     * - `from`, `to`, `amount` lists are the same length.
     * - no values in `from` can be the zero address.
     * - no values in `to` can be the zero address.
     * - each `amount` tokens must be owned by `from`.
     * - If the caller is not `from`, it must be an operator for `from` with access to at least
     * `amount` tokens.
     *
     * Emits {Transfer} events.
     */
    function transferBatch(
        address[] memory from,
        address[] memory to,
        uint256[] memory amount,
        bool force,
        bytes[] memory data
    ) external;
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

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// modules
import "./LSP8IdentifiableDigitalAssetCore.sol";
import "../LSP4DigitalAssetMetadata/LSP4DigitalAssetMetadata.sol";
import "@erc725/smart-contracts/contracts/ERC725Y.sol";

// constants
import "./LSP8Constants.sol";
import "../LSP4DigitalAssetMetadata/LSP4Constants.sol";

/**
 * @title LSP8IdentifiableDigitalAsset contract
 * @author Matthew Stevens
 * @dev Implementation of a LSP8 compliant contract.
 */
contract LSP8IdentifiableDigitalAsset is
    LSP8IdentifiableDigitalAssetCore,
    LSP4DigitalAssetMetadata
{
    /**
     * @notice Sets the token-Metadata and register LSP8InterfaceId
     * @param name_ The name of the token
     * @param symbol_ The symbol of the token
     * @param newOwner_ The owner of the the token-Metadata
     */
    constructor(
        string memory name_,
        string memory symbol_,
        address newOwner_
    ) LSP4DigitalAssetMetadata(name_, symbol_, newOwner_) {
        _registerInterface(_INTERFACEID_LSP8);
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

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/**
 * @title The interface for ERC725Y General key/value store
 * @dev ERC725Y provides the ability to set arbitrary key value sets that can be changed over time
 * It is intended to standardise certain keys value pairs to allow automated retrievals and interactions
 * from interfaces and other smart contracts
 */
interface IERC725Y {
    /**
     * @notice Emitted when data at a key is changed
     * @param key The key which value is set
     * @param value The value to set
     */
    event DataChanged(bytes32 indexed key, bytes value);

    /**
     * @notice Gets array of data at multiple given keys
     * @param keys The array of keys which values to retrieve
     * @return values The array of data stored at multiple keys
     */
    function getData(bytes32[] memory keys) external view returns (bytes[] memory values);

    /**
     * @param keys The array of keys which values to set
     * @param values The array of values to set
     * @dev Sets array of data at multiple given `key`
     * SHOULD only be callable by the owner of the contract set via ERC173
     *
     * Emits a {DataChanged} event.
     */
    function setData(bytes32[] memory keys, bytes[] memory values) external;
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// modules
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@erc725/smart-contracts/contracts/ERC725Y.sol";

// interfaces
import "../LSP1UniversalReceiver/ILSP1UniversalReceiver.sol";
import "./ILSP8IdentifiableDigitalAsset.sol";

// libraries
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../Utils/ERC725Utils.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

// constants
import "./LSP8Constants.sol";
import "../LSP1UniversalReceiver/LSP1Constants.sol";
import "../LSP4DigitalAssetMetadata/LSP4Constants.sol";

/**
 * @title LSP8IdentifiableDigitalAsset contract
 * @author Matthew Stevens
 * @dev Core Implementation of a LSP8 compliant contract.
 */
abstract contract LSP8IdentifiableDigitalAssetCore is
    Context,
    ILSP8IdentifiableDigitalAsset
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using Address for address;

    // --- Errors

    error LSP8NonExistentTokenId(bytes32 tokenId);
    error LSP8NotTokenOwner(address tokenOwner, bytes32 tokenId, address caller);
    error LSP8NotTokenOperator(bytes32 tokenId, address caller);
    error LSP8CannotUseAddressZeroAsOperator();
    error LSP8CannotSendToAddressZero();
    error LSP8TokenIdAlreadyMinted(bytes32 tokenId);
    error LSP8InvalidTransferBatch();
    error LSP8NotifyTokenReceiverContractMissingLSP1Interface(address tokenReceiver);
    error LSP8NotifyTokenReceiverIsEOA(address tokenReceiver);

    // --- Storage

    uint256 internal _existingTokens;

    // Mapping from `tokenId` to `tokenOwner`
    mapping(bytes32 => address) internal _tokenOwners;

    // Mapping `tokenOwner` to owned tokenIds
    mapping(address => EnumerableSet.Bytes32Set) internal _ownedTokens;

    // Mapping a `tokenId` to its authorized operator addresses.
    mapping(bytes32 => EnumerableSet.AddressSet) internal _operators;

    // --- Token queries

    /**
     * @inheritdoc ILSP8IdentifiableDigitalAsset
     */
    function totalSupply() public view override returns (uint256) {
        return _existingTokens;
    }

    // --- Token owner queries

    /**
     * @inheritdoc ILSP8IdentifiableDigitalAsset
     */
    function balanceOf(address tokenOwner)
        public
        view
        override
        returns (uint256)
    {
        return _ownedTokens[tokenOwner].length();
    }

    /**
     * @inheritdoc ILSP8IdentifiableDigitalAsset
     */
    function tokenOwnerOf(bytes32 tokenId)
        public
        view
        override
        returns (address)
    {
        address tokenOwner = _tokenOwners[tokenId];

        if (tokenOwner == address(0)) {
            revert LSP8NonExistentTokenId(tokenId);
        }

        return tokenOwner;
    }

    /**
     * @inheritdoc ILSP8IdentifiableDigitalAsset
     */
    function tokenIdsOf(address tokenOwner)
        public
        view
        override
        returns (bytes32[] memory)
    {
        return _ownedTokens[tokenOwner].values();
    }

    // --- Operator functionality

    /**
     * @inheritdoc ILSP8IdentifiableDigitalAsset
     */
    function authorizeOperator(address operator, bytes32 tokenId)
        public
        virtual
        override
    {
        address tokenOwner = tokenOwnerOf(tokenId);
        address caller = _msgSender();

        if (tokenOwner != caller) {
            revert LSP8NotTokenOwner(tokenOwner, tokenId, caller);
        }

        if (operator == address(0)) {
            revert LSP8CannotUseAddressZeroAsOperator();
        }

        // tokenOwner is always their own operator, no update required
        if (tokenOwner == operator) {
            return;
        }

        _operators[tokenId].add(operator);

        emit AuthorizedOperator(operator, tokenOwner, tokenId);
    }

    /**
     * @inheritdoc ILSP8IdentifiableDigitalAsset
     */
    function revokeOperator(address operator, bytes32 tokenId)
        public
        virtual
        override
    {
        address tokenOwner = tokenOwnerOf(tokenId);
        address caller = _msgSender();

        if (tokenOwner != caller) {
            revert LSP8NotTokenOwner(tokenOwner, tokenId, caller);
        }

        if (operator == address(0)) {
            revert LSP8CannotUseAddressZeroAsOperator();
        }

        // tokenOwner is always their own operator, no update required
        if (tokenOwner == operator) {
            return;
        }

        _revokeOperator(operator, tokenOwner, tokenId);
    }

    /**
     * @inheritdoc ILSP8IdentifiableDigitalAsset
     */
    function isOperatorFor(address operator, bytes32 tokenId)
        public
        view
        virtual
        override
        returns (bool)
    {
        _existsOrError(tokenId);

        return _isOperatorOrOwner(operator, tokenId);
    }

    /**
     * @inheritdoc ILSP8IdentifiableDigitalAsset
     */
    function getOperatorsOf(bytes32 tokenId)
        public
        view
        virtual
        override
        returns (address[] memory)
    {
        _existsOrError(tokenId);

        return _operators[tokenId].values();
    }

    function _isOperatorOrOwner(address caller, bytes32 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        address tokenOwner = tokenOwnerOf(tokenId);

        return (caller == tokenOwner || _operators[tokenId].contains(caller));
    }

    // --- Transfer functionality

    /**
     * @inheritdoc ILSP8IdentifiableDigitalAsset
     */
    function transfer(
        address from,
        address to,
        bytes32 tokenId,
        bool force,
        bytes memory data
    ) public virtual override {
        address operator = _msgSender();

        if (!_isOperatorOrOwner(operator, tokenId)) {
            revert LSP8NotTokenOperator(tokenId, operator);
        }

        _transfer(from, to, tokenId, force, data);
    }

    /**
     * @inheritdoc ILSP8IdentifiableDigitalAsset
     */
    function transferBatch(
        address[] memory from,
        address[] memory to,
        bytes32[] memory tokenId,
        bool force,
        bytes[] memory data
    ) external virtual override {
        if (from.length != to.length ||
                from.length != tokenId.length ||
                from.length != data.length) {
            revert LSP8InvalidTransferBatch();
        }

        for (uint256 i = 0; i < from.length; i++) {
            transfer(from[i], to[i], tokenId[i], force, data[i]);
        }
    }

    function _revokeOperator(
        address operator,
        address tokenOwner,
        bytes32 tokenId
    ) internal virtual {
        _operators[tokenId].remove(operator);
        emit RevokedOperator(operator, tokenOwner, tokenId);
    }

    function _clearOperators(address tokenOwner, bytes32 tokenId)
        internal
        virtual
    {
        // TODO: here is a good exmaple of why having multiple operators will be expensive.. we
        // need to clear them on token transfer
        //
        // NOTE: this may cause a tx to fail if there is too many operators to clear, in which case
        // the tokenOwner needs to call `revokeOperator` until there is less operators to clear and
        // the desired `transfer` or `burn` call can succeed.
        EnumerableSet.AddressSet storage operatorsForTokenId = _operators[
            tokenId
        ];

        uint256 operatorListLength = operatorsForTokenId.length();
        for (uint256 i = 0; i < operatorListLength; i++) {
            // we are emptying the list, always remove from index 0
            address operator = operatorsForTokenId.at(0);
            _revokeOperator(operator, tokenOwner, tokenId);
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens start existing when they are minted (`_mint`), and stop existing when they are burned
     * (`_burn`).
     */
    function _exists(bytes32 tokenId) internal view virtual returns (bool) {
        return _tokenOwners[tokenId] != address(0);
    }

    /**
     * @dev When `tokenId` does not exist then revert with an error.
     */
    function _existsOrError(bytes32 tokenId) internal view {
        if (!_exists(tokenId)) {
            revert LSP8NonExistentTokenId(tokenId);
        }
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        address to,
        bytes32 tokenId,
        bool force,
        bytes memory data
    ) internal virtual {
        if (to == address(0)) {
            revert LSP8CannotSendToAddressZero();
        }

        if (_exists(tokenId)) {
            revert LSP8TokenIdAlreadyMinted(tokenId);
        }

        address operator = _msgSender();

        _beforeTokenTransfer(address(0), to, tokenId);

        _ownedTokens[to].add(tokenId);
        _tokenOwners[tokenId] = to;

        emit Transfer(operator, address(0), to, tokenId, force, data);

        _notifyTokenReceiver(address(0), to, tokenId, force, data);
    }

    /**
     * @dev Destroys `tokenId`, clearing authorized operators.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(bytes32 tokenId, bytes memory data) internal virtual {
        address tokenOwner = tokenOwnerOf(tokenId);
        address operator = _msgSender();

        _notifyTokenSender(tokenOwner, address(0), tokenId, data);

        _beforeTokenTransfer(tokenOwner, address(0), tokenId);

        _clearOperators(tokenOwner, tokenId);

        _ownedTokens[tokenOwner].remove(tokenId);
        delete _tokenOwners[tokenId];

        emit Transfer(operator, tokenOwner, address(0), tokenId, false, data);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        bytes32 tokenId,
        bool force,
        bytes memory data
    ) internal virtual {
        address tokenOwner = tokenOwnerOf(tokenId);
        if (tokenOwner != from) {
            revert LSP8NotTokenOwner(tokenOwner, tokenId, from);
        }

        if (to == address(0)) {
            revert LSP8CannotSendToAddressZero();
        }

        address operator = _msgSender();

        _notifyTokenSender(from, to, tokenId, data);

        _beforeTokenTransfer(from, to, tokenId);

        _clearOperators(from, tokenId);

        _ownedTokens[from].remove(tokenId);
        _ownedTokens[to].add(tokenId);
        _tokenOwners[tokenId] = to;

        emit Transfer(operator, from, to, tokenId, force, data);

        _notifyTokenReceiver(from, to, tokenId, force, data);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        bytes32 tokenId
    ) internal virtual {
        // silence compiler warning about unused variable
        tokenId;

        // token being minted
        if (from == address(0)) {
            _existingTokens += 1;
        }

        // token being burned
        if (to == address(0)) {
            _existingTokens -= 1;
        }
    }

    /**
     * @dev An attempt is made to notify the token sender about the `tokenId` changing owners using
     * LSP1 interface.
     */
    function _notifyTokenSender(
        address from,
        address to,
        bytes32 tokenId,
        bytes memory data
    ) internal virtual {
        if (
            ERC165Checker.supportsERC165(from) &&
            ERC165Checker.supportsInterface(from, _INTERFACEID_LSP1)
        ) {
            bytes memory packedData = abi.encodePacked(from, to, tokenId, data);
            ILSP1UniversalReceiver(from).universalReceiver(
                _TYPEID_LSP8_TOKENSSENDER,
                packedData
            );
        }
    }

    /**
     * @dev An attempt is made to notify the token receiver about the `tokenId` changing owners
     * using LSP1 interface. When force is FALSE the token receiver MUST support LSP1.
     *
     * The receiver may revert when the token being sent is not wanted.
     */
    function _notifyTokenReceiver(
        address from,
        address to,
        bytes32 tokenId,
        bool force,
        bytes memory data
    ) internal virtual {
        if (
            ERC165Checker.supportsERC165(to) &&
            ERC165Checker.supportsInterface(to, _INTERFACEID_LSP1)
        ) {
            bytes memory packedData = abi.encodePacked(from, to, tokenId, data);
            ILSP1UniversalReceiver(to).universalReceiver(
                _TYPEID_LSP8_TOKENSRECIPIENT,
                packedData
            );
        } else if (!force) {
            if (to.isContract()) {
                revert LSP8NotifyTokenReceiverContractMissingLSP1Interface(to);
            } else {
                revert LSP8NotifyTokenReceiverIsEOA(to);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// modules
import "@erc725/smart-contracts/contracts/ERC725Y.sol";

// constants
import "./LSP4Constants.sol";

/**
 * @title LSP4DigitalAssetMetadata
 * @author Matthew Stevens
 * @dev Implementation of a LSP8 compliant contract.
 */
abstract contract LSP4DigitalAssetMetadata is ERC725Y {
    /**
     * @notice Sets the name, symbol of the token and the owner, and sets the SupportedStandards:LSP4DigitalAsset key
     * @param name_ The name of the token
     * @param symbol_ The symbol of the token
     * @param newOwner_ The owner of the token contract
     */
    constructor(
        string memory name_,
        string memory symbol_,
        address newOwner_
    ) ERC725Y(newOwner_) {
        // SupportedStandards:LSP4DigitalAsset
        _setData(
            _LSP4_SUPPORTED_STANDARDS_KEY,
            _LSP4_SUPPORTED_STANDARDS_VALUE
        );

        _setData(_LSP4_METADATA_TOKEN_NAME_KEY, bytes(name_));
        _setData(_LSP4_METADATA_TOKEN_SYMBOL_KEY, bytes(symbol_));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// modules
import "./ERC725YCore.sol";

/**
 * @title ERC725 Y General key/value store
 * @author Fabian Vogelsteller <[email protected]>
 * @dev Contract module which provides the ability to set arbitrary key value sets that can be changed over time
 * It is intended to standardise certain keys value pairs to allow automated retrievals and interactions
 * from interfaces and other smart contracts
 */
contract ERC725Y is ERC725YCore {
    /**
     * @notice Sets the owner of the contract and register ERC725Y interfaceId
     * @param _newOwner the owner of the contract
     */
    constructor(address _newOwner) {
        // This is necessary to prevent a contract that implements both ERC725X and ERC725Y to call both constructors
        if (_newOwner != owner()) {
            OwnableUnset.initOwner(_newOwner);
        }

        _registerInterface(_INTERFACEID_ERC725Y);
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// --- ERC165 interface ids
bytes4 constant _INTERFACEID_LSP8 = 0x49399145;

// --- ERC725Y entries

// bytes8('LSP8MetadataAddress') + bytes4(0)
bytes12 constant _LSP8_METADATA_ADDRESS_KEY_PREFIX = 0x73dcc7c3c4096cdc00000000;

// bytes8('LSP8MetadataJSON') + bytes4(0)
bytes12 constant _LSP8_METADATA_JSON_KEY_PREFIX = 0x9a26b4060ae7f7d500000000;

// --- Token Hooks
bytes32 constant _TYPEID_LSP8_TOKENSSENDER = 0x3724c94f0815e936299cca424da4140752198e0beb7931a6e0925d11bc97544c; // keccak256("LSP8TokensSender")

bytes32 constant _TYPEID_LSP8_TOKENSRECIPIENT = 0xc7a120a42b6057a0cbed111fbbfbd52fcd96748c04394f77fc2c3adbe0391e01; // keccak256("LSP8TokensRecipient")

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// --- ERC725Y entries

// bytes16(keccak256('SupportedStandard')) + bytes12(0) + bytes4(keccak256('LSP4DigitalAsset'))
bytes32 constant _LSP4_SUPPORTED_STANDARDS_KEY = 0xeafec4d89fa9619884b6b89135626455000000000000000000000000a4d96624;

// bytes4(keccak256('LSP4DigitalAsset'))
bytes constant _LSP4_SUPPORTED_STANDARDS_VALUE = hex"a4d96624";

// keccak256('LSP4TokenName')
bytes32 constant _LSP4_METADATA_TOKEN_NAME_KEY = 0xdeba1e292f8ba88238e10ab3c7f88bd4be4fac56cad5194b6ecceaf653468af1;

// keccak256('LSP4TokenSymbol')
bytes32 constant _LSP4_METADATA_TOKEN_SYMBOL_KEY = 0x2f0a68ab07768e01943a599e73362a0e17a63a72e94dd2e384d2c1d4db932756;

// keccak256('LSP4Metadata')
bytes32 constant _LSP4_METADATA_KEY = 0x9afb95cacc9f95858ec44aa8c3b685511002e30ae54415823f406128b85b238e;

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/**
 * @title The interface for LSP1UniversalReceiver
 * @dev LSP1UniversalReceiver allows to receive arbitrary messages and to be informed when assets are sent or received
 */
interface ILSP1UniversalReceiver {
    /**
     * @notice Emitted when the universalReceiver function is succesfully executed
     * @param from The address calling the universalReceiver function
     * @param typeId The hash of a specific standard or a hook
     * @param returnedValue The return value of universalReceiver function
     * @param receivedData The arbitrary data passed to universalReceiver function
     */
    event UniversalReceiver(
        address indexed from,
        bytes32 indexed typeId,
        bytes indexed returnedValue,
        bytes receivedData
    );

    /**
     * @param typeId The hash of a specific standard or a hook
     * @param data The arbitrary data received with the call
     * @dev Emits an event when it's succesfully executed
     *
     * Call the universalReceiverDelegate function in the UniversalReceiverDelegate (URD) contract, if the address of the URD
     * was set as a value for the `_UniversalReceiverKey` in the account key/value value store of the same contract implementing
     * the universalReceiver function and if the URD contract has the LSP1UniversalReceiverDelegate Interface Id registred using ERC165
     *
     * Emits a {UniversalReceiver} event
     */
    function universalReceiver(bytes32 typeId, bytes calldata data)
        external
        returns (bytes memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// interfaces
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@erc725/smart-contracts/contracts/interfaces/IERC725Y.sol";

/**
 * @dev Required interface of a LSP8 compliant contract.
 */
interface ILSP8IdentifiableDigitalAsset is IERC165, IERC725Y {
    // --- Events

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     * @param operator The address of operator sending tokens
     * @param from The address which tokens are sent
     * @param to The receiving address
     * @param tokenId The tokenId transferred
     * @param force When set to TRUE, `to` may be any address but
     * when set to FALSE `to` must be a contract that supports LSP1 UniversalReceiver
     * @param data Additional data the caller wants included in the emitted event, and sent in the hooks to `from` and `to` addresses
     */
    event Transfer(
        address operator,
        address indexed from,
        address indexed to,
        bytes32 indexed tokenId,
        bool force,
        bytes data
    );

    /**
     * @dev Emitted when `tokenOwner` enables `operator` for `tokenId`.
     * @param operator The address authorized as an operator
     * @param tokenOwner The token owner
     * @param tokenId The tokenId `operator` address has access to from `tokenOwner`
     */
    event AuthorizedOperator(
        address indexed operator,
        address indexed tokenOwner,
        bytes32 indexed tokenId
    );

    /**
     * @dev Emitted when `tokenOwner` disables `operator` for `tokenId`.
     * @param operator The address revoked from operating
     * @param tokenOwner The token owner
     * @param tokenId The tokenId `operator` is revoked from operating
     */
    event RevokedOperator(
        address indexed operator,
        address indexed tokenOwner,
        bytes32 indexed tokenId
    );

    // --- Token queries

    /**
     * @dev Returns the number of existing tokens.
     * @return The number of existing tokens
     */
    function totalSupply() external view returns (uint256);

    //
    // --- Token owner queries
    //

    /**
     * @dev Returns the number of tokens owned by `tokenOwner`.
     * @param tokenOwner The address to query
     * @return The number of tokens owned by this address
     */
    function balanceOf(address tokenOwner) external view returns (uint256);

    /**
     * @param tokenId The tokenId to query
     * @return The address owning the `tokenId`
     * @dev Returns the `tokenOwner` address of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function tokenOwnerOf(bytes32 tokenId) external view returns (address);

    /**
     * @dev Returns the list of `tokenIds` for the `tokenOwner` address.
     * @param tokenOwner The address to query owned tokens
     * @return List of owned tokens by `tokenOwner` address
     */
    function tokenIdsOf(address tokenOwner)
        external
        view
        returns (bytes32[] memory);

    // --- Operator functionality

    /**
     * @param operator The address to authorize as an operator.
     * @param tokenId The tokenId operator has access to.
     * @dev Makes `operator` address an operator of `tokenId`.
     *
     * See {isOperatorFor}.
     *
     * Requirements
     *
     * - `tokenId` must exist.
     * - caller must be current `tokenOwner` of `tokenId`.
     * - `operator` cannot be the zero address.
     *
     * Emits an {AuthorizedOperator} event.
     */
    function authorizeOperator(address operator, bytes32 tokenId) external;

    /**
     * @param operator The address to revoke as an operator.
     * @param tokenId The tokenId `operator` is revoked from operating
     * @dev Removes `operator` address as an operator of `tokenId`.
     *
     * See {isOperatorFor}.
     *
     * Requirements
     *
     * - `tokenId` must exist.
     * - caller must be current `tokenOwner` of `tokenId`.
     * - `operator` cannot be the zero address.
     *
     * Emits a {RevokedOperator} event.
     */
    function revokeOperator(address operator, bytes32 tokenId) external;

    /**
     * @param operator The address to query
     * @param tokenId The tokenId to query
     * @return True if the owner of `tokenId` is `operator` address, false otherwise
     * @dev Returns whether `operator` address is an operator of `tokenId`.
     * Operators can send and burn tokens on behalf of their owners. The tokenOwner is their own
     * operator.
     *
     * Requirements
     *
     * - `tokenId` must exist.
     */
    function isOperatorFor(address operator, bytes32 tokenId)
        external
        view
        returns (bool);

    /**
     * @param tokenId The tokenId to query
     * @return The list of operators for the `tokenId`
     * @dev Returns all `operator` addresses of `tokenId`.
     *
     * Requirements
     *
     * - `tokenId` must exist.
     */
    function getOperatorsOf(bytes32 tokenId)
        external
        view
        returns (address[] memory);

    // --- Transfer functionality

    /**
     * @param from The sending address.
     * @param to The receiving address.
     * @param tokenId The tokenId to transfer.
     * @param force When set to TRUE, to may be any address but
     * when set to FALSE to must be a contract that supports LSP1 UniversalReceiver
     * @param data Additional data the caller wants included in the emitted event, and sent in the hooks to `from` and `to` addresses.
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be an operator of `tokenId`.
     *
     * Emits a {Transfer} event.
     */
    function transfer(
        address from,
        address to,
        bytes32 tokenId,
        bool force,
        bytes memory data
    ) external;

    /**
     * @param from The list of sending addresses.
     * @param to The list of receiving addresses.
     * @param tokenId The list of tokenId to transfer.
     * @param force When set to TRUE, to may be any address but
     * when set to FALSE to must be a contract that supports LSP1 UniversalReceiver
     * @param data Additional data the caller wants included in the emitted event, and sent in the hooks to `from` and `to` addresses.
     *
     * @dev Transfers many tokens based on the list `from`, `to`, `tokenId`. If any transfer fails
     * the call will revert.
     *
     * Requirements:
     *
     * - `from`, `to`, `tokenId` lists are the same length.
     * - no values in `from` can be the zero address.
     * - no values in `to` can be the zero address.
     * - each `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be an operator of each `tokenId`.
     *
     * Emits {Transfer} events.
     */
    function transferBatch(
        address[] memory from,
        address[] memory to,
        bytes32[] memory tokenId,
        bool force,
        bytes[] memory data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@erc725/smart-contracts/contracts/interfaces/IERC725Y.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";

library ERC725Utils {
    // internal functions

    /**
     * @dev Gets one value from account storage
     */
    function getDataSingle(IERC725Y _account, bytes32 _key)
        internal
        view
        returns (bytes memory)
    {
        bytes32[] memory keys = new bytes32[](1);
        keys[0] = _key;
        bytes memory fetchResult = _account.getData(keys)[0];
        return fetchResult;
    }

    /**
     * @dev Initiates Map and ArrayKey and sets the length of the Array to `1` if it's not set before,
     * If it's already set, it decodes the arrayLength, increment it and adds Map and ArrayKey
     */
    function addMapAndArrayKey(
        IERC725Y _account,
        bytes32 _arrayKey,
        bytes32 _mapKey,
        address _sender,
        bytes4 _appendix
    ) internal view returns (bytes32[] memory keys, bytes[] memory values) {
        keys = new bytes32[](3);
        values = new bytes[](3);

        bytes memory rawArrayLength = getDataSingle(_account, _arrayKey);

        keys[0] = _arrayKey;
        keys[2] = _mapKey;

        values[1] = abi.encodePacked(_sender);

        if (rawArrayLength.length != 32) {
            keys[1] = _generateArrayKeyAtIndex(_arrayKey, 0);

            values[0] = abi.encodePacked(uint256(1));
            values[2] = abi.encodePacked(bytes8(0), _appendix);
        } else if (rawArrayLength.length == 32) {
            uint256 arrayLength = abi.decode(rawArrayLength, (uint256));
            uint256 newArrayLength = arrayLength + 1;

            keys[1] = _generateArrayKeyAtIndex(_arrayKey, newArrayLength - 1);

            values[0] = abi.encodePacked(newArrayLength);
            values[2] = abi.encodePacked(
                bytes8(uint64(arrayLength)),
                _appendix
            );
        }
    }

    /**
     * @dev Decrements the arrayLength, removes the Map, swaps the arrayKey that need to be removed with
     * the last `arrayKey` in the array and removes the last arrayKey with updating all modified entries
     */
    function removeMapAndArrayKey(
        IERC725Y _account,
        bytes32 _arrayKey,
        bytes32 mapHash,
        bytes32 _mapKeyToRemove
    ) internal view returns (bytes32[] memory keys, bytes[] memory values) {
        keys = new bytes32[](5);
        values = new bytes[](5);

        uint64 index = _extractIndexFromMap(_account, _mapKeyToRemove);
        bytes32 arrayKeyToRemove = _generateArrayKeyAtIndex(_arrayKey, index);

        bytes memory rawArrayLength = getDataSingle(_account, _arrayKey);
        uint256 arrayLength = abi.decode(rawArrayLength, (uint256));
        uint256 newLength = arrayLength - 1;

        keys[0] = _arrayKey;
        values[0] = abi.encodePacked(newLength);

        keys[1] = _mapKeyToRemove;
        values[1] = "";

        if (index == (arrayLength - 1)) {
            keys[2] = arrayKeyToRemove;
            values[2] = "";
        } else {
            bytes32 lastKey = _generateArrayKeyAtIndex(_arrayKey, newLength);
            bytes memory lastKeyValue = getDataSingle(_account, lastKey);

            bytes32 mapOfLastkey = generateMapKey(mapHash, lastKeyValue);
            bytes memory mapValueOfLastkey = getDataSingle(
                _account,
                mapOfLastkey
            );

            bytes memory appendix = BytesLib.slice(mapValueOfLastkey, 8, 4);

            keys[2] = arrayKeyToRemove;
            values[2] = lastKeyValue;

            keys[3] = lastKey;
            values[3] = "";

            keys[4] = mapOfLastkey;
            values[4] = abi.encodePacked(bytes8(index), appendix);
        }
    }

    function generateMapKey(bytes32 _mapHash, bytes memory _sender)
        internal
        pure
        returns (bytes32)
    {
        bytes memory mapKey = abi.encodePacked(
            bytes8(_mapHash),
            bytes4(0),
            _sender
        );
        return _generateBytes32Key(mapKey);
    }

    // private functions

    function _generateBytes32Key(bytes memory _rawKey)
        private
        pure
        returns (bytes32 key)
    {
        /* solhint-disable */
        assembly {
            key := mload(add(_rawKey, 32))
        }
        /* solhint-enable */
    }

    function _generateArrayKeyAtIndex(bytes32 _arrayKey, uint256 _index)
        private
        pure
        returns (bytes32)
    {
        bytes memory elementInArray = abi.encodePacked(
            bytes16(_arrayKey),
            bytes16(uint128(_index))
        );
        return _generateBytes32Key(elementInArray);
    }

    function _extractIndexFromMap(IERC725Y _account, bytes32 _mapKey)
        private
        view
        returns (uint64)
    {
        bytes memory indexInBytes = getDataSingle(_account, _mapKey);
        bytes8 indexKey;
        /* solhint-disable */
        assembly {
            indexKey := mload(add(indexInBytes, 32))
        }
        /* solhint-enable */
        return uint64(indexKey);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// --- ERC165 interface ids
bytes4 constant _INTERFACEID_LSP1 = 0x6bb56a14;
bytes4 constant _INTERFACEID_LSP1_DELEGATE = 0xc2d7bcc1;

// --- ERC725Y Keys
bytes32 constant _LSP1_UNIVERSAL_RECEIVER_DELEGATE_KEY = 0x0cfc51aec37c55a4d0b1a65c6255c4bf2fbdf6277f3cc0730c45b828b6db8b47; // keccak256("LSP1UniversalReceiverDelegate")

bytes32 constant _ARRAYKEY_LSP5 = 0x6460ee3c0aac563ccbf76d6e1d07bada78e3a9514e6382b736ed3f478ab7b90b; // keccak256("LSP5ReceivedAssets[]")

bytes32 constant _MAPHASH_LSP5 = 0x812c4334633eb816c80deebfa5fb7d2509eb438ca1b6418106442cb5ccc62f6c; // keccak256("LSP5ReceivedAssetsMap")

bytes32 constant _ARRAYKEY_LSP10 = 0x55482936e01da86729a45d2b87a6b1d3bc582bea0ec00e38bdb340e3af6f9f06; // keccak256("LSP10Vaults[]")

bytes32 constant _MAPHASH_LSP10 = 0x192448c3c0f88c7f238c7f70449c270032f9752568e88cc8936ce3a2cb18e3ec; // keccak256("LSP10VaultsMap")

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// constants
import "./constants.sol";

// interfaces
import "./interfaces/IERC725Y.sol";

// modules
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "./utils/OwnableUnset.sol";

/**
 * @title Core implementation of ERC725 Y General key/value store
 * @author Fabian Vogelsteller <[email protected]>
 * @dev Contract module which provides the ability to set arbitrary key value sets that can be changed over time
 * It is intended to standardise certain keys value pairs to allow automated retrievals and interactions
 * from interfaces and other smart contracts
 */
abstract contract ERC725YCore is OwnableUnset, ERC165Storage, IERC725Y {
    /**
     * @dev Map the keys to their values
     */
    mapping(bytes32 => bytes) internal store;

    /* Public functions */

    /**
     * @inheritdoc IERC725Y
     */
    function getData(bytes32[] memory keys)
        public
        view
        virtual
        override
        returns (bytes[] memory values)
    {
        values = new bytes[](keys.length);

        for (uint256 i = 0; i < keys.length; i++) {
            values[i] = _getData(keys[i]);
        }

        return values;
    }

    /**
     * @inheritdoc IERC725Y
     */
    function setData(bytes32[] memory _keys, bytes[] memory _values)
        public
        virtual
        override
        onlyOwner
    {
        require(_keys.length == _values.length, "Keys length not equal to values length");
        for (uint256 i = 0; i < _keys.length; i++) {
            _setData(_keys[i], _values[i]);
        }
    }

    /* Internal functions */

    /**
     * @notice Gets singular data at a given `key`
     * @param key The key which value to retrieve
     * @return value The data stored at the key
     */
    function _getData(bytes32 key) internal view virtual returns (bytes memory value) {
        return store[key];
    }

    /**
     * @notice Sets singular data at a given `key`
     * @param key The key which value to retrieve
     * @param value The value to set
     */
    function _setData(bytes32 key, bytes memory value) internal virtual {
        store[key] = value;
        emit DataChanged(key, value);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// interfaces
import "./interfaces/IERC725X.sol";
import "./interfaces/IERC725Y.sol";

// >> INTERFACES

// ERC725 - Smart Contract based Account
bytes4 constant _INTERFACEID_ERC725X = 0x44c028fe;
bytes4 constant _INTERFACEID_ERC725Y = 0x5a988c0f;

// >> OPERATIONS
uint256 constant OPERATION_CALL = 0;
uint256 constant OPERATION_CREATE = 1;
uint256 constant OPERATION_CREATE2 = 2;
uint256 constant OPERATION_STATICCALL = 3;
uint256 constant OPERATION_DELEGATECALL = 4;

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Storage.sol)

pragma solidity ^0.8.0;

import "./ERC165.sol";

/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Storage is ERC165 {
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// modules
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Modified version of ERC173 with no constructor, instead should call `initOwner` function
 * Contract module which provides a basic access control mechanism, where
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
abstract contract OwnableUnset is Context {
    address private _owner;

    bool private _initiatedOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
     * @dev initiate the owner for the contract
     * It can be called once
     */
    function initOwner(address newOwner) internal {
        require(!_initiatedOwner, "Ownable: owner can only be initiated once");
        _initiatedOwner = true;
        _setOwner(newOwner);
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/**
 * @title The interface for ERC725X General executor
 * @dev ERC725X provides the ability to call arbitrary functions at any other smart contract and itself,
 * including using `delegatecall`, `staticcall`, as well creating contracts using `create` and `create2`
 * This is the basis for a smart contract based account system, but could also be used as a proxy account system
 */
interface IERC725X {
    /**
     * @notice Emitted when a contract is created
     * @param operation The operation used to create a contract
     * @param contractAddress The created contract address
     * @param value The value sent to the created contract address
     */
    event ContractCreated(
        uint256 indexed operation,
        address indexed contractAddress,
        uint256 indexed value
    );

    /**
     * @notice Emitted when a contract executed.
     * @param operation The operation used to execute a contract
     * @param to The address where the call is executed
     * @param value The value sent to the created contract address
     * @param data The data sent with the call
     */
    event Executed(
        uint256 indexed operation,
        address indexed to,
        uint256 indexed value,
        bytes data
    );

    /**
     * @param operationType The operation to execute: CALL = 0 CREATE = 1 CREATE2 = 2 STATICCALL = 3 DELEGATECALL = 4
     * @param to The smart contract or address to interact with, `to` will be unused if a contract is created (operation 1 and 2)
     * @param value The value to transfer
     * @param data The call data, or the contract data to deploy
     * @dev Executes any other smart contract.
     * SHOULD only be callable by the owner of the contract set via ERC173
     *
     * Emits a {Executed} event, when a call is executed under `operationType` 0, 3 and 4
     * Emits a {ContractCreated} event, when a contract is created under `operationType` 1 and 2
     */
    function execute(
        uint256 operationType,
        address to,
        uint256 value,
        bytes calldata data
    ) external payable returns (bytes memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// modules
import "../LSP8IdentifiableDigitalAsset.sol";
import "./LSP8CompatibilityForERC721Core.sol";

// constants
import "./LSP8CompatibilityConstants.sol";

/**
 * @dev LSP8 extension, for compatibility for clients / tools that expect ERC721.
 */
contract LSP8CompatibilityForERC721 is
    LSP8CompatibilityForERC721Core,
    LSP8IdentifiableDigitalAsset
{
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * @notice Sets the name, the symbol and the owner of the token
     * @param name_ The name of the token
     * @param symbol_ The symbol of the token
     * @param newOwner_ The owner of the token
     */
    constructor(
        string memory name_,
        string memory symbol_,
        address newOwner_
    ) LSP8IdentifiableDigitalAsset(name_, symbol_, newOwner_) {
        _registerInterface(_INTERFACEID_ERC721);
        _registerInterface(_INTERFACEID_ERC721METADATA);
    }

    // --- Overrides

    function authorizeOperator(address operator, bytes32 tokenId)
        public
        virtual
        override(
            LSP8IdentifiableDigitalAssetCore,
            LSP8CompatibilityForERC721Core
        )
    {
        super.authorizeOperator(operator, tokenId);
    }

    function _transfer(
        address from,
        address to,
        bytes32 tokenId,
        bool force,
        bytes memory data
    )
        internal
        virtual
        override(
            LSP8IdentifiableDigitalAssetCore,
            LSP8CompatibilityForERC721Core
        )
    {
        super._transfer(from, to, tokenId, force, data);
    }

    function _mint(
        address to,
        bytes32 tokenId,
        bool force,
        bytes memory data
    )
        internal
        virtual
        override(
            LSP8IdentifiableDigitalAssetCore,
            LSP8CompatibilityForERC721Core
        )
    {
        super._mint(to, tokenId, force, data);
    }

    function _burn(bytes32 tokenId, bytes memory data)
        internal
        virtual
        override(
            LSP8IdentifiableDigitalAssetCore,
            LSP8CompatibilityForERC721Core
        )
    {
        super._burn(tokenId, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// modules
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../LSP8IdentifiableDigitalAssetCore.sol";
import "../../LSP4DigitalAssetMetadata/LSP4Compatibility.sol";

// libraries
import "solidity-bytes-utils/contracts/BytesLib.sol";

// interfaces
import "./ILSP8CompatibilityForERC721.sol";

// constants
import "./LSP8CompatibilityConstants.sol";

/**
 * @dev LSP8 extension, for compatibility for clients / tools that expect ERC721.
 */
abstract contract LSP8CompatibilityForERC721Core is
    ILSP8CompatibilityForERC721,
    LSP8IdentifiableDigitalAssetCore,
    LSP4Compatibility
{
    using ERC725Utils for IERC725Y;
    using EnumerableSet for EnumerableSet.AddressSet;

    /*
     * @inheritdoc ILSP8CompatibilityForERC721
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        // silence compiler warning about unused variable
        tokenId;

        bytes memory data = IERC725Y(this).getDataSingle(_LSP4_METADATA_KEY);

        // offset = bytes4(hashSig) + bytes32(contentHash) -> 4 + 32 = 36
        uint256 offset = 36;

        bytes memory uriBytes = BytesLib.slice(
            data,
            offset,
            data.length - offset
        );
        return string(uriBytes);
    }

    /**
     * @inheritdoc ILSP8CompatibilityForERC721
     */
    function ownerOf(uint256 tokenId)
        external
        view
        virtual
        override
        returns (address)
    {
        return tokenOwnerOf(bytes32(tokenId));
    }

    /**
     * @inheritdoc ILSP8CompatibilityForERC721
     */
    function approve(address operator, uint256 tokenId)
        external
        virtual
        override
    {
        authorizeOperator(operator, bytes32(tokenId));

        emit Approval(tokenOwnerOf(bytes32(tokenId)), operator, tokenId);
    }

    /**
     * @inheritdoc ILSP8CompatibilityForERC721
     */
    function getApproved(uint256 tokenId)
        external
        view
        virtual
        override
        returns (address)
    {
        bytes32 tokenIdAsBytes32 = bytes32(tokenId);
        _existsOrError(tokenIdAsBytes32);

        EnumerableSet.AddressSet storage operatorsForTokenId = _operators[
            tokenIdAsBytes32
        ];
        uint256 operatorListLength = operatorsForTokenId.length();

        if (operatorListLength == 0) {
            return address(0);
        } else {
            // Read the last added operator authorized to provide "best" compatibility.
            // In ERC721 there is one operator address at a time for a tokenId, so multiple calls to
            // `approve` would cause `getApproved` to return the last added operator. In this
            // compatibility version the same is true, when the authorized operators were not previously
            // authorized. If addresses are removed, then `getApproved` returned address can change due
            // to implementation of `EnumberableSet._remove`.
            return operatorsForTokenId.at(operatorListLength - 1);
        }
    }

    /*
     * @inheritdoc ILSP8CompatibilityForERC721
     */
    function isApprovedForAll(address tokenOwner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        // silence compiler warning about unused variable
        tokenOwner;
        operator;

        return false;
    }

    /**
     * @inheritdoc ILSP8CompatibilityForERC721
     * @dev Compatible with ERC721 transferFrom.
     * Using force=true so that EOA and any contract may receive the tokenId.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external virtual override {
        return
            transfer(from, to, bytes32(tokenId), true, "");
    }

    /**
     * @inheritdoc ILSP8CompatibilityForERC721
     * @dev Compatible with ERC721 safeTransferFrom.
     * Using force=false so that no EOA and only contracts supporting LSP1 interface may receive the tokenId.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external virtual override {
        return
            transfer(
                from,
                to,
                bytes32(tokenId),
                false,
                ""
            );
    }

    /*
     * @dev Compatible with ERC721 safeTransferFrom.
     * Using force=false so that no EOA and only contracts supporting LSP1 interface may receive the tokenId.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external virtual override {
        return transfer(from, to, bytes32(tokenId), false, data);
    }

    // --- Overrides

    function authorizeOperator(address operator, bytes32 tokenId)
        public
        virtual
        override(
            ILSP8IdentifiableDigitalAsset,
            LSP8IdentifiableDigitalAssetCore
        )
    {
        super.authorizeOperator(operator, tokenId);

        emit Approval(
            tokenOwnerOf(tokenId),
            operator,
            abi.decode(abi.encodePacked(tokenId), (uint256))
        );
    }

    function _transfer(
        address from,
        address to,
        bytes32 tokenId,
        bool force,
        bytes memory data
    ) internal virtual override {
        super._transfer(from, to, tokenId, force, data);

        emit Transfer(
            from,
            to,
            abi.decode(abi.encodePacked(tokenId), (uint256))
        );
    }

    function _mint(
        address to,
        bytes32 tokenId,
        bool force,
        bytes memory data
    ) internal virtual override {
        super._mint(to, tokenId, force, data);

        emit Transfer(
            address(0),
            to,
            abi.decode(abi.encodePacked(tokenId), (uint256))
        );
    }

    function _burn(bytes32 tokenId, bytes memory data)
        internal
        virtual
        override
    {
        address tokenOwner = tokenOwnerOf(tokenId);

        super._burn(tokenId, data);

        emit Transfer(
            tokenOwner,
            address(0),
            abi.decode(abi.encodePacked(tokenId), (uint256))
        );
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// --- ERC165 interface ids
bytes4 constant _INTERFACEID_ERC721 = 0x80ac58cd;
bytes4 constant _INTERFACEID_ERC721METADATA = 0x5b5e139f;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// modules
import "@erc725/smart-contracts/contracts/ERC725YCore.sol";

// interfaces
import "./ILSP4Compatibility.sol";

// libraries
import "../Utils/ERC725Utils.sol";

// constants
import "./LSP4Constants.sol";

/**
 * @title LSP4Compatibility
 * @author Matthew Stevens
 * @dev LSP4 extension, for compatibility with clients & tools that expect ERC20/721.
 */
abstract contract LSP4Compatibility is ILSP4Compatibility, ERC725YCore {
    // --- Token queries

    /**
     * @dev Returns the name of the token.
     * @return The name of the token
     */
    function name() public view virtual override returns (string memory) {
        bytes memory data = ERC725Utils.getDataSingle(
            this,
            _LSP4_METADATA_TOKEN_NAME_KEY
        );
        return string(data);
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the name.
     * @return The symbol of the token
     */
    function symbol() public view virtual override returns (string memory) {
        bytes memory data = ERC725Utils.getDataSingle(
            this,
            _LSP4_METADATA_TOKEN_SYMBOL_KEY
        );
        return string(data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// interfaces
import "../ILSP8IdentifiableDigitalAsset.sol";

/**
 * @dev LSP8 extension, for compatibility for clients / tools that expect ERC721.
 */
interface ILSP8CompatibilityForERC721 is ILSP8IdentifiableDigitalAsset {
    /**
     * @notice To provide compatibility with indexing ERC721 events.
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     * @param from The sending address
     * @param to The receiving address
     * @param tokenId The tokenId to transfer
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @notice To provide compatibility with indexing ERC721 events.
     * @dev Emitted when `owner` enables `approved` for `tokenId`.
     * @param owner The address of the owner of the `tokenId`
     * @param approved The address set as operator
     * @param tokenId The approved tokenId
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Compatible with ERC721 transferFrom.
     * @param from The sending address
     * @param to The receiving address
     * @param tokenId The tokenId to transfer
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Compatible with ERC721 transferFrom.
     * @param from The sending address
     * @param to The receiving address
     * @param tokenId The tokenId to transfer
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Compatible with ERC721 safeTransferFrom.
     * @param from The sending address
     * @param to The receiving address
     * @param tokenId The tokenId to transfer
     * @param data The data to be sent with the transfer
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external;

    /**
     * @dev Compatible with ERC721 ownerOf.
     * @param tokenId The tokenId to query
     * @return The owner of the tokenId
     */
    function ownerOf(uint256 tokenId) external view returns (address);

    /**
     * @dev Compatible with ERC721 approve.
     * @param operator The address to approve for `amount`
     * @param tokenId The tokenId to approve
     */
    function approve(address operator, uint256 tokenId) external;

    /**
     * @dev Compatible with ERC721 getApproved.
     * @param tokenId The tokenId to query
     * @return The address of the operator for `tokenId`
     */
    function getApproved(uint256 tokenId) external view returns (address);

    /*
     * @dev Compatible with ERC721 isApprovedForAll.
     * @param owner The tokenOwner address to query
     * @param operator The operator address to query
     * @return Returns if the `operator` is allowed to manage all of the assets of `owner`
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /*
     * @dev Compatible with ERC721Metadata tokenURI.
     * @param tokenId The tokenId to query
     * @return The token URI
     */
    function tokenURI(uint256 tokenId) external returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// interfaces
import "@erc725/smart-contracts/contracts/interfaces/IERC725Y.sol";

/**
 * @dev LSP4 extension, for compatibility with clients & tools that expect ERC20/721.
 */
interface ILSP4Compatibility is IERC725Y {
    /**
     * @dev Returns the name of the token.
     * @return The name of the token
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the name.
     * @return The symbol of the token
     */
    function symbol() external view returns (string memory);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// constants
import { OPENSEA_PROXY_NAME_HASH } from "../registry/constants.sol";

// interfaces
import "../registry/IContractRegistry.sol";

// modules
import "@lukso/universalprofile-smart-contracts/contracts/LSP8IdentifiableDigitalAsset/extensions/LSP8CompatibilityForERC721Core.sol";
import "../registry/UsesContractRegistryProxy.sol";

// NOTE: this contract allows OpenSea to be able to sell & auction tokens
//
// https://docs.opensea.io/docs/polygon-basic-integration
abstract contract OpenSeaCompatForLSP8 is
    LSP8CompatibilityForERC721Core,
    UsesContractRegistryProxy
{
    using ERC725Utils for IERC725Y;

    function contractURI() public view returns (string memory) {
        bytes memory data = IERC725Y(this).getDataSingle(_LSP4_METADATA_KEY);

        // offset = bytes4(hashSig) + bytes32(contentHash) -> 4 + 32 = 36
        uint256 offset = 36;

        bytes memory uriBytes = BytesLib.slice(
            data,
            offset,
            data.length - offset
        );
        return string(uriBytes);
    }

    // support for ERC721
    function isApprovedForAll(address tokenOwner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        if (operator == _getOpenSeaProxyAddress()) {
            return true;
        }

        return super.isApprovedForAll(tokenOwner, operator);
    }

    // support for LSP8
    function _isOperatorOrOwner(address caller, bytes32 tokenId)
        internal
        view
        virtual
        override
        returns (bool)
    {
        if (caller == _getOpenSeaProxyAddress()) {
            return true;
        }

        return super._isOperatorOrOwner(caller, tokenId);
    }

    //
    // --- Contract Registry queries
    //

    function _getOpenSeaProxyAddress() internal view returns (address) {
        return
            IContractRegistry(UsesContractRegistryProxy.contractRegistry())
                .getRegisteredContract(OPENSEA_PROXY_NAME_HASH);
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// keccak256("FeeCollector")
bytes32 constant FEE_COLLECTOR_NAME_HASH = 0xd59ed7e0cf777b70bff43b36b5e7942a53db5cdc1ed3eac0584ffe6898bb47cd;

// keccak256("CardTokenScoring")
bytes32 constant CARD_TOKEN_SCORING_NAME_HASH = 0xdffe073e73d032dfae2943de6514599be7d9b1cd7b5ff3c3cafaeafef9ce8120;

// keccak256("OpenSeaProxy")
bytes32 constant OPENSEA_PROXY_NAME_HASH = 0x0cef494da2369e60d9db5c21763fa9ba82fceb498a37b9aaa12fe66296738da9;

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

interface IContractRegistry {
    //
    // --- Registry Queries
    //

    function getRegisteredContract(bytes32 nameHash)
        external
        view
        returns (address);

    //
    // --- Registry Logic
    //

    function setRegisteredContract(bytes32 nameHash, address target) external;

    function removeRegisteredContract(bytes32 nameHash) external;

    //
    // --- Whitelist Token Queries
    //

    function isWhitelistedToken(address token) external view returns (bool);

    //
    // --- Whitelist Token Logic
    //

    function setWhitelistedToken(address token) external;

    function removeWhitelistedToken(address token) external;
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// interfaces
import "./IUsesContractRegistry.sol";

// modules
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

abstract contract UsesContractRegistryProxy is
    IUsesContractRegistry,
    Initializable
{
    //
    // --- Errors
    //

    error ContractRegistryRequired();

    //
    // --- Storage
    //

    address private _contractRegistry;

    //
    // --- Initialize
    //

    function _initializeUsesContractRegistry(address contractRegistry_)
        internal
        onlyInitializing
    {
        if (contractRegistry_ == address(0)) {
            revert ContractRegistryRequired();
        }
        _contractRegistry = contractRegistry_;
    }

    //
    // --- Queries
    //

    function contractRegistry() public view override returns (address) {
        return _contractRegistry;
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

interface IUsesContractRegistry {
    function contractRegistry() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// modules
import "@lukso/universalprofile-smart-contracts/contracts/LSP8IdentifiableDigitalAsset/LSP8IdentifiableDigitalAssetInitAbstract.sol";
import "../registry/UsesContractRegistryProxy.sol";
import "../royalties/RoyaltySharesProxy.sol";
import "../card/CardMarket.sol";

/* solhint-disable no-empty-blocks */

contract TestCardMarket is
    LSP8IdentifiableDigitalAssetInitAbstract,
    RoyaltySharesProxy,
    UsesContractRegistryProxy,
    CardMarket
{
    constructor(
        string memory name,
        string memory symbol,
        address contractRegistry,
        address[] memory creators,
        uint96[] memory creatorRoyaltyShares
    ) initializer {
        LSP8IdentifiableDigitalAssetInitAbstract.initialize(
            name,
            symbol,
            msg.sender
        );
        _initializeUsesContractRegistry(contractRegistry);
        _initializeRoyaltyShares(creators, creatorRoyaltyShares);
    }

    function mint(
        address to,
        bytes32 tokenId,
        bool force,
        bytes memory data
    ) public {
        _mint(to, tokenId, force, data);
    }

    function burn(bytes32 tokenId, bytes memory data) public {
        _burn(tokenId, data);
    }

    function _transfer(
        address from,
        address to,
        bytes32 tokenId,
        bool force,
        bytes memory data
    ) internal virtual override(LSP8IdentifiableDigitalAssetCore, CardMarket) {
        super._transfer(from, to, tokenId, force, data);
    }

    function _burn(bytes32 tokenId, bytes memory data)
        internal
        virtual
        override(LSP8IdentifiableDigitalAssetCore, CardMarket)
    {
        super._burn(tokenId, data);
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// modules
import "./LSP8IdentifiableDigitalAssetCore.sol";
import "../LSP4DigitalAssetMetadata/LSP4DigitalAssetMetadataInitAbstract.sol";

// constants
import "./LSP8Constants.sol";
import "../LSP4DigitalAssetMetadata/LSP4Constants.sol";

/**
 * @title LSP8IdentifiableDigitalAsset contract
 * @author Matthew Stevens
 * @dev Proxy Implementation of a LSP8 compliant contract.
 */
abstract contract LSP8IdentifiableDigitalAssetInitAbstract is
    LSP8IdentifiableDigitalAssetCore,
    Initializable,
    LSP4DigitalAssetMetadataInitAbstract
{
    /**
     * @notice Sets the token-Metadata and register LSP8InterfaceId
     * @param name_ The name of the token
     * @param symbol_ The symbol of the token
     * @param newOwner_ The owner of the the token-Metadata
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        address newOwner_
    ) public virtual override onlyInitializing {
        LSP4DigitalAssetMetadataInitAbstract.initialize(
            name_,
            symbol_,
            newOwner_
        );

        _registerInterface(_INTERFACEID_LSP8);
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// constants
import { FEE_SCALE } from "../royalties/constants.sol";

// libs
import "./RoyaltySharesLib.sol";

// interfaces
import "../royalties/IRoyaltyShares.sol";

// modules
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

abstract contract RoyaltySharesProxy is IRoyaltyShares, Initializable {
    //
    // --- Errors
    //

    error RoyaltySharesRoyaltiesRequired();
    error RoyaltySharesRoyaltiesSum();

    //
    // --- Storage
    //

    RoyaltySharesLib.RoyaltyShare[] private _royalties;

    //
    // --- Initialize
    //

    function _initializeRoyaltyShares(
        address[] memory receivers,
        uint96[] memory receiverRoyaltyShares
    ) internal onlyInitializing {
        if (
            receivers.length == 0 ||
            receivers.length != receiverRoyaltyShares.length
        ) {
            revert RoyaltySharesRoyaltiesRequired();
        }

        uint256 revenueShareSum;
        for (uint256 i = 0; i < receiverRoyaltyShares.length; i++) {
            revenueShareSum += receiverRoyaltyShares[i];
            _royalties.push(
                RoyaltySharesLib.RoyaltyShare({
                    receiver: receivers[i],
                    share: receiverRoyaltyShares[i]
                })
            );
        }

        if (revenueShareSum != FEE_SCALE) {
            revert RoyaltySharesRoyaltiesSum();
        }
    }

    //
    // --- Royalty Queries
    //

    function royaltyShares()
        public
        view
        override
        returns (RoyaltySharesLib.RoyaltyShare[] memory)
    {
        return _royalties;
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// constants
import { FEE_COLLECTOR_NAME_HASH } from "../registry/constants.sol";

// interfaces
import "@lukso/universalprofile-smart-contracts/contracts/LSP7DigitalAsset/extensions/ILSP7CompatibilityForERC20.sol";
import "../registry/IContractRegistry.sol";
import "../royalties/IFeeCollector.sol";
import "../royalties/IFeeCollectorRevenueShareCallback.sol";
import "./ICardMarket.sol";

// modules
import "@openzeppelin/contracts/utils/Context.sol";
import "@lukso/universalprofile-smart-contracts/contracts/LSP8IdentifiableDigitalAsset/LSP8IdentifiableDigitalAssetCore.sol";
import "../registry/UsesContractRegistryProxy.sol";
import "../royalties/RoyaltySharesProxy.sol";

abstract contract CardMarket is
    ICardMarket,
    IFeeCollectorRevenueShareCallback,
    LSP8IdentifiableDigitalAssetCore,
    RoyaltySharesProxy,
    UsesContractRegistryProxy
{
    //
    // --- Errors
    //

    error CardMarketNotTokenOwner(
        address owner,
        address operator,
        bytes32 tokenId
    );
    error CardMarketNoMarket(bytes32 tokenId);
    error CardMarketMinimumAmountRequired();
    error CardMarketTokenNotWhitelisted(address token);
    error CardMarketBuyAmountTooSmall(uint256 minimumAmount, uint256 amount);

    //
    // --- Storage
    //

    mapping(bytes32 => CardMarketState) private marketStateForTokenId;

    //
    // --- Market queries
    //

    function marketFor(bytes32 tokenId)
        public
        view
        override
        returns (CardMarketState memory)
    {
        CardMarketState storage market = marketStateForTokenId[tokenId];
        if (market.minimumAmount == 0) {
            revert CardMarketNoMarket(tokenId);
        }

        return market;
    }

    //
    // --- Market logic
    //

    function setMarketFor(
        bytes32 tokenId,
        address acceptedToken,
        uint256 minimumAmount
    ) public override {
        address tokenOwner = tokenOwnerOf(tokenId);
        address operator = _msgSender();
        if (tokenOwner != operator) {
            revert CardMarketNotTokenOwner(tokenOwner, operator, tokenId);
        }

        if (minimumAmount == 0) {
            revert CardMarketMinimumAmountRequired();
        }

        if (
            !IContractRegistry(UsesContractRegistryProxy.contractRegistry())
                .isWhitelistedToken(acceptedToken)
        ) {
            revert CardMarketTokenNotWhitelisted(acceptedToken);
        }

        marketStateForTokenId[tokenId] = CardMarketState({
            minimumAmount: minimumAmount,
            acceptedToken: acceptedToken
        });

        emit MarketSet(tokenId, acceptedToken, minimumAmount);
    }

    function removeMarketFor(bytes32 tokenId) public override {
        address tokenOwner = tokenOwnerOf(tokenId);
        address operator = _msgSender();
        if (tokenOwner != operator) {
            revert CardMarketNotTokenOwner(tokenOwner, operator, tokenId);
        }

        CardMarketState storage market = marketStateForTokenId[tokenId];
        if (market.minimumAmount == 0) {
            revert CardMarketNoMarket(tokenId);
        }

        delete marketStateForTokenId[tokenId];

        emit MarketRemove(tokenId);
    }

    function buyFromMarket(
        bytes32 tokenId,
        uint256 amount,
        address referrer
    ) public override {
        CardMarketState memory market = marketStateForTokenId[tokenId];
        if (market.minimumAmount == 0) {
            revert CardMarketNoMarket(tokenId);
        }
        if (amount < market.minimumAmount) {
            revert CardMarketBuyAmountTooSmall(market.minimumAmount, amount);
        }

        address buyer = _msgSender();
        address tokenOwner = tokenOwnerOf(tokenId);

        uint256 totalFee = IFeeCollector(_getFeeCollectorAddress())
            .shareRevenue(
                market.acceptedToken,
                amount,
                referrer,
                RoyaltySharesProxy.royaltyShares(),
                abi.encode(buyer, tokenId)
            );
        uint256 tokenOwnerAmount = amount - totalFee;

        // clear market state after shareRevenue, we need market state in revenueShareCallback
        delete marketStateForTokenId[tokenId];

        ILSP7CompatibilityForERC20(market.acceptedToken).transferFrom(
            buyer,
            tokenOwner,
            tokenOwnerAmount
        );

        _transfer(tokenOwner, buyer, tokenId, true, "");

        emit MarketBuy(tokenId, buyer, amount);
    }

    //
    // --- FeeCollectorCallback logic
    //

    function revenueShareCallback(
        uint256 totalFee,
        bytes calldata dataForCallback
    ) external override {
        address feeCollector = _getFeeCollectorAddress();

        if (msg.sender != feeCollector) {
            revert RevenueShareCallbackInvalidSender();
        }

        (address feePayer, bytes32 tokenId) = abi.decode(
            dataForCallback,
            (address, bytes32)
        );
        CardMarketState memory market = marketStateForTokenId[tokenId];

        ILSP7CompatibilityForERC20(market.acceptedToken).transferFrom(
            feePayer,
            feeCollector,
            totalFee
        );
    }

    //
    // --- Contract Registry queries
    //

    function _getFeeCollectorAddress() internal view returns (address) {
        return
            IContractRegistry(UsesContractRegistryProxy.contractRegistry())
                .getRegisteredContract(FEE_COLLECTOR_NAME_HASH);
    }

    //
    // --- Internal overrides
    //

    function _transfer(
        address from,
        address to,
        bytes32 tokenId,
        bool force,
        bytes memory data
    ) internal virtual override {
        delete marketStateForTokenId[tokenId];

        super._transfer(from, to, tokenId, force, data);
    }

    function _burn(bytes32 tokenId, bytes memory data)
        internal
        virtual
        override
    {
        delete marketStateForTokenId[tokenId];

        super._burn(tokenId, data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// modules
import "@erc725/smart-contracts/contracts/ERC725YInitAbstract.sol";

// constants
import "./LSP4Constants.sol";

/**
 * @title LSP4DigitalAssetMetadata
 * @author Matthew Stevens
 * @dev Inheritable Proxy Implementation of a LSP8 compliant contract.
 */
abstract contract LSP4DigitalAssetMetadataInitAbstract is
    Initializable,
    ERC725YInitAbstract
{
    /**
     * @notice Sets the name, symbol of the token and the owner, and sets the SupportedStandards:LSP4DigitalAsset key
     * @param name_ The name of the token
     * @param symbol_ The symbol of the token
     * @param newOwner_ The owner of the token contract
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        address newOwner_
    ) public virtual onlyInitializing {
        ERC725YInitAbstract.initialize(newOwner_);

        // set SupportedStandards:LSP4DigitalAsset
        _setData(
            _LSP4_SUPPORTED_STANDARDS_KEY,
            _LSP4_SUPPORTED_STANDARDS_VALUE
        );

        _setData(_LSP4_METADATA_TOKEN_NAME_KEY, bytes(name_));
        _setData(_LSP4_METADATA_TOKEN_SYMBOL_KEY, bytes(symbol_));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// modules
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./ERC725YCore.sol";

/**
 * @title Inheritable Proxy Implementation of ERC725 Y General key/value store
 * @author Fabian Vogelsteller <[email protected]>
 * @dev Contract module which provides the ability to set arbitrary key value sets that can be changed over time
 * It is intended to standardise certain keys value pairs to allow automated retrievals and interactions
 * from interfaces and other smart contracts
 */
abstract contract ERC725YInitAbstract is ERC725YCore, Initializable {
    /**
     * @notice Sets the owner of the contract and register ERC725Y interfaceId
     * @param _newOwner the owner of the contract
     */
    function initialize(address _newOwner) public virtual onlyInitializing {
        // This is necessary to prevent a contract that implements both ERC725X and ERC725Y to call both constructors
        if (_newOwner != owner()) {
            OwnableUnset.initOwner(_newOwner);
        }

        _registerInterface(_INTERFACEID_ERC725Y);
    }
}

// using basis points to describe fees
uint256 constant FEE_SCALE = 100_00;

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

library RoyaltySharesLib {
    struct RoyaltyShare {
        address receiver;
        // using basis points to describe shares
        uint96 share;
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// libs
import "./RoyaltySharesLib.sol";

interface IRoyaltyShares {
    //
    // --- Royalty Queries
    //

    function royaltyShares()
        external
        view
        returns (RoyaltySharesLib.RoyaltyShare[] memory royaltiesForAsset);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// interfaces
import "../ILSP7DigitalAsset.sol";

/**
 * @dev LSP8 extension, for compatibility for clients / tools that expect ERC20.
 */
interface ILSP7CompatibilityForERC20 is ILSP7DigitalAsset {
    /**
     * @notice To provide compatibility with indexing ERC20 events.
     * @dev Emitted when `amount` tokens is transferred from `from` to `to`.
     * @param from The sending address
     * @param to The receiving address
     * @param value The amount of tokens transfered.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @notice To provide compatibility with indexing ERC20 events.
     * @dev Emitted when `owner` enables `spender` for `value` tokens.
     * @param owner The account giving approval
     * @param spender The account receiving approval
     * @param value The amount of tokens `spender` has access to from `owner`
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /*
     * @dev Compatible with ERC20 transfer
     * @param to The receiving address
     * @param amount The amount of tokens to transfer
     */
    function transfer(address to, uint256 amount) external;

    /*
     * @dev Compatible with ERC20 transferFrom
     * @param from The sending address
     * @param to The receiving address
     * @param amount The amount of tokens to transfer
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external;

    /*
     * @dev Compatible with ERC20 approve
     * @param operator The address to approve for `amount`
     * @param amount The amount to approve
     */
    function approve(address operator, uint256 amount) external;

    /*
     * @dev Compatible with ERC20 allowance
     * @param tokenOwner The address of the token owner
     * @param operator The address approved by the `tokenOwner`
     * @return The amount `operator` is approved by `tokenOwner`
     */
    function allowance(address tokenOwner, address operator)
        external
        returns (uint256);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// libs
import "./RoyaltySharesLib.sol";

interface IFeeCollector {
    //
    // --- Struct
    //

    // NOTE: packed into one storage slot
    struct RevenueShareFees {
        uint16 platform;
        uint16 creator;
        uint16 referral;
    }

    //
    // --- Fee queries
    //

    function feeBalance(address receiver, address token)
        external
        view
        returns (uint256);

    function revenueShareFees() external view returns (RevenueShareFees memory);

    function baseRevenueShareFee() external view returns (uint256);

    function platformFeeReceiver() external view returns (address);

    //
    // --- Fee logic
    //

    function shareRevenue(
        address token,
        uint256 amount,
        address referrer,
        RoyaltySharesLib.RoyaltyShare[] calldata creatorRoyalties,
        bytes calldata dataForCallback
    ) external returns (uint256);

    function withdrawTokens(address[] calldata tokenList) external;

    function withdrawTokensForMany(
        address[] calldata addressList,
        address[] calldata tokenList
    ) external;
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

interface IFeeCollectorRevenueShareCallback {
    error RevenueShareCallbackInvalidSender();

    // @notice Called to `msg.sender` after FeeCollector.revenueShare is called.
    // @param totalFee The amount expected to be transfered to the FeeCollector after the callback is complete
    // @param dataForCallback The data provided when calling FeeCollector.revenueShare to process the callback
    function revenueShareCallback(
        uint256 totalFee,
        bytes memory dataForCallback
    ) external;
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface ICardMarket {
    //
    // --- Structs
    //

    struct CardMarketState {
        uint256 minimumAmount;
        address acceptedToken;
    }

    //
    // --- Events
    //

    event MarketSet(
        bytes32 indexed tokenId,
        address indexed acceptedToken,
        uint256 amount
    );

    event MarketRemove(bytes32 indexed tokenId);

    event MarketBuy(
        bytes32 indexed tokenId,
        address indexed buyer,
        uint256 amount
    );

    //
    // --- Market queries
    //

    function marketFor(bytes32 tokenId)
        external
        returns (CardMarketState memory);

    //
    // --- Market logic
    //

    function setMarketFor(
        bytes32 tokenId,
        address acceptedToken,
        uint256 minimumAmount
    ) external;

    function removeMarketFor(bytes32 tokenId) external;

    function buyFromMarket(
        bytes32 tokenId,
        uint256 amount,
        address referrer
    ) external;
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/**
 * FANZONE.io NFT implementation of the LUKSO LSP-8-IdentifiableDigitalAsset standard
 * for more see https://fanzone.io/nfts
 */

// constants
import { CARD_TOKEN_SCORING_NAME_HASH } from "../registry/constants.sol";

// libs
import "../royalties/RoyaltySharesLib.sol";

// interfaces
import "../registry/IContractRegistry.sol";
import "./ICardTokenScoring.sol";
import "./ICardToken.sol";
import "./ICardTokenProxy.sol";

// modules
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@lukso/universalprofile-smart-contracts/contracts/LSP8IdentifiableDigitalAsset/extensions/LSP8CappedSupplyInitAbstract.sol";
import "@lukso/universalprofile-smart-contracts/contracts/LSP8IdentifiableDigitalAsset/extensions/LSP8CompatibilityForERC721InitAbstract.sol";
import "../lsp/LSP8Metadata.sol";
import "../lsp/OpenSeaCompatForLSP8.sol";
import "../registry/UsesContractRegistryProxy.sol";
import "../royalties/RoyaltySharesProxy.sol";
import "./CardMarket.sol";
// TODO: remove me one day soon
import "../lsp/TemporaryLSP4Compatability.sol";

contract CardTokenProxy is
    ICardToken,
    ICardTokenProxy,
    Initializable,
    Pausable,
    LSP8CompatibilityForERC721InitAbstract,
    LSP8CappedSupplyInitAbstract,
    LSP8Metadata,
    RoyaltySharesProxy,
    UsesContractRegistryProxy,
    TemporaryLSP4Compatability,
    CardMarket,
    OpenSeaCompatForLSP8
{
    //
    // --- Storage
    //

    // TODO: could pack score values together to save some gas on initialize
    uint256 private _scoreMin;
    uint256 private _scoreMax;
    uint256 private _scoreScale;
    uint256 private _scoreMaxTokenId;

    //
    // --- Errors
    //

    error CardTokenScoreRange();
    error CardTokenScoreScaleZero();
    error CardTokenScoreMaxTokenIdZero();
    error CardTokenScoreMaxTokenIdLargerThanSupplyCap();
    error CardTokenInvalidTokenId(bytes32 tokenId);

    //
    // --- Modifiers
    //

    modifier onlyValidTokenId(bytes32 tokenId) {
        _onlyValidTokenId(tokenId);

        _;
    }

    function _onlyValidTokenId(bytes32 tokenId) internal view {
        uint256 tokenIdAsNumber = uint256(tokenId);

        if (tokenIdAsNumber == 0 || tokenIdAsNumber > tokenSupplyCap()) {
            revert CardTokenInvalidTokenId(tokenId);
        }
    }

    //
    // --- Initialize
    //

    // solhint-disable-next-line no-empty-blocks
    constructor() initializer {
        // when the base logic contract is deployed, the initialized flag should get set so its not
        // possible to call `initialize(...)`
    }

    function initialize(
        address owner,
        string memory name,
        string memory symbol,
        address contractRegistry,
        address[] memory creators,
        uint96[] memory creatorRoyaltyShares,
        uint256 tokenSupplyCap,
        uint256 scoreMin,
        uint256 scoreMax,
        uint256 scoreScale,
        uint256 scoreMaxTokenId
    ) public override initializer {
        LSP8CompatibilityForERC721InitAbstract.initialize(name, symbol, owner);
        LSP8CappedSupplyInitAbstract.initialize(tokenSupplyCap);
        _initializeUsesContractRegistry(contractRegistry);
        _initializeRoyaltyShares(creators, creatorRoyaltyShares);

        if (scoreMin > scoreMax) {
            revert CardTokenScoreRange();
        }
        _scoreMin = scoreMin;
        _scoreMax = scoreMax;

        if (scoreScale == 0) {
            revert CardTokenScoreScaleZero();
        }
        _scoreScale = scoreScale;

        if (scoreMaxTokenId == 0) {
            revert CardTokenScoreMaxTokenIdZero();
        }
        if (scoreMaxTokenId > tokenSupplyCap) {
            revert CardTokenScoreMaxTokenIdLargerThanSupplyCap();
        }
        _scoreMaxTokenId = scoreMaxTokenId;
    }

    //
    // --- Token queries
    //

    /**
     * @dev Returns the number of tokens available to be minted.
     */
    function mintableSupply() public view override returns (uint256) {
        return tokenSupplyCap() - totalSupply();
    }

    //
    // --- TokenId queries
    //

    /**
     * @dev Returns the score for a given `tokenId`.
     */
    function calculateScore(bytes32 tokenId)
        public
        view
        override
        onlyValidTokenId(tokenId)
        returns (string memory)
    {
        uint256 tokenIdAsNumber = uint256(tokenId);

        return
            ICardTokenScoring(_getCardTokenScoringAddress()).calculateScore(
                tokenSupplyCap(),
                _scoreMin,
                _scoreMax,
                _scoreScale,
                _scoreMaxTokenId,
                tokenIdAsNumber
            );
    }

    //
    // --- Unpacking logic
    //

    /**
     * @dev Mints a `tokenId` to `to`.
     *
     * Returns the `mintableSupply` for the caller to know when it is no longer available for unpack
     * requests.
     *
     * Requirements:
     *
     * - `mintableSupply()` must be greater than zero.
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function unpackCard(address to, bytes32 tokenId)
        public
        override
        onlyOwner
        onlyValidTokenId(tokenId)
        returns (uint256)
    {
        // TODO(future version): eventually this function should be called from a CardManager contract for better
        // control of unpacking on-chain and visibility when creating new cards; instead of onlyOwner
        // modifier we might want a different access control pattern

        // using force=true to allow minting a token to an EOA or contract that isnt an UniversalProfile
        _mint(to, tokenId, true, "");

        // inform the caller about mintable supply
        return mintableSupply();
    }

    //
    // --- Pause logic
    //

    function pause() public onlyOwner {
        _pause();
    }

    //
    // --- Metadata logic
    //

    /*
     * @dev Creates a metadata contract (ERC725Y) for `tokenId`.
     *
     * Returns the created contract address.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function createMetadataFor(bytes32 tokenId)
        public
        override
        onlyOwner
        onlyValidTokenId(tokenId)
        whenNotPaused
        returns (address)
    {
        _existsOrError(tokenId);

        // TODO(future version): eventually this function could be called from a CardManager contract for better
        // control over all deployed CardTokens; instead of onlyOwner modifier we might want a
        // different access control pattern

        return _createMetadataFor(tokenId);
    }

    //
    // --- Contract Registry queries
    //

    function _getCardTokenScoringAddress() internal view returns (address) {
        return
            IContractRegistry(UsesContractRegistryProxy.contractRegistry())
                .getRegisteredContract(CARD_TOKEN_SCORING_NAME_HASH);
    }

    //
    // --- Public override
    //

    // TODO: we shouldnt need to do this.. instead each initialize function should have unique name
    // so we dont have function selector collision (ie. __LSP8IdentifiableDigitalAsset_initialize)
    function initialize(
        string memory name_,
        string memory symbol_,
        address newOwner_
    )
        public
        virtual
        override(
            LSP8IdentifiableDigitalAssetInit,
            LSP8CompatibilityForERC721InitAbstract
        )
    {
        super.initialize(name_, symbol_, newOwner_);
    }

    function authorizeOperator(address operator, bytes32 tokenId)
        public
        virtual
        override(
            ILSP8IdentifiableDigitalAsset,
            LSP8IdentifiableDigitalAssetCore,
            LSP8CompatibilityForERC721Core,
            LSP8CompatibilityForERC721InitAbstract
        )
    {
        super.authorizeOperator(operator, tokenId);
    }

    /**
     * @inheritdoc ILSP8CompatibilityForERC721
     * @dev Compatible with ERC721 safeTransferFrom.
     * Using force=true so that any address may receive the tokenId.
     * Change added to support transfer on third-party platforms (ex: OpenSea)
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external virtual override {
        return transfer(from, to, bytes32(tokenId), true, "");
    }

    /**
     * @inheritdoc ILSP8CompatibilityForERC721
     * @dev Compatible with ERC721 safeTransferFrom.
     * Using force=true so that any address may receive the tokenId.
     * Change added to support transfer on third-party platforms (ex: OpenSea)
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external virtual override {
        return transfer(from, to, bytes32(tokenId), true, data);
    }

    function isApprovedForAll(address tokenOwner, address operator)
        public
        view
        virtual
        override(LSP8CompatibilityForERC721Core, OpenSeaCompatForLSP8)
        returns (bool)
    {
        return super.isApprovedForAll(tokenOwner, operator);
    }

    //
    // --- Internal override
    //

    function _transfer(
        address from,
        address to,
        bytes32 tokenId,
        bool force,
        bytes memory data
    )
        internal
        virtual
        override(
            LSP8IdentifiableDigitalAssetCore,
            LSP8CompatibilityForERC721Core,
            LSP8CompatibilityForERC721InitAbstract,
            CardMarket,
            TemporaryLSP4Compatability
        )
        whenNotPaused
    {
        super._transfer(from, to, tokenId, force, data);
    }

    function _mint(
        address to,
        bytes32 tokenId,
        bool force,
        bytes memory data
    )
        internal
        virtual
        override(
            LSP8IdentifiableDigitalAssetCore,
            LSP8CompatibilityForERC721Core,
            LSP8CompatibilityForERC721InitAbstract,
            LSP8CappedSupplyInitAbstract,
            TemporaryLSP4Compatability
        )
        whenNotPaused
    {
        super._mint(to, tokenId, force, data);
    }

    function _burn(bytes32 tokenId, bytes memory data)
        internal
        virtual
        override(
            LSP8IdentifiableDigitalAssetCore,
            LSP8CompatibilityForERC721Core,
            LSP8CompatibilityForERC721InitAbstract,
            CardMarket
        )
        whenNotPaused
    {
        super._burn(tokenId, data);
    }

    function _isOperatorOrOwner(address caller, bytes32 tokenId)
        internal
        view
        virtual
        override(LSP8IdentifiableDigitalAssetCore, OpenSeaCompatForLSP8)
        returns (bool)
    {
        return super._isOperatorOrOwner(caller, tokenId);
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

interface ICardTokenScoring {
    function calculateScore(
        uint256 tokenSupply,
        uint256 scoreMin,
        uint256 scoreMax,
        uint256 scoreScale,
        uint256 scoreMaxTokenId,
        uint256 tokenId
    ) external pure returns (string memory);
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface ICardToken {
    //
    // --- Token queries
    //

    /**
     * @dev Returns the number of tokens available to be minted.
     */
    function mintableSupply() external view returns (uint256);

    //
    // --- TokenId queries
    //

    /**
     * @dev Returns the score for a given `tokenId`.
     */
    function calculateScore(bytes32 tokenId) external returns (string memory);

    //
    // --- Unpacking logic
    //

    /**
     * @dev Mints a `tokenId` and transfers it to `to`.
     *
     * Returns the `mintableSupply` for the caller to know when it is no longer available for unpack
     * requests.
     *
     * Requirements:
     *
     * - `mintableSupply()` must be greater than zero.
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function unpackCard(address to, bytes32 tokenId) external returns (uint256);

    //
    // --- Owner logic
    //

    /*
     * @dev Creates a metadata contract (ERC725Y) for `tokenId`.
     *
     * Returns the created contract address.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function createMetadataFor(bytes32 tokenId) external returns (address);
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface ICardTokenProxy {
    function initialize(
        address owner,
        string memory name,
        string memory symbol,
        address contractRegistry,
        address[] memory creators,
        uint96[] memory creatorRoyaltyShares,
        uint256 tokenSupplyCap,
        uint256 scoreMin,
        uint256 scoreMax,
        uint256 scoreScale,
        uint256 scoreMaxTokenId
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// modules
import "./LSP8CappedSupplyCore.sol";
import "../LSP8IdentifiableDigitalAssetInit.sol";

/**
 * @dev LSP8 extension, adds token supply cap.
 */
abstract contract LSP8CappedSupplyInitAbstract is
    Initializable,
    LSP8CappedSupplyCore,
    LSP8IdentifiableDigitalAssetInit
{
    /**
     * @notice Sets the token max supply
     * @param tokenSupplyCap_ The Token max supply
     */
    function initialize(uint256 tokenSupplyCap_)
        public
        virtual
        onlyInitializing
    {
        if (tokenSupplyCap_ == 0) {
            revert LSP8CappedSupplyRequired();
        }

        _tokenSupplyCap = tokenSupplyCap_;
    }

    // --- Overrides

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenSupplyCap() - totalSupply()` must be greater than zero.
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        address to,
        bytes32 tokenId,
        bool force,
        bytes memory data
    )
        internal
        virtual
        override(LSP8IdentifiableDigitalAssetCore, LSP8CappedSupplyCore)
    {
        super._mint(to, tokenId, force, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// modules
import "./LSP8CompatibilityForERC721Core.sol";
import "../LSP8IdentifiableDigitalAssetInitAbstract.sol";

// constants
import "./LSP8CompatibilityConstants.sol";

/**
 * @dev LSP8 extension, for compatibility for clients / tools that expect ERC721.
 */
contract LSP8CompatibilityForERC721InitAbstract is
    LSP8CompatibilityForERC721Core,
    LSP8IdentifiableDigitalAssetInitAbstract
{
    /**
     * @notice Sets the name, the symbol and the owner of the token
     * @param name_ The name of the token
     * @param symbol_ The symbol of the token
     * @param newOwner_ The owner of the token
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        address newOwner_
    ) public virtual override onlyInitializing {
        LSP8IdentifiableDigitalAssetInitAbstract.initialize(name_, symbol_, newOwner_);

        _registerInterface(_INTERFACEID_ERC721);
        _registerInterface(_INTERFACEID_ERC721METADATA);
    }

    function authorizeOperator(address operator, bytes32 tokenId)
        public
        virtual
        override(
            LSP8IdentifiableDigitalAssetCore,
            LSP8CompatibilityForERC721Core
        )
    {
        super.authorizeOperator(operator, tokenId);
    }

    function _transfer(
        address from,
        address to,
        bytes32 tokenId,
        bool force,
        bytes memory data
    )
        internal
        virtual
        override(
            LSP8IdentifiableDigitalAssetCore,
            LSP8CompatibilityForERC721Core
        )
    {
        super._transfer(from, to, tokenId, force, data);
    }

    function _mint(
        address to,
        bytes32 tokenId,
        bool force,
        bytes memory data
    )
        internal
        virtual
        override(
            LSP8IdentifiableDigitalAssetCore,
            LSP8CompatibilityForERC721Core
        )
    {
        super._mint(to, tokenId, force, data);
    }

    function _burn(bytes32 tokenId, bytes memory data)
        internal
        virtual
        override(
            LSP8IdentifiableDigitalAssetCore,
            LSP8CompatibilityForERC721Core
        )
    {
        super._burn(tokenId, data);
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// libraries
import "@lukso/universalprofile-smart-contracts/contracts/Utils/ERC725Utils.sol";

// modules
import "@lukso/universalprofile-smart-contracts/contracts/LSP8IdentifiableDigitalAsset/LSP8IdentifiableDigitalAssetCore.sol";
import "@erc725/smart-contracts/contracts/ERC725YCore.sol";

// TODO: this should be in
// "@lukso/universalprofile-smart-contracts/contracts/LSP8IdentifiableDigitalAsset/extensions"

abstract contract LSP8Metadata is
    LSP8IdentifiableDigitalAssetCore,
    ERC725YCore
{
    //
    // --- Metadata queries
    //

    event MetadataAddressCreated(
        bytes32 indexed tokenId,
        address metadataAddress
    );

    function metadataAddressOf(bytes32 tokenId) public view returns (address) {
        require(
            _exists(tokenId),
            "LSP8Metadata: metadata query for nonexistent token"
        );

        bytes memory value = ERC725Utils.getDataSingle(
            this,
            _buildMetadataKey(tokenId, true)
        );

        if (value.length == 0) {
            return address(0);
        } else {
            return address(bytes20(value));
        }
    }

    function metadataJsonOf(bytes32 tokenId)
        public
        view
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "LSP8Metadata: metadata query for nonexistent token"
        );

        bytes memory value = ERC725Utils.getDataSingle(
            this,
            _buildMetadataKey(tokenId, false)
        );

        return abi.decode(value, (string));
    }

    function _buildMetadataKey(bytes32 tokenId, bool buildAddressKey)
        internal
        pure
        returns (bytes32)
    {
        return
            bytes32(
                abi.encodePacked(
                    buildAddressKey
                        ? _LSP8_METADATA_ADDRESS_KEY_PREFIX
                        : _LSP8_METADATA_JSON_KEY_PREFIX,
                    bytes20(keccak256(abi.encodePacked(tokenId)))
                )
            );
    }

    //
    // --- Metadata functionality
    //

    /**
     * @dev Create a ERC725Y contract to be used for metadata storage of `tokenId`.
     */
    function _createMetadataFor(bytes32 tokenId)
        internal
        virtual
        returns (address)
    {
        require(
            _exists(tokenId),
            "LSP8: metadata creation for nonexistent token"
        );

        bytes32 metadataKeyForTokenId = _buildMetadataKey(tokenId, true);

        bytes memory existingMetadataValue = _getData(metadataKeyForTokenId);
        if (existingMetadataValue.length > 0) {
            address existingMetadataAddress = address(
                bytes20(existingMetadataValue)
            );
            return existingMetadataAddress;
        }

        // TODO: can use a proxy pattern here / have a factory registed in ContractRegistry
        //
        // NOTE: the owner for the ERC725Y will be the current owner of the CardToken. If the owner
        // for CardToken ever changes, all metadata contracts could also have their owner changed..
        address metadataAddress = address(new ERC725Y(_msgSender()));
        _setData(metadataKeyForTokenId, abi.encodePacked(metadataAddress));

        emit MetadataAddressCreated(tokenId, metadataAddress);

        return metadataAddress;
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

//
// --- This file contains temporary code to support the change from old LSP4DigitalCertificate
//

import "@lukso/universalprofile-smart-contracts/contracts/LSP8IdentifiableDigitalAsset/LSP8IdentifiableDigitalAssetCore.sol";

// TODO: only here to satisfy current client expectation that token holders can be discovered
// directly from the contract (this is a leftover from LSP4DigitalCertificate)
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

abstract contract TemporaryLSP4Compatability is
    LSP8IdentifiableDigitalAssetCore
{
    //
    // --- Storage
    //

    // TODO: only here to satisfy current client expectation that token holders can be discovered
    // directly from the contract (this is a leftover from LSP4DigitalCertificate)
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _tokenHolders;

    //
    // --- Queries
    //

    /**
     * @dev Returns a bytes32 array of all token holder addresses
     */
    function allTokenHolders() public view returns (bytes32[] memory) {
        // TODO: only here to satisfy current client expectation that token holders can be discovered
        // directly from the contract (this is a leftover from LSP4DigitalCertificate)
        return _tokenHolders._inner._values;
    }

    //
    // --- Overrides
    //

    function _transfer(
        address from,
        address to,
        bytes32 tokenId,
        bool force,
        bytes memory data
    ) internal virtual override {
        super._transfer(from, to, tokenId, force, data);

        // TODO: only here to satisfy current client expectation that token holders can be discovered
        // directly from the contract (this is a leftover from LSP4DigitalCertificate)
        _tokenHolders.add(to);
        if (balanceOf(from) == 0) {
            _tokenHolders.remove(from);
        }
    }

    function _mint(
        address to,
        bytes32 tokenId,
        bool force,
        bytes memory data
    ) internal virtual override {
        super._mint(to, tokenId, force, data);

        // TODO: only here to satisfy current client expectation that token holders can be discovered
        // directly from the contract (this is a leftover from LSP4DigitalCertificate)
        _tokenHolders.add(to);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// modules
import "../LSP8IdentifiableDigitalAssetCore.sol";

// interfaces
import "./ILSP8CappedSupply.sol";

/**
 * @dev LSP8 extension, adds token supply cap.
 */
abstract contract LSP8CappedSupplyCore is
    ILSP8CappedSupply,
    LSP8IdentifiableDigitalAssetCore
{
    // --- Errors

    error LSP8CappedSupplyRequired();
    error LSP8CappedSupplyCannotMintOverCap();

    // --- Storage

    uint256 internal _tokenSupplyCap;

    // --- Token queries

    /**
     * @inheritdoc ILSP8CappedSupply
     */
    function tokenSupplyCap() public view virtual override returns (uint256) {
        return _tokenSupplyCap;
    }

    // --- Transfer functionality

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenSupplyCap() - totalSupply()` must be greater than zero.
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        address to,
        bytes32 tokenId,
        bool force,
        bytes memory data
    ) internal virtual override {
        if (totalSupply() + 1 > tokenSupplyCap()) {
            revert LSP8CappedSupplyCannotMintOverCap();
        }

        super._mint(to, tokenId, force, data);
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// modules
import "./LSP8IdentifiableDigitalAssetInitAbstract.sol";

/**
 * @title LSP8IdentifiableDigitalAsset contract
 * @author Matthew Stevens
 * @dev Proxy Implementation of a LSP8 compliant contract.
 */
contract LSP8IdentifiableDigitalAssetInit is
    LSP8IdentifiableDigitalAssetInitAbstract
{
    /**
     * @inheritdoc LSP8IdentifiableDigitalAssetInitAbstract
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        address newOwner_
    ) public virtual override initializer {
        LSP8IdentifiableDigitalAssetInitAbstract.initialize(
            name_,
            symbol_,
            newOwner_
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// interfaces
import "../ILSP8IdentifiableDigitalAsset.sol";

/**
 * @dev LSP8 extension, adds token supply cap.
 */
interface ILSP8CappedSupply is ILSP8IdentifiableDigitalAsset {
    /**
     * @dev Returns the number of tokens that can be minted.
     * @return The token max supply
     */
    function tokenSupplyCap() external view returns (uint256);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// libs
import "@openzeppelin/contracts/proxy/Clones.sol";

// interfaces
import "./ICardTokenProxy.sol";

// modules
import "@openzeppelin/contracts/access/Ownable.sol";
import "./CardTokenProxy.sol";

contract CardTokenProxyFactory is Ownable {
    //
    // --- Errors
    //

    error CardTokenProxyFactoryImplementationRequired();

    //
    // --- Storage
    //

    address public implementation;

    constructor() {
        implementation = address(new CardTokenProxy());

        if (implementation == address(0)) {
            revert CardTokenProxyFactoryImplementationRequired();
        }
    }

    function deployProxy(
        bytes32 salt,
        string memory name,
        string memory symbol,
        address contractRegistry,
        address[] memory creators,
        uint96[] memory creatorRoyaltyShares,
        uint256 tokenSupplyCap,
        uint256 scoreMin,
        uint256 scoreMax,
        uint256 scoreScale,
        uint256 scoreMaxTokenId
    ) public onlyOwner returns (address) {
        address clone = Clones.cloneDeterministic(implementation, salt);
        ICardTokenProxy(clone).initialize(
            msg.sender,
            name,
            symbol,
            contractRegistry,
            creators,
            creatorRoyaltyShares,
            tokenSupplyCap,
            scoreMin,
            scoreMax,
            scoreScale,
            scoreMaxTokenId
        );

        return clone;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
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

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// libs
import "@openzeppelin/contracts/proxy/Clones.sol";

// interfaces
import "./IFeeReceiverProxy.sol";

// modules
import "@openzeppelin/contracts/access/Ownable.sol";
import "./FeeReceiverProxy.sol";

contract FeeReceiverProxyFactory is Ownable {
    //
    // --- Errors
    //

    error FeeReceiverProxyFactoryImplementationRequired();

    //
    // --- Storage
    //

    address public implementation;

    constructor() {
        implementation = address(new FeeReceiverProxy());

        if (implementation == address(0)) {
            revert FeeReceiverProxyFactoryImplementationRequired();
        }
    }

    function deployProxy(
        bytes32 salt,
        address cardToken,
        address contractRegistry
    ) public onlyOwner returns (address) {
        address clone = Clones.cloneDeterministic(implementation, salt);
        IFeeReceiverProxy(clone).initialize(cardToken, contractRegistry);

        return clone;
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface IFeeReceiverProxy {
    function initialize(address cardToken, address contractRegistry) external;
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// constants
import { FEE_SCALE } from "./constants.sol";
import { FEE_COLLECTOR_NAME_HASH } from "../registry/constants.sol";

// libs
import "../royalties/RoyaltySharesLib.sol";

// interfaces
import "@lukso/universalprofile-smart-contracts/contracts/LSP7DigitalAsset/extensions/ILSP7CompatibilityForERC20.sol";
import "../registry/IContractRegistry.sol";
import "./IFeeReceiverProxy.sol";
import "./IFeeCollector.sol";
import "./IFeeCollectorRevenueShareCallback.sol";
import "./IRoyaltyShares.sol";

// modules
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract FeeReceiverProxy is
    IFeeReceiverProxy,
    IFeeCollectorRevenueShareCallback,
    Initializable
{
    //
    // --- Storage
    //

    address public cardToken;
    address public contractRegistry;

    //
    // --- Initialize
    //

    // solhint-disable-next-line no-empty-blocks
    constructor() initializer {
        // when the base logic contract is deployed, the initialized flag should get set so its not
        // possible to call `initialize(...)`
    }

    function initialize(address _cardToken, address _contractRegistry)
        public
        override
        initializer
    {
        cardToken = _cardToken;
        contractRegistry = _contractRegistry;
    }

    //
    // --- OpenSea support for FeeCollector logic
    //
    
    function shareRevenueToFeeCollector(address[] calldata feeTokenList)
        public
    {
        for (uint256 i = 0; i < feeTokenList.length; i++) {
            address token = feeTokenList[i];
            _shareRevenue(token);
        }
    }

    function _shareRevenue(address feeToken) internal {
        RoyaltySharesLib.RoyaltyShare[]
            memory creatorRoyalties = IRoyaltyShares(cardToken).royaltyShares();

        uint256 balance;
        if (feeToken == address(0)) {
            balance = address(this).balance;
        } else {
            balance = ILSP7CompatibilityForERC20(feeToken).balanceOf(
                address(this)
            );
        }

        IFeeCollector feeCollector = IFeeCollector(_getFeeCollectorAddress());

        uint256 baseRevenueShareFee = feeCollector.baseRevenueShareFee();
        uint256 amount = (balance * FEE_SCALE) / baseRevenueShareFee;

        feeCollector.shareRevenue(
            feeToken,
            amount,
            address(0),
            creatorRoyalties,
            abi.encode(feeToken, balance)
        );
    }

    function _transferFeesToCollector(
        address feeCollector,
        address feeToken,
        uint256 feeAmount
    ) internal {
        if (feeToken == address(0)) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = payable(feeCollector).call{ value: feeAmount }(
                ""
            );
            require(success, "FeeReceiverProxy: transfer failed");
        } else {
            ILSP7CompatibilityForERC20(feeToken).transfer(
                feeCollector,
                feeAmount
            );
        }
    }

    //
    // --- FeeCollectorCallback logic
    //

    function revenueShareCallback(
        uint256 baseFee,
        bytes calldata dataForCallback
    ) external override(IFeeCollectorRevenueShareCallback) {
        address feeCollector = _getFeeCollectorAddress();

        if (msg.sender != feeCollector) {
            revert RevenueShareCallbackInvalidSender();
        }

        (address feeToken, uint256 balance) = abi.decode(
            dataForCallback,
            (address, uint256)
        );

        // NOTE: sending `balance` instead of `baseFee` as we want to always drain to 0 and not leave
        // any dust
        baseFee;
        _transferFeesToCollector(feeCollector, feeToken, balance);
    }

    //
    // --- Contract Registry queries
    //

    function _getFeeCollectorAddress() internal view returns (address) {
        return
            IContractRegistry(contractRegistry).getRegisteredContract(
                FEE_COLLECTOR_NAME_HASH
            );
    }

    //
    // --- Fallbacks
    //

    // solhint-disable-next-line no-empty-blocks
    fallback() external payable {}

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// modules
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./ERC725XCore.sol";

/**
 * @title Inheritable Proxy Implementation of ERC725 X Executor
 * @author Fabian Vogelsteller <[email protected]>
 * @dev Implementation of a contract module which provides the ability to call arbitrary functions at any other smart contract and itself,
 * including using `delegatecall`, `staticcall` as well creating contracts using `create` and `create2`
 * This is the basis for a smart contract based account system, but could also be used as a proxy account system
 */
abstract contract ERC725XInitAbstract is ERC725XCore, Initializable {
    /**
     * @notice Sets the owner of the contract and register ERC725X interfaceId
     * @param _newOwner the owner of the contract
     */
    function initialize(address _newOwner) public virtual onlyInitializing {
        // This is necessary to prevent a contract that implements both ERC725X and ERC725Y to call both constructors
        if (_newOwner != owner()) {
            OwnableUnset.initOwner(_newOwner);
        }

        _registerInterface(_INTERFACEID_ERC725X);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// constants
import "./constants.sol";

// interfaces
import "./interfaces/IERC725X.sol";

// libraries
import "@openzeppelin/contracts/utils/Create2.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";

// modules
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "./utils/OwnableUnset.sol";

/**
 * @title Core implementation of ERC725 X executor
 * @author Fabian Vogelsteller <[email protected]>
 * @dev Implementation of a contract module which provides the ability to call arbitrary functions at any other smart contract and itself,
 * including using `delegatecall`, `staticcall` as well creating contracts using `create` and `create2`
 * This is the basis for a smart contract based account system, but could also be used as a proxy account system
 */
abstract contract ERC725XCore is OwnableUnset, ERC165Storage, IERC725X {
    /* Public functions */

    /**
     * @inheritdoc IERC725X
     */
    function execute(
        uint256 _operation,
        address _to,
        uint256 _value,
        bytes calldata _data
    ) public payable virtual override onlyOwner returns (bytes memory result) {
        uint256 txGas = gasleft();

        // prettier-ignore

        // CALL
        if (_operation == OPERATION_CALL) {
            result = executeCall(_to, _value, _data, txGas);

            emit Executed(_operation, _to, _value, _data);

        // STATICCALL
        } else if (_operation == OPERATION_STATICCALL) {
            result = executeStaticCall(_to, _data, txGas);

            emit Executed(_operation, _to, _value, _data);

        // DELEGATECALL
        } else if (_operation == OPERATION_DELEGATECALL) {
            address currentOwner = owner();
            result = executeDelegateCall(_to, _data, txGas);
            
            emit Executed(_operation, _to, _value, _data);

            require(owner() == currentOwner, "Delegate call is not allowed to modify the owner!");

        // CREATE
        } else if (_operation == OPERATION_CREATE) {
            address contractAddress = performCreate(_value, _data);
            result = abi.encodePacked(contractAddress);

            emit ContractCreated(_operation, contractAddress, _value);

        // CREATE2
        } else if (_operation == OPERATION_CREATE2) {
            bytes32 salt = BytesLib.toBytes32(_data, _data.length - 32);
            bytes memory data = BytesLib.slice(_data, 0, _data.length - 32);

            address contractAddress = Create2.deploy(_value, salt, data);
            result = abi.encodePacked(contractAddress);

            emit ContractCreated(_operation, contractAddress, _value);
    
        } else {
            revert("Wrong operation type");
        }
    }

    /* Internal functions */

    /**
     * @dev perform staticcall using operation 3
     * Taken from GnosisSafe: https://github.com/gnosis/safe-contracts/blob/main/contracts/base/Executor.sol
     *
     * @param to The address on which staticcall is executed
     * @param value The value to be sent with the call
     * @param data The data to be sent with the call
     * @param txGas The amount of gas for performing staticcall
     * @return The data from the call
     */
    function executeCall(
        address to,
        uint256 value,
        bytes memory data,
        uint256 txGas
    ) internal returns (bytes memory) {
        // solhint-disable avoid-low-level-calls
        (bool success, bytes memory result) = to.call{gas: txGas, value: value}(data);

        if (!success) {
            // solhint-disable reason-string
            if (result.length < 68) revert();

            // solhint-disable no-inline-assembly
            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }

        return result;
    }

    /**
     * @dev perform staticcall using operation 3
     * @param to The address on which staticcall is executed
     * @param data The data to be sent with the call
     * @param txGas The amount of gas for performing staticcall
     * @return The data from the call
     */
    function executeStaticCall(
        address to,
        bytes memory data,
        uint256 txGas
    ) internal view returns (bytes memory) {
        (bool success, bytes memory result) = to.staticcall{gas: txGas}(data);

        if (!success) {
            // solhint-disable reason-string
            if (result.length < 68) revert();

            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }

        return result;
    }

    /**
     * @dev perform delegatecall using operation 4
     * Taken from GnosisSafe: https://github.com/gnosis/safe-contracts/blob/main/contracts/base/Executor.sol
     *
     * @param to The address on which delegatecall is executed
     * @param data The data to be sent with the call
     * @param txGas The amount of gas for performing delegatecall
     * @return The data from the call
     */
    function executeDelegateCall(
        address to,
        bytes memory data,
        uint256 txGas
    ) internal returns (bytes memory) {
        // solhint-disable avoid-low-level-calls
        (bool success, bytes memory result) = to.delegatecall{gas: txGas}(data);

        if (!success) {
            // solhint-disable reason-string
            if (result.length < 68) revert();

            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }

        return result;
    }

    /**
     * @dev perform contract creation using operation 1
     * Taken from GnosisSafe: https://github.com/gnosis/safe-contracts/blob/main/contracts/libraries/CreateCall.sol
     *
     * @param value The value to be sent to the contract created
     * @param deploymentData The contract bytecode to deploy
     * @return newContract The address of the contract created
     */
    function performCreate(uint256 value, bytes memory deploymentData)
        internal
        returns (address newContract)
    {
        assembly {
            newContract := create(value, add(deploymentData, 0x20), mload(deploymentData))
        }

        require(newContract != address(0), "Could not deploy contract");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
        return address(uint160(uint256(_data)));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// interfaces
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "../LSP1UniversalReceiver/ILSP1UniversalReceiver.sol";
import "../LSP1UniversalReceiver/ILSP1UniversalReceiverDelegate.sol";

// modules

import "@erc725/smart-contracts/contracts/ERC725YCore.sol";
import "@erc725/smart-contracts/contracts/ERC725XCore.sol";

// libraries
import "../Utils/UtilsLib.sol";
import "../Utils/ERC725Utils.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// constants
import "../LSP1UniversalReceiver/LSP1Constants.sol";
import "../LSP0ERC725Account/LSP0Constants.sol";

/**
 * @title Core Implementation of ERC725Account
 * @author Fabian Vogelsteller <[email protected]>, Jean Cavallera (CJ42), Yamen Merhi (YamenMerhi)
 * @dev Bundles ERC725X and ERC725Y, ERC1271 and LSP1UniversalReceiver and allows receiving native tokens
 */
abstract contract LSP0ERC725AccountCore is
    IERC1271,
    ILSP1UniversalReceiver,
    ERC725XCore,
    ERC725YCore
{
    using ERC725Utils for IERC725Y;

    event ValueReceived(address indexed sender, uint256 indexed value);

    receive() external payable {
        emit ValueReceived(_msgSender(), msg.value);
    }

    //    TODO to be discussed
    //    function fallback()
    //    public
    //    {
    //        address to = owner();
    //        assembly {
    //            calldatacopy(0, 0, calldatasize())
    //            let result := staticcall(gas(), to, 0, calldatasize(), 0, 0)
    //            returndatacopy(0, 0, returndatasize())
    //            switch result
    //            case 0  { revert (0, returndatasize()) }
    //            default { return (0, returndatasize()) }
    //        }
    //    }

    /**
     * @notice Checks if an owner signed `_data`.
     * ERC1271 interface.
     *
     * @param _hash hash of the data signed//Arbitrary length data signed on the behalf of address(this)
     * @param _signature owner's signature(s) of the data
     */
    function isValidSignature(bytes32 _hash, bytes memory _signature)
        public
        view
        override
        returns (bytes4 magicValue)
    {
        // prettier-ignore
        // if OWNER is a contract
        if (UtilsLib.isContract(owner())) {
            return 
                supportsInterface(_INTERFACE_ID_ERC1271)
                    ? IERC1271(owner()).isValidSignature(_hash, _signature)
                    : _ERC1271FAILVALUE;
        // if OWNER is a key
        } else {
            return 
                owner() == ECDSA.recover(_hash, _signature)
                    ? _INTERFACE_ID_ERC1271
                    : _ERC1271FAILVALUE;
        }
    }

    function universalReceiver(bytes32 _typeId, bytes calldata _data)
        external
        virtual
        override
        returns (bytes memory returnValue)
    {
        bytes memory receiverData = IERC725Y(this).getDataSingle(
            _LSP1_UNIVERSAL_RECEIVER_DELEGATE_KEY
        );
        returnValue = "";

        // call external contract
        if (receiverData.length == 20) {
            address universalReceiverAddress = BytesLib.toAddress(
                receiverData,
                0
            );

            if (
                ERC165(universalReceiverAddress).supportsInterface(
                    _INTERFACEID_LSP1_DELEGATE
                )
            ) {
                returnValue = ILSP1UniversalReceiverDelegate(
                    universalReceiverAddress
                ).universalReceiverDelegate(_msgSender(), _typeId, _data);
            }
        }

        emit UniversalReceiver(_msgSender(), _typeId, returnValue, _data);

        return returnValue;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/**
 * @title The interface for LSP1UniversalReceiverDelegate
 * @dev LSP1UniversalReceiverDelegate allows for an external universal receiver smart contract,
 * that is the delegate of the initial universal receiver
 */
interface ILSP1UniversalReceiverDelegate {
    /**
     * @dev Get called by the universalReceiver function, can be customized to have a specific logic
     * @param sender The address calling the universalReceiver function
     * @param typeId The hash of a specific standard or a hook
     * @param data The arbitrary data received with the call
     * @return result Any useful data could be returned
     */
    function universalReceiverDelegate(
        address sender,
        bytes32 typeId,
        bytes memory data
    ) external returns (bytes memory result);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/*
 * @title Solidity Utils
 * @author Fabian Vogelsteller <[email protected]>
 *
 * @dev Utils functions
 */
library UtilsLib {
    /**
     * @dev Internal function to determine if an address is a contract
     * @param _target The address being queried
     *
     * @return result Returns TRUE if `_target` is a contract
     */
    function isContract(address _target) internal view returns (bool result) {
        // solhint-disable no-inline-assembly
        assembly {
            result := gt(extcodesize(_target), 0)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// >> INTERFACES

bytes4 constant _INTERFACE_ID_ERC725ACCOUNT = 0x63cb749b;

bytes4 constant _INTERFACE_ID_ERC1271 = 0x1626ba7e;

// >> OTHER

// ERC1271 - Standard Signature Validation
bytes4 constant _ERC1271MAGICVALUE = 0x1626ba7e;
bytes4 constant _ERC1271FAILVALUE = 0xffffffff;

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// modules
import "@erc725/smart-contracts/contracts/ERC725InitAbstract.sol";
import "./LSP0ERC725AccountCore.sol";

/**
 * @title Inheritable Proxy Implementation of ERC725Account
 * @author Fabian Vogelsteller <[email protected]>, Jean Cavallera (CJ42), Yamen Merhi (YamenMerhi)
 * @dev Bundles ERC725X and ERC725Y, ERC1271 and LSP1UniversalReceiver and allows receiving native tokens
 */
abstract contract LSP0ERC725AccountInitAbstract is
    LSP0ERC725AccountCore,
    ERC725InitAbstract
{
    /**
     * @notice Sets the owner of the contract and register ERC725Account, ERC1271 and LSP1UniversalReceiver interfacesId
     * @param _newOwner the owner of the contract
     */
    function initialize(address _newOwner)
        public
        virtual
        override
        onlyInitializing
    {
        ERC725InitAbstract.initialize(_newOwner);

        _registerInterface(_INTERFACE_ID_ERC725ACCOUNT);
        _registerInterface(_INTERFACE_ID_ERC1271);
        _registerInterface(_INTERFACEID_LSP1);
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// modules
import "./ERC725XInitAbstract.sol";
import "./ERC725YInitAbstract.sol";

/**
 * @title Inheritable Proxy Implementation of ERC725 bundle
 * @author Fabian Vogelsteller <[email protected]>
 * @dev Bundles ERC725XInit and ERC725YInit together into one smart contract
 */
abstract contract ERC725InitAbstract is ERC725XInitAbstract, ERC725YInitAbstract {
    /**
     * @notice Sets the owner of the contract
     * @param _newOwner the owner of the contract
     */
    function initialize(address _newOwner)
        public
        virtual
        override(ERC725XInitAbstract, ERC725YInitAbstract)
        onlyInitializing
    {
        ERC725XInitAbstract.initialize(_newOwner);
        ERC725YInitAbstract.initialize(_newOwner);
    }

    // NOTE this implementation has not by default: receive() external payable {}
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@lukso/universalprofile-smart-contracts/contracts/LSP8IdentifiableDigitalAsset/LSP8IdentifiableDigitalAsset.sol";
import "@lukso/universalprofile-smart-contracts/contracts/LSP8IdentifiableDigitalAsset/extensions/LSP8CompatibilityForERC721.sol";
import "../lsp/TemporaryLSP4Compatability.sol";

contract Lns is
    Pausable,
    LSP8CompatibilityForERC721,
    TemporaryLSP4Compatability
{
    uint256 public price;
    mapping(bytes1 => bool) private allowedChar;

    // events
    event PriceChanged(uint256 newPrice);
    event VanityNameSet(address addr, bytes32 vantiyName);
    using EnumerableSet for EnumerableSet.Bytes32Set;

    constructor(
        string memory name,
        string memory symbol,
        uint256 _price
    ) LSP8CompatibilityForERC721(name, symbol, msg.sender) {
        price = _price;
        _setAllowedChar();
    }

    function freeze() public onlyOwner {
        _pause();
    }

    function unFreeze() public onlyOwner {
        _unpause();
    }

    function setVanityName(address addr, bytes32 vanityName)
        public
        payable
        whenNotPaused
    {
        require(msg.value == price, "wrong amount sent");
        require(
            vanityName[4] != 0x00 && vanityName[15] == 0x00,
            "name should be between 5 to 15 characters long"
        );
        require(
            _ownedTokens[addr].length() == 0,
            "you already have a vanity name"
        );
        _inputValidation(vanityName);
        _mint(addr, vanityName, false, "");
        emit VanityNameSet(addr, vanityName);
    }

    function updatePrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
        emit PriceChanged(price);
    }

    function _inputValidation(bytes32 vanityName) internal view {
        for (uint256 i = 0; i < 32; i++) {
            if (!allowedChar[vanityName[i]] && vanityName[i] != 0x00) {
                revert("character not allowed");
            }
        }
    }

    function _setAllowedChar() private {
        bytes26 allowedCharUc = "ABCDEFGHIGKLMNOPQRSTUVWXYZ";
        bytes26 allowedCharLc = "abcdefghijklmnopqrstuvwxyz";
        bytes10 allowedNum = "0123456789";
        bytes1 allowedSpecialChar = "_";

        for (uint256 i = 0; i < 26; i++) {
            allowedChar[allowedCharUc[i]] = true;
            allowedChar[allowedCharLc[i]] = true;
        }
        for (uint256 i = 0; i < 10; i++) {
            allowedChar[allowedNum[i]] = true;
        }
        allowedChar[allowedSpecialChar] = true;
    }

    // room for change
    function withdrawFunds() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "contract balance is 0");
        payable(msg.sender).transfer(balance);
    }

    function authorizeOperator(address operator, bytes32 tokenId)
        public
        virtual
        override(LSP8IdentifiableDigitalAssetCore, LSP8CompatibilityForERC721)
    {
        super.authorizeOperator(operator, tokenId);
    }

    function _transfer(
        address from,
        address to,
        bytes32 tokenId,
        bool force,
        bytes memory data
    )
        internal
        virtual
        override(LSP8CompatibilityForERC721, TemporaryLSP4Compatability)
    {
        super._transfer(from, to, tokenId, force, data);
    }

    function _mint(
        address to,
        bytes32 tokenId,
        bool force,
        bytes memory data
    )
        internal
        virtual
        override(LSP8CompatibilityForERC721, TemporaryLSP4Compatability)
    {
        super._mint(to, tokenId, force, data);
    }

    function _burn(bytes32 tokenId, bytes memory data)
        internal
        virtual
        override(LSP8IdentifiableDigitalAssetCore, LSP8CompatibilityForERC721)
    {
        super._burn(tokenId, data);
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// modules
import "@openzeppelin/contracts/security/Pausable.sol";
import "@lukso/universalprofile-smart-contracts/contracts/LSP7DigitalAsset/extensions/LSP7CappedSupply.sol";
import "@lukso/universalprofile-smart-contracts/contracts/LSP7DigitalAsset/extensions/LSP7CompatibilityForERC20.sol";

contract FanzoneToken is Pausable, LSP7CompatibilityForERC20, LSP7CappedSupply {
    //
    // --- Initialize
    //

    constructor(
        string memory name,
        string memory symbol,
        uint256 tokenSupplyCap
    )
        LSP7CompatibilityForERC20(name, symbol, msg.sender)
        LSP7CappedSupply(tokenSupplyCap)
    {
        // using force=true the initial supply can go to any address (EOA or contract)
        _mint(msg.sender, tokenSupplyCap, true, "");
    }

    //
    // --- Pause logic
    //

    function pause() public onlyOwner {
        _pause();
    }

    //
    // --- Overrides
    //

    function authorizeOperator(address operator, uint256 amount)
        public
        virtual
        override(ILSP7DigitalAsset, LSP7CompatibilityForERC20)
    {
        super.authorizeOperator(operator, amount);
    }

    function _burn(
        address from,
        uint256 amount,
        bytes memory data
    )
        internal
        virtual
        override(LSP7DigitalAssetCore, LSP7CompatibilityForERC20)
    {
        super._burn(from, amount, data);
    }

    function _mint(
        address to,
        uint256 amount,
        bool force,
        bytes memory data
    ) internal virtual override(LSP7CompatibilityForERC20, LSP7CappedSupply) {
        super._mint(to, amount, force, data);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount,
        bool force,
        bytes memory data
    )
        internal
        virtual
        override(LSP7DigitalAssetCore, LSP7CompatibilityForERC20)
    {
        super._transfer(from, to, amount, force, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// modules
import "./LSP7CappedSupplyCore.sol";
import "../LSP7DigitalAsset.sol";

/**
 * @dev LSP7 extension, adds token supply cap.
 */
abstract contract LSP7CappedSupply is LSP7CappedSupplyCore, LSP7DigitalAsset {
    /**
     * @notice Sets the token max supply
     * @param tokenSupplyCap_ The Token max supply
     */
    constructor(uint256 tokenSupplyCap_) {
        if (tokenSupplyCap_ == 0) {
            revert LSP7CappedSupplyRequired();
        }

        _tokenSupplyCap = tokenSupplyCap_;
    }

    // --- Overrides

    /**
     * @dev Mints `amount` tokens and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenSupplyCap() - totalSupply()` must be greater than zero.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        address to,
        uint256 amount,
        bool force,
        bytes memory data
    ) internal virtual override(LSP7DigitalAssetCore, LSP7CappedSupplyCore) {
        super._mint(to, amount, force, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// modules
import "../LSP7DigitalAsset.sol";
import "./LSP7CompatibilityForERC20Core.sol";

contract LSP7CompatibilityForERC20 is LSP7CompatibilityForERC20Core, LSP7DigitalAsset {
    /* solhint-disable no-empty-blocks */
    /**
     * @notice Sets the name, the symbol and the owner of the token
     * @param name_ The name of the token
     * @param symbol_ The symbol of the token
     * @param newOwner_ The owner of the token
     */
    constructor(
        string memory name_,
        string memory symbol_,
        address newOwner_
    ) LSP7DigitalAsset(name_, symbol_, newOwner_, false) {

    }

    // --- Overrides

    function authorizeOperator(address operator, uint256 amount)
    public
        virtual
        override(LSP7DigitalAssetCore, LSP7CompatibilityForERC20Core)
    {
        super.authorizeOperator(operator, amount);
    }

    function _burn(address from, uint256 amount, bytes memory data)
        internal
        virtual
        override(LSP7DigitalAssetCore, LSP7CompatibilityForERC20Core)
    {
        super._burn(from, amount, data);
    }

    function _mint(address to, uint256 amount, bool force, bytes memory data)
    internal
        virtual
        override(LSP7DigitalAssetCore, LSP7CompatibilityForERC20Core) {
            super._mint(to, amount, force, data);
    }

    function _transfer(address from, address to, uint256 amount, bool force, bytes memory data)
    internal
        virtual
        override(LSP7DigitalAssetCore, LSP7CompatibilityForERC20Core) {
            super._transfer(from, to, amount, force, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// modules
import "../LSP7DigitalAssetCore.sol";

// interfaces
import "./ILSP7CappedSupply.sol";

/**
 * @dev LSP7 extension, adds token supply cap.
 */
abstract contract LSP7CappedSupplyCore is
    ILSP7CappedSupply,
    LSP7DigitalAssetCore
{
    // --- Errors

    error LSP7CappedSupplyRequired();
    error LSP7CappedSupplyCannotMintOverCap();

    // --- Storage

    uint256 internal _tokenSupplyCap;

    // --- Token queries

    /**
     * @inheritdoc ILSP7CappedSupply
     */
    function tokenSupplyCap() public view virtual override returns (uint256) {
        return _tokenSupplyCap;
    }

    // --- Transfer functionality

    /**
     * @dev Mints `amount` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenSupplyCap() - totalSupply()` must be greater than zero.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        address to,
        uint256 amount,
        bool force,
        bytes memory data
    ) internal virtual override {
        if (totalSupply() + amount > tokenSupplyCap()) {
            revert LSP7CappedSupplyCannotMintOverCap();
        }

        super._mint(to, amount, force, data);
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// constants
import "./LSP7Constants.sol";
import "../LSP4DigitalAssetMetadata/LSP4Constants.sol";

// modules
import "./LSP7DigitalAssetCore.sol";
import "../LSP4DigitalAssetMetadata/LSP4DigitalAssetMetadata.sol";
import "@erc725/smart-contracts/contracts/ERC725Y.sol";

/**
 * @title LSP7DigitalAsset contract
 * @author Matthew Stevens
 * @dev Implementation of a LSP7 compliant contract.
 */
contract LSP7DigitalAsset is LSP7DigitalAssetCore, LSP4DigitalAssetMetadata {
    /**
     * @notice Sets the token-Metadata and register LSP7InterfaceId
     * @param name_ The name of the token
     * @param symbol_ The symbol of the token
     * @param newOwner_ The owner of the the token-Metadata
     * @param isNFT_ Specify if the LSP7 token is a fungible or non-fungible token
     */
    constructor(
        string memory name_,
        string memory symbol_,
        address newOwner_,
        bool isNFT_
    ) LSP4DigitalAssetMetadata(name_, symbol_, newOwner_) {
        _isNFT = isNFT_;
        _registerInterface(_INTERFACEID_LSP7);
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// constants
import "./LSP7Constants.sol";
import "../LSP1UniversalReceiver/LSP1Constants.sol";
import "../LSP4DigitalAssetMetadata/LSP4Constants.sol";

// interfaces
import "../LSP1UniversalReceiver/ILSP1UniversalReceiver.sol";
import "./ILSP7DigitalAsset.sol";

// modules
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@erc725/smart-contracts/contracts/ERC725Y.sol";

// library
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

/**
 * @title LSP7DigitalAsset contract
 * @author Matthew Stevens
 * @dev Core Implementation of a LSP7 compliant contract.
 */
abstract contract LSP7DigitalAssetCore is Context, ILSP7DigitalAsset {
    using Address for address;

    // --- Errors

    error LSP7AmountExceedsBalance(uint256 balance, address tokenOwner, uint256 amount);
    error LSP7AmountExceedsAuthorizedAmount(address tokenOwner, uint256 authorizedAmount, address operator, uint256 amount);
    error LSP7CannotUseAddressZeroAsOperator();
    error LSP7CannotSendWithAddressZero();
    error LSP7InvalidTransferBatch();
    error LSP7NotifyTokenReceiverContractMissingLSP1Interface(address tokenReceiver);
    error LSP7NotifyTokenReceiverIsEOA(address tokenReceiver);

    // --- Storage

    bool internal _isNFT;

    uint256 internal _existingTokens;

    // Mapping from `tokenOwner` to an `amount` of tokens
    mapping(address => uint256) internal _tokenOwnerBalances;

    // Mapping a `tokenOwner` to an `operator` to `amount` of tokens.
    mapping(address => mapping(address => uint256))
        internal _operatorAuthorizedAmount;

    // --- Token queries

    /**
     * @inheritdoc ILSP7DigitalAsset
     */
    function decimals() public view override returns (uint256) {
        return _isNFT ? 0 : 18;
    }

    /**
     * @inheritdoc ILSP7DigitalAsset
     */
    function totalSupply() public view override returns (uint256) {
        return _existingTokens;
    }

    // --- Token owner queries

    /**
     * @inheritdoc ILSP7DigitalAsset
     */
    function balanceOf(address tokenOwner)
        public
        view
        override
        returns (uint256)
    {
        return _tokenOwnerBalances[tokenOwner];
    }

    // --- Operator functionality

    /**
     * @inheritdoc ILSP7DigitalAsset
     */
    function authorizeOperator(address operator, uint256 amount)
        public
        virtual
        override
    {
        _updateOperator(_msgSender(), operator, amount);
    }

    /**
     * @inheritdoc ILSP7DigitalAsset
     */
    function revokeOperator(address operator) public virtual override {
        _updateOperator(_msgSender(), operator, 0);
    }

    /**
     * @inheritdoc ILSP7DigitalAsset
     */
    function isOperatorFor(address operator, address tokenOwner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        if (tokenOwner == operator) {
            return _tokenOwnerBalances[tokenOwner];
        } else {
            return _operatorAuthorizedAmount[tokenOwner][operator];
        }
    }

    // --- Transfer functionality

    /**
     * @inheritdoc ILSP7DigitalAsset
     */
    function transfer(
        address from,
        address to,
        uint256 amount,
        bool force,
        bytes memory data
    ) public virtual override {
        address operator = _msgSender();
        if (operator != from) {
            uint256 operatorAmount = _operatorAuthorizedAmount[from][operator];
            if (amount > operatorAmount) {
                revert LSP7AmountExceedsAuthorizedAmount(from, operatorAmount, operator, amount);
            }

            _updateOperator(
                from,
                operator,
                operatorAmount - amount
            );
        }

        _transfer(from, to, amount, force, data);
    }

    /**
     * @inheritdoc ILSP7DigitalAsset
     */
    function transferBatch(
        address[] memory from,
        address[] memory to,
        uint256[] memory amount,
        bool force,
        bytes[] memory data
    ) external virtual override {
        if (from.length != to.length ||
                from.length != amount.length ||
                from.length != data.length) {
            revert LSP7InvalidTransferBatch();
        }

        for (uint256 i = 0; i < from.length; i++) {
            // using the public transfer function to handle updates to operator authorized amounts
            transfer(from[i], to[i], amount[i], force, data[i]);
        }
    }

    /**
     * @dev Changes token `amount` the `operator` has access to from `tokenOwner` tokens. If the
     * amount is zero then the operator is being revoked, otherwise the operator amount is being
     * modified.
     *
     * See {isOperatorFor}.
     *
     * Emits either {AuthorizedOperator} or {RevokedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be the zero address.
     */
    function _updateOperator(
        address tokenOwner,
        address operator,
        uint256 amount
    ) internal virtual {
        if (operator == address(0)) {
            revert LSP7CannotUseAddressZeroAsOperator();
        }

        // tokenOwner is always their own operator, no update required
        if (operator == tokenOwner) {
            return;
        }

        _operatorAuthorizedAmount[tokenOwner][operator] = amount;

        if (amount > 0) {
            emit AuthorizedOperator(operator, tokenOwner, amount);
        } else {
            emit RevokedOperator(operator, tokenOwner);
        }
    }

    /**
     * @dev Mints `amount` tokens and transfers it to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        address to,
        uint256 amount,
        bool force,
        bytes memory data
    ) internal virtual {
        if (to == address(0)){
            revert LSP7CannotSendWithAddressZero();
        }

        address operator = _msgSender();

        _beforeTokenTransfer(address(0), to, amount);

        _tokenOwnerBalances[to] += amount;

        emit Transfer(operator, address(0), to, amount, force, data);

        _notifyTokenReceiver(address(0), to, amount, force, data);
    }

    /**
     * @dev Destroys `amount` tokens.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens.
     * - If the caller is not `from`, it must be an operator for `from` with access to at least
     * `amount` tokens.
     *
     * Emits a {Transfer} event.
     */
    function _burn(
        address from,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        if (from == address(0)) {
            revert LSP7CannotSendWithAddressZero();
        }

        uint256 balance = _tokenOwnerBalances[from];
        if (amount > balance) {
            revert LSP7AmountExceedsBalance(balance, from, amount);
        }

        address operator = _msgSender();
        if (operator != from) {
            uint256 authorizedAmount = _operatorAuthorizedAmount[from][operator];
            if (amount > authorizedAmount) {
                revert LSP7AmountExceedsAuthorizedAmount(from, authorizedAmount, operator, amount);
            }
            _operatorAuthorizedAmount[from][operator] -= amount;
        }

        _notifyTokenSender(from, address(0), amount, data);

        _beforeTokenTransfer(from, address(0), amount);

        _tokenOwnerBalances[from] -= amount;

        emit Transfer(operator, from, address(0), amount, false, data);
    }

    /**
     * @dev Transfers `amount` tokens from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens.
     * - If the caller is not `from`, it must be an operator for `from` with access to at least
     * `amount` tokens.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount,
        bool force,
        bytes memory data
    ) internal virtual {
        if (from == address(0) || to == address(0)) {
            revert LSP7CannotSendWithAddressZero();
        }

        uint256 balance = _tokenOwnerBalances[from];
        if (amount > balance) {
            revert LSP7AmountExceedsBalance(balance, from, amount);
        }

        address operator = _msgSender();

        _notifyTokenSender(from, to, amount, data);

        _beforeTokenTransfer(from, to, amount);

        _tokenOwnerBalances[from] -= amount;
        _tokenOwnerBalances[to] += amount;

        emit Transfer(operator, from, to, amount, force, data);

        _notifyTokenReceiver(from, to, amount, force, data);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `amount` tokens will be
     * transferred to `to`.
     * - When `from` is zero, `amount` tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s `amount` tokens will be burned.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        // tokens being minted
        if (from == address(0)) {
            _existingTokens += amount;
        }

        // tokens being burned
        if (to == address(0)) {
            _existingTokens -= amount;
        }
    }

    /**
     * @dev An attempt is made to notify the token sender about the `amount` tokens changing owners using
     * LSP1 interface.
     */
    function _notifyTokenSender(
        address from,
        address to,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        if (
            ERC165Checker.supportsERC165(from) &&
            ERC165Checker.supportsInterface(from, _INTERFACEID_LSP1)
        ) {
            bytes memory packedData = abi.encodePacked(from, to, amount, data);
            ILSP1UniversalReceiver(from).universalReceiver(
                _TYPEID_LSP7_TOKENSSENDER,
                packedData
            );
        }
    }

    /**
     * @dev An attempt is made to notify the token receiver about the `amount` tokens changing owners
     * using LSP1 interface. When force is FALSE the token receiver MUST support LSP1.
     *
     * The receiver may revert when the token being sent is not wanted.
     */
    function _notifyTokenReceiver(
        address from,
        address to,
        uint256 amount,
        bool force,
        bytes memory data
    ) internal virtual {
        if (
            ERC165Checker.supportsERC165(to) &&
            ERC165Checker.supportsInterface(to, _INTERFACEID_LSP1)
        ) {
            bytes memory packedData = abi.encodePacked(from, to, amount, data);
            ILSP1UniversalReceiver(to).universalReceiver(
                _TYPEID_LSP7_TOKENSRECIPIENT,
                packedData
            );
        } else if (!force) {
            if (to.isContract()) {
                revert LSP7NotifyTokenReceiverContractMissingLSP1Interface(to);
            } else {
                revert LSP7NotifyTokenReceiverIsEOA(to);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// interfaces
import "../ILSP7DigitalAsset.sol";

/**
 * @dev LSP7 extension, adds token supply cap.
 */
interface ILSP7CappedSupply is ILSP7DigitalAsset {
    /**
     * @dev Returns the number of tokens that can be minted
     * @return The number of tokens that can be minted
     */
    function tokenSupplyCap() external view returns (uint256);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// --- ERC165 interface ids
bytes4 constant _INTERFACEID_LSP7 = 0xe33f65c3;

// --- ERC725Y entries

// --- Token Hooks
bytes32 constant _TYPEID_LSP7_TOKENSSENDER = 0x40b8bec57d7b5ff0dbd9e9acd0a47dfeb0101e1a203766f5ccab00445fbf39e9; // keccak256("LSP7TokensSender")

bytes32 constant _TYPEID_LSP7_TOKENSRECIPIENT = 0xdbe2c314e1aee2970c72666f2ebe8933a8575263ea71e5ff6a9178e95d47a26f; // keccak256("LSP7TokensRecipient")

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// modules
import "../../LSP4DigitalAssetMetadata/LSP4Compatibility.sol";
import "../LSP7DigitalAssetCore.sol";

// interfaces
import "./ILSP7CompatibilityForERC20.sol";

/**
 * @dev LSP7 extension, for compatibility for clients / tools that expect ERC20.
 */
abstract contract LSP7CompatibilityForERC20Core is
    ILSP7CompatibilityForERC20,
    LSP7DigitalAssetCore,
    LSP4Compatibility
{
    /**
     * @inheritdoc ILSP7CompatibilityForERC20
     */
    function approve(address operator, uint256 amount)
        external
        virtual
        override
    {
        return authorizeOperator(operator, amount);
    }

    /**
     * @inheritdoc ILSP7CompatibilityForERC20
     */
    function allowance(address tokenOwner, address operator)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return isOperatorFor(operator, tokenOwner);
    }

    /**
     * @inheritdoc ILSP7CompatibilityForERC20
     * @dev Compatible with ERC20 transfer.
     * Using force=true so that EOA and any contract may receive the tokens.
     */
    function transfer(address to, uint256 amount) external virtual override {
        return transfer(_msgSender(), to, amount, true, "");
    }

    /**
     * @inheritdoc ILSP7CompatibilityForERC20
     * @dev Compatible with ERC20 transferFrom.
     * Using force=true so that EOA and any contract may receive the tokens.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external virtual override {
        return transfer(from, to, amount, true, "");
    }

    // --- Overrides

    function authorizeOperator(address operator, uint256 amount)
        public
        virtual
        override(ILSP7DigitalAsset, LSP7DigitalAssetCore)
    {
        super.authorizeOperator(operator, amount);

        emit Approval(
            _msgSender(),
            operator,
            amount
        );
    }

    function _transfer(
        address from,
        address to,
        uint256 amount,
        bool force,
        bytes memory data
    ) internal virtual override {
        super._transfer(from, to, amount, force, data);

        emit Transfer(
            from,
            to,
            amount
        );
    }

    function _mint(
        address to,
        uint256 amount,
        bool force,
        bytes memory data
    ) internal virtual override {
        super._mint(to, amount, force, data);

        emit Transfer(
            address(0),
            to,
            amount
        );
    }

    function _burn(address from, uint256 amount, bytes memory data)
        internal
        virtual
        override
    {
        super._burn(from, amount, data);

        emit Transfer(
            from,
            address(0),
            amount
        );
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// interfaces
import "@lukso/universalprofile-smart-contracts/contracts/LSP7DigitalAsset/extensions/ILSP7CompatibilityForERC20.sol";
import "../royalties/IFeeCollector.sol";
import "../royalties/IFeeCollectorRevenueShareCallback.sol";

contract TestFeeCollectorShareRevenueCaller is
    IFeeCollectorRevenueShareCallback
{
    //
    // --- Storage
    //

    address private _feeCollector;
    bool public wasCalled;

    constructor(address feeCollector) {
        _feeCollector = feeCollector;
    }

    function callShareRevenue(
        address token,
        uint256 amount,
        address referrer,
        RoyaltySharesLib.RoyaltyShare[] calldata royaltyShares,
        bytes calldata dataForCallback
    ) public {
        IFeeCollector(_feeCollector).shareRevenue(
            token,
            amount,
            referrer,
            royaltyShares,
            dataForCallback
        );
    }

    function revenueShareCallback(
        uint256 totalFee,
        bytes calldata dataForCallback
    ) external override {
        // silence compiler warning about unused variable
        totalFee;

        (address feePayer, address token, uint256 feeToPay) = abi.decode(
            dataForCallback,
            (address, address, uint256)
        );
        ILSP7CompatibilityForERC20(token).transferFrom(
            feePayer,
            _feeCollector,
            feeToPay
        );

        wasCalled = true;
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// constants
import { FEE_SCALE } from "./constants.sol";

// libs
import "./RoyaltySharesLib.sol";

// interfaces
import "@lukso/universalprofile-smart-contracts/contracts/LSP7DigitalAsset/extensions/ILSP7CompatibilityForERC20.sol";
import "./IFeeCollector.sol";
import "./IFeeCollectorRevenueShareCallback.sol";

// modules
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "../security/LockGuard.sol";

// a pull based fee collection for creators / platform / referrers of CardToken sales
contract FeeCollector is Context, Ownable, LockGuard, IFeeCollector {
    //
    // --- Errors
    //

    error FeeCollectorPlatformFeeReceiverRequired();
    error FeeCollectorRevenueShareFeesRequired(
        uint16 platform,
        uint16 creator,
        uint16 referral
    );
    error FeeCollectorRevenueShareFeesTooHigh(uint256 maxFeeSum);
    error FeeCollectorShareRevenuePaymentFailed(
        uint256 expectedAmount,
        uint256 receivedAmount
    );

    //
    // --- Storage
    //

    RevenueShareFees private _revenueShareFees;

    // fees are capped at 5% = 500 basis points
    uint256 private constant MAX_REVENUE_SHARE_FEE_SUM = 5_00;
    // base revenue share fees
    uint256 private _baseRevenueShareFee;

    address private _platformFeeReceiver;

    // fee receive address => fee token address => fees available
    mapping(address => mapping(address => uint256)) public override feeBalance;

    //
    // --- Initialize
    //

    constructor(address platformFeeReceiver_) {
        setPlatformFeeReceiver(platformFeeReceiver_);

        // fees are measured in basis points
        // 1% = 100 basis points
        setRevenueShareFees(1_00, 3_00, 1_00);
    }

    //
    // --- Fee queries
    //

    function revenueShareFees()
        public
        view
        override
        returns (RevenueShareFees memory)
    {
        return _revenueShareFees;
    }

    function baseRevenueShareFee() public view override returns (uint256) {
        return _baseRevenueShareFee;
    }

    function platformFeeReceiver() public view override returns (address) {
        return _platformFeeReceiver;
    }

    //
    // --- Revenue Share logic
    //

    function shareRevenue(
        address feeToken,
        uint256 amount,
        address referrer,
        RoyaltySharesLib.RoyaltyShare[] calldata creatorRoyalties,
        bytes calldata dataForCallback
    ) external override takeLock returns (uint256) {
        // if we are called with a zero amount to share then just return
        if (amount == 0) {
            return amount;
        }

        (
            uint256 platformFeeAmount,
            uint256 creatorFeeAmount,
            uint256 referralFeeAmount,
            uint256 totalFeeAmount
        ) = _calculateRevenueShare(amount, referrer);

        // take snapshots and perform callback
        uint256 preBalance;
        uint256 postBalance;

        if (feeToken == address(0)) {
            preBalance = address(this).balance;
            IFeeCollectorRevenueShareCallback(msg.sender).revenueShareCallback(
                totalFeeAmount,
                dataForCallback
            );
            postBalance = address(this).balance;
        } else {
            preBalance = ILSP7CompatibilityForERC20(feeToken).balanceOf(
                address(this)
            );
            IFeeCollectorRevenueShareCallback(msg.sender).revenueShareCallback(
                totalFeeAmount,
                dataForCallback
            );
            postBalance = ILSP7CompatibilityForERC20(feeToken).balanceOf(
                address(this)
            );
        }

        // ensure the expected amount of tokens was sent to cover revenue share fees
        uint256 feeReceived = postBalance - preBalance;
        if (feeReceived < totalFeeAmount) {
            revert FeeCollectorShareRevenuePaymentFailed(
                totalFeeAmount,
                postBalance - preBalance
            );
        }

        // if additional payment was received, in the case of FeeReceiver clearing any dust, add it
        // to the platformFee
        if (feeReceived > totalFeeAmount) {
            platformFeeAmount += feeReceived - totalFeeAmount;
        }

        // update fee balances
        _depositFee(feeToken, _platformFeeReceiver, platformFeeAmount);
        _depositRoyaltiesFee(feeToken, creatorFeeAmount, creatorRoyalties);
        _depositFee(feeToken, referrer, referralFeeAmount);

        return totalFeeAmount;
    }

    function _calculateRevenueShare(uint256 amount, address referrer)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 platformFeeAmount = _calculateFee(
            amount,
            _revenueShareFees.platform
        );
        uint256 creatorFeeAmount = _calculateFee(
            amount,
            _revenueShareFees.creator
        );
        uint256 referralFeeAmount = 0;
        if (referrer != address(0)) {
            referralFeeAmount = _calculateFee(
                amount,
                _revenueShareFees.referral
            );
        }

        uint256 totalFeeAmount = platformFeeAmount +
            creatorFeeAmount +
            referralFeeAmount;

        return (
            platformFeeAmount,
            creatorFeeAmount,
            referralFeeAmount,
            totalFeeAmount
        );
    }

    function _depositFee(
        address feeToken,
        address receiver,
        uint256 amount
    ) internal {
        if (amount > 0) {
            feeBalance[receiver][feeToken] += amount;
        }
    }

    function _depositRoyaltiesFee(
        address feeToken,
        uint256 amountForRoyalty,
        RoyaltySharesLib.RoyaltyShare[] memory creatorRoyalties
    ) internal {
        uint256 royaltySum = 0;
        for (uint256 i = creatorRoyalties.length - 1; i > 0; i--) {
            RoyaltySharesLib.RoyaltyShare
                memory creatorRoyalty = creatorRoyalties[i];
            uint256 royaltyAmountForCreator = _calculateFee(
                amountForRoyalty,
                creatorRoyalty.share
            );
            _depositFee(
                feeToken,
                creatorRoyalty.receiver,
                royaltyAmountForCreator
            );
            royaltySum += royaltyAmountForCreator;
        }

        // the first creator entry will receive any dust from royalty fee calculation
        _depositFee(
            feeToken,
            creatorRoyalties[0].receiver,
            amountForRoyalty - royaltySum
        );
    }

    function _calculateFee(uint256 amount, uint256 fee)
        internal
        pure
        returns (uint256)
    {
        return (amount * fee) / FEE_SCALE;
    }

    //
    // --- Withdrawl logic
    //

    // allow the _msgSender to receive tokens
    function withdrawTokens(address[] calldata feeTokenList) public override {
        _withdrawTokens(_msgSender(), feeTokenList);
    }

    // allow anyone to have many addresses receive many tokens
    function withdrawTokensForMany(
        address[] calldata accountList,
        address[] calldata feeTokenList
    ) public override {
        for (uint256 i = 0; i < accountList.length; i++) {
            _withdrawTokens(accountList[i], feeTokenList);
        }
    }

    function _withdrawTokens(address receiver, address[] calldata feeTokenList)
        internal
    {
        for (uint256 i = 0; i < feeTokenList.length; i++) {
            address feeToken = feeTokenList[i];
            uint256 amount = feeBalance[receiver][feeToken];

            if (amount > 0) {
                delete feeBalance[receiver][feeToken];
                if (feeToken == address(0)) {
                    // solhint-disable-next-line avoid-low-level-calls
                    (bool success, ) = payable(receiver).call{ value: amount }(
                        ""
                    );
                    require(success, "FeeCollector: transfer failed");
                } else {
                    ILSP7CompatibilityForERC20(feeToken).transfer(
                        receiver,
                        amount
                    );
                }
            }
        }
    }

    //
    // --- Storage updates
    //

    function setPlatformFeeReceiver(address platformFeeReceiver_)
        public
        onlyOwner
    {
        if (platformFeeReceiver_ == address(0)) {
            revert FeeCollectorPlatformFeeReceiverRequired();
        }

        _platformFeeReceiver = platformFeeReceiver_;
    }

    function setRevenueShareFees(
        uint16 platformFee,
        uint16 creatorFee,
        uint16 referralFee
    ) public onlyOwner {
        _revenueShareFees = _validateRevenueShareFees(
            platformFee,
            creatorFee,
            referralFee
        );

        _baseRevenueShareFee = platformFee + creatorFee;
    }

    function _validateRevenueShareFees(
        uint16 platformFee,
        uint16 creatorFee,
        uint16 referralFee
    ) internal pure returns (RevenueShareFees memory) {
        if (platformFee == 0 || creatorFee == 0 || referralFee == 0) {
            revert FeeCollectorRevenueShareFeesRequired(
                platformFee,
                creatorFee,
                referralFee
            );
        }

        if (
            platformFee + creatorFee + referralFee > MAX_REVENUE_SHARE_FEE_SUM
        ) {
            revert FeeCollectorRevenueShareFeesTooHigh(
                MAX_REVENUE_SHARE_FEE_SUM
            );
        }

        return
            RevenueShareFees({
                platform: platformFee,
                creator: creatorFee,
                referral: referralFee
            });
    }

    //
    // --- Fallbacks
    //

    // solhint-disable-next-line no-empty-blocks
    receive() external payable onlyWithLock {}
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `LockGuard` will make the {takeLock} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them. The {withLock} modifier can be used to ensure that the
 * lock has been taken, for functions that should only be called when a lock has been taken.
 *
 * Note that because there is a single `takeLock` guard, functions marked as
 * `takeLock` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract LockGuard {
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
    uint256 private constant _NOT_LOCKED = 1;
    uint256 private constant _LOCKED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_LOCKED;
    }

    modifier takeLock() {
        require(_status == _NOT_LOCKED, "LockGuard: already locked");

        // Any calls to takeLock after this point will fail
        _status = _LOCKED;
        _;

        _status = _NOT_LOCKED;
    }

    modifier onlyWithLock() {
        require(_status == _LOCKED, "LockGuard: need lock");
        _;
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// modules
import "../royalties/FeeCollector.sol";

contract TestFeeCollector is FeeCollector {
    /* solhint-disable no-empty-blocks */
    constructor(address platformFeeReceiver)
        FeeCollector(platformFeeReceiver)
    {}

    function testOnlyCalculateRevenueShare(uint256 amount, address referrer)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return _calculateRevenueShare(amount, referrer);
    }

    function testOnlySetFeeBalance(
        address account,
        address token,
        uint256 amount
    ) public {
        feeBalance[account][token] = amount;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/presets/ERC20PresetFixedSupply.sol)
pragma solidity ^0.8.0;

import "../extensions/ERC20Burnable.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - Preminted initial supply
 *  - Ability for holders to burn (destroy) their tokens
 *  - No access control mechanism (for minting/pausing) and hence no governance
 *
 * This contract uses {ERC20Burnable} to include burn capabilities - head to
 * its documentation for details.
 *
 * _Available since v3.4._
 *
 * _Deprecated in favor of https://wizard.openzeppelin.com/[Contracts Wizard]._
 */
contract ERC20PresetFixedSupply is ERC20Burnable {
    /**
     * @dev Mints `initialSupply` amount of token and transfers them to `owner`.
     *
     * See {ERC20-constructor}.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner
    ) ERC20(name, symbol) {
        _mint(owner, initialSupply);
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// modules
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";

contract TestERC20 is ERC20PresetFixedSupply {
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    )
        ERC20PresetFixedSupply(name, symbol, initialSupply, msg.sender)
    // solhint-disable-next-line no-empty-blocks
    {

    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// modules
import "./ERC725X.sol";
import "./ERC725Y.sol";

/**
 * @title ERC725 bundle
 * @author Fabian Vogelsteller <[email protected]>
 * @dev Bundles ERC725X and ERC725Y together into one smart contract
 */
contract ERC725 is ERC725X, ERC725Y {
    /**
     * @notice Sets the owner of the contract
     * @param _newOwner the owner of the contract
     */
    // solhint-disable no-empty-blocks
    constructor(address _newOwner) ERC725X(_newOwner) ERC725Y(_newOwner) {}

    // NOTE this implementation has not by default: receive() external payable {}
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// modules
import "./ERC725XCore.sol";

/**
 * @title ERC725 X executor
 * @author Fabian Vogelsteller <[email protected]>
 * @dev Implementation of a contract module which provides the ability to call arbitrary functions at any other smart contract and itself,
 * including using `delegatecall`, `staticcall` as well creating contracts using `create` and `create2`
 * This is the basis for a smart contract based account system, but could also be used as a proxy account system
 */
contract ERC725X is ERC725XCore {
    /**
     * @notice Sets the owner of the contract and register ERC725X interfaceId
     * @param _newOwner the owner of the contract
     */
    constructor(address _newOwner) {
        // This is necessary to prevent a contract that implements both ERC725X and ERC725Y to call both constructors
        if (_newOwner != owner()) {
            OwnableUnset.initOwner(_newOwner);
        }
        _registerInterface(_INTERFACEID_ERC725X);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// modules
import "./LSP0ERC725AccountCore.sol";
import "@erc725/smart-contracts/contracts/ERC725.sol";

/**
 * @title Implementation of ERC725Account
 * @author Fabian Vogelsteller <[email protected]>, Jean Cavallera (CJ42), Yamen Merhi (YamenMerhi)
 * @dev Bundles ERC725X and ERC725Y, ERC1271 and LSP1UniversalReceiver and allows receiving native tokens
 */
contract LSP0ERC725Account is LSP0ERC725AccountCore, ERC725 {
    /**
     * @notice Sets the owner of the contract and register ERC725Account, ERC1271 and LSP1UniversalReceiver interfacesId
     * @param _newOwner the owner of the contract
     */
    constructor(address _newOwner) ERC725(_newOwner) {
        _registerInterface(_INTERFACE_ID_ERC725ACCOUNT);
        _registerInterface(_INTERFACE_ID_ERC1271);
        _registerInterface(_INTERFACEID_LSP1);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// modules
import "./LSP0ERC725Account/LSP0ERC725Account.sol";

/**
 * @title implementation of a LUKSO's Universal Profile based on LSP3
 * @author Fabian Vogelsteller <[email protected]>
 * @dev Implementation of the ERC725Account + LSP1 universalReceiver
 */
contract UniversalProfile is LSP0ERC725Account {
    /**
     * @notice Sets the owner of the contract and sets the SupportedStandards:LSP3UniversalProfile key
     * @param _newOwner the owner of the contract
     */
    constructor(address _newOwner) LSP0ERC725Account(_newOwner) {
        // set SupportedStandards:LSP3UniversalProfile
        bytes32 key = 0xeafec4d89fa9619884b6b89135626455000000000000000000000000abe425d6;
        bytes memory value = hex"abe425d6";
        _setData(key, value);
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// modules
import "@lukso/universalprofile-smart-contracts/contracts/UniversalProfile.sol";

/* solhint-disable no-empty-blocks */

// NOTE: need to make this an abstract class to get hardhat to compile it (and get typechain generated classes)
abstract contract ImportUniversalProfile is UniversalProfile {

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.6;

// modules
import "@erc725/smart-contracts/contracts/ERC725Y.sol";
import "@erc725/smart-contracts/contracts/ERC725.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

// interfaces
import "./ILSP6KeyManager.sol";

// libraries
import "../Utils/LSP6Utils.sol";

import "../Utils/ERC725Utils.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";

// constants
import "./LSP6Constants.sol";
import "../LSP0ERC725Account/LSP0Constants.sol";
import "@erc725/smart-contracts/contracts/constants.sol";

/**
 * @dev address `from` is not authorised to `permission`
 * @param permission permission required
 * @param from address not-authorised
 */
error NotAuthorised(address from, string permission);

/**
 * @dev address `from` is not authorised to interact with `disallowedAddress` via account
 * @param from address making the request
 * @param disallowedAddress address that `from` is not authorised to call
 */
error NotAllowedAddress(address from, address disallowedAddress);

/**
 * @dev address `from` is not authorised to run `disallowedFunction` via account
 * @param from address making the request
 * @param disallowedFunction bytes4 function selector that `from` is not authorised to run
 */
error NotAllowedFunction(address from, bytes4 disallowedFunction);

/**
 * @dev address `from` is not authorised to set the key `disallowedKey` on the account
 * @param from address making the request
 * @param disallowedKey a bytes32 key that `from` is not authorised to set on the ERC725Y storage
 */
error NotAllowedERC725YKey(address from, bytes32 disallowedKey);

/**
 * @title Core implementation of a contract acting as a controller of an ERC725 Account, using permissions stored in the ERC725Y storage
 * @author Fabian Vogelsteller, Jean Cavallera
 * @dev all the permissions can be set on the ERC725 Account using `setData(...)` with the keys constants below
 */
abstract contract LSP6KeyManagerCore is ILSP6KeyManager, ERC165Storage {
    using ERC725Utils for ERC725Y;
    using LSP2Utils for ERC725Y;
    using LSP6Utils for ERC725;
    using Address for address;
    using ECDSA for bytes32;
    using ERC165Checker for address;

    ERC725 public account;
    mapping(address => mapping(uint256 => uint256)) internal _nonceStore;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Storage)
        returns (bool)
    {
        return
            interfaceId == _INTERFACE_ID_ERC1271 ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc ILSP6KeyManager
     */
    function getNonce(address _from, uint256 _channel)
        public
        view
        override
        returns (uint256)
    {
        uint128 nonceId = uint128(_nonceStore[_from][_channel]);
        return (uint256(_channel) << 128) | nonceId;
    }

    /**
     * @inheritdoc IERC1271
     */
    function isValidSignature(bytes32 _hash, bytes memory _signature)
        public
        view
        override
        returns (bytes4 magicValue)
    {
        address recoveredAddress = ECDSA.recover(_hash, _signature);
        return
            (_PERMISSION_SIGN & account.getPermissionsFor(recoveredAddress)) ==
                _PERMISSION_SIGN
                ? _INTERFACE_ID_ERC1271
                : _ERC1271FAILVALUE;
    }

    /**
     * @inheritdoc ILSP6KeyManager
     */
    function execute(bytes calldata _data)
        external
        payable
        override
        returns (bytes memory)
    {
        _verifyPermissions(msg.sender, _data);

        // solhint-disable avoid-low-level-calls
        (bool success, bytes memory result_) = address(account).call{
            value: msg.value,
            gas: gasleft()
        }(_data);

        if (!success) {
            // solhint-disable reason-string
            if (result_.length < 68) revert();

            // solhint-disable no-inline-assembly
            assembly {
                result_ := add(result_, 0x04)
            }
            revert(abi.decode(result_, (string)));
        }

        emit Executed(msg.value, _data);
        return result_.length > 0 ? abi.decode(result_, (bytes)) : result_;
    }

    /**
     * @inheritdoc ILSP6KeyManager
     */
    function executeRelayCall(
        address _signedFor,
        uint256 _nonce,
        bytes calldata _data,
        bytes memory _signature
    ) external payable override returns (bytes memory) {
        require(
            _signedFor == address(this),
            "executeRelayCall: Message not signed for this keyManager"
        );

        bytes memory blob = abi.encodePacked(
            address(this), // needs to be signed for this keyManager
            _nonce,
            _data
        );

        address signer = keccak256(blob).toEthSignedMessageHash().recover(
            _signature
        );

        require(
            _isValidNonce(signer, _nonce),
            "executeRelayCall: Invalid nonce"
        );

        // increase nonce after successful verification
        _nonceStore[signer][_nonce >> 128]++;

        _verifyPermissions(signer, _data);

        // solhint-disable avoid-low-level-calls
        (bool success, bytes memory result_) = address(account).call{
            value: 0,
            gas: gasleft()
        }(_data);

        if (!success) {
            // solhint-disable reason-string
            if (result_.length < 68) revert();

            // solhint-disable no-inline-assembly
            assembly {
                result_ := add(result_, 0x04)
            }
            revert(abi.decode(result_, (string)));
        }

        emit Executed(msg.value, _data);
        return result_.length > 0 ? abi.decode(result_, (bytes)) : result_;
    }

    /**
     * @notice verify the nonce `_idx` for `_from` (obtained via `getNonce(...)`)
     * @dev "idx" is a 256bits (unsigned) integer, where:
     *          - the 128 leftmost bits = channelId
     *      and - the 128 rightmost bits = nonce within the channel
     * @param _from caller address
     * @param _idx (channel id + nonce within the channel)
     */
    function _isValidNonce(address _from, uint256 _idx)
        internal
        view
        returns (bool)
    {
        // idx % (1 << 128) = nonce
        // (idx >> 128) = channel
        // equivalent to: return (nonce == _nonceStore[_from][channel]
        return (_idx % (1 << 128)) == (_nonceStore[_from][_idx >> 128]);
    }

    /**
     * @dev verify the permissions of the _from address that want to interact with the `account`
     * @param _from the address making the request
     * @param _data the payload that will be run on `account`
     */
    function _verifyPermissions(address _from, bytes calldata _data)
        internal
        view
    {
        bytes4 erc725Function = bytes4(_data[:4]);

        if (erc725Function == account.setData.selector) {
            _verifyCanSetData(_from, _data);
        } else if (erc725Function == account.execute.selector) {
            _verifyCanExecute(_from, _data);

            address to = address(bytes20(_data[48:68]));
            _verifyAllowedAddress(_from, to);

            if (to.isContract()) {
                _verifyAllowedStandard(_from, to);

                if (_data.length >= 168) {
                    // extract bytes4 function selector from payload
                    _verifyAllowedFunction(_from, bytes4(_data[164:168]));
                }
            }
        } else if (erc725Function == account.transferOwnership.selector) {
            bytes32 permissions = account.getPermissionsFor(_from);

            if (!_hasPermission(_PERMISSION_CHANGEOWNER, permissions))
                revert NotAuthorised(_from, "TRANSFEROWNERSHIP");
        } else {
            revert("_verifyPermissions: unknown ERC725 selector");
        }
    }

    /**
     * @dev verify if `_from` has the required permissions to set some keys
     * on the linked ERC725Account
     * @param _from the address who want to set the keys
     * @param _data the ABI encoded payload `account.setData(keys, values)`
     * containing a list of keys-value pairs
     */
    function _verifyCanSetData(address _from, bytes calldata _data)
        internal
        view
    {
        bytes32 permissions = account.getPermissionsFor(_from);

        (bytes32[] memory inputKeys, ) = abi.decode(
            _data[4:],
            (bytes32[], bytes[])
        );

        bool isSettingERC725YKeys = false;

        // loop through the keys we are trying to set
        for (uint256 ii = 0; ii < inputKeys.length; ii++) {
            bytes32 key = inputKeys[ii];

            // prettier-ignore
            // if the key is a permission key
            if (bytes8(key) == _SET_PERMISSIONS_PREFIX) {
                _verifyCanSetPermissions(key, _from, permissions);

                // "nullify permission keys, 
                // so that they do not get check against allowed ERC725Y keys
                inputKeys[ii] = bytes32(0);

            // if the key is any other bytes32 key
            } else {
                isSettingERC725YKeys = true;
            }
        }

        if (isSettingERC725YKeys) {
            if (!_hasPermission(_PERMISSION_SETDATA, permissions))
                revert NotAuthorised(_from, "SETDATA");

            _verifyAllowedERC725YKeys(_from, inputKeys);
        }
    }

    function _verifyCanSetPermissions(
        bytes32 _key,
        address _from,
        bytes32 _callerPermissions
    ) internal view {
        // prettier-ignore
        // check if some permissions are already stored under this key
        if (bytes32(ERC725Y(account).getDataSingle(_key)) == bytes32(0)) {
            // if nothing is stored under this key,
            // we are trying to ADD permissions for a NEW address
            if (!_hasPermission(_PERMISSION_ADDPERMISSIONS, _callerPermissions))
                revert NotAuthorised(_from, "ADDPERMISSIONS");
        } else {
            // if there are already a value stored under this key,
            // we are trying to CHANGE the permissions of an address
            // (that has already some EXISTING permissions set)
            if (!_hasPermission(_PERMISSION_CHANGEPERMISSIONS, _callerPermissions)) 
                revert NotAuthorised(_from, "CHANGEPERMISSIONS");
        }
    }

    function _verifyAllowedERC725YKeys(
        address _from,
        bytes32[] memory _inputKeys
    ) internal view {
        bytes memory allowedERC725YKeysEncoded = ERC725Y(account).getDataSingle(
            LSP2Utils.generateBytes20MappingWithGroupingKey(
                _ADDRESS_ALLOWEDERC725YKEYS,
                bytes20(_from)
            )
        );

        // whitelist any ERC725Y key if nothing in the list
        if (allowedERC725YKeysEncoded.length == 0) return;

        bytes32[] memory allowedERC725YKeys = abi.decode(
            allowedERC725YKeysEncoded,
            (bytes32[])
        );

        bytes memory allowedKeySlice;
        bytes memory inputKeySlice;
        uint256 sliceLength;

        bool isAllowedKey;

        // save the not allowed key for cusom revert error
        bytes32 notAllowedKey;

        // loop through each allowed ERC725Y key retrieved from storage
        for (uint256 ii = 0; ii < allowedERC725YKeys.length; ii++) {
            // save the length of the slice
            // so to know which part to compare for each key we are trying to set
            (allowedKeySlice, sliceLength) = _extractKeySlice(
                allowedERC725YKeys[ii]
            );

            // loop through each keys given as input
            for (uint256 jj = 0; jj < _inputKeys.length; jj++) {
                // skip permissions keys that have been "nulled" previously
                if (_inputKeys[jj] == bytes32(0)) continue;

                // extract the slice to compare with the allowed key
                inputKeySlice = BytesLib.slice(
                    bytes.concat(_inputKeys[jj]),
                    0,
                    sliceLength
                );

                isAllowedKey =
                    keccak256(allowedKeySlice) == keccak256(inputKeySlice);

                // if the keys match, the key is allowed so stop iteration
                if (isAllowedKey) break;

                // if the keys do not match, save this key as a not allowed key
                notAllowedKey = _inputKeys[jj];
            }

            // if after checking all the keys given as input we did not find any not allowed key
            // stop checking the other allowed ERC725Y keys
            if (isAllowedKey == true) break;
        }

        // we always revert with the last not-allowed key that we found in the keys given as inputs
        if (isAllowedKey == false)
            revert NotAllowedERC725YKey(_from, notAllowedKey);
    }

    /**
     * @dev verify if `_from` has the required permissions to make an external call
     * via the linked ERC725Account
     * @param _from the address who want to run the execute function on the ERC725Account
     * @param _data the ABI encoded payload `account.execute(...)`
     */
    function _verifyCanExecute(address _from, bytes calldata _data)
        internal
        view
    {
        bytes32 permissions = account.getPermissionsFor(_from);

        uint256 operationType = uint256(bytes32(_data[4:36]));
        uint256 value = uint256(bytes32(_data[68:100]));

        require(
            operationType != 4,
            "_verifyCanExecute: operation 4 `DELEGATECALL` not supported"
        );

        (
            bytes32 permissionRequired,
            string memory operationName
        ) = _extractPermissionFromOperation(operationType);

        if (!_hasPermission(permissionRequired, permissions))
            revert NotAuthorised(_from, operationName);

        if (
            (value > 0) &&
            !_hasPermission(_PERMISSION_TRANSFERVALUE, permissions)
        ) {
            revert NotAuthorised(_from, "TRANSFERVALUE");
        }
    }

    /**
     * @dev verify if `_from` is authorised to interact with address `_to` via the linked ERC725Account
     * @param _from the caller address
     * @param _to the address to interact with
     */
    function _verifyAllowedAddress(address _from, address _to) internal view {
        bytes memory allowedAddresses = account.getAllowedAddressesFor(_from);

        // whitelist any address if nothing in the list
        if (allowedAddresses.length == 0) return;

        address[] memory allowedAddressesList = abi.decode(
            allowedAddresses,
            (address[])
        );

        for (uint256 ii = 0; ii < allowedAddressesList.length; ii++) {
            if (_to == allowedAddressesList[ii]) return;
        }
        revert NotAllowedAddress(_from, _to);
    }

    /**
     * @dev if `_from` is restricted to interact with contracts that implement a specific interface,
     * verify that `_to` implements one of these interface.
     * @param _from the caller address
     * @param _to the address of the contract to interact with
     */
    function _verifyAllowedStandard(address _from, address _to) internal view {
        bytes memory allowedStandards = ERC725Y(account).getDataSingle(
            LSP2Utils.generateBytes20MappingWithGroupingKey(
                _ADDRESS_ALLOWEDSTANDARDS,
                bytes20(_from)
            )
        );

        // whitelist any standard interface (ERC165) if nothing in the list
        if (allowedStandards.length == 0) return;

        bytes4[] memory allowedStandardsList = abi.decode(
            allowedStandards,
            (bytes4[])
        );

        for (uint256 ii = 0; ii < allowedStandardsList.length; ii++) {
            if (_to.supportsInterface(allowedStandardsList[ii])) return;
        }
        revert("Not Allowed Standards");
    }

    /**
     * @dev verify if `_from` is authorised to use the linked ERC725Account
     * to run a specific function `_functionSelector` at a target contract
     * @param _from the caller address
     * @param _functionSelector the bytes4 function selector of the function to run
     * at the target contract
     */
    function _verifyAllowedFunction(address _from, bytes4 _functionSelector)
        internal
        view
    {
        bytes memory allowedFunctions = account.getAllowedFunctionsFor(_from);

        // whitelist any function if nothing in the list
        if (allowedFunctions.length == 0) return;

        bytes4[] memory allowedFunctionsList = abi.decode(
            allowedFunctions,
            (bytes4[])
        );

        for (uint256 ii = 0; ii < allowedFunctionsList.length; ii++) {
            if (_functionSelector == allowedFunctionsList[ii]) return;
        }
        revert NotAllowedFunction(_from, _functionSelector);
    }

    /**
     * @dev compare the permissions `_addressPermission` of an address with `_requiredPermission`
     * @param _requiredPermission the permission required
     * @param _addressPermission the permission of address that we want to check
     * @return true if address has enough permissions, false otherwise
     */
    function _hasPermission(
        bytes32 _requiredPermission,
        bytes32 _addressPermission
    ) internal pure returns (bool) {
        return
            (_requiredPermission & _addressPermission) == _requiredPermission
                ? true
                : false;
    }

    function _extractKeySlice(bytes32 _key)
        internal
        pure
        returns (bytes memory keySlice_, uint256 sliceLength_)
    {
        // check each individual bytes of the allowed key, starting from the end (right to left)
        for (uint256 index = 31; index >= 0; index--) {
            // find where the first non-empty bytes starts (skip empty bytes 0x00)
            if (_key[index] != 0x00) {
                // stop as soon as we find a non-empty byte
                sliceLength_ = index + 1;
                keySlice_ = BytesLib.slice(bytes.concat(_key), 0, sliceLength_);
                break;
            }
        }
    }

    /**
     * @dev extract the required permission + a descriptive string, based on the `_operationType`
     * being run via ERC725Account.execute(...)
     * @param _operationType 0 = CALL, 1 = CREATE, 2 = CREATE2, etc... See ERC725X docs for more infos.
     * @return bytes32 the permission associated with the `_operationType`
     * @return string the opcode associated with `_operationType`
     */
    function _extractPermissionFromOperation(uint256 _operationType)
        internal
        pure
        returns (bytes32, string memory)
    {
        require(
            _operationType < 5,
            "_extractPermissionFromOperation: invalid operation type"
        );

        if (_operationType == 0) return (_PERMISSION_CALL, "CALL");
        if (_operationType == 1) return (_PERMISSION_DEPLOY, "CREATE");
        if (_operationType == 2) return (_PERMISSION_DEPLOY, "CREATE2");
        if (_operationType == 3) return (_PERMISSION_DEPLOY, "STATICCALL");
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// interfaces
import "@openzeppelin/contracts/interfaces/IERC1271.sol";

/**
 * @dev Contract acting as a controller of an ERC725 Account, using permissions stored in the ERC725Y storage
 */
interface ILSP6KeyManager is
    IERC1271
    /* is ERC165 */
{
    event Executed(uint256 indexed _value, bytes _data);

    /**
     * @notice get latest nonce for `_from` for channel ID: `_channel`
     * @dev use channel ID = 0 for sequential nonces, any other number for out-of-order execution (= execution in parallel)
     * @param _address caller address
     * @param _channel channel id
     */
    function getNonce(address _address, uint256 _channel)
        external
        view
        returns (uint256);

    /**
     * @notice execute the following payload on the ERC725Account: `_data`
     * @dev the ERC725Account will return some data on successful call, or revert on failure
     * @param _data the payload to execute. Obtained in web3 via encodeABI()
     * @return result_ the data being returned by the ERC725 Account
     */
    function execute(bytes calldata _data)
        external
        payable
        returns (bytes memory);

    /**
     * @dev allows anybody to execute given they have a signed message from an executor
     * @param _signedFor this KeyManager
     * @param _nonce the address' nonce (in a specific `_channel`), obtained via `getNonce(...)`. Used to prevent replay attack
     * @param _data obtained via encodeABI() in web3
     * @param _signature bytes32 ethereum signature
     * @return result_ the data being returned by the ERC725 Account
     */
    function executeRelayCall(
        address _signedFor,
        uint256 _nonce,
        bytes calldata _data,
        bytes memory _signature
    ) external payable returns (bytes memory);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// constants
import "../LSP6KeyManager/LSP6Constants.sol";

// libraries
import "../Utils/LSP2Utils.sol";
import "..//Utils/ERC725Utils.sol";

library LSP6Utils {
    using LSP2Utils for bytes12;
    using ERC725Utils for IERC725Y;

    function getPermissionsFor(IERC725Y _account, address _address)
        internal
        view
        returns (bytes32)
    {
        bytes memory permissions = _account.getDataSingle(
            LSP2Utils.generateBytes20MappingWithGroupingKey(
                _ADDRESS_PERMISSIONS,
                bytes20(_address)
            )
        );

        if (bytes32(permissions) == bytes32(0)) {
            revert(
                "LSP6Utils:getPermissionsFor: no permissions set for this address"
            );
        }

        return bytes32(permissions);
    }

    function getAllowedAddressesFor(IERC725Y _account, address _address)
        internal
        view
        returns (bytes memory)
    {
        return
            _account.getDataSingle(
                LSP2Utils.generateBytes20MappingWithGroupingKey(
                    _ADDRESS_ALLOWEDADDRESSES,
                    bytes20(_address)
                )
            );
    }

    function getAllowedFunctionsFor(IERC725Y _account, address _address)
        internal
        view
        returns (bytes memory)
    {
        return
            _account.getDataSingle(
                LSP2Utils.generateBytes20MappingWithGroupingKey(
                    _ADDRESS_ALLOWEDFUNCTIONS,
                    bytes20(_address)
                )
            );
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// --- ERC165 interface ids
bytes4 constant _INTERFACEID_LSP6 = 0x6f4df48b;

/* solhint-disable */
// PERMISSION KEYS
// prettier-ignore
bytes8 constant _SET_PERMISSIONS_PREFIX           = 0x4b80742d00000000; // AddressPermissions:<...>
bytes12 constant _ADDRESS_PERMISSIONS = 0x4b80742d0000000082ac0000; // AddressPermissions:Permissions:<address> --> bytes32
bytes12 constant _ADDRESS_ALLOWEDADDRESSES = 0x4b80742d00000000c6dd0000; // AddressPermissions:AllowedAddresses:<address> --> address[]
bytes12 constant _ADDRESS_ALLOWEDFUNCTIONS = 0x4b80742d000000008efe0000; // AddressPermissions:AllowedFunctions:<address> --> bytes4[]
bytes12 constant _ADDRESS_ALLOWEDSTANDARDS = 0x4b80742d000000003efa0000; // AddressPermissions:AllowedStandards:<address> --> bytes4[]
bytes12 constant _ADDRESS_ALLOWEDERC725YKEYS = 0x4b80742d0000000090b80000; // AddressPermissions:AllowedERC725YKeys:<address> --> bytes32[]
/* solhint-enable */

// PERMISSIONS VALUES
// prettier-ignore
bytes32 constant _PERMISSION_CHANGEOWNER       = 0x0000000000000000000000000000000000000000000000000000000000000001; // [240 x 0 bits...] 0000 0000 0000 0001
bytes32 constant _PERMISSION_CHANGEPERMISSIONS = 0x0000000000000000000000000000000000000000000000000000000000000002; // [      ...      ] .... .... .... 0010
bytes32 constant _PERMISSION_ADDPERMISSIONS = 0x0000000000000000000000000000000000000000000000000000000000000004; // [      ...      ] .... .... .... 0100
bytes32 constant _PERMISSION_SETDATA = 0x0000000000000000000000000000000000000000000000000000000000000008; // [      ...      ] .... .... .... 1000
bytes32 constant _PERMISSION_CALL = 0x0000000000000000000000000000000000000000000000000000000000000010; // [      ...      ] .... .... 0001 ....
bytes32 constant _PERMISSION_STATICCALL = 0x0000000000000000000000000000000000000000000000000000000000000020; // [      ...      ] .... .... 0010 ....
bytes32 constant _PERMISSION_DELEGATECALL = 0x0000000000000000000000000000000000000000000000000000000000000040; // [      ...      ] .... .... 0100 ....
bytes32 constant _PERMISSION_DEPLOY = 0x0000000000000000000000000000000000000000000000000000000000000080; // [      ...      ] .... .... 1000 ....
bytes32 constant _PERMISSION_TRANSFERVALUE = 0x0000000000000000000000000000000000000000000000000000000000000100; // [      ...      ] .... 0001 .... ....
bytes32 constant _PERMISSION_SIGN = 0x0000000000000000000000000000000000000000000000000000000000000200; // [      ...      ] .... 0010 .... ....

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @title ERC725 Utility library to encode key types
 * @author Jean Cavallera (CJ-42)
 * @dev based on LSP2 - ERC725Y JSON Schema
 *      https://github.com/lukso-network/LIPs/blob/master/LSPs/LSP-2-ERC725YJSONSchema.md
 */
library LSP2Utils {
    /* solhint-disable no-inline-assembly */
    function generateSingletonKey(string memory _keyName)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(bytes(_keyName));
    }

    function generateArrayKey(string memory _keyName)
        internal
        pure
        returns (bytes32)
    {
        bytes memory keyName = bytes(_keyName);

        // prettier-ignore
        require(
            keyName[keyName.length - 2] == 0x5b && // "[" in utf8 encoded
                keyName[keyName.length - 1] == 0x5d, // "]" in utf8
            "Missing empty square brackets \"[]\" at the end of the key name"
        );

        return keccak256(keyName);
    }

    function generateMappingKey(
        string memory _firstWord,
        string memory _lastWord
    ) internal pure returns (bytes32 key_) {
        bytes32 firstWordHash = keccak256(bytes(_firstWord));
        bytes32 lastWordHash = keccak256(bytes(_lastWord));

        bytes memory temporaryBytes = abi.encodePacked(
            bytes16(firstWordHash),
            bytes12(0),
            bytes4(lastWordHash)
        );

        assembly {
            key_ := mload(add(temporaryBytes, 32))
        }
    }

    function generateBytes20MappingKey(
        string memory _firstWord,
        address _address
    ) internal pure returns (bytes32 key_) {
        bytes32 firstWordHash = keccak256(bytes(_firstWord));

        bytes memory temporaryBytes = abi.encodePacked(
            bytes8(firstWordHash),
            bytes4(0),
            _address
        );

        assembly {
            key_ := mload(add(temporaryBytes, 32))
        }
    }

    function generateBytes20MappingWithGroupingKey(
        string memory _firstWord,
        string memory _secondWord,
        address _address
    ) internal pure returns (bytes32 key_) {
        bytes32 firstWordHash = keccak256(bytes(_firstWord));
        bytes32 secondWordHash = keccak256(bytes(_secondWord));

        bytes memory temporaryBytes = abi.encodePacked(
            bytes4(firstWordHash),
            bytes4(0),
            bytes2(secondWordHash),
            bytes2(0),
            _address
        );

        assembly {
            key_ := mload(add(temporaryBytes, 32))
        }
    }

    function generateBytes20MappingWithGroupingKey(
        bytes12 _keyPrefix,
        bytes20 _bytes20
    ) internal pure returns (bytes32) {
        bytes memory generatedKey = bytes.concat(_keyPrefix, _bytes20);
        bytes32 toBytes32Key;
        // solhint-disable-next-line
        assembly {
            toBytes32Key := mload(add(generatedKey, 32))
        }
        return toBytes32Key;
    }

    function generateJSONURLValue(
        string memory _hashFunction,
        string memory _json,
        string memory _url
    ) internal pure returns (bytes memory key_) {
        bytes32 hashFunctionDigest = keccak256(bytes(_hashFunction));
        bytes32 jsonDigest = keccak256(bytes(_json));

        key_ = abi.encodePacked(bytes4(hashFunctionDigest), jsonDigest, _url);
    }

    function generateASSETURLValue(
        string memory _hashFunction,
        string memory _assetBytes,
        string memory _url
    ) internal pure returns (bytes memory key_) {
        bytes32 hashFunctionDigest = keccak256(bytes(_hashFunction));
        bytes32 jsonDigest = keccak256(bytes(_assetBytes));

        key_ = abi.encodePacked(bytes4(hashFunctionDigest), jsonDigest, _url);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.6;

// modules
import "./LSP6KeyManagerCore.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * @title Proxy implementation of a contract acting as a controller of an ERC725 Account, using permissions stored in the ERC725Y storage
 * @author Fabian Vogelsteller, Jean Cavallera
 * @dev all the permissions can be set on the ERC725 Account using `setData(...)` with the keys constants below
 */
abstract contract LSP6KeyManagerInitAbstract is
    Initializable,
    LSP6KeyManagerCore
{
    /**
     * @notice Initiate the account with the address of the ERC725Account contract and sets LSP6KeyManager InterfaceId
     * @param _account The address of the ER725Account to control
     */
    function initialize(address _account) public virtual onlyInitializing {
        account = ERC725(_account);
        _registerInterface(_INTERFACEID_LSP6);
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./Handling/TokenAndVaultHandling.sol";

import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

import "../ILSP1UniversalReceiverDelegate.sol";

/**
 * @title Core Implementation of contract writing the received Vaults and LSP7, LSP8 assets into your ERC725Account using
 *        the LSP5-ReceivedAsset and LSP10-ReceivedVaults standard and removing the sent vaults and assets.
 *
 * @author Fabian Vogelsteller, Yamen Merhi, Jean Cavallera
 * @dev Delegate contract of the initial universal receiver
 *
 * Owner of the UniversalProfile MUST be a KeyManager that allows (this) address to setData on the UniversalProfile
 *
 */
abstract contract LSP1UniversalReceiverDelegateUPCore is
    ILSP1UniversalReceiverDelegate,
    ERC165Storage,
    TokenAndVaultHandlingContract
{
    /**
     * @inheritdoc ILSP1UniversalReceiverDelegate
     * @dev Allows to register arrayKeys and Map of incoming vaults and assets and removing them after being sent
     * @return result the return value of keyManager's execute function
     */
    function universalReceiverDelegate(
        address sender,
        bytes32 typeId,
        bytes memory data
    ) public override returns (bytes memory result) {
        if (
            typeId == _TYPEID_LSP7_TOKENSSENDER ||
            typeId == _TYPEID_LSP7_TOKENSRECIPIENT ||
            typeId == _TYPEID_LSP8_TOKENSSENDER ||
            typeId == _TYPEID_LSP8_TOKENSRECIPIENT ||
            typeId == _TYPEID_LSP9_VAULTSENDER ||
            typeId == _TYPEID_LSP9_VAULTRECIPIENT
        ) {
            result = _tokenAndVaultHandling(sender, typeId, data);
        }

        /* @TODO
          else if() {
            result = FollowerHandling(sender, typeId, data);
            }
        */
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// modules
import "@erc725/smart-contracts/contracts/ERC725Y.sol";
import "../../../LSP6KeyManager/LSP6KeyManager.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

// interfaces
import "../../../LSP6KeyManager/ILSP6KeyManager.sol";
import "../../../LSP7DigitalAsset/ILSP7DigitalAsset.sol";

// libraries
import "../../../Utils/ERC725Utils.sol";

// constants
import "../../LSP1Constants.sol";
import "../../../LSP6KeyManager/LSP6Constants.sol";
import "../../../LSP7DigitalAsset/LSP7Constants.sol";
import "../../../LSP8IdentifiableDigitalAsset/LSP8Constants.sol";
import "../../../LSP9Vault/LSP9Constants.sol";

/**
 * @dev Function logic to add and remove the MapAndArrayKey of incoming assets and vaults
 */
abstract contract TokenAndVaultHandlingContract {
    using ERC725Utils for IERC725Y;

    function _tokenAndVaultHandling(
        address sender,
        bytes32 typeId,
        bytes memory data
    ) internal returns (bytes memory result) {
        address keyManagerAddress = ERC725Y(msg.sender).owner();
        _profileChecker(keyManagerAddress);

        if (
            ERC165Checker.supportsInterface(
                keyManagerAddress,
                _INTERFACEID_LSP6
            )
        ) {
            (
                bytes32 arrayKey,
                bytes32 mapHash,
                bytes4 interfaceID
            ) = _getTransferData(typeId);
            bytes32 mapKey = ERC725Utils.generateMapKey(
                mapHash,
                abi.encodePacked(sender)
            );
            bytes memory mapValue = IERC725Y(msg.sender).getDataSingle(mapKey);

            if (
                typeId == _TYPEID_LSP7_TOKENSRECIPIENT ||
                typeId == _TYPEID_LSP8_TOKENSRECIPIENT ||
                typeId == _TYPEID_LSP9_VAULTRECIPIENT
            ) {
                if (bytes12(mapValue) == bytes12(0)) {
                    (bytes32[] memory keys, bytes[] memory values) = ERC725Utils
                        .addMapAndArrayKey(
                            IERC725Y(msg.sender),
                            arrayKey,
                            mapKey,
                            sender,
                            interfaceID
                        );

                    result = _executeViaKeyManager(
                        ILSP6KeyManager(keyManagerAddress),
                        keys,
                        values
                    );
                }
            } else if (
                typeId == _TYPEID_LSP7_TOKENSSENDER ||
                typeId == _TYPEID_LSP8_TOKENSSENDER ||
                typeId == _TYPEID_LSP9_VAULTSENDER
            ) {
                if (bytes12(mapValue) != bytes12(0)) {
                    if (typeId == _TYPEID_LSP9_VAULTSENDER) {
                        (
                            bytes32[] memory keys,
                            bytes[] memory values
                        ) = ERC725Utils.removeMapAndArrayKey(
                                IERC725Y(msg.sender),
                                arrayKey,
                                mapHash,
                                mapKey
                            );

                        result = _executeViaKeyManager(
                            ILSP6KeyManager(keyManagerAddress),
                            keys,
                            values
                        );
                    } else if (
                        typeId == _TYPEID_LSP7_TOKENSSENDER ||
                        typeId == _TYPEID_LSP8_TOKENSSENDER
                    ) {
                        uint256 balance = ILSP7DigitalAsset(sender).balanceOf(
                            msg.sender
                        );
                        if ((balance - _tokenAmount(typeId, data)) == 0) {
                            (
                                bytes32[] memory keys,
                                bytes[] memory values
                            ) = ERC725Utils.removeMapAndArrayKey(
                                    IERC725Y(msg.sender),
                                    arrayKey,
                                    mapHash,
                                    mapKey
                                );

                            result = _executeViaKeyManager(
                                ILSP6KeyManager(keyManagerAddress),
                                keys,
                                values
                            );
                        }
                    }
                }
            }
        }
    }

    // helper functions

    function _getTransferData(bytes32 _typeId)
        private
        pure
        returns (
            bytes32 _arrayKey,
            bytes32 _mapHash,
            bytes4 _interfaceID
        )
    {
        if (
            _typeId == _TYPEID_LSP7_TOKENSSENDER ||
            _typeId == _TYPEID_LSP7_TOKENSRECIPIENT ||
            _typeId == _TYPEID_LSP8_TOKENSSENDER ||
            _typeId == _TYPEID_LSP8_TOKENSRECIPIENT
        ) {
            _arrayKey = _ARRAYKEY_LSP5;
            _mapHash = _MAPHASH_LSP5;
            if (
                _typeId == _TYPEID_LSP7_TOKENSSENDER ||
                _typeId == _TYPEID_LSP7_TOKENSRECIPIENT
            ) {
                _interfaceID = _INTERFACEID_LSP7;
            } else {
                _interfaceID = _INTERFACEID_LSP8;
            }
        } else if (
            _typeId == _TYPEID_LSP9_VAULTSENDER ||
            _typeId == _TYPEID_LSP9_VAULTRECIPIENT
        ) {
            _arrayKey = _ARRAYKEY_LSP10;
            _mapHash = _MAPHASH_LSP10;
            _interfaceID = _INTERFACEID_LSP9;
        }
    }

    function _executeViaKeyManager(
        ILSP6KeyManager _keyManagerAdd,
        bytes32[] memory _keys,
        bytes[] memory _values
    ) private returns (bytes memory result) {
        bytes memory payload = abi.encodeWithSelector(
            IERC725Y.setData.selector,
            _keys,
            _values
        );
        result = ILSP6KeyManager(_keyManagerAdd).execute(payload);
    }

    function _tokenAmount(bytes32 _typeId, bytes memory _data)
        private
        pure
        returns (uint256 amount)
    {
        if (_typeId == _TYPEID_LSP7_TOKENSSENDER) {
            /* solhint-disable */
            assembly {
                amount := mload(add(add(_data, 0x20), 0x28))
            }
            /* solhint-enable */
        } else {
            amount = 1;
        }
    }

    function _profileChecker(address keyManagerAddress) private {
        address profileAddress = address(
            LSP6KeyManager(keyManagerAddress).account()
        );
        require(
            profileAddress == msg.sender,
            "Security: The called Key Manager belongs to a different account"
        );
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.6;

// modules
import "./LSP6KeyManagerCore.sol";

/**
 * @title Implementation of a contract acting as a controller of an ERC725 Account, using permissions stored in the ERC725Y storage
 * @author Fabian Vogelsteller, Jean Cavallera
 * @dev all the permissions can be set on the ERC725 Account using `setData(...)` with the keys constants below
 */
contract LSP6KeyManager is LSP6KeyManagerCore {
    /**
     * @notice Initiate the account with the address of the ERC725Account contract and sets LSP6KeyManager InterfaceId
     * @param _account The address of the ER725Account to control
     */
    constructor(address _account) {
        account = ERC725(_account);
        _registerInterface(_INTERFACEID_LSP6);
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// --- ERC165 interface ids
bytes4 constant _INTERFACEID_LSP9 = 0x75edcee5;

// --- ERC725Y entries

// --- Token Hooks
bytes32 constant _TYPEID_LSP9_VAULTSENDER = 0x3ca9f769340018257ac15b3a00e502e8fb730d66086f774210f84d0205af31e7; // keccak256("LSP9VaultSender")

bytes32 constant _TYPEID_LSP9_VAULTRECIPIENT = 0x09aaf55960715d8d86b57af40be36b0bfd469c9a3643445d8c65d39e27b4c56f; // keccak256("LSP9VaultRecipient")

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// modules
import "./LSP1UniversalReceiverDelegateUPCore.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * @title Inheritable Proxy Implementation of contract writing the received Vaults and LSP7, LSP8 assets into your ERC725Account using
 *        the LSP5-ReceivedAsset and LSP10-ReceivedVaults standard and removing the sent vaults and assets.
 *
 * @author Fabian Vogelsteller, Yamen Merhi, Jean Cavallera
 * @dev Delegate contract of the initial universal receiver
 *
 * Owner of the UniversalProfile MUST be a KeyManager that allows (this) address to setData on the UniversalProfile
 *
 */
abstract contract LSP1UniversalReceiverDelegateUPInitAbstract is
    Initializable,
    LSP1UniversalReceiverDelegateUPCore
{
    /**
     * @notice Register the LSP1UniversalReceiverDelegate InterfaceId
     */
    function initialize() public virtual onlyInitializing {
        _registerInterface(_INTERFACEID_LSP1_DELEGATE);
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// modules
import "./LSP1UniversalReceiverDelegateUPInitAbstract.sol";

/**
 * @title Deployable Proxy Implementation of contract writing the received Vaults and LSP7, LSP8 assets into your ERC725Account using
 *        the LSP5-ReceivedAsset and LSP10-ReceivedVaults standard and removing the sent vaults and assets.
 *
 * @author Fabian Vogelsteller, Yamen Merhi, Jean Cavallera
 * @dev Delegate contract of the initial universal receiver
 *
 * Owner of the UniversalProfile MUST be a KeyManager that allows (this) address to setData on the UniversalProfile
 *
 */
contract LSP1UniversalReceiverDelegateUPInit is
    LSP1UniversalReceiverDelegateUPInitAbstract
{
    /**
     * @inheritdoc LSP1UniversalReceiverDelegateUPInitAbstract
     */
    function initialize() public virtual override initializer {
        LSP1UniversalReceiverDelegateUPInitAbstract.initialize();
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

// interfaces
import "./ILSP1UniversalReceiverDelegateUPProxy.sol";

// modules
import "@lukso/universalprofile-smart-contracts/contracts/LSP1UniversalReceiver/LSP1UniversalReceiverDelegateUP/LSP1UniversalReceiverDelegateUPInit.sol";

contract LSP1UniversalReceiverDelegateUPProxy is
    ILSP1UniversalReceiverDelegateUPProxy,
    LSP1UniversalReceiverDelegateUPInit
{
    // solhint-disable-next-line no-empty-blocks
    constructor() initializer {
        // when the base logic contract is deployed, the initialized flag should get set so its not
        // possible to call `initialize(...)`
    }

    function initialize()
        public
        override(
            ILSP1UniversalReceiverDelegateUPProxy,
            LSP1UniversalReceiverDelegateUPInit
        )
    {
        super.initialize();
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface ILSP1UniversalReceiverDelegateUPProxy {
    function initialize() external;
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// libs
import "@openzeppelin/contracts/proxy/Clones.sol";

// interfaces
import "./ILSP1UniversalReceiverDelegateUPProxy.sol";

// modules
import "@openzeppelin/contracts/access/Ownable.sol";
import "./LSP1UniversalReceiverDelegateUPProxy.sol";

contract LSP1UniversalReceiverDelegateUPProxyFactory is Ownable {
    //
    // --- Errors
    //

    error LSP1UniversalReceiverDelegateUPProxyFactoryImplementationRequired();

    //
    // --- Storage
    //

    address public implementation;

    constructor() {
        implementation = address(new LSP1UniversalReceiverDelegateUPProxy());

        if (implementation == address(0)) {
            revert LSP1UniversalReceiverDelegateUPProxyFactoryImplementationRequired();
        }
    }

    function deployProxy(bytes32 salt) public onlyOwner returns (address) {
        address clone = Clones.cloneDeterministic(implementation, salt);
        ILSP1UniversalReceiverDelegateUPProxy(clone).initialize();

        return clone;
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// libs
import "@openzeppelin/contracts/proxy/Clones.sol";

// interfaces
import "./IUniversalProfileProxy.sol";

// modules
import "@openzeppelin/contracts/access/Ownable.sol";
import "./UniversalProfileProxy.sol";

contract UniversalProfileProxyFactory is Ownable {
    //
    // --- Errors
    //

    error UniversalProfileProxyFactoryImplementationRequired();

    //
    // --- Storage
    //

    address public implementation;

    constructor() {
        implementation = address(new UniversalProfileProxy());

        if (implementation == address(0)) {
            revert UniversalProfileProxyFactoryImplementationRequired();
        }
    }

    function deployProxy(bytes32 salt, address newOwner)
        public
        onlyOwner
        returns (address)
    {
        address clone = Clones.cloneDeterministic(implementation, salt);
        IUniversalProfileProxy(clone).initialize(newOwner);

        return clone;
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface IUniversalProfileProxy {
    function initialize(address newOwner) external;
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

// interfaces
import "./IUniversalProfileProxy.sol";

// modules
import "@lukso/universalprofile-smart-contracts/contracts/UniversalProfileInit.sol";

contract UniversalProfileProxy is IUniversalProfileProxy, UniversalProfileInit {
    // solhint-disable-next-line no-empty-blocks
    constructor() initializer {
        // when the base logic contract is deployed, the initialized flag should get set so its not
        // possible to call `initialize(...)`
    }

    function initialize(address universalProfile)
        public
        override(IUniversalProfileProxy, UniversalProfileInit)
    {
        super.initialize(universalProfile);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// modules
import "./UniversalProfileInitAbstract.sol";

/**
 * @title Deployable Proxy implementation of a LUKSO's Universal Profile based on LSP3
 * @author Fabian Vogelsteller <[email protected]>
 * @dev Implementation of the ERC725Account + LSP1 universalReceiver
 */
contract UniversalProfileInit is UniversalProfileInitAbstract {
    /**
     * @inheritdoc UniversalProfileInitAbstract
     */
    function initialize(address _newOwner) public virtual override initializer {
        UniversalProfileInitAbstract.initialize(_newOwner);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// modules
import "./LSP0ERC725Account/LSP0ERC725AccountInitAbstract.sol";

/**
 * @title Inheritable Proxy implementation of a LUKSO's Universal Profile based on LSP3
 * @author Fabian Vogelsteller <[email protected]>
 * @dev Implementation of the ERC725Account + LSP1 universalReceiver
 */
abstract contract UniversalProfileInitAbstract is
    Initializable,
    LSP0ERC725AccountInitAbstract
{
    /**
     * @notice Sets the owner of the contract and sets the SupportedStandards:LSP3UniversalProfile key
     * @param _newOwner the owner of the contract
     */
    function initialize(address _newOwner)
        public
        virtual
        override
        onlyInitializing
    {
        LSP0ERC725AccountInitAbstract.initialize(_newOwner);

        // set SupportedStandards:LSP3UniversalProfile
        bytes32 key = 0xeafec4d89fa9619884b6b89135626455000000000000000000000000abe425d6;
        bytes memory value = hex"abe425d6";
        _setData(key, value);
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// libs
import "@openzeppelin/contracts/proxy/Clones.sol";

// interfaces
import "./ILSP6KeyManagerProxy.sol";

// modules
import "@openzeppelin/contracts/access/Ownable.sol";
import "./LSP6KeyManagerProxy.sol";

contract LSP6KeyManagerProxyFactory is Ownable {
    //
    // --- Errors
    //

    error LSP6KeyManagerProxyFactoryImplementationRequired();

    //
    // --- Storage
    //

    address public implementation;

    constructor() {
        implementation = address(new LSP6KeyManagerProxy());

        if (implementation == address(0)) {
            revert LSP6KeyManagerProxyFactoryImplementationRequired();
        }
    }

    function deployProxy(bytes32 salt, address universalProfile)
        public
        onlyOwner
        returns (address)
    {
        address clone = Clones.cloneDeterministic(implementation, salt);
        ILSP6KeyManagerProxy(clone).initialize(universalProfile);

        return clone;
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface ILSP6KeyManagerProxy {
    function initialize(address universalProfile) external;
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

// interfaces
import "./ILSP6KeyManagerProxy.sol";

// modules
import "@lukso/universalprofile-smart-contracts/contracts/LSP6KeyManager/LSP6KeyManagerInit.sol";

contract LSP6KeyManagerProxy is ILSP6KeyManagerProxy, LSP6KeyManagerInit {
    // solhint-disable-next-line no-empty-blocks
    constructor() initializer {
        // when the base logic contract is deployed, the initialized flag should get set so its not
        // possible to call `initialize(...)`
    }

    function initialize(address universalProfile)
        public
        override(ILSP6KeyManagerProxy, LSP6KeyManagerInit)
    {
        super.initialize(universalProfile);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.6;

// modules
import "./LSP6KeyManagerInitAbstract.sol";

/**
 * @title Proxy implementation of a contract acting as a controller of an ERC725 Account, using permissions stored in the ERC725Y storage
 * @author Fabian Vogelsteller, Jean Cavallera
 * @dev all the permissions can be set on the ERC725 Account using `setData(...)` with the keys constants below
 */
contract LSP6KeyManagerInit is LSP6KeyManagerInitAbstract {
    /**
     * @inheritdoc LSP6KeyManagerInitAbstract
     */
    function initialize(address _account) public virtual override initializer {
        LSP6KeyManagerInitAbstract.initialize(_account);
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// modules
import "@lukso/universalprofile-smart-contracts/contracts/LSP6KeyManager/LSP6KeyManager.sol";

/* solhint-disable no-empty-blocks */

// NOTE: need to make this an abstract class to get hardhat to compile it (and get typechain generated classes)
abstract contract ImportLSP6KeyManager is LSP6KeyManager {

}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// modules
import "./LSP1UniversalReceiverDelegateUPCore.sol";

/**
 * @title Implementation of contract writing the received Vaults and LSP7, LSP8 assets into your ERC725Account using
 *        the LSP5-ReceivedAsset and LSP10-ReceivedVaults standard and removing the sent vaults and assets.
 *
 * @author Fabian Vogelsteller, Yamen Merhi, Jean Cavallera
 * @dev Delegate contract of the initial universal receiver
 *
 * Owner of the UniversalProfile MUST be a KeyManager that allows (this) address to setData on the UniversalProfile
 *
 */
contract LSP1UniversalReceiverDelegateUP is
    LSP1UniversalReceiverDelegateUPCore
{
    /**
     * @notice Register the LSP1UniversalReceiverDelegate InterfaceId
     */
    constructor() {
        _registerInterface(_INTERFACEID_LSP1_DELEGATE);
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// modules
import "@lukso/universalprofile-smart-contracts/contracts/LSP1UniversalReceiver/LSP1UniversalReceiverDelegateUP/LSP1UniversalReceiverDelegateUP.sol";

/* solhint-disable no-empty-blocks */

// NOTE: need to make this an abstract class to get hardhat to compile it (and get typechain generated classes)
abstract contract ImportLSP1UniversalReceiverDelegateUP is
    LSP1UniversalReceiverDelegateUP
{

}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// libs
import "../royalties/RoyaltySharesLib.sol";

contract TestFeeCollectorMock {
    function shareRevenue(
        address token,
        uint256 amount,
        address referrer,
        RoyaltySharesLib.RoyaltyShare[] calldata creatorRoyalties,
        bytes calldata dataForCallback
    ) external pure returns (uint256) {
        // silence compiler warning about unused variable
        token;
        amount;
        referrer;
        creatorRoyalties;
        dataForCallback;

        return 0;
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// interfaces
import "./IContractRegistry.sol";

// modules
import "@openzeppelin/contracts/access/Ownable.sol";

contract ContractRegistry is Ownable, IContractRegistry {
    //
    // --- Error
    //

    error ContractRegistryNotRegistered(bytes32 nameHash);
    error ContractRegistryInvalidContract(address target);

    //
    // --- Storage
    //

    // TODO: could have EnumerableSet here
    mapping(bytes32 => address) private registeredContracts;
    mapping(address => bool) private whitelistedTokens;

    //
    // --- Registry Queries
    //

    function getRegisteredContract(bytes32 nameHash)
        public
        view
        override
        returns (address)
    {
        address target = registeredContracts[nameHash];

        if (target == address(0)) {
            revert ContractRegistryNotRegistered(nameHash);
        }

        return target;
    }

    //
    // --- Registry Logic
    //

    function setRegisteredContract(bytes32 nameHash, address target)
        public
        override
        onlyOwner
    {
        if (target.code.length == 0) {
            revert ContractRegistryInvalidContract(target);
        }

        registeredContracts[nameHash] = target;
    }

    function removeRegisteredContract(bytes32 nameHash)
        public
        override
        onlyOwner
    {
        delete registeredContracts[nameHash];
    }

    //
    // --- Whitelist Token Queries
    //

    function isWhitelistedToken(address token)
        public
        view
        override
        returns (bool)
    {
        return whitelistedTokens[token];
    }

    //
    // --- Whitelist Token Logic
    //

    function setWhitelistedToken(address token) public override onlyOwner {
        if (token.code.length == 0) {
            revert ContractRegistryInvalidContract(token);
        }

        whitelistedTokens[token] = true;
    }

    function removeWhitelistedToken(address token) public override onlyOwner {
        delete whitelistedTokens[token];
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

// interfaces
import "./ICardTokenScoring.sol";

// modules
import "../libraries/ABDKMathQuad.sol";

/**
 * @dev Logic required for providing a score for a card
 */
contract CardTokenScoring is ICardTokenScoring {
    /**
     * @dev Implemention for all Fanzone card scores. Expected not to be used in transactions as it
     * costs additional gas to do floating point math.
     */
    function calculateScore(
        uint256 tokenSupply,
        uint256 scoreMin,
        uint256 scoreMax,
        uint256 scoreScale,
        uint256 scoreMaxTokenId,
        uint256 tokenId
    ) public pure override returns (string memory) {
        // setup
        bytes16 tenQuad;
        bytes16 oneTenthQuad;
        bytes16 tokenSupplyDiv10Quad;
        bytes16 scoreMinScaledQuad;
        bytes16 scoreMaxScaledQuad;
        // we want 2 decimal places rounded up, so we need a scale with 3 additional digits
        uint256 resultScale = 1000;
        {
            // constants
            bytes16 oneQuad = ABDKMathQuad.fromUInt(1);
            tenQuad = ABDKMathQuad.fromUInt(10);
            oneTenthQuad = ABDKMathQuad.div(oneQuad, tenQuad);

            // value used in multiple steps of formula
            tokenSupplyDiv10Quad = ABDKMathQuad.div(
                ABDKMathQuad.fromUInt(tokenSupply),
                tenQuad
            );

            // scale the score values
            bytes16 scoreScaleQuad = ABDKMathQuad.fromUInt(scoreScale);
            scoreMaxScaledQuad = ABDKMathQuad.div(
                ABDKMathQuad.fromUInt(scoreMax),
                scoreScaleQuad
            );
            scoreMinScaledQuad = ABDKMathQuad.div(
                ABDKMathQuad.fromUInt(scoreMin),
                scoreScaleQuad
            );
        }

        // cards are only scored up to a max tokenId; for tokenIds outside this range the min score
        // is the static value
        if (tokenId > scoreMaxTokenId) {
            uint256 scoreMinResultScaled = ABDKMathQuad.toUInt(
                ABDKMathQuad.mul(
                    scoreMinScaledQuad,
                    ABDKMathQuad.fromUInt(resultScale)
                )
            );
            return buildDecimalString(scoreMinResultScaled, resultScale);
        }

        // compute x1 & x2 part
        bytes16 x1x2Quad;
        {
            bytes16 x1Quad = ABDKMathQuad.sub(
                scoreMaxScaledQuad,
                scoreMinScaledQuad
            );
            bytes16 x2Quad = ABDKMathQuad.mul(
                tokenSupplyDiv10Quad,
                tokenSupplyDiv10Quad
            );

            x1x2Quad = ABDKMathQuad.div(x1Quad, x2Quad);
        }

        // compute x3 & x4 part
        bytes16 x3x4Quad;
        {
            bytes16 tokenIdQuad = ABDKMathQuad.fromUInt(tokenId);

            bytes16 x3Quad = ABDKMathQuad.sub(
                ABDKMathQuad.div(tokenIdQuad, tenQuad),
                oneTenthQuad
            );
            bytes16 x4Quad = tokenSupplyDiv10Quad;
            bytes16 x3x4StepQuad = ABDKMathQuad.sub(x3Quad, x4Quad);

            x3x4Quad = ABDKMathQuad.mul(x3x4StepQuad, x3x4StepQuad);
        }

        // compute final x
        bytes16 xFinalQuad;
        {
            bytes16 x5Quad = scoreMinScaledQuad;

            xFinalQuad = ABDKMathQuad.add(
                ABDKMathQuad.mul(x1x2Quad, x3x4Quad),
                x5Quad
            );
        }

        uint256 xFinalResultScaled = ABDKMathQuad.toUInt(
            ABDKMathQuad.mul(xFinalQuad, ABDKMathQuad.fromUInt(resultScale))
        );

        return buildDecimalString(xFinalResultScaled, resultScale);
    }

    /**
     * @dev Helper function that will round up `x` then create a decimal string using `scale` to
     * "split" the rounded value into the integer and fractional parts.
     *
     * NOTE: `scale` should be one power of 10 larger than desired number of digits in the
     * fractional part to account for rounding up. For two digits in the fractional part, `scale`
     * should be `1000`.
     *
     * ie. x = 12345, scale = 1000, result = '12.35'
     */
    function buildDecimalString(uint256 x, uint256 scale)
        internal
        pure
        returns (string memory)
    {
        // last digit is used to round the number up
        uint256 xRounded = x + 5;

        uint256 lhs = xRounded / (scale);
        // we throw away last digit by dividing by 10
        uint256 rhs = ((xRounded - (lhs * scale))) / 10;

        return
            string(
                abi.encodePacked(
                    uintToString(lhs, false),
                    ".",
                    uintToString(rhs, true)
                )
            );
    }

    /**
     * @dev Helper function to convert a uint into a string.
     */
    function uintToString(uint256 x, bool isFractionalPart)
        internal
        pure
        returns (string memory uintAsString)
    {
        if (x == 0) {
            if (isFractionalPart) {
                // fractional part should always have 2 digits
                return "00";
            } else {
                return "0";
            }
        }

        // determine size of bytes array to encode number
        uint256 length;
        {
            uint256 xTemp = x;
            while (xTemp != 0) {
                length++;
                xTemp /= 10;
            }
        }

        bytes memory byteString;
        if (isFractionalPart && length == 1) {
            // fractional part should always have 2 digits, need to add the leading zero when the
            // `rhs` value is one digit
            // (ie. when `rhs` value is 2 return '02')
            length = 2;
            byteString = new bytes(length);
            byteString[0] = bytes1(uint8(48));
        } else {
            byteString = new bytes(length);
        }

        {
            uint256 i = length;
            while (x != 0) {
                i = i - 1;
                uint8 temp = (48 + uint8(x - (x / 10) * 10));
                bytes1 b1 = bytes1(temp);
                byteString[i] = b1;
                x /= 10;
            }
        }

        return string(byteString);
    }
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math Quad Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.8.0;

/**
 * Smart contract library of mathematical functions operating with IEEE 754
 * quadruple-precision binary floating-point numbers (quadruple precision
 * numbers).  As long as quadruple precision numbers are 16-bytes long, they are
 * represented by bytes16 type.
 */
library ABDKMathQuad {
    /*
     * 0.
     */
    bytes16 private constant POSITIVE_ZERO = 0x00000000000000000000000000000000;

    /*
     * -0.
     */
    bytes16 private constant NEGATIVE_ZERO = 0x80000000000000000000000000000000;

    /*
     * +Infinity.
     */
    bytes16 private constant POSITIVE_INFINITY =
        0x7FFF0000000000000000000000000000;

    /*
     * -Infinity.
     */
    bytes16 private constant NEGATIVE_INFINITY =
        0xFFFF0000000000000000000000000000;

    /*
     * Canonical NaN value.
     */
    bytes16 private constant NaN = 0x7FFF8000000000000000000000000000;

    /**
     * Convert signed 256-bit integer number into quadruple precision number.
     *
     * @param x signed 256-bit integer number
     * @return quadruple precision number
     */
    function fromInt(int256 x) internal pure returns (bytes16) {
        unchecked {
            if (x == 0) return bytes16(0);
            else {
                // We rely on overflow behavior here
                uint256 result = uint256(x > 0 ? x : -x);

                uint256 msb = mostSignificantBit(result);
                if (msb < 112) result <<= 112 - msb;
                else if (msb > 112) result >>= msb - 112;

                result =
                    (result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF) |
                    ((16383 + msb) << 112);
                if (x < 0) result |= 0x80000000000000000000000000000000;

                return bytes16(uint128(result));
            }
        }
    }

    /**
     * Convert quadruple precision number into signed 256-bit integer number
     * rounding towards zero.  Revert on overflow.
     *
     * @param x quadruple precision number
     * @return signed 256-bit integer number
     */
    function toInt(bytes16 x) internal pure returns (int256) {
        unchecked {
            uint256 exponent = (uint128(x) >> 112) & 0x7FFF;

            require(exponent <= 16638); // Overflow
            if (exponent < 16383) return 0; // Underflow

            uint256 result = (uint256(uint128(x)) &
                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF) |
                0x10000000000000000000000000000;

            if (exponent < 16495) result >>= 16495 - exponent;
            else if (exponent > 16495) result <<= exponent - 16495;

            if (uint128(x) >= 0x80000000000000000000000000000000) {
                // Negative
                require(
                    result <=
                        0x8000000000000000000000000000000000000000000000000000000000000000
                );
                return -int256(result); // We rely on overflow behavior here
            } else {
                require(
                    result <=
                        0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                );
                return int256(result);
            }
        }
    }

    /**
     * Convert unsigned 256-bit integer number into quadruple precision number.
     *
     * @param x unsigned 256-bit integer number
     * @return quadruple precision number
     */
    function fromUInt(uint256 x) internal pure returns (bytes16) {
        unchecked {
            if (x == 0) return bytes16(0);
            else {
                uint256 result = x;

                uint256 msb = mostSignificantBit(result);
                if (msb < 112) result <<= 112 - msb;
                else if (msb > 112) result >>= msb - 112;

                result =
                    (result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF) |
                    ((16383 + msb) << 112);

                return bytes16(uint128(result));
            }
        }
    }

    /**
     * Convert quadruple precision number into unsigned 256-bit integer number
     * rounding towards zero.  Revert on underflow.  Note, that negative floating
     * point numbers in range (-1.0 .. 0.0) may be converted to unsigned integer
     * without error, because they are rounded to zero.
     *
     * @param x quadruple precision number
     * @return unsigned 256-bit integer number
     */
    function toUInt(bytes16 x) internal pure returns (uint256) {
        unchecked {
            uint256 exponent = (uint128(x) >> 112) & 0x7FFF;

            if (exponent < 16383) return 0; // Underflow

            require(uint128(x) < 0x80000000000000000000000000000000); // Negative

            require(exponent <= 16638); // Overflow
            uint256 result = (uint256(uint128(x)) &
                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF) |
                0x10000000000000000000000000000;

            if (exponent < 16495) result >>= 16495 - exponent;
            else if (exponent > 16495) result <<= exponent - 16495;

            return result;
        }
    }

    /**
     * Convert signed 128.128 bit fixed point number into quadruple precision
     * number.
     *
     * @param x signed 128.128 bit fixed point number
     * @return quadruple precision number
     */
    function from128x128(int256 x) internal pure returns (bytes16) {
        unchecked {
            if (x == 0) return bytes16(0);
            else {
                // We rely on overflow behavior here
                uint256 result = uint256(x > 0 ? x : -x);

                uint256 msb = mostSignificantBit(result);
                if (msb < 112) result <<= 112 - msb;
                else if (msb > 112) result >>= msb - 112;

                result =
                    (result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF) |
                    ((16255 + msb) << 112);
                if (x < 0) result |= 0x80000000000000000000000000000000;

                return bytes16(uint128(result));
            }
        }
    }

    /**
     * Convert quadruple precision number into signed 128.128 bit fixed point
     * number.  Revert on overflow.
     *
     * @param x quadruple precision number
     * @return signed 128.128 bit fixed point number
     */
    function to128x128(bytes16 x) internal pure returns (int256) {
        unchecked {
            uint256 exponent = (uint128(x) >> 112) & 0x7FFF;

            require(exponent <= 16510); // Overflow
            if (exponent < 16255) return 0; // Underflow

            uint256 result = (uint256(uint128(x)) &
                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF) |
                0x10000000000000000000000000000;

            if (exponent < 16367) result >>= 16367 - exponent;
            else if (exponent > 16367) result <<= exponent - 16367;

            if (uint128(x) >= 0x80000000000000000000000000000000) {
                // Negative
                require(
                    result <=
                        0x8000000000000000000000000000000000000000000000000000000000000000
                );
                return -int256(result); // We rely on overflow behavior here
            } else {
                require(
                    result <=
                        0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                );
                return int256(result);
            }
        }
    }

    /**
     * Convert signed 64.64 bit fixed point number into quadruple precision
     * number.
     *
     * @param x signed 64.64 bit fixed point number
     * @return quadruple precision number
     */
    function from64x64(int128 x) internal pure returns (bytes16) {
        unchecked {
            if (x == 0) return bytes16(0);
            else {
                // We rely on overflow behavior here
                uint256 result = uint128(x > 0 ? x : -x);

                uint256 msb = mostSignificantBit(result);
                if (msb < 112) result <<= 112 - msb;
                else if (msb > 112) result >>= msb - 112;

                result =
                    (result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF) |
                    ((16319 + msb) << 112);
                if (x < 0) result |= 0x80000000000000000000000000000000;

                return bytes16(uint128(result));
            }
        }
    }

    /**
     * Convert quadruple precision number into signed 64.64 bit fixed point
     * number.  Revert on overflow.
     *
     * @param x quadruple precision number
     * @return signed 64.64 bit fixed point number
     */
    function to64x64(bytes16 x) internal pure returns (int128) {
        unchecked {
            uint256 exponent = (uint128(x) >> 112) & 0x7FFF;

            require(exponent <= 16446); // Overflow
            if (exponent < 16319) return 0; // Underflow

            uint256 result = (uint256(uint128(x)) &
                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF) |
                0x10000000000000000000000000000;

            if (exponent < 16431) result >>= 16431 - exponent;
            else if (exponent > 16431) result <<= exponent - 16431;

            if (uint128(x) >= 0x80000000000000000000000000000000) {
                // Negative
                require(result <= 0x80000000000000000000000000000000);
                return -int128(int256(result)); // We rely on overflow behavior here
            } else {
                require(result <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
                return int128(int256(result));
            }
        }
    }

    /**
     * Convert octuple precision number into quadruple precision number.
     *
     * @param x octuple precision number
     * @return quadruple precision number
     */
    function fromOctuple(bytes32 x) internal pure returns (bytes16) {
        unchecked {
            bool negative = x &
                0x8000000000000000000000000000000000000000000000000000000000000000 >
                0;

            uint256 exponent = (uint256(x) >> 236) & 0x7FFFF;
            uint256 significand = uint256(x) &
                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

            if (exponent == 0x7FFFF) {
                if (significand > 0) return NaN;
                else return negative ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
            }

            if (exponent > 278526)
                return negative ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
            else if (exponent < 245649)
                return negative ? NEGATIVE_ZERO : POSITIVE_ZERO;
            else if (exponent < 245761) {
                significand =
                    (significand |
                        0x100000000000000000000000000000000000000000000000000000000000) >>
                    (245885 - exponent);
                exponent = 0;
            } else {
                significand >>= 124;
                exponent -= 245760;
            }

            uint128 result = uint128(significand | (exponent << 112));
            if (negative) result |= 0x80000000000000000000000000000000;

            return bytes16(result);
        }
    }

    /**
     * Convert quadruple precision number into octuple precision number.
     *
     * @param x quadruple precision number
     * @return octuple precision number
     */
    function toOctuple(bytes16 x) internal pure returns (bytes32) {
        unchecked {
            uint256 exponent = (uint128(x) >> 112) & 0x7FFF;

            uint256 result = uint128(x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

            if (exponent == 0x7FFF)
                exponent = 0x7FFFF; // Infinity or NaN
            else if (exponent == 0) {
                if (result > 0) {
                    uint256 msb = mostSignificantBit(result);
                    result =
                        (result << (236 - msb)) &
                        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                    exponent = 245649 + msb;
                }
            } else {
                result <<= 124;
                exponent += 245760;
            }

            result |= exponent << 236;
            if (uint128(x) >= 0x80000000000000000000000000000000)
                result |= 0x8000000000000000000000000000000000000000000000000000000000000000;

            return bytes32(result);
        }
    }

    /**
     * Convert double precision number into quadruple precision number.
     *
     * @param x double precision number
     * @return quadruple precision number
     */
    function fromDouble(bytes8 x) internal pure returns (bytes16) {
        unchecked {
            uint256 exponent = (uint64(x) >> 52) & 0x7FF;

            uint256 result = uint64(x) & 0xFFFFFFFFFFFFF;

            if (exponent == 0x7FF)
                exponent = 0x7FFF; // Infinity or NaN
            else if (exponent == 0) {
                if (result > 0) {
                    uint256 msb = mostSignificantBit(result);
                    result =
                        (result << (112 - msb)) &
                        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                    exponent = 15309 + msb;
                }
            } else {
                result <<= 60;
                exponent += 15360;
            }

            result |= exponent << 112;
            if (x & 0x8000000000000000 > 0)
                result |= 0x80000000000000000000000000000000;

            return bytes16(uint128(result));
        }
    }

    /**
     * Convert quadruple precision number into double precision number.
     *
     * @param x quadruple precision number
     * @return double precision number
     */
    function toDouble(bytes16 x) internal pure returns (bytes8) {
        unchecked {
            bool negative = uint128(x) >= 0x80000000000000000000000000000000;

            uint256 exponent = (uint128(x) >> 112) & 0x7FFF;
            uint256 significand = uint128(x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

            if (exponent == 0x7FFF) {
                if (significand > 0) return 0x7FF8000000000000;
                // NaN
                else
                    return
                        negative
                            ? bytes8(0xFFF0000000000000) // -Infinity
                            : bytes8(0x7FF0000000000000); // Infinity
            }

            if (exponent > 17406)
                return
                    negative
                        ? bytes8(0xFFF0000000000000) // -Infinity
                        : bytes8(0x7FF0000000000000);
            // Infinity
            else if (exponent < 15309)
                return
                    negative
                        ? bytes8(0x8000000000000000) // -0
                        : bytes8(0x0000000000000000);
            // 0
            else if (exponent < 15361) {
                significand =
                    (significand | 0x10000000000000000000000000000) >>
                    (15421 - exponent);
                exponent = 0;
            } else {
                significand >>= 60;
                exponent -= 15360;
            }

            uint64 result = uint64(significand | (exponent << 52));
            if (negative) result |= 0x8000000000000000;

            return bytes8(result);
        }
    }

    /**
     * Test whether given quadruple precision number is NaN.
     *
     * @param x quadruple precision number
     * @return true if x is NaN, false otherwise
     */
    function isNaN(bytes16 x) internal pure returns (bool) {
        unchecked {
            return
                uint128(x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF >
                0x7FFF0000000000000000000000000000;
        }
    }

    /**
     * Test whether given quadruple precision number is positive or negative
     * infinity.
     *
     * @param x quadruple precision number
     * @return true if x is positive or negative infinity, false otherwise
     */
    function isInfinity(bytes16 x) internal pure returns (bool) {
        unchecked {
            return
                uint128(x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF ==
                0x7FFF0000000000000000000000000000;
        }
    }

    /**
     * Calculate sign of x, i.e. -1 if x is negative, 0 if x if zero, and 1 if x
     * is positive.  Note that sign (-0) is zero.  Revert if x is NaN.
     *
     * @param x quadruple precision number
     * @return sign of x
     */
    function sign(bytes16 x) internal pure returns (int8) {
        unchecked {
            uint128 absoluteX = uint128(x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

            require(absoluteX <= 0x7FFF0000000000000000000000000000); // Not NaN

            if (absoluteX == 0) return 0;
            else if (uint128(x) >= 0x80000000000000000000000000000000)
                return -1;
            else return 1;
        }
    }

    /**
     * Calculate sign (x - y).  Revert if either argument is NaN, or both
     * arguments are infinities of the same sign.
     *
     * @param x quadruple precision number
     * @param y quadruple precision number
     * @return sign (x - y)
     */
    function cmp(bytes16 x, bytes16 y) internal pure returns (int8) {
        unchecked {
            uint128 absoluteX = uint128(x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

            require(absoluteX <= 0x7FFF0000000000000000000000000000); // Not NaN

            uint128 absoluteY = uint128(y) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

            require(absoluteY <= 0x7FFF0000000000000000000000000000); // Not NaN

            // Not infinities of the same sign
            require(x != y || absoluteX < 0x7FFF0000000000000000000000000000);

            if (x == y) return 0;
            else {
                bool negativeX = uint128(x) >=
                    0x80000000000000000000000000000000;
                bool negativeY = uint128(y) >=
                    0x80000000000000000000000000000000;

                if (negativeX) {
                    if (negativeY) return absoluteX > absoluteY ? -1 : int8(1);
                    else return -1;
                } else {
                    if (negativeY) return 1;
                    else return absoluteX > absoluteY ? int8(1) : -1;
                }
            }
        }
    }

    /**
     * Test whether x equals y.  NaN, infinity, and -infinity are not equal to
     * anything.
     *
     * @param x quadruple precision number
     * @param y quadruple precision number
     * @return true if x equals to y, false otherwise
     */
    function eq(bytes16 x, bytes16 y) internal pure returns (bool) {
        unchecked {
            if (x == y) {
                return
                    uint128(x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF <
                    0x7FFF0000000000000000000000000000;
            } else return false;
        }
    }

    /**
     * Calculate x + y.  Special values behave in the following way:
     *
     * NaN + x = NaN for any x.
     * Infinity + x = Infinity for any finite x.
     * -Infinity + x = -Infinity for any finite x.
     * Infinity + Infinity = Infinity.
     * -Infinity + -Infinity = -Infinity.
     * Infinity + -Infinity = -Infinity + Infinity = NaN.
     *
     * @param x quadruple precision number
     * @param y quadruple precision number
     * @return quadruple precision number
     */
    function add(bytes16 x, bytes16 y) internal pure returns (bytes16) {
        unchecked {
            uint256 xExponent = (uint128(x) >> 112) & 0x7FFF;
            uint256 yExponent = (uint128(y) >> 112) & 0x7FFF;

            if (xExponent == 0x7FFF) {
                if (yExponent == 0x7FFF) {
                    if (x == y) return x;
                    else return NaN;
                } else return x;
            } else if (yExponent == 0x7FFF) return y;
            else {
                bool xSign = uint128(x) >= 0x80000000000000000000000000000000;
                uint256 xSignifier = uint128(x) &
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                if (xExponent == 0) xExponent = 1;
                else xSignifier |= 0x10000000000000000000000000000;

                bool ySign = uint128(y) >= 0x80000000000000000000000000000000;
                uint256 ySignifier = uint128(y) &
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                if (yExponent == 0) yExponent = 1;
                else ySignifier |= 0x10000000000000000000000000000;

                if (xSignifier == 0)
                    return y == NEGATIVE_ZERO ? POSITIVE_ZERO : y;
                else if (ySignifier == 0)
                    return x == NEGATIVE_ZERO ? POSITIVE_ZERO : x;
                else {
                    int256 delta = int256(xExponent) - int256(yExponent);

                    if (xSign == ySign) {
                        if (delta > 112) return x;
                        else if (delta > 0) ySignifier >>= uint256(delta);
                        else if (delta < -112) return y;
                        else if (delta < 0) {
                            xSignifier >>= uint256(-delta);
                            xExponent = yExponent;
                        }

                        xSignifier += ySignifier;

                        if (xSignifier >= 0x20000000000000000000000000000) {
                            xSignifier >>= 1;
                            xExponent += 1;
                        }

                        if (xExponent == 0x7FFF)
                            return
                                xSign ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
                        else {
                            if (xSignifier < 0x10000000000000000000000000000)
                                xExponent = 0;
                            else xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

                            return
                                bytes16(
                                    uint128(
                                        (
                                            xSign
                                                ? 0x80000000000000000000000000000000
                                                : 0
                                        ) |
                                            (xExponent << 112) |
                                            xSignifier
                                    )
                                );
                        }
                    } else {
                        if (delta > 0) {
                            xSignifier <<= 1;
                            xExponent -= 1;
                        } else if (delta < 0) {
                            ySignifier <<= 1;
                            xExponent = yExponent - 1;
                        }

                        if (delta > 112) ySignifier = 1;
                        else if (delta > 1)
                            ySignifier =
                                ((ySignifier - 1) >> uint256(delta - 1)) +
                                1;
                        else if (delta < -112) xSignifier = 1;
                        else if (delta < -1)
                            xSignifier =
                                ((xSignifier - 1) >> uint256(-delta - 1)) +
                                1;

                        if (xSignifier >= ySignifier) xSignifier -= ySignifier;
                        else {
                            xSignifier = ySignifier - xSignifier;
                            xSign = ySign;
                        }

                        if (xSignifier == 0) return POSITIVE_ZERO;

                        uint256 msb = mostSignificantBit(xSignifier);

                        if (msb == 113) {
                            xSignifier =
                                (xSignifier >> 1) &
                                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                            xExponent += 1;
                        } else if (msb < 112) {
                            uint256 shift = 112 - msb;
                            if (xExponent > shift) {
                                xSignifier =
                                    (xSignifier << shift) &
                                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                                xExponent -= shift;
                            } else {
                                xSignifier <<= xExponent - 1;
                                xExponent = 0;
                            }
                        } else xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

                        if (xExponent == 0x7FFF)
                            return
                                xSign ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
                        else
                            return
                                bytes16(
                                    uint128(
                                        (
                                            xSign
                                                ? 0x80000000000000000000000000000000
                                                : 0
                                        ) |
                                            (xExponent << 112) |
                                            xSignifier
                                    )
                                );
                    }
                }
            }
        }
    }

    /**
     * Calculate x - y.  Special values behave in the following way:
     *
     * NaN - x = NaN for any x.
     * Infinity - x = Infinity for any finite x.
     * -Infinity - x = -Infinity for any finite x.
     * Infinity - -Infinity = Infinity.
     * -Infinity - Infinity = -Infinity.
     * Infinity - Infinity = -Infinity - -Infinity = NaN.
     *
     * @param x quadruple precision number
     * @param y quadruple precision number
     * @return quadruple precision number
     */
    function sub(bytes16 x, bytes16 y) internal pure returns (bytes16) {
        unchecked {
            return add(x, y ^ 0x80000000000000000000000000000000);
        }
    }

    /**
     * Calculate x * y.  Special values behave in the following way:
     *
     * NaN * x = NaN for any x.
     * Infinity * x = Infinity for any finite positive x.
     * Infinity * x = -Infinity for any finite negative x.
     * -Infinity * x = -Infinity for any finite positive x.
     * -Infinity * x = Infinity for any finite negative x.
     * Infinity * 0 = NaN.
     * -Infinity * 0 = NaN.
     * Infinity * Infinity = Infinity.
     * Infinity * -Infinity = -Infinity.
     * -Infinity * Infinity = -Infinity.
     * -Infinity * -Infinity = Infinity.
     *
     * @param x quadruple precision number
     * @param y quadruple precision number
     * @return quadruple precision number
     */
    function mul(bytes16 x, bytes16 y) internal pure returns (bytes16) {
        unchecked {
            uint256 xExponent = (uint128(x) >> 112) & 0x7FFF;
            uint256 yExponent = (uint128(y) >> 112) & 0x7FFF;

            if (xExponent == 0x7FFF) {
                if (yExponent == 0x7FFF) {
                    if (x == y)
                        return x ^ (y & 0x80000000000000000000000000000000);
                    else if (x ^ y == 0x80000000000000000000000000000000)
                        return x | y;
                    else return NaN;
                } else {
                    if (y & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
                    else return x ^ (y & 0x80000000000000000000000000000000);
                }
            } else if (yExponent == 0x7FFF) {
                if (x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
                else return y ^ (x & 0x80000000000000000000000000000000);
            } else {
                uint256 xSignifier = uint128(x) &
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                if (xExponent == 0) xExponent = 1;
                else xSignifier |= 0x10000000000000000000000000000;

                uint256 ySignifier = uint128(y) &
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                if (yExponent == 0) yExponent = 1;
                else ySignifier |= 0x10000000000000000000000000000;

                xSignifier *= ySignifier;
                if (xSignifier == 0)
                    return
                        (x ^ y) & 0x80000000000000000000000000000000 > 0
                            ? NEGATIVE_ZERO
                            : POSITIVE_ZERO;

                xExponent += yExponent;

                uint256 msb = xSignifier >=
                    0x200000000000000000000000000000000000000000000000000000000
                    ? 225
                    : xSignifier >=
                        0x100000000000000000000000000000000000000000000000000000000
                    ? 224
                    : mostSignificantBit(xSignifier);

                if (xExponent + msb < 16496) {
                    // Underflow
                    xExponent = 0;
                    xSignifier = 0;
                } else if (xExponent + msb < 16608) {
                    // Subnormal
                    if (xExponent < 16496) xSignifier >>= 16496 - xExponent;
                    else if (xExponent > 16496)
                        xSignifier <<= xExponent - 16496;
                    xExponent = 0;
                } else if (xExponent + msb > 49373) {
                    xExponent = 0x7FFF;
                    xSignifier = 0;
                } else {
                    if (msb > 112) xSignifier >>= msb - 112;
                    else if (msb < 112) xSignifier <<= 112 - msb;

                    xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

                    xExponent = xExponent + msb - 16607;
                }

                return
                    bytes16(
                        uint128(
                            uint128(
                                (x ^ y) & 0x80000000000000000000000000000000
                            ) |
                                (xExponent << 112) |
                                xSignifier
                        )
                    );
            }
        }
    }

    /**
     * Calculate x / y.  Special values behave in the following way:
     *
     * NaN / x = NaN for any x.
     * x / NaN = NaN for any x.
     * Infinity / x = Infinity for any finite non-negative x.
     * Infinity / x = -Infinity for any finite negative x including -0.
     * -Infinity / x = -Infinity for any finite non-negative x.
     * -Infinity / x = Infinity for any finite negative x including -0.
     * x / Infinity = 0 for any finite non-negative x.
     * x / -Infinity = -0 for any finite non-negative x.
     * x / Infinity = -0 for any finite non-negative x including -0.
     * x / -Infinity = 0 for any finite non-negative x including -0.
     *
     * Infinity / Infinity = NaN.
     * Infinity / -Infinity = -NaN.
     * -Infinity / Infinity = -NaN.
     * -Infinity / -Infinity = NaN.
     *
     * Division by zero behaves in the following way:
     *
     * x / 0 = Infinity for any finite positive x.
     * x / -0 = -Infinity for any finite positive x.
     * x / 0 = -Infinity for any finite negative x.
     * x / -0 = Infinity for any finite negative x.
     * 0 / 0 = NaN.
     * 0 / -0 = NaN.
     * -0 / 0 = NaN.
     * -0 / -0 = NaN.
     *
     * @param x quadruple precision number
     * @param y quadruple precision number
     * @return quadruple precision number
     */
    function div(bytes16 x, bytes16 y) internal pure returns (bytes16) {
        unchecked {
            uint256 xExponent = (uint128(x) >> 112) & 0x7FFF;
            uint256 yExponent = (uint128(y) >> 112) & 0x7FFF;

            if (xExponent == 0x7FFF) {
                if (yExponent == 0x7FFF) return NaN;
                else return x ^ (y & 0x80000000000000000000000000000000);
            } else if (yExponent == 0x7FFF) {
                if (y & 0x0000FFFFFFFFFFFFFFFFFFFFFFFFFFFF != 0) return NaN;
                else
                    return
                        POSITIVE_ZERO |
                        ((x ^ y) & 0x80000000000000000000000000000000);
            } else if (y & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) {
                if (x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
                else
                    return
                        POSITIVE_INFINITY |
                        ((x ^ y) & 0x80000000000000000000000000000000);
            } else {
                uint256 ySignifier = uint128(y) &
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                if (yExponent == 0) yExponent = 1;
                else ySignifier |= 0x10000000000000000000000000000;

                uint256 xSignifier = uint128(x) &
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                if (xExponent == 0) {
                    if (xSignifier != 0) {
                        uint256 shift = 226 - mostSignificantBit(xSignifier);

                        xSignifier <<= shift;

                        xExponent = 1;
                        yExponent += shift - 114;
                    }
                } else {
                    xSignifier =
                        (xSignifier | 0x10000000000000000000000000000) <<
                        114;
                }

                xSignifier = xSignifier / ySignifier;
                if (xSignifier == 0)
                    return
                        (x ^ y) & 0x80000000000000000000000000000000 > 0
                            ? NEGATIVE_ZERO
                            : POSITIVE_ZERO;

                assert(xSignifier >= 0x1000000000000000000000000000);

                uint256 msb = xSignifier >= 0x80000000000000000000000000000
                    ? mostSignificantBit(xSignifier)
                    : xSignifier >= 0x40000000000000000000000000000
                    ? 114
                    : xSignifier >= 0x20000000000000000000000000000
                    ? 113
                    : 112;

                if (xExponent + msb > yExponent + 16497) {
                    // Overflow
                    xExponent = 0x7FFF;
                    xSignifier = 0;
                } else if (xExponent + msb + 16380 < yExponent) {
                    // Underflow
                    xExponent = 0;
                    xSignifier = 0;
                } else if (xExponent + msb + 16268 < yExponent) {
                    // Subnormal
                    if (xExponent + 16380 > yExponent)
                        xSignifier <<= xExponent + 16380 - yExponent;
                    else if (xExponent + 16380 < yExponent)
                        xSignifier >>= yExponent - xExponent - 16380;

                    xExponent = 0;
                } else {
                    // Normal
                    if (msb > 112) xSignifier >>= msb - 112;

                    xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

                    xExponent = xExponent + msb + 16269 - yExponent;
                }

                return
                    bytes16(
                        uint128(
                            uint128(
                                (x ^ y) & 0x80000000000000000000000000000000
                            ) |
                                (xExponent << 112) |
                                xSignifier
                        )
                    );
            }
        }
    }

    /**
     * Calculate -x.
     *
     * @param x quadruple precision number
     * @return quadruple precision number
     */
    function neg(bytes16 x) internal pure returns (bytes16) {
        unchecked {
            return x ^ 0x80000000000000000000000000000000;
        }
    }

    /**
     * Calculate |x|.
     *
     * @param x quadruple precision number
     * @return quadruple precision number
     */
    function abs(bytes16 x) internal pure returns (bytes16) {
        unchecked {
            return x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        }
    }

    /**
     * Calculate square root of x.  Return NaN on negative x excluding -0.
     *
     * @param x quadruple precision number
     * @return quadruple precision number
     */
    function sqrt(bytes16 x) internal pure returns (bytes16) {
        unchecked {
            if (uint128(x) > 0x80000000000000000000000000000000) return NaN;
            else {
                uint256 xExponent = (uint128(x) >> 112) & 0x7FFF;
                if (xExponent == 0x7FFF) return x;
                else {
                    uint256 xSignifier = uint128(x) &
                        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                    if (xExponent == 0) xExponent = 1;
                    else xSignifier |= 0x10000000000000000000000000000;

                    if (xSignifier == 0) return POSITIVE_ZERO;

                    bool oddExponent = xExponent & 0x1 == 0;
                    xExponent = (xExponent + 16383) >> 1;

                    if (oddExponent) {
                        if (xSignifier >= 0x10000000000000000000000000000)
                            xSignifier <<= 113;
                        else {
                            uint256 msb = mostSignificantBit(xSignifier);
                            uint256 shift = (226 - msb) & 0xFE;
                            xSignifier <<= shift;
                            xExponent -= (shift - 112) >> 1;
                        }
                    } else {
                        if (xSignifier >= 0x10000000000000000000000000000)
                            xSignifier <<= 112;
                        else {
                            uint256 msb = mostSignificantBit(xSignifier);
                            uint256 shift = (225 - msb) & 0xFE;
                            xSignifier <<= shift;
                            xExponent -= (shift - 112) >> 1;
                        }
                    }

                    uint256 r = 0x10000000000000000000000000000;
                    r = (r + xSignifier / r) >> 1;
                    r = (r + xSignifier / r) >> 1;
                    r = (r + xSignifier / r) >> 1;
                    r = (r + xSignifier / r) >> 1;
                    r = (r + xSignifier / r) >> 1;
                    r = (r + xSignifier / r) >> 1;
                    r = (r + xSignifier / r) >> 1; // Seven iterations should be enough
                    uint256 r1 = xSignifier / r;
                    if (r1 < r) r = r1;

                    return
                        bytes16(
                            uint128(
                                (xExponent << 112) |
                                    (r & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                            )
                        );
                }
            }
        }
    }

    /**
     * Calculate binary logarithm of x.  Return NaN on negative x excluding -0.
     *
     * @param x quadruple precision number
     * @return quadruple precision number
     */
    function log_2(bytes16 x) internal pure returns (bytes16) {
        unchecked {
            if (uint128(x) > 0x80000000000000000000000000000000) return NaN;
            else if (x == 0x3FFF0000000000000000000000000000)
                return POSITIVE_ZERO;
            else {
                uint256 xExponent = (uint128(x) >> 112) & 0x7FFF;
                if (xExponent == 0x7FFF) return x;
                else {
                    uint256 xSignifier = uint128(x) &
                        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                    if (xExponent == 0) xExponent = 1;
                    else xSignifier |= 0x10000000000000000000000000000;

                    if (xSignifier == 0) return NEGATIVE_INFINITY;

                    bool resultNegative;
                    uint256 resultExponent = 16495;
                    uint256 resultSignifier;

                    if (xExponent >= 0x3FFF) {
                        resultNegative = false;
                        resultSignifier = xExponent - 0x3FFF;
                        xSignifier <<= 15;
                    } else {
                        resultNegative = true;
                        if (xSignifier >= 0x10000000000000000000000000000) {
                            resultSignifier = 0x3FFE - xExponent;
                            xSignifier <<= 15;
                        } else {
                            uint256 msb = mostSignificantBit(xSignifier);
                            resultSignifier = 16493 - msb;
                            xSignifier <<= 127 - msb;
                        }
                    }

                    if (xSignifier == 0x80000000000000000000000000000000) {
                        if (resultNegative) resultSignifier += 1;
                        uint256 shift = 112 -
                            mostSignificantBit(resultSignifier);
                        resultSignifier <<= shift;
                        resultExponent -= shift;
                    } else {
                        uint256 bb = resultNegative ? 1 : 0;
                        while (
                            resultSignifier < 0x10000000000000000000000000000
                        ) {
                            resultSignifier <<= 1;
                            resultExponent -= 1;

                            xSignifier *= xSignifier;
                            uint256 b = xSignifier >> 255;
                            resultSignifier += b ^ bb;
                            xSignifier >>= 127 + b;
                        }
                    }

                    return
                        bytes16(
                            uint128(
                                (
                                    resultNegative
                                        ? 0x80000000000000000000000000000000
                                        : 0
                                ) |
                                    (resultExponent << 112) |
                                    (resultSignifier &
                                        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                            )
                        );
                }
            }
        }
    }

    /**
     * Calculate natural logarithm of x.  Return NaN on negative x excluding -0.
     *
     * @param x quadruple precision number
     * @return quadruple precision number
     */
    function ln(bytes16 x) internal pure returns (bytes16) {
        unchecked {
            return mul(log_2(x), 0x3FFE62E42FEFA39EF35793C7673007E5);
        }
    }

    /**
     * Calculate 2^x.
     *
     * @param x quadruple precision number
     * @return quadruple precision number
     */
    function pow_2(bytes16 x) internal pure returns (bytes16) {
        unchecked {
            bool xNegative = uint128(x) > 0x80000000000000000000000000000000;
            uint256 xExponent = (uint128(x) >> 112) & 0x7FFF;
            uint256 xSignifier = uint128(x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

            if (xExponent == 0x7FFF && xSignifier != 0) return NaN;
            else if (xExponent > 16397)
                return xNegative ? POSITIVE_ZERO : POSITIVE_INFINITY;
            else if (xExponent < 16255)
                return 0x3FFF0000000000000000000000000000;
            else {
                if (xExponent == 0) xExponent = 1;
                else xSignifier |= 0x10000000000000000000000000000;

                if (xExponent > 16367) xSignifier <<= xExponent - 16367;
                else if (xExponent < 16367) xSignifier >>= 16367 - xExponent;

                if (
                    xNegative &&
                    xSignifier > 0x406E00000000000000000000000000000000
                ) return POSITIVE_ZERO;

                if (
                    !xNegative &&
                    xSignifier > 0x3FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                ) return POSITIVE_INFINITY;

                uint256 resultExponent = xSignifier >> 128;
                xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                if (xNegative && xSignifier != 0) {
                    xSignifier = ~xSignifier;
                    resultExponent += 1;
                }

                uint256 resultSignifier = 0x80000000000000000000000000000000;
                if (xSignifier & 0x80000000000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x16A09E667F3BCC908B2FB1366EA957D3E) >>
                        128;
                if (xSignifier & 0x40000000000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1306FE0A31B7152DE8D5A46305C85EDEC) >>
                        128;
                if (xSignifier & 0x20000000000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1172B83C7D517ADCDF7C8C50EB14A791F) >>
                        128;
                if (xSignifier & 0x10000000000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10B5586CF9890F6298B92B71842A98363) >>
                        128;
                if (xSignifier & 0x8000000000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1059B0D31585743AE7C548EB68CA417FD) >>
                        128;
                if (xSignifier & 0x4000000000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x102C9A3E778060EE6F7CACA4F7A29BDE8) >>
                        128;
                if (xSignifier & 0x2000000000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10163DA9FB33356D84A66AE336DCDFA3F) >>
                        128;
                if (xSignifier & 0x1000000000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100B1AFA5ABCBED6129AB13EC11DC9543) >>
                        128;
                if (xSignifier & 0x800000000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10058C86DA1C09EA1FF19D294CF2F679B) >>
                        128;
                if (xSignifier & 0x400000000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1002C605E2E8CEC506D21BFC89A23A00F) >>
                        128;
                if (xSignifier & 0x200000000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100162F3904051FA128BCA9C55C31E5DF) >>
                        128;
                if (xSignifier & 0x100000000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000B175EFFDC76BA38E31671CA939725) >>
                        128;
                if (xSignifier & 0x80000000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100058BA01FB9F96D6CACD4B180917C3D) >>
                        128;
                if (xSignifier & 0x40000000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10002C5CC37DA9491D0985C348C68E7B3) >>
                        128;
                if (xSignifier & 0x20000000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000162E525EE054754457D5995292026) >>
                        128;
                if (xSignifier & 0x10000000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000B17255775C040618BF4A4ADE83FC) >>
                        128;
                if (xSignifier & 0x8000000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000058B91B5BC9AE2EED81E9B7D4CFAB) >>
                        128;
                if (xSignifier & 0x4000000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100002C5C89D5EC6CA4D7C8ACC017B7C9) >>
                        128;
                if (xSignifier & 0x2000000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000162E43F4F831060E02D839A9D16D) >>
                        128;
                if (xSignifier & 0x1000000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000B1721BCFC99D9F890EA06911763) >>
                        128;
                if (xSignifier & 0x800000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000058B90CF1E6D97F9CA14DBCC1628) >>
                        128;
                if (xSignifier & 0x400000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000002C5C863B73F016468F6BAC5CA2B) >>
                        128;
                if (xSignifier & 0x200000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000162E430E5A18F6119E3C02282A5) >>
                        128;
                if (xSignifier & 0x100000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000B1721835514B86E6D96EFD1BFE) >>
                        128;
                if (xSignifier & 0x80000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000058B90C0B48C6BE5DF846C5B2EF) >>
                        128;
                if (xSignifier & 0x40000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000002C5C8601CC6B9E94213C72737A) >>
                        128;
                if (xSignifier & 0x20000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000162E42FFF037DF38AA2B219F06) >>
                        128;
                if (xSignifier & 0x10000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000B17217FBA9C739AA5819F44F9) >>
                        128;
                if (xSignifier & 0x8000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000058B90BFCDEE5ACD3C1CEDC823) >>
                        128;
                if (xSignifier & 0x4000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000002C5C85FE31F35A6A30DA1BE50) >>
                        128;
                if (xSignifier & 0x2000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000162E42FF0999CE3541B9FFFCF) >>
                        128;
                if (xSignifier & 0x1000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000B17217F80F4EF5AADDA45554) >>
                        128;
                if (xSignifier & 0x800000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000058B90BFBF8479BD5A81B51AD) >>
                        128;
                if (xSignifier & 0x400000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000002C5C85FDF84BD62AE30A74CC) >>
                        128;
                if (xSignifier & 0x200000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000162E42FEFB2FED257559BDAA) >>
                        128;
                if (xSignifier & 0x100000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000B17217F7D5A7716BBA4A9AE) >>
                        128;
                if (xSignifier & 0x80000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000058B90BFBE9DDBAC5E109CCE) >>
                        128;
                if (xSignifier & 0x40000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000002C5C85FDF4B15DE6F17EB0D) >>
                        128;
                if (xSignifier & 0x20000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000162E42FEFA494F1478FDE05) >>
                        128;
                if (xSignifier & 0x10000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000B17217F7D20CF927C8E94C) >>
                        128;
                if (xSignifier & 0x8000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000058B90BFBE8F71CB4E4B33D) >>
                        128;
                if (xSignifier & 0x4000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000002C5C85FDF477B662B26945) >>
                        128;
                if (xSignifier & 0x2000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000162E42FEFA3AE53369388C) >>
                        128;
                if (xSignifier & 0x1000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000B17217F7D1D351A389D40) >>
                        128;
                if (xSignifier & 0x800000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000058B90BFBE8E8B2D3D4EDE) >>
                        128;
                if (xSignifier & 0x400000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000002C5C85FDF4741BEA6E77E) >>
                        128;
                if (xSignifier & 0x200000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000162E42FEFA39FE95583C2) >>
                        128;
                if (xSignifier & 0x100000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000B17217F7D1CFB72B45E1) >>
                        128;
                if (xSignifier & 0x80000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000058B90BFBE8E7CC35C3F0) >>
                        128;
                if (xSignifier & 0x40000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000002C5C85FDF473E242EA38) >>
                        128;
                if (xSignifier & 0x20000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000162E42FEFA39F02B772C) >>
                        128;
                if (xSignifier & 0x10000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000B17217F7D1CF7D83C1A) >>
                        128;
                if (xSignifier & 0x8000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000058B90BFBE8E7BDCBE2E) >>
                        128;
                if (xSignifier & 0x4000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000002C5C85FDF473DEA871F) >>
                        128;
                if (xSignifier & 0x2000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000162E42FEFA39EF44D91) >>
                        128;
                if (xSignifier & 0x1000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000B17217F7D1CF79E949) >>
                        128;
                if (xSignifier & 0x800000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000058B90BFBE8E7BCE544) >>
                        128;
                if (xSignifier & 0x400000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000002C5C85FDF473DE6ECA) >>
                        128;
                if (xSignifier & 0x200000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000162E42FEFA39EF366F) >>
                        128;
                if (xSignifier & 0x100000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000000B17217F7D1CF79AFA) >>
                        128;
                if (xSignifier & 0x80000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000058B90BFBE8E7BCD6D) >>
                        128;
                if (xSignifier & 0x40000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000002C5C85FDF473DE6B2) >>
                        128;
                if (xSignifier & 0x20000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000000162E42FEFA39EF358) >>
                        128;
                if (xSignifier & 0x10000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000000B17217F7D1CF79AB) >>
                        128;
                if (xSignifier & 0x8000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000000058B90BFBE8E7BCD5) >>
                        128;
                if (xSignifier & 0x4000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000002C5C85FDF473DE6A) >>
                        128;
                if (xSignifier & 0x2000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000000162E42FEFA39EF34) >>
                        128;
                if (xSignifier & 0x1000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000000B17217F7D1CF799) >>
                        128;
                if (xSignifier & 0x800000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000000058B90BFBE8E7BCC) >>
                        128;
                if (xSignifier & 0x400000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000000002C5C85FDF473DE5) >>
                        128;
                if (xSignifier & 0x200000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000000162E42FEFA39EF2) >>
                        128;
                if (xSignifier & 0x100000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000000000B17217F7D1CF78) >>
                        128;
                if (xSignifier & 0x80000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000000058B90BFBE8E7BB) >>
                        128;
                if (xSignifier & 0x40000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000000002C5C85FDF473DD) >>
                        128;
                if (xSignifier & 0x20000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000000000162E42FEFA39EE) >>
                        128;
                if (xSignifier & 0x10000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000000000B17217F7D1CF6) >>
                        128;
                if (xSignifier & 0x8000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000000000058B90BFBE8E7A) >>
                        128;
                if (xSignifier & 0x4000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000000002C5C85FDF473C) >>
                        128;
                if (xSignifier & 0x2000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000000000162E42FEFA39D) >>
                        128;
                if (xSignifier & 0x1000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000000000B17217F7D1CE) >>
                        128;
                if (xSignifier & 0x800000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000000000058B90BFBE8E6) >>
                        128;
                if (xSignifier & 0x400000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000000000002C5C85FDF472) >>
                        128;
                if (xSignifier & 0x200000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000000000162E42FEFA38) >>
                        128;
                if (xSignifier & 0x100000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000000000000B17217F7D1B) >>
                        128;
                if (xSignifier & 0x80000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000000000058B90BFBE8D) >>
                        128;
                if (xSignifier & 0x40000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000000000002C5C85FDF46) >>
                        128;
                if (xSignifier & 0x20000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000000000000162E42FEFA2) >>
                        128;
                if (xSignifier & 0x10000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000000000000B17217F7D0) >>
                        128;
                if (xSignifier & 0x8000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000000000000058B90BFBE7) >>
                        128;
                if (xSignifier & 0x4000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000000000002C5C85FDF3) >>
                        128;
                if (xSignifier & 0x2000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000000000000162E42FEF9) >>
                        128;
                if (xSignifier & 0x1000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000000000000B17217F7C) >>
                        128;
                if (xSignifier & 0x800000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000000000000058B90BFBD) >>
                        128;
                if (xSignifier & 0x400000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000000000000002C5C85FDE) >>
                        128;
                if (xSignifier & 0x200000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000000000000162E42FEE) >>
                        128;
                if (xSignifier & 0x100000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000000000000000B17217F6) >>
                        128;
                if (xSignifier & 0x80000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000000000000058B90BFA) >>
                        128;
                if (xSignifier & 0x40000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000000000000002C5C85FC) >>
                        128;
                if (xSignifier & 0x20000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000000000000000162E42FD) >>
                        128;
                if (xSignifier & 0x10000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000000000000000B17217E) >>
                        128;
                if (xSignifier & 0x8000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000000000000000058B90BE) >>
                        128;
                if (xSignifier & 0x4000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000000000000002C5C85E) >>
                        128;
                if (xSignifier & 0x2000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000000000000000162E42E) >>
                        128;
                if (xSignifier & 0x1000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000000000000000B17216) >>
                        128;
                if (xSignifier & 0x800000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000000000000000058B90A) >>
                        128;
                if (xSignifier & 0x400000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000000000000000002C5C84) >>
                        128;
                if (xSignifier & 0x200000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000000000000000162E41) >>
                        128;
                if (xSignifier & 0x100000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000000000000000000B1720) >>
                        128;
                if (xSignifier & 0x80000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000000000000000058B8F) >>
                        128;
                if (xSignifier & 0x40000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000000000000000002C5C7) >>
                        128;
                if (xSignifier & 0x20000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000000000000000000162E3) >>
                        128;
                if (xSignifier & 0x10000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000000000000000000B171) >>
                        128;
                if (xSignifier & 0x8000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000000000000000000058B8) >>
                        128;
                if (xSignifier & 0x4000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000000000000000002C5B) >>
                        128;
                if (xSignifier & 0x2000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000000000000000000162D) >>
                        128;
                if (xSignifier & 0x1000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000000000000000000B16) >>
                        128;
                if (xSignifier & 0x800 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000000000000000000058A) >>
                        128;
                if (xSignifier & 0x400 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000000000000000000002C4) >>
                        128;
                if (xSignifier & 0x200 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000000000000000000161) >>
                        128;
                if (xSignifier & 0x100 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000000000000000000000B0) >>
                        128;
                if (xSignifier & 0x80 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000000000000000000057) >>
                        128;
                if (xSignifier & 0x40 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000000000000000000002B) >>
                        128;
                if (xSignifier & 0x20 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000000000000000000015) >>
                        128;
                if (xSignifier & 0x10 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000000000000000000000A) >>
                        128;
                if (xSignifier & 0x8 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000000000000000000004) >>
                        128;
                if (xSignifier & 0x4 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000000000000000000001) >>
                        128;

                if (!xNegative) {
                    resultSignifier =
                        (resultSignifier >> 15) &
                        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                    resultExponent += 0x3FFF;
                } else if (resultExponent <= 0x3FFE) {
                    resultSignifier =
                        (resultSignifier >> 15) &
                        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                    resultExponent = 0x3FFF - resultExponent;
                } else {
                    resultSignifier =
                        resultSignifier >>
                        (resultExponent - 16367);
                    resultExponent = 0;
                }

                return
                    bytes16(uint128((resultExponent << 112) | resultSignifier));
            }
        }
    }

    /**
     * Calculate e^x.
     *
     * @param x quadruple precision number
     * @return quadruple precision number
     */
    function exp(bytes16 x) internal pure returns (bytes16) {
        unchecked {
            return pow_2(mul(x, 0x3FFF71547652B82FE1777D0FFDA0D23A));
        }
    }

    /**
     * Get index of the most significant non-zero bit in binary representation of
     * x.  Reverts if x is zero.
     *
     * @return index of the most significant non-zero bit in binary representation
     *         of x
     */
    function mostSignificantBit(uint256 x) private pure returns (uint256) {
        unchecked {
            require(x > 0);

            uint256 result = 0;

            if (x >= 0x100000000000000000000000000000000) {
                x >>= 128;
                result += 128;
            }
            if (x >= 0x10000000000000000) {
                x >>= 64;
                result += 64;
            }
            if (x >= 0x100000000) {
                x >>= 32;
                result += 32;
            }
            if (x >= 0x10000) {
                x >>= 16;
                result += 16;
            }
            if (x >= 0x100) {
                x >>= 8;
                result += 8;
            }
            if (x >= 0x10) {
                x >>= 4;
                result += 4;
            }
            if (x >= 0x4) {
                x >>= 2;
                result += 2;
            }
            if (x >= 0x2) result += 1; // No need to shift x anymore

            return result;
        }
    }
}