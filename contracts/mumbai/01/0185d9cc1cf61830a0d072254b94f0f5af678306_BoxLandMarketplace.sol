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

contract BoxLandMarketplace is
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

    IERC721 boxLand;
    IERC20 token;

    mapping(uint256 => OMarketItem) private mMarketItems;

    uint256 private commissionFee;
    uint256 private minListingPrice;
    address owner;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _owner,
        address _token,
        address _boxLand
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

        boxLand = IERC721(_boxLand);
        token = IERC20(_token);
        commissionFee = 1; // 1%
        minListingPrice = 10**18; // 1 PDR
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
        uint256 amount = address(this).balance;
        token.transferFrom(address(this), owner, amount);
        emit EWithdrawCommissionFee(owner, amount);
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
        require(boxLand.ownerOf(_tokenId) == msg.sender, "NOT_OWNER_NFT");
        OMarketItem memory omi = mMarketItems[_tokenId];
        require(omi.status != ItemStatus.LISTING, "ITEM_IN_LISTING");
        require(_price >= minListingPrice, "MIN_LISTING_PRICE");
        mMarketItems[_tokenId] = OMarketItem(
            _tokenId,
            _price,
            msg.sender,
            address(this),
            ItemStatus.LISTING
        );
        boxLand.transferFrom(msg.sender, address(this), _tokenId);
        emit EListingMarketItem(
            _tokenId,
            _price,
            msg.sender,
            address(this),
            ItemStatus.LISTING
        );
    }

    function saleMarketItem(uint256 tokenId) public {
        OMarketItem storage omi = mMarketItems[tokenId];
        require(omi.status == ItemStatus.LISTING, "ITEM_NOT_IN_LISTING");
        require(omi.seller != msg.sender, "NOT_BUY_YOURSELF");
        require(
            token.balanceOf(msg.sender) > omi.price,
            "INSUFFICIENT_BALANCE"
        );
        uint256 fee = omi.price.mul(commissionFee).div(1000);
        omi.owner = msg.sender;
        omi.status = ItemStatus.SUCCESS;
        token.transferFrom(msg.sender, address(this), fee);
        token.transferFrom(msg.sender, omi.seller, omi.price.sub(fee));
        boxLand.transferFrom(address(this), msg.sender, omi.tokenId);
        emit ESaleMarketItem(omi.tokenId, fee, msg.sender, ItemStatus.SUCCESS);
    }

    function cancelMarketItem(uint256 tokenId) public {
        OMarketItem storage _omi = mMarketItems[tokenId];
        require(_omi.status == ItemStatus.LISTING, "ITEM_NOT_IN_LISTING");
        require(_omi.seller == msg.sender, "NOT_OWN_ITEM");
        _omi.owner = msg.sender;
        _omi.status = ItemStatus.CANCELLED;
        boxLand.transferFrom(address(this), msg.sender, _omi.tokenId);
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
        return mMarketItems[tokenId];
    }

    function getCommissionFee() public view returns (uint256) {
        return commissionFee;
    }

    function getMinListingPrice() public view returns (uint256) {
        return minListingPrice;
    }

    function getBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
     * @dev function return current verion of smart contract
     */
    function version() public pure returns (string memory) {
        return "v1.0!";
    }
}