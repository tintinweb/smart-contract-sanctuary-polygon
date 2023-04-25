// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ITicketingBase.sol";
import "./IRoyaltyDist.sol";

error PriceNotMet(address ticketAddress, uint256 tokenId, uint256 price);
error ItemNotForSale(address ticketAddress, uint256 ticketId);
error NotListed(address ticketAddress, uint256 ticketId);
error AlreadyListed(address ticketAddress, uint256 ticketId);
error NoProceeds();
error NotOwner();
error NotApprovedForMarketplace();
error PriceMustBeAboveZero();

contract TicketMarketplace is Ownable, ReentrancyGuard {

	struct Listing {
		uint256 price;
		address seller;
	}	

	struct Market {
		bool isSecondaryMarket;
	}

	// Events
	event TicketListed (
		address indexed seller,
		address indexed ticketAddress,
		uint256 indexed ticketId, 
		uint256 price
	);

	event TicketCanceled (
		address indexed seller,
		address indexed ticketAddress,
		uint256 indexed ticketId 
	);

	event TicketBought (
		address indexed buyer,
		address indexed ticketAddress,
		uint256 indexed ticketId,
		uint256 price
	);

	event Log(uint gas);

	// State Variables
		// mapping of ticket contract to tockenId that point to the listing data struct
	mapping(address => mapping(uint256 => Listing)) private s_listings;
		// mapping of seller's address and the amount they have earned in sales
	mapping(address => uint256) private s_proceeds;
		// create a mapping to track if ticket is being sold on the primary or secondary market
	mapping(address => mapping(uint256 => Market)) private s_market; 

	uint256 public _txnFee = 50; // initiate 0.5% transaction fee charged on every transaction
	uint256 public _maxTxnFee = 200; // cap transaction fees at 2%
	
	address public RoyaltyDistributionContract;

	// Function modifiers 
	modifier isNotListed (
		address ticketAddress,
		uint256 ticketId, 
		address owner
	) {
		Listing memory listing = s_listings[ticketAddress][ticketId];
		if (listing.price > 0) {
			revert AlreadyListed(ticketAddress, ticketId);
		}
		_;
	}

	modifier isListed(address ticketAddress, uint256 ticketId) {
		Listing memory listing = s_listings[ticketAddress][ticketId];
		if(listing.price <= 0) {
			revert NotListed(ticketAddress, ticketId);
		}
		_;
	}

	modifier isTicketOwner(
		address ticketAddress,
		uint256 ticketId,
		address spender
	) {
		IERC721 ticket = IERC721(ticketAddress);
		address owner = ticket.ownerOf(ticketId);
		if (spender != owner) {
			revert NotOwner();
		}
		_;
	}

	modifier isContractOwner(
		address ticketAddress,
		address spender
	) {
		ITicket ticket = ITicket(ticketAddress);
		address owner = ticket.getOwner();
		if (spender != owner) {
			revert NotOwner();
		}
		_;
	}

	// Methods 

	function listTicket (
		address ticketAddress, 
		uint256 ticketId,
		uint256 price 
	)
		external 
		isNotListed(ticketAddress, ticketId, msg.sender)
		isTicketOwner(ticketAddress, ticketId, msg.sender)
	{
		if (price <= 0) {
			revert PriceMustBeAboveZero();
		}
		IERC721 ticket = IERC721(ticketAddress);
		if (ticket.getApproved(ticketId) != address(this) && 
			ticket.isApprovedForAll(msg.sender, address(this)) == false ) 
		{
			revert NotApprovedForMarketplace();
		}			
		setMarketType(ticketAddress, ticketId);
		setListingData(ticketAddress, ticketId, price);
		emit TicketListed(msg.sender, ticketAddress, ticketId, price);
	}

	// List multiple tickets from the same contract at once 
	function listMultiple (
		address ticketAddress,
		uint256 idFrom,
		uint256 idTo,
		uint256 price
	)
		external
		isNotListed(ticketAddress, idFrom, msg.sender)
		// isContractOwner(ticketAddress, msg.sender)
	{
		// require(ITicket(ticketAddress).isTrading(idTo) == true);
		if (price <= 0) {
			revert PriceMustBeAboveZero();
		}

		// IERC721 ticket = IERC721(ticketAddress);
		// if (ticket.isApprovedForAll(msg.sender, address(this)) == false ) {
		//  	revert NotApprovedForMarketplace();
		// }
		
		uint id;
		for (id = idFrom; id <= idTo; id ++) {		
			s_market[ticketAddress][id] = Market(false) ;
			setListingData(ticketAddress, id, price);
			emit TicketListed(msg.sender, ticketAddress, id, price);			
		}
	}

	function setListingData(
		address ticketAddress, 
		uint256 tokenId, 
		uint256 price
	) 
		internal 
	{
		s_listings[ticketAddress][tokenId] = Listing(price, msg.sender);
	}

	function setMarketType(
		address ticketAddress, 
		uint256 ticketId
	) 
		internal 
	{
		// Pull the tradeCount from ticket contract to see how many times the ticket has been sold before
		uint256 timesSold = ITicket(ticketAddress).getTradeCount(ticketId);

		// Determine market type based on the number of total sales on the ticket
		s_market[ticketAddress][ticketId] = timesSold >= 1 ? Market(true): Market(false) ;
	}

	function isSecondaryMarket(
		address ticketAddress, 
		uint256 ticketId
	) 
		external 
		view 
		returns(bool) 
	{
		Market memory _ticket = s_market[ticketAddress][ticketId];
		bool isSecondary = _ticket.isSecondaryMarket;
		return(isSecondary);
	}

	function cancelListing(address ticketAddress, uint256 ticketId)
		external
		isTicketOwner(ticketAddress, ticketId, msg.sender)
		isListed(ticketAddress, ticketId)
	{
		delete (s_listings[ticketAddress][ticketId]);
		emit TicketCanceled(msg.sender, ticketAddress, ticketId);
	}

	// Delist all tickets from the same contract
	function cancelAll(
		address ticketAddress
	) 
		external 
		isContractOwner(ticketAddress, msg.sender) 
	{
		uint256 lastTicketId = ITicket(ticketAddress).getLastId();
		uint id;
		for(id = 0; id <= lastTicketId; id ++) {
			Listing memory ticket = s_listings[ticketAddress][id];
			if(ticket.price != 0 && ticket.seller == msg.sender) {
				delete (s_listings[ticketAddress][id]);
				emit TicketCanceled(msg.sender, ticketAddress, id);
			}
		}
	}

	function adminCancelListing(address ticketAddress, uint256 ticketId)
		external
		onlyOwner
		isListed(ticketAddress, ticketId)
	{
		delete (s_listings[ticketAddress][ticketId]);
		emit TicketCanceled(msg.sender, ticketAddress, ticketId);
	}

	// Admin delist all tickets from the same event 
	function adminCancelAll(
		address ticketAddress
	) 
		external 
		onlyOwner 
	{
		uint256 lastTicketId = ITicket(ticketAddress).getLastId();
		uint id;
		for(id = 0; id <= lastTicketId; id ++) {
			Listing memory ticket = s_listings[ticketAddress][id];
			if(ticket.price != 0) {
				delete (s_listings[ticketAddress][id]);
				emit TicketCanceled(msg.sender, ticketAddress, id);
			}
		}
	}

	function buyTicket(
		address ticketAddress, 
		uint256 ticketId
	)
		external 
		payable 
		isListed(ticketAddress, ticketId)
		nonReentrant
	{
		Listing memory listedTicket = s_listings[ticketAddress][ticketId];
		uint256 price = listedTicket.price;
		uint weiPrice = price * 1e18; // convert Eth amount to wei
		address seller = listedTicket.seller;

		if (msg.value < weiPrice) {
			revert PriceNotMet(ticketAddress, ticketId, price);
		}

		// Account for Royalties and deduct transaction fee
		uint256 netProceeds = deductRoyalties(ticketAddress, ticketId, msg.value);
		uint256 transactionFee = (_txnFee * msg.value) / 10000; 
		netProceeds -= transactionFee; 

		// update seller proceeds record and delete listing
		s_proceeds[listedTicket.seller] += netProceeds; 
		delete (s_listings[ticketAddress][ticketId]);

		// Exchange Token
		IERC721(ticketAddress).safeTransferFrom(seller, msg.sender, ticketId);

		emit TicketBought(msg.sender, ticketAddress, ticketId, price);
	}

	// Define function to assign the royalty distribution
	function setRoyaltyContract(
		address _royaltyDistributionContract
	) 
		external 
		onlyOwner
	{
		RoyaltyDistributionContract = _royaltyDistributionContract;
	}

    // Define function to send ether for royalty payment 
    function debitRoyalties(
    	address ticketContract, 
    	address recipient,
    	uint256 royaltyAmount
    ) 
    	internal 
    {
    	(bool success) = IRoyaltyDistribution(RoyaltyDistributionContract)
    		.distributeRoyalty{value: royaltyAmount}(ticketContract, recipient, royaltyAmount);

        require(success , "Royalty payment not received");
    } 

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function must be declared as external.
    fallback() external payable {
    	require(msg.data.length == 0);
        emit Log(gasleft());
    }

    // Helper function to check the balance of this contract
    function getBalance() 
    	public 
    	view 
    	returns (uint) 
    {
        return address(this).balance;
    }

	function deductRoyalties(
		address ticketAddress, 
		uint256 ticketId, 
		uint256 grossSale
	)
		internal
		returns (uint256 net)
	{
		uint256 royaltyAmount = 0;
		Market memory _ticket = s_market[ticketAddress][ticketId];
		
		if (_ticket.isSecondaryMarket == true) {
			try IERC165(ticketAddress).supportsInterface(type(IERC2981).interfaceId) returns (bool supported) {
				// If IERC2981 interface is supported, get royalty info
				if (supported) {
					// Get royalty recipient and expected payment
					(address recipient, uint256 expected) = IERC2981(ticketAddress).royaltyInfo(ticketId, grossSale);

					// Can implement a maximum royalty amount for the platform e.g 20%
					uint256 maxRoyalty = (2000 * grossSale)/10000;

					// If royalty is expected...
					if (expected > 0) {
						// Determine royalty amount limiting to the maximum allowed on the platform
						royaltyAmount = (expected <= maxRoyalty) ? expected : maxRoyalty;

						// send royalty payment to the royalty distribution smart contract
						debitRoyalties(ticketAddress, recipient, royaltyAmount);
 
						// notify listeners of payment by calling royaltiesReceived on ticketing smart contract
						ITicket(ticketAddress).royaltiesRecieved(recipient, royaltyAmount);
					}
				} 
			} catch Error (string memory) {
			} catch (bytes memory) {
			}
		}

		// Return the net amount after royaties have been deducted
		net = grossSale - royaltyAmount;
	}

	function updateListing (
		address ticketAddress, 
		uint256 ticketId,
		uint256 newPrice
	)
		external 
		isListed(ticketAddress, ticketId)
		nonReentrant
		isTicketOwner(ticketAddress, ticketId, msg.sender)
	{
		if (newPrice == 0) {
			revert PriceMustBeAboveZero();
		}

		s_listings[ticketAddress][ticketId].price = newPrice;
		emit TicketListed(msg.sender, ticketAddress, ticketId, newPrice);
	}

	function withdrawProceeds()
		external 
		nonReentrant 
	{
		uint256 proceeds = s_proceeds[msg.sender];
		if (proceeds <= 0) {
			revert NoProceeds(); 
		}
		s_proceeds[msg.sender] = 0;

		(bool success, ) = payable(msg.sender).call{value: proceeds}("");
		require(success, "Transfer failed");
	}

	// Set Methods for Public Variables
	function setTransactionFee(
		uint256 txnFee
	) 
		external 
		onlyOwner 
	{
		require(txnFee <= _maxTxnFee, "Input Exceeds Maximum");
		_txnFee = txnFee;
	}

	// Getter Methods
	function getListing (
		address ticketAddress, 
		uint256 ticketId
	)
		external 
		view 
		returns (Listing memory)
	{
		return s_listings[ticketAddress][ticketId];
	}

	function getPrice (
		address ticketAddress, 
		uint256 ticketId
	) 
		external
		view
		returns(uint256)
	{
		return s_listings[ticketAddress][ticketId].price;
	}

	function getSeller (
		address ticketAddress, 
		uint256 ticketId
	) 
		external
		view
		returns(address)
	{
		return s_listings[ticketAddress][ticketId].seller;
	}

	function getProceeds (
		address seller
	) 	
		external 
		view 
		returns(uint256) 
	{
		return s_proceeds[seller];
	}

	//	TODO... Implement a refund feature 
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC165.sol";

/**
 *	@dev Interface for the ParaPass Ticketing contract
 */
 interface ITicket is IERC165 {
 	/**
 	 *	@dev Emitted when a ticket is staked 
 	 */
 	event TicketStaked (address indexed owner, uint256 indexed tokenId,	uint256 indexed _stakeStartTime);

 	/**
 	 *	@dev Emitted when a ticket is unstaked 
 	 */
 	event TicketUnstaked (address indexed owner, uint256 indexed tokenId, uint256 indexed _stakeEndTime);

 	/**
 	 *	@dev Emitted when a ticket is redeemed
 	 */
 	event TicketRedeemed (address indexed owner, uint256 indexed tokenId, uint256 indexed _redeemTime);

  /**
   *  @dev Calls the erc721a mint function passing in the quantity of tokens to be batch minted and the address of the minter
   */
  function autoMint (address creator, uint256 quantity) pure external;

  /**
   *  @dev Assigns a single tier ticket uri to all the minted tickets 
   */
  function setSingleTierURIs( string memory _ticketUri ) pure external;

  /**
   *  @dev Assigns the multi-tier ticket uris for all the minted tickets 
   */
  function setMultiTierURIs( string[] calldata _multiTierURIArray, uint[] calldata _tierTokenCountArray, uint256 _tierCount ) pure external;

 	/**
 	 *	@dev Returns the number of times a ticket has been traded since it was minted
 	 */
 	function getTradeCount (uint256 tokenId) external view returns (uint256);

 	/**
 	 *	@dev Stakes the 'tokenId' putting it in a state where it can not be sold/traded while it is being staked
 	 *
 	 *	Requirements:
 	 *  
 	 *	- caller must own the ticket
 	 *	- ticket must not be currently staked 
 	 * 	- only unredeemed tickets can be staked
 	 *
 	 */
 	function stake (uint256 tokenId) external;

 	/**
 	 *	@dev Unstakes the making it possible to claim any rewards accrued as well as trade the ticket
 	 *
 	 *	Requirements:
 	 *  
 	 *	- caller must own the ticket
 	 *	- ticket must be currently staked 
 	 */
 	function unstake (uint256 tokenId) external;

 	/**
 	 *	@dev Allows the owner to claim the value of the ticket recording their wallet for any post event gifts
 	 *
 	 *	Requirements:
 	 *  
 	 *	- caller must own the ticket
 	 *	- ticket must be currently staked 
 	 */
 	function redeem (uint256 tokenId) external;

 	/**
 	 *	@dev Bool to check if the ticket is currently allowed to be traded
 	 */
 	function isTrading (uint256 tokenId) external view returns (bool);

 	/**
 	 *	@dev Bool to check if the ticket is currently being staked 
 	 */
 	function isStaked (uint256 tokenId) external view returns (bool);

 	/**
 	 *	@dev Bool to check if the ticket's value has been redeemed
 	 */
 	function isRedeemed (uint256 tokenId) external view returns (bool);

 	/**
 	 *	@dev Allows ticket creator to revert the ticket state from `Redeemed` to `Unredeemed`
 	 *	meant to be a last resort undo method for refunding tickets that have been redeemed by mistake
 	 *	before the live event has been attended
 	 *
 	 *	Requirements:
 	 *
 	 *	- can only be called by contract owner
 	 *	- the ticket must exist
 	 */
 	function unRedeem (uint256 tokenId) external;

 	/**
 	 *	@dev Bool to check if the ticket was used to attend a live event
 	 */
 	function AttendedLiveEvent (uint256 tokenId) external view returns (bool);

 	/**
 	 *	@dev Returns the address that redeemed the value of the ticket
 	 */
 	function getRedeemingAddress (uint256 tokenId) external view returns (address);

   /**
    *  @dev Returns the address of the owner of the contract
    */
  function getOwner () external view returns (address);

   /**
    *  @dev Returns the tokenId of the last minted ticket
    */
  function getLastId () external view returns (uint256);

 	/**
 	 *	@dev Allows ticket owner to send their ticket to a new address 'to'
 	 *	this method is not considered as a sale so the trade count is not incremented 
 	 *	uses the `transferFrom` method to transfer ticket from `msg.sender` to `to`
 	 *
 	 *	Requirements:
 	 *
 	 *	- can not be called from a smart contract
 	 *	- ticket should be unstaked to transfer
 	 */
 	function sendTicket (address to, uint256 tokenId) external;

 	/**
 	 *	@dev Allows ticket to be safely transfered from one wallet to another 
 	 *	Use of this method for marketplace transactions as it considers all transfers as sales 
 	 *	uses the `safeTransferFrom` method to transfer ticket
 	 *
 	 *	Requirements:
 	 *
 	 *	- the ticket should hold a 'trading' status to allow transfer
   *  - updates the ticket tradecount used to determine the market type (primary/secondary)
 	 */
 	function safeTransferFrom (address from, address to, uint256 tokenId) external;

  /**
   *  @dev Allows marketplace to send confirmation for royalties recieved. 
   *  Called after royalties have been transfered to the recipient address to notify any listeners
   *  Checks if calling contract has been approvedForAll
   *
   */
  function royaltiesRecieved(address recipient, uint256 amount) external;

  /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
  function transferOwnership(address newOwner) external;
 }

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/interfaces/IERC165.sol";

/**
 *	@dev Interface for the ParaPass Royalty Distribution contract
 */
 interface IRoyaltyDistribution is IERC165 {
 	/**
 	 *	@dev Emitted when royalties are paid out from the royalty distribution contract
 	 */
 	event RoyaltiesPaid ( address ticketContract, address recipient, uint256 royaltyAmount );

    event Withdrawal ( address ticketContract, address recipient, uint256 amountWithdrawn );

 	/**
 	 *	@dev 
 	 *
 	 *	Requirements:
 	 *  
 	 *	- payable function called by the marketplace contract when a ticket sale has a royalty payment
 	 *	- recieves royalties and updates recipient's accumulated amount
 	 * 	- recieved amount must be >= the input royalty amount (_royaltyAmount)
 	 *
 	 */
 	function distributeRoyalty ( address _ticketContract, address _recipient, uint256 _royaltyAmount ) external payable returns(bool success);

    function withdrawProceeds(address _ticketContract) external; 
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