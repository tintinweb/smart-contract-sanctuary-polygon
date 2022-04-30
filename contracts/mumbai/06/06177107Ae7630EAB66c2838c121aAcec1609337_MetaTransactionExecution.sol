// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MetaTransactionExecution {
    string public constant name = "NFTify";
    string public constant version = "1";

    string public constant BUY_FROM_PRIMARY_SALE = "Buy from primary sale";
    string public constant BUY_FROM_SECONDARY_SALE = "Buy from secondary sale";
    string public constant CANCEL_SALE_ORDER = "Cancel sale order";
    string public constant CANCEL_OFFER = "Cancel offer";
    string public constant CANCEL_BID = "Cancel bid";
    string public constant TRANSFER_NFT = "Transfer NFT";

    bytes32 public constant PRIMARY_SALE_REQUEST =
        keccak256(bytes("PRIMARY_SALE_REQUEST"));
    bytes32 public constant SECONDARY_SALE_REQUEST =
        keccak256(bytes("SECONDARY_SALE_REQUEST"));
    bytes32 public constant CANCEL_SALE_ORDER_REQUEST =
        keccak256(bytes("CANCEL_SALE_ORDER_REQUEST"));
    bytes32 public constant CANCEL_OFFER_REQUEST =
        keccak256(bytes("CANCEL_OFFER_REQUEST"));
    bytes32 public constant CANCEL_BID_REQUEST =
        keccak256(bytes("CANCEL_BID_REQUEST"));
    bytes32 public constant TRANSFER_NFT_REQUEST =
        keccak256(bytes("TRANSFER_NFT_REQUEST"));

    /**
     * * Structure for EIP712Domain
     */
    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    struct Item {
        uint256 tokenID;
        uint256 tokenType;
        address collection;
    }

    /**
     * * Structure for MetaTransaction
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        address targetContract;
        string request;
    }

    /**
     * * Structure for BuyRequest
     */
    struct BuyRequest {
        MetaTransaction metaTx;
        Item item;
        uint256 quantity;
        uint256 price;
        address seller;
        address paymentToken;
    }

    /**
     * * Structure of CancelRequest
     */
    struct CancelSaleOrderRequest {
        MetaTransaction metaTx;
        Item item;
        uint256 quantity;
        uint256 price;
    }

    struct CancelOfferRequest {
        MetaTransaction metaTx;
        Item item;
        uint256 quantity;
        uint256 price;
        uint256 yourOffer;
    }

    struct CancelBidRequest {
        MetaTransaction metaTx;
        Item item;
        uint256 quantity;
        uint256 price;
        uint256 yourBid;
    }

    struct TransferNFTRequest {
        MetaTransaction metaTx;
        Item item;
        uint256 quantity;
        address from;
        address to;
    }

    bytes32 public constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            bytes(
                "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
            )
        );

    bytes32 public constant META_TRANSACTION_TYPEHASH =
        keccak256(
            bytes(
                "MetaTransaction(uint256 nonce,address from,address targetContract,string request)"
            )
        );

    bytes32 public constant ITEM_TYPEHASH =
        keccak256(
            bytes("Item(uint256 tokenID,uint256 tokenType,address collection)")
        );

    bytes32 public constant BUY_REQUEST_TYPEHASH =
        keccak256(
            bytes(
                "BuyRequest(MetaTransaction metaTx,Item item,uint256 quantity,uint256 price,address seller,address paymentToken)MetaTransaction(uint256 nonce,address from,address targetContract,string request)Item(uint256 tokenID,uint256 tokenType,address collection)"
            )
        );

    bytes32 public constant CANCEL_SALE_ORDER_REQUEST_TYPEHASH =
        keccak256(
            bytes(
                "CancelSaleOrderRequest(MetaTransaction metaTx,Item item,uint256 quantity,uint256 price)MetaTransaction(uint256 nonce,address from,address targetContract,string request)Item(uint256 tokenID,uint256 tokenType,address collection)"
            )
        );

    bytes32 public constant CANCEL_OFFER_REQUEST_TYPEHASH =
        keccak256(
            bytes(
                "CancelOfferRequest(MetaTransaction metaTx,Item item,uint256 quantity,uint256 price)MetaTransaction(uint256 nonce,address from,address targetContract,string request)Item(uint256 tokenID,uint256 tokenType,address collection)"
            )
        );

    bytes32 public constant CANCEL_BID_REQUEST_TYPEHASH =
        keccak256(
            bytes(
                "CancelBidRequest(MetaTransaction metaTx,Item item,uint256 quantity,uint256 price)MetaTransaction(uint256 nonce,address from,address targetContract,string request)Item(uint256 tokenID,uint256 tokenType,address collection)"
            )
        );

    bytes32 public constant TRANSFER_NFT_REQUEST_TYPEHASH =
        keccak256(
            bytes(
                "TransferNFTRequest(MetaTransaction metaTx,Item item,uint256 quantity,address from,address to)MetaTransaction(uint256 nonce,address from,address targetContract,string request)Item(uint256 tokenID,uint256 tokenType,address collection)"
            )
        );

    bytes32 public DOMAIN_SEPARATOR =
        keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes("NFTify")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );

    // * Mapping from the account to its current nonce
    mapping(address => uint256) nonces;

    /**
     * @dev Returns the current nonce of the user
     * @param user the user's address
     */
    function getNonce(address user) public view returns (uint256) {
        return nonces[user];
    }

    /**
     * @dev Execute the meta transaction
     * @param data [0] tokenType, [1] tokenID, [2] quantity, [3] price, [4] offer/bid
     * @param addrs [0] userAddress, [1] targetContract, [2] collection, [3] seller, [4] paymentToken
     * @param signatures (0) functionSignature
     * @param requestType requestType
     * @param v v component
     * @param r r component
     * @param s s component
     */
    function executeMetaTransaction(
        uint256[] memory data,
        address[] memory addrs,
        bytes[] memory signatures,
        bytes32 requestType,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[addrs[0]],
            from: addrs[0],
            targetContract: addrs[1],
            request: ""
        });

        Item memory item = Item({
            tokenID: data[1],
            tokenType: data[0],
            collection: addrs[2]
        });

        bytes32 typedDataHash;

        if (requestType == PRIMARY_SALE_REQUEST) {
            metaTx.request = BUY_FROM_PRIMARY_SALE;

            BuyRequest memory buyRequest = BuyRequest({
                metaTx: metaTx,
                item: item,
                quantity: data[2],
                price: data[3],
                seller: addrs[3],
                paymentToken: addrs[4]
            });

            // * Get the hash
            typedDataHash = hash(buyRequest);
        } else if (requestType == CANCEL_SALE_ORDER_REQUEST) {
            metaTx.request = CANCEL_SALE_ORDER;

            CancelSaleOrderRequest
                memory cancelRequest = CancelSaleOrderRequest({
                    metaTx: metaTx,
                    item: item,
                    quantity: data[2],
                    price: data[3]
                });

            // * Get the hash
            typedDataHash = hash(cancelRequest);
        } else if (requestType == CANCEL_OFFER_REQUEST) {
            metaTx.request = CANCEL_OFFER;

            CancelOfferRequest memory cancelRequest = CancelOfferRequest({
                metaTx: metaTx,
                item: item,
                quantity: data[2],
                price: data[3],
                yourOffer: data[4]
            });

            // * Get the hash
            typedDataHash = hash(cancelRequest);
        } else if (requestType == CANCEL_BID_REQUEST) {
            metaTx.request = CANCEL_BID;

            CancelBidRequest memory cancelRequest = CancelBidRequest({
                metaTx: metaTx,
                item: item,
                quantity: data[2],
                price: data[3],
                yourBid: data[4]
            });

            // * Get the hash
            typedDataHash = hash(cancelRequest);
        } else if (requestType == TRANSFER_NFT_REQUEST) {
            metaTx.request = TRANSFER_NFT;

            TransferNFTRequest memory request = TransferNFTRequest({
                metaTx: metaTx,
                item: item,
                quantity: data[2],
                from: addrs[2],
                to: addrs[3]
            });

            typedDataHash = hash(request);
        }

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, typedDataHash)
        );

        require(
            metaTx.from == ecrecover(digest, v, r, s),
            "NFTifyMetaTx: invalid signature"
        );

        nonces[metaTx.from]++;

        (bool success, bytes memory returnData) = metaTx.targetContract.call(
            abi.encodePacked(signatures[0], metaTx.from)
        );

        require(success, "NFTifyMetaTx: function call not success");

        return returnData;
    }

    function hash(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    metaTx.targetContract,
                    keccak256(bytes(metaTx.request))
                )
            );
    }

    function hash(Item memory item) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ITEM_TYPEHASH,
                    item.tokenID,
                    item.tokenType,
                    item.collection
                )
            );
    }

    function hash(BuyRequest memory buyRequest)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    BUY_REQUEST_TYPEHASH,
                    hash(buyRequest.metaTx),
                    hash(buyRequest.item),
                    buyRequest.quantity,
                    buyRequest.price,
                    buyRequest.seller,
                    buyRequest.paymentToken
                )
            );
    }

    function hash(CancelSaleOrderRequest memory cancelRequest)
        internal
        pure
        returns (bytes32)
    {
        return (
            keccak256(
                abi.encode(
                    CANCEL_SALE_ORDER_REQUEST_TYPEHASH,
                    hash(cancelRequest.metaTx),
                    hash(cancelRequest.item),
                    cancelRequest.quantity,
                    cancelRequest.price
                )
            )
        );
    }

    function hash(CancelOfferRequest memory cancelRequest)
        internal
        pure
        returns (bytes32)
    {
        return (
            keccak256(
                abi.encode(
                    CANCEL_OFFER_REQUEST_TYPEHASH,
                    hash(cancelRequest.metaTx),
                    hash(cancelRequest.item),
                    cancelRequest.quantity,
                    cancelRequest.price,
                    cancelRequest.yourOffer
                )
            )
        );
    }

    function hash(CancelBidRequest memory cancelRequest)
        internal
        pure
        returns (bytes32)
    {
        return (
            keccak256(
                abi.encode(
                    CANCEL_BID_REQUEST_TYPEHASH,
                    hash(cancelRequest.metaTx),
                    hash(cancelRequest.item),
                    cancelRequest.quantity,
                    cancelRequest.price,
                    cancelRequest.yourBid
                )
            )
        );
    }

    function hash(TransferNFTRequest memory transferRequest)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    TRANSFER_NFT_REQUEST_TYPEHASH,
                    hash(transferRequest.metaTx),
                    hash(transferRequest.item),
                    transferRequest.quantity,
                    transferRequest.from,
                    transferRequest.to
                )
            );
    }
}