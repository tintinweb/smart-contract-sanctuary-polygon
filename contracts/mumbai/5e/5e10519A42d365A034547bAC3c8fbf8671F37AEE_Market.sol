/**
 *Submitted for verification at polygonscan.com on 2022-05-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IModule {
    function getModule(uint8 function_) external returns (address);
}

interface IRoles {
    function isVerifiedSeller(address user_) external returns (bool);
    function isModerator(address user_) external returns (bool);
    function isAdmin(address user_) external returns (bool);
    function isSeller(address user_) external returns (bool);
}

interface ICategories {
    function isValidERC20(address token_) external returns (bool);
    function setValidERC20(address token_, bool valid_) external;
    function hasOwnershipOf(uint collection_, uint tokenId_, address owner_) external returns (bool);
    function setApprovalForAll(address operator, bool approval) external;
    function isApprovedForAll(address account, address operator) external returns (bool);
    function safeTransferFrom(address from, address to, uint collection, uint id, bytes memory data) external;
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

/**
 * @notice The interface to implement in the market contract
 */
interface IMarket {
    /**
     * @notice Struct created when a NFT is listed for a fixed price
     * @param active If this offer is active or not
     * @param collection NFT collection. If the token is ERC721, set to 0
     * @param tokenId Token id (in the collection given)
     * @param value Value required to complete the offer
     * @param collectionAddress Address of the NFT
     * @param paymentToken Token to accept for the listing
     * @param seller The address that sells the NFT (owner or approved)
     * @dev If the paymentToken is address(0), pays in native token
     */
    struct Offer {
        bool active;
        bool isAuction;
        uint256 endTime;
        uint256[] collections;
        uint256[] tokenIds;
        uint256 value;
        address[] collectionAddresses;
        address paymentToken;
        address seller;
    }

    /**
     * @notice Struct created when a NFT is listed for a fixed price
     * @param id Fixed offer id
     * @param isAuction If the offer is an auction
     * @param collections NFT collection. If the token is ERC721, set to 0
     * @param tokenIds Token id (in the collection given)
     * @param value Value required to complete the offer
     * @param collectionAddresses Address of the NFT
     * @param paymentToken Token to accept for the listing
     * @param seller The address that sells the NFT (owner or approved)
     * @dev If the paymentToken is address(0), pays in native token
     */
    event OfferCreated(
        uint256 id,
        bool isAuction,
        uint256[] collections,
        uint256[] tokenIds,
        uint256 value,
        address[] collectionAddresses,
        address paymentToken,
        address seller
    );

    /**
     * @notice When an offer is completed
     * @param seller The address that sells the NFT (owner or approved)
     * @param buyer Who bought the offer
     * @param collectionAddresses Contract addresses of the tokens selled
     * @param collections Collection  
     */
    event OfferCompleted(
        bool isAuction,
        address seller,
        address buyer,
        address[] collectionAddresses,
        uint[] collections,
        uint[] tokenIds,
        uint value
    );

    /**
     * @notice When a fixed offer is approved
     * @param offerId The offer approved
     */
    event OfferApproved(
        uint offerId
    );

    /**
     * @notice When a fixed offer is cancelled
     * @param offerId The offer cancelled
     */
    event OfferCancelled(
        uint offerId
    );

    /**
     * @notice Creates a fixed offer
     * @param isAuction_ If the offer is an auction
     * @param endTime If it is an auction, the time to be valid
     * @param collections_ NFT collection. If the token is ERC721, set to 0
     * @param tokenIds_ Token id (in the collection given)
     * @param value_ Value required to complete the offer
     * @param collectionAddresses_ Address of the NFT
     * @param paymentToken_ Token to accept for the listing
     * @dev If the paymentToken is address(0), pays in native token
     */
    function createOffer(
        bool isAuction_,
        uint256 endTime,
        uint256[] memory collections_,
        uint256[] memory tokenIds_,
        uint256 value_,
        address[] memory collectionAddresses_,
        address paymentToken_
    ) external;

}

/**
 * @notice Market logic
 */
contract Market is IMarket {    
    /**
     * @notice List of offers
     */
    mapping(uint256 => Offer) public offersList;

    /**
     * @notice Winner of the auction
     */
    mapping(uint256 => address) public winner;

    /**
     *
     */
    IModule moduleManager;

    /**
     *
     */
    IRoles rolesContract;

    /**
     *
     */
    ICategories tokenContract;

    /**
     * @notice Amount of offers
     */
    uint public offersCount;

    /**
     * @notice List of approved offers
     */
    mapping(uint256 => bool) public approvedOffers;

    /**
     * @notice Event for when someone bid in an auction
     */
    event BidForAuction(address who, uint offerId, uint amount);

    /**
     *
     */
    error InvalidCaller();

    /**
     * @notice If you are not the token owner!
     */
    error NotTokenOwner();

    /**
     * @notice If a offer is inactive
     */
    error InactiveOffer();

    /** 
     * @notice Requires to be the owner of the token
     */
    error OwnershipRequired();

    /**
     * @notice Requires the approval of the token owner to transact
     */
    error ApprovalRequired();

    /**
     * @notice If the ERC20 to accept is not validated
     */
    error NotValidERC20();

    /**
     *
     */
    error InvalidParams(string reason);

    /**
     * @notice Only offers that are approved by a moderator/admin
     * @param offerId_ Offer id to check if approved
     */
    modifier onlyApprovedOffers(uint offerId_) {
        if (approvedOffers[offerId_] == true) _; else revert();
    }

    /**
     *
     */
    constructor (address module_) {
        moduleManager = IModule(module_);
        address roles = moduleManager.getModule(0);
        address token = moduleManager.getModule(1);
        rolesContract = IRoles(roles);
        tokenContract = ICategories(token);
    }

    /**
     * @notice Function to create fixed offers
     * @param collections_ Collection number (if ERC721: 0)
     * @param tokenIds_ Token to sell
     * @param value_ Value of the token
     * @param collectionAddresses_ Token address
     * @param paymentToken_ You can ask for USDT, DAI or Matic/Ether
     * @dev If the paymentToken is address(0), pays in native token
     * @dev NOTE: Not compatible with ERC1155 for now
     */
    function createOffer(bool isAuction_,
                         uint endTime_,
                         uint[] memory collections_,
                         uint[] memory tokenIds_,
                         uint value_,
                         address[] memory collectionAddresses_,
                         address paymentToken_) public {
        if ((collections_.length != tokenIds_.length) ||
            (collections_.length != collectionAddresses_.length))
            revert InvalidParams('Invalid array');
        if (isAuction_ && (endTime_ <= block.timestamp + 3600)) revert InvalidParams('Invalid time');
        if (!tokenContract.isValidERC20(paymentToken_)) revert InvalidParams('Invalid ERC20');
        if (value_ <= 0) revert InvalidParams('Invalid value');
        // Check for ownership and approved
        for (uint i = 0; i < collectionAddresses_.length; i++) {
            if (collectionAddresses_[i] == address(this)) {
                if (!tokenContract.hasOwnershipOf(collections_[i], tokenIds_[i], msg.sender)) revert OwnershipRequired();
                tokenContract.setApprovalForAll(address(this), true); // msg.sender -> seller
            } else {
                if (IERC721(collectionAddresses_[i]).getApproved(tokenIds_[i]) != address(this)) // msg.sender -> Beru
                    revert ApprovalRequired();
            }
        }
        _createOffer(isAuction_, endTime_, collections_, tokenIds_, value_, collectionAddresses_, paymentToken_);
    }

    /**
     * @notice Internal fixed offer creation
     * @param isAuction_ if it is an auction
     * @param endTime_ If it is an auction, time that will be valid
     * @param collections_ List of collections
     * @param tokenIds_ List of tokens ids
     * @param value_ Value of the offer
     * @param collectionAddresses_ Addresses of the tokens collection
     * @param paymentToken_ USDT/DAI/Ether/Matic..
     */
    function _createOffer(bool isAuction_,
                          uint endTime_,
                          uint[] memory collections_,
                          uint[] memory tokenIds_,
                          uint value_,
                          address[] memory collectionAddresses_,
                          address paymentToken_) internal {
        offersList[offersCount] = Offer(
            true, //active
            isAuction_,
            endTime_,
            collections_,
            tokenIds_,
            value_,
            collectionAddresses_,
            paymentToken_,
            msg.sender //seller
        );
        emit OfferCreated(offersCount, isAuction_, collections_, tokenIds_, value_, collectionAddresses_, paymentToken_, msg.sender);
        offersCount++;
    }

    /**
     * @notice For buying a fixed offer & closing an auction
     * @param offerId_ The offer to buy
     * @dev Requires ERC20 allowance
     */
    function buyOffer(uint offerId_) public payable onlyApprovedOffers(offerId_) {
        if (offerId_ > offersCount) revert InvalidParams('Invalid id');
        Offer storage offer = offersList[offerId_];
        if (offer.isAuction) {
            // Check if caller is the winner and if it is ended
            if (winner[offerId_] == address(0)) {
                offer.active = false;
                emit OfferCancelled(offerId_);
            }
            if (msg.sender != winner[offerId_]) revert InvalidParams('Not the winner');
            if (validateAuctionTime(offerId_)) revert InvalidParams('Not ended');
        }
        if (offer.active != true) revert InactiveOffer();
        if (offer.paymentToken == address(0)) {
            // Not enought sended
            if (msg.value < offer.value)
                revert InvalidParams('Invalid amount');
        } else {
            // Not enought allowance
            if (IERC20(offer.paymentToken)
                    .allowance(msg.sender, address(this)) < offer.value)
                revert InvalidParams('Allowance required');
        } 
        for (uint i = 0; i < offer.collectionAddresses.length; i++) {
            if (offer.collectionAddresses[i] == address(this)) {
                if (!tokenContract.isApprovedForAll(offer.seller, address(this)))
                    revert ApprovalRequired();
                tokenContract.safeTransferFrom(
                    offer.seller,
                    msg.sender,
                    offer.collections[i],
                    offer.tokenIds[i],
                    '');        
            } else {
                if (IERC721(offer.collectionAddresses[i]).getApproved(offer.tokenIds[i]) != address(this))
                    revert ApprovalRequired();
                IERC721(offer.collectionAddresses[i]).safeTransferFrom(
                    offer.seller,
                    msg.sender,
                    offer.tokenIds[i]);
            }
        }
        
        // Send the funds to the seller
        sendFunds(offerId_);
        // Set the offer as inactive and emit event
        offer.active = false;

        // Emit event
        emit OfferCompleted(
            offer.isAuction,
            offer.seller,
            msg.sender,
            offer.collectionAddresses,
            offer.collections,
            offer.tokenIds,
            offer.value
        );
    }
    
    /**
     * @notice Internal function to native or ERC20 funds
     * @param offerId_ The offer that will be closed
     */
    function sendFunds(uint offerId_) internal {
        // Check if the collection has royalties!
        // Send the funds to the seller
        if (offersList[offerId_].paymentToken == address(0)) {
            (bool success, ) = payable(offersList[offerId_].seller).call{value: offersList[offerId_].value}('');
            require(success);
        } else IERC20(offersList[offerId_].paymentToken).transferFrom(msg.sender, offersList[offerId_].seller, offersList[offerId_].value); 
    }

    /**
     * @notice This is made to approve a valid offer
     * @param offerId_ The offer id to validate
     */
    function approveOffer(uint offerId_) public {
        if (!rolesContract.isModerator(msg.sender)) revert InvalidCaller();
        if (offersList[offerId_].active != true) revert InactiveOffer();
        approvedOffers[offerId_] = true;
        emit OfferApproved(offerId_);
    }

    /** ONLY MODERATORS
     * @notice Deprecate offer, it does not matter if it is a fixed offer or an auction
     * @param offerId_ The offer id to deprecate
     */
    function deprecateOffer(uint offerId_) public {
        offersList[offerId_].active = false;
        emit OfferCancelled(offerId_);
    }

    /**
     * @notice Bid for an auction
     * @param offerId_ The auction
     * @param value_ The value to bid
     */
    function bidForAuction(uint offerId_, uint value_) public onlyApprovedOffers(offerId_) {
        if (offerId_ > offersCount) revert InvalidParams('');
        if (offersList[offerId_].active == false) revert InactiveOffer();
        if ((value_ <= 0) || (offersList[offerId_].value >= value_)) revert InvalidParams('Your bid must be higher');
        if (!offersList[offerId_].isAuction) revert InvalidParams('Not an auction');
        if (!validateAuctionTime(offerId_)) revert InactiveOffer();
        if (offersList[offerId_].paymentToken == address(0)) {
            if (value_ > msg.sender.balance) revert InvalidParams('Not enought balance');
        } else {
            if (value_ > IERC20(offersList[offerId_].paymentToken).balanceOf(msg.sender)) revert InvalidParams('Not enought balance');
        }
        offersList[offerId_].value = value_;
        winner[offerId_] = msg.sender; 
        // Emit event
        emit BidForAuction(msg.sender, offerId_, value_);
    }

    /**
     * @notice Get offer info
     * @param offerId_ Offer to get info from
     * @return All the info from the offer given
     * @dev Revert if offerId is an inexistent offer
     */
    function getOfferInfo(uint offerId_) public view returns (bool, uint,
                                                              address[] memory,
                                                              uint256[] memory,
                                                              uint256[] memory,
                                                              address,
                                                              uint) {
        // Validate if offer exists
        if (offerId_ > offersCount) revert InvalidParams('Inexistent offer');
        return (
            offersList[offerId_].isAuction ? validateAuctionTime(offerId_) : offersList[offerId_].active,
            offersList[offerId_].endTime,
            offersList[offerId_].collectionAddresses,
            offersList[offerId_].collections,
            offersList[offerId_].tokenIds,
            offersList[offerId_].paymentToken,
            offersList[offerId_].value
        );
    }
    
    /**
     * @notice Validates if an auction is still valid or not
     * @param offerId_ The auction
     * @return valid if it is valid or not
     */    
    function validateAuctionTime(uint offerId_) public view returns (bool valid) {
        if (!offersList[offerId_].isAuction) revert InvalidParams('Not an auction');
        offersList[offerId_].endTime > block.timestamp ? valid = true : valid = false;
    }    

    /**
     * @notice Validate an ERC20 token as payment method
     * @param token_ The token address
     * @param validated_ If validated or not
     * @dev Only admins
     */
    function validateERC20(address token_, bool validated_) public {
        if (msg.sender != moduleManager.getModule(0)) revert InvalidCaller();
        tokenContract.setValidERC20(token_, validated_);
    } 
}