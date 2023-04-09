// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { IMarketplace } from "./interfaces/IMarketplace.sol";
import { IItem } from "./interfaces/IItem.sol";
import { IGold } from "./interfaces/IGold.sol";

contract Marketplace is IMarketplace {
    BuyOrder[] private _buyOrders;
    SellOrder[] private _sellOrders;

    IItem private immutable _item;
    IGold private immutable _gold;

    constructor(IItem item_, IGold gold_) {
        _item = item_;
        _gold = gold_;
    }

    function placeOrders(
        uint256[] calldata sellOrdersIds_,
        uint80[] calldata sellOrderPrices_,
        uint16[] calldata buyOrdersIds_,
        uint80[] calldata buyOrderPrices_
    ) external override {
        if (sellOrdersIds_.length == 0 && buyOrdersIds_.length == 0) revert NoOrdersError();
        require(
            sellOrdersIds_.length == sellOrderPrices_.length,
            "Marketplace: sellOrdersIds_.length != sellOrderPrices_.length"
        );
        require(
            buyOrdersIds_.length == buyOrderPrices_.length,
            "Marketplace: buyOrdersIds_.length != buyOrderPrices_.length"
        );

        uint256 totalGoldInBuyOrders_;
        for (uint256 i_; i_ < buyOrdersIds_.length;) {
            totalGoldInBuyOrders_ += buyOrderPrices_[i_];
            _buyOrders.push(BuyOrder(msg.sender, buyOrdersIds_[i_], buyOrderPrices_[i_]));
            emit BuyOrderPlaced(msg.sender, buyOrdersIds_[i_], buyOrderPrices_[i_]);
            unchecked {
                ++i_;
            }
        }
        if (totalGoldInBuyOrders_ != 0) _gold.privilegedTransferFrom(msg.sender, address(this), totalGoldInBuyOrders_);

        uint256[] memory amounts_ = new uint256[](sellOrdersIds_.length);
        for (uint256 i_; i_ < sellOrdersIds_.length;) {
            amounts_[i_] = 1;
            _sellOrders.push(SellOrder(msg.sender, uint16(sellOrdersIds_[i_]), sellOrderPrices_[i_]));
            emit SellOrderPlaced(msg.sender, uint16(sellOrdersIds_[i_]), sellOrderPrices_[i_]);
            unchecked {
                ++i_;
            }
        }
        if (sellOrdersIds_.length != 0) _item.burnBatch(msg.sender, sellOrdersIds_, amounts_);
    }

    function fulfilOrders(uint256[] calldata sellOrderIds_, uint256[] calldata buyOrderIds_) external override {
        if (sellOrderIds_.length == 0 && buyOrderIds_.length == 0) revert NoOrdersError();

        for (uint256 i_; i_ < sellOrderIds_.length;) {
            SellOrder memory sellOrder_ = _sellOrders[sellOrderIds_[i_]];
            if (sellOrder_.seller == address(0)) revert SellOrderDoesNotExistError(sellOrderIds_[i_]);
            delete _sellOrders[sellOrderIds_[i_]];
            _gold.privilegedTransferFrom(msg.sender, sellOrder_.seller, sellOrder_.price);
            _item.mint(msg.sender, sellOrder_.itemId);
            emit SellOrderFulfilled(sellOrder_.seller, sellOrder_.itemId, sellOrder_.price);
            unchecked {
                ++i_;
            }
        }

        uint256 totalGoldInBuyOrders_;
        for (uint256 i_; i_ < buyOrderIds_.length;) {
            BuyOrder memory buyOrder_ = _buyOrders[buyOrderIds_[i_]];
            if (buyOrder_.buyer == address(0)) revert BuyOrderDoesNotExistError(buyOrderIds_[i_]);
            delete _buyOrders[buyOrderIds_[i_]];
            totalGoldInBuyOrders_ += buyOrder_.price;
            _item.privilegedSafeTransferFrom(msg.sender, buyOrder_.buyer, buyOrder_.itemId);
            emit BuyOrderFulfilled(buyOrder_.buyer, buyOrder_.itemId, buyOrder_.price);
            unchecked {
                ++i_;
            }
        }
        _gold.transfer(msg.sender, totalGoldInBuyOrders_);
    }

    function cancelOrders(uint256[] calldata sellOrderIds_, uint256[] calldata buyOrderIds_) external override {
        if (sellOrderIds_.length == 0 && buyOrderIds_.length == 0) revert NoOrdersError();

        for (uint256 i_; i_ < sellOrderIds_.length;) {
            SellOrder memory sellOrder_ = _sellOrders[sellOrderIds_[i_]];
            if (sellOrder_.seller == address(0)) revert SellOrderDoesNotExistError(sellOrderIds_[i_]);
            if (sellOrder_.seller != msg.sender) revert NotSellerError(sellOrderIds_[i_]);
            delete _sellOrders[sellOrderIds_[i_]];
            _item.mint(msg.sender, sellOrder_.itemId);
            emit SellOrderCancelled(sellOrder_.seller, sellOrder_.itemId, sellOrder_.price);
            unchecked {
                ++i_;
            }
        }

        uint256 totalGoldInBuyOrders_;
        for (uint256 i_; i_ < buyOrderIds_.length;) {
            BuyOrder memory buyOrder_ = _buyOrders[buyOrderIds_[i_]];
            if (buyOrder_.buyer == address(0)) revert BuyOrderDoesNotExistError(buyOrderIds_[i_]);
            if (buyOrder_.buyer != msg.sender) revert NotBuyerError(buyOrderIds_[i_]);
            delete _buyOrders[buyOrderIds_[i_]];
            totalGoldInBuyOrders_ += buyOrder_.price;
            emit BuyOrderCancelled(buyOrder_.buyer, buyOrder_.itemId, buyOrder_.price);
            unchecked {
                ++i_;
            }
        }
        _gold.transfer(msg.sender, totalGoldInBuyOrders_);
    }

    function getBuyOrders() external view override returns (BuyOrder[] memory) {
        return _buyOrders;
    }

    function getSellOrders() external view override returns (SellOrder[] memory) {
        return _sellOrders;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "./IOFTCore.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Interface of the OFT standard
 */
interface IOFT is IOFTCore, IERC20 { }

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Interface of the IOFT core standard
 */
interface IOFTCore is IERC165 {
    /**
     * @dev estimate send token `_tokenId` to (`_dstChainId`, `_toAddress`)
     * _dstChainId - L0 defined chain id to send tokens too
     * _toAddress - dynamic bytes array which contains the address to whom you are sending tokens to on the dstChain
     * _amount - amount of the tokens to transfer
     * _useZro - indicates to use zro to pay L0 fees
     * _adapterParam - flexible bytes array to indicate messaging adapter services in L0
     */
    function estimateSendFee(
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint256 _amount,
        bool _useZro,
        bytes calldata _adapterParams
    ) external view returns (uint256 nativeFee, uint256 zroFee);

    /**
     * @dev send `_amount` amount of token to (`_dstChainId`, `_toAddress`) from `_from`
     * `_from` the owner of token
     * `_dstChainId` the destination chain identifier
     * `_toAddress` can be any size depending on the `dstChainId`.
     * `_amount` the quantity of tokens in wei
     * `_refundAddress` the address LayerZero refunds if too much message fee is sent
     * `_zroPaymentAddress` set to address(0x0) if not paying in ZRO (LayerZero Token)
     * `_adapterParams` is a flexible bytes array to indicate messaging adapter services
     */
    function sendFrom(
        address _from,
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint256 _amount,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable;

    /**
     * @dev returns the circulating amount of tokens on current chain
     */
    function circulatingSupply() external view returns (uint256);

    /**
     * @dev returns the address of the ERC20 token
     */
    function token() external view returns (address);

    /**
     * @dev Emitted when `_amount` tokens are moved from the `_sender` to (`_dstChainId`, `_toAddress`)
     * `_nonce` is the outbound nonce
     */
    event SendToChain(uint16 indexed _dstChainId, address indexed _from, bytes _toAddress, uint256 _amount);

    /**
     * @dev Emitted when `_amount` tokens are received from `_srcChainId` into the `_toAddress` on the local chain.
     * `_nonce` is the inbound nonce.
     */
    event ReceiveFromChain(uint16 indexed _srcChainId, address indexed _to, uint256 _amount);

    event SetUseCustomAdapterParams(bool _useCustomAdapterParams);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "./IONFT1155Core.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 * @dev Interface of the ONFT standard
 */
interface IONFT1155 is IONFT1155Core, IERC1155 { }

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Interface of the ONFT Core standard
 */
interface IONFT1155Core is IERC165 {
    event SendToChain(
        uint16 indexed _dstChainId, address indexed _from, bytes indexed _toAddress, uint256 _tokenId, uint256 _amount
    );
    event SendBatchToChain(
        uint16 indexed _dstChainId,
        address indexed _from,
        bytes indexed _toAddress,
        uint256[] _tokenIds,
        uint256[] _amounts
    );
    event ReceiveFromChain(
        uint16 indexed _srcChainId,
        bytes indexed _srcAddress,
        address indexed _toAddress,
        uint256 _tokenId,
        uint256 _amount
    );
    event ReceiveBatchFromChain(
        uint16 indexed _srcChainId,
        bytes indexed _srcAddress,
        address indexed _toAddress,
        uint256[] _tokenIds,
        uint256[] _amounts
    );

    // _from - address where tokens should be deducted from on behalf of
    // _dstChainId - L0 defined chain id to send tokens too
    // _toAddress - dynamic bytes array which contains the address to whom you are sending tokens to on the dstChain
    // _tokenId - token Id to transfer
    // _amount - amount of the tokens to transfer
    // _refundAddress - address on src that will receive refund for any overpayment of L0 fees
    // _zroPaymentAddress - if paying in zro, pass the address to use. using 0x0 indicates not paying fees in zro
    // _adapterParams - flexible bytes array to indicate messaging adapter services in L0
    function sendFrom(
        address _from,
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint256 _tokenId,
        uint256 _amount,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable;

    // _from - address where tokens should be deducted from on behalf of
    // _dstChainId - L0 defined chain id to send tokens too
    // _toAddress - dynamic bytes array which contains the address to whom you are sending tokens to on the dstChain
    // _tokenIds - token Ids to transfer
    // _amounts - amounts of the tokens to transfer
    // _refundAddress - address on src that will receive refund for any overpayment of L0 fees
    // _zroPaymentAddress - if paying in zro, pass the address to use. using 0x0 indicates not paying fees in zro
    // _adapterParams - flexible bytes array to indicate messaging adapter services in L0
    function sendBatchFrom(
        address _from,
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable;

    // _dstChainId - L0 defined chain id to send tokens too
    // _toAddress - dynamic bytes array which contains the address to whom you are sending tokens to on the dstChain
    // _tokenId - token Id to transfer
    // _amount - amount of the tokens to transfer
    // _useZro - indicates to use zro to pay L0 fees
    // _adapterParams - flexible bytes array to indicate messaging adapter services in L0
    function estimateSendFee(
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint256 _tokenId,
        uint256 _amount,
        bool _useZro,
        bytes calldata _adapterParams
    ) external view returns (uint256 nativeFee, uint256 zroFee);

    // _dstChainId - L0 defined chain id to send tokens too
    // _toAddress - dynamic bytes array which contains the address to whom you are sending tokens to on the dstChain
    // _tokenIds - tokens Id to transfer
    // _amounts - amounts of the tokens to transfer
    // _useZro - indicates to use zro to pay L0 fees
    // _adapterParams - flexible bytes array to indicate messaging adapter services in L0
    function estimateSendBatchFee(
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts,
        bool _useZro,
        bytes calldata _adapterParams
    ) external view returns (uint256 nativeFee, uint256 zroFee);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { IOFT } from "src/dependencies/layerZero/interfaces/oft/IOFT.sol";

interface IGold is IOFT {
    error NotPrivilegedSender(address sender);
    error NotCharacterError(address sender);

    event GoldBurned(address indexed account, uint256 amount);
    event GoldMinted(address indexed account, uint256 amount);
    event GoldPrivilegedTransfer(address indexed from, address indexed to, uint256 amount);

    function burn(address account_, uint256 amount_) external;
    function mint(address account_, uint256 amount_) external;
    function privilegedTransferFrom(address from_, address to_, uint256 amount_) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { IONFT1155 } from "src/dependencies/layerZero/interfaces/onft1155/IONFT1155.sol";

interface IItem is IONFT1155 {
    event ItemBurned(address indexed from, uint256 id);
    event ItemMinted(address indexed to, uint256 id);
    event ItemBatchBurned(address indexed from, uint256[] ids, uint256[] amounts);
    event ItemBatchMinted(address indexed to, uint256[] ids, uint256[] amounts);
    event ItemPrivilegedTransfer(address indexed from, address indexed to, uint256 id);

    function burn(address from, uint256 id) external;
    function mint(address to, uint256 id) external;
    function burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) external;
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) external;
    function privilegedSafeTransferFrom(address from_, address to_, uint256 id_) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

interface IMarketplace {
    struct SellOrder {
        address seller;
        uint16 itemId;
        uint80 price;
    }

    struct BuyOrder {
        address buyer;
        uint16 itemId;
        uint80 price;
    }

    event SellOrderPlaced(address indexed seller, uint16 itemId, uint80 price);
    event BuyOrderPlaced(address indexed buyer, uint16 itemId, uint80 price);
    event SellOrderCancelled(address indexed seller, uint16 itemId, uint80 price);
    event BuyOrderCancelled(address indexed buyer, uint16 itemId, uint80 price);
    event SellOrderFulfilled(address indexed seller, uint16 itemId, uint80 price);
    event BuyOrderFulfilled(address indexed buyer, uint16 itemId, uint80 price);

    error NoOrdersError();
    error NotBuyerError(uint256 buyOrderId_);
    error NotSellerError(uint256 sellOrderId_);
    error SellOrderDoesNotExistError(uint256 sellOrderId_);
    error BuyOrderDoesNotExistError(uint256 buyOrderId_);

    function placeOrders(
        uint256[] calldata sellOrdersIds_,
        uint80[] calldata sellOrderPrices_,
        uint16[] calldata buyOrdersIds_,
        uint80[] calldata buyOrderPrices
    ) external;

    function fulfilOrders(uint256[] calldata sellOrderIds_, uint256[] calldata buyOrderIds_) external;

    function cancelOrders(uint256[] calldata sellOrderIds_, uint256[] calldata buyOrderIds_) external;

    function getBuyOrders() external view returns (BuyOrder[] memory);

    function getSellOrders() external view returns (SellOrder[] memory);
}