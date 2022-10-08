/**
 *Submitted for verification at polygonscan.com on 2022-10-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC1155 is IERC165 {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function isWhitelisted(address user) external returns (bool);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function paymentTokens(address _token) external view returns (bool);

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);

    function xrRoyaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

interface IERC1155Receiver is IERC165 {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

abstract contract ERC165 is IERC165 {
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
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

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

interface ILocking {
    function userDeposits(address user)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool
        );
}

contract MarketPlace is ERC165 {
    using SafeERC20 for IERC20;

    address public owner;
    address public tokenAddress;
    address public xrDynamicAddress;
    address public Treasury;
    uint256 public orderNonce;
    IERC20 public ERC20Interface;
    IERC1155 public ERC1155Interface;
    ILocking public SNFTLockInterface;

    enum SaleType {
        BuyNow,
        DutchAuction    
    }

    struct Order {
        uint256 tokenId;
        uint256 copies;
        address seller;
        SaleType saleType;
        address paymentToken;
        uint256 startTime;
        uint256 endTime;
        uint256 startPrice;
        uint256 endPrice;
        uint256 stepInterval;
        uint256 priceStep;
        bool isReSale;
    }

    //Events
    event OwnerUpdated(address newOwner, uint256 timestamp);
    event OrderPlaced(Order _order, uint256 _orderNonce, uint256 timestamp);
    event OrderCancelled(Order _order, uint256 _orderNonce, uint256 timestamp);
    event ItemBought(
        Order _order,
        uint256 _orderNonce,
        uint256 _copies,
        uint256 timestamp
    );
    
    //Mappings
    mapping(uint256 => Order) public order;
    mapping(uint256 => uint256)public totalRaise;
    mapping(uint256 => mapping(address => uint256))public userLimit;

    constructor(
        address _token,
        address _owner,
        address _xrDynamicAddress,
        address _treasury,
        address _SNFTLock
    ) {
        require(
            _token != address(0) &&
                _owner != address(0) &&
                _owner != address(0) &&
                _SNFTLock != address(0),
            "Zero address"
        );
        ERC1155Interface = IERC1155(_token);
        tokenAddress = _token;
        owner = (_owner);
        xrDynamicAddress = _xrDynamicAddress;
        Treasury = _treasury;
        SNFTLockInterface = ILocking(_SNFTLock);
        emit OwnerUpdated(_owner, block.timestamp);
    }

    function changeOwner(address newOwner) external {
        require(msg.sender == owner, "Only owner");
        require(newOwner != address(0), "Zero address");
        owner = payable(newOwner);
        emit OwnerUpdated(newOwner, block.timestamp);
    }

    function changeTreasury(address _treasury) external returns (bool) {
        require(msg.sender == owner, "Only owner");
        require(_treasury != address(0), "Zero treasury address");
        Treasury = _treasury;
        return true;
    }

    function changeXrDynamicAddress(address _xrDynamicAddress) external returns (bool) {
        require(msg.sender == owner, "Only owner");
        require(_xrDynamicAddress != address(0), "Zero xrDynamic address");
        xrDynamicAddress = _xrDynamicAddress;
        return true;
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


    function placeOrder(
        uint256 tokenId,
        uint256 copies,
        uint256 pricePerNFT,
        uint256 _startTime,
        uint256 _endTime,
        address _paymentToken,
        bool _isResale
    ) external returns (bool){
         require(pricePerNFT > 0, "Invalid price");
        if(!_isResale)require(ERC1155Interface.isWhitelisted(msg.sender), "Not whitelisted");
        require(
            ERC1155Interface.paymentTokens(_paymentToken),
            "ERC20: Token not enabled for payment"
        );
        if (_startTime < block.timestamp) _startTime = block.timestamp;
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
            msg.sender,
             SaleType.BuyNow,
            _paymentToken,
            _startTime,
            _endTime,
            pricePerNFT,
            0,
            0,
            0,
            _isResale
        );
        emit OrderPlaced(order[orderNonce], orderNonce, block.timestamp);
        return true;
    
    }

    function placeDutchOrder(
        uint256 _tokenId,
        uint256 _editions,
        uint256 _pricePerNFT,
        uint256 _startTime,
        uint256 _endPricePerNFT,
        address _paymentToken,
        uint256 _stepInterval,
        uint256 _priceStep,
        bool _isResale
    ) external returns (bool) {
         if(!_isResale)require(ERC1155Interface.isWhitelisted(msg.sender), "Not whitelisted");
        require(
            ERC1155Interface.paymentTokens(_paymentToken),
            "Token not enabled for payment"
        );
        if (_startTime < block.timestamp) _startTime = block.timestamp;
        require(0 < _stepInterval, "0 step interval");
        require(_endPricePerNFT < _pricePerNFT, "Invalid start price");
        require(0 < _endPricePerNFT, "Invalid bottom price");
        require(
            0 < _priceStep && _priceStep < _pricePerNFT,
            "Invalid price step"
        );

        orderNonce = orderNonce + 1;
        ERC1155Interface.safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId,
            _editions,
            ""
        );
        order[orderNonce] = Order(
            _tokenId,
            _editions,
            msg.sender,
            (SaleType.DutchAuction),
            _paymentToken,
            _startTime,
            (_startTime +
                (((_pricePerNFT - _endPricePerNFT) * _stepInterval) /
                    _priceStep)),
            _pricePerNFT,
            _endPricePerNFT,
            _stepInterval,
            _priceStep,
            _isResale
        );
        emit OrderPlaced(order[orderNonce], orderNonce, block.timestamp);
        return true;
    }

    function buy(
        uint256 _orderNonce,
        uint256 copies,
        uint256 amount,
        uint256 platformFees
    ) external returns (bool) {
        Order storage _order = order[_orderNonce];
        require(_order.seller != msg.sender, "Seller can't buy");
        require(_order.startTime <= block.timestamp, "Start time not reached");
        require(_order.endTime >= block.timestamp, "End time reached");
        require(_order.startPrice > 0, "NFT not in marketplace");
        require(_order.saleType == SaleType.BuyNow, "Wrong saletype");
        require(copies > 0 && copies <= _order.copies, "Invalid no of copies");
        require(
            amount ==
                (copies * _order.startPrice) +
                    ((platformFees * (copies * _order.startPrice)) / 100),
            "Incorrect amount price"
        );
        uint256 pnp=1;
        require(
            payment(_order, amount, ((platformFees * (copies * _order.startPrice)) / 100), pnp),
            "Payment failed"
        );
        ERC1155Interface.safeTransferFrom(
            address(this),
            msg.sender,
            _order.tokenId,
            copies,
            ""
        );
        
        addTotalRaise(_order.tokenId, copies * _order.startPrice);

        emit ItemBought(
            order[_orderNonce],
            _orderNonce,
            copies,
            block.timestamp
        );

        if (_order.copies == copies) {
            delete (order[orderNonce]);
        } else {
            order[_orderNonce].copies -= copies;
        }
        return true;
    }

    function buyMatic(
        uint256 _orderNonce,
        uint256 copies,
        uint256 amount,
        uint256 platformFees
    ) external payable returns (bool) {
        Order storage _order = order[_orderNonce];
        require(_order.seller != msg.sender, "Seller can't buy");
        require(_order.startTime <= block.timestamp, "Start time not reached");
        require(_order.endTime >= block.timestamp, "End time reached");
        require(_order.startPrice > 0, "NFT not in marketplace");
        require(_order.saleType == SaleType.BuyNow, "Wrong saletype");
        require(copies > 0 && copies <= _order.copies, "Invalid no of copies");
        require(
            amount ==
                (copies * _order.startPrice) +
                    ((platformFees * (copies * _order.startPrice)) / 100),
            "Incorrect amount price"
        );
        uint256 pnp=2;
        require(
            payment(_order, amount, ((platformFees * (copies * _order.startPrice)) / 100), pnp),
            "Payment failed"
        );
        ERC1155Interface.safeTransferFrom(
            address(this),
            msg.sender,
            _order.tokenId,
            copies,
            ""
        );
        
        addTotalRaise(_order.tokenId, copies * _order.startPrice);

        emit ItemBought(
            order[_orderNonce],
            _orderNonce,
            copies,
            block.timestamp
        );

        if (_order.copies == copies) {
            delete (order[orderNonce]);
        } else {
            order[_orderNonce].copies -= copies;
        }
        return true;
    }

    function buyDutchAuction(
        uint256 _orderNonce,
        uint256 _copies,
        uint256 tokenAmount,
        uint256 platformFees
    ) external returns (bool) {
        Order storage _order = order[_orderNonce];
        require(_order.startPrice > 0, "NFT not in marketplace");
        require(_order.saleType == SaleType.DutchAuction, "Wrong saletype");
        require(_order.startTime <= block.timestamp, "Start time not reached");
        require(_order.seller != msg.sender, "Seller can't buy");
        require(_copies > 0 && _copies <= _order.copies, "Incorrect editions");

        uint256 currentPrice = getCurrentPrice(_orderNonce);

        uint256 totalAmount = (currentPrice * _copies);

        require(
            (totalAmount + ((platformFees * totalAmount) / 100)) <= tokenAmount,
            "Insufficient funds"
        );
        uint256 pnp=1;
        require(
            payment(
                _order,
                (totalAmount + ((platformFees * totalAmount) / 100)),
                ((platformFees * totalAmount) / 100),
                pnp
            ),
            "Payment failed"
        );
        ERC1155Interface.safeTransferFrom(
            address(this),
            msg.sender,
            _order.tokenId,
            _copies,
            ""
        );
        
        addTotalRaise(_order.tokenId, _copies * currentPrice);

        emit ItemBought(
            order[_orderNonce],
            _orderNonce,
            _copies,
            block.timestamp
        );

        if (_order.copies == _copies) {
            delete (order[orderNonce]);
        } else {
            order[_orderNonce].copies -= _copies;
        }
        return true;
    }

    function getCurrentPrice(uint256 _orderNonce)
        public
        view
        returns (uint256 currentPrice)
    {
        Order storage _order = order[_orderNonce];
        if (_order.saleType == SaleType.DutchAuction) {
            uint256 timestamp = block.timestamp;

            uint256 elapsedIntervals = (timestamp - _order.startTime) /
                _order.stepInterval;

            if (
                _order.startPrice > (elapsedIntervals * _order.priceStep) &&
                ((_order.startPrice - (elapsedIntervals * _order.priceStep)) >=
                    _order.endPrice)
            )
                currentPrice =
                    _order.startPrice -
                    (elapsedIntervals * _order.priceStep);
            else {
                currentPrice = _order.endPrice;
            }
        } else {
            currentPrice = _order.startPrice;
        }
    }

    function payment(
        Order memory _order,
        uint256 amount,
        uint256 fees,
        uint256 pnp
    ) internal returns (bool) {
        sendValue(msg.sender, Treasury, fees, _order.paymentToken, pnp);

        amount = amount - fees;
        (address user, uint256 royaltyFee) = ERC1155Interface.royaltyInfo(
            _order.tokenId,
            (amount)
        );

        if (royaltyFee > 0) {
            amount -= royaltyFee;
            sendValue(msg.sender, user, royaltyFee, _order.paymentToken, pnp);
        }

        (address receiver, uint256 xrRoyaltyFee) = ERC1155Interface.xrRoyaltyInfo(
            _order.tokenId,
            (amount)
        );

        if (xrRoyaltyFee > 0) {
            amount -= xrRoyaltyFee;
            sendValue(msg.sender, xrDynamicAddress, xrRoyaltyFee, _order.paymentToken, pnp);
        }
        sendValue(msg.sender, _order.seller, amount, _order.paymentToken, pnp);
        return true;
    }

    function cancelOrder(uint256 _orderNonce) external returns (bool) {
        Order storage _order = order[_orderNonce];
        require(_order.seller == msg.sender, "Not the seller");

        require(block.timestamp >= _order.endTime, "End time not reached");

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

    function sendValue(
        address user,
        address to,
        uint256 amount,
        address _token,
        uint256 pnp
    ) internal {
        uint256 allowance;
        ERC20Interface = IERC20(_token);
        allowance = ERC20Interface.allowance(user, address(this));
        require(allowance >= amount, "Not enough allowance");
        if(pnp==1){
            ERC20Interface.safeTransferFrom(user, to, amount);
        }
        else{
            payable(to).transfer(amount);
        }
    }

    function addTotalRaise(uint256 _tokenId, uint256 _amount)internal{
        totalRaise[_tokenId] += _amount;
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