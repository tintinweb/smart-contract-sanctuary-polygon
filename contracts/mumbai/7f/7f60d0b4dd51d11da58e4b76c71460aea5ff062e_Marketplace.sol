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
        SUCCESS
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

    IERC721 _heroToken;
    IERC20 _token;

    mapping(uint256 => OMarketItem) private _mMarketItems;

    uint256 private _commissionFee;
    uint256 private _minListingPrice;
    address _owner;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address owner,
        address heroAddress,
        address tokenAddress
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

        _heroToken = IERC721(heroAddress);
        _token = IERC20(tokenAddress);
        _commissionFee = 1;
        _minListingPrice = 10**18;
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
        emit EWithdrawCommissionFee(_owner, address(this).balance);
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
        require(_heroToken.ownerOf(tokenId) == msg.sender, "NOT_OWNER_NFT");
        OMarketItem memory _omi = _mMarketItems[tokenId];
        require(_omi.status != ItemStatus.LISTING, "ITEM_IN_LISTING");
        require(price >= _minListingPrice, "MIN_LISTING_PRICE");
        _mMarketItems[tokenId] = OMarketItem(
            tokenId,
            price,
            msg.sender,
            address(this),
            ItemStatus.LISTING
        );
        _heroToken.transferFrom(msg.sender, address(this), tokenId);
        emit EListingMarketItem(
            tokenId,
            price,
            msg.sender,
            address(this),
            ItemStatus.LISTING
        );
    }

    function changeListingPriceItem(uint256 tokenId, uint256 price) public {
        OMarketItem storage _omi = _mMarketItems[tokenId];
        require(_omi.seller == msg.sender, "NOT_OWNER_NFT");
        require(_omi.status == ItemStatus.LISTING, "ITEM_NOT_IN_LISTING");
        require(price >= _minListingPrice, "MIN_LISTING_PRICE");
        _omi.price = price;
        emit EChangeListingPriceItem(tokenId, price, msg.sender);
    }

    function saleMarketItem(uint256 tokenId) public {
        OMarketItem storage _omi = _mMarketItems[tokenId];
        require(_omi.status == ItemStatus.LISTING, "ITEM_NOT_IN_LISTING");
        require(_omi.seller != msg.sender, "NOT_BUY_YOURSELF");
        require(
            _token.balanceOf(msg.sender) > _omi.price,
            "INSUFFICIENT_BALANCE"
        );
        uint256 _fee = _omi.price.mul(_commissionFee).div(1000);
        _omi.owner = msg.sender;
        _omi.status = ItemStatus.SUCCESS;
        _token.transfer(address(this), _fee);
        _token.transfer(_omi.seller, _omi.price.sub(_fee));
        _heroToken.transferFrom(address(this), msg.sender, _omi.tokenId);
        emit ESaleMarketItem(
            _omi.tokenId,
            _fee,
            msg.sender,
            ItemStatus.SUCCESS
        );
    }

    function cancelMarketItem(uint256 tokenId) public {
        OMarketItem storage _omi = _mMarketItems[tokenId];
        require(_omi.status == ItemStatus.LISTING, "ITEM_NOT_IN_LISTING");
        require(_omi.seller == msg.sender, "NOT_OWN_ITEM");
        _omi.owner = msg.sender;
        _omi.status = ItemStatus.CANCELLED;
        _heroToken.transferFrom(address(this), msg.sender, _omi.tokenId);
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

    /**
     * @dev function return current verion of smart contract
     */
    function version() public pure returns (string memory) {
        return "v1.0!";
    }
}