// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./VCMarketplaceBase.sol";
import "../interfaces/IArtistNft.sol";
import "../interfaces/IVCStarter.sol";

contract VCMarketplaceAuction is VCMarketplaceBase {
    error MktAlreadyListed();
    error MktExistingBid();
    error MktBidderNotAllowed();
    error MktBidTooLate();
    error MktBidTooLow();
    error MktSettleFailed();
    error MktSettleTooEarly();

    struct AuctionListing {
        bool minted;
        address seller;
        uint256 initialPrice;
        uint256 maturity;
        address highestBidder;
        uint256 highestBid;
        uint256 marketFee;
    }

    event ListedAuction(
        address indexed token,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 initialPrice,
        uint256 marketFee,
        uint256 maturity
    );
    event UnlistedAuction(address indexed seller, address indexed token, uint256 indexed tokenId);
    event Settled(
        address indexed buyer,
        address indexed seller,
        address indexed token,
        uint256 tokenId,
        uint256 endPrice
    );
    event Bid(address indexed bidder, address indexed token, uint256 indexed tokenId, uint256 amount);

    mapping(address => mapping(uint256 => AuctionListing)) public auctionListings;

    constructor(
        address _artistNft,
        address _pool,
        address _starter,
        address _admin,
        uint256 _minTotalFeeBps,
        uint256 _marketplaceFee,
        uint96 _maxBeneficiaryProjects
    )
        VCMarketplaceBase(_artistNft)
        FeeBeneficiary(_pool, _starter, _minTotalFeeBps, _marketplaceFee, _maxBeneficiaryProjects)
    {
        _checkAddress(_admin);
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /**
     * @dev Allows the seller, i.e. msg.sender, to list only ERC1155 NFTs
     * with a given initial price to the Marketplace.
     *
     * @param _tokenId the token identifier
     * @param _initialPrice minimum price set by the seller
     * @param _biddingDuration duration of the auction in seconds
     * @param _projectIds Array of projects identifiers to support on purchases
     * @param _projectFeesBps Array of project fees in basis points on purchases
     */
    function listAuction(
        uint256 _tokenId,
        uint256 _initialPrice,
        uint256 _biddingDuration,
        uint256 _poolFeeBps,
        uint256[] calldata _projectIds,
        uint256[] calldata _projectFeesBps
    ) public whenNotPaused {
        // creator or collector cannot re-list
        if (auctionListings[address(artistNft)][_tokenId].seller != address(0)) {
            revert MktAlreadyListed();
        }

        bool minted = artistNft.exists(_tokenId);

        _checkSupply(minted, _tokenId);

        uint256 marketFee = _toFee(_initialPrice, marketplaceFeeBps);

        _setFees(address(artistNft), _tokenId, msg.sender, _poolFeeBps, _projectIds, _projectFeesBps);

        uint256 maturity = block.timestamp + _biddingDuration;

        _newList(minted, _tokenId, _initialPrice, maturity, marketFee);

        emit ListedAuction(address(artistNft), _tokenId, msg.sender, _initialPrice, marketFee, maturity);
    }

    function _checkSupply(bool _minted, uint256 _tokenId) internal {
        uint256 totalSupply = _minted ? artistNft.totalSupply(_tokenId) : artistNft.lazyTotalSupply(_tokenId);
        require(totalSupply == 1, "Can auction NFTs only");
    }

    function _newList(
        bool minted,
        uint256 _tokenId,
        uint256 _initialPrice,
        uint256 _maturity,
        uint256 marketFee
    ) internal {
        if (!minted) {
            artistNft.requireCanRequestMint(msg.sender, _tokenId, 1);
        } else {
            artistNft.safeTransferFrom(msg.sender, address(this), _tokenId, 1, "");
        }

        auctionListings[address(artistNft)][_tokenId] = AuctionListing(
            minted,
            msg.sender,
            _initialPrice,
            _maturity,
            address(0),
            0,
            marketFee
        );
    }

    /**
     * @dev Cancels the token auction from the Marketplace and sends back the
     * asset to the seller.
     *
     * Requirements:
     *
     * - The token must not have a bid placed, if there is a bid the transaction will fail
     *
     * @param _tokenId the token identifier
     */
    function unlistAuction(uint256 _tokenId) public {
        AuctionListing memory listing = auctionListings[address(artistNft)][_tokenId];

        if (listing.seller != msg.sender) {
            revert MktCallerNotSeller();
        }

        if (listing.highestBid != 0) {
            revert MktExistingBid();
        }

        delete auctionListings[address(artistNft)][_tokenId];

        if (listing.minted) {
            artistNft.safeTransferFrom(address(this), listing.seller, _tokenId, 1, "");
        }

        emit UnlistedAuction(msg.sender, address(artistNft), _tokenId);
    }

    /**
     * @dev Places a bid for a token listed in the Marketplace. If the bid is valid,
     * previous bid amount and its market fee gets returned back to previous bidder,
     * while current bid amount and market fee is charged to current bidder.
     *
     * @param _tokenId the token identifier
     * @param _amount the bid amount
     */
    function bid(uint256 _tokenId, uint256 _amount) public whenNotPaused {
        AuctionListing memory listing = auctionListings[address(artistNft)][_tokenId];

        _checkBeforeBid(listing, _amount);

        if (listing.highestBid != 0) {
            currency.transfer(listing.highestBidder, listing.highestBid + listing.marketFee);
        }

        uint256 marketFee = _toFee(_amount, marketplaceFeeBps);

        currency.transferFrom(msg.sender, address(this), _amount + marketFee);

        listing.highestBidder = msg.sender;
        listing.highestBid = _amount;
        listing.marketFee = marketFee;
        auctionListings[address(artistNft)][_tokenId] = listing;

        emit Bid(msg.sender, address(artistNft), _tokenId, _amount);
    }

    /**
     * @dev Allows anyone to settle the auction. If there are no bids, the seller
     * receives back the NFT
     *
     * @param _tokenId the token identifier
     */
    function settle(uint256 _tokenId) public whenNotPaused {
        AuctionListing memory listing = auctionListings[address(artistNft)][_tokenId];

        _checkBeforeSettle(listing);

        delete auctionListings[address(artistNft)][_tokenId];

        if (listing.highestBid != 0) {
            (uint256 starterFee, uint256 poolFee, uint256 resultingAmount) = _transferFee(
                address(artistNft),
                _tokenId,
                listing.seller,
                currency,
                listing.highestBid,
                listing.marketFee
            );
            resultingAmount -= _transferRoyalty(_tokenId, listing.highestBid);
            if (!currency.transfer(listing.seller, resultingAmount)) {
                revert MktSettleFailed();
            }
            if (!listing.minted) {
                artistNft.mint(_tokenId, 1);
            }
            artistNft.safeTransferFrom(address(this), listing.highestBidder, _tokenId, 1, "");
            pocNft.mint(listing.highestBidder, listing.marketFee);
            pocNft.mint(listing.seller, starterFee + poolFee);
        } else {
            if (listing.minted) {
                artistNft.safeTransferFrom(address(this), listing.seller, _tokenId, 1, "");
            }
        }

        emit Settled(listing.highestBidder, listing.seller, address(artistNft), _tokenId, listing.highestBid);
    }

    function _checkBeforeBid(AuctionListing memory listing, uint256 _amount) internal view {
        if (listing.seller == address(0)) {
            revert MktTokenNotListed();
        }
        if (listing.seller == msg.sender) {
            revert MktBidderNotAllowed();
        }
        if (block.timestamp > listing.maturity) {
            revert MktBidTooLate();
        }
        if (_amount < listing.highestBid || _amount < listing.initialPrice) {
            revert MktBidTooLow();
        }
    }

    function _checkBeforeSettle(AuctionListing memory listing) internal view {
        if (listing.seller == address(0)) {
            revert MktTokenNotListed();
        }
        if (!(block.timestamp > listing.maturity)) {
            revert MktSettleTooEarly();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./FeeBeneficiary.sol";
import "../interfaces/IPoCNft.sol";
import "../interfaces/IVCStarter.sol";
import "../interfaces/IArtistNft.sol";

abstract contract VCMarketplaceBase is FeeBeneficiary, Pausable, ERC1155Holder {
    error MktCallerNotSeller();
    error MktTokenNotListed();
    error MktNotWhitelistedToken();
    error MktRoyaltyChargeFailed();
    error MktRoyaltyTransferFailed();

    /// @notice The Marketplace currency.
    IERC20 public currency;

    /// @notice The Viral(Cure) Proof of Collaboration Non-Fungible Token
    IPoCNft public pocNft;

    /// @notice The Viral(Cure) Artist Non-Fungible Token
    IArtistNft public artistNft;

    /**
     * @dev Sets the whitelisted tokens to be traded at the Marketplace.
     */
    constructor(address _artistNft) {
        artistNft = IArtistNft(_artistNft);
    }

    /**
     * @dev pause or unpause the Marketplace
     */
    function pause(bool _paused) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_paused) _pause();
        else _unpause();
    }

    /**
     * @dev Sets the Proof of Collaboration Non-Fungible Token.
     */
    function setPoCNft(address _pocNft) external onlyRole(DEFAULT_ADMIN_ROLE) {
        pocNft = IPoCNft(_pocNft);
    }

    /**
     * @dev Sets the Marketplace currency.
     */
    function setCurrency(IERC20 _currency) external onlyRole(DEFAULT_ADMIN_ROLE) {
        currency = _currency;
    }

    // IDEA: we left this function just in case, there is no real use for the moment.
    /**
     * @dev Allows the withdrawal of any `ERC20` token from the Marketplace to
     * any account. Can only be called by the owner.
     *
     * Requirements:
     *
     * - Contract balance has to be equal or greater than _amount
     *
     * @param _token: ERC20 token address to withdraw
     * @param _to: Address that will receive the transfer
     * @param _amount: Amount to withdraw
     */
    function withdrawTo(
        address _token,
        address _to,
        uint256 _amount
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(IERC20(_token).balanceOf(address(this)) > _amount);
        IERC20(_token).transfer(_to, _amount);
    }

    function _fundProject(uint256 _projectId, uint256 _amount) internal override {
        IVCStarter(starter).fundProjectFromMarketplace(_projectId, _amount);
    }

    /**
     * @dev Computes the royalty amount and transfers it from sender to the
     * asset creator, i.e. the royalty beneficiary.
     *
     * @param _tokenId: NFT token ID
     * @param _amount: A pertinent amount used to compute the royalty.
     *
     * NOTE: Charges fee to msg.sender, i.e. buyer.
     */
    function _chargeRoyalty(uint256 _tokenId, uint256 _amount) internal returns (uint256) {
        (address receiver, uint256 royaltyAmount) = IERC2981(address(artistNft)).royaltyInfo(_tokenId, _amount);
        if (royaltyAmount > 0) {
            if (!currency.transferFrom(msg.sender, receiver, royaltyAmount)) {
                revert MktRoyaltyChargeFailed();
            }
        }
        return royaltyAmount;
    }

    /**
     * @dev Computes the royalty amount and transfers it from the Marketplace
     * to the asset creator, i.e. the royalty beneficiary.
     *
     * @param _tokenId: NFT token ID
     * @param _amount: A pertinent amount used to compute the royalty.
     *
     * NOTE: Transfer royalty from contract (Market) itself.
     */
    function _transferRoyalty(uint256 _tokenId, uint256 _amount) internal returns (uint256) {
        (address receiver, uint256 royaltyAmount) = IERC2981(address(artistNft)).royaltyInfo(_tokenId, _amount);
        if (royaltyAmount > 0) {
            if (!currency.transfer(receiver, royaltyAmount)) {
                revert MktRoyaltyTransferFailed();
            }
        }
        return royaltyAmount;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC1155Receiver)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IArtistNft is IERC1155 {
    function mint(uint256 _tokenId, uint256 _amount) external;

    function exists(uint256 _tokenId) external returns (bool);

    function totalSupply(uint256 _tokenId) external returns (uint256);

    function lazyTotalSupply(uint256 _tokenId) external returns (uint256);

    function requireCanRequestMint(
        address _by,
        uint256 _tokenId,
        uint256 _amount
    ) external;

    function grantMinterRole(address _address) external;

    function setMaxRoyalty(uint256 _maxRoyaltyBps) external;

    function setMaxBatchSize(uint256 _maxBatchSize) external;

    function grantRole(address _newCreator) external;

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeeBps) external;

    function addCreator(address _creator) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVCStarter {
    function currency() external returns (IERC20);

    function setPoCNft(address _poCNFT) external;

    function setMarketplaceAuction(address _newMarketplace) external;

    function setMarketplaceFixedPrice(address _newMarketplace) external;

    function whitelistLabs(address[] memory _labs) external;

    function setCurrency(IERC20 _currency) external;

    function setQuorumPoll(uint256 _quorumPoll) external;

    function setMaxPollDuration(uint256 _maxPollDuration) external;

    function maxPollDuration() external view returns (uint256);

    function fundProjectFromMarketplace(uint256 _projectId, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

struct TokenFeesData {
    uint256 poolFeeBps;
    uint256 starterFeeBps;
    uint256[] projectIds;
    uint256[] projectFeesBps;
}

error MktFeesDataError();
error MktAddProjectFailed();
error MktRemoveProjectFailed();
error MktTotalFeeTooLow();
error MktVCPoolTransferFailed();
error MktVCStarterTransferFailed();
error MktUnexpectedAddress();
error MktInactiveProject();

contract FeeBeneficiary is AccessControl {
    bytes32 public constant STARTER_ROLE = keccak256("STARTER_ROLE");
    bytes32 public constant POOL_ROLE = keccak256("POOL_ROLE");

    /// @notice The VC Pool contract address
    address public pool;

    /// @notice The VC Starter contract address
    address public starter;

    /// @notice The minimum fee in basis points to distribute amongst VC Pool and VC Starter Projects
    uint256 public minTotalFeeBps;

    /// @notice The VC Marketplace fee in basis points
    uint256 public marketplaceFeeBps;

    /// @notice The maximum amount of projects a token seller can support
    uint96 public maxBeneficiaryProjects;

    /// @notice Used to translate from basis points to amounts
    uint96 public constant FEE_DENOMINATOR = 10_000;

    event ProjectAdded(uint256 indexed projectId, uint256 time);
    event ProjectRemoved(uint256 indexed projectId, uint256 time);

    /**
     * @dev Maps a token and seller to its TokenFeesData struct.
     */
    mapping(address => mapping(uint256 => mapping(address => TokenFeesData))) _tokenFeesData;

    /**
     * @dev Maps a project id to its beneficiary status.
     */
    mapping(uint256 => bool) internal _isActiveProject;

    /**
     * @dev Constructor
     */
    constructor(
        address _pool,
        address _starter,
        uint256 _minTotalFeeBps,
        uint256 _marketplaceFeeBps,
        uint96 _maxBeneficiaryProjects
    ) {
        _checkAddress(_pool);
        _checkAddress(_starter);

        _setMinTotalFeeBps(_minTotalFeeBps);
        _setMarketplaceFeeBps(_marketplaceFeeBps);
        _setMaxBeneficiaryProjects(_maxBeneficiaryProjects);

        _grantRole(POOL_ROLE, _pool);
        _grantRole(STARTER_ROLE, _starter);

        pool = _pool;
        starter = _starter;
    }

    function _checkAddress(address _address) internal view {
        if (_address == address(this) || _address == address(0)) {
            revert MktUnexpectedAddress();
        }
    }

    function setMinTotalFeeBps(uint96 _minTotalFeeBps) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setMinTotalFeeBps(_minTotalFeeBps);
    }

    function _setMinTotalFeeBps(uint256 _minTotalFeeBps) private {
        minTotalFeeBps = _minTotalFeeBps;
    }

    function setMarketplaceFeeBps(uint256 _marketplaceFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setMarketplaceFeeBps(_marketplaceFee);
    }

    function _setMarketplaceFeeBps(uint256 _marketplaceFeeBps) private {
        marketplaceFeeBps = _marketplaceFeeBps;
    }

    function setMaxBeneficiaryProjects(uint96 _maxBeneficiaryProjects) public onlyRole(DEFAULT_ADMIN_ROLE) {
        maxBeneficiaryProjects = _maxBeneficiaryProjects;
    }

    function _setMaxBeneficiaryProjects(uint96 _maxBeneficiaryProjects) private {
        maxBeneficiaryProjects = _maxBeneficiaryProjects;
    }

    /**
     * @dev Adds a project as a beneficiary candidate.
     *
     * @param _projectId the project identifier.
     *
     * NOTE: can only be called by starter or admin.
     */
    // THIS RIGHT NOW CAN BE CALLED ONLY BY STARTER
    function addProject(uint256 _projectId) public onlyRole(STARTER_ROLE) {
        if (_isActiveProject[_projectId]) {
            revert MktAddProjectFailed();
        }
        _isActiveProject[_projectId] = true;
        emit ProjectAdded(_projectId, block.timestamp);
    }

    /**
     * @dev Removes a project as a beneficiary candidate.
     *
     * @param _projectId the project identifier to remove.
     *
     * NOTE: can only be called by starter or admin.
     */
    // THIS RIGHT NOW CAN BE CALLED ONLY BY STARTER
    function removeProject(uint256 _projectId) public onlyRole(STARTER_ROLE) {
        if (!_isActiveProject[_projectId]) {
            revert MktRemoveProjectFailed();
        }
        _isActiveProject[_projectId] = false;
        emit ProjectRemoved(_projectId, block.timestamp);
    }

    /**
     * @dev Returns True if the project is active or False if is not.
     *
     * @param _projectId the project identifier.
     */
    function isActiveProject(uint256 _projectId) public view returns (bool) {
        return _isActiveProject[_projectId];
    }

    /**
     * @dev Constructs a `TokenFeesData` struct which stores the total fees in
     * bips that will be transferred to both the pool and the starter smart
     * contracts.
     *
     * @param _token NFT token address
     * @param _tokenId NFT token ID
     * @param _seller The seller address
     * @param _projectIds Array of Project identifiers to support
     * @param _projectFeesBps Array of fees to support each project ID
     */
    function _setFees(
        address _token,
        uint256 _tokenId,
        address _seller,
        uint256 _poolFeeBps,
        uint256[] calldata _projectIds,
        uint256[] calldata _projectFeesBps
    ) internal {
        if (_projectIds.length != _projectFeesBps.length || _projectIds.length > maxBeneficiaryProjects) {
            revert MktFeesDataError();
        }

        uint256 starterFeeBps;
        for (uint256 i = 0; i < _projectFeesBps.length; i++) {
            if (!_isActiveProject[_projectIds[i]]) {
                revert MktInactiveProject();
            }
            starterFeeBps += _projectFeesBps[i];
        }

        if (_poolFeeBps + starterFeeBps < minTotalFeeBps) {
            revert MktTotalFeeTooLow();
        }

        _tokenFeesData[_token][_tokenId][_seller] = TokenFeesData(
            _poolFeeBps,
            starterFeeBps,
            _projectIds,
            _projectFeesBps
        );
    }

    /**
     * @dev Returns the struct TokenFeesData corresponding to the _token and _tokenId
     *
     * @param _token: Non-fungible token address
     * @param _tokenId: Non-fungible token identifier
     */
    function getFeesData(
        address _token,
        uint256 _tokenId,
        address _seller
    ) public view returns (TokenFeesData memory result) {
        return _tokenFeesData[_token][_tokenId][_seller];
    }

    /**
     * @dev Computes and transfers fees to both the Pool and the Starter smart
     * contracts when the token is sold.
     *
     * @param _token Non-fungible token address
     * @param _tokenId Non-fungible token identifier
     * @param _currency the Marketplace currency
     * @param _listPrice Token fixed price
     *
     * NOTE: Charges fee to msg.sender, i.e. buyer.
     */
    function _chargeFee(
        address _token,
        uint256 _tokenId,
        address _seller,
        IERC20 _currency,
        uint256 _listPrice,
        uint256 _marketFee
    )
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        TokenFeesData memory feesData = _tokenFeesData[_token][_tokenId][_seller];
        (uint256 starterFee, uint256 poolFee, uint256 resultingAmount) = _splitListPrice(feesData, _listPrice);
        if (!_currency.transferFrom(msg.sender, pool, _marketFee + poolFee)) {
            revert MktVCPoolTransferFailed();
        }
        if (starterFee > 0) {
            if (!_currency.transferFrom(msg.sender, address(this), starterFee)) {
                revert MktVCStarterTransferFailed();
            }
            _currency.approve(starter, starterFee);
            _fundProjects(feesData, _listPrice);
        }

        return (starterFee, poolFee, resultingAmount);
    }

    /**
     * @dev Computes and transfers fees to both the Pool and the Starter smart
     * contracts.
     *
     * @param _token Non-fungible token address
     * @param _tokenId Non-fungible token identifier
     * @param _currency the Marketplace currency
     * @param _listPrice Token auction price
     *
     * NOTE: Transfer fee from contract (Marketplace) itself.
     */
    function _transferFee(
        address _token,
        uint256 _tokenId,
        address _seller,
        IERC20 _currency,
        uint256 _listPrice,
        uint256 _marketFee
    )
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        TokenFeesData memory feesData = _tokenFeesData[_token][_tokenId][_seller];
        (uint256 starterFee, uint256 poolFee, uint256 resultingAmount) = _splitListPrice(feesData, _listPrice);
        if (!_currency.transfer(pool, _marketFee + poolFee)) {
            revert MktVCPoolTransferFailed();
        }
        if (starterFee > 0) {
            _currency.approve(starter, starterFee);
            _fundProjects(feesData, _listPrice);
        }

        return (starterFee, poolFee, resultingAmount);
    }

    /**
     * @dev Splits an amount into fees for both Pool and Starter smart
     * contracts and a resulting amount to be transferred to the token
     * owner (i.e. the token seller).
     */
    function _splitListPrice(TokenFeesData memory _feesData, uint256 _listPrice)
        private
        pure
        returns (
            uint256 starterFee,
            uint256 poolFee,
            uint256 resultingAmount
        )
    {
        starterFee = _toFee(_listPrice, _feesData.starterFeeBps);
        poolFee = _toFee(_listPrice, _feesData.poolFeeBps);
        resultingAmount = _listPrice - starterFee - poolFee;
    }

    /**
     * @dev Computes individual fees for each beneficiary project and performs
     * the pertinent accounting at the Starter smart contract.
     */
    function _fundProjects(TokenFeesData memory _feesData, uint256 _listPrice) internal {
        for (uint256 i = 0; i < _feesData.projectFeesBps.length; i++) {
            uint256 amount = _toFee(_listPrice, _feesData.projectFeesBps[i]);
            if (amount > 0) {
                _fundProject(_feesData.projectIds[i], amount);
            }
        }
    }

    /**
     * @dev
     */
    function _fundProject(uint256 _projectId, uint256 _amount) internal virtual {}

    /**
     * @dev Translates a fee in basis points to a fee amount.
     */
    function _toFee(uint256 _amount, uint256 _feeBps) internal pure returns (uint256) {
        return (_amount * _feeBps) / FEE_DENOMINATOR;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IPoCNft {
    function mint(address _user, uint256 _amount) external returns (uint256 _currentTokenId);

    function getVotingPowerBoost(address _user) external view returns (uint256 votingPowerBoost);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}