/**
 *Submitted for verification at polygonscan.com on 2022-04-12
*/

// Sources flattened with hardhat v2.8.4 https://hardhat.org
// SPDX-License-Identifier: MIT
// File @openzeppelin/contracts/token/ERC20/[email protected]

// License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}


// File @openzeppelin/contracts/utils/introspection/[email protected]

// License-Identifier: MIT
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


// File @openzeppelin/contracts/token/ERC721/[email protected]

// License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}


// File @openzeppelin/contracts/interfaces/[email protected]

// License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;


// File @openzeppelin/contracts/interfaces/[email protected]

// License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

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
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}


// File contracts/ILazyMint.sol

// License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILazyMint {
    function lazyMint(uint256 tokenId, uint256 royaltyFraction) external;
}


// File contracts/HbNftDex.sol

// License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

// import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

// import "./libs/order.sol";
// import "hardhat/console.sol";



contract HbNftDex {

    bytes32 public HashEIP712Domain = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );
    bytes32 public HashOrderSturct = keccak256(
        "FixedPriceOrder(address taker,address maker,uint256 maker_nonce,uint64 listing_time,uint64 expiration_time,address nft_contract,uint256 token_id,address payment_token,uint256 fixed_price,uint256 royalty_rate,address royalty_recipient)"
    );
    bytes32 public HashEIP712Version;
    bytes32 public HashEIP712Name;
    string public name;
    string public version;
    address public daoOwner;
    address public hbNFT;
    uint256 constant public feeDenominator = 10000;
    uint256 public feeRate = 30;  // 30/10000 == 0.3%
    address public feeRecipient;
    // uint256 public minFee;

    /* support contracts. */
    mapping(address => bool) public allowedNftContracts;
    bool public isAllowAllNftContracts;

    /* Finalized orders, by hash. */
    mapping(bytes32 => bool) public finalizedOrder;

    /* user operate times */
    mapping(address => uint256) public userNonce;

    /* Canceled orders, by hash. */
    mapping(address => mapping(bytes32 => bool)) private userCanceledOrder;

    struct Sig {
        /* v parameter */
        uint8 v;
        /* r parameter */
        bytes32 r;
        /* s parameter */
        bytes32 s;
    }

    /* 挂单类型: FixedPrice; EnglishAuction; DutchAuction */
    struct FixedPriceOrder {
        /* 订单taker，表示只与特定的taker进行交易，Address(0)表示同意与任意地址进行交易 */
        address taker;
        /* 订单maker. */
        address maker;
        /* nonce */
        uint256 maker_nonce;
        /* 挂单时间 */
        uint64 listing_time;
        /* 失效时间 */
        uint64 expiration_time;
        /* NFT 地址 */
        address nft_contract;
        /* NFT tokenId  */
        uint256 token_id;
        /* 支付代币地址, 如果用本币支付, 设置为address(0). */
        address payment_token;
        /* 如果order_type是FixedPrice, 即为成交价; 如果是拍卖, 按拍卖方式定义 */
        uint256 fixed_price;
        /* 版税比例 */
        uint256 royalty_rate;
        /* 版税接收地址 */
        address royalty_recipient;
    }

    /* 订单取消事件 */
    event OrderCancelled(address indexed maker, bytes32 indexed hash);
    /* 订单成交事件 */
    event FixedPriceOrderMatched(
        address tx_origin,
        address taker,
        address maker,
        bytes32 order_digest,
        bytes order_bytes
    );

    /* 取消所有的挂单 */
    event AllOrdersCancelled(address indexed maker, uint256 currentNonce);
    /* 增加允许接入的NFT合约*/
    event NftContractAdded(address indexed operator, address indexed nftContract);
    /* 取消允许接入的NFT合约*/
    event NftContractRemoved(address indexed operator, address indexed nftContract);

    modifier onlyDAO() {
        require(daoOwner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor (
        string memory _name,
        string memory _version,
        address _feeRecipient,
        address _daoOwner,
        address _hbNFT
    ) {
        // minFee = _minFee;
        daoOwner = _daoOwner;
        hbNFT = _hbNFT;
        allowedNftContracts[hbNFT] = true;
        feeRecipient = _feeRecipient;
        isAllowAllNftContracts = false;
        name = _name;
        version = _version;
        HashEIP712Name = keccak256(bytes(name));
        HashEIP712Version = keccak256(bytes(version));
    }

    function setFee(uint256 _feeRate, address _feeRecipient) public onlyDAO {
        // minFee = _minFee;
        feeRate = _feeRate;
        feeRecipient = _feeRecipient;
    }

    function setIsAllowedNftContracts(bool _isAllowAllNftContracts) public onlyDAO {
        isAllowAllNftContracts = _isAllowAllNftContracts;
    }

    function addAllowedContract(address contractAddr) public onlyDAO {
        if(!allowedNftContracts[contractAddr]) {
            allowedNftContracts[contractAddr] = true;
            emit NftContractAdded(msg.sender, contractAddr);
        }
    }

    function removeAllowedContract(address contractAddr) public onlyDAO {
        if(allowedNftContracts[contractAddr]) {
            delete allowedNftContracts[contractAddr];
            emit NftContractRemoved(msg.sender, contractAddr);
        }
    }

    // CompilerError: Stack too deep, try removing local variables.
    function exchangeFixedPrice(
        bool maker_sells_nft,
        address taker,
        FixedPriceOrder memory order,
        Sig memory maker_sig,
        Sig memory taker_sig
    ) external payable {
        address maker = order.maker;
        if(order.taker != address(0)) {
            require(taker == order.taker, "Taker is not the one set by maker");
        }
        require(maker != taker, "Taker is same as maker");
        require(maker != address(0) && taker != address(0), "Maker or Taker is address(0)");
        require(order.expiration_time >= block.timestamp, "Order is expired");
        require(order.maker_nonce == userNonce[maker], "Maker nonce doesn't match");

        bytes memory order_bytes = FixedPriceOrderEIP712Encode(order);
        bytes32 order_digest = _hashTypedDataV4(keccak256(order_bytes));
        require(
            !finalizedOrder[order_digest] &&
            !userCanceledOrder[maker][order_digest] &&
            !userCanceledOrder[taker][order_digest],
            "The order is finalized or canceled"
        );
        require(maker == ecrecover(order_digest, maker_sig.v, maker_sig.r, maker_sig.s));
        require(taker == ecrecover(order_digest, taker_sig.v, taker_sig.r, taker_sig.s));
        require(isAllowAllNftContracts || allowedNftContracts[order.nft_contract], "NFT contract is not supported");

        address nft_seller = maker;
        address nft_buyer = taker;
        if(!maker_sells_nft) {
            nft_seller = taker;
            nft_buyer = maker;
        }

        address nft_owner = address(0);
        // TODO 考虑 nft_contract 不是真正的 NFT 合约时的情况
        try IERC721(order.nft_contract).ownerOf(order.token_id) returns (address owner) {
            nft_owner = owner;
        } catch {

        }
        if(nft_owner == address(0) && order.nft_contract == hbNFT) {
            // 可在NFT后台检查订单中的版税参数是否符合在平台上创建专辑时设定的值，若不符合，则不创建NFT所对应的MetaData
            // NFT合约中，由NFT原创者进行版税的修改，并伴随NFT后台的签名确认
            // mint NFT & set royalty_rate royalty_recipient EIP2981
            require(address(uint160(order.token_id >> 96)) == nft_seller, "Token ID is wrong");
            ILazyMint(order.nft_contract).lazyMint(order.token_id, order.royalty_rate);
            nft_owner = nft_seller;
        }
        require(nft_owner == nft_seller, "The NFT seller is not the NFT owner");

        uint256 royalty_amount = order.fixed_price * order.royalty_rate / feeDenominator;
        uint256 platform_amount = order.fixed_price * feeRate / feeDenominator;
        uint256 remain_amount = order.fixed_price  - (royalty_amount + platform_amount);

        try IERC2981(order.nft_contract).royaltyInfo(order.token_id, order.fixed_price) returns (address receiver, uint256 royaltyAmount) {
            if(royaltyAmount != 0 || receiver != address(0)) {
                require(
                    order.royalty_recipient == receiver &&
                    royalty_amount == royaltyAmount, // TODO, >= ???
                    "Royalty information doesn't match"
                );
            }
        } catch {

        }

        // 执行结算: 平台费、版税、卖家所得，若是本币（链自身的代币）结算，多余的额度需退还
        if(order.payment_token != address(0)) {
            require(msg.value == 0, "Msg.value should be zero");
            IERC20(order.payment_token).transferFrom(nft_buyer, order.royalty_recipient, royalty_amount);
            IERC20(order.payment_token).transferFrom(nft_buyer, feeRecipient, platform_amount);
            IERC20(order.payment_token).transferFrom(nft_buyer, nft_seller, remain_amount);
        } else {
            require(msg.value >= order.fixed_price, "Msg.value is not enough");
            if(msg.value > order.fixed_price) {
                sendValue(payable(msg.sender), msg.value - order.fixed_price);
            }
            sendValue(payable(order.royalty_recipient), royalty_amount);
            sendValue(payable(feeRecipient), platform_amount);
            sendValue(payable(nft_seller), remain_amount);
        }

        emit FixedPriceOrderMatched(tx.origin, taker, maker, order_digest, order_bytes);

    }

    // openzeppelin/contracts/utils/Address.sol
    function sendValue(address payable recipient, uint256 amount) private {
        require(address(this).balance >= amount, "Insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Unable to send value, recipient may have reverted");
    }

    function cancelOrder(bytes32 order_hash) public {
        userCanceledOrder[msg.sender][order_hash] = true;

        emit OrderCancelled(msg.sender, order_hash);
    }

    function cancelAllOrders() public {
        ++userNonce[msg.sender];
        uint256 nonce = userNonce[msg.sender];

        emit AllOrdersCancelled(msg.sender, nonce);
    }

    // https://eips.ethereum.org/EIPS/eip-712
    function FixedPriceOrderDigestForSign(FixedPriceOrder memory order) public view returns(bytes32) {
        bytes memory order_bytes = FixedPriceOrderEIP712Encode(order);
        bytes32 order_hash = keccak256(order_bytes);
        bytes32 order_digest = _hashTypedDataV4(order_hash);
        return order_digest;
    }

    // https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct
    function FixedPriceOrderEIP712Encode(FixedPriceOrder memory order) public view returns(bytes memory) {
        bytes memory order_bytes = abi.encode(
            HashOrderSturct,
            order.taker,
            order.maker,
            order.maker_nonce,
            order.listing_time,
            order.expiration_time,
            order.nft_contract,
            order.token_id,
            order.payment_token,
            order.fixed_price,
            order.royalty_rate,
            order.royalty_recipient
        );
        return order_bytes;
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        // return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
        return _toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function _toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return keccak256(abi.encode(HashEIP712Domain, HashEIP712Name, HashEIP712Version, block.chainid, address(this)));
    }


}