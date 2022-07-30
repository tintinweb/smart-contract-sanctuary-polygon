/**
 *Submitted for verification at polygonscan.com on 2022-07-30
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.3;

abstract contract Initializable {


    bool private _initialized;


    bool private _initializing;

    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}


abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}


library AddressUpgradeable {

    function isContract(address account) internal view returns (bool) {
      

        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

   
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {

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




abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

 
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}


abstract contract ReentrancyGuardUpgradeable is Initializable {
   
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }


    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;

      
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}


interface IERC721TokenCreator {
    function tokenCreator(address _contractAddress, uint256 _tokenId)
        external
        view
        returns (address payable);
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


interface IMarketplaceSettings {
    /////////////////////////////////////////////////////////////////////////
    // Marketplace Min and Max Values
    /////////////////////////////////////////////////////////////////////////
   
    function getMarketplaceMaxValue() external view returns (uint256);

   
    function getMarketplaceMinValue() external view returns (uint256);

    /////////////////////////////////////////////////////////////////////////
    // Marketplace Fee
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Get the marketplace fee percentage.
     * @return uint8 wei fee.
     */
    function getMarketplaceFeePercentage() external view returns (uint8);

    /**
     * @dev Utility function for calculating the marketplace fee for given amount of wei.
     * @param _amount uint256 wei amount.
     * @return uint256 wei fee.
     */
    function calculateMarketplaceFee(uint256 _amount)
        external
        view
        returns (uint256);

    /////////////////////////////////////////////////////////////////////////
    // Primary Sale Fee
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Get the primary sale fee percentage for a specific ERC721 contract.
     * @param _contractAddress address ERC721Contract address.
     * @return uint8 wei primary sale fee.
     */
    function getERC721ContractPrimarySaleFeePercentage(address _contractAddress)
        external
        view
        returns (uint8);

    /**
     * @dev Utility function for calculating the primary sale fee for given amount of wei
     */
    function calculatePrimarySaleFee(address _contractAddress, uint256 _amount)
        external
        view
        returns (uint256);

    /**
     * @dev Check whether the ERC721 token has sold at least once.
     */
    function hasERC721TokenSold(address _contractAddress, uint256 _tokenId)
        external
        view
        returns (bool);

    /**
     * @dev Mark a token as sold.
     */
    function markERC721Token(
        address _contractAddress,
        uint256 _tokenId,
        bool _hasSold
    ) external;

    function setERC721ContractPrimarySaleFeePercentage(
        address _contractAddress,
        uint8 _percentage
    ) external;
}


/**
 * @title IERC721CreatorRoyalty Token level royalty interface.
 */
interface IERC721CreatorRoyalty is IERC721TokenCreator {
    /**
     * @dev Get the royalty fee percentage for a specific ERC721 contract.
     * @param _contractAddress address ERC721Contract address.
     * @param _tokenId uint256 token ID.
     * @return uint8 wei royalty fee.
     */
    function getERC721TokenRoyaltyPercentage(
        address _contractAddress,
        uint256 _tokenId
    ) external view returns (uint8);

    /**
     * @dev Utililty function to calculate the royalty fee for a token.
     * @param _contractAddress address ERC721Contract address.
     * @param _tokenId uint256 token ID.
     * @param _amount uint256 wei amount.
     * @return uint256 wei fee.
     */
    function calculateRoyaltyFee(
        address _contractAddress,
        uint256 _tokenId,
        uint256 _amount
    ) external view returns (uint256);

    /**
     * @dev Utililty function to set the royalty percentage for a specific ERC721 contract.
     * @param _contractAddress address ERC721Contract address.
     * @param _percentage percentage for royalty
     */
    function setPercentageForSetERC721ContractRoyalty(
        address _contractAddress,
        uint8 _percentage
    ) external;
}


/// @notice Interface for the Payments contract used.
interface IPayments {
    function refund(address _payee, uint256 _amount) external payable;

    function payout(address[] calldata _splits, uint256[] calldata _amounts)
        external
        payable;
}


// @notice The interface for the SpaceOperatorRegistry
interface ISpaceOperatorRegistry {
    function getPlatformCommission(address _operator)
        external
        view
        returns (uint8);

    function setPlatformCommission(address _operator, uint8 _commission)
        external;

    function isApprovedSpaceOperator(address _operator)
        external
        view
        returns (bool);

    function setSpaceOperatorApproved(address _operator, bool _approved)
        external;
}


interface IApprovedTokenRegistry {
    /// @notice Returns if a token has been approved or not.
    function isApprovedToken(address _tokenContract)
        external
        view
        returns (bool);

    /// @notice Adds a token to the list of approved tokens.
    function addApprovedToken(address _tokenContract) external;

    /// @notice Removes a token from the approved tokens list.
    function removeApprovedToken(address _tokenContract) external;

    /// @notice Sets whether all token contracts should be approved.
    /// @param _allTokensApproved Bool denoting if all tokens should be approved.
    function setAllTokensApproved(bool _allTokensApproved) external;
}


/// @title Auction888Bazar Storage Contract
/// @dev STORAGE CAN ONLY BE APPENDED NOT INSERTED OR MODIFIED
contract Auctions888BazaarStorage {

    // Constants

    // Auction Types
    bytes32 public constant COLDIE_AUCTION = "COLDIE_AUCTION";
    bytes32 public constant SCHEDULED_AUCTION = "SCHEDULED_AUCTION";
    bytes32 public constant NO_AUCTION = bytes32(0);

    // Structs

    // The Offer struct for a given token:
    // buyer - address of person making the offer
    // currencyAddress - address of the erc20 token used for an offer
    //                   or the zero address for eth
    // amount - offer in wei/full erc20 value
    // marketplaceFee - the amount that is taken by the network on offer acceptance.
    struct Offer {
        address payable buyer;
        uint256 amount;
        uint256 timestamp;
        uint8 marketplaceFee;
        bool convertible;
    }

    // The Sale Price struct for a given token:
    // seller - address of the person selling the token
    // currencyAddress - address of the erc20 token used for an offer
    //                   or the zero address for eth
    // amount - offer in wei/full erc20 value
    struct SalePrice {
        address payable seller;
        address currencyAddress;
        uint256 amount;
        address payable[] splitRecipients;
        uint8[] splitRatios;
    }

    // Structure of an Auction:
    // auctionCreator - creator of the auction
    // creationBlock - time that the auction was created/configured
    // startingBlock - time that the auction starts on
    // lengthOfAuction - how long the auction is
    // currencyAddress - address of the erc20 token used for an offer
    //                   or the zero address for eth
    // minimumBid - min amount a bidder can bid at the start of an auction.
    // auctionType - type of auction, represented as the formatted bytes 32 string
    struct Auction {
        address payable auctionCreator;
        uint256 creationBlock;
        uint256 startingTime;
        uint256 lengthOfAuction;
        address currencyAddress;
        uint256 minimumBid;
        bytes32 auctionType;
        address payable[] splitRecipients;
        uint8[] splitRatios;
    }

    struct Bid {
        address payable bidder;
        address currencyAddress;
        uint256 amount;
        uint8 marketplaceFee;
    }

    // Events

    event Sold(
        address indexed _originContract,
        address indexed _buyer,
        address indexed _seller,
        address _currencyAddress,
        uint256 _amount,
        uint256 _tokenId
    );

    event SetSalePrice(
        address indexed _originContract,
        address indexed _currencyAddress,
        address _target,
        uint256 _amount,
        uint256 _tokenId,
        address payable[] _splitRecipients,
        uint8[] _splitRatios
    );

    event OfferPlaced(
        address indexed _originContract,
        address indexed _bidder,
        address indexed _currencyAddress,
        uint256 _amount,
        uint256 _tokenId,
        bool _convertible
    );

    event AcceptOffer(
        address indexed _originContract,
        address indexed _bidder,
        address indexed _seller,
        address _currencyAddress,
        uint256 _amount,
        uint256 _tokenId,
        address payable[] _splitAddresses,
        uint8[] _splitRatios
    );

    event CancelOffer(
        address indexed _originContract,
        address indexed _bidder,
        address indexed _currencyAddress,
        uint256 _amount,
        uint256 _tokenId
    );

    event NewAuction(
        address indexed _contractAddress,
        uint256 indexed _tokenId,
        address indexed _auctionCreator,
        address _currencyAddress,
        uint256 _startingTime,
        uint256 _minimumBid,
        uint256 _lengthOfAuction
    );

    event CancelAuction(
        address indexed _contractAddress,
        uint256 indexed _tokenId,
        address indexed _auctionCreator
    );

    event AuctionBid(
        address indexed _contractAddress,
        address indexed _bidder,
        uint256 indexed _tokenId,
        address _currencyAddress,
        uint256 _amount,
        bool _startedAuction,
        uint256 _newAuctionLength,
        address _previousBidder
    );

    event AuctionSettled(
        address indexed _contractAddress,
        address indexed _bidder,
        address _seller,
        uint256 indexed _tokenId,
        address _currencyAddress,
        uint256 _amount
    );

    // State Variables

    // Current marketplace settings implementation to be used
    IMarketplaceSettings public marketplaceSettings;


    address public auctions888Marketplace;

    address public auctions888House;

    // Current SpaceOperatorRegistry implementation to be used.
    ISpaceOperatorRegistry public spaceOperatorRegistry;

    // Current ApprovedTokenRegistry implementation being used for currencies.
    IApprovedTokenRegistry public approvedTokenRegistry;

    // Current payments contract to use
    IPayments public payments;

    // Address of the network beneficiary
    address public networkBeneficiary;

    // A minimum increase in bid amount when out bidding someone.
    uint8 public minimumBidIncreasePercentage; // 10 = 10%

    // Maximum length that an auction can be.
    uint256 public maxAuctionLength;

    // Extension length for an auction
    uint256 public auctionLengthExtension;

    // Offer cancellation delay
    uint256 public offerCancelationDelay;

    // Mapping from contract to mapping of tokenId to mapping of target to sale price.
    mapping(address => mapping(uint256 => mapping(address => SalePrice)))
        public tokenSalePrices;

    // Mapping from contract to mapping of tokenId to mapping of currency address to Current Offer.
    mapping(address => mapping(uint256 => mapping(address => Offer)))
        public tokenCurrentOffers;

    // Mapping from contract to mapping of tokenId to Auction.
    mapping(address => mapping(uint256 => Auction)) public tokenAuctions;

    // Mapping from contract to mapping of tokenId to Bid.
    mapping(address => mapping(uint256 => Bid)) public auctionBids;

    uint256[50] private __gap;
    /// ALL NEW STORAGE MUST COME AFTER THIS
}


interface IAuctions888Bazaar {
    // Marketplace Functions
    // Buyer

    /// @notice Create an offer for a given asset
    /// @param _originContract Contract address of the asset being listed.
    /// @param _amount Amount being offered.
    /// @param _convertible If the offer can be converted into an auction
    function offer(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress,
        uint256 _amount,
        bool _convertible
    ) external payable;

    /// @notice Purchases the token for the current sale price.
    /// @param _originContract Contract address for asset being bought.
    /// @param _tokenId TokenId of asset being bought.
    /// @param _currencyAddress Currency address of asset being used to buy.
    /// @param _amount Amount the piece if being bought for.
    function buy(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress,
        uint256 _amount
    ) external payable;

    /// @notice Cancels an existing offer the sender has placed on a piece.
    /// @param _originContract Contract address of token.
    /// @param _tokenId TokenId that has an offer.
    /// @param _currencyAddress Currency address of the offer.
    function cancelOffer(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress
    ) external;

    // Seller

    /// @notice Sets a sale price for the given asset(s).
    /// @param _originContract Contract address of the asset being listed.
    /// @param _tokenId Token Id of the asset.
    /// @param _currencyAddress Contract address of the currency asset is being listed for.
    /// @param _listPrice Amount of the currency the asset is being listed for (including all decimal points).
    /// @param _target Address of the person this sale price is target to.
    /// @param _splitAddresses Addresses to split the sellers commission with.
    /// @param _splitRatios The ratio for the split corresponding to each of the addresses being split with.
    function setSalePrice(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress,
        uint256 _listPrice,
        address _target,
        address payable[] calldata _splitAddresses,
        uint8[] calldata _splitRatios
    ) external;

    /// @notice Removes the current sale price of an asset for the given currency.
    /// @param _originContract The origin contract of the asset.
    /// @param _tokenId The tokenId of the asset within the _originContract.
    /// @param _target The address of the person
    function removeSalePrice(
        address _originContract,
        uint256 _tokenId,
        address _target
    ) external;

    /// @notice Accept an offer placed on _originContract : _tokenId.
    /// @param _originContract Contract of the asset the offer was made on.
    /// @param _tokenId TokenId of the asset.
    /// @param _currencyAddress Address of the currency used for the offer.
    /// @param _amount Amount the offer was for/and is being accepted.
    /// @param _splitAddresses Addresses to split the sellers commission with.
    /// @param _splitRatios The ratio for the split corresponding to each of the addresses being split with.
    function acceptOffer(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress,
        uint256 _amount,
        address payable[] calldata _splitAddresses,
        uint8[] calldata _splitRatios
    ) external;

    // Auction House
    // Anyone

    /// @notice Settles an auction that has ended.
    /// @param _originContract Contract address of asset.
    /// @param _tokenId Token Id of the asset.
    function settleAuction(address _originContract, uint256 _tokenId) external;

    // Buyer

    /// @notice Places a bid on a valid auction.
    /// @param _originContract Contract address of asset being bid on.
    /// @param _tokenId Token Id of the asset.
    /// @param _currencyAddress Address of currency being used to bid.
    /// @param _amount Amount of the currency being used for the bid.
    function bid(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress,
        uint256 _amount
    ) external payable;

    // Seller

    /// @notice Configures an Auction for a given asset.
    /// @param _auctionType The type of auction being configured.
    /// @param _originContract Contract address of the asset being put up for auction.
    /// @param _tokenId Token Id of the asset.
    /// @param _startingAmount The reserve price or min bid of an auction.
    /// @param _currencyAddress The currency the auction is being conducted in.
    /// @param _lengthOfAuction The amount of time in seconds that the auction is configured for.
    /// @param _splitAddresses Addresses to split the sellers commission with.
    /// @param _splitRatios The ratio for the split corresponding to each of the addresses being split with.
    function configureAuction(
        bytes32 _auctionType,
        address _originContract,
        uint256 _tokenId,
        uint256 _startingAmount,
        address _currencyAddress,
        uint256 _lengthOfAuction,
        uint256 _startTime,
        address payable[] calldata _splitAddresses,
        uint8[] calldata _splitRatios
    ) external;

    /// @notice Cancels a configured Auction that has not started.
    /// @param _originContract Contract address of the asset pending auction.
    /// @param _tokenId Token Id of the asset.
    function cancelAuction(address _originContract, uint256 _tokenId) external;

    /// @notice Converts an offer into a coldie auction.
    /// @param _originContract Contract address of the asset.
    /// @param _tokenId Token Id of the asset.
    /// @param _currencyAddress Address of the currency being converted.
    /// @param _amount Amount being converted into an auction.
    /// @param _lengthOfAuction Number of seconds the auction will last.
    /// @param _splitAddresses Addresses that the sellers take in will be split amongst.
    /// @param _splitRatios Ratios that the take in will be split by.
    function convertOfferToAuction(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress,
        uint256 _amount,
        uint256 _lengthOfAuction,
        address payable[] calldata _splitAddresses,
        uint8[] calldata _splitRatios
    ) external;

    /// @notice Grabs the current auction details for a token.
    /// @param _originContract Contract address of asset.
    /// @param _tokenId Token Id of the asset.
    /** @return Auction Struct: creatorAddress, creationTime, startingTime, lengthOfAuction,
                currencyAddress, minimumBid, auctionType, splitRecipients array, and splitRatios array.
    */
    function getAuctionDetails(address _originContract, uint256 _tokenId)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            address,
            uint256,
            bytes32,
            address payable[] calldata,
            uint8[] calldata
        );

    function getSalePrice(
        address _originContract,
        uint256 _tokenId,
        address _target
    )
        external
        view
        returns (
            address,
            address,
            uint256,
            address payable[] memory,
            uint8[] memory
        );
}

// The unified contract for the bazar logic (Marketplace and Auction House)

/// @dev All storage is inherrited and append only (no modifications) to make upgrade compliant
contract Auctions888Bazaar is
    IAuctions888Bazaar,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    Auctions888BazaarStorage
{
    // Initializer
    function initialize(
        address _marketplaceSettings,
        address _auctions888Marketplace,
        address _auctions888House,
        address _spaceOperatorRegistry,
        address _approvedTokenRegistry,
        address _payments,
         address _networkBeneficiary
    ) public initializer {
        require(_marketplaceSettings != address(0));
        require(_auctions888Marketplace != address(0));
        require(_auctions888House != address(0));
        require(_spaceOperatorRegistry != address(0));
        require(_approvedTokenRegistry != address(0));
        require(_payments != address(0));
         require(_networkBeneficiary != address(0));

        marketplaceSettings = IMarketplaceSettings(_marketplaceSettings);
        auctions888Marketplace = _auctions888Marketplace;
        auctions888House = _auctions888House;
        spaceOperatorRegistry = ISpaceOperatorRegistry(_spaceOperatorRegistry);
        approvedTokenRegistry = IApprovedTokenRegistry(_approvedTokenRegistry);
        payments = IPayments(_payments);
         networkBeneficiary = _networkBeneficiary;

        minimumBidIncreasePercentage = 10;
        maxAuctionLength = 7 days;
        auctionLengthExtension = 15 minutes;
        offerCancelationDelay = 5 minutes;

        __Ownable_init();
        __ReentrancyGuard_init();
    }

    // onlyOwner Functions

    function setMarketplaceSettings(address _marketplaceSettings)
        external
        onlyOwner
    {
        require(_marketplaceSettings != address(0));
        marketplaceSettings = IMarketplaceSettings(_marketplaceSettings);
    }

    function setAuctions888Marketplace(address _auctions888Marketplace)
        external
        onlyOwner
    {
        require(_auctions888Marketplace != address(0));
        auctions888Marketplace = _auctions888Marketplace;
    }

    function setAuctions888House(address _auctions888House)
        external
        onlyOwner
    {
        require(_auctions888House != address(0));
        auctions888House = _auctions888House;
    }

    function setSpaceOperatorRegistry(address _spaceOperatorRegistry)
        external
        onlyOwner
    {
        require(_spaceOperatorRegistry != address(0));
        spaceOperatorRegistry = ISpaceOperatorRegistry(_spaceOperatorRegistry);
    }

    function setApprovedTokenRegistry(address _approvedTokenRegistry)
        external
        onlyOwner
    {
        require(_approvedTokenRegistry != address(0));
        approvedTokenRegistry = IApprovedTokenRegistry(_approvedTokenRegistry);
    }

    function setPayments(address _payments) external onlyOwner {
        require(_payments != address(0));
        payments = IPayments(_payments);
    }

    function setNetworkBeneficiary(address _networkBeneficiary)
        external
        onlyOwner
    {
        require(_networkBeneficiary != address(0));
        networkBeneficiary = _networkBeneficiary;
    }

    function setMinimumBidIncreasePercentage(
        uint8 _minimumBidIncreasePercentage
    ) external onlyOwner {
        minimumBidIncreasePercentage = _minimumBidIncreasePercentage;
    }

    function setMaxAuctionLength(uint8 _maxAuctionLength) external onlyOwner {
        maxAuctionLength = _maxAuctionLength;
    }

    function setAuctionLengthExtension(uint256 _auctionLengthExtension)
        external
        onlyOwner
    {
        auctionLengthExtension = _auctionLengthExtension;
    }

    function setOfferCancelationDelay(uint256 _offerCancelationDelay)
        external
        onlyOwner
    {
        offerCancelationDelay = _offerCancelationDelay;
    }

    // Marketplace Functions

    /// @notice Place an offer for a given asset
    /// @dev Notice we need to verify that the msg sender has approved us to move funds on their behalf.
    /// @dev Covers use of any currency (0 address is eth).
    /// @dev _amount is the amount of the offer excluding the marketplace fee.
    /// @dev There can be multiple offers of different currencies, but only 1 per currency.
    /// @param _originContract Contract address of the asset being listed.
    /// @param _tokenId Token Id of the asset.
    /// @param _currencyAddress Address of the token being offered.
    /// @param _amount Amount being offered.
    /// @param _convertible If the offer can be converted into an auction
    function offer(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress,
        uint256 _amount,
        bool _convertible
    ) external payable override {
        (bool success, bytes memory data) = auctions888Marketplace.delegatecall(
            abi.encodeWithSelector(
                this.offer.selector,
                _originContract,
                _tokenId,
                _currencyAddress,
                _amount,
                _convertible
            )
        );

        require(success, string(data));
    }

    /// @notice Purchases the token for the current sale price.
    /// @dev Covers use of any currency (0 address is eth).
    /// @dev Need to verify that the buyer (if not using eth) has the marketplace approved for _currencyContract.
    /// @dev Need to verify that the seller has the marketplace approved for _originContract.
    /// @param _originContract Contract address for asset being bought.
    /// @param _tokenId TokenId of asset being bought.
    /// @param _currencyAddress Currency address of asset being used to buy.
    /// @param _amount Amount the piece if being bought for (including marketplace fee).
    function buy(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress,
        uint256 _amount
    ) external payable override {
        (bool success, bytes memory data) = auctions888Marketplace.delegatecall(
            abi.encodeWithSelector(
                this.buy.selector,
                _originContract,
                _tokenId,
                _currencyAddress,
                _amount
            )
        );

        require(success, string(data));
    }

    /// @notice Cancels an existing offer the sender has placed on a piece.
    /// @param _originContract Contract address of token.
    /// @param _tokenId TokenId that has an offer.
    /// @param _currencyAddress Currency address of the offer.
    function cancelOffer(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress
    ) external override {
        (bool success, bytes memory data) = auctions888Marketplace.delegatecall(
            abi.encodeWithSelector(
                this.cancelOffer.selector,
                _originContract,
                _tokenId,
                _currencyAddress
            )
        );

        require(success, string(data));
    }

    /// @notice Sets a sale price for the given asset(s) directed at the _target address.
    /// @dev Covers use of any currency (0 address is eth).
    /// @dev Sale price for everyone is denoted as the 0 address.
    /// @dev Only 1 currency can be used for the sale price directed at a speicific target.
    /// @dev _listPrice of 0 signifies removing the list price for the provided currency.
    /// @dev This function can be used for counter offers as well.
    /// @param _originContract Contract address of the asset being listed.
    /// @param _tokenId Token Id of the asset.
    /// @param _currencyAddress Contract address of the currency asset is being listed for.
    /// @param _listPrice Amount of the currency the asset is being listed for (including all decimal points).
    /// @param _target Address of the person this sale price is target to.
    /// @param _splitAddresses Addresses to split the sellers commission with.
    /// @param _splitRatios The ratio for the split corresponding to each of the addresses being split with.
    function setSalePrice(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress,
        uint256 _listPrice,
        address _target,
        address payable[] calldata _splitAddresses,
        uint8[] calldata _splitRatios
    ) external override {
        (bool success, bytes memory data) = auctions888Marketplace.delegatecall(
            abi.encodeWithSelector(
                this.setSalePrice.selector,
                _originContract,
                _tokenId,
                _currencyAddress,
                _listPrice,
                _target,
                _splitAddresses,
                _splitRatios
            )
        );

        require(success, string(data));
    }

    /// @notice Removes the current sale price of an asset for _target for the given currency.
    /// @dev Sale prices could still exist for different currencies.
    /// @dev Sale prices could still exist for different targets.
    /// @dev Zero address for _currency means that its listed in ether.
    /// @dev _target of zero address is the general sale price.
    /// @param _originContract The origin contract of the asset.
    /// @param _tokenId The tokenId of the asset within the _originContract.
    /// @param _target The address of the person
    function removeSalePrice(
        address _originContract,
        uint256 _tokenId,
        address _target
    ) external override {
        IERC721 erc721 = IERC721(_originContract);
        address tokenOwner = erc721.ownerOf(_tokenId);

        require(
            msg.sender == tokenOwner,
            "removeSalePrice::Must be tokenOwner."
        );

        delete tokenSalePrices[_originContract][_tokenId][_target];

        emit SetSalePrice(
            _originContract,
            address(0),
            address(0),
            0,
            _tokenId,
            new address payable[](0),
            new uint8[](0)
        );
    }

    /// @notice Accept an offer placed on _originContract : _tokenId.
    /// @dev Zero address for _currency means that the offer being accepted is in ether.
    /// @param _originContract Contract of the asset the offer was made on.
    /// @param _tokenId TokenId of the asset.
    /// @param _currencyAddress Address of the currency used for the offer.
    /// @param _amount Amount the offer was for/and is being accepted.
    /// @param _splitAddresses Addresses to split the sellers commission with.
    /// @param _splitRatios The ratio for the split corresponding to each of the addresses being split with.
    function acceptOffer(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress,
        uint256 _amount,
        address payable[] calldata _splitAddresses,
        uint8[] calldata _splitRatios
    ) external override {
        (bool success, bytes memory data) = auctions888Marketplace.delegatecall(
            abi.encodeWithSelector(
                this.acceptOffer.selector,
                _originContract,
                _tokenId,
                _currencyAddress,
                _amount,
                _splitAddresses,
                _splitRatios
            )
        );

        require(success, string(data));
    }

    // Auction House Functions

    /// @notice Configures an Auction for a given asset.
    /// @dev If auction type is coldie (reserve) then _startingAmount cant be 0.
    /// @dev _currencyAddress equal to the zero address denotes eth.
    /// @dev All time related params are unix epoch timestamps.
    /// @param _auctionType The type of auction being configured.
    /// @param _originContract Contract address of the asset being put up for auction.
    /// @param _tokenId Token Id of the asset.
    /// @param _startingAmount The reserve price or min bid of an auction.
    /// @param _currencyAddress The currency the auction is being conducted in.
    /// @param _lengthOfAuction The amount of time in seconds that the auction is configured for.
    /// @param _splitAddresses Addresses to split the sellers commission with.
    /// @param _splitRatios The ratio for the split corresponding to each of the addresses being split with.
    function configureAuction(
        bytes32 _auctionType,
        address _originContract,
        uint256 _tokenId,
        uint256 _startingAmount,
        address _currencyAddress,
        uint256 _lengthOfAuction,
        uint256 _startTime,
        address payable[] calldata _splitAddresses,
        uint8[] calldata _splitRatios
    ) external override {
        (bool success, bytes memory data) = auctions888House.delegatecall(
            abi.encodeWithSelector(
                this.configureAuction.selector,
                _auctionType,
                _originContract,
                _tokenId,
                _startingAmount,
                _currencyAddress,
                _lengthOfAuction,
                _startTime,
                _splitAddresses,
                _splitRatios
            )
        );

        require(success, string(data));
    }

    /// @notice Converts an offer into a coldie auction.
    /// @dev Covers use of any currency (0 address is eth).
    /// @dev Only covers converting an offer to a coldie auction.
    /// @dev Cant convert offer if an auction currently exists.
    /// @param _originContract Contract address of the asset.
    /// @param _tokenId Token Id of the asset.
    /// @param _currencyAddress Address of the currency being converted.
    /// @param _amount Amount being converted into an auction.
    /// @param _lengthOfAuction Number of seconds the auction will last.
    /// @param _splitAddresses Addresses that the sellers take in will be split amongst.
    /// @param _splitRatios Ratios that the take in will be split by.
    function convertOfferToAuction(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress,
        uint256 _amount,
        uint256 _lengthOfAuction,
        address payable[] calldata _splitAddresses,
        uint8[] calldata _splitRatios
    ) external override {
        (bool success, bytes memory data) = auctions888House.delegatecall(
            abi.encodeWithSelector(
                this.convertOfferToAuction.selector,
                _originContract,
                _tokenId,
                _currencyAddress,
                _amount,
                _lengthOfAuction,
                _splitAddresses,
                _splitRatios
            )
        );

        require(success, string(data));
    }

    /// @notice Cancels a configured Auction that has not started.
    /// @dev Requires the person sending the message to be the auction creator or token owner.
    /// @param _originContract Contract address of the asset pending auction.
    /// @param _tokenId Token Id of the asset.
    function cancelAuction(address _originContract, uint256 _tokenId)
        external
        override
    {
        (bool success, bytes memory data) = auctions888House.delegatecall(
            abi.encodeWithSelector(
                this.cancelAuction.selector,
                _originContract,
                _tokenId
            )
        );

        require(success, string(data));
    }

    /// @notice Places a bid on a valid auction.
    /// @dev Only the configured currency can be used (Zero address for eth)
    /// @param _originContract Contract address of asset being bid on.
    /// @param _tokenId Token Id of the asset.
    /// @param _currencyAddress Address of currency being used to bid.
    /// @param _amount Amount of the currency being used for the bid.
    function bid(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress,
        uint256 _amount
    ) external payable override {
        (bool success, bytes memory data) = auctions888House.delegatecall(
            abi.encodeWithSelector(
                this.bid.selector,
                _originContract,
                _tokenId,
                _currencyAddress,
                _amount
            )
        );

        require(success, string(data));
    }

    /// @notice Settles an auction that has ended.
    /// @dev Anyone is able to settle an auction since non-input params are used.
    /// @param _originContract Contract address of asset.
    /// @param _tokenId Token Id of the asset.
    function settleAuction(address _originContract, uint256 _tokenId)
        external
        override
    {
        (bool success, bytes memory data) = auctions888House.delegatecall(
            abi.encodeWithSelector(
                this.settleAuction.selector,
                _originContract,
                _tokenId
            )
        );

        require(success, string(data));
    }

    /// @notice Grabs the current auction details for a token.
    /// @param _originContract Contract address of asset.
    /// @param _tokenId Token Id of the asset.
    /** @return Auction Struct: creatorAddress, creationTime, startingTime, lengthOfAuction,
                currencyAddress, minimumBid, auctionType, splitRecipients array, and splitRatios array.
    */
    function getAuctionDetails(address _originContract, uint256 _tokenId)
        external
        view
        override
        returns (
            address,
            uint256,
            uint256,
            uint256,
            address,
            uint256,
            bytes32,
            address payable[] memory,
            uint8[] memory
        )
    {
        Auction memory auction = tokenAuctions[_originContract][_tokenId];

        return (
            auction.auctionCreator,
            auction.creationBlock,
            auction.startingTime,
            auction.lengthOfAuction,
            auction.currencyAddress,
            auction.minimumBid,
            auction.auctionType,
            auction.splitRecipients,
            auction.splitRatios
        );
    }

    function getSalePrice(
        address _originContract,
        uint256 _tokenId,
        address _target
    )
        external
        view
        override
        returns (
            address,
            address,
            uint256,
            address payable[] memory,
            uint8[] memory
        )
    {
        SalePrice memory sp = tokenSalePrices[_originContract][_tokenId][
            _target
        ];

        return (
            sp.seller,
            sp.currencyAddress,
            sp.amount,
            sp.splitRecipients,
            sp.splitRatios
        );
    }
}