/**
 *Submitted for verification at polygonscan.com on 2022-04-01
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

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
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

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
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

    function paymentTokens(address _token) external view returns (bool);
}

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

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

library SafeERC20 {
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        require(token.transferFrom(from, to, value));
    }
}

contract MarketPlace is ERC165 {
    using SafeERC20 for IERC20;

    address public tokenAddress;
    address payable public owner;
    uint256 public platformFees;

    IERC20 public ERC20Interface;
    IERC1155 public ERC1155Interface;

    struct Order {
        uint256 tokenId;
        uint256 copies;
        uint256 price;
        address seller;
        uint8 saleType;
        uint256 startTime;
        address paymentToken;
    }

    struct Bid {
        address bidder;
        uint256 copies;
        uint256 amount;
        uint256 timestamp;
        address token;
    }

    struct Royalties {
        address owner;
        uint256 percent;
        bool initiated;
    }

    mapping(uint256 => Order) public order;
    mapping(uint256 => Bid[]) public openBids;
    mapping(uint256 => Royalties) public royalties;
    mapping(address => mapping(uint256 => uint256)) public index;

    uint256 public orderNonce;

    enum SaleType {
        BuyNow,
        OpenForBids
    }

    event PlatformFeesUpdated(uint256 fees, uint256 timestamp);
    event OwnerUpdated(address newOwner, uint256 timestamp);
    event OrderPlaced(Order _order, uint256 _orderNonce, uint256 timestamp);
    event OrderCancelled(Order _order, uint256 _orderNonce, uint256 timestamp);
    event ItemBought(
        Order _order,
        uint256 _orderNonce,
        uint256 _copies,
        uint256 timestamp
    );
    event BidPlaced(
        Order _order,
        uint256 _orderNonce,
        uint256 bidAmount,
        uint256 timestamp
    );
    event BidWithdrawn(
        Order _order,
        uint256 _orderNonce,
        uint256 bidAmount,
        uint256 timestamp
    );

    constructor(
        address _token,
        address _owner,
        uint256 _platformFees
    ) {
        require(_token != address(0) && _owner != address(0), "Zero address");
        ERC1155Interface = IERC1155(_token);
        tokenAddress = _token;
        owner = payable(_owner);
        platformFees = _platformFees;
        emit OwnerUpdated(_owner, block.timestamp);
        emit PlatformFeesUpdated(_platformFees, block.timestamp);
    }

    /**
     * @dev External function to change the fee of Marketplace contract.
     *
     * @param fee, new fees for the platform on each successful buy transaction
     */
    function setPlatformFees(uint256 fee) external {
        require(msg.sender == owner, "Only owner");
        require(fee <= 50, "High fee"); //Max cap on platform fee is set to 50, and can be changed before deployment
        platformFees = fee;
        emit PlatformFeesUpdated(fee, block.timestamp);
    }

    /**
     * @dev External function to change the owner of the token contract.
     *
     * @param newOwner, new expected owner of the contract
     */
    function changeOwner(address newOwner) external {
        require(msg.sender == owner, "Only owner");
        require(newOwner != address(0), "Zero address");
        owner = payable(newOwner);
        emit OwnerUpdated(newOwner, block.timestamp);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev External function to place order in Marketplace
     *
     * @param tokenId, tokenId of the NFT
     * @param copies, copies of the NFT
     * @param pricePerNFT, price of the NFT
     * @param _saleType, Type of sale.
     * @param startTime, auction start time.
     * @param royaltyAddress, address to receive royalty fees.
     * @param royaltyPercentage, percentage fees.
     * @param _paymentToken, payment token to be used.
     * @return bool returns true on successful transaction
     */
    function placeOrder(
        uint256 tokenId,
        uint256 copies,
        uint256 pricePerNFT,
        SaleType _saleType,
        uint256 startTime,
        address royaltyAddress,
        uint256 royaltyPercentage,
        address _paymentToken
    ) external returns (bool) {
        require(pricePerNFT > 0, "Invalid price");
        require(royaltyPercentage <= 50, "Royalty fees too high");
        require(
            ERC1155Interface.paymentTokens(_paymentToken),
            "ERC20: Token not enabled for payment"
        );
        if (startTime < block.timestamp) startTime = block.timestamp;
        ERC1155Interface.safeTransferFrom(
            msg.sender,
            address(this),
            tokenId,
            copies,
            ""
        );
        orderNonce++;
        order[orderNonce] = Order(
            tokenId,
            copies,
            pricePerNFT,
            msg.sender,
            uint8(_saleType),
            startTime,
            _paymentToken
        );

        if (!royalties[tokenId].initiated && royaltyAddress != address(0)) {
            royalties[tokenId] = Royalties(
                royaltyAddress,
                royaltyPercentage,
                false
            );
        }
        emit OrderPlaced(order[orderNonce], orderNonce, block.timestamp);
        return true;
    }

    /**
     * @dev External function to place order in Marketplace
     *
     * @param tokenId, tokenId of the NFT
     * @param copies, copies of the NFT
     * @param pricePerNFT, price of the NFT
     * @param saleType, saleType of the order
     * @param user, creator of the NFT
     * @param startTime, order start time.
     * @param royaltyAddress, address to receive royalty fees.
     * @param royaltyPercentage, percentage fees.
     * @return bool returns true on successful transaction
     */
    function placeOrderByTokenContract(
        uint256 tokenId,
        uint256 copies,
        uint256 pricePerNFT,
        uint8 saleType,
        address user,
        uint256 startTime,
        address royaltyAddress,
        uint256 royaltyPercentage,
        address _paymentToken
    ) external returns (bool) {
        require(msg.sender == tokenAddress, "Only token address");
        // require(royaltyAddress != address(0), "Zero address");
        require(royaltyPercentage <= 50, "Royalty fees too high");
        require(pricePerNFT > 0, "Invalid price");
        orderNonce++;
        order[orderNonce] = Order(
            tokenId,
            copies,
            pricePerNFT,
            user,
            saleType,
            startTime,
            _paymentToken
        );
        if (!royalties[tokenId].initiated && royaltyAddress != address(0)) {
            royalties[tokenId] = Royalties(
                royaltyAddress,
                royaltyPercentage,
                false
            );
        }
        emit OrderPlaced(order[orderNonce], orderNonce, block.timestamp);
        return true;
    }

    /**
     * @dev External function to buy an order in Marketplace
     *
     * @param _orderNonce, Nonce of the order
     * @param copies, copies to be buy
     * @param amount, Amount to be paid
     * @return bool returns true on successful transaction
     */
    function buy(
        uint256 _orderNonce,
        uint256 copies,
        uint256 amount
    ) external returns (bool) {
        Order storage _order = order[_orderNonce];
        require(_order.seller != msg.sender, "Seller can't buy");
        require(_order.startTime <= block.timestamp, "Start time not reached");
        require(_order.price > 0, "NFT not in marketplace");
        require(
            _order.saleType != uint8(SaleType.OpenForBids),
            "Invalid sale type"
        );
        require(copies > 0 && copies <= _order.copies, "Invalid no of copies");
        require(amount == (copies * _order.price), "Incorrect price");
        uint256 fees = (amount * platformFees) / 100;
        uint256 royaltyFee;
        if (royalties[_order.tokenId].initiated) {
            royaltyFee =
                ((amount - fees) * royalties[_order.tokenId].percent) /
                100;
            if (royaltyFee > 0)
                sendValue(
                    msg.sender,
                    royalties[_order.tokenId].owner,
                    royaltyFee,
                    _order.paymentToken
                );
        } else {
            royalties[_order.tokenId].initiated = true;
        }
        if (fees > 0) {
            sendValue(msg.sender, owner, fees, _order.paymentToken);
        }
        sendValue(
            msg.sender,
            (_order.seller),
            (amount - fees - royaltyFee),
            _order.paymentToken
        );
        ERC1155Interface.safeTransferFrom(
            address(this),
            msg.sender,
            _order.tokenId,
            copies,
            ""
        );

        emit ItemBought(
            order[_orderNonce],
            _orderNonce,
            copies,
            block.timestamp
        );

        if (_order.copies == copies) {
            delete (order[_orderNonce]);
        } else {
            order[_orderNonce].copies -= copies;
        }
        return true;
    }

    /**
     * @dev External function to place open bid in Marketplace
     *
     * @param _orderNonce, Nonce of the order
     * @param copies, copies to be buy
     * @param amount, Amount to be paid
     * @return bool returns true on successful transaction
     */
    function placeOpenBid(
        uint256 _orderNonce,
        uint256 copies,
        uint256 amount
    ) external returns (bool) {
        Order storage _order = order[_orderNonce];
        require(_order.seller != msg.sender, "Seller can't place bid");
        require(
            amount >= _order.price,
            "Amount should be greater than order price"
        );
        require(_order.startTime <= block.timestamp, "Start time not reached");
        require(
            _order.saleType == uint8(SaleType.OpenForBids),
            "Invalid SaleType"
        );
        require(copies > 0 && copies <= _order.copies, "Invalid no of copies");
        if (index[msg.sender][_orderNonce] != 0) {
            Bid storage currentBid = openBids[_orderNonce][
                index[msg.sender][_orderNonce] - 1
            ];
            sendValue(msg.sender, address(this), amount, _order.paymentToken);
            sendDirect(msg.sender, currentBid.amount, _order.paymentToken);
            currentBid.amount = amount;
            currentBid.copies = copies;
        } else {
            sendValue(msg.sender, address(this), amount, _order.paymentToken);
            openBids[_orderNonce].push(
                Bid(
                    msg.sender,
                    copies,
                    amount,
                    block.timestamp,
                    _order.paymentToken
                )
            );
            index[msg.sender][_orderNonce] = openBids[_orderNonce].length;
        }
        emit BidPlaced(_order, _orderNonce, amount, block.timestamp);

        return true;
    }

    /**
     * @dev External function to accept open bid by the seller
     *
     * @param _orderNonce, Nonce of the order
     * @param buyer, receiver address
     * @return bool returns true on successful transaction
     */
    function acceptOpenBid(uint256 _orderNonce, address buyer)
        external
        returns (bool)
    {
        Order storage _order = order[_orderNonce];
        require(_order.seller == msg.sender, "Not the seller");
        Bid storage _bid = openBids[_orderNonce][index[buyer][_orderNonce] - 1];
        uint256 currentBidAmount = _bid.amount;
        require(_bid.copies <= _order.copies, "Invalid no of copies");
        require(currentBidAmount > 0, "No active bids from the buyer");
        uint256 fees = (currentBidAmount * platformFees) / 100;
        if (fees > 0) {
            sendDirect(owner, fees, _order.paymentToken);
        }
        uint256 royaltyFee;
        if (royalties[_order.tokenId].initiated) {
            royaltyFee =
                ((currentBidAmount - fees) *
                    royalties[_order.tokenId].percent) /
                100;
            if (royaltyFee > 0)
                sendDirect(
                    royalties[_order.tokenId].owner,
                    royaltyFee,
                    _order.paymentToken
                );
        } else {
            royalties[_order.tokenId].initiated = true;
        }
        sendDirect(
            (_order.seller),
            (currentBidAmount - royaltyFee - fees),
            _order.paymentToken
        );
        ERC1155Interface.safeTransferFrom(
            address(this),
            buyer,
            _order.tokenId,
            _bid.copies,
            ""
        );
        emit ItemBought(_order, _orderNonce, _bid.copies, block.timestamp);
        if (_order.copies == _bid.copies) {
            delete (order[_orderNonce]);
        } else {
            order[_orderNonce].copies -= _bid.copies;
        }

        delete openBids[_orderNonce][index[buyer][_orderNonce] - 1];
        delete index[buyer][_orderNonce];
        return true;
    }

    /**
     * @dev External function to withdraw placed open bid
     *
     * @param _orderNonce, Nonce of the order
     * @return bool returns true on successful transaction
     */
    function withdrawOpenBid(uint256 _orderNonce) external returns (bool) {
        require(
            index[msg.sender][_orderNonce] != 0,
            "No bids placed by user on selected order"
        );
        require(
            openBids[_orderNonce][index[msg.sender][_orderNonce] - 1]
                .timestamp +
                300 <=
                block.timestamp,
            "Wait at least 5 mins before withdrawaing"
        );
        uint256 currentBidAmount = openBids[_orderNonce][
            index[msg.sender][_orderNonce] - 1
        ].amount;
        require(currentBidAmount > 0, "No bid amount");
        sendDirect(
            msg.sender,
            currentBidAmount,
            openBids[_orderNonce][index[msg.sender][_orderNonce] - 1].token
        );
        emit BidWithdrawn(
            order[_orderNonce],
            _orderNonce,
            currentBidAmount,
            block.timestamp
        );
        delete openBids[_orderNonce][index[msg.sender][_orderNonce] - 1];
        delete index[msg.sender][_orderNonce];
        return true;
    }

    function cancelOrder(uint256 _orderNonce) external returns (bool) {
        Order storage _order = order[_orderNonce];
        require(_order.seller == msg.sender, "Not the seller");
        ERC1155Interface.safeTransferFrom(
            address(this),
            msg.sender,
            _order.tokenId,
            _order.copies,
            ""
        );
        emit OrderCancelled(_order, _orderNonce, block.timestamp);
        delete (order[_orderNonce]);
        return true;
    }

    /**
     * @dev Internal function to send tokens from the user to this contract
     *
     * @param user, address from which tokens need to be sent
     * @param to, address to which tokens need to be sent
     * @param amount, amount to be sent
     */
    function sendValue(
        address user,
        address to,
        uint256 amount,
        address _token
    ) internal {
        uint256 allowance;
        ERC20Interface = IERC20(_token);
        allowance = ERC20Interface.allowance(user, address(this));
        require(allowance >= amount, "Not enough allowance");
        ERC20Interface.safeTransferFrom(user, to, amount);
    }

    /**
     * @dev Internal function to send tokens from the this contract to user
     *
     * @param to, address to which tokens need to be sent
     * @param amount, amount to be sent
     */
    function sendDirect(
        address to,
        uint256 amount,
        address _token
    ) internal {
        ERC20Interface = IERC20(_token);
        ERC20Interface.safeTransfer(to, amount);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return (
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            )
        );
    }
}