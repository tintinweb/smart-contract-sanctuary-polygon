/**
 *Submitted for verification at polygonscan.com on 2022-05-10
*/

/**
 *Submitted for verification at polygonscan.com on 2022-05-09
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function paymentTokens(address _token) external view returns (bool);
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
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
    IERC721 public ERC721Interface;

    struct Order {
        uint256 tokenId;
        uint256 price;
        address seller;
        uint8 saleType;
        uint256 startTime;
        uint256 endTime;
        address paymentToken;
    }

    struct Bid {
        address bidder;
        uint256 amount;
        uint256 timestamp;
        address token;
    }

    struct Royalties {
        address owner;
        uint256 percent;
        bool initiated;
    }

    mapping(uint256 => Bid) public bid;
    mapping(uint256 => Order) public order;
    mapping(uint256 => Bid[]) public openBids;
    mapping(uint256 => Royalties) public royalties;
    mapping(address => mapping(uint256 => uint256)) public index;

    uint256 public orderNonce;

    enum SaleType {
        BuyNow,
        Auction,
        OpenForBids
    }

    event PlatformFeesUpdated(uint256 fees, uint256 timestamp);
    event OwnerUpdated(address newOwner, uint256 timestamp);
    event OrderPlaced(Order _order, uint256 _orderNonce, uint256 timestamp);
    event OrderCancelled(Order _order, uint256 _orderNonce, uint256 timestamp);
    event ItemBought(Order _order, uint256 _orderNonce, uint256 timestamp);
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
        ERC721Interface = IERC721(_token);
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
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev External function to place order in Marketplace
     *
     * @param tokenId, tokenId of the NFT
     * @param pricePerNFT, price of the NFT
     * @param _saleType, Type of sale.
     * @param startTime, auction start time.
     * @param endTime, auction end time.
     * @param royaltyAddress, address to receive royalty fees.
     * @param royaltyPercentage, percentage fees.
     * @param _paymentToken, payment token to be used.
     * @return bool returns true on successful transaction
     */
    function placeOrder(
        uint256 tokenId,
        uint256 pricePerNFT,
        SaleType _saleType,
        uint256 startTime,
        uint256 endTime,
        address royaltyAddress,
        uint256 royaltyPercentage,
        address _paymentToken
    ) external returns (bool) {
        require(pricePerNFT > 0, "Invalid price");
        require(royaltyPercentage <= 50, "Royalty fees too high");
        require(
            ERC721Interface.paymentTokens(_paymentToken),
            "ERC20: Token not enabled for payment"
        );
        if (startTime < block.timestamp) startTime = block.timestamp;
        if (_saleType == SaleType.BuyNow || _saleType == SaleType.OpenForBids) {
            endTime = startTime;
        } else {
            require(endTime > startTime, "Invalid endtime for auction");
        }
        ERC721Interface.safeTransferFrom(msg.sender, address(this), tokenId);
        orderNonce++;
        order[orderNonce] = Order(
            tokenId,
            pricePerNFT,
            msg.sender,
            uint8(_saleType),
            startTime,
            endTime,
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
     * @param pricePerNFT, price of the NFT
     * @param saleType, saleType of the order
     * @param user, creator of the NFT
     * @param startTime, auction start time.
     * @param endTime, auction end time.
     * @param royaltyAddress, address to receive royalty fees.
     * @param royaltyPercentage, percentage fees.
     * @param _paymentToken, payment token to be used.
     * @return bool returns true on successful transaction
     */
    function placeOrderByTokenContract(
        uint256 tokenId,
        uint256 pricePerNFT,
        uint8 saleType,
        address user,
        uint256 startTime,
        uint256 endTime,
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
            pricePerNFT,
            user,
            saleType,
            startTime,
            endTime,
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
     * @param amount, Amount to be paid
     * @return bool returns true on successful transaction
     */
    function buy(uint256 _orderNonce, uint256 amount) external returns (bool) {
        Order storage _order = order[_orderNonce];
        require(_order.seller != msg.sender, "Seller can't buy");
        require(_order.startTime <= block.timestamp, "Start time not reached");
        require(_order.price > 0, "NFT not in marketplace");
        require(
            _order.saleType != uint8(SaleType.OpenForBids),
            "Invalid sale type"
        );
        if (_order.saleType == uint8(SaleType.Auction)) {
            require(
                _order.endTime < block.timestamp,
                "Auction still in progress"
            );
            require(bid[_orderNonce].amount == 0, "Active bid on the order");
        }
        require(amount == _order.price, "Incorrect price");
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
        ERC721Interface.safeTransferFrom(
            address(this),
            msg.sender,
            _order.tokenId
        );

        emit ItemBought(order[_orderNonce], _orderNonce, block.timestamp);

        delete (order[_orderNonce]);
        return true;
    }

    /**
     * @dev External function to place auction bid in Marketplace
     *
     * @param _orderNonce, Nonce of the order
     * @param amount, Amount to be paid
     * @return bool returns true on successful transaction
     */
    function placeAuctionBid(uint256 _orderNonce, uint256 amount)
        external
        returns (bool)
    {
        Order storage _order = order[_orderNonce];
        require(_order.seller != msg.sender, "Seller can't place bid");
        require(_order.startTime <= block.timestamp, "Start time not reached");
        require(_order.saleType == uint8(SaleType.Auction), "Invalid SaleType");
        require(
            amount >= _order.price + ((10 * _order.price) / 100),
            "Current bid should be greater than the price"
        );

        require(_order.endTime >= block.timestamp, "Auction ended");

        Bid storage _bid = bid[_orderNonce];
        if (_bid.amount > 0) {
            require(
                amount > _bid.amount + (10 * _bid.amount) / 100,
                "Current bid should be greater than existing bid"
            );
            sendDirect(_bid.bidder, _bid.amount, _order.paymentToken);
        }
        sendValue(msg.sender, address(this), amount, _order.paymentToken);
        bid[_orderNonce] = Bid(
            msg.sender,
            amount,
            block.timestamp,
            _order.paymentToken
        );
        emit BidPlaced(_order, _orderNonce, amount, block.timestamp);
        return true;
    }

    /**
     * @dev External function to claim NFT after auction
     *
     * @param _orderNonce, Nonce of the order
     * @return bool returns true on successful transaction
     */
    function claim(uint256 _orderNonce) external returns (bool) {
        Order storage _order = order[_orderNonce];
        require(_order.saleType == uint8(SaleType.Auction), "Invalid SaleType");
        require(_order.endTime < block.timestamp, "Auction in progress");
        Bid storage _bid = bid[_orderNonce];
        // require(_bid.bidder == msg.sender, "Not highest bidder");
        uint256 fees = (_bid.amount * platformFees) / 100;
        uint256 royaltyFee;
        if (royalties[_order.tokenId].initiated) {
            royaltyFee =
                ((_bid.amount - fees) * royalties[_order.tokenId].percent) /
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
        if (fees > 0) {
            sendDirect(owner, fees, _order.paymentToken);
        }
        sendDirect(
            (_order.seller),
            (_bid.amount - fees - royaltyFee),
            _order.paymentToken
        );
        ERC721Interface.safeTransferFrom(
            address(this),
            _bid.bidder,
            _order.tokenId
        );
        emit ItemBought(order[_orderNonce], _orderNonce, block.timestamp);
        delete bid[_orderNonce];
        delete (order[_orderNonce]);
        return true;
    }

    /**
     * @dev External function to place open bid in Marketplace
     *
     * @param _orderNonce, Nonce of the order
     * @param amount, Amount to be paid
     * @return bool returns true on successful transaction
     */
    function placeOpenBid(uint256 _orderNonce, uint256 amount)
        external
        returns (bool)
    {
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
        if (index[msg.sender][_orderNonce] != 0) {
            Bid storage currentBid = openBids[_orderNonce][
                index[msg.sender][_orderNonce] - 1
            ];
            sendValue(msg.sender, address(this), amount, _order.paymentToken);
            sendDirect(msg.sender, currentBid.amount, _order.paymentToken);
            currentBid.amount = amount;
        } else {
            sendValue(msg.sender, address(this), amount, _order.paymentToken);
            openBids[_orderNonce].push(
                Bid(msg.sender, amount, block.timestamp, _order.paymentToken)
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
        uint256 currentBidAmount = openBids[_orderNonce][
            index[buyer][_orderNonce] - 1
        ].amount;
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
        ERC721Interface.safeTransferFrom(address(this), buyer, _order.tokenId);
        emit ItemBought(_order, _orderNonce, block.timestamp);
        delete openBids[_orderNonce][index[buyer][_orderNonce] - 1];
        delete index[buyer][_orderNonce];
        delete (order[_orderNonce]);
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
        if (
            _order.saleType == uint8(SaleType.Auction) &&
            bid[_orderNonce].amount > 0
        ) {
            sendDirect(
                bid[_orderNonce].bidder,
                bid[_orderNonce].amount,
                _order.paymentToken
            );
            delete bid[_orderNonce];
        }
        ERC721Interface.safeTransferFrom(
            address(this),
            msg.sender,
            _order.tokenId
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

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return (
            bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))
        );
    }
}