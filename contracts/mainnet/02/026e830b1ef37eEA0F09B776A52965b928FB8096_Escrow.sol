/**
 *Submitted for verification at polygonscan.com on 2022-08-02
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165Storage is IERC165 {
    mapping(bytes4 => bool) private _supportsInterface;

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC165).interfaceId ||
            _supportsInterface[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportsInterface[interfaceId] = true;
    }
}

interface IERC1155 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function ownerOfToken(uint256 _tokenId)
        external
        view
        returns (
            address,
            uint256,
            address,
            uint256
        );

    function paymentEnabled(address token) external view returns (bool);

    function burn(
        address from,
        uint256 _tokenId,
        uint256 amount
    ) external returns (bool);

    function release(uint256 _token) external;
}

interface IERC1155Receiver {
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

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
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

contract Escrow is ERC165Storage {
    using SafeERC20 for IERC20;

    bool private locked;
    uint256 public orderNonce;
    // address public tokenAddress;
    address payable public admin;
    IERC20 internal ERC20Interface;
    IERC1155 public ERC1155Interface;

    struct Order {
        address token;
        address seller;
        uint256 tokenId;
        uint256 amount;
        uint256 pricePerNFT;
        uint256 saleType;
        uint256 saleStart;
        uint256 timeline;
        address paymentToken;
    }

    struct Bid {
        address bidder;
        uint256 bidValue;
        uint256 timeStamp;
    }

    struct Fee {
        uint8 platformCutFirstHand;
        uint8 platformCutSecondHand;
        uint8 creatorRoyalty;
    }

    mapping(address => Fee) public fee;
    mapping(uint256 => Order) public order;
    mapping(address => bool) public whitelist;
    mapping(address => mapping(uint256 => mapping(uint256 => Bid))) bid;
    mapping(address => mapping(uint256 => mapping(uint256 => bool))) burnt;
    mapping(address => mapping(uint256 => mapping(uint256 => bool))) secondHand;
    mapping(address => mapping(uint256 => mapping(uint256 => address))) holder;
    mapping(address => mapping(uint256 => uint256)) public tokenEditions;
    mapping(address => mapping(uint256 => uint256)) internal flexPlatFee;
    mapping(address => mapping(uint256 => uint256)) internal secondHandOrder;

    event OrderPlaced(
        Order order,
        uint256 timestamp,
        uint256 nonce,
        uint256 editionNumber
    );
    event OrderBought(
        Order order,
        uint256 timestamp,
        address buyer,
        uint256 nonce,
        uint256 editionNumber
    );
    event OrderCancelled(
        Order order,
        uint256 timestamp,
        uint256 nonce,
        uint256 editionNumber
    );
    event BidPlaced(
        Order order,
        uint256 timestamp,
        address buyer,
        uint256 nonce,
        uint256 editionNumber
    );

    event EditionTransferred(
        address from,
        address to,
        uint256 id,
        uint256 edition,
        address mintingAddress
    );

    event AdminChanged(address newAdmin, uint256 timestamp);

    event FeesUpdated(Fee _fee, uint256 timestamp);

    event TokenStatusAdded(
        address indexed _tokenAddress,
        bool _status,
        uint256 timestamp
    );

    constructor(
        address _admin,
        uint8 _firstHandPlatFee,
        uint8 _secondHandPlatfee,
        uint8 _creatorRoyalty
    ) {
        require(_admin != address(0), "Zero address");
        require(
            _firstHandPlatFee <= 50 &&
                _secondHandPlatfee <= 40 &&
                _creatorRoyalty <= 40,
            "Fee too high"
        );
        admin = payable(_admin);
        fee[address(this)] = Fee(
            _firstHandPlatFee,
            _secondHandPlatfee,
            _creatorRoyalty
        );
        _registerInterface(type(IERC1155Receiver).interfaceId);
        emit AdminChanged(_admin, block.timestamp);
        emit FeesUpdated(fee[address(this)], block.timestamp);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    function changeAdmin(address _admin) external onlyAdmin returns (bool) {
        require(_admin != address(0), "Zero admin address");
        admin = payable(_admin);
        emit AdminChanged(_admin, block.timestamp);
        return true;
    }

    function setFees(
        uint8 _firstHandPlatFee,
        uint8 _secondHandPlatfee,
        uint8 _creatorRoyalty
    ) external onlyAdmin {
        require(
            _firstHandPlatFee <= 50 &&
                _secondHandPlatfee <= 40 &&
                _creatorRoyalty <= 40,
            "Fee too high"
        );
        fee[address(this)] = Fee(
            _firstHandPlatFee,
            _secondHandPlatfee,
            _creatorRoyalty
        );
        emit FeesUpdated(fee[address(this)], block.timestamp);
    }

    function addTokenAddress(address _tokenAddress)
        external
        onlyAdmin
        returns (bool)
    {
        require(_tokenAddress != address(0), "Zero address");
        whitelist[_tokenAddress] = true;
        emit TokenStatusAdded(_tokenAddress, true, block.timestamp);
        return true;
    }

    function removeTokenAddress(address _tokenAddress)
        external
        onlyAdmin
        returns (bool)
    {
        require(whitelist[_tokenAddress], "Not whitelisted");
        whitelist[_tokenAddress] = false;
        emit TokenStatusAdded(_tokenAddress, false, block.timestamp);
        return true;
    }

    function currentHolder(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _editionNumber
    ) public view returns (address) {
        if (
            _editionNumber > tokenEditions[_tokenAddress][_tokenId] ||
            _editionNumber == 0
        ) return address(0);
        if (burnt[_tokenAddress][_tokenId][_editionNumber]) return address(0);
        if (holder[_tokenAddress][_tokenId][_editionNumber] == address(0)) {
            (address creator1, , , ) = IERC1155(_tokenAddress).ownerOfToken(
                _tokenId
            );
            return creator1;
        }
        return holder[_tokenAddress][_tokenId][_editionNumber];
    }

    modifier tokenCheck(address _tokenAddress) {
        require(
            whitelist[_tokenAddress],
            "Minting token address is not whitelisted"
        );
        ERC1155Interface = IERC1155(_tokenAddress);
        _;
    }

    function placeOrder(
        address _creator,
        uint256 _tokenId,
        uint256 _editions,
        uint256 _pricePerNFT,
        uint256 _saleType,
        uint256[2] memory _times,
        uint256 _adminPlatformFee,
        address _paymentToken
    ) external tokenCheck(msg.sender) returns (bool) {
        require(_editions > 0, "0 editions");
        require(_pricePerNFT > 0, "0 price");
        require(_adminPlatformFee < 51, "Too high");

        uint256 _startTime = _times[0];
        uint256 _timeline = _times[1];

        if (_startTime < block.timestamp) {
            _startTime = block.timestamp;
        }

        if (_saleType == 0) {
            _timeline = _startTime;
        } else {
            _timeline = _startTime + (_timeline * (3600)); //Change 30 to 1 for unit testing and 3600 for production
        }
        tokenEditions[msg.sender][_tokenId] = _editions;
        flexPlatFee[msg.sender][_tokenId] = _adminPlatformFee;
        orderNonce = orderNonce + 1;
        order[orderNonce] = Order(
            msg.sender,
            _creator,
            _tokenId,
            _editions,
            _pricePerNFT,
            _saleType,
            _startTime,
            _timeline,
            _paymentToken
        );

        emit OrderPlaced(
            order[orderNonce],
            block.timestamp,
            orderNonce,
            _editions
        );

        return true;
    }

    function buyNow(
        uint256 _orderNonce,
        uint256 _editionNumber,
        uint256 _tokenAmount
    ) external payable returns (bool) {
        Order memory _order = order[_orderNonce];
        require(_order.seller != address(0), "Expired");
        require(_order.saleStart <= block.timestamp, "Not started");
        require(
            _editionNumber > 0 &&
                _editionNumber <= tokenEditions[_order.token][_order.tokenId],
            "Wrong edition"
        );
        require(
            _order.saleType == 0 ||
                _order.saleType == 1 ||
                _order.saleType == 2,
            "Wrong saletype"
        );
        if (_order.saleType == 2) {
            require(
                secondHandOrder[_order.seller][_orderNonce] == _editionNumber,
                "Wrong edition"
            );
        }
        if (_order.saleType == 1) {
            require(block.timestamp > _order.timeline, "In progress");
            require(
                bid[_order.token][_order.tokenId][_editionNumber].bidder ==
                    address(0),
                "Active"
            );
        }
        require(_order.seller != msg.sender, "Seller can't buy");
        uint256 amount;
        if (_order.paymentToken == address(0)) {
            amount = msg.value;
        } else {
            amount = _tokenAmount;
        }
        require(amount == (_order.pricePerNFT), "Wrong price");
        require(
            currentHolder(_order.token, _order.tokenId, _editionNumber) ==
                _order.seller ||
                currentHolder(_order.token, _order.tokenId, _editionNumber) ==
                address(this),
            "Already sold"
        );
        if (_order.paymentToken == address(0)) {
            require(
                buyNowPayment(_order, _editionNumber, msg.value),
                "Payment Failed"
            );
        } else {
            require(buyNowPayment(_order, _editionNumber, _tokenAmount));
        }
        holder[_order.token][_order.tokenId][_editionNumber] = msg.sender;
        IERC1155(_order.token).safeTransferFrom(
            address(this),
            msg.sender,
            _order.tokenId,
            1,
            ""
        );

        emit OrderBought(
            _order,
            block.timestamp,
            msg.sender,
            _orderNonce,
            _editionNumber
        );

        if (_order.amount == 1) {
            delete order[_orderNonce];
        } else {
            order[_orderNonce].amount = order[_orderNonce].amount - 1;
        }
        return true;
    }

    function buyAndTransfer(
        address user,
        uint256 _orderNonce,
        uint256 _editionNumber,
        uint256 _tokenAmount
    ) external payable returns (bool) {
        Order memory _order = order[_orderNonce];
        require(_order.seller != address(0), "Expired");
        require(_order.saleStart <= block.timestamp, "Not started");
        require(
            _editionNumber > 0 &&
                _editionNumber <= tokenEditions[_order.token][_order.tokenId],
            "Wrong edition"
        );
        require(
            _order.saleType == 0 ||
                _order.saleType == 1 ||
                _order.saleType == 2,
            "Wrong saletype"
        );
        if (_order.saleType == 2) {
            require(
                secondHandOrder[_order.seller][_orderNonce] == _editionNumber,
                "Wrong edition"
            );
        }
        if (_order.saleType == 1) {
            require(block.timestamp > _order.timeline, "In progress");
            require(
                bid[_order.token][_order.tokenId][_editionNumber].bidder ==
                    address(0),
                "Active bidding"
            );
        }
        require(_order.seller != user, "Seller can't buy");
        uint256 amount;
        if (_order.paymentToken == address(0)) {
            amount = msg.value;
        } else {
            amount = _tokenAmount;
        }
        require(amount == (_order.pricePerNFT), "Wrong price");
        require(
            currentHolder(_order.token, _order.tokenId, _editionNumber) ==
                _order.seller ||
                currentHolder(_order.token, _order.tokenId, _editionNumber) ==
                address(this),
            "Already sold"
        );
        if (_order.paymentToken == address(0)) {
            require(
                buyNowPayment(_order, _editionNumber, msg.value),
                "Payment Failed"
            );
        } else {
            require(buyNowPayment(_order, _editionNumber, _tokenAmount));
        }
        holder[_order.token][_order.tokenId][_editionNumber] = user;
        IERC1155(_order.token).safeTransferFrom(
            address(this),
            user,
            _order.tokenId,
            1,
            ""
        );

        emit OrderBought(
            _order,
            block.timestamp,
            user,
            _orderNonce,
            _editionNumber
        );

        if (_order.amount == 1) {
            delete order[_orderNonce];
        } else {
            order[_orderNonce].amount = order[_orderNonce].amount - 1;
        }
        return true;
    }

    function buyNowPayment(
        Order memory _order,
        uint256 _editionNumber,
        uint256 payAmount
    ) internal returns (bool) {
        uint256 platformCut;
        uint256 creatorsCut;
        uint256 finalCut;
        uint256 creatorCut;
        uint256 coCreatorCut;
        (address _creator, uint256 _percent1, address _coCreator, ) = IERC1155(
            _order.token
        ).ownerOfToken(_order.tokenId);

        if (!secondHand[_order.token][_order.tokenId][_editionNumber]) {
            if (flexPlatFee[_order.token][_order.tokenId] > 0) {
                uint256 flexFee = flexPlatFee[_order.token][_order.tokenId];
                platformCut = (payAmount * (flexFee)) / (100);
            } else {
                platformCut =
                    (payAmount * (fee[address(this)].platformCutFirstHand)) /
                    (100);
            }
            creatorsCut = payAmount - (platformCut);
            IERC1155(_order.token).release(_order.tokenId);
            secondHand[_order.token][_order.tokenId][_editionNumber] = true;
        } else {
            platformCut =
                (payAmount * (fee[address(this)].platformCutSecondHand)) /
                (100);
            creatorsCut =
                (payAmount * (fee[address(this)].creatorRoyalty)) /
                (100);
            finalCut = payAmount - (platformCut + (creatorsCut));
        }

        creatorCut = (creatorsCut * (_percent1)) / (100);
        coCreatorCut = creatorsCut - (creatorCut);

        if (_order.paymentToken == address(0)) {
            sendValue(payable(_creator), creatorCut);
            if (coCreatorCut > 0) {
                sendValue(payable(_coCreator), coCreatorCut);
            }
            sendValue(admin, platformCut);
            if (finalCut > 0) {
                sendValue(payable(_order.seller), finalCut);
            }
        } else {
            require(msg.value == 0, "Sent ETH for ERC20 payments");
            tokenPay(msg.sender, _creator, creatorCut, _order.paymentToken);
            if (coCreatorCut > 0) {
                tokenPay(
                    msg.sender,
                    _coCreator,
                    coCreatorCut,
                    _order.paymentToken
                );
            }
            tokenPay(msg.sender, admin, platformCut, _order.paymentToken);
            if (finalCut > 0) {
                tokenPay(
                    msg.sender,
                    _order.seller,
                    finalCut,
                    _order.paymentToken
                );
            }
        }

        return true;
    }

    function tokenPay(
        address from,
        address to,
        uint256 amount,
        address token
    ) internal _hasAllowance(from, amount, token) returns (bool) {
        ERC20Interface = IERC20(token);
        ERC20Interface.safeTransferFrom(from, to, amount);
        return true;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Low balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Error");
    }

    modifier _hasAllowance(
        address allower,
        uint256 amount,
        address token
    ) {
        // Make sure the allower has provided the right allowance.
        ERC20Interface = IERC20(token);
        uint256 ourAllowance = ERC20Interface.allowance(allower, address(this));
        require(amount <= ourAllowance, "Low allowance");
        _;
    }

    function placeBid(
        uint256 _orderNonce,
        uint256 _editionNumber,
        uint256 _tokenAmount
    ) external payable returns (bool) {
        Order memory _order = order[_orderNonce];
        require(!locked, "Locked");
        locked = true;
        require(_order.seller != address(0), "Expired");
        require(_order.seller != msg.sender, "Owner can't place bid");
        require(_order.saleStart <= block.timestamp, "Auction not started");
        require(block.timestamp <= _order.timeline, "Auction ended");
        require(_order.saleType == 1, "Wrong saletype");
        require(
            _editionNumber > 0 &&
                _editionNumber <= tokenEditions[_order.token][_order.tokenId],
            "Wrong edition"
        );
        uint256 amount;
        if (_order.paymentToken == address(0)) {
            amount = msg.value;
        } else {
            amount = _tokenAmount;
        }
        require(
            amount > _order.pricePerNFT &&
                amount >=
                ((bid[_order.token][_order.tokenId][_editionNumber].bidValue *
                    (11)) / (10)),
            "Wrong Price"
        );
        require(checkBidStatus(_order, _editionNumber, amount));

        bid[_order.token][_order.tokenId][_editionNumber] = Bid(
            msg.sender,
            amount,
            block.timestamp
        );

        emit BidPlaced(
            _order,
            block.timestamp,
            msg.sender,
            _orderNonce,
            _editionNumber
        );
        locked = false;
        return true;
    }

    function checkBidStatus(
        Order memory _order,
        uint256 _editionNumber,
        uint256 amount
    ) internal returns (bool) {
        if (_order.paymentToken == address(0)) {
            if (
                bid[_order.token][_order.tokenId][_editionNumber].bidder !=
                address(0)
            ) {
                sendValue(
                    payable(
                        bid[_order.token][_order.tokenId][_editionNumber].bidder
                    ),
                    bid[_order.token][_order.tokenId][_editionNumber].bidValue
                );
                delete bid[_order.token][_order.tokenId][_editionNumber];
            }
        } else {
            require(msg.value == 0, "Sent ETH for ERC20 payments");
            if (
                bid[_order.token][_order.tokenId][_editionNumber].bidder !=
                address(0)
            ) {
                ERC20Interface = IERC20(_order.paymentToken);
                ERC20Interface.safeTransfer(
                    bid[_order.token][_order.tokenId][_editionNumber].bidder,
                    bid[_order.token][_order.tokenId][_editionNumber].bidValue
                );
            }
            tokenPay(msg.sender, address(this), amount, _order.paymentToken);
        }
        return true;
    }

    function claimAfterAuction(uint256 _orderNonce, uint256 _editionNumber)
        external
        returns (bool)
    {
        Order memory _order = order[_orderNonce];
        require(block.timestamp > _order.timeline, "In progress");
        require(
            msg.sender ==
                bid[_order.token][_order.tokenId][_editionNumber].bidder,
            "Not highest bidder"
        );

        uint256 bidAmount = bid[_order.token][_order.tokenId][_editionNumber]
            .bidValue;

        delete bid[_order.token][_order.tokenId][_editionNumber];

        require(buyNowPayment(_order, _editionNumber, bidAmount));

        IERC1155(_order.token).safeTransferFrom(
            address(this),
            msg.sender,
            _order.tokenId,
            1,
            ""
        );

        holder[_order.token][_order.tokenId][_editionNumber] = msg.sender;

        if (_order.amount == 1) {
            delete order[_orderNonce];
        } else {
            order[_orderNonce].amount = order[_orderNonce].amount - 1;
        }

        _order.pricePerNFT = bidAmount;

        emit OrderBought(
            _order,
            block.timestamp,
            msg.sender,
            _orderNonce,
            _editionNumber
        );
        return true;
    }

    function placeSecondHandOrder(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _editionNumber,
        uint256 _pricePerNFT,
        uint256 _saleType,
        address _paymentToken
    ) external tokenCheck(_tokenAddress) returns (bool) {
        require(
            secondHand[_tokenAddress][_tokenId][_editionNumber],
            "Edition not in second market"
        );
        require(
            currentHolder(_tokenAddress, _tokenId, _editionNumber) ==
                msg.sender,
            "Not owner"
        );
        require(_saleType == 2, "Wrong saleType");
        require(
            ERC1155Interface.paymentEnabled(_paymentToken),
            "Token not supported"
        );

        ERC1155Interface.safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId,
            1,
            ""
        );
        orderNonce = orderNonce + (1);
        secondHandOrder[msg.sender][orderNonce] = _editionNumber;
        holder[_tokenAddress][_tokenId][_editionNumber] = address(this);
        order[orderNonce] = Order(
            _tokenAddress,
            msg.sender,
            _tokenId,
            1,
            _pricePerNFT,
            _saleType,
            block.timestamp,
            0,
            _paymentToken
        );

        emit OrderPlaced(
            order[orderNonce],
            block.timestamp,
            orderNonce,
            _editionNumber
        );

        return true;
    }

    function cancelSaleOrder(uint256 _orderNonce, uint256 _editionNumber)
        external
        returns (bool)
    {
        Order memory _order = order[_orderNonce];
        require(_order.saleType == 2, "Invalid sale type");
        require(_order.seller == msg.sender, "Not the seller");
        require(
            secondHandOrder[_order.seller][_orderNonce] == _editionNumber,
            "Incorrect edition"
        );
        IERC1155(_order.token).safeTransferFrom(
            address(this),
            msg.sender,
            _order.tokenId,
            1,
            ""
        );

        holder[_order.token][_order.tokenId][_editionNumber] = msg.sender;

        emit OrderCancelled(
            _order,
            block.timestamp,
            _orderNonce,
            _editionNumber
        );

        delete secondHandOrder[msg.sender][_orderNonce];
        delete order[_orderNonce];
        return true;
    }

    function updatePrice(
        uint256 _orderNonce,
        uint256 _editionNumber,
        uint256 _pricePerNFT
    ) external returns (bool) {
        Order storage _order = order[_orderNonce];
        require(_order.saleType == 2, "Invalid sale type");
        require(_order.seller == msg.sender, "Not the seller");
        require(
            secondHandOrder[_order.seller][_orderNonce] == _editionNumber,
            "Incorrect edition"
        );
        _order.pricePerNFT = _pricePerNFT;
        return true;
    }

    function transfer(
        address from,
        address to,
        uint256 id,
        uint256 editionNumber,
        bytes memory data,
        address _tokenAddress
    ) external returns (bool) {
        require(
            secondHand[_tokenAddress][id][editionNumber],
            "Edition is not in secondhand market"
        );
        require(
            currentHolder(_tokenAddress, id, editionNumber) == msg.sender,
            "Not the current holder for edition"
        );
        IERC1155(_tokenAddress).safeTransferFrom(from, to, id, 1, data);
        holder[_tokenAddress][id][editionNumber] = to;
        emit EditionTransferred(from, to, id, editionNumber, _tokenAddress);
        return true;
    }

    function burnTokenEdition(
        uint256 _tokenId,
        uint256 _editionNumber,
        address _tokenAddress
    ) external returns (bool) {
        require(
            secondHand[_tokenAddress][_tokenId][_editionNumber],
            "Edition is not in secondhand market"
        );
        require(
            currentHolder(_tokenAddress, _tokenId, _editionNumber) ==
                msg.sender,
            "Not the current holder for edition"
        );
        IERC1155(_tokenAddress).burn(msg.sender, _tokenId, 1);
        burnt[_tokenAddress][_tokenId][_editionNumber] = true;
        emit EditionTransferred(
            msg.sender,
            address(0),
            _tokenId,
            _editionNumber,
            _tokenAddress
        );
        return true;
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