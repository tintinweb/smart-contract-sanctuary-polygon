// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./SafeMath.sol";
import "./IERC721.sol";
import "./IERC20.sol";

contract BoxHeroMarketplace is
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
        SUCCESS
    }

    event EListingMarketItem(
        uint256 indexed tokenId,
        uint256 price,
        address seller,
        address owner,
        ItemStatus status
    );

    event ESaleMarketItem(
        uint256 indexed tokenId,
        uint256 fee,
        address buyer,
        ItemStatus status
    );

    event ECancelMarketItem(
        uint256 indexed tokenId,
        address owner,
        ItemStatus status
    );

    event ETransferAdmin(address admin, address newAdmin);
    event ESetCommissionFee(address operator, uint256 commissionFee);
    event EMinListingPrice(address operator, uint256 minListingPrice);
    event ESetCreatorEarning(address by, uint256 tokenId, uint256 fee);
    event EWithdrawCommissionFee(address owner, uint256 amount);

    event EChangeListingPriceItem(
        uint256 indexed tokenId,
        uint256 price,
        address seller
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

    IERC721 _boxHero;
    IERC20 _token;

    mapping(uint256 => OMarketItem) private _mMarketItems;

    uint256 private _commissionFee;
    uint256 private _minListingPrice;
    address _owner;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address owner,
        address token,
        address boxHero
    ) public initializer {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(PAUSER_ROLE, owner);
        _grantRole(UPGRADER_ROLE, owner);
        _grantRole(OPERATOR_ROLE, owner);

        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        _boxHero = IERC721(boxHero);
        _token = IERC20(token);
        _commissionFee = 1; // 1%
        _minListingPrice = 10**18; // 1 PDR
        _owner = owner;
    }

    function transferAdmin(address admin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(admin != address(0), "ZERO_ADDRESS");
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _owner = admin;
        emit ETransferAdmin(msg.sender, admin);
    }

    function withdrawCommissionFee() public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 _amount = address(this).balance;
        _token.transferFrom(address(this), _owner, _amount);
        emit EWithdrawCommissionFee(_owner, _amount);
    }

    function setOperatorRole(address operator)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(operator != address(0), "ZERO_ADDRESS");
        _grantRole(OPERATOR_ROLE, operator);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function setCommissionFee(uint256 commissionFee)
        public
        onlyRole(OPERATOR_ROLE)
    {
        _commissionFee = commissionFee;
        emit ESetCommissionFee(msg.sender, commissionFee);
    }

    function setMinListingPrice(uint256 minListingPrice)
        public
        onlyRole(OPERATOR_ROLE)
    {
        _minListingPrice = minListingPrice;
        emit EMinListingPrice(msg.sender, minListingPrice);
    }

    function listMarketItem(uint256 tokenId, uint256 price) public {
        require(_boxHero.ownerOf(tokenId) == msg.sender, "NOT_OWNER_NFT");
        OMarketItem memory omi = _mMarketItems[tokenId];
        require(omi.status != ItemStatus.LISTING, "ITEM_IN_LISTING");
        require(price >= _minListingPrice, "MIN_LISTING_PRICE");
        _mMarketItems[tokenId] = OMarketItem(
            tokenId,
            price,
            msg.sender,
            address(this),
            ItemStatus.LISTING
        );
        _boxHero.transferFrom(msg.sender, address(this), tokenId);
        emit EListingMarketItem(
            tokenId,
            price,
            msg.sender,
            address(this),
            ItemStatus.LISTING
        );
    }

    function saleMarketItem(uint256 tokenId) public {
        OMarketItem storage omi = _mMarketItems[tokenId];
        require(omi.status == ItemStatus.LISTING, "ITEM_NOT_IN_LISTING");
        require(omi.seller != msg.sender, "NOT_BUY_YOURSELF");
        require(
            _token.balanceOf(msg.sender) > omi.price,
            "INSUFFICIENT_BALANCE"
        );
        uint256 fee = omi.price.mul(_commissionFee).div(1000);
        omi.owner = msg.sender;
        omi.status = ItemStatus.SUCCESS;
        _token.transferFrom(msg.sender, address(this), fee);
        _token.transferFrom(msg.sender, omi.seller, omi.price.sub(fee));
        _boxHero.transferFrom(address(this), msg.sender, omi.tokenId);
        emit ESaleMarketItem(omi.tokenId, fee, msg.sender, ItemStatus.SUCCESS);
    }

    function cancelMarketItem(uint256 tokenId) public {
        OMarketItem storage _omi = _mMarketItems[tokenId];
        require(_omi.status == ItemStatus.LISTING, "ITEM_NOT_IN_LISTING");
        require(_omi.seller == msg.sender, "NOT_OWN_ITEM");
        _omi.owner = msg.sender;
        _omi.status = ItemStatus.CANCELLED;
        _boxHero.transferFrom(address(this), msg.sender, _omi.tokenId);
        emit ECancelMarketItem(_omi.tokenId, msg.sender, ItemStatus.CANCELLED);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    function getMarketItemByTokenId(uint256 tokenId)
        public
        view
        returns (OMarketItem memory)
    {
        return _mMarketItems[tokenId];
    }

    function getCommissionFee() public view returns (uint256) {
        return _commissionFee;
    }

    function getMinListingPrice() public view returns (uint256) {
        return _minListingPrice;
    }

    function getBalance() public view returns (uint256) {
        return _token.balanceOf(address(this));
    }

    /**
     * @dev function return current verion of smart contract
     */
    function version() public pure returns (string memory) {
        return "v1.0!";
    }
}