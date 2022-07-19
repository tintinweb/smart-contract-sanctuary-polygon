// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../utils/TransferHelper.sol";

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract NftAuction is IERC721Receiver, ReentrancyGuard, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    enum AuctionType {
        dutchAuction,
        englishAuction
    }

    struct Auction {
        uint256 auctionID;
        uint256 highestBid;
        uint256 startBid;
        uint256 endBid;
        address highestBidder;
        bool isActive;
        address originalOwner;
        bool isSold;
        address nftAddress;
        bool paymentType;
        AuctionType orderType;
        uint64 startingTime;
        uint64 closingTime;
        uint256[] tokenIDs;
    }

    mapping(uint256 => uint256) private _nftToAuctionId; //  TokenID -> AuctionID

    uint256 public _auctionIds;

    mapping(uint256 => Auction) private auctions;
    mapping(address => mapping(uint256 => uint256)) public claimableFunds; // User address -> AuctionID -> amount claimable

    address public immutable erc20;

    EnumerableSet.AddressSet private _allowedNFTs;
    address public treasuryAddress;
    uint256 public treasuryPercentagehaka;
    uint256 public treasuryPercentageMatic;

    modifier onlyAuctionActive(uint256 _auctionId) {
        require(auctions[_auctionId].isActive == true, "Not active auction");
        _;
    }

    event NewAuctionOpened(
        uint256 indexed auctionId,
        AuctionType indexed orderType,
        uint256[] nftIds,
        uint256 startingBid,
        uint64 startingTime,
        uint64 closingTime,
        address originalOwner,
        bool paymentTypeMatic
    );

    event EnglishAuctionClosed(uint256 indexed auctionId, uint256 highestBid, address indexed highestBidder);

    event BidPlacedInEnglishAuction(
        uint256 indexed auctionId,
        uint256 indexed bidPrice,
        address indexed bidder,
        bool paymentTypeMatic
    );

    event BoughtNFTInDutchAuction(uint256 indexed auctionId, uint256 indexed bidPrice, address indexed buyer);

    event AuctionCancelled(uint256 indexed auctionId, address indexed cancelledBy);

    event Fundclaimed(uint256 indexed auctionId, address sender, bool paymentType, uint256 funds);

    constructor(address _erc20, address _treasuryAddress) {
        erc20 = _erc20;
        treasuryAddress = _treasuryAddress;
    }

    function getAuction(uint256 _id) external view returns(Auction memory) {
        return auctions[_id];
    }

    function allowedNFTs() external view returns (address[] memory) {
        return _allowedNFTs.values();
    }

    function addNFTCollection(address _nftCollection) external onlyOwner {
        require(!_allowedNFTs.contains(_nftCollection), "Already added");
        _allowedNFTs.add(_nftCollection);
    }

    function removeNFTCollection(address _nftCollection) external onlyOwner {
        require(_allowedNFTs.contains(_nftCollection), "Already removed");
        _allowedNFTs.remove(_nftCollection);
    }

    function setTreasuryPercentageforhaka(uint256 _treasuryPercentage) external onlyOwner {
        require(_treasuryPercentage <= 1000 && _treasuryPercentage >= 0, "Treasury Percentage limitation");
        treasuryPercentagehaka = _treasuryPercentage;
    }

    function setTreasuryPercentageforMatic(uint256 _treasuryPercentage) external onlyOwner {
        require(_treasuryPercentage <= 1000 && _treasuryPercentage >= 0, "Treasury Percentage limitation");
        treasuryPercentageMatic = _treasuryPercentage;
    }

    function transferFromWithTreasury(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        uint256 treasuryFee = (_amount * treasuryPercentagehaka) / 10000; // 100 * 100;
        TransferHelper.safeTransferFrom(erc20, _from, treasuryAddress, treasuryFee);
        TransferHelper.safeTransferFrom(erc20, _from, _to, _amount - treasuryFee);
    }

    function transferWithTreasury(address _to, uint256 _amount) internal {
        uint256 treasuryFee = (_amount * treasuryPercentagehaka) / 10000;
        TransferHelper.safeTransfer(erc20, treasuryAddress, treasuryFee);
        TransferHelper.safeTransfer(erc20, _to, _amount - treasuryFee);
    }

    function getCurrentPrice(uint256 _auctionId, AuctionType orderType) public view returns (uint256) {
        if (AuctionType.englishAuction == orderType) {
            return auctions[_auctionId].highestBid;
        } else {
            uint256 _startPrice = auctions[_auctionId].startBid;
            uint256 _endPrice = auctions[_auctionId].endBid;
            uint256 _startingTime = auctions[_auctionId].startingTime;
            uint256 tickPerBlock = (_startPrice - _endPrice) / (auctions[_auctionId].closingTime - _startingTime);
            return _startPrice - ((block.timestamp - _startingTime) * tickPerBlock);
        }
    }

    function startDutchAuction(
        address nftAddress,
        uint256[] calldata _nftIds,
        uint256 _startPrice,
        uint256 _endBid,
        uint64 _startingTime,
        uint64 _closingTime,
        bool _paymentTypeMatic
    ) external returns (uint256) {
        require(_allowedNFTs.contains(nftAddress), "Not allowed collection");
        require(_startPrice > _endBid, "End price should be lower than start price");
        AuctionType choicee = AuctionType.dutchAuction;
        return
            openAuction(
                choicee,
                nftAddress,
                _nftIds,
                _startPrice,
                _endBid,
                _startingTime,
                _closingTime,
                _paymentTypeMatic
            );
    }

    function startEnglishAuction(
        address nftAddress,
        uint256[] calldata _nftIds,
        uint256 _startPrice,
        uint64 _startingTime,
        uint64 _closingTime,
        bool _paymentTypeMatic
    ) external returns (uint256) {
        require(_allowedNFTs.contains(nftAddress), "Not allowed collection");
        AuctionType choicee = AuctionType.englishAuction;
        return
            openAuction(choicee, nftAddress, _nftIds, _startPrice, 0, _startingTime, _closingTime, _paymentTypeMatic);
    }

    function openAuction(
        AuctionType _orderType,
        address nftAddress,
        uint256[] calldata _nftIds,
        uint256 _initialBid,
        uint256 _endBid,
        uint64 _startingTime,
        uint64 _closingTime,
        bool _paymentTypeMatic
    ) private nonReentrant returns (uint256) {
        require(_nftIds.length > 0, "Atleast one NFT should be specified");
        require(_startingTime > 0 && _closingTime > 0 && _initialBid > 0, "Invalid input");
        for (uint256 i = 0; i < _nftIds.length; i++) {
            require(_nftToAuctionId[_nftIds[i]] == 0, "An auction Bundle exists with one of the given NFT");
            address nftOwner = IERC721(nftAddress).ownerOf(_nftIds[i]);
            require(_msgSender() == nftOwner, "Not owner of one or more NFTs");
        }

        uint256 newAuctionId = ++_auctionIds;
        auctions[newAuctionId].auctionID = newAuctionId;
        auctions[newAuctionId].orderType = _orderType;
        auctions[newAuctionId].startBid = _initialBid;
        auctions[newAuctionId].endBid = _endBid;
        auctions[newAuctionId].startingTime = _startingTime;
        auctions[newAuctionId].closingTime = _closingTime;
        auctions[newAuctionId].highestBid = _initialBid;
        auctions[newAuctionId].highestBidder = _msgSender();
        auctions[newAuctionId].originalOwner = _msgSender();
        auctions[newAuctionId].isActive = true;
        auctions[newAuctionId].nftAddress = nftAddress;
        auctions[newAuctionId].tokenIDs = _nftIds;
        auctions[newAuctionId].paymentType = _paymentTypeMatic;

        for (uint256 i = 0; i < _nftIds.length; i++) {
            _nftToAuctionId[_nftIds[i]] = newAuctionId;
            IERC721(nftAddress).transferFrom(_msgSender(), address(this), _nftIds[i]);
        }

        emit NewAuctionOpened(
            newAuctionId,
            _orderType,
            _nftIds,
            auctions[newAuctionId].startBid,
            auctions[newAuctionId].startingTime,
            auctions[newAuctionId].closingTime,
            auctions[newAuctionId].originalOwner,
            auctions[newAuctionId].paymentType
        );
        return newAuctionId;
    }

    function placeBidInEnglishAuction(
        uint256 _auctionId,
        uint256 _amount,
        AuctionType orderType
    ) external payable nonReentrant onlyAuctionActive(_auctionId) {
        require(orderType == AuctionType.englishAuction, "only for English Auction");
        require(auctions[_auctionId].originalOwner != _msgSender(), "Owner cant place bid");
        require(auctions[_auctionId].orderType == orderType, "Only English auction bid can be used");
        require(auctions[_auctionId].closingTime > block.timestamp, "Auction is closed");
        require(_amount > auctions[_auctionId].highestBid, "Bid is too low");
        require(_msgSender() != auctions[_auctionId].highestBidder, "Highest bidder cannot outbid himeself");
        uint256 lockedFunds = claimableFunds[_msgSender()][_auctionId];
        uint256 toLock = _amount - lockedFunds;

        if (auctions[_auctionId].paymentType) {
            require(_amount == lockedFunds + msg.value, "_amount should be equal to funds available");
            require(toLock == msg.value, "Matic transfer to be equal amount require to locked");
        }

        if (auctions[_auctionId].closingTime - block.timestamp <= 600) {
            auctions[_auctionId].closingTime += 60;
        }
        // Lock Additional funds only if the user has made a bid before on the same auction

        if (!auctions[_auctionId].paymentType) {
            TransferHelper.safeTransferFrom(erc20, _msgSender(), address(this), toLock);
        }

        claimableFunds[_msgSender()][_auctionId] = 0;

        // Make previous highest bidder's funds claimable
        claimableFunds[auctions[_auctionId].highestBidder][_auctionId] = auctions[_auctionId].highestBid;

        // Make current bidder the highest bidder
        auctions[_auctionId].highestBid = _amount;
        auctions[_auctionId].highestBidder = _msgSender();
        emit BidPlacedInEnglishAuction(
            _auctionId,
            auctions[_auctionId].highestBid,
            auctions[_auctionId].highestBidder,
            auctions[_auctionId].paymentType
        );
    }

    function buyNftFromDutchAuction(
        uint256 _auctionId,
        uint256 _amount,
        AuctionType orderType
    ) external payable nonReentrant onlyAuctionActive(_auctionId) {
        AuctionType choicee = AuctionType.dutchAuction;
        require(auctions[_auctionId].originalOwner != _msgSender(), "Owner cant place bid");
        require(auctions[_auctionId].closingTime > block.timestamp, "Auction is closed");
        require(auctions[_auctionId].orderType == orderType, "Only Dutch auction id can be used");
        require(orderType == choicee, "only for Dutch Auction");
        require(auctions[_auctionId].isSold == false, "Already sold");
        uint256 currentPrice = getCurrentPrice(_auctionId, choicee);
        require(_amount >= currentPrice, "price error");
        if (auctions[_auctionId].paymentType) {
            require(_amount == msg.value, "Transfer matic amount equal to value");
        }

        address seller = auctions[_auctionId].originalOwner;

        auctions[_auctionId].highestBid = _amount;
        auctions[_auctionId].highestBidder = _msgSender();
        auctions[_auctionId].isSold = true;
        uint256 fees = (_amount * treasuryPercentageMatic) / 10000;
        uint256 Maticpay = _amount - fees;
        // transferring price to seller of nft
        if (!auctions[_auctionId].paymentType) {
            transferFromWithTreasury(_msgSender(), seller, _amount);
        } else {
            payable(seller).transfer(Maticpay);
            payable(treasuryAddress).transfer(fees);
        }
        //transferring nft to highest bidder
        address nftAddress = auctions[_auctionId].nftAddress;
        uint256[] memory _nftIds = auctions[_auctionId].tokenIDs;
        for (uint256 i = 0; i < _nftIds.length; i++) {
            _nftToAuctionId[_nftIds[i]] = 0;
            IERC721(nftAddress).transferFrom(address(this), _msgSender(), _nftIds[i]);
        }

        emit BoughtNFTInDutchAuction(_auctionId, auctions[_auctionId].highestBid, auctions[_auctionId].highestBidder);
    }

    function claimNftFromEnglishAuction(uint256 _auctionId) external nonReentrant onlyAuctionActive(_auctionId) {
        require(auctions[_auctionId].closingTime <= block.timestamp, "Auction is not closed");
        require(auctions[_auctionId].highestBidder == _msgSender(), "You are not owner of this NFT");

        address seller = auctions[_auctionId].originalOwner;
        uint256 fees = (auctions[_auctionId].highestBid * treasuryPercentageMatic) / 10000;
        uint256 sellerMatic = auctions[_auctionId].highestBid - fees;
        auctions[_auctionId].isActive = false;
        if (auctions[_auctionId].originalOwner != _msgSender()) {
            if (!auctions[_auctionId].paymentType) {
                //sending price to seller of nft
                transferWithTreasury(seller, auctions[_auctionId].highestBid);
            } else {
                payable(seller).transfer(sellerMatic);
                payable(treasuryAddress).transfer(fees);
            }
        }
        //transferring nft to highest bidder
        address nftAddress = auctions[_auctionId].nftAddress;
        uint256[] memory _nftIds = auctions[_auctionId].tokenIDs;
        for (uint256 i = 0; i < _nftIds.length; i++) {
            _nftToAuctionId[_nftIds[i]] = 0;
            IERC721(nftAddress).transferFrom(address(this), auctions[_auctionId].highestBidder, _nftIds[i]);
        }
        emit EnglishAuctionClosed(_auctionId, auctions[_auctionId].highestBid, auctions[_auctionId].highestBidder);
    }

    function claimFundsFromEnglishAuction(uint256 _auctionId) external nonReentrant {
        address sender = _msgSender();
        uint256 claimable = claimableFunds[sender][_auctionId];
        require(claimable > 0, "No funds to claim for this auction ID");
        claimableFunds[sender][_auctionId] = 0;
        if (!auctions[_auctionId].paymentType) {
            TransferHelper.safeTransfer(erc20, sender, claimable);
        } else {
            payable(sender).transfer(claimable);
        }
        emit Fundclaimed(_auctionId, sender, auctions[_auctionId].paymentType, claimable);
    }

    function cancelAuction(uint256 _auctionId) external nonReentrant onlyAuctionActive(_auctionId) {
        require(auctions[_auctionId].closingTime > block.timestamp, "Auction is closed");
        require(auctions[_auctionId].startBid == auctions[_auctionId].highestBid, "Bids were placed in the Auction");
        require(auctions[_auctionId].originalOwner == _msgSender(), "You are not the creator of Auction");
        auctions[_auctionId].isActive = false;

        address nftAddress = auctions[_auctionId].nftAddress;
        uint256[] memory _nftIds = auctions[_auctionId].tokenIDs;
        for (uint256 i = 0; i < _nftIds.length; i++) {
            _nftToAuctionId[_nftIds[i]] = 0;
            IERC721(nftAddress).transferFrom(address(this), auctions[_auctionId].originalOwner, _nftIds[i]);
        }

        emit AuctionCancelled(_auctionId, _msgSender());
    }

    function getBundledNFTs(uint256 _auctionId) external view returns (uint256[] memory) {
        return auctions[_auctionId].tokenIDs;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

library TransferHelper {
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::safeTransfer: transfer failed");
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::transferFrom: transferFrom failed");
    }
}

// SPDX-License-Identifier: MIT

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