// SPDX-License-Identifier: ---DG---

pragma solidity =0.8.14;

import "./EIP712MetaTransaction.sol";
import "./AccessController.sol";
import "./TransferHelper.sol";
import "./Interfaces.sol";

contract NFTPurchaser is AccessController, TransferHelper, EIP712MetaTransaction {

    uint256 public buyingPrice;
    address public paymentToken;

    uint256 public saleCount;
    uint256 public saleFrame;
    uint256 public saleLimit;

    bool public allowChangeSaleLimit;

    mapping (address => address) public targets;
    mapping (address => uint256) public frames;
    mapping (uint256 => uint256) public limits;

    event Buy(
        uint256 indexed tokenId,
        uint256 indexed buyCount,
        address indexed tokenOwner
    );

    event SupplyCheck(
        string rarity,
        uint256 maxSupply,
        uint256 price,
        address indexed beneficiary,
        string indexed metadata,
        string indexed contentHash
    );

    constructor(
        uint256 _buyingPrice,
        address _paymentToken,
        address _accessoriesContract
    )
        EIP712Base("NFTPurchaser", "v1.5")
    {
        saleLimit = 500;
        saleFrame = 1 hours;

        paymentToken = _paymentToken;
        buyingPrice = _buyingPrice;

        allowChangeSaleLimit = true;
        targets[_accessoriesContract] = _accessoriesContract;

        limits[0] = 100;
    }

    function changeBuyingPrice(
        uint256 _newBuyingPrice
    )
        external
        onlyCEO
    {
        buyingPrice = _newBuyingPrice;
    }

    function changeBuyingLimits(
        uint256 _itemId,
        uint256 _newLimit
    )
        external
        onlyCEO
    {
        limits[_itemId] = _newLimit;
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
        address _tokenAddress
    )
        external
        onlyWorker
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
            limits[_itemId] > 0,
            "NFTPurchaser: LIMITED"
        );

        unchecked {
            limits[_itemId] =
            limits[_itemId] - 1;
        }

        require(
            canPurchaseAgain(_buyerAddress),
            "NFTPurchaser: COOL_DOWN_DETECTED"
        );

        address workerCaller = msg.sender;
        frames[_buyerAddress] = block.timestamp;

        safeTransferFrom(
            paymentToken,
            workerCaller,
            ceoAddress,
            buyingPrice
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
            _buyerAddress
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