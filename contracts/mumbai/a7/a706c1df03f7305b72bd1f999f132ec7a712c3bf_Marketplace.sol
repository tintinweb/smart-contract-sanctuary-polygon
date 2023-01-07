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

    enum ItemStatus {
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
        ItemStatus _status
    );

    event ESaleMarketItem(
        uint256 indexed _tokenId,
        uint256 _fee,
        address _buyer,
        ItemStatus _status
    );

    event ECancelMarketItem(
        uint256 indexed _tokenId,
        address _owner,
        ItemStatus _status
    );

    event ETransferAdmin(address _admin, address _newAdmin);
    event ESetCommissionFee(address _operator, uint256 _commissionFee);
    event EMinListingPrice(address _operator, uint256 _minListingPrice);
    event ESetCreatorEarning(address _by, uint256 _tokenId, uint256 _fee);
    event EWithdrawCommissionFee(address _owner, uint256 _amount);

    event EChangeListingPriceItem(
        uint256 indexed _tokenId,
        uint256 _price,
        address _seller
    );

    struct OMarketItem {
        uint256 tokenId;
        uint256 price;
        address seller;
        address owner;
        ItemStatus status;
    }

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    IERC721 INFTToken;

    mapping(uint256 => OMarketItem) private mMarketItems;

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
        commissionFee = 50;
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

    function withdrawCommissionFee() public onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(owner).transfer(address(this).balance);
        emit EWithdrawCommissionFee(owner, address(this).balance);
    }

    function setOperatorRole(address _operator)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_operator != address(0), "ZERO_ADDRESS");
        _grantRole(OPERATOR_ROLE, _operator);
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

    function listMarketItem(uint256 _tokenId, uint256 _price) public {
        require(INFTToken.ownerOf(_tokenId) == msg.sender, "NOT_OWNER_NFT");
        OMarketItem memory _omi = mMarketItems[_tokenId];
        require(_omi.status != ItemStatus.LISTING, "ITEM_IN_LISTING");
        require(_price >= minListingPrice, "MIN_LISTING_PRICE");

        mMarketItems[_tokenId] = OMarketItem(
            _tokenId,
            _price,
            msg.sender,
            address(this),
            ItemStatus.LISTING
        );

        INFTToken.transferFrom(msg.sender, address(this), _tokenId);

        emit EListingMarketItem(
            _tokenId,
            _price,
            msg.sender,
            address(this),
            ItemStatus.LISTING
        );
    }

    function changeListingPriceItem(uint256 _tokenId, uint256 _price) public {
        OMarketItem storage _omi = mMarketItems[_tokenId];
        require(_omi.seller == msg.sender, "NOT_OWNER_NFT");
        require(_omi.status == ItemStatus.LISTING, "ITEM_NOT_IN_LISTING");
        require(_price >= minListingPrice, "MIN_LISTING_PRICE");
        _omi.price = _price;
        emit EChangeListingPriceItem(_tokenId, _price, msg.sender);
    }

    function saleMarketItem(uint256 _tokenId) public payable {
        OMarketItem storage _omi = mMarketItems[_tokenId];
        require(_omi.status == ItemStatus.LISTING, "ITEM_NOT_IN_LISTING");
        require(_omi.seller != msg.sender, "NOT_BUY_YOURSELF");
        require(msg.value == _omi.price, "MISSING_ASKING_PRICE");
        require(msg.sender.balance > msg.value, "INSUFFICIENT_BALANCE");

        uint256 _fee = _omi.price.mul(commissionFee).div(1000);

        _omi.owner = msg.sender;
        _omi.status = ItemStatus.BOUGHT;

        payable(_omi.seller).transfer(_omi.price.sub(_fee));
        payable(address(this)).transfer(_fee);

        INFTToken.transferFrom(address(this), msg.sender, _omi.tokenId);

        emit ESaleMarketItem(_omi.tokenId, _fee, msg.sender, ItemStatus.BOUGHT);
    }

    function cancelMarketItem(uint256 _tokenId) public {
        OMarketItem storage _omi = mMarketItems[_tokenId];
        require(_omi.status == ItemStatus.LISTING, "ITEM_NOT_IN_LISTING");
        require(_omi.seller == msg.sender, "NOT_OWN_ITEM");

        _omi.owner = msg.sender;
        _omi.status = ItemStatus.CANCELLED;

        INFTToken.transferFrom(address(this), msg.sender, _omi.tokenId);

        emit ECancelMarketItem(_omi.tokenId, msg.sender, ItemStatus.CANCELLED);
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