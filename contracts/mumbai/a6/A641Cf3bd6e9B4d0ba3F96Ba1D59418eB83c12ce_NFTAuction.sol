// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

contract NFTAuction is Initializable, OwnableUpgradeable, PausableUpgradeable {
    /**
     * @dev NFT Auction Struct
     * @param seller NFT owner
     * @param startingPrice Auction starting price
     * @param endingPrice Auction ending price
     * @param currentPrice current price of the auction
     * @param duration Duration of the Auction
     * @param startedAt Auction start time (0 represent the auction is ended)
     */
    struct Auction {
        address seller;
        uint256 startingPrice;
        uint256 endingPrice;
        uint256 currentPrice;
        uint256 duration;
        uint256 startedAt;
        address highestBidder;
        //Bidder[] bidders;
        mapping(uint256 => Bidder) bidders;
        uint256 bidderSize; // mapping size starts from 1 instead of 0
    }

    /* struct ERC20Auction {
        address seller;
        uint256 startingPrice;
        uint256 endingPrice;
        uint256 currentPrice;
        uint64 duration;
        uint64 startedAt;
    } */

    /**
     * @dev NFT auction bidders
     * @param bidder address of the user who bids
     * @param bidAmount the bid amount
     * @param tokenId The NFT id
     */
    struct Bidder {
        address bidder;
        uint256 bidAmount;
        uint256 tokenId;
    }

    /**
     * @dev referring NFT contract
     */
    IERC721Upgradeable public NFTContract;

    /**
     * @dev Map from tokenId to their corresponding auction
     */
    mapping(uint256 => Auction) public tokenIdToAuction;

    //mapping(uint256 => Bidder[]) public biddersOFAToken;

    //Bidder[] public bidder;

    event AuctionCreated(
        uint256 tokenId,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 auctionCreatedAt
    );

    event AuctionSuccessful(
        uint256 tokenId,
        uint256 totalPrice,
        address winner
    );

    event AuctionCancelled(uint256 tokenId);

    event SetNFTContract(address nftContract);

    event Bid(address bidder, uint256 tokenId, uint256 amount);

    event ClaimNFT(address receiver, uint256 tokenId);

    function initialize(address nftAddress) public initializer {
        __Ownable_init();

        NFTContract = IERC721Upgradeable(nftAddress);
    }

    /**
     * @dev allow contract to receive ETH
     */
    receive() external payable {}

    /**
     * @dev validate nft ownership
     */
    function _isOwnerOf(address nftOwner, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        return (NFTContract.ownerOf(tokenId) == nftOwner);
    }

    /**
     * @dev Transfering the NFT to the contract for auction
     * @param owner owner of the NFT
     * @param tokenId the NFT tokenId
     */
    function _escrow(address owner, uint256 tokenId) internal {
        NFTContract.transferFrom(owner, address(this), tokenId);
    }

    /**
     * @dev Transfering the NFT from the contract to another address
     * @param receiver the address of the NFT receiver
     * @param tokenId the NFT tokenId
     */
    function _transferNFT(address receiver, uint256 tokenId) internal {
        NFTContract.transferFrom(address(this), receiver, tokenId);
    }

    /**
     * @dev creating an open auction to bid on the NFT
     * @param tokenId the NFT to be in the auction
     * @param startingPrice starting price of the auction
     * @param endingPrice ending price of the auction
     * @param startTime start time of the auction
     * @param endTime end time of the auction
     * @param seller the owner of the NFT
     */
    function _createAuction(
        uint256 tokenId,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 startTime,
        uint256 endTime,
        address seller
    ) internal {
        Auction storage auction = tokenIdToAuction[tokenId];
        require(!_hasAuctionCreated(auction), "NFTAuction: Auction exists");
        require(
            endTime >= 1 minutes,
            "NFTAuction: Auction duration must be atleast 1 minutes"
        );

        uint256 auctionStartTime;
        if (startTime == 0) {
            auctionStartTime = block.timestamp;
        } else {
            auctionStartTime = startTime;
        }

        auction.seller = seller;
        auction.startingPrice = startingPrice;
        auction.endingPrice = endingPrice;
        auction.currentPrice = startingPrice;
        auction.duration = endTime;
        auction.startedAt = auctionStartTime;

        emit AuctionCreated(
            tokenId,
            auction.startingPrice,
            auction.endingPrice,
            auction.duration,
            auction.startedAt
        );
    }

    /**
     * @dev Checks whether the auction is active.
     * @param auction the Auction struct data
     */
    function _isAuctionActive(Auction storage auction)
        internal
        view
        returns (bool)
    {
        return (auction.startedAt + auction.duration <= block.timestamp);
        // if(auction.startedAt == 0) {
        //     return false;
        // } else if(auction.startedAt + auction.duration <= block.timestamp) {
        //     return false;
        // } else {
        //     return true;
        // }

        //return (auction.startedAt > 0);
    }

    /**
     * @dev Check whether the auction has created.
     * Note auction.startedAt 0 represents the auction has not created
     * @param auction the auction struct data
     */
    function _hasAuctionCreated(Auction storage auction)
        internal
        view
        returns (bool)
    {
        return (auction.startedAt != 0);
    }

    /**
     * @dev Removes an Auction from the mapping
     * @param tokenId the NFT tokenId to find the auction
     */
    function _removeAuction(uint256 tokenId) internal {
        delete tokenIdToAuction[tokenId];
    }

    /**
     * @dev cancels an auction and return the NFT to the seller
     * @param tokenId the NFT
     * @param seller the owner of the NFT
     */
    function _cancelAuction(uint256 tokenId, address seller) internal {
        // transfer funds to bidders

        _removeAuction(tokenId);
        _transferNFT(seller, tokenId);

        emit AuctionCancelled(tokenId);
    }

    /**
     * @dev bids an auction
     * @param tokenId the NFT
     * @param bidAmount the bidding amount
     */
    function _bid(uint256 tokenId, uint256 bidAmount) internal {
        Auction storage auction = tokenIdToAuction[tokenId];

        require(
            _hasAuctionCreated(auction),
            "NFTAuction: The auction has not created"
        );
        require(_isAuctionActive(auction), "NFTAuction: The Auction has ended");
        require(
            auction.startingPrice <= bidAmount,
            "NFTAuction: The amount should be greater than starting price"
        );
        require(
            auction.currentPrice < bidAmount,
            "NFTAuction: The bid amount should be greater than the previous bid amount"
        );

        //pushing the details of the bidder to the mapping to act according to the auction result
        Bidder memory bidder = Bidder(msg.sender, bidAmount, tokenId);
        //biddersOFAToken[tokenId].push(bidder);
        //auction.bidders.push(bidder);
        auction.bidderSize++;
        auction.bidders[auction.bidderSize] = bidder;

        //setting up the highest bidder on struct
        auction.currentPrice = bidAmount;
        auction.highestBidder = msg.sender;

        emit Bid(bidder.bidder, tokenId, bidAmount);
    }

    /**
     * @dev claim NFT Note: only the auction winner can claim NFT
     * @param tokenId the NFT
     */
    function claimNFT(uint256 tokenId) public {
        Auction storage auction = tokenIdToAuction[tokenId];

        require(
            _hasAuctionCreated(auction),
            "NFTAuction: Auction has not been created yet"
        );
        require(
            auction.highestBidder == msg.sender,
            "NFTAuction: Winner can only claim NFT"
        );
        require(
            !_isAuctionActive(auction),
            "NFTAuction: Auction has not ended"
        );

        _transferNFT(msg.sender, tokenId);

        emit ClaimNFT(msg.sender, tokenId);
    }

    /**
     * @dev set referring NFT contract address
     * @param nftContract the referring NFT contract address
     */
    function setNFTInterface(address nftContract) external onlyOwner {
        require(nftContract != address(0), "NFTAuction: Invalid Address");
        NFTContract = IERC721Upgradeable(nftContract);

        emit SetNFTContract(nftContract);
    }

    /**
     * @dev withdraw the bidding amount. Note: only users who lost the bid amount allowed to withdraw.
     * @param tokenId the NFT
     */
    function withdrawBiddingAmount(uint256 tokenId) public {
        Auction storage auction = tokenIdToAuction[tokenId];
        require(
            _hasAuctionCreated(auction),
            "NFTAuction: Auction has not been created yet"
        );
        require(
            !_isAuctionActive(auction),
            "NFTAuction: The auction is not ended yet"
        );
        require(
            auction.highestBidder != msg.sender,
            "NFTAuction: Winner cannot withdraw"
        );

        // transfer bid amount respectively

        for (uint256 i = 0; i < auction.bidderSize; i++) {
            if (auction.bidders[i].bidder == msg.sender) {
                require(
                    auction.bidders[i].bidAmount < address(this).balance,
                    "NFTAuction: Insufficient contract balance"
                );
                (bool succeed, bytes memory data) = msg.sender.call{
                    value: auction.bidders[i].bidAmount
                }("");
                require(succeed, "NFTAuction: Failed to withdraw");
                break;
            }
        }

        /** For Bulk transfer use case **/
        // for (uint256 i = 0; i < auction.bidders.length; i++) {
        //     if (auction.bidders[i].bidder != auction.highestBidder) {
        //         require(
        //             auction.bidders[i].bidAmount < address(this).balance,
        //             "NFTAuction: Insufficient contract balance"
        //         );
        //         (bool succeed, bytes memory data) = msg.sender.call{
        //             value: auction.bidders[i].bidAmount
        //         }("");
        //         require(succeed, "NFTAuction: Failed to withdraw");
        //     }
        // }
    }

    /**
     * @dev create auction public function
     * @param tokenId the NFT
     * @param startingPrice the initial price of the auction
     * @param endingPrice the ending price of the auction
     * @param startTime the auction start time
     * @param endTime the duration of the auction. Note: in epoch unix timestamp
     * @param seller the owner of the NFT
     */
    function createAuction(
        uint256 tokenId,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 startTime,
        uint256 endTime,
        address seller
    ) external whenNotPaused {
        require(
            _isOwnerOf(seller, tokenId),
            "NFTAuction: Only NFT owner can create auction"
        );

        _escrow(msg.sender, tokenId);
        _createAuction(
            tokenId,
            startingPrice,
            endingPrice,
            startTime,
            endTime,
            seller
        );
    }

    /**
     * @dev bidding an auction.
     * @param tokenId the bidding NFT
     */
    function bid(uint256 tokenId) external payable whenNotPaused {
        _bid(tokenId, msg.value);
    }

    /**
     * @dev get auction details
     * @param tokenId the NFT in auction
     */
    function getAuction(uint256 tokenId)
        external
        view
        returns (
            address seller,
            uint256 startingPrice,
            uint256 endingPrice,
            uint256 currentPrice,
            uint256 duration,
            uint256 startedAt,
            uint256 bidders,
            address highestBidder
        )
    {
        Auction storage auction = tokenIdToAuction[tokenId];
        require(_hasAuctionCreated(auction), "NFTAuction: Auction not created");
        return (
            auction.seller,
            auction.startingPrice,
            auction.endingPrice,
            auction.currentPrice,
            auction.duration,
            auction.startedAt,
            auction.bidderSize,
            auction.highestBidder
        );
    }

    /**
     * @dev cancels an auction 
        Note: returns the NFT to the original owner
     * @param tokenId the NFT tokenId 
     */
    function cancelAuction(uint256 tokenId) external {
        Auction storage auction = tokenIdToAuction[tokenId];

        require(
            _hasAuctionCreated(auction),
            "NFTAuction: auction does not exist"
        );
        require(_isAuctionActive(auction), "NFTAuction: Auction has ended");

        require(
            msg.sender == auction.seller,
            "NFTauction: Only auction creator can cancel the auction"
        );

        if (block.timestamp >= auction.startedAt) {
            require(
                auction.bidderSize == 0,
                "NFTauction: Auction with bidders cannot be cancelled"
            );

            _cancelAuction(tokenId, msg.sender);
        } else {
            _cancelAuction(tokenId, msg.sender);
        }
    }

    /**
     * @dev cancels an auction when paused
       Note: Function accessible for contract owner only for emergency purposes.
     * @param tokenId the NFT tokenId
     */
    function cancelAuctionWhenPaused(uint256 tokenId)
        external
        whenPaused
        onlyOwner
    {
        Auction storage auction = tokenIdToAuction[tokenId];

        require(
            _hasAuctionCreated(auction),
            "NFTAuction: auction does not exist"
        );

        require(_isAuctionActive(auction), "NFTAuction: Auction has ended");

        if (block.timestamp >= auction.startedAt) {
            require(
                auction.bidderSize == 0,
                "NFTauction: Auction with bidders cannot be cancelled"
            );

            _cancelAuction(tokenId, msg.sender);
        } else {
            _cancelAuction(tokenId, msg.sender);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}