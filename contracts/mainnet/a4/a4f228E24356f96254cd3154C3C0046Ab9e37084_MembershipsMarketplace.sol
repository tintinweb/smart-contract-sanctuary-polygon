// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.9;

import '@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts/interfaces/IERC1155.sol';
import '@openzeppelin/contracts/interfaces/IERC721.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import './lib/MarketplaceHelper.sol' as MarketplaceHelper;
import './lib/Models.sol' as Models;
import {HUNDRED_PERCENT, MINIMUM_ASK} from './lib/Constants.sol';

/**
 * @title Admin Contract Interface
 * @dev See https://github.com/Fanz-events/contracts/blob/main/src/Admin.sol
 */
interface IAdmin {
    function primaryMarketplaceRoyalty() external view returns (uint16);

    function secondaryMarketplaceRoyalty() external view returns (uint16);

    function collaborators(uint256 eventId, address collaborator) external view returns (bool);
}

/**
 * @title Membership Tokens Interface
 * @dev See https://github.com/Fanz-events/contracts/blob/main/src/Membership.sol
 */
interface IMembership is IERC1155 {
    /// @dev for publishing new Memberships
    function mintBatch(
        address to,
        uint256[] memory id,
        uint256[] memory amount,
        string[] calldata uris,
        bytes memory data
    ) external;

    /// @dev for deleting Memberships
    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external;

    // @dev for editing Memberships metadata
    function setUri(uint256 tokenId, string calldata tokenURI) external;

    // @dev for transfering membership ownership
    function bulkTransfer(
        address from,
        address[] calldata to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external;
}

/**
 * @title The Fanz's Marketplace
 * @dev This Fanz's Marketplace is a smart contract that allows to manage memberships.
 * @author The Fanz's Team. See https://fanz.events/
 * Features: create/delete/modify memberships, buy and sell memberships, modify royalties.
 */
contract MembershipsMarketplace is Initializable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    /* Storage */

    /// @dev Reference to Membership (ERC1155) contract
    address public membershipAddress;

    /// @dev Reference to Admin contract
    address public adminAddress;

    /// @dev Mapping of membership per organizer - [organizerAddress, [membershipIds]]
    mapping(address => uint256[]) public organizerMemberships;

    /// @dev Mapping of membership properties (creator, royalties, etc.) - [membershipId, Models.AssetProperties]
    mapping(uint256 => Models.AssetProperties) public membershipsProperties;

    /// @dev Market offers: Mapping of memberships market offers - [seller, [membershipId, Models.Offer]]
    mapping(address => mapping(uint256 => Models.Offer)) public offers;

    /// @dev the Membership's Id's counter
    CountersUpgradeable.Counter internal _membershipIds;

    /// @dev Mapping of private memberships
    mapping(uint256 => bool) public privateMemberships;

    /// @dev the Allowance's Id's counter
    CountersUpgradeable.Counter internal _allowanceIds;

    /// @dev Mapping of allowances per membership [membershipId, [allowanceId, Allowance]]
    mapping(uint256 => mapping(uint256 => Models.Allowance)) public allowances;

    /* Events */

    /// @dev Event emitted when a new membership is created and published on the marketplace
    event MembershipPublished(address organizer, uint256 indexed membershipId, uint256 amount, Models.NewAssetSaleInfo saleInfo, string uri);

    /// @dev Event emitted when an membership's URI is modified
    event MembershipEdited(uint256 indexed membershipId, string newUri);

    /// @dev Event emitted when a membership is deleted
    event MembershipsDeleted(uint256[] ids, address owner, uint256[] amounts);

    /// @dev Event emitted when a membership is sold
    event MembershipBought(uint256 indexed membershipId, address seller, address buyer, uint256 price, uint256 amount);

    /// @dev Event emitted when a new sale Models.Offer is published
    event AskSetted(uint256 indexed membershipId, address indexed seller, uint256 membershipPrice, uint256 amount);

    /// @dev Event emitted when a sale Models.Offer is deleted
    event AskRemoved(address indexed seller, uint256 indexed membershipId);

    /// @dev Event emmited when the primary marketplace royalty is modified on a membership
    event PrimaryMarketRoyaltyModifiedOnMembership(uint256 indexed membershipId, uint256 newRoyalty);

    /// @dev Event emmited when the secondary marketplace royalty is modified on a membership
    event SecondaryMarketRoyaltyModifiedOnMembership(uint256 indexed membershipId, uint256 newRoyalty);

    /// @dev Event emmited when the creator royalty is modified on a membership
    event CreatorRoyaltyModifiedOnMembership(uint256 indexed membershipId, uint256 newRoyalty);

    /// @dev Event emmited when an allowance is added to a membership
    event AllowanceAdded(uint256 indexed membershipId, uint256 indexed allowanceId, Models.AllowanceInput allowance);

    /// @dev Event emmited when an allowance is removed from a membership
    event AllowanceRemoved(uint256 indexed membershipId, uint256 indexed allowanceId);

    /// @dev Event emmited when an allowance is consumed
    event AllowanceConsumed(uint256 indexed allowanceId);

    /* Modifiers */

    /// @dev Verifies that the sender is either the marketplace's owner or the given membership's creator.
    modifier onlyMembershipCreatorOrContractOwner(uint256 membershipId) {
        require(membershipsProperties[membershipId].creator == msg.sender || this.owner() == msg.sender, 'Not allowed!');
        _;
    }

    /// @dev Verifies that the sender is the given membership's creator.
    modifier onlyMembershipCreator(uint256 membershipId) {
        require(membershipsProperties[membershipId].creator == msg.sender, 'Only creator is allowed!');
        _;
    }

    /* Initializer */

    /**
     *  @dev Constructor.
     *  @param _membershipAddress Address of the Membership contract
     *  @param _adminAddress Address of the Admin contract
     */
    function initialize(address _membershipAddress, address _adminAddress) external initializer {
        membershipAddress = _membershipAddress;
        adminAddress = _adminAddress;

        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
    }

    /* External */

    /**
     *  @dev Publish new memberships for sender.
     *  @param memberships Membership's information (metadata's uri, amount to sell, price, etc.), See NewAssetSaleInfo struct.
     */
    function publishMemberships(Models.NewAssetSaleInfo[] calldata memberships) external returns (uint256[] memory membershipIds) {
        return publishMembershipsForOrganizer(msg.sender, memberships);
    }

    /**
     *  @dev Modifies a membership's URI.
     *  @param membershipId The id of the membership to be deleted
     *  @param newUri The new URI
     */
    function setMembershipUri(uint256 membershipId, string calldata newUri)
        external
        whenNotPaused
        onlyMembershipCreatorOrContractOwner(membershipId)
    {
        IMembership(membershipAddress).setUri(membershipId, newUri);

        emit MembershipEdited(membershipId, newUri);
    }

    /**
     *  @dev Bulk deletes memberships.
     *  @param ids The ids of the memberships to be deleted
     *  @param amounts The amounts of the memberships to be deleted
     */
    function deleteMemberships(uint256[] memory ids, uint256[] memory amounts) external whenNotPaused {
        require(ids.length == amounts.length, 'Ids and amounts count mismatch.');
        for (uint256 i = 0; i < ids.length; i++) {
            require(membershipsProperties[ids[i]].creator == msg.sender || this.owner() == msg.sender, 'Not allowed!');
        }

        IMembership(membershipAddress).burnBatch(msg.sender, ids, amounts);

        emit MembershipsDeleted(ids, msg.sender, amounts);
    }

    /**
     *  @dev Claim free Membership.
     *  @param membershipId The id of the membership to be claimed
     *  @param claimer Address of the person who would be the membership holder
     */
    function claimFreeMembership(
        uint256 membershipId,
        address claimer,
        uint256 allowanceId
    ) external {
        address creator = membershipsProperties[membershipId].creator;
        require(IMembership(membershipAddress).balanceOf(creator, membershipId) >= 1, 'Not enough memberships available');
        require(IMembership(membershipAddress).balanceOf(claimer, membershipId) == 0, 'Claimer has a membership.');
        require(offers[creator][membershipId].price == 0, 'Membership is not free.');
        require(offers[creator][membershipId].amount >= 1, 'Not enough memberships for claim');
        if (privateMemberships[membershipId] == true) {
            _consumeAllowance(claimer, membershipId, allowanceId, 1);
        }

        IMembership(membershipAddress).safeTransferFrom(address(creator), claimer, membershipId, 1, '');
        offers[creator][membershipId].amount -= 1;

        emit MembershipBought(membershipId, creator, claimer, 0, 1);
    }

    /**
     *  @dev Buy market Memberships.
     *  @param membershipId The id of the membership to buy
     *  @param seller The seller from whom would like to buy (should be a sale Models.Offer setted)
     *  @param amount Amount of memberships to buy (Memberships are ERC1155)
     */
    function buyMarketMembership(
        uint256 membershipId,
        address seller,
        uint256 amount,
        uint256 allowanceId
    ) external payable whenNotPaused nonReentrant {
        require(IMembership(membershipAddress).balanceOf(seller, membershipId) >= amount, 'Seller hasnt enough membership.');
        require(amount <= offers[seller][membershipId].amount, 'Not enough membership for sale');
        require(msg.value == (amount * offers[seller][membershipId].price), 'Value does not match price');
        require(msg.sender != seller, 'You cant buy your own membership');
        address creator = membershipsProperties[membershipId].creator;
        if (privateMemberships[membershipId] == true && seller == creator) {
            _consumeAllowance(msg.sender, membershipId, allowanceId, amount);
        }

        uint256 membershipPrice = offers[seller][membershipId].price;
        uint256 previousBalance = address(this).balance;
        offers[seller][membershipId].amount -= amount;

        if (membershipPrice == 0) {
            require(amount == 1, 'Can only buy one free membership');
            require(IMembership(membershipAddress).balanceOf(msg.sender, membershipId) == 0, 'Claimer has a membership.');
        } else {
            // Paid Memberships
            if (seller == creator) {
                // primary sale, selling by creator.

                uint256 marketplaceShare = MarketplaceHelper.calculateFee(
                    membershipPrice,
                    membershipsProperties[membershipId].primaryMarketRoyalty
                );
                uint256 creatorShare = membershipPrice - marketplaceShare;

                MarketplaceHelper.transferFundsSupportingGnosisSafe(creator, creatorShare * amount); // Untrusted transfer
                MarketplaceHelper.transferFundsSupportingGnosisSafe(owner(), amount * marketplaceShare); // Trusted transfer, Gnosis Safe Wallet
            } else {
                // secondary sale, seller is not creator.

                uint256 marketplaceShare = MarketplaceHelper.calculateFee(
                    membershipPrice,
                    membershipsProperties[membershipId].secondaryMarketRoyalty
                );
                uint256 creatorShare = MarketplaceHelper.calculateFee(membershipPrice, membershipsProperties[membershipId].creatorRoyalty);
                uint256 sellerShare = membershipPrice - marketplaceShare - creatorShare;

                MarketplaceHelper.transferFundsSupportingGnosisSafe(seller, sellerShare * amount); // Untrusted transfer
                MarketplaceHelper.transferFundsSupportingGnosisSafe(creator, creatorShare * amount); // Untrusted transfer
                MarketplaceHelper.transferFundsSupportingGnosisSafe(owner(), marketplaceShare * amount); // Trusted transfer, Gnosis Safe Wallet
            }
        }
        IMembership(membershipAddress).safeTransferFrom(address(seller), msg.sender, membershipId, amount, '');

        assert((previousBalance - address(this).balance) == msg.value); // All value should be distributed.

        emit MembershipBought(membershipId, seller, msg.sender, membershipPrice, amount);
    }

    /**
     *  @dev Sets a new sale Models.Offer.
     *  @param membershipId The id of the membership to set the sale Models.Offer (sender should have balance of this one)
     *  @param membershipPrice The price to be setted for this Models.Offer
     *  @param amount The amount of memberships that will be available for sale
     */
    function setAsk(
        uint256 membershipId,
        uint256 membershipPrice,
        uint256 amount
    ) external whenNotPaused {
        require(membershipPrice >= MINIMUM_ASK, 'Price below minimum.');
        require(IMembership(membershipAddress).balanceOf(msg.sender, membershipId) >= amount, 'Sender does not have membership.');
        require(membershipsProperties[membershipId].isResellable == true, 'Membership is not resellable.');

        offers[msg.sender][membershipId].price = membershipPrice;
        offers[msg.sender][membershipId].amount = amount;

        emit AskSetted(membershipId, msg.sender, membershipPrice, amount);
    }

    /**
     *  @dev Removes a sale Models.Offer
     *  @param membershipId The id of the membership to remove the sale Models.Offer (only sender's Models.Offer)
     */
    function removeAsk(uint256 membershipId) external whenNotPaused {
        require(IMembership(membershipAddress).balanceOf(msg.sender, membershipId) > 0, 'Sender has no membership.');

        delete offers[msg.sender][membershipId];
        emit AskRemoved(msg.sender, membershipId);
    }

    /**
     *  @dev Modifies creator's royalty for a given Membership.
     *  @param membershipId The id of the membership whose royalty will be modified
     *  @param newCreatorRoyalty The new royalty to be setted
     */
    function modifyCreatorRoyaltyOnMembership(uint256 membershipId, uint256 newCreatorRoyalty)
        external
        onlyMembershipCreator(membershipId)
        whenNotPaused
    {
        require(newCreatorRoyalty <= (HUNDRED_PERCENT - membershipsProperties[membershipId].secondaryMarketRoyalty), 'Above 100%.');

        membershipsProperties[membershipId].creatorRoyalty = newCreatorRoyalty;

        emit CreatorRoyaltyModifiedOnMembership(membershipId, newCreatorRoyalty);
    }

    function transferMembershipOwnership(uint256 membershipId, address newOwner) external onlyMembershipCreator(membershipId) whenNotPaused {
        delete offers[msg.sender][membershipId];
        IMembership(membershipAddress).safeTransferFrom(
            msg.sender,
            newOwner,
            membershipId,
            IMembership(membershipAddress).balanceOf(msg.sender, membershipId),
            ''
        );

        membershipsProperties[membershipId].creator = newOwner;
        uint256[] memory currentOwnerMemberships = organizerMemberships[msg.sender];
        for (uint8 i = 0; i < currentOwnerMemberships.length; i++) {
            if (currentOwnerMemberships[i] == membershipId) {
                delete organizerMemberships[msg.sender][i];
                break;
            }
        }

        organizerMemberships[newOwner].push(membershipId);
    }

    /**
     *  @dev Modifies Primary Marketplace royalty for a given membership.
     *  @param membershipId The id of the membership whose royalty will be modified
     *  @param newMarketplaceRoyalty The new royalty to be setted
     */
    function modifyPrimaryMarketplaceRoyaltyOnMembership(uint256 membershipId, uint256 newMarketplaceRoyalty) external onlyOwner whenNotPaused {
        membershipsProperties[membershipId].primaryMarketRoyalty = newMarketplaceRoyalty;

        emit PrimaryMarketRoyaltyModifiedOnMembership(membershipId, newMarketplaceRoyalty);
    }

    /**
     *  @dev Modifies Secondary Marketplace royalty for a given membership.
     *  @param membershipId The id of the membership whose royalty will be modified
     *  @param newMarketplaceRoyalty The new royalty to be setted
     */
    function modifySecondaryMarketplaceRoyaltyOnMembership(uint256 membershipId, uint256 newMarketplaceRoyalty)
        external
        onlyOwner
        whenNotPaused
    {
        require(newMarketplaceRoyalty <= (HUNDRED_PERCENT - membershipsProperties[membershipId].creatorRoyalty), 'Above 100%.');

        membershipsProperties[membershipId].secondaryMarketRoyalty = newMarketplaceRoyalty;

        emit SecondaryMarketRoyaltyModifiedOnMembership(membershipId, newMarketplaceRoyalty);
    }

    /* public */

    /**
     *  @dev Publish new memberships for an address.
     *  @param memberships Membership's information (metadata's uri, amount to sell, price, etc.), See NewAssetSaleInfo struct.
     */
    function publishMembershipsForOrganizer(address organizer, Models.NewAssetSaleInfo[] calldata memberships)
        public
        whenNotPaused
        nonReentrant
        returns (uint256[] memory membershipIds)
    {
        uint256 quantity = memberships.length;
        uint256[] memory newMembershipIds = new uint256[](quantity);
        uint256[] memory amounts = new uint256[](quantity);
        string[] memory uris = new string[](quantity);

        // Create Membership
        for (uint256 i = 0; i < quantity; i++) {
            require(
                memberships[i].royalty <= (HUNDRED_PERCENT - IAdmin(adminAddress).secondaryMarketplaceRoyalty()),
                'Creator royalty above the limit.'
            );
            require(memberships[i].price == 0 || memberships[i].price >= MINIMUM_ASK, 'Asking price below minimum.');
            require(memberships[i].amountToSell <= memberships[i].amount, 'Amount to sell is too high.');
            if (memberships[i].isResellable == true) {
                require(memberships[i].price != 0, 'Free are not resellable.');
            }

            _membershipIds.increment();
            uint256 membershipId = _membershipIds.current();
            membershipsProperties[membershipId] = Models.AssetProperties(
                memberships[i].royalty,
                IAdmin(adminAddress).primaryMarketplaceRoyalty(),
                IAdmin(adminAddress).secondaryMarketplaceRoyalty(),
                organizer,
                memberships[i].isResellable
            );
            offers[organizer][membershipId] = Models.Offer(memberships[i].amountToSell, memberships[i].price);
            newMembershipIds[i] = membershipId;
            organizerMemberships[organizer].push(membershipId);
            amounts[i] = memberships[i].amount;
            uris[i] = memberships[i].uri;

            if (memberships[i].isPrivate == true) {
                privateMemberships[membershipId] = true;
            }
            for (uint256 a = 0; a < memberships[i].allowances.length; a++) {
                _addAllowance(membershipId, memberships[i].allowances[a]);
            }
        }

        IMembership(membershipAddress).mintBatch(organizer, newMembershipIds, amounts, uris, '');

        for (uint256 i = 0; i < quantity; i++) {
            emit MembershipPublished(organizer, newMembershipIds[i], amounts[i], memberships[i], uris[i]);
        }

        return organizerMemberships[organizer];
    }

    /**
     *  @dev Pauses the contract in case of an emergency. Can only be called by the owner.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     *  @dev Re-plays the contract in case a prior emergency has been solved. Can only be called by the owner.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     *  @dev Adds an Allowance (amount for allowed addresses) for a membership
     */
    function addAllowance(uint256 membershipId, Models.AllowanceInput calldata allowance)
        public
        onlyMembershipCreator(membershipId)
        returns (uint256)
    {
        return _addAllowance(membershipId, allowance);
    }

    /**
     *  @dev Removes an Allowance (amount for allowed addresses) for a membership
     */
    function removeAllowance(uint256 membershipId, uint256 allowanceId) public onlyMembershipCreator(membershipId) {
        _removeAllowance(membershipId, allowanceId);
    }

    /**
     *  @dev Retrieves if the given address is allowed for the give allowance.
     */
    function isAddressAllowed(
        uint256 membershipId,
        uint256 allowanceId,
        address operator
    ) public view returns (bool) {
        return allowances[membershipId][allowanceId].allowed[operator];
    }

    /**
     *  @dev Retrieves the amount left in a given allowance.
     */
    function allowanceAmountLeft(uint256 membershipId, uint256 allowanceId) public view returns (uint256) {
        return allowances[membershipId][allowanceId].amount;
    }

    /**
     *  @dev Consumes a membership from an allowance.
     */
    function _consumeAllowance(
        address sender,
        uint256 membershipId,
        uint256 allowanceId,
        uint256 amount
    ) internal {
        require(_isAllowed(sender, membershipId, allowanceId), 'Not allowed!');
        require(allowances[membershipId][allowanceId].amount >= amount, 'Available amount is not enough.');
        allowances[membershipId][allowanceId].amount -= amount;
        emit AllowanceConsumed(allowanceId);
        if (allowances[membershipId][allowanceId].amount == 0) {
            _removeAllowance(membershipId, allowanceId);
        }
    }

    /**
     *  @dev Adds an Allowance (amount for allowed addresses) for a membership
     */
    function _addAllowance(uint256 membershipId, Models.AllowanceInput calldata allowance) internal returns (uint256) {
        uint256 id = _allowanceIds.current();
        _allowanceIds.increment();
        for (uint256 i = 0; i < allowance.allowedAddresses.length; i++) {
            allowances[membershipId][id].allowed[allowance.allowedAddresses[i]] = true;
        }
        allowances[membershipId][id].amount = allowance.amount;
        emit AllowanceAdded(membershipId, id, allowance);
        return id;
    }

    /**
     *  @dev Removes an Allowance (amount for allowed addresses) for a membership
     */
    function _removeAllowance(uint256 membershipId, uint256 allowanceId) internal {
        delete allowances[membershipId][allowanceId];
        emit AllowanceRemoved(membershipId, allowanceId);
    }

    /**
     *  @dev Retrieves true if the claimer is allowed to claim.
     */
    function _isAllowed(
        address operator,
        uint256 membershipId,
        uint256 allowanceId
    ) internal view returns (bool) {
        return allowances[membershipId][allowanceId].allowed[operator] == true && allowances[membershipId][allowanceId].amount > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
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
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
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
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.9;

import {HUNDRED_PERCENT} from './Constants.sol';

/**
 * @dev Transfers funds to a given address.
 * @dev Necesary to avoid gas error since eip 2929, more info in eip 2930.
 * @param to The address to transfer the funds to
 * @param amount The amount to be transfered
 */
function transferFundsSupportingGnosisSafe(address to, uint256 amount) {
    (bool sent, ) = payable(to).call{value: amount, gas: 2600}(''); // solhint-disable-line
    assert(sent);
}

/**
 *  @dev Calculated a fee given an amount and a fee percentage
 *  @dev HUNDRED_PERCENT is used as 100% to enhanced presicion.
 *  @param totalAmount The total amount to be paid
 *  @param fee The percentage of the fee over the full amount.
 */
function calculateFee(uint256 totalAmount, uint256 fee) pure returns (uint256) {
    return (totalAmount * fee) / HUNDRED_PERCENT;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.9;

/* Structs */

/// @dev Properties assigned to a particular ticket, including royalties and sellable status.
struct AssetProperties {
    uint256 creatorRoyalty;
    uint256 primaryMarketRoyalty;
    uint256 secondaryMarketRoyalty;
    address creator;
    bool isResellable;
}

/// @dev A particular sale Models.Offer made by a owner, including price and amount.
struct Offer {
    uint256 amount;
    uint256 price;
}

/// @dev all required information for publishing a new ticket.
struct NewAssetSaleInfo {
    uint256 amount;
    uint256 price;
    uint256 royalty;
    uint256 amountToSell;
    bool isResellable;
    string uri;
    bool isPrivate;
    AllowanceInput[] allowances;
}

/// @dev ERC721 & ERC1155 memberships management.
struct AllowedMemberships {
    mapping(address => bool) allowedByAddress;
    mapping(address => uint256) tokenIdsAmountAllowedByAddress;
    mapping(address => mapping(uint256 => bool)) allowedTokenIds;
}

/// @dev Memberships input management.
struct MembershipsInfo {
    address[][] addresses;
    uint256[][][] ids;
}

/// @dev Allowance pools e.g. for custom claiming rights for tickets.
struct Allowance {
    uint256 amount;
    mapping(address => bool) allowed;
}

/// @dev Allowance pools input e.g. for custom claiming rights for tickets.
struct AllowanceInput {
    uint256 amount;
    address[] allowedAddresses;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.9;

/// @dev A multiplier for calculating royalties with some digits of presicion
uint16 constant HUNDRED_PERCENT = 10000; // For two digits precision

/// @dev Lower boundary for beign able to calculates fees with the given HUNDRED_PERCENT presicion
uint256 constant MINIMUM_ASK = 10000; // For fee calculation

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

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
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

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
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

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
    function isApprovedForAll(address account, address operator) external view returns (bool);

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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