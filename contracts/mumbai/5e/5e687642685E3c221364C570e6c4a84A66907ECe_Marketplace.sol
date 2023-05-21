/**
 *Submitted for verification at polygonscan.com on 2023-05-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Ownable {
    error NotOwner(); // 0x30cd7471

    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlyOwner() {
        if (_owner != msg.sender) revert NotOwner();
        _;
    }

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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
}

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
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

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
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

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
    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);

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
    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool);

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

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

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC2981 is IERC165 {
    /// ERC165 bytes to add to interface array - set in parent contract
    /// implementing this standard
    ///
    /// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
    /// bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    /// _registerInterface(_INTERFACE_ID_ERC2981);

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);
}

contract Marketplace is Ownable {
    struct DirectSale {
        address nft;
        uint256 id;
        uint256 validAmount;
        uint256 soldAmount;
        IERC20 token;
        uint256 price;
        address seller;
    }

    struct AuctionSale {
        address nft;
        uint256 id;
        uint256 amount;
        IERC20 token;
        uint256 price;
        uint256 currentPrice;
        uint256 openTimestamp;
        uint256 closeTimestamp;
        address seller;
        address currentBuyer;
        bool closed;
    }

    mapping(address => bool) private _nfts;
    mapping(IERC20 => bool) private _tokens;
    mapping(uint256 => DirectSale) private _directs;
    mapping(uint256 => AuctionSale) private _auctions;
    mapping(address => mapping(uint256 => uint256)) private _buyerInfo;

    uint256 private _fee;
    uint256 private _auctionStep;
    uint256 private _extraTime;

    uint256 private _directsLength;
    uint256 private _auctionsLength;

    uint256 private _minTimestamp;
    uint256 private _maxTimestamp;

    error SafeTransferFromFailed();
    error SafeTransferFailed();
    error InvalidNft();
    error InvalidToken();
    error ZeroAmount();
    error NotLotOwner();
    error LotOwnerCannotBuyHimself();
    error TimestampMistake();
    error AuctionNotClosed();
    error AuctionClosed();
    error NotParticipate();
    error BidTooLow();

    event CloseAuctionSale(uint256 indexed id);
    event RefundBid(uint256 indexed id, address indexed user);
    event BidAuctionSale(
        uint256 indexed id,
        address indexed user,
        uint256 amount
    );
    event UpdateCloseTimestamp(uint256 indexed id, uint256 newTimestamp);
    event CreateAuctionSale(uint256 indexed id, address indexed user);
    event CreateDirectSale(uint256 indexed id, address indexed user);
    event BuyDirectSale(
        uint256 indexed id,
        address indexed buyer,
        uint256 amount,
        uint256 price
    );
    event CloseDirectSale(uint256 indexed id, address indexed user);
    event UpdateDirectSale(uint256 indexed id);

    constructor(uint256 _step) payable {
        if (_step < 100) revert();
        _auctionStep = _step;
    }

    function closeAuctionSale(uint256 id) external {
        AuctionSale storage auction = _auctions[id];
        if (
            msg.sender == auction.currentBuyer || msg.sender == auction.seller
        ) {
            if (block.timestamp < auction.closeTimestamp)
                revert AuctionNotClosed();

            if (auction.closed) revert AuctionClosed();
            auction.closed = true;

            (
                uint256 sale,
                uint256 fee,
                uint256 royalty,
                address royaltyRecipient
            ) = _getAmounts(auction.nft, auction.id, auction.currentPrice);

            _safeTransfer(auction.token, auction.seller, sale);
            if (fee > 0) _safeTransfer(auction.token, owner(), fee);
            if (royalty > 0)
                _safeTransfer(auction.token, royaltyRecipient, royalty);

            _safeTransferFrom(
                auction.nft,
                address(this),
                auction.currentBuyer,
                auction.id,
                auction.amount
            );

            emit CloseAuctionSale(id);
            return;
        }
        if (_buyerInfo[msg.sender][id] > 0) {
            _safeTransfer(
                auction.token,
                msg.sender,
                _buyerInfo[msg.sender][id]
            );
            _buyerInfo[msg.sender][id] = 0;

            emit RefundBid(id, msg.sender);
            return;
        }
        revert NotParticipate();
    }

    function bidAuctionSale(uint256 id, uint256 newAmount) external {
        AuctionSale storage auction = _auctions[id];
        if (auction.seller == msg.sender) revert LotOwnerCannotBuyHimself();
        if (
            block.timestamp < auction.openTimestamp ||
            block.timestamp > auction.closeTimestamp
        ) revert TimestampMistake();
        if (
            newAmount < (auction.currentPrice * _auctionStep) / 100 ||
            newAmount == 0
        ) revert BidTooLow();

        if (_buyerInfo[msg.sender][id] > 0) {
            _safeTransferFrom(
                auction.token,
                msg.sender,
                address(this),
                newAmount - _buyerInfo[msg.sender][id]
            );
        } else {
            _safeTransferFrom(
                auction.token,
                msg.sender,
                address(this),
                newAmount
            );
        }

        _buyerInfo[msg.sender][id] = newAmount;

        auction.currentPrice = newAmount;
        auction.currentBuyer = msg.sender;

        emit BidAuctionSale(id, msg.sender, newAmount);
        if (auction.closeTimestamp - block.timestamp < _extraTime) {
            uint256 closeTimestamp = block.timestamp + _extraTime;
            auction.closeTimestamp = closeTimestamp;
            emit UpdateCloseTimestamp(id, closeTimestamp);
        }
    }

    function createAuctionSale(
        address nft,
        uint256 id,
        uint256 amount,
        IERC20 token,
        uint256 price,
        uint256 openTimestamp,
        uint256 closeTimestamp
    ) external {
        if (!_nfts[nft]) revert InvalidNft();
        if (!_tokens[token]) revert InvalidToken();
        if (amount == 0) revert ZeroAmount();
        uint256 time = closeTimestamp - openTimestamp;
        if (
            openTimestamp < block.timestamp ||
            closeTimestamp <= block.timestamp ||
            time < _minTimestamp ||
            time > _maxTimestamp
        ) revert TimestampMistake();

        uint256 _id = _auctionsLength;
        _auctionsLength++;

        _auctions[_id] = AuctionSale(
            nft,
            id,
            amount,
            token,
            price,
            price,
            openTimestamp,
            closeTimestamp,
            msg.sender,
            address(0),
            false
        );

        _safeTransferFrom(nft, msg.sender, address(this), id, amount);
        emit CreateAuctionSale(_id, msg.sender);
    }

    function createDirectSale(
        address nft,
        uint256 id,
        uint256 amount,
        IERC20 token,
        uint256 price
    ) external {
        if (!_nfts[nft]) revert InvalidNft();
        if (!_tokens[token]) revert InvalidToken();
        if (amount == 0 || price == 0) revert ZeroAmount();

        uint256 _id = _directsLength;
        _directsLength++;
        _directs[_id] = DirectSale(
            nft,
            id,
            amount,
            0,
            token,
            price,
            msg.sender
        );

        _safeTransferFrom(nft, msg.sender, address(this), id, amount);
        emit CreateDirectSale(_id, msg.sender);
    }

    function buyDirectSale(uint256 id, uint256 amount) external {
        if (amount == 0) revert ZeroAmount();

        DirectSale storage direct = _directs[id];
        if (direct.seller == msg.sender) revert LotOwnerCannotBuyHimself();

        direct.soldAmount += amount;
        direct.validAmount -= amount;

        (
            uint256 sale,
            uint256 fee,
            uint256 royalty,
            address royaltyRecipient
        ) = _getAmounts(direct.nft, direct.id, amount * direct.price);

        _safeTransferFrom(direct.token, msg.sender, direct.seller, sale);
        if (fee > 0) _safeTransferFrom(direct.token, msg.sender, owner(), fee);
        if (royalty > 0)
            _safeTransferFrom(
                direct.token,
                msg.sender,
                royaltyRecipient,
                royalty
            );

        _safeTransferFrom(
            direct.nft,
            address(this),
            msg.sender,
            direct.id,
            amount
        );

        emit BuyDirectSale(id, msg.sender, amount, direct.price);
    }

    function closeDirectSale(uint256 id) external {
        if (_directs[id].seller != msg.sender) revert NotLotOwner();
        if (_directs[id].validAmount == 0) revert ZeroAmount();

        uint256 tAmount = _directs[id].validAmount;
        _directs[id].validAmount = 0;

        _safeTransferFrom(
            _directs[id].nft,
            address(this),
            msg.sender,
            _directs[id].id,
            tAmount
        );

        emit CloseDirectSale(id, msg.sender);
    }

    function updateDirectSale(uint256 id, uint256 newPrice) external {
        if (_directs[id].seller != msg.sender) revert NotLotOwner();
        if (newPrice == 0) revert ZeroAmount();
        _directs[id].price = newPrice;
        emit UpdateDirectSale(id);
    }

    function setAuctionStep(uint256 newAuctionStep) external onlyOwner {
        if (newAuctionStep < 100 || newAuctionStep > 150) revert();
        _auctionStep = newAuctionStep;
    }

    function setExtraTime(uint256 newExtraTime) external onlyOwner {
        if (newExtraTime > 3600) revert();
        _extraTime = newExtraTime;
    }

    function setNft(address _nft, bool _valid) external onlyOwner {
        _nfts[_nft] = _valid;
    }

    function setToken(IERC20 _token, bool _valid) external onlyOwner {
        _tokens[_token] = _valid;
    }

    function setTimestamp(uint256 min, uint256 max) external onlyOwner {
        if (max < min) revert();
        (_minTimestamp, _maxTimestamp) = (min, max);
    }

    function setFee(uint256 newFee) external onlyOwner {
        if (newFee > 1000) revert();
        _fee = newFee;
    }

    function lengths()
        external
        view
        returns (uint256 directs, uint256 auctions)
    {
        return (_directsLength, _auctionsLength);
    }

    function getDirect(uint256 id) external view returns (DirectSale memory) {
        return _directs[id];
    }

    function getAuction(uint256 id) external view returns (AuctionSale memory) {
        return _auctions[id];
    }

    function getToken(IERC20 _token) external view returns (bool) {
        return _tokens[_token];
    }

    function getNft(address _nft) external view returns (bool) {
        return _nfts[_nft];
    }

    function getFee() external view returns (uint256) {
        return _fee;
    }

    function getAuctionStep() external view returns (uint256) {
        return _auctionStep;
    }

    function getExtraTime() external view returns (uint256) {
        return _extraTime;
    }

    function getMinAndMaxTimestamp()
        external
        view
        returns (uint256 min, uint256 max)
    {
        (min, max) = (_minTimestamp, _maxTimestamp);
    }

    function getTimestamp() external view returns (uint256) {
        return block.timestamp;
    }

    function getBuyerInfo(
        address user,
        uint256 auctionId
    ) external view returns (uint256) {
        return _buyerInfo[user][auctionId];
    }

    function _getAmounts(
        address nft,
        uint256 tokenId,
        uint256 amount
    )
        private
        view
        returns (
            uint256 sale,
            uint256 fee,
            uint256 royalty,
            address royaltyRecipient
        )
    {
        try IERC2981(nft).royaltyInfo(tokenId, amount) returns (
            address _royaltyRecipient,
            uint256 _royalty
        ) {
            (royaltyRecipient, royalty) = (_royaltyRecipient, _royalty);
        } catch {}
        fee = (amount * _fee) / 10000;
        sale = amount - fee - royalty;
    }

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) private {
        (bool success, ) = token.call(
            abi.encodeWithSelector(
                IERC1155.safeTransferFrom.selector,
                from,
                to,
                id,
                amount,
                new bytes(0)
            )
        );
        if (!success) revert SafeTransferFromFailed();
    }

    function _safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) private {
        bytes4 selector = token.transferFrom.selector;
        bool success;
        assembly {
            let data := mload(0x40)
            mstore(data, selector)
            mstore(add(data, 0x04), from)
            mstore(add(data, 0x24), to)
            mstore(add(data, 0x44), amount)
            success := call(gas(), token, 0, data, 100, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 {
                    success := gt(extcodesize(token), 0)
                }
                default {
                    success := and(gt(returndatasize(), 31), eq(mload(0), 1))
                }
            }
        }
        if (!success) revert SafeTransferFromFailed();
    }

    function _safeTransfer(IERC20 token, address to, uint256 amount) private {
        bool success;
        bytes4 selector = token.transfer.selector;
        assembly {
            let data := mload(0x40)
            mstore(data, selector)
            mstore(add(data, 0x04), to)
            mstore(add(data, 0x24), amount)
            success := call(gas(), token, 0, data, 0x44, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 {
                    success := gt(extcodesize(token), 0)
                }
                default {
                    success := and(gt(returndatasize(), 31), eq(mload(0), 1))
                }
            }
        }
        if (!success) revert SafeTransferFailed();
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return 0xf23a6e61;
    }
}