// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ISwap } from "./Interfaces/ISwap.sol";
import { IVault } from "./Interfaces/IVault.sol";
import { IStorageRegistry } from "./Interfaces/IStorageRegistry.sol";
import { ISigningUtils } from "./Interfaces/lib/ISigningUtils.sol";
import { ValidationUtils } from "./lib/ValidationUtils.sol";
import "../utils/DataTypes.sol";

/// @title NF3 Swap
/// @author NF3 Exchange
/// @notice This contract inherits from ISwap interface.
/// @dev Functions in this contract are not public callable. They can only be called through the public facing contract(NF3Proxy).
/// @dev This contract has the functions related to all types of swaps.

contract Swap is ISwap, Ownable {
    /// -----------------------------------------------------------------------
    /// Library Usage
    /// -----------------------------------------------------------------------

    using ValidationUtils for *;

    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    /// @notice Storage registry contract address
    address public storageRegistryAddress;

    /// -----------------------------------------------------------------------
    /// Modifiers
    /// -----------------------------------------------------------------------

    modifier onlyMarket() {
        _onlyMarket();
        _;
    }

    /// -----------------------------------------------------------------------
    /// Cancel Actions
    /// -----------------------------------------------------------------------

    /// @notice Inherit from ISwap
    function cancelListing(
        Listing calldata _listing,
        bytes memory _signature,
        address _user
    ) external override onlyMarket {
        address _storageRegistryAddress = storageRegistryAddress;

        // Verify signature.
        ISigningUtils(_signingUtilsAddress(_storageRegistryAddress))
            .verifyListingSignature(_listing, _signature);

        // Should be called by the listing owner.
        _listing.owner.itemOwnerOnly(_user);

        _checkNonce(_listing.owner, _listing.nonce, _storageRegistryAddress);

        _setNonce(_listing.owner, _listing.nonce, _storageRegistryAddress);

        emit ListingCancelled(_listing);
    }

    /// @notice Inherit from ISwap
    function cancelSwapOffer(
        SwapOffer calldata _offer,
        bytes memory _signature,
        address _user
    ) external override onlyMarket {
        address _storageRegistryAddress = storageRegistryAddress;

        // Verify signature.
        ISigningUtils(_signingUtilsAddress(_storageRegistryAddress))
            .verifySwapOfferSignature(_offer, _signature);

        // Should be called by the offer owner.
        _offer.owner.itemOwnerOnly(_user);

        _checkNonce(_offer.owner, _offer.nonce, _storageRegistryAddress);

        _setNonce(_offer.owner, _offer.nonce, _storageRegistryAddress);

        emit SwapOfferCancelled(_offer);
    }

    /// @notice Inherit from ISwap
    function cancelCollectionSwapOffer(
        CollectionSwapOffer calldata _offer,
        bytes memory _signature,
        address _user
    ) external override onlyMarket {
        address _storageRegistryAddress = storageRegistryAddress;

        // Verify signature.
        ISigningUtils(_signingUtilsAddress(_storageRegistryAddress))
            .verifyCollectionSwapOfferSignature(_offer, _signature);

        // Should be called by the offer owner.
        _offer.owner.itemOwnerOnly(_user);

        _checkNonce(_offer.owner, _offer.nonce, _storageRegistryAddress);

        _setNonce(_offer.owner, _offer.nonce, _storageRegistryAddress);

        emit CollectionSwapOfferCancelled(_offer);
    }

    /// -----------------------------------------------------------------------
    /// Swap Actions
    /// -----------------------------------------------------------------------

    /// @notice Inherit from ISwap
    function directSwap(
        Listing calldata _listing,
        bytes memory _signature,
        uint256 _swapId,
        address _user,
        SwapParams memory swapParams,
        uint256 _value,
        Royalty calldata _royalty,
        Fees calldata sellerFees,
        Fees calldata buyerFees
    ) external override onlyMarket {
        address _storageRegistryAddress = storageRegistryAddress;

        {
            // Verify signature, nonce and expiration.
            ISigningUtils(_signingUtilsAddress(_storageRegistryAddress))
                .verifyListingSignature(_listing, _signature);

            _checkNonce(
                _listing.owner,
                _listing.nonce,
                _storageRegistryAddress
            );

            checkExpiration(_listing.timePeriod);

            // check if called by eligible contract
            address intendedFor = _listing.tradeIntendedFor;
            if (!(intendedFor == address(0) || intendedFor == _user)) {
                revert SwapError(
                    SwapErrorCodes.INTENDED_FOR_PEER_TO_PEER_TRADE
                );
            }

            // Seller should not buy his own listing.
            _listing.owner.notItemOwner(_user);
        }

        // Verify swap option with swapId exist.
        SwapAssets memory swapAssets = swapExists(
            _listing.directSwaps,
            _swapId
        );

        // Verfy incoming assets to be the same.
        Assets memory offeredAssets = swapAssets.verifySwapAssets(
            swapParams.tokens,
            swapParams.tokenIds,
            swapParams.proofs,
            _value
        );
        // to prevent stack too deep
        Listing calldata listing = _listing;

        {
            address vaultAddress = _vaultAddress(_storageRegistryAddress);

            // Exchange the assets.
            IVault(vaultAddress).transferAssets(
                listing.listingAssets,
                listing.owner,
                _user,
                _royalty,
                false
            );

            IVault(vaultAddress).transferAssets(
                offeredAssets,
                _user,
                listing.owner,
                listing.royalty,
                true
            );

            // transfer fees
            IVault(vaultAddress).transferFees(
                sellerFees,
                listing.owner,
                buyerFees,
                _user
            );
        }

        // Update the nonce.
        _setNonce(listing.owner, listing.nonce, _storageRegistryAddress);

        emit DirectSwapped(listing, offeredAssets, _swapId, _user);
    }

    /// @notice Inherit from ISwap
    function acceptUnlistedDirectSwapOffer(
        SwapOffer calldata _offer,
        bytes memory _signature,
        Assets calldata _consideration,
        bytes32[] calldata _proof,
        address _user,
        uint256 _value,
        Royalty calldata _royalty,
        Fees calldata sellerFees,
        Fees calldata buyerFees
    ) external override onlyMarket {
        address _storageRegistryAddress = storageRegistryAddress;

        {
            // Verify signature, nonce and expiration.
            ISigningUtils(_signingUtilsAddress(_storageRegistryAddress))
                .verifySwapOfferSignature(_offer, _signature);

            _checkNonce(_offer.owner, _offer.nonce, _storageRegistryAddress);

            checkExpiration(_offer.timePeriod);

            // Seller should not accept his own offer.
            _offer.owner.notItemOwner(_user);

            // Verify incomming assets to be present in the merkle root.
            _offer.considerationRoot.verifyAssetProof(_consideration, _proof);

            // Check if enough eth amount is sent.
            _consideration.checkEthAmount(_value);
        }

        // to prevent stack too deep
        SwapOffer calldata offer = _offer;

        {
            address vaultAddress = _vaultAddress(_storageRegistryAddress);

            // Exchange the assets.
            IVault(vaultAddress).transferAssets(
                offer.offeringItems,
                offer.owner,
                _user,
                _royalty,
                false
            );

            IVault(vaultAddress).transferAssets(
                _consideration,
                _user,
                offer.owner,
                offer.royalty,
                true
            );

            // transfer fees
            IVault(vaultAddress).transferFees(
                sellerFees,
                _user,
                buyerFees,
                offer.owner
            );
        }

        // Update the nonce.
        _setNonce(offer.owner, offer.nonce, _storageRegistryAddress);

        emit UnlistedSwapOfferAccepted(offer, _consideration, _user);
    }

    /// @notice Inherit from ISwap
    function acceptListedDirectSwapOffer(
        Listing calldata _listing,
        bytes memory _listingSignature,
        SwapOffer calldata _offer,
        bytes memory _offerSignature,
        bytes32[] calldata _proof,
        address _user,
        Fees calldata sellerFees,
        Fees calldata buyerFees
    ) external override onlyMarket {
        address _storageRegistryAddress = storageRegistryAddress;

        {
            address __signingUtilsAddress = _signingUtilsAddress(
                _storageRegistryAddress
            );

            // Verify listing signature, nonce and expiration.
            ISigningUtils(__signingUtilsAddress).verifyListingSignature(
                _listing,
                _listingSignature
            );

            _checkNonce(
                _listing.owner,
                _listing.nonce,
                _storageRegistryAddress
            );

            checkExpiration(_listing.timePeriod);

            // Verify offer signature, nonce and expiration.
            ISigningUtils(__signingUtilsAddress).verifySwapOfferSignature(
                _offer,
                _offerSignature
            );

            _checkNonce(_offer.owner, _offer.nonce, _storageRegistryAddress);

            checkExpiration(_offer.timePeriod);

            // Should be called by listing owner.
            _listing.owner.itemOwnerOnly(_user);

            // Should not be called by the offer owner.
            _offer.owner.notItemOwner(_user);

            // Verify lisitng assets to be present in the offer's merkle root.
            _offer.considerationRoot.verifyAssetProof(
                _listing.listingAssets,
                _proof
            );
        }
        {
            address vaultAddress = _vaultAddress(_storageRegistryAddress);
            // Exchange the assets.
            IVault(vaultAddress).transferAssets(
                _listing.listingAssets,
                _listing.owner,
                _offer.owner,
                _offer.royalty,
                false
            );
            IVault(vaultAddress).transferAssets(
                _offer.offeringItems,
                _offer.owner,
                _listing.owner,
                _listing.royalty,
                false
            );

            // transfer fees
            IVault(vaultAddress).transferFees(
                sellerFees,
                _listing.owner,
                buyerFees,
                _offer.owner
            );
        }

        // Update the nonce.
        _setNonce(_listing.owner, _listing.nonce, _storageRegistryAddress);
        _setNonce(_offer.owner, _offer.nonce, _storageRegistryAddress);

        emit ListedSwapOfferAccepted(_listing, _offer, _user);
    }

    /// @notice Inherit from ISwap
    function acceptCollectionSwapOffer(
        CollectionSwapOffer calldata _offer,
        bytes memory _signature,
        SwapParams memory swapParams,
        address _user,
        uint256 _value,
        Royalty calldata _royalty,
        Fees calldata sellerFees,
        Fees calldata buyerFees
    ) external override onlyMarket {
        address _storageRegistryAddress = storageRegistryAddress;
        {
            // Verify signature, nonce and expiration.
            ISigningUtils(_signingUtilsAddress(_storageRegistryAddress))
                .verifyCollectionSwapOfferSignature(_offer, _signature);

            _checkNonce(_offer.owner, _offer.nonce, _storageRegistryAddress);

            checkExpiration(_offer.timePeriod);

            // Seller must not be offer owner.
            _offer.owner.notItemOwner(_user);
        }

        // Verify incomming assets to be the same as consideration items.
        Assets memory offeredAssets = _offer
            .considerationItems
            .verifySwapAssets(
                swapParams.tokens,
                swapParams.tokenIds,
                swapParams.proofs,
                _value
            );

        {
            address vaultAddress = _vaultAddress(_storageRegistryAddress);

            // Exchange the assets.
            IVault(vaultAddress).transferAssets(
                _offer.offeringItems,
                _offer.owner,
                _user,
                _royalty,
                false
            );
            IVault(vaultAddress).transferAssets(
                offeredAssets,
                _user,
                _offer.owner,
                _offer.royalty,
                true
            );

            // transfer fees
            IVault(vaultAddress).transferFees(
                sellerFees,
                _user,
                buyerFees,
                _offer.owner
            );
        }

        // Update the nonce.
        _setNonce(_offer.owner, _offer.nonce, _storageRegistryAddress);
        emit CollectionSwapOfferAccepted(_offer, offeredAssets, _user);
    }

    /// -----------------------------------------------------------------------
    /// Owner actions
    /// -----------------------------------------------------------------------

    /// @notice Inherit from ISwap
    function setStorageRegistry(address _storageRegistryAddress)
        external
        override
        onlyOwner
    {
        if (_storageRegistryAddress == address(0)) {
            revert SwapError(SwapErrorCodes.INVALID_ADDRESS);
        }

        emit StorageRegistrySet(
            _storageRegistryAddress,
            storageRegistryAddress
        );

        storageRegistryAddress = _storageRegistryAddress;
    }

    /// -----------------------------------------------------------------------
    /// Internal functions
    /// -----------------------------------------------------------------------

    /// @dev Check if the give nonce is valid or not
    /// @param _user address of the user
    /// @param _nonce actual nonce to check
    /// @param _storageRegistryAddress memoized storage registry address
    function _checkNonce(
        address _user,
        uint256 _nonce,
        address _storageRegistryAddress
    ) internal view {
        IStorageRegistry(_storageRegistryAddress).checkNonce(_user, _nonce);
    }

    /// @dev Set the given nonce as used
    /// @param _user address of the user
    /// @param _nonce actual nonce to set
    /// @param _storageRegistryAddress memoized storage registry address
    function _setNonce(
        address _user,
        uint256 _nonce,
        address _storageRegistryAddress
    ) internal {
        IStorageRegistry(_storageRegistryAddress).setNonce(_user, _nonce);
    }

    /// @dev Check if the swap option with given swap id exist or not.
    /// @param _swaps All the swap options
    /// @param _swapId Swap id to be checked
    /// @return swap Swap assets at given index
    function swapExists(SwapAssets[] calldata _swaps, uint256 _swapId)
        internal
        pure
        returns (SwapAssets calldata)
    {
        if (_swaps.length <= _swapId) {
            revert SwapError(SwapErrorCodes.OPTION_DOES_NOT_EXIST);
        }
        return _swaps[_swapId];
    }

    /// @dev Check if the item has expired.
    /// @param _timePeriod Expiration time
    function checkExpiration(uint256 _timePeriod) internal view {
        if (_timePeriod < block.timestamp) {
            revert SwapError(SwapErrorCodes.ITEM_EXPIRED);
        }
    }

    /// @dev internal function to check if the caller is market or not
    function _onlyMarket() internal view {
        address marketAddress = IStorageRegistry(storageRegistryAddress)
            .marketAddress();
        if (msg.sender != marketAddress) {
            revert SwapError(SwapErrorCodes.NOT_MARKET);
        }
    }

    /// @dev internal function to get vault address from storage registry contract
    /// @param _storageRegistryAddress  memoized storage registry address
    function _vaultAddress(address _storageRegistryAddress)
        internal
        view
        returns (address)
    {
        return IStorageRegistry(_storageRegistryAddress).vaultAddress();
    }

    /// @dev internal function to get signing utils library address from storage registry
    /// @param _storageRegistryAddress memoized storage registry address
    function _signingUtilsAddress(address _storageRegistryAddress)
        internal
        view
        returns (address)
    {
        return IStorageRegistry(_storageRegistryAddress).signingUtilsAddress();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../../utils/DataTypes.sol";

/// @title NF3 Swap Interface
/// @author NF3 Exchange
/// @dev This interface defines all the functions related to swap features of the platform.

interface ISwap {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    enum SwapErrorCodes {
        NOT_MARKET,
        INTENDED_FOR_PEER_TO_PEER_TRADE,
        INVALID_ADDRESS,
        OPTION_DOES_NOT_EXIST,
        ITEM_EXPIRED
    }

    error SwapError(SwapErrorCodes code);

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /// @dev Emits when listing has cancelled.
    /// @param listing Listing assets, details and seller's info
    event ListingCancelled(Listing listing);

    /// @dev Emits when swap offer has cancelled.
    /// @param offer Offer information
    event SwapOfferCancelled(SwapOffer offer);

    /// @dev Emits when collection offer has cancelled.
    /// @param offer Offer information
    event CollectionSwapOfferCancelled(CollectionSwapOffer offer);

    /// @dev Emits when direct swap has happened.
    /// @param listing Listing assets, details and seller's info
    /// @param offeredAssets Assets offered by the buyer
    /// @param swapId Swap id
    /// @param user Address of the buyer
    event DirectSwapped(
        Listing listing,
        Assets offeredAssets,
        uint256 swapId,
        address indexed user
    );

    /// @dev Emits when swap offer has been accepted by the user.
    /// @param offer Swap offer assets and details
    /// @param considerationItems Assets given by the user
    /// @param user Address of the user who accepted the offer
    event UnlistedSwapOfferAccepted(
        SwapOffer offer,
        Assets considerationItems,
        address indexed user
    );

    /// @dev Emits when swap offer has been accepted by a listing owner.
    /// @param listing Listing assets info
    /// @param offer Swap offer info
    /// @param user Listing owner
    event ListedSwapOfferAccepted(
        Listing listing,
        SwapOffer offer,
        address indexed user
    );

    /// @dev Emits when collection swap offer has accepted by the seller.
    /// @param offer Collection offer assets and details
    /// @param considerationItems Assets given by the seller
    /// @param user Address of the buyer
    event CollectionSwapOfferAccepted(
        CollectionSwapOffer offer,
        Assets considerationItems,
        address indexed user
    );

    /// @dev Emits when new storage registry address has set.
    /// @param oldStorageRegistry Previous market contract address
    /// @param newStorageRegistry New market contract address
    event StorageRegistrySet(
        address oldStorageRegistry,
        address newStorageRegistry
    );

    /// -----------------------------------------------------------------------
    /// Cancel Actions
    /// -----------------------------------------------------------------------

    /// @dev Cancel listing.
    /// @param listing Listing parameters
    /// @param signature Signature of the listing parameters
    /// @param user Listing owner
    function cancelListing(
        Listing calldata listing,
        bytes memory signature,
        address user
    ) external;

    /// @dev Cancel Swap offer.
    /// @param offer Collection offer patameter
    /// @param signature Signature of the offer patameters
    /// @param user Collection offer owner
    function cancelSwapOffer(
        SwapOffer calldata offer,
        bytes memory signature,
        address user
    ) external;

    /// @dev Cancel collection level offer.
    /// @param offer Collection offer patameter
    /// @param signature Signature of the offer patameters
    /// @param user Collection offer owner
    function cancelCollectionSwapOffer(
        CollectionSwapOffer calldata offer,
        bytes memory signature,
        address user
    ) external;

    /// -----------------------------------------------------------------------
    /// Swap Actions
    /// -----------------------------------------------------------------------

    /// @dev Direct swap of bundle of NFTs + FTs with other bundles.
    /// @param listing Listing assets and details
    /// @param signature Signature as a proof of listing
    /// @param swapId Index of swap option being used
    /// @param value Eth value sent in the function call
    /// @param royalty Buyer's royalty info
    function directSwap(
        Listing calldata listing,
        bytes memory signature,
        uint256 swapId,
        address user,
        SwapParams memory swapParams,
        uint256 value,
        Royalty calldata royalty,
        Fees calldata sellerFees,
        Fees calldata buyerFees
    ) external;

    /// @dev Accpet unlisted direct swap offer.
    /// @dev User should see the swap offer and accpet that offer.
    /// @param offer Multi offer assets and details
    /// @param signature Signature as a proof of offer
    /// @param consideration Consideration assets been provided by the user
    /// @param proof Merkle proof that the considerationItems is valid
    /// @param user Address of the user who accepted this offer
    /// @param royalty Seller's royalty info
    function acceptUnlistedDirectSwapOffer(
        SwapOffer calldata offer,
        bytes memory signature,
        Assets calldata consideration,
        bytes32[] calldata proof,
        address user,
        uint256 value,
        Royalty calldata royalty,
        Fees calldata sellerFees,
        Fees calldata buyerFees
    ) external;

    /// @dev Accept listed direct swap offer.
    /// @dev Only listing owner should accept that offer.
    /// @param listing Listing assets and parameters
    /// @param listingSignature Signature as a proof of listing
    /// @param offer Offering assets and parameters
    /// @param offerSignature Signature as a proof of offer
    /// @param proof Mekrle proof that the listed assets are valid
    /// @param user Listing owner
    function acceptListedDirectSwapOffer(
        Listing calldata listing,
        bytes memory listingSignature,
        SwapOffer calldata offer,
        bytes memory offerSignature,
        bytes32[] calldata proof,
        address user,
        Fees calldata sellerFees,
        Fees calldata buyerFees
    ) external;

    /// @dev Accept collection offer.
    /// @dev Anyone who holds the consideration assets can accpet this offer.
    /// @param offer Collection offer assets and details
    /// @param signature Signature as a proof of offer
    /// @param user Seller address
    /// @param value Eth value send in the function call
    /// @param royalty Seller's royalty info
    function acceptCollectionSwapOffer(
        CollectionSwapOffer memory offer,
        bytes memory signature,
        SwapParams memory swapParams,
        address user,
        uint256 value,
        Royalty calldata royalty,
        Fees calldata sellerFees,
        Fees calldata buyerFees
    ) external;

    /// -----------------------------------------------------------------------
    /// Owner actions
    /// -----------------------------------------------------------------------

    /// @dev Set Storage registry contract address.
    /// @param _storageRegistryAddress storage registry contract address
    function setStorageRegistry(address _storageRegistryAddress) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../../utils/DataTypes.sol";

/// @title NF3 Vault Interface
/// @author NF3 Exchange
/// @dev This interface defines all the functions related to assets transfer and assets escrow.

interface IVault {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    enum VaultErrorCodes {
        CALLER_NOT_APPROVED,
        FAILED_TO_SEND_ETH,
        ETH_NOT_ALLOWED,
        INVALID_ASSET_TYPE,
        COULD_NOT_RECEIVE_KITTY,
        COULD_NOT_SEND_KITTY,
        INVALID_PUNK,
        COULD_NOT_RECEIVE_PUNK,
        COULD_NOT_SEND_PUNK,
        INVALID_ADDRESS,
        COULD_NOT_TRANSFER_SELLER_FEES,
        COULD_NOT_TRANSFER_BUYER_FEES
    }

    error VaultError(VaultErrorCodes code);

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /// @dev Emits when the assets have transferred.
    /// @param assets Assets
    /// @param from Sender address
    /// @param to Receiver address
    event AssetsTransferred(Assets assets, address from, address to);

    /// @dev Emits when the assets have been received by the vault.
    /// @param assets Assets
    /// @param from Sender address
    event AssetsReceived(Assets assets, address from);

    /// @dev Emits when the assets have been sent by the vault.
    /// @param assets Assets
    /// @param to Receiver address
    event AssetsSent(Assets assets, address to);

    /// @dev Emits when new storage registry address has set.
    /// @param oldStorageRegistryAddress Previous storage registry contract address
    /// @param newStorageRegistryAddress New storage registry contract address
    event StorageRegistrySet(
        address oldStorageRegistryAddress,
        address newStorageRegistryAddress
    );

    /// @dev Emits when fee is paid in a trade or reservation
    /// @param sellerFee Fee paid from seller's end
    /// @param seller address of the seller
    /// @param buyerFee Fee paid from buyer's end
    /// @param buyer address of the buyer
    event FeesPaid(
        Fees sellerFee,
        address seller,
        Fees buyerFee,
        address buyer
    );

    /// -----------------------------------------------------------------------
    /// Transfer actions
    /// -----------------------------------------------------------------------

    /// @dev Transfer the assets "assets" from "from" to "to".
    /// @param assets Assets to be transfered
    /// @param from Sender address
    /// @param to Receiver address
    /// @param royalty Royalty info
    /// @param allowEth Bool variable if can send ETH or not
    function transferAssets(
        Assets calldata assets,
        address from,
        address to,
        Royalty calldata royalty,
        bool allowEth
    ) external;

    /// @dev Receive assets "assets" from "from" address to the vault
    /// @param assets Assets to be transfered
    /// @param from Sender address
    function receiveAssets(
        Assets calldata assets,
        address from,
        bool allowEth
    ) external;

    /// @dev Send assets "assets" from the vault to "_to" address
    /// @param assets Assets to be transfered
    /// @param to Receiver address
    /// @param royalty Royalty info
    function sendAssets(
        Assets calldata assets,
        address to,
        Royalty calldata royalty,
        bool allowEth
    ) external;

    /// @dev Transfer fees from seller and buyer to the mentioned addresses
    /// @param sellerFees Fees to be taken from the seller
    /// @param buyerFees Fees to be taken from the buyer
    /// @param seller Seller's address
    /// @param buyer Buyer's address
    function transferFees(
        Fees calldata sellerFees,
        address seller,
        Fees calldata buyerFees,
        address buyer
    ) external;

    /// -----------------------------------------------------------------------
    /// Owner actions
    /// -----------------------------------------------------------------------

    /// @dev Set Storage registry contract address
    /// @param _storageRegistryAddress storage registry contract address
    function setStorageRegistry(address _storageRegistryAddress) external;

    /// @dev Set upper limit for fee that can be deducted
    /// @param tokens Addresses of payment tokens for fees
    /// @param caps Upper limit for payment tokens respectively
    function setFeeCap(address[] memory tokens, uint256[] memory caps) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

/// @title NF3 Storage Registry Interface
/// @author NF3 Exchange
/// @dev This interface defines all the functions related to storage for the protocol.

interface IStorageRegistry {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------
    enum StorageRegistryErrorCodes {
        INVALID_NONCE,
        CALLER_NOT_APPROVED,
        INVALID_ADDRESS
    }

    error StorageRegistryError(StorageRegistryErrorCodes code);

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /// @dev Emits when status has changed.
    /// @param owner user whose nonce is updated
    /// @param nonce value of updated nonce
    event NonceSet(address owner, uint256 nonce);

    /// @dev Emits when new market address has set.
    /// @param oldMarketAddress Previous market contract address
    /// @param newMarketAddress New market contract address
    event MarketSet(address oldMarketAddress, address newMarketAddress);

    /// @dev Emits when new reserve address has set.
    /// @param oldVaultAddress Previous vault contract address
    /// @param newVaultAddress New vault contract address
    event VaultSet(address oldVaultAddress, address newVaultAddress);

    /// @dev Emits when new reserve address has set.
    /// @param oldReserveAddress Previous reserve contract address
    /// @param newReserveAddress New reserve contract address
    event ReserveSet(address oldReserveAddress, address newReserveAddress);

    /// @dev Emits when new whitelist contract address has set
    /// @param oldWhitelistAddress Previous whitelist contract address
    /// @param newWhitelistAddress New whitelist contract address
    event WhitelistSet(
        address oldWhitelistAddress,
        address newWhitelistAddress
    );

    /// @dev Emits when new swap address has set.
    /// @param oldSwapAddress Previous swap contract address
    /// @param newSwapAddress New swap contract address
    event SwapSet(address oldSwapAddress, address newSwapAddress);

    /// @dev Emits when new loan contract address has set
    /// @param oldLoanAddress Previous loan contract address
    /// @param newLoanAddress New whitelist contract address
    event LoanSet(address oldLoanAddress, address newLoanAddress);

    /// @dev Emits when airdrop claim implementation address is set
    /// @param oldAirdropClaimImplementation Previous air drop claim implementation address
    /// @param newAirdropClaimImplementation New air drop claim implementation address
    event AirdropClaimImplementationSet(
        address oldAirdropClaimImplementation,
        address newAirdropClaimImplementation
    );

    /// @dev Emits when signing utils library address is set
    /// @param oldSigningUtilsAddress Previous air drop claim implementation address
    /// @param newSigningUtilsAddress New air drop claim implementation address
    event SigningUtilSet(
        address oldSigningUtilsAddress,
        address newSigningUtilsAddress
    );

    /// @dev Emits when new position token address has set.
    /// @param oldPositionTokenAddress Previous position token contract address
    /// @param newPositionTokenAddress New position token contract address
    event PositionTokenSet(
        address oldPositionTokenAddress,
        address newPositionTokenAddress
    );

    /// -----------------------------------------------------------------------
    /// Nonce actions
    /// -----------------------------------------------------------------------

    /// @dev Get the value of nonce without reverting.
    /// @param owner Owner address
    /// @param _nonce Nonce value
    function getNonce(address owner, uint256 _nonce)
        external
        view
        returns (bool);

    /// @dev Check if the nonce is in correct status.
    /// @param owner Owner address
    /// @param _nonce Nonce value
    function checkNonce(address owner, uint256 _nonce) external view;

    /// @dev Set the nonce value of a user. Can only be called by reserve contract.
    /// @param owner Address of the user
    /// @param _nonce Nonce value of the user
    function setNonce(address owner, uint256 _nonce) external;

    /// -----------------------------------------------------------------------
    /// Owner actions
    /// -----------------------------------------------------------------------

    /// @dev Set Market contract address.
    /// @param _marketAddress Market contract address
    function setMarket(address _marketAddress) external;

    /// @dev Set Vault contract address.
    /// @param _vaultAddress Vault contract address
    function setVault(address _vaultAddress) external;

    /// @dev Set Reserve contract address.
    /// @param _reserveAddress Reserve contract address
    function setReserve(address _reserveAddress) external;

    /// @dev Set Whitelist contract address.
    /// @param _whitelistAddress contract address
    function setWhitelist(address _whitelistAddress) external;

    /// @dev Set Swap contract address.
    /// @param _swapAddress Swap contract address
    function setSwap(address _swapAddress) external;

    /// @dev Set Loan contract address
    /// @param _loanAddress Whitelist contract address
    function setLoan(address _loanAddress) external;

    /// @dev Set Signing Utils library address
    /// @param _signingUtilsAddress signing utils contract address
    function setSigningUtil(address _signingUtilsAddress) external;

    /// @dev Set air drop claim contract implementation address
    /// @param _airdropClaimImplementation Airdrop claim contract address
    function setAirdropClaimImplementation(address _airdropClaimImplementation)
        external;

    /// @dev Set position token contract address
    /// @param _positionTokenAddress position token contract address
    function setPositionToken(address _positionTokenAddress) external;

    /// @dev Whitelist airdrop contract that can be called for the user
    /// @param _contract address of the airdrop contract
    /// @param _allow bool value for the whitelist
    function setAirdropWhitelist(address _contract, bool _allow) external;

    /// @notice Set claim contract address for position token
    /// @param _tokenId Token id for which the claim contract is deployed
    /// @param _claimContract address of the claim contract
    function setClaimContractAddresses(uint256 _tokenId, address _claimContract)
        external;

    /// -----------------------------------------------------------------------
    /// Public Getter Functions
    /// -----------------------------------------------------------------------

    /// @dev Get whitelist contract address
    function whitelistAddress() external view returns (address);

    /// @dev Get vault contract address
    function vaultAddress() external view returns (address);

    /// @dev Get swap contract address
    function swapAddress() external view returns (address);

    /// @dev Get reserve contract address
    function reserveAddress() external view returns (address);

    /// @dev Get market contract address
    function marketAddress() external view returns (address);

    /// @dev Get loan contract address
    function loanAddress() external view returns (address);

    /// @dev Get airdropClaim contract address
    function airdropClaimImplementation() external view returns (address);

    /// @dev Get signing utils contract address
    function signingUtilsAddress() external view returns (address);

    /// @dev Get position token contract address
    function positionTokenAddress() external view returns (address);

    /// @dev Get claim contract address
    function claimContractAddresses(uint256 _tokenId)
        external
        view
        returns (address);

    /// @dev Get whitelist of an airdrop contract
    function airdropWhitelist(address _contract) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../../../utils/DataTypes.sol";
import "../../../utils/LoanDataTypes.sol";

interface ISigningUtils {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    enum SigningUtilsErrorCodes {
        INVALID_LISTING_SIGNATURE,
        INVALID_SWAP_OFFER_SIGNATURE,
        INVALID_COLLECTION_SWAP_OFFER_SIGNATURE,
        INVALID_RESERVE_OFFER_SIGNATURE,
        INVALID_COLLECTION_RESERVE_OFFER_SIGNATURE,
        INVALID_LOAN_OFFER_SIGNATURE,
        INVALID_COLLECTION_LOAN_OFFER_SIGNATURE,
        INVALID_UPDATE_LOAN_OFFER_SIGNATURE
    }

    error SigningUtilsError(SigningUtilsErrorCodes code);

    /// -----------------------------------------------------------------------
    /// Signature Verification Actions
    /// -----------------------------------------------------------------------

    /// @dev Check the signature if the listing info is valid or not.
    /// @param _listing Listing info
    /// @param signature Listing signature
    function verifyListingSignature(
        Listing calldata _listing,
        bytes calldata signature
    ) external view;

    /// @dev Check the signature if the swap offer is valid or not.
    /// @param offer Offer info
    /// @param signature Offer signature
    function verifySwapOfferSignature(
        SwapOffer calldata offer,
        bytes calldata signature
    ) external view;

    /// @dev Check the signature if the collection offer is valid or not.
    /// @param offer Offer info
    /// @param signature Offer signature
    function verifyCollectionSwapOfferSignature(
        CollectionSwapOffer calldata offer,
        bytes calldata signature
    ) external view;

    /// @dev Check the signature if the reserve offer is valid or not.
    /// @param offer Reserve offer info
    /// @param signature Reserve offer signature
    function verifyReserveOfferSignature(
        ReserveOffer calldata offer,
        bytes calldata signature
    ) external view;

    /// @dev Check the signature if the collection reserve offer is valid or not.
    /// @param offer Reserve offer info
    /// @param signature Reserve offer signature
    function verifyCollectionReserveOfferSignature(
        CollectionReserveOffer calldata offer,
        bytes calldata signature
    ) external view;

    /// @dev Check the signature if the loan offer is valid or not.
    /// @param offer Loan offer info
    /// @param signature Loan offer signature
    function verifyLoanOfferSignature(
        LoanOffer calldata offer,
        bytes memory signature
    ) external view;

    /// @dev Check the signature if the collection loan offer is valid or not.
    /// @param offer Collection loan offer info
    /// @param signature Collection loan offer signature
    function verifyCollectionLoanOfferSignature(
        CollectionLoanOffer calldata offer,
        bytes memory signature
    ) external view;

    /// @dev Check the signature if the update loan offer is valid or not.
    /// @param offer Update loan offer info
    /// @param signature Update loan offer signature
    function verifyUpdateLoanSignature(
        LoanUpdateOffer calldata offer,
        bytes memory signature
    ) external view;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../../utils/DataTypes.sol";
import "../../utils/LoanDataTypes.sol";

/// @title NF3 Validation Utils
/// @author NF3 Exchange
/// @dev  Helper library for Protocol. This contract manages validation checks
///       commonly required throughout the protocol

library ValidationUtils {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    enum ValidationUtilsErrorCodes {
        INVALID_ITEMS,
        ONLY_OWNER,
        OWNER_NOT_ALLOWED
    }

    error ValidationUtilsError(ValidationUtilsErrorCodes code);

    /// -----------------------------------------------------------------------
    /// Asset Validation Actions
    /// -----------------------------------------------------------------------

    /// @dev Verify assets1 and assets2 if they are the same.
    /// @param _assets1 First assets
    /// @param _assets2 Second assets
    function verifyAssets(Assets calldata _assets1, Assets calldata _assets2)
        internal
        pure
    {
        if (
            _assets1.paymentTokens.length != _assets2.paymentTokens.length ||
            _assets1.tokens.length != _assets2.tokens.length
        ) revert ValidationUtilsError(ValidationUtilsErrorCodes.INVALID_ITEMS);

        unchecked {
            uint256 i;
            for (i = 0; i < _assets1.paymentTokens.length; i++) {
                if (
                    _assets1.paymentTokens[i] != _assets2.paymentTokens[i] ||
                    _assets1.amounts[i] != _assets2.amounts[i]
                )
                    revert ValidationUtilsError(
                        ValidationUtilsErrorCodes.INVALID_ITEMS
                    );
            }

            for (i = 0; i < _assets1.tokens.length; i++) {
                if (
                    _assets1.tokens[i] != _assets2.tokens[i] ||
                    _assets1.tokenIds[i] != _assets2.tokenIds[i]
                )
                    revert ValidationUtilsError(
                        ValidationUtilsErrorCodes.INVALID_ITEMS
                    );
            }
        }
    }

    /// @dev Verify swap assets to be satisfied as the consideration items by the seller.
    /// @param _swapAssets Swap assets
    /// @param _tokens NFT addresses
    /// @param _tokenIds NFT token ids
    /// @param _value Eth value
    /// @return assets Verified swap assets
    function verifySwapAssets(
        SwapAssets memory _swapAssets,
        address[] memory _tokens,
        uint256[] memory _tokenIds,
        bytes32[][] memory _proofs,
        uint256 _value
    ) internal pure returns (Assets memory) {
        // check Eth amounts
        checkEthAmount(
            Assets({
                tokens: new address[](0),
                tokenIds: new uint256[](0),
                paymentTokens: _swapAssets.paymentTokens,
                amounts: _swapAssets.amounts
            }),
            _value
        );

        uint256 i;
        unchecked {
            // check compatible NFTs
            for (i = 0; i < _swapAssets.tokens.length; i++) {
                if (
                    _swapAssets.tokens[i] != _tokens[i] ||
                    (!verifyMerkleProof(
                        _swapAssets.roots[i],
                        _proofs[i],
                        keccak256(abi.encodePacked(_tokenIds[i]))
                    ) && _swapAssets.roots[i] != bytes32(0))
                ) {
                    revert ValidationUtilsError(
                        ValidationUtilsErrorCodes.INVALID_ITEMS
                    );
                }
            }
        }

        return
            Assets(
                _tokens,
                _tokenIds,
                _swapAssets.paymentTokens,
                _swapAssets.amounts
            );
    }

    /// @dev Verify if the passed asset is present in the merkle root passed.
    /// @param _root Merkle root to check in
    /// @param _consideration Consideration assets
    /// @param _proof Merkle proof
    function verifyAssetProof(
        bytes32 _root,
        Assets calldata _consideration,
        bytes32[] calldata _proof
    ) internal pure {
        bytes32 _leaf = hashAssets(_consideration, bytes32(0));

        if (!verifyMerkleProof(_root, _proof, _leaf)) {
            revert ValidationUtilsError(
                ValidationUtilsErrorCodes.INVALID_ITEMS
            );
        }
    }

    /// @dev Check if the ETH amount is valid.
    /// @param _assets Assets
    /// @param _value ETH amount
    function checkEthAmount(Assets memory _assets, uint256 _value)
        internal
        pure
    {
        uint256 ethAmount;

        for (uint256 i = 0; i < _assets.paymentTokens.length; ) {
            if (_assets.paymentTokens[i] == address(0))
                ethAmount += _assets.amounts[i];
            unchecked {
                ++i;
            }
        }
        if (ethAmount > _value) {
            revert ValidationUtilsError(
                ValidationUtilsErrorCodes.INVALID_ITEMS
            );
        }
    }

    /// @dev Verify that the given leaf exist in the passed root and has the correct proof.
    /// @param _root Merkle root of the given criterial
    /// @param _proof Merkle proof of the given leaf and root
    /// @param _leaf Hash of the token id to be searched in the root
    /// @return bool Validation of the leaf, root and proof
    function verifyMerkleProof(
        bytes32 _root,
        bytes32[] memory _proof,
        bytes32 _leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = _leaf;

        unchecked {
            for (uint256 i = 0; i < _proof.length; i++) {
                computedHash = getHash(computedHash, _proof[i]);
            }
        }

        return computedHash == _root;
    }

    /// -----------------------------------------------------------------------
    /// Owner Validation Actions
    /// -----------------------------------------------------------------------

    /// @dev Check if the function is called by the item owner.
    /// @param _owner Owner address
    /// @param _caller Caller address
    function itemOwnerOnly(address _owner, address _caller) internal pure {
        if (_owner != _caller) {
            revert ValidationUtilsError(ValidationUtilsErrorCodes.ONLY_OWNER);
        }
    }

    /// @dev Check if the function is not called by the item owner.
    /// @param _owner Owner address
    /// @param _caller Caller address
    function notItemOwner(address _owner, address _caller) internal pure {
        if (_owner == _caller) {
            revert ValidationUtilsError(
                ValidationUtilsErrorCodes.OWNER_NOT_ALLOWED
            );
        }
    }

    /// -----------------------------------------------------------------------
    /// Getter Actions
    /// -----------------------------------------------------------------------

    /// @dev Get the hash of data saved in position token.
    /// @param _listingAssets Listing assets
    /// @param _reserveInfo Reserve ino
    /// @param _listingOwner Listing owner
    /// @return hash Hash of the passed data
    function getPositionTokenDataHash(
        Assets calldata _listingAssets,
        ReserveInfo calldata _reserveInfo,
        address _listingOwner
    ) internal pure returns (bytes32 hash) {
        hash = hashAssets(_listingAssets, hash);

        hash = keccak256(
            abi.encodePacked(getReserveHash(_reserveInfo), _listingOwner, hash)
        );
    }

    /// -----------------------------------------------------------------------
    /// Internal functions
    /// -----------------------------------------------------------------------

    /// @dev Get the hash of the given pair of hashes.
    /// @param _a First hash
    /// @param _b Second hash
    function getHash(bytes32 _a, bytes32 _b) internal pure returns (bytes32) {
        return _a < _b ? _hash(_a, _b) : _hash(_b, _a);
    }

    /// @dev Hash two bytes32 variables efficiently using assembly
    /// @param a First bytes variable
    /// @param b Second bytes variable
    function _hash(bytes32 a, bytes32 b) internal pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }

    /// @dev Add the hash of type assets to signature.
    /// @param _assets Assets to be added in hash
    /// @param _sig Hash to which assets need to be added
    /// @return hash Hash result
    function hashAssets(Assets calldata _assets, bytes32 _sig)
        internal
        pure
        returns (bytes32)
    {
        _sig = _addTokensArray(_assets.tokens, _assets.tokenIds, _sig);
        _sig = _addTokensArray(_assets.paymentTokens, _assets.amounts, _sig);

        return _sig;
    }

    /// @dev Add the hash of NFT information to signature.
    /// @param _tokens Array of nft address to be hashed
    /// @param _value Array of NFT tokenIds or amount of FT to be hashed
    /// @param _sig Hash to which assets need to be added
    /// @return hash Hash result
    function _addTokensArray(
        address[] memory _tokens,
        uint256[] memory _value,
        bytes32 _sig
    ) internal pure returns (bytes32) {
        assembly {
            let len := mload(_tokens)
            if eq(eq(len, mload(_value)), 0) {
                revert(0, 0)
            }

            let fmp := mload(0x40)

            let tokenPtr := add(_tokens, 0x20)
            let idPtr := add(_value, 0x20)

            for {
                let tokenIdx := tokenPtr
            } lt(tokenIdx, add(tokenPtr, mul(len, 0x20))) {
                tokenIdx := add(tokenIdx, 0x20)
                idPtr := add(idPtr, 0x20)
            } {
                mstore(fmp, mload(tokenIdx))
                mstore(add(fmp, 0x20), mload(idPtr))
                mstore(add(fmp, 0x40), _sig)

                _sig := keccak256(add(fmp, 0xc), 0x54)
            }
        }
        return _sig;
    }

    /// @dev Get the hash of reserve info.
    /// @param _reserve Reserve info
    /// @return hash Hash of the reserve info
    function getReserveHash(ReserveInfo calldata _reserve)
        internal
        pure
        returns (bytes32)
    {
        bytes32 signature;

        signature = hashAssets(_reserve.deposit, signature);

        signature = hashAssets(_reserve.remaining, signature);

        signature = keccak256(abi.encodePacked(_reserve.duration, signature));

        return signature;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

/// @dev Royalties for collection creators and platform fee for platform manager.
///      to[0] is platform owner address.
/// @param to Creators and platform manager address array
/// @param percentage Royalty percentage based on the listed FT
struct Royalty {
    address[] to;
    uint256[] percentage;
}

/// @dev Common Assets type, packing bundle of NFTs and FTs.
/// @param tokens NFT asset address
/// @param tokenIds NFT token id
/// @param paymentTokens FT asset address
/// @param amounts FT token amount
struct Assets {
    address[] tokens;
    uint256[] tokenIds;
    address[] paymentTokens;
    uint256[] amounts;
}

/// @dev Common SwapAssets type, packing Bundle of NFTs and FTs. Notice tokenIds are represented by merkle roots
///      Each collection address ie. tokens[i] will have a merkle root corrosponding it's valid tokenIds.
///      This is used to select particular tokenId in corrospoding collection. If roots[i]
///      has the value of bytes32(0), this means the entire collection is considered valid.
/// @param tokens NFT asset address
/// @param roots Merkle roots of the criterias. NOTE: bytes32(0) represents the entire collection
/// @param paymentTokens FT asset address
/// @param amounts FT token amount
struct SwapAssets {
    address[] tokens;
    bytes32[] roots;
    address[] paymentTokens;
    uint256[] amounts;
}

/// @dev Common Reserve type, packing data related to reserve listing and reserve offer.
/// @param deposit Assets considered as initial deposit
/// @param remaining Assets considered as due amount
/// @param duration Duration of reserve now swap later
struct ReserveInfo {
    Assets deposit;
    Assets remaining;
    uint256 duration;
}

/// @dev All the reservation details that are stored in the position token
/// @param reservedAssets Assets that were reserved as a part of the reservation
/// @param reservedAssestsRoyalty Royalty offered by the assets owner
/// @param reserveInfo Deposit, remainig and time duriation details of the reservation
/// @param assetOwner Original owner of the reserved assets
struct Reservation {
    Assets reservedAssets;
    Royalty reservedAssetsRoyalty;
    ReserveInfo reserveInfo;
    address assetOwner;
}

/// @dev Listing type, packing the assets being listed, listing parameters, listing owner
///      and users's nonce.
/// @param listingAssets All the assets listed
/// @param directSwaps List of options for direct swap
/// @param reserves List of options for reserve now swap later
/// @param royalty Listing royalty and platform fee info
/// @param timePeriod Time period of listing
/// @param owner Owner's address
/// @param nonce User's nonce
struct Listing {
    Assets listingAssets;
    SwapAssets[] directSwaps;
    ReserveInfo[] reserves;
    Royalty royalty;
    address tradeIntendedFor;
    uint256 timePeriod;
    address owner;
    uint256 nonce;
}

/// @dev Listing type of special NF3 banner listing
/// @param token address of collection
/// @param tokenId token id being listed
/// @param editions number of tokenIds being distributed
/// @param gateCollectionsRoot merkle root for eligible collections
/// @param timePeriod timePeriod of listing
/// @param owner owner of listing
struct NF3GatedListing {
    address token;
    uint256 tokenId;
    uint256 editions;
    bytes32 gatedCollectionsRoot;
    uint256 timePeriod;
    address owner;
}

/// @dev Swap Offer type info.
/// @param offeringItems Assets being offered
/// @param royalty Swap offer royalty info
/// @param considerationRoot Assets to which this offer is made
/// @param timePeriod Time period of offer
/// @param owner Offer owner
/// @param nonce Offer nonce
struct SwapOffer {
    Assets offeringItems;
    Royalty royalty;
    bytes32 considerationRoot;
    uint256 timePeriod;
    address owner;
    uint256 nonce;
}

/// @dev Reserve now swap later type offer info.
/// @param reserveDetails Reservation scheme begin offered
/// @param considerationRoot Assets to which this offer is made
/// @param royalty Reserve offer royalty info
/// @param timePeriod Time period of offer
/// @param owner Offer owner
/// @param nonce Offer nonce
struct ReserveOffer {
    ReserveInfo reserveDetails;
    bytes32 considerationRoot;
    Royalty royalty;
    uint256 timePeriod;
    address owner;
    uint256 nonce;
}

/// @dev Collection offer type info.
/// @param offeringItems Assets being offered
/// @param considerationItems Assets to which this offer is made
/// @param royalty Collection offer royalty info
/// @param timePeriod Time period of offer
/// @param owner Offer owner
/// @param nonce Offer nonce
struct CollectionSwapOffer {
    Assets offeringItems;
    SwapAssets considerationItems;
    Royalty royalty;
    uint256 timePeriod;
    address owner;
    uint256 nonce;
}

/// @dev Collection Reserve type offer info.
/// @param reserveDetails Reservation scheme begin offered
/// @param considerationItems Assets to which this offer is made
/// @param royalty Reserve offer royalty info
/// @param timePeriod Time period of offer
/// @param owner Offer owner
/// @param nonce Offer nonce
struct CollectionReserveOffer {
    ReserveInfo reserveDetails;
    SwapAssets considerationItems;
    Royalty royalty;
    uint256 timePeriod;
    address owner;
    uint256 nonce;
}

/// @dev Swap Params type to be used as one of the input params
/// @param tokens Tokens provided in the parameters
/// @param tokenIds Token Ids provided in the parameters
/// @param proofs Merkle proofs provided in the parameters
struct SwapParams {
    address[] tokens;
    uint256[] tokenIds;
    bytes32[][] proofs;
}

/// @dev Fees struct to be used to signify fees to be paid by a party
/// @param token Address of erc20 tokens to be used for payment
/// @param amount amount of tokens to be paid respectively
/// @param to address to which the fee is paid
struct Fees {
    address token;
    uint256 amount;
    address to;
}

enum Status {
    AVAILABLE,
    EXHAUSTED
}

enum AssetType {
    INVALID,
    ETH,
    ERC_20,
    ERC_721,
    ERC_1155,
    KITTIES,
    PUNK
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

/// @dev Common loan offer struct to be used both the borrower and lender
///      to propose new offers,
/// @param nftCollateralContract Address of the NFT contract
/// @param nftCollateralId NFT collateral token id
/// @param owner Offer owner address
/// @param nonce Nonce of owner
/// @param loanPaymentToken Address of the loan payment token
/// @param loanPrincipalAmount Principal amount of the loan
/// @param maximumRepaymentAmount Maximum amount to be repayed
/// @param loanDuration Duration of the loan
/// @param loanInterestRate Interest rate of the loan
/// @param adminFees Admin fees in basis points
/// @param isLoanProrated Flag for interest rate type of loan
/// @param isBorrowerTerms Bool value to represent if borrower's terms were accepted.
///        - if this value is true, this mean msg.sender must be the lender.
///        - if this value is false, this means lender's terms were accepted and msg.sender
///          must be the borrower.
struct LoanOffer {
    address nftCollateralContract;
    uint256 nftCollateralId;
    address owner;
    uint256 nonce;
    address loanPaymentToken;
    uint256 loanPrincipalAmount;
    uint256 maximumRepaymentAmount;
    uint256 loanDuration;
    uint256 loanInterestRate;
    uint256 adminFees;
    bool isLoanProrated;
    bool isBorrowerTerms;
}

/// @dev Collection loan offer struct to be used to making collection
///      specific offers and trait level offers.
/// @param nftCollateralContract Address of the NFT contract
/// @param nftCollateralIdRoot Merkle root of the tokenIds for collateral
/// @param owner Offer owner address
/// @param nonce Nonce of owner
/// @param loanPaymentToken Address of the loan payment token
/// @param loanPrincipalAmount Principal amount of the loan
/// @param maximumRepaymentAmount Maximum amount to be repayed
/// @param loanDuration Duration of the loan
/// @param loanInterestRate Interest rate of the loan
/// @param adminFees Admin fees in basis points
/// @param isLoanProrated Flag for interest rate type of loan
struct CollectionLoanOffer {
    address nftCollateralContract;
    bytes32 nftCollateralIdRoot;
    address owner;
    uint256 nonce;
    address loanPaymentToken;
    uint256 loanPrincipalAmount;
    uint256 maximumRepaymentAmount;
    uint256 loanDuration;
    uint256 loanInterestRate;
    uint256 adminFees;
    bool isLoanProrated;
}

/// @dev Update loan offer struct to propose new terms for an ongoing loan.
/// @param loanId Id of the loan, same as promissory tokenId
/// @param maximumRepaymentAmount Maximum amount to be repayed
/// @param loanDuration Duration of the loan
/// @param loanInterestRate Interest rate of the loan
/// @param owner Offer owner address
/// @param nonce Nonce of owner
/// @param isLoanProrated Flag for interest rate type of loan
/// @param isBorrowerTerms Bool value to represent if borrower's terms were accepted.
///        - if this value is true, this mean msg.sender must be the lender.
///        - if this value is false, this means lender's terms were accepted and msg.sender
///          must be the borrower.
struct LoanUpdateOffer {
    uint256 loanId;
    uint256 maximumRepaymentAmount;
    uint256 loanDuration;
    uint256 loanInterestRate;
    address owner;
    uint256 nonce;
    bool isLoanProrated;
    bool isBorrowerTerms;
}

/// @dev Main loan struct that stores the details of an ongoing loan.
///      This struct is used to create hashes and store them in promissory tokens.
/// @param loanId Id of the loan, same as promissory tokenId
/// @param nftCollateralContract Address of the NFT contract
/// @param nftCollateralId TokenId of the NFT collateral
/// @param loanPaymentToken Address of the ERC20 token involved
/// @param loanPrincipalAmount Principal amount of the loan
/// @param maximumRepaymentAmount Maximum amount to be repayed
/// @param loanStartTime Timestamp of when the loan started
/// @param loanDuration Duration of the loan
/// @param loanInterestRate Interest Rate of the loan
/// @param isLoanProrated Flag for interest rate type of loan
struct Loan {
    uint256 loanId;
    address nftCollateralContract;
    uint256 nftCollateralId;
    address loanPaymentToken;
    uint256 loanPrincipalAmount;
    uint256 maximumRepaymentAmount;
    uint256 loanStartTime;
    uint256 loanDuration;
    uint256 loanInterestRate;
    uint256 adminFees;
    bool isLoanProrated;
}