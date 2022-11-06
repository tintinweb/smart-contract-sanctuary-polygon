// SPDX-License-Identifier: ---DG---

pragma solidity =0.8.17;

import "./EIP712MetaTransaction.sol";
import "./AccessController.sol";
import "./TransferHelper.sol";
import "./Interfaces.sol";

contract NFTPurchaser is AccessController, TransferHelper, EIP712MetaTransaction {

    address public paymentToken;

    mapping(uint256 => uint256) public shinePrice;
    mapping(address => mapping(uint256 => uint256)) public buyingPrice;

    uint256 public saleCount;
    uint256 public saleFrame;
    uint256 public saleLimit;

    bool public allowChangeSaleLimit;

    mapping(address => address) public targets;
    mapping(address => uint256) public frames;

    mapping(address => mapping(uint256 => uint256)) public limits;

    event Buy(
        uint256 tokenId,
        uint256 buyCount,
        uint256 finalPrice,
        address indexed tokenOwner,
        address indexed tokenAddress,
        uint256 indexed shineLevel
    );

    event SupplyCheck(
        string rarity,
        uint256 maxSupply,
        uint256 price,
        address beneficiary,
        string indexed metadata,
        string indexed contentHash
    );

    constructor(
        address _paymentToken,
        address _accessoriesContract
    )
        EIP712Base(
            "NFTPurchaser",
            "v1.6"
        )
    {
        saleLimit = 500;
        saleFrame = 1 hours;

        paymentToken = _paymentToken;

        allowChangeSaleLimit = true;
        targets[_accessoriesContract] = _accessoriesContract;
    }

    function changeShinePrice(
        uint256 _shineLevel,
        uint256 _shinePrice
    )
        external
        onlyCEO
    {
        shinePrice[_shineLevel] = _shinePrice;
    }

    function changeBuyingPrice(
        uint256 _itemId,
        address _tokenAddress,
        uint256 _newBuyingPrice
    )
        external
        onlyCEO
    {
        buyingPrice[_tokenAddress][_itemId] = _newBuyingPrice;
    }

    function changeBuyingLimits(
        uint256 _itemId,
        address _tokenAddress,
        uint256 _newLimit
    )
        external
        onlyCEO
    {
        limits[_tokenAddress][_itemId] = _newLimit;
    }

    function changeSaleFrame(
        uint256 _newSaleFrame
    )
        external
        onlyCEO
    {
        saleFrame = _newSaleFrame;
    }

    function changeSaleLimit(
        uint256 _newSaleLimit
    )
        external
        onlyCEO
    {
        require(
            allowChangeSaleLimit == true,
            "NFTPurchaser: DISABLED"
        );

        saleLimit = _newSaleLimit;
    }

    function disabledSaleLimitChange()
        external
        onlyCEO
    {
        allowChangeSaleLimit = false;
    }

    function changePaymentToken(
        address _newPaymentToken
    )
        external
        onlyCEO
    {
        paymentToken = _newPaymentToken;
    }

    function changeTargetContract(
        address _tokenAddress,
        address _accessoriesContract
    )
        external
        onlyCEO
    {
        targets[_tokenAddress] = _accessoriesContract;
    }

    function purchaseToken(
        uint256 _itemId,
        address _buyerAddress,
        address _tokenAddress,
        uint256 _shineLevel
    )
        external
    {
        require(
            saleLimit > saleCount,
            "NFTPurchaser: SOLD_OUT"
        );

        unchecked {
            saleCount =
            saleCount + 1;
        }

        require(
            limits[_tokenAddress][_itemId] > 0,
            "NFTPurchaser: ITEM_LIMITED"
        );

        unchecked {
            limits[_tokenAddress][_itemId] =
            limits[_tokenAddress][_itemId] - 1;
        }

        require(
            canPurchaseAgain(_buyerAddress),
            "NFTPurchaser: COOL_DOWN_DETECTED"
        );

        uint256 itemPrice = buyingPrice[_tokenAddress][_itemId];

        require(
            itemPrice > 0,
            "NFTPurchaser: UNPRICED_ITEM"
        );

        if (_shineLevel > 0) {

            uint256 extraPrice = shinePrice[_shineLevel];

            require(
                extraPrice > 0,
                "NFTPurchaser: UNPRICED_SHINE"
            );

            itemPrice = itemPrice + extraPrice;
        }

        frames[_buyerAddress] = block.timestamp;

        safeTransferFrom(
            paymentToken,
            msgSender(),
            ceoAddress,
            itemPrice
        );

        DGAccessories target = DGAccessories(
            targets[_tokenAddress]
        );

        uint256 newTokenId = target.encodeTokenId(
            _itemId,
            getSupply(_itemId, targets[_tokenAddress]) + 1
        );

        address[] memory beneficiaries = new address[](1);
        beneficiaries[0] = _buyerAddress;

        uint256[] memory itemIds = new uint256[](1);
        itemIds[0] = _itemId;

        target.issueTokens(
            beneficiaries,
            itemIds
        );

        emit Buy(
            newTokenId,
            saleCount,
            itemPrice,
            _buyerAddress,
            _tokenAddress,
            _shineLevel
        );
    }

    function canPurchaseAgain(
        address _buyerAddress
    )
        public
        view
        returns (bool)
    {
        return block.timestamp - frames[_buyerAddress] > saleFrame;
    }

    function getSupply(
        uint256 _itemId,
        address _accessoriesContract
    )
        public
        returns (uint256)
    {
        (   string memory rarity,
            uint256 maxSupply,
            uint256 totalSupply,
            uint256 price,
            address beneficiary,
            string memory metadata,
            string memory contentHash

        ) = DGAccessories(_accessoriesContract).items(_itemId);

        emit SupplyCheck(
            rarity,
            maxSupply,
            price,
            beneficiary,
            metadata,
            contentHash
        );

        return totalSupply;
    }
}