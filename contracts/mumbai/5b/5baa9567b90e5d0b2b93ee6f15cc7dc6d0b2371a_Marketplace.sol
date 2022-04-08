// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./SafeMath.sol";
import "./IERC721.sol";

contract Marketplace is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    using SafeMath for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    enum EnItemStatus {
        DEFAULT,
        CANCELLED,
        LISTING,
        BOUGHT
    }

    event EListingMarketItem(
        uint256 indexed _tokenId,
        uint256 _price,
        address _seller,
        address _owner,
        EnItemStatus _status
    );

    event ESaleMarketItem(
        uint256 indexed _tokenId,
        uint256 _fee,
        uint256 _creatorEarning,
        address _buyer,
        EnItemStatus _status
    );

    event ECancelMarketItem(
        uint256 indexed _tokenId,
        address _owner,
        EnItemStatus _status
    );

    event ETransferAdmin(address _admin, address _newAdmin);
    event ESetCommissionFee(address _operator, uint256 _commissionFee);
    event EMinListingPrice(address _operator, uint256 _minListingPrice);
    event ESetCreatorEarning(address _by, uint256 _tokenId, uint256 _fee);

    struct OMarketItem {
        uint256 tokenId;
        uint256 price;
        address seller;
        address owner;
        EnItemStatus status;
    }

    struct OCreator {
        address creator;
        uint256 creatorEarning;
    }

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    IERC721 INFTToken;

    mapping(uint256 => OMarketItem) private mMarketItems;
    mapping(uint256 => OCreator) private mCreator;

    uint256 private commissionFee;
    uint256 private minListingPrice;
    address owner;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address _owner, address _NFTAddress)
        public
        initializer
    {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(PAUSER_ROLE, _owner);
        _grantRole(UPGRADER_ROLE, _owner);
        _grantRole(OPERATOR_ROLE, _owner);

        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        INFTToken = IERC721(_NFTAddress);
        commissionFee = 5;
        minListingPrice = 0.0001 ether;
        owner = _owner;
    }

    function transferAdmin(address _admin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_admin != address(0), "ZERO_ADDRESS");
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        owner = _admin;
        emit ETransferAdmin(msg.sender, _admin);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function setCommissionFee(uint256 _commissionFee)
        public
        onlyRole(OPERATOR_ROLE)
    {
        commissionFee = _commissionFee;
        emit ESetCommissionFee(msg.sender, _commissionFee);
    }

    function setMinListingPrice(uint256 _minListingPrice)
        public
        onlyRole(OPERATOR_ROLE)
    {
        minListingPrice = _minListingPrice;
        emit EMinListingPrice(msg.sender, _minListingPrice);
    }

    function firstListMarketItem(uint256 _tokenId, uint256 _price, uint256 _creatorEarning) public {
        require(INFTToken.ownerOf(_tokenId) == msg.sender, "NOT_OWNER_NFT");
        OMarketItem memory _omi = mMarketItems[_tokenId];
        require(_omi.status != EnItemStatus.LISTING, "ITEM_IN_LISTING");
        require(_price >= minListingPrice, "MIN_LISTING_PRICE");

        OCreator memory _oc = mCreator[_tokenId];
        require(_oc.creatorEarning == 0, "SETTED_CREATOR_EARNING");
        require(_creatorEarning <= 10, "CREATOR_EARNING_OVER_LIMIT");
        mCreator[_tokenId] = OCreator(msg.sender, _creatorEarning);

        mMarketItems[_tokenId] = OMarketItem(
            _tokenId,
            _price,
            msg.sender,
            address(this),
            EnItemStatus.LISTING
        );

        INFTToken.transferFrom(msg.sender, address(this), _tokenId);

        emit EListingMarketItem(
            _tokenId,
            _price,
            msg.sender,
            address(this),
            EnItemStatus.LISTING
        );
    }

    function listMarketItem(uint256 _tokenId, uint256 _price) public {
        require(INFTToken.ownerOf(_tokenId) == msg.sender, "NOT_OWNER_NFT");
        OMarketItem memory _omi = mMarketItems[_tokenId];
        require(_omi.status != EnItemStatus.LISTING, "ITEM_IN_LISTING");
        require(_price >= minListingPrice, "MIN_LISTING_PRICE");

        mMarketItems[_tokenId] = OMarketItem(
            _tokenId,
            _price,
            msg.sender,
            address(this),
            EnItemStatus.LISTING
        );

        INFTToken.transferFrom(msg.sender, address(this), _tokenId);

        emit EListingMarketItem(
            _tokenId,
            _price,
            msg.sender,
            address(this),
            EnItemStatus.LISTING
        );
    }

    function saleMarketItem(uint256 _tokenId) public payable {
        OMarketItem storage _omi = mMarketItems[_tokenId];
        require(_omi.status == EnItemStatus.LISTING, "ITEM_NOT_IN_LISTING");
        require(_omi.seller != msg.sender, "NOT_BUY_YOURSELF");
        require(msg.value == _omi.price, "MISSING_ASKING_PRICE");
        require(msg.sender.balance > msg.value, "INSUFFICIENT_BALANCE");

        uint256 _fee = _omi.price.mul(commissionFee).div(100);
        uint256 _creatorEarning = 0;

        _omi.owner = msg.sender;
        _omi.status = EnItemStatus.BOUGHT;

        payable(_omi.seller).transfer(_omi.price.sub(_fee));
        payable(owner).transfer(_fee);

        OCreator memory _oc = mCreator[_tokenId];
        if (_oc.creatorEarning > 0) {
            _creatorEarning = _omi.price.mul(_oc.creatorEarning).div(100);
            payable(_oc.creator).transfer(_creatorEarning);
        }

        INFTToken.transferFrom(address(this), msg.sender, _omi.tokenId);

        emit ESaleMarketItem(
            _omi.tokenId,
            _fee,
            _creatorEarning,
            msg.sender,
            EnItemStatus.BOUGHT
        );
    }

    function cancelMarketItem(uint256 _tokenId) public {
        OMarketItem storage _omi = mMarketItems[_tokenId];
        require(_omi.status == EnItemStatus.LISTING, "ITEM_NOT_IN_LISTING");
        require(_omi.seller == msg.sender, "NOT_OWN_ITEM");

        _omi.owner = msg.sender;
        _omi.status = EnItemStatus.CANCELLED;

        INFTToken.transferFrom(address(this), msg.sender, _omi.tokenId);

        emit ECancelMarketItem(
            _omi.tokenId,
            msg.sender,
            EnItemStatus.CANCELLED
        );
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    function getMarketItemByTokenId(uint256 _tokenId)
        public
        view
        returns (OMarketItem memory)
    {
        return mMarketItems[_tokenId];
    }

    function getCommissionFee() public view returns (uint256) {
        return commissionFee;
    }
    /**
     * @dev function return current verion of smart contract
     */
    function version() public pure returns (string memory) {
        return "v1.0!";
    }
}