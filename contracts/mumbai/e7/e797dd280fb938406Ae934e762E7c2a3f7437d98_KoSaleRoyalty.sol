/**
 *Submitted for verification at polygonscan.com on 2022-05-24
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

abstract contract ContextMixin {
    function msgSender() internal view returns (address payable sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

contract Initializable {
    bool inited = false;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
}

contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string public constant ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            bytes(
                "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
            )
        );
    bytes32 internal domainSeperator;

    // supposed to be called once while initializing.
    // one of the contractsa that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(string memory name) internal initializer {
        _setDomainSeperator(name);
    }

    function _setDomainSeperator(string memory name) internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }

        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
            );
    }
}

contract NativeMetaTransaction is EIP712Base {
    bytes32 private constant META_TRANSACTION_TYPEHASH =
        keccak256(
            bytes(
                "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
            )
        );

    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );

    mapping(address => uint256) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] += 1;

        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
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
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    function approve(address to, uint256 tokenId) external;

    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    // Use for checking interface utilisations through the ERC165
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

contract KoSaleRoyalty is NativeMetaTransaction, ContextMixin {
    struct SaleDetails {
        address nft;
        uint256 tokenId;
        address seller;
        uint128 price;
        uint256 endDate;
        address maxBidUser;
    }

    event CreateSale(
        address indexed nft,
        uint256 indexed tokenId,
        bytes32 saleId,
        uint128 price,
        uint256 endDate
    );

    event Bid(address bidder, bytes32 indexed saleId);

    event ExecuteSale(
        address indexed nft,
        uint256 indexed tokenId,
        bytes32 saleId,
        address indexed seller,
        address buyer,
        uint256 amount
    );

    event RefundBid(
        address indexed nft,
        uint256 indexed tokenId,
        bytes32 saleId,
        address indexed bidder,
        uint256 bidValue
    );

    // ERC20 Contract
    address token;

    // Max Sale Duration
    uint32 public maxDuration;

    // Sale Details by ID (bytes32)
    mapping(bytes32 => SaleDetails) public saleDetails;

    // Current Sale ID for NFT (Address Contract + Token ID)
    mapping(address => mapping(uint256 => bytes32)) public currentSale;

    /**
     * @notice KoSale constructor
     * @param name_ EIP712 name value
     * @param token_ Address ERC20 Smart Contract
     * @param maxDuration_ Max Duration in seconds for all sales
     */
    constructor(
        string memory name_,
        address token_,
        uint32 maxDuration_
    ) {
        _initializeEIP712(name_);
        token = token_;
        maxDuration = maxDuration_;
    }

    /**
     * @notice Create an ERC721 Sale
     * @param _nft gallery address of the NFT Token
     * @param _tokenId of the NFT Token
     * @param _price in wei of the NFT token, defined according to the ERC20 token
     * @param _endDate in seconds of the period in which the NFT token will be sold
     */
    function createSale(
        address _nft,
        uint256 _tokenId,
        uint128 _price,
        uint256 _endDate
    ) external {
        require(_price > 0, "Price must greater than zero");

        require(
            _endDate <= (block.timestamp + maxDuration),
            "End date less than now + maxDuration"
        );

        require(
            _endDate > block.timestamp, // Add minDuration of 6-hours(21600) to better listing
            "End date must greater than now"
        );

        // [Proposal] Check if the NFT support the interface of IERC721 through ERC165
        // If so, we can sell safely any NFT that uses IERC721
        require(
            IERC721(_nft).supportsInterface(0x80ac58cd),
            "Your Token doesn't supports the IERC721 or ERC165"
        );

        // Prevents anyone from creating an NFT sale that they don't own.
        require(
            IERC721(_nft).ownerOf(_tokenId) == msgSender(),
            "You must be the owner"
        );

        bytes32 saleId = keccak256(
            abi.encodePacked(_nft, _tokenId, msgSender(), block.timestamp)
        );

        // Initialize Auction Details
        saleDetails[saleId].nft = _nft;
        saleDetails[saleId].tokenId = _tokenId;
        saleDetails[saleId].seller = msgSender();
        saleDetails[saleId].price = uint128(_price);
        saleDetails[saleId].endDate = _endDate;

        // Memorize Current Auction ID
        currentSale[_nft][_tokenId] = saleId;

        emit CreateSale(_nft, _tokenId, saleId, _price, _endDate);
    }

    /**
     *@notice Make an offer on a sale
     * @dev Called by Bidder
     * @param _nft gallery address of the NFT Token
     * @param _tokenId of the NFT Token
     */
    function bid(address _nft, uint256 _tokenId) external {
        bytes32 saleId = currentSale[_nft][_tokenId];
        SaleDetails storage sale = saleDetails[saleId];

        require(
            sale.maxBidUser == address(0),
            "An offer has already been made"
        );
        require(sale.endDate > block.timestamp, "Deadline already passed");

        bool success = IERC20(token).transferFrom(
            msgSender(),
            address(this),
            sale.price
        );
        require(success);

        // Save Buyer address
        sale.maxBidUser = msgSender();

        emit Bid(msgSender(), saleId);
    }

    /**
     * @notice Executes the sale
     * @dev Called by the seller when the sale duration is over or a bid is placed.
     * @param _nft gallery address of the NFT Token
     * @param _tokenId of the NFT Token
     */
    function executeSale(
        address _nft,
        uint256 _tokenId,
        bool _accepted
    ) external {
        bytes32 saleId = currentSale[_nft][_tokenId];
        SaleDetails storage sale = saleDetails[saleId];
        uint256 royalty = 0;

        require(
            sale.seller == msgSender(),
            "Only the seller can execute the sale"
        );
        require(
            sale.maxBidUser != address(0),
            "Can't Execute sale without offer"
        );

        if (_accepted) {
            // _executeSale(saleId);

            // Transfer NFT to buyer
            IERC721(_nft).safeTransferFrom(
                sale.seller,
                sale.maxBidUser,
                _tokenId
            );

            bool royaltyIsSupported = IERC721(_nft).supportsInterface(0x2a55205a);
            if(royaltyIsSupported){
                // Get Royalty Info
                (address receiver, uint256 royaltyAmount) = IERC721(_nft)
                .royaltyInfo(_tokenId, sale.price);

                // Pay the royalties receiver
                if (royaltyAmount > 0) {
                    royalty = royaltyAmount;
                    IERC20(token).transfer(receiver, royaltyAmount);
                }
            }

            // Pay the seller
            bool success = IERC20(token).transfer(
                sale.seller,
                (sale.price - uint128(royalty))
            );
            require(success);

            saleDetails[saleId].endDate = block.timestamp;

            emit ExecuteSale(
                _nft,
                _tokenId,
                saleId,
                sale.seller,
                sale.maxBidUser,
                sale.price
            );
        } else {
            // _cancelSale(saleId);
            bool success = IERC20(token).transfer(sale.maxBidUser, sale.price);
            require(success);

            delete saleDetails[saleId].maxBidUser;
        }
    }

    /**
     * @notice Refund Buyer bid on sale
     * @dev Called by anyone after the end date passed and refund the buyer.
     * @param _saleId ID of sale
     */
    function refundBid(bytes32 _saleId) public {
        SaleDetails storage sale = saleDetails[_saleId];

        require(sale.maxBidUser != address(0), "No refund available");

        require(sale.endDate <= block.timestamp, "Deadline did not pass yet");

        bool success = IERC20(token).transfer(sale.maxBidUser, sale.price);
        require(success);

        emit RefundBid(
            sale.nft,
            sale.tokenId,
            _saleId,
            sale.maxBidUser,
            sale.price
        );

        //Delete value of maxBidUser because the sale is closed and no one buy it
        delete sale.maxBidUser;
    }
}