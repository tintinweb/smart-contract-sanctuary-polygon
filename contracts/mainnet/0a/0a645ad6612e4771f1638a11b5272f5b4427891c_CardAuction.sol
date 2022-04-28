// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/**
 * FANZONE.io NFT implementation of the LUKSO LSP-8-IdentifiableDigitalAsset standard
 * for more see https://fanzone.io/nfts
 */

// constants
import { FEE_COLLECTOR_NAME_HASH } from "../registry/constants.sol";

// libraries
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// interfaces
import "@lukso/lsp-smart-contracts/contracts/LSP7DigitalAsset/extensions/ILSP7CompatibilityForERC20.sol";
import "../registry/IContractRegistry.sol";
import "../royalties/IFeeCollector.sol";
import "../royalties/IFeeCollectorRevenueShareCallback.sol";
import "../royalties/IRoyaltyShares.sol";
import "./ICardAuction.sol";

// modules
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@lukso/lsp-smart-contracts/contracts/LSP8IdentifiableDigitalAsset/LSP8IdentifiableDigitalAsset.sol";
import "../registry/UsesContractRegistry.sol";

contract CardAuction is
    ICardAuction,
    IFeeCollectorRevenueShareCallback,
    Ownable,
    Pausable,
    UsesContractRegistry
{
    //
    // --- Errors
    //

    error CardAuctionTokenNotWhitelisted(address token);
    error CardAuctionActiveAuction(address lsp8Contract, bytes32 tokenId);
    error CardAuctionNoActiveAuction(address lsp8Contract, bytes32 tokenId);
    error CardAuctionInvalidMinimumBid();
    error CardAuctionInvalidDuration();
    error CardAuctionBidTooSmall(uint256 bidAmount, uint256 minimumBid);
    error CardAuctionHasEnded();
    error CardAuctionCannotCancelAuctionWhenNotSeller(
        address msgSender,
        address seller
    );
    error CardAuctionCannotCancelAuctionWithActiveBid();
    error CardAuctionCannotFinalizeWithoutActiveBid(bytes32 tokenId);
    error CardAuctionInvalidAuctionSetting(
        uint24 value,
        uint256 minValue,
        uint256 maxValue
    );

    //
    // --- Constants
    //

    // using basis points to describe bid
    uint256 private constant AUCTION_BID_SCALE = 100_00;
    uint256 private constant AUCTION_BID_STEP = 5_00;

    //
    // --- Storage
    //

    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _allLSP8Auctions;
    mapping(address => EnumerableSet.Bytes32Set) private _allAuctions;

    mapping(address => mapping(bytes32 => CardAuctionState))
        private _auctionStateForTokenId;
    mapping(address => mapping(address => uint256))
        private _claimableAmountsForAccount;

    AuctionSettings private _auctionSettings;

    //
    // --- Initialize
    //

    // solhint-disable-next-line no-empty-blocks
    constructor(
        address contractRegistry,
        uint24 minAuctionDuration,
        uint24 maxAuctionDuration,
        uint24 bidExtensionDuration
    ) UsesContractRegistry(contractRegistry) {
        setAuctionSettings(
            minAuctionDuration,
            maxAuctionDuration,
            bidExtensionDuration
        );
    }

    //
    // --- Admin actions
    //

    function pause() public override onlyOwner whenNotPaused {
        _pause();
    }

    function setAuctionSettings(
        uint24 minAuctionDuration,
        uint24 maxAuctionDuration,
        uint24 bidExtensionDuration
    ) public override onlyOwner {
        _validateAuctionSetting(minAuctionDuration, 1 minutes, 1 days);
        _validateAuctionSetting(maxAuctionDuration, 1 days, 30 days);
        _validateAuctionSetting(bidExtensionDuration, 1 minutes, 10 minutes);

        _auctionSettings = AuctionSettings({
            minAuctionDuration: minAuctionDuration,
            maxAuctionDuration: maxAuctionDuration,
            bidExtensionDuration: bidExtensionDuration
        });
    }

    function _validateAuctionSetting(
        uint24 value,
        uint256 minValue,
        uint256 maxValue
    ) internal {
        if (value < minValue || value > maxValue) {
            revert CardAuctionInvalidAuctionSetting(value, minValue, maxValue);
        }
    }

    //
    // --- Auction queries
    //

    function auctionSettings()
        public
        view
        override
        returns (AuctionSettings memory)
    {
        return _auctionSettings;
    }

    function auctionFor(address lsp8Contract, bytes32 tokenId)
        public
        view
        override
        returns (CardAuctionState memory)
    {
        CardAuctionState storage auction = _auctionStateForTokenId[
            lsp8Contract
        ][tokenId];

        if (auction.minimumBid == 0) {
            revert CardAuctionNoActiveAuction(lsp8Contract, tokenId);
        }

        return auction;
    }

    function getAllAuctions()
        public
        view
        override
        returns (AuctionsForLSP8Contract[] memory)
    {
        uint256 allAuctionsLength = _allLSP8Auctions.length();
        AuctionsForLSP8Contract[]
            memory allAuctions = new AuctionsForLSP8Contract[](
                allAuctionsLength
            );

        for (uint256 i = 0; i < allAuctionsLength; i++) {
            address lsp8Contract = _allLSP8Auctions.at(i);
            allAuctions[i] = getAuctionsForLSP8Contract(lsp8Contract);
        }

        return allAuctions;
    }

    function getAuctionsForLSP8Contract(address lsp8Contract)
        public
        view
        override
        returns (AuctionsForLSP8Contract memory)
    {
        uint256 auctionsForLSP8ContractLength = _allAuctions[lsp8Contract]
            .length();
        AuctionsForLSP8Contract
            memory auctionsForLSP8Contract = AuctionsForLSP8Contract({
                lsp8Contract: lsp8Contract,
                auctions: new AuctionForTokenId[](auctionsForLSP8ContractLength)
            });

        for (uint256 j = 0; j < auctionsForLSP8ContractLength; j++) {
            bytes32 tokenId = _allAuctions[lsp8Contract].at(j);
            auctionsForLSP8Contract.auctions[j] = AuctionForTokenId({
                tokenId: tokenId,
                auction: auctionFor(lsp8Contract, tokenId)
            });
        }

        return auctionsForLSP8Contract;
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
    ) public override whenNotPaused {
        address seller = _msgSender();
        CardAuctionState storage auction = _auctionStateForTokenId[
            lsp8Contract
        ][tokenId];
        if (auction.minimumBid > 0) {
            revert CardAuctionActiveAuction(lsp8Contract, tokenId);
        }
        if (minimumBid == 0) {
            revert CardAuctionInvalidMinimumBid();
        }

        if (
            duration < _auctionSettings.minAuctionDuration ||
            duration > _auctionSettings.maxAuctionDuration
        ) {
            revert CardAuctionInvalidDuration();
        }

        if (
            !IContractRegistry(UsesContractRegistry.contractRegistry())
                .isWhitelistedToken(acceptedToken)
        ) {
            revert CardAuctionTokenNotWhitelisted(acceptedToken);
        }

        // solhint-disable-next-line not-rely-on-time
        uint256 endTime = block.timestamp + duration;
        _auctionStateForTokenId[lsp8Contract][tokenId] = CardAuctionState({
            seller: seller,
            acceptedToken: acceptedToken,
            minimumBid: minimumBid,
            endTime: endTime,
            activeBidder: address(0),
            activeBidAmount: 0
        });

        _allLSP8Auctions.add(lsp8Contract);
        _allAuctions[lsp8Contract].add(tokenId);

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
    ) public override {
        address bidder = _msgSender();
        CardAuctionState memory auction = _auctionStateForTokenId[lsp8Contract][
            tokenId
        ];
        if (auction.minimumBid == 0) {
            revert CardAuctionNoActiveAuction(lsp8Contract, tokenId);
        }

        uint256 minimumBid = auction.minimumBid;
        if (auction.activeBidAmount > 0) {
            minimumBid =
                (auction.activeBidAmount * AUCTION_BID_STEP) /
                AUCTION_BID_SCALE;
        }
        if (bidAmount < minimumBid) {
            revert CardAuctionBidTooSmall(bidAmount, minimumBid);
        }

        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp > auction.endTime) {
            revert CardAuctionHasEnded();
        }

        if (auction.activeBidAmount > 0) {
            _updateClaimableAmount(
                auction.acceptedToken,
                auction.activeBidder,
                auction.activeBidAmount
            );
        }

        // update auctions active bid
        _auctionStateForTokenId[lsp8Contract][tokenId]
            .activeBidAmount = bidAmount;
        _auctionStateForTokenId[lsp8Contract][tokenId].activeBidder = bidder;

        // when a bid is made near the end of the auction, extend the auction to allow for other
        // bidders to react to the bid
        uint256 endTime = auction.endTime;
        uint24 bidExtensionDuration = _auctionSettings.bidExtensionDuration;
        if (block.timestamp + bidExtensionDuration > auction.endTime) {
            endTime = auction.endTime + bidExtensionDuration;
            _auctionStateForTokenId[lsp8Contract][tokenId].endTime = endTime;
        }

        ILSP7CompatibilityForERC20(auction.acceptedToken).transferFrom(
            bidder,
            address(this),
            bidAmount
        );

        emit AuctionBid(lsp8Contract, tokenId, bidder, bidAmount, endTime);
    }

    function cancelAuctionFor(address lsp8Contract, bytes32 tokenId)
        public
        override
    {
        address msgSender = _msgSender();
        CardAuctionState memory auction = _auctionStateForTokenId[lsp8Contract][
            tokenId
        ];
        if (auction.minimumBid == 0) {
            revert CardAuctionNoActiveAuction(lsp8Contract, tokenId);
        }
        if (auction.seller != msgSender) {
            revert CardAuctionCannotCancelAuctionWhenNotSeller(
                msgSender,
                auction.seller
            );
        }
        if (auction.activeBidder != address(0)) {
            revert CardAuctionCannotCancelAuctionWithActiveBid();
        }

        _deleteAuction(lsp8Contract, tokenId);

        ILSP8IdentifiableDigitalAsset(lsp8Contract).transfer(
            address(this),
            auction.seller,
            tokenId,
            true,
            ""
        );

        emit AuctionCancel(lsp8Contract, tokenId);
    }

    function finalizeAuctionFor(address lsp8Contract, bytes32 tokenId)
        public
        override
    {
        CardAuctionState memory auction = _auctionStateForTokenId[lsp8Contract][
            tokenId
        ];
        if (auction.minimumBid == 0) {
            revert CardAuctionNoActiveAuction(lsp8Contract, tokenId);
        }
        if (auction.activeBidAmount == 0) {
            revert CardAuctionCannotFinalizeWithoutActiveBid(tokenId);
        }
        // solhint-disable-next-line not-rely-on-time
        if (auction.endTime > block.timestamp) {
            revert CardAuctionActiveAuction(lsp8Contract, tokenId);
        }

        _deleteAuction(lsp8Contract, tokenId);

        uint256 sellerAmount = auction.activeBidAmount;

        if (_supportsRoyaltyShares(lsp8Contract)) {
            uint256 totalFee = IFeeCollector(_getFeeCollectorAddress())
                .shareRevenue(
                    auction.acceptedToken,
                    auction.activeBidAmount,
                    address(0),
                    IRoyaltyShares(lsp8Contract).royaltyShares(),
                    abi.encode(auction.acceptedToken)
                );
            sellerAmount = auction.activeBidAmount - totalFee;
        }

        _updateClaimableAmount(
            auction.acceptedToken,
            auction.seller,
            sellerAmount
        );

        ILSP8IdentifiableDigitalAsset(lsp8Contract).transfer(
            address(this),
            auction.activeBidder,
            tokenId,
            true,
            ""
        );

        emit AuctionFinalize(
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
        _claimableAmountsForAccount[account][token] =
            _claimableAmountsForAccount[account][token] +
            amount;
    }

    function _deleteAuction(address lsp8Contract, bytes32 tokenId) private {
        delete _auctionStateForTokenId[lsp8Contract][tokenId];

        _allAuctions[lsp8Contract].remove(tokenId);

        if (_allAuctions[lsp8Contract].length() == 0) {
            _allLSP8Auctions.remove(lsp8Contract);
        }
    }

    // TODO(one-day as we need to redeploy CardToken): this could be a ERC165 like call, as this will load the array from storage in the
    // implementing contract but not use the value
    function _supportsRoyaltyShares(address lsp8Contract)
        private
        returns (bool)
    {
        (bool success, ) = lsp8Contract.staticcall(
            abi.encodeWithSelector(IRoyaltyShares.royaltyShares.selector)
        );
        return success;
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
        return _claimableAmountsForAccount[account][token];
    }

    //
    // --- Claimable logic
    //

    function claimToken(address account, address token)
        public
        override
        returns (uint256)
    {
        uint256 amount = _claimableAmountsForAccount[account][token];
        if (amount > 0) {
            delete _claimableAmountsForAccount[account][token];

            ILSP7CompatibilityForERC20(token).transfer(account, amount);
        }

        return amount;
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

        address token = abi.decode(dataForCallback, (address));

        ILSP7CompatibilityForERC20(token).transfer(feeCollector, totalFee);
    }

    //
    // --- Contract Registry queries
    //

    function _getFeeCollectorAddress() internal view returns (address) {
        return
            IContractRegistry(UsesContractRegistry.contractRegistry())
                .getRegisteredContract(FEE_COLLECTOR_NAME_HASH);
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/*
 * FANZONE.io NFT implementation of the LUKSO LSP-8-IdentifiableDigitalAsset standard
 * for more see https://fanzone.io/nfts
 */

// keccak256("FeeCollector")
bytes32 constant FEE_COLLECTOR_NAME_HASH = 0xd59ed7e0cf777b70bff43b36b5e7942a53db5cdc1ed3eac0584ffe6898bb47cd;

// keccak256("CardTokenScoring")
bytes32 constant CARD_TOKEN_SCORING_NAME_HASH = 0xdffe073e73d032dfae2943de6514599be7d9b1cd7b5ff3c3cafaeafef9ce8120;

// keccak256("OpenSeaProxy")
bytes32 constant OPENSEA_PROXY_NAME_HASH = 0x0cef494da2369e60d9db5c21763fa9ba82fceb498a37b9aaa12fe66296738da9;

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

/**
 * FANZONE.io NFT implementation of the LUKSO LSP-8-IdentifiableDigitalAsset standard
 * for more see https://fanzone.io/nfts
 */

interface IContractRegistry {
    //
    // --- Events
    //

    event RegisteredContract(bytes32 nameHash, address target);
    event WhitelistedToken(address token, bool whitelisted);

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

    function allWhitelistedTokens() external view returns (address[] memory);

    //
    // --- Whitelist Token Logic
    //

    function setWhitelistedToken(address token) external;

    function removeWhitelistedToken(address token) external;
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/**
 * FANZONE.io NFT implementation of the LUKSO LSP-8-IdentifiableDigitalAsset standard
 * for more see https://fanzone.io/nfts
 */

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

/**
 * FANZONE.io NFT implementation of the LUKSO LSP-8-IdentifiableDigitalAsset standard
 * for more see https://fanzone.io/nfts
 */

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

/**
 * FANZONE.io NFT implementation of the LUKSO LSP-8-IdentifiableDigitalAsset standard
 * for more see https://fanzone.io/nfts
 */

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

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/**
 * FANZONE.io NFT implementation of the LUKSO LSP-8-IdentifiableDigitalAsset standard
 * for more see https://fanzone.io/nfts
 */

interface ICardAuction {
    //
    // --- Structs
    //

    struct CardAuctionState {
        address seller;
        address acceptedToken;
        uint256 minimumBid;
        uint256 endTime;
        address activeBidder;
        uint256 activeBidAmount;
    }

    struct AuctionsForLSP8Contract {
        address lsp8Contract;
        AuctionForTokenId[] auctions;
    }

    struct AuctionForTokenId {
        bytes32 tokenId;
        CardAuctionState auction;
    }

    struct AuctionSettings {
        uint24 minAuctionDuration;
        uint24 maxAuctionDuration;
        uint24 bidExtensionDuration;
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

    event AuctionBid(
        address indexed lsp8Contract,
        bytes32 indexed tokenId,
        address indexed bidder,
        uint256 bidAmount,
        uint256 endTime
    );

    event AuctionCancel(address indexed lsp8Contract, bytes32 indexed tokenId);

    event AuctionFinalize(
        address indexed lsp8Contract,
        bytes32 indexed tokenId,
        address indexed auctionWinner,
        uint256 bidAmount
    );

    //
    // --- Admin actions
    //

    function pause() external;

    function setAuctionSettings(
        uint24 minAuctionDuration,
        uint24 maxAuctionDuration,
        uint24 bidExtensionDuration
    ) external;

    //
    // --- Auction queries
    //

    function auctionSettings() external view returns (AuctionSettings memory);

    function auctionFor(address lsp8Contract, bytes32 tokenId)
        external
        view
        returns (CardAuctionState memory);

    function getAllAuctions()
        external
        view
        returns (AuctionsForLSP8Contract[] memory);

    function getAuctionsForLSP8Contract(address lsp8Contract)
        external
        view
        returns (AuctionsForLSP8Contract memory);

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
    ) external;

    function cancelAuctionFor(address lsp8Contract, bytes32 tokenId) external;

    function finalizeAuctionFor(address lsp8Contract, bytes32 tokenId) external;

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
     * @notice Sets the token-Metadata
     * @param name_ The name of the token
     * @param symbol_ The symbol of the token
     * @param newOwner_ The owner of the the token-Metadata
     */
    constructor(
        string memory name_,
        string memory symbol_,
        address newOwner_
    ) LSP4DigitalAssetMetadata(name_, symbol_, newOwner_) {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC165Storage)
        returns (bool)
    {
        return
            interfaceId == _INTERFACEID_LSP8 ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/**
 * FANZONE.io NFT implementation of the LUKSO LSP-8-IdentifiableDigitalAsset standard
 * for more see https://fanzone.io/nfts
 */

// interfaces
import "./IUsesContractRegistry.sol";

abstract contract UsesContractRegistry is IUsesContractRegistry {
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

    constructor(address contractRegistry_) internal {
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

/**
 * FANZONE.io NFT implementation of the LUKSO LSP-8-IdentifiableDigitalAsset standard
 * for more see https://fanzone.io/nfts
 */

library RoyaltySharesLib {
    struct RoyaltyShare {
        address receiver;
        // using basis points to describe shares
        uint96 share;
    }
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
    error LSP8NotTokenOwner(
        address tokenOwner,
        bytes32 tokenId,
        address caller
    );
    error LSP8NotTokenOperator(bytes32 tokenId, address caller);
    error LSP8CannotUseAddressZeroAsOperator();
    error LSP8CannotSendToAddressZero();
    error LSP8TokenIdAlreadyMinted(bytes32 tokenId);
    error LSP8InvalidTransferBatch();
    error LSP8NotifyTokenReceiverContractMissingLSP1Interface(
        address tokenReceiver
    );
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
        if (
            from.length != to.length ||
            from.length != tokenId.length ||
            from.length != data.length
        ) {
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

        _beforeTokenTransfer(tokenOwner, address(0), tokenId);

        _clearOperators(tokenOwner, tokenId);

        _ownedTokens[tokenOwner].remove(tokenId);
        delete _tokenOwners[tokenId];

        emit Transfer(operator, tokenOwner, address(0), tokenId, false, data);

        _notifyTokenSender(tokenOwner, address(0), tokenId, data);
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

        _beforeTokenTransfer(from, to, tokenId);

        _clearOperators(from, tokenId);

        _ownedTokens[from].remove(tokenId);
        _ownedTokens[to].add(tokenId);
        _tokenOwners[tokenId] = to;

        emit Transfer(operator, from, to, tokenId, force, data);

        _notifyTokenSender(from, to, tokenId, data);
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
            if (to.code.length > 0) {
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
        // set key SupportedStandards:LSP4DigitalAsset
        _setData(
            _LSP4_SUPPORTED_STANDARDS_KEY,
            _LSP4_SUPPORTED_STANDARDS_VALUE
        );

        _setData(_LSP4_TOKEN_NAME_KEY, bytes(name_));
        _setData(_LSP4_TOKEN_SYMBOL_KEY, bytes(symbol_));
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

// --- ERC725Y Keys

// bytes8('LSP8MetadataAddress') + bytes4(0)
bytes12 constant _LSP8_METADATA_ADDRESS_KEY_PREFIX = 0x73dcc7c3c4096cdc00000000;

// bytes8('LSP8MetadataJSON') + bytes4(0)
bytes12 constant _LSP8_METADATA_JSON_KEY_PREFIX = 0x9a26b4060ae7f7d500000000;

// --- Token Hooks

// keccak256('LSP8TokensSender')
bytes32 constant _TYPEID_LSP8_TOKENSSENDER = 0x3724c94f0815e936299cca424da4140752198e0beb7931a6e0925d11bc97544c;

// keccak256('LSP8TokensRecipient')
bytes32 constant _TYPEID_LSP8_TOKENSRECIPIENT = 0xc7a120a42b6057a0cbed111fbbfbd52fcd96748c04394f77fc2c3adbe0391e01;

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// --- ERC725Y entries

// bytes16(keccak256('SupportedStandard')) + bytes12(0) + bytes4(keccak256('LSP4DigitalAsset'))
bytes32 constant _LSP4_SUPPORTED_STANDARDS_KEY = 0xeafec4d89fa9619884b6b89135626455000000000000000000000000a4d96624;

// bytes4(keccak256('LSP4DigitalAsset'))
bytes constant _LSP4_SUPPORTED_STANDARDS_VALUE = hex"a4d96624";

// keccak256('LSP4TokenName')
bytes32 constant _LSP4_TOKEN_NAME_KEY = 0xdeba1e292f8ba88238e10ab3c7f88bd4be4fac56cad5194b6ecceaf653468af1;

// keccak256('LSP4TokenSymbol')
bytes32 constant _LSP4_TOKEN_SYMBOL_KEY = 0x2f0a68ab07768e01943a599e73362a0e17a63a72e94dd2e384d2c1d4db932756;

// keccak256('LSP4Creators[]')
bytes32 constant _LSP4_CREATORS_ARRAY_KEY = 0x114bd03b3a46d48759680d81ebb2b414fda7d030a7105a851867accf1c2352e7;

// bytes8(keccak256('LSP4CreatorsMap')) + bytes4(0)
bytes12 constant _LSP4_CREATORS_MAP_KEY_PREFIX = 0x6de85eaf5d982b4e00000000;

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// interfaces
import "@erc725/smart-contracts/contracts/interfaces/IERC725Y.sol";

library ERC725Utils {
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

// keccak256('LSP1UniversalReceiverDelegate')
bytes32 constant _LSP1_UNIVERSAL_RECEIVER_DELEGATE_KEY = 0x0cfc51aec37c55a4d0b1a65c6255c4bf2fbdf6277f3cc0730c45b828b6db8b47;

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// constants
import "./constants.sol";

// interfaces
import "./interfaces/IERC725Y.sol";

// modules
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "./utils/OwnableUnset.sol";

// libraries
import "./utils/GasLib.sol";

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

        for (uint256 i = 0; i < keys.length; i = GasLib.unchecked_inc(i)) {
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
        for (uint256 i = 0; i < _keys.length; i = GasLib.unchecked_inc(i)) {
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 * @dev Library to add all efficient functions that could get repeated.
 */
library GasLib {
    /**
     * @dev Will return unchecked incremented uint256
     */
    function unchecked_inc(uint256 i) internal pure returns (uint256) {
        unchecked {
            return i + 1;
        }
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

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/**
 * FANZONE.io NFT implementation of the LUKSO LSP-8-IdentifiableDigitalAsset standard
 * for more see https://fanzone.io/nfts
 */

interface IUsesContractRegistry {
    function contractRegistry() external view returns (address);
}