//Note: Optimization needs to be enabled in this contract
pragma solidity ^0.8;

// import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
//import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./IMemberManagement.sol";
import "./NMNFactory.sol";
import "./NMNFactory721.sol";

/// @title Escrow smart contract for CryptoMintr Protocol
/// @author Naman R. Bhardwaj, Lokesh Nalot
/// @notice This smart contract manages members' collected commissions and orders for the CryptoMintr protocol
/// @dev For using on multiple chains, the numbering distinction may have to be changed, or maybe simply managed in database. Communicates with MemberManagement contact for commission percentages


contract NMNEscrow is ERC1155Holder, ERC721Holder, ReentrancyGuard {
    using SafeMath for uint256;

    constructor(
        IMemberManagement _member,
        address[4] memory addresses,
        address[] memory _whiteList,
        address _protocolFundsWithdrawer
    ) {
        member = _member;
        orderCtr = 0;
        protocolFundsWithdrawer = _protocolFundsWithdrawer;
        nonce = 124;
        for (uint256 i = 0; i < 4; i++) {
            signers[i] = addresses[i];
        }
        for (uint256 j = 0; j < _whiteList.length; j++)
            whiteList.push(_whiteList[j]);
        messageHash = keccak256(
            abi.encodePacked(
                addresses[0],
                addresses[1],
                addresses[2],
                addresses[3],
                nonce
            )
        );
    }

    enum Stage {
        NOT_LISTED,
        LISTED,
        PARTIALLY_SOLD,
        ORDER_CLOSED
    }
    enum orderType {
        None,
        auction,
        sale
    }
    enum nftType {
        None,
        ERC721,
        ERC1155
    }
    struct Order {
        Stage stage;
        uint256 id;
        address payable seller;
        uint256 tokenID;
        address contractAddr;
        uint256 highestBid;
        address highestBidder;
        uint256 minBid; //Can work as sale price
        uint256 timeLimit;
        uint256 reservePrice;
        uint256 publisherID;
        uint256 publisherIDBidder;
        uint256 amountToSell;
    }

    modifier onlyOwner() {
        require(msg.sender == protocolFundsWithdrawer, "Only owner can access this function");
        _;
    }

    uint256 public minWithdrawl = 1000000000000000000; // 1 MATIC
    IMemberManagement member;
    uint256 public orderCtr;
    //orderID to orders
    mapping(uint256 => Order) public ORDER;
    //publisherID to earnings
    mapping(uint256 => uint256) memberEarnings;
    //orderID to orderType
    mapping(uint256 => orderType) TypeMapping;
    //orderID to token type
    mapping(uint256 => nftType) public tokenType;
    uint256 bidIncrementPercent = 5;
    uint256 bidIncrementAmt = 50000000000000000;
    address[4] signers;
    uint256 nonce;
    bytes32 public messageHash;
    address public protocolFundsWithdrawer;
    address[] whiteList;
    //Min. Bid price of any token should be set greater than 0.01 ether and user can set its minimum anything above this
    uint256 public minPrice = 10000000000000000; //0.01 ether

    event BidPlaced(
        address indexed _seller,
        address indexed _bidder,
        uint256 orderId,
        uint256 _tokenId,
        uint256 indexed _bidderMarketMemberID
    );
    event TokenSold(
        address indexed _seller,
        address indexed _buyer,
        uint256 orderId,
        uint256 _tokenIdPurchased,
        uint256 indexed _bidderMarketMemberID
    );
    event TokenListedAuction(
        address indexed _seller,
        address indexed _contract,
        uint256 _tokenIdListed,
        uint256 orderId,
        uint256 _price,
        uint256 indexed _memberID,
        uint256 exptime
    );
    event AuctionCancelled(
        address indexed _seller,
        uint256 indexed _tokenID,
        uint256 orderId,
        uint256 indexed _memberID
    );

    event EarningsCreditedLister(
        uint256 indexed _memberId,
        uint256 _amtCredited,
        bool indexed isSale //true for sale, false for auction
    );

    event EarningsCreditedSeller(
        uint256 indexed _memberId,
        uint256 _amtCredited,
        bool indexed isSale //true for sale, false for auction
    );

    event EarningsWithdrawn(
        uint256 indexed _memberID,
        uint256 indexed _amtWithdrawn
    );

    function changeMinAuctionPrice(uint256 _new) public onlyOwner{
        minPrice = _new;
    }

    function changeBidIncAmt(uint256 _amt) public onlyOwner {
        bidIncrementAmt = _amt;
    }

    function changeBidIncPercent(uint256 _per) public onlyOwner {
        bidIncrementPercent = _per;
    }

    function withdrawProtocolEarnings(uint256 _amount, address payable _to)
        public
    {
        require(protocolFundsWithdrawer == msg.sender, "Invalid caller!!!");
        require(_amount <= memberEarnings[0], "Not enough balance!!!");
        memberEarnings[0] = memberEarnings[0].sub(_amount);
        bool processed = false;
        for (uint256 i = 0; i < whiteList.length; i++) {
            if (whiteList[i] == _to) {
                processed = true;
                break;
            }
        }
        require(processed == true, "Address not present in whitelist!!!");
        emit EarningsWithdrawn(0, _amount);
        _to.transfer(_amount);
    }

    function withdrawEarnings(uint256 _memberID, uint256 _amount) public {
        require(
            _memberID > 0 && _memberID <= member.memberCount(),
            "Invalid member ID provided!!!"
        );
        require(
            msg.sender == member.getAddress(_memberID) || msg.sender == address(this),
            "Invalid caller!!!"
        );
        if(msg.sender != protocolFundsWithdrawer)
            require(_amount >= minWithdrawl, "Minimum withdraw amount not met!!!");
        require(_amount <= memberEarnings[_memberID], "Not enough balance!!!");

        memberEarnings[_memberID] = memberEarnings[_memberID].sub(_amount);
        emit EarningsWithdrawn(_memberID, _amount);
        payable(member.getAddress(_memberID)).transfer(_amount);
    }

    //Publisher balance function, can only be checked by owner, member themselves, or the contract itself 
    function balance(uint256 _memberID) public view returns (uint256) {
        require(
            _memberID >= 0 && _memberID <= member.memberCount(),
            "Invalid member ID provided!!!"
        );
        if (_memberID == 0)
            require(msg.sender == protocolFundsWithdrawer, "Invalid caller!!!");
        else
            require(
                msg.sender == member.getAddress(_memberID) || msg.sender == address(this) || msg.sender == protocolFundsWithdrawer,
                "Invalid caller!!!"
            );
        return memberEarnings[_memberID];
    }

    function listForAuction(
        address _contract,
        uint256 _tokenId,
        uint256 _minBid,
        uint256 _dayLimit,
        uint256 _reservePrice,
        uint256 _publisherID,
        nftType tktype
    ) public {
        require(_contract != address(0), "Null contract address provided!!!");
        NMNFactory token;
        NMNFactory721 token721;
        if (tktype == nftType.ERC1155) token = NMNFactory(_contract);
        else token721 = NMNFactory721(_contract);
        require(
            _publisherID > 0 && _publisherID <= member.memberCount(),
            "please enter a valid Publisher ID!!!"
        );
        require(
            member.getPublisherStatus(_publisherID) == true,
            "Publisher inactive!!!"
        );
        require(
            _minBid <= _reservePrice,
            "Minimum bid cannot be greater than reserve price!!!"
        );
        require(
            _minBid >= minPrice,
            "Min Bid Price should be set more than 10000000000000000 wei!!!"
        );
        if (tktype == nftType.ERC1155) {
            require(
                token.isApprovedForAll(msg.sender, address(this)) == true,
                "Escrow not approved!!!"
            );
            require(
                token.balanceOf(msg.sender, _tokenId) >= 1,
                "Not enough tokens in your wallet!!!"
            );
            orderCtr = orderCtr.add(1);
            TypeMapping[orderCtr] = orderType.auction;
            tokenType[orderCtr] = tktype;
            ORDER[orderCtr] = Order(
                Stage.LISTED,
                orderCtr,
                payable(msg.sender),
                _tokenId,
                _contract,
                0,
                address(0),
                _minBid,
                block.timestamp.add(_dayLimit.mul(1 days)),
                _reservePrice,
                _publisherID,
                0,
                1
            );
            token.safeTransferFrom(msg.sender, address(this), _tokenId, 1, "");
        } else if (tktype == nftType.ERC721) {
            require(
                token721.isApprovedForAll(msg.sender, address(this)) == true,
                "Escrow not approved!!!"
            );
            require(
                token721.balanceOf(msg.sender) >= 1,
                "Not enough tokens in your wallet!!!"
            );
            orderCtr = orderCtr.add(1);
            TypeMapping[orderCtr] = orderType.auction;
            tokenType[orderCtr] = tktype;
            ORDER[orderCtr] = Order(
                Stage.LISTED,
                orderCtr,
                payable(msg.sender),
                _tokenId,
                _contract,
                0,
                address(0),
                _minBid,
                block.timestamp.add(_dayLimit.mul(1 days)),
                _reservePrice,
                _publisherID,
                0,
                1
            );
            token721.safeTransferFrom(msg.sender, address(this), _tokenId, "");
        } else revert("Invalid contract type");

        emit TokenListedAuction(
            msg.sender,
            _contract,
            _tokenId,
            orderCtr,
            _minBid,
            _publisherID,
            ORDER[orderCtr].timeLimit
        );
    }

    function unlistAuction(uint256 orderID) public {
        require(
            msg.sender == ORDER[orderID].seller || msg.sender == address(this),
            "Only seller can access this function!!!"
        );
        require(
            (orderID > 0) && (orderID <= orderCtr),
            "Invalid Order ID provided!!!"
        );
        require(
            TypeMapping[orderID] == orderType.auction,
            "Order ID-Type mismatch"
        );
        require(ORDER[orderID].stage == Stage.LISTED, "Wrong Token stage!!!");
        ORDER[orderID].stage = Stage.ORDER_CLOSED; //To prevent Reentrancy
        emit AuctionCancelled(
            ORDER[orderID].seller,
            ORDER[orderID].tokenID,
            orderID,
            ORDER[orderID].publisherID
        );
        if (tokenType[orderID] == nftType.ERC1155) {
            NMNFactory token = NMNFactory(ORDER[orderID].contractAddr);
            token.safeTransferFrom(
                address(this),
                ORDER[orderID].seller,
                ORDER[orderID].tokenID,
                1,
                ""
            );
        } else {
            NMNFactory721 token = NMNFactory721(ORDER[orderID].contractAddr);
            token.safeTransferFrom(
                address(this),
                ORDER[orderID].seller,
                ORDER[orderID].tokenID,
                ""
            );
        }
        if (ORDER[orderID].highestBid != 0) {
            payable(ORDER[orderID].highestBidder).transfer(
                ORDER[orderID].highestBid
            );
        }
    }

    function bid(uint256 orderID, uint256 _publisherIDBidder)
        public
        payable
        nonReentrant
    {
        require(
            TypeMapping[orderID] == orderType.auction,
            "Order ID-Type mismatch"
        );
        require(
            _publisherIDBidder > 0 &&
                _publisherIDBidder <= member.memberCount(),
            "please enter a valid Publisher ID!!!"
        );
        require(
            member.getPublisherStatus(_publisherIDBidder) == true,
            "Publisher not active!!!"
        );

        require(
            member.getPublisherStatus(ORDER[orderID].publisherID) == true,
            "Publisher this was listed on is not active, So not accepting any new bids!!!"
        );

        require(
            (orderID > 0) && (orderID <= orderCtr),
            "Invalid Order ID provided!!!"
        );
        require(
            member.tokenTradableAmongPublishers(
                ORDER[orderID].publisherID,
                _publisherIDBidder
            ) == true,
            "Token not tradable on this platform!!!"
        );
        require(ORDER[orderID].stage == Stage.LISTED, "Order is closed!!!");
        require(
            msg.sender != ORDER[orderID].seller,
            "Sellers can't buy their own token!!!"
        );
        require(
            msg.value > ORDER[orderID].highestBid &&
                msg.value >= ORDER[orderID].minBid,
            "Insufficient bid!!!"
        );
        require(
            block.timestamp < ORDER[orderID].timeLimit,
            "Time expired for auction!!!"
        );
        if (ORDER[orderID].highestBid == 0) {
            require(
                msg.value >= ORDER[orderID].minBid,
                "Lower than minimum bid!!!"
            );
            ORDER[orderID].highestBid = msg.value;
            ORDER[orderID].highestBidder = msg.sender;
            ORDER[orderID].publisherIDBidder = _publisherIDBidder;
            if (
                block.timestamp >= (ORDER[orderID].timeLimit.sub(600)) &&
                block.timestamp < ORDER[orderID].timeLimit
            )
                ORDER[orderID].timeLimit = ORDER[orderID].timeLimit.add(600);

            emit BidPlaced(
                ORDER[orderID].seller,
                ORDER[orderID].highestBidder,
                orderID,
                ORDER[orderID].tokenID,
                ORDER[orderID].publisherIDBidder
            );
        } else {
            uint256 bidIncrement = msg.value.sub(ORDER[orderID].highestBid);
            uint256 percent = (ORDER[orderID].highestBid.mul(uint256(bidIncrementPercent)))
                .div(uint256(100));
            if (percent > bidIncrementAmt)
                //Checking suitable increment for next bid
                require(
                    bidIncrement >= percent,
                    "Consecutive bid's increment required atleast of 5%!!!"
                );
            else
                require(
                    bidIncrement >= bidIncrementAmt,
                    "Consecutive bid's increment required atleast of 0.05 ETH!!!"
                );

            uint256 refundBid = ORDER[orderID].highestBid;
            address to = ORDER[orderID].highestBidder;
            ORDER[orderID].highestBid = msg.value;
            ORDER[orderID].highestBidder = msg.sender;
            ORDER[orderID].publisherIDBidder = _publisherIDBidder;

            if (
                block.timestamp >= (ORDER[orderID].timeLimit.sub(600)) &&
                block.timestamp < ORDER[orderID].timeLimit
            ) ORDER[orderID].timeLimit = ORDER[orderID].timeLimit.add(600);

            emit BidPlaced(
                ORDER[orderID].seller,
                ORDER[orderID].highestBidder,
                orderID,
                ORDER[orderID].tokenID,
                ORDER[orderID].publisherIDBidder
            );
            payable(to).transfer(refundBid); //relinquish previous bid
        }
    }

    function confirmSale(uint256 orderID) public {
        require(
            TypeMapping[orderID] == orderType.auction,
            "Order ID-Type mismatch"
        );
        require(
            msg.sender == ORDER[orderID].seller,
            "Only owner or seller can confirm sale!!!"
        );
        require(ORDER[orderID].stage == Stage.LISTED, "Order is closed!!!");
        uint256 cost = ORDER[orderID].highestBid;
        if (cost == 0) {
            unlistAuction(orderID);
        } else {
            ORDER[orderID].stage = Stage.ORDER_CLOSED; //will prevent Reentrancy
            uint256 listShare;
            uint256 sellShare;
            uint256 protocolShare;
            (listShare, sellShare, protocolShare) = member
                .getCommissionDistribution(
                    ORDER[orderID].publisherID,
                    ORDER[orderID].publisherIDBidder,
                    cost
                );

            //platform where it's listed
            memberEarnings[ORDER[orderID].publisherID] = memberEarnings[
                ORDER[orderID].publisherID
            ].add(listShare);
            emit EarningsCreditedLister(
                ORDER[orderID].publisherID,
                listShare,
                false
            );

            //platform where it's sold
            memberEarnings[ORDER[orderID].publisherIDBidder] = memberEarnings[
                ORDER[orderID].publisherIDBidder
            ].add(sellShare);
            emit EarningsCreditedSeller(
                ORDER[orderID].publisherIDBidder,
                sellShare,
                false
            );

            //protocol will have member id 0
            memberEarnings[0] = memberEarnings[0].add(protocolShare);
            //uint256 commissions = listShare.add(sellShare).add(protocolShare);
            address minter;
            uint256 royaltyAmount;
            NMNFactory token;
            NMNFactory721 token721;

            if (tokenType[orderID] == nftType.ERC1155) {
                token = NMNFactory(ORDER[orderID].contractAddr);
                try token.royaltyInfo(ORDER[orderID].tokenID, cost) returns (
                    address x,
                    uint256 y
                ) {
                    minter = x;
                    royaltyAmount = y;
                } catch {
                    minter = address(0);
                    royaltyAmount = 0;
                }
                token.safeTransferFrom(
                    address(this),
                    ORDER[orderID].highestBidder,
                    ORDER[orderID].tokenID,
                    1,
                    ""
                );
            } else {
                token721 = NMNFactory721(ORDER[orderID].contractAddr);
                try token721.royaltyInfo(ORDER[orderID].tokenID, cost) returns (
                    address x,
                    uint256 y
                ) {
                    minter = x;
                    royaltyAmount = y;
                } catch {
                    minter = address(0);
                    royaltyAmount = 0;
                }
                token721.safeTransferFrom(
                    address(this),
                    ORDER[orderID].highestBidder,
                    ORDER[orderID].tokenID,
                    ""
                );
            }
            if (ORDER[orderID].seller != minter)
                if (royaltyAmount != 0) payable(minter).transfer(royaltyAmount);
            emit TokenSold(
                ORDER[orderID].seller,
                ORDER[orderID].highestBidder,
                orderID,
                ORDER[orderID].tokenID,
                ORDER[orderID].publisherIDBidder
            );
            ORDER[orderID].seller.transfer(cost.sub(listShare.add(sellShare).add(protocolShare).add(royaltyAmount)));
        }
    }

    

    /////////////////////////////////////////////FOR DIRECT SALE ///////////////////////////////////////////////////////////////////////////////////////////////////

    //Min. price of any token should be set grater than 0.01 matic
    uint256 public  minSalePrice = 10000000000000000;

    event TokenListed(
        address indexed _seller,
        address indexed _contract,
        uint256 _tokenIdListed,
        uint256 _orderid,
        uint256 _amountListed,
        uint256 _pricePerPiece,
        uint256 _publisherID
    );
    event TokenUnlisted(
        address indexed _seller,
        address indexed _contract,
        uint256 _tokenIdUnlisted,
        uint256 _orderid,
        uint256 _publisherID
    );
    event TokenPurchased(
        address indexed _seller,
        address indexed _buyer,
        address indexed _contract,
        uint256 _orderID,
        uint256 _tokenIdPurchased,
        uint256 _amountBought,
        uint256 _cost,
        uint256 _memberID
    );

    //_price should be in wei
    function listForSale(
        address _contract,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _price,
        uint256 _publisherID,
        nftType tktype
    ) public {
        require(_contract != address(0), "Null contract address provided!!!");
        NMNFactory token;
        NMNFactory721 token721;
        if (tktype == nftType.ERC1155) token = NMNFactory(_contract);
        else {
            token721 = NMNFactory721(_contract);
            require(_amount == 1, "Invalid amount for ERC721");
        }

        require(
            member.getPublisherStatus(_publisherID) == true,
            "Publisher not active!!!"
        );
        require(
            _publisherID > 0 && _publisherID <= member.memberCount(),
            "please enter a valid Publisher ID!!!"
        );
        require(
            _price >= minSalePrice,
            "Price should be more than 10000000000000000 wei!!!"
        );

        if (tktype == nftType.ERC1155) {
            require(
                token.isApprovedForAll(msg.sender, address(this)) == true,
                "Escrow not approved!!!"
            );
            require(
                token.balanceOf(msg.sender, _tokenId) >= 1,
                "Not enough tokens in your wallet!!!"
            );
            orderCtr = orderCtr.add(1);
            TypeMapping[orderCtr] = orderType.sale;
            tokenType[orderCtr] = tktype;
            ORDER[orderCtr] = Order(
                Stage.LISTED,
                orderCtr,
                payable(msg.sender),
                _tokenId,
                _contract,
                0,
                address(0),
                _price,
                0,
                0,
                _publisherID,
                0,
                _amount
            );
            token.safeTransferFrom(
                msg.sender,
                address(this),
                _tokenId,
                _amount,
                ""
            );
        } else if (tktype == nftType.ERC721) {
            require(
                token721.isApprovedForAll(msg.sender, address(this)) == true,
                "Escrow not approved!!!"
            );
            require(
                token721.balanceOf(msg.sender) >= 1,
                "Not enough tokens in your wallet!!!"
            );

            orderCtr = orderCtr.add(1);
            TypeMapping[orderCtr] = orderType.sale;
            tokenType[orderCtr] = tktype;
            ORDER[orderCtr] = Order(
                Stage.LISTED,
                orderCtr,
                payable(msg.sender),
                _tokenId,
                _contract,
                0,
                address(0),
                _price,
                0,
                0,
                _publisherID,
                0,
                _amount
            );
            token721.safeTransferFrom(msg.sender, address(this), _tokenId, "");
        } else revert("Invalid contract type");
        emit TokenListed(
            msg.sender,
            _contract,
            _tokenId,
            orderCtr,
            _amount,
            _price,
            _publisherID
        );
    }

    function unlistSale(uint256 orderID) public {
        require(
            msg.sender == ORDER[orderID].seller || msg.sender == address(this),
            "Only seller can access this function!!!"
        );
        require(
            TypeMapping[orderID] == orderType.sale,
            "Order ID-Type mismatch"
        );
        require(
            (orderID > 0) && (orderID <= orderCtr),
            "Invalid Order ID provided!!!"
        );
        require(
            ORDER[orderID].stage != Stage.ORDER_CLOSED,
            "Order is closed!!!"
        );
        require(
            ((ORDER[orderID].stage == Stage.LISTED) ||
                (ORDER[orderID].stage == Stage.PARTIALLY_SOLD)),
            "Wrong Token stage!!!"
        );
        ORDER[orderID].stage = Stage.ORDER_CLOSED;
        emit TokenUnlisted(
            msg.sender,
            ORDER[orderID].contractAddr,
            ORDER[orderID].tokenID,
            orderID,
            ORDER[orderID].publisherID
        );
        if (tokenType[orderID] == nftType.ERC1155) {
            NMNFactory token = NMNFactory(ORDER[orderID].contractAddr);
            token.safeTransferFrom(
                address(this),
                ORDER[orderID].seller,
                ORDER[orderID].tokenID,
                ORDER[orderID].amountToSell,
                ""
            );
        } else {
            NMNFactory721 token = NMNFactory721(ORDER[orderID].contractAddr);
            token.safeTransferFrom(
                address(this),
                ORDER[orderID].seller,
                ORDER[orderID].tokenID,
                ""
            );
        }
    }


    //For direct buy of tokens
    function buy(
        uint256 orderID,
        uint256 buyAmount,
        uint256 _publisherID
    ) public payable {
        require(
            TypeMapping[orderID] == orderType.sale,
            "Order ID-Type mismatch"
        );
        require(
            (orderID > 0) && (orderID <= orderCtr),
            "Invalid Order ID provided!!!"
        );
        require(
            ORDER[orderID].stage != Stage.ORDER_CLOSED,
            "Order is closed!!!"
        );
        require(
            msg.sender != ORDER[orderID].seller,
            "Sellers can't buy their own token!!!"
        );
        require(
            (buyAmount > 0) && (buyAmount <= ORDER[orderID].amountToSell),
            "Invalid buy amount provided!!!"
        );
        require(
            ((ORDER[orderID].stage == Stage.LISTED) ||
                (ORDER[orderID].stage == Stage.PARTIALLY_SOLD)),
            "Wrong Token stage!!!"
        );
        require(
            _publisherID > 0 && _publisherID <= member.memberCount(),
            "please enter a valid Publisher ID!!!"
        );
        require(
            member.tokenTradableAmongPublishers(
                _publisherID,
                ORDER[orderID].publisherID
            ) == true,
            "Token is not tradable among the given publishers!!!"
        );
        //will reset the old values on every new call
        uint256 listShare;
        uint256 protocolShare;
        uint256 sellShare;
        uint256 cost = (ORDER[orderID].minBid).mul(buyAmount);

        require(msg.value == cost, "Insufficient funds!!!");
        (listShare, sellShare, protocolShare) = member
            .getCommissionDistribution(
                _publisherID,
                ORDER[orderID].publisherID,
                cost
            );

        memberEarnings[ORDER[orderID].publisherID] = memberEarnings[
            ORDER[orderID].publisherID
        ].add(listShare);
        emit EarningsCreditedLister(
            ORDER[orderID].publisherID,
            listShare,
            true
        );
        
        memberEarnings[_publisherID] = memberEarnings[_publisherID].add(
            sellShare
        );
        emit EarningsCreditedSeller(_publisherID, sellShare, true);

        memberEarnings[0] = memberEarnings[0].add(protocolShare);

        address minter;
        uint256 royaltyAmount;
        if (tokenType[orderID] == nftType.ERC1155) {
            NMNFactory token = NMNFactory(ORDER[orderID].contractAddr);
            try token.royaltyInfo(ORDER[orderID].tokenID, cost) returns (
                address x,
                uint256 y
            ) {
                minter = x;
                royaltyAmount = y;
            } catch {
                minter = address(0);
                royaltyAmount = 0;
            }

            //(, , minter) = token.creator(ORDER[orderID].tokenID);
            token.safeTransferFrom(
                address(this),
                msg.sender,
                ORDER[orderID].tokenID,
                buyAmount,
                ""
            );
        } else {
            NMNFactory721 token = NMNFactory721(ORDER[orderID].contractAddr);
            try token.royaltyInfo(ORDER[orderID].tokenID, cost) returns (
                address x,
                uint256 y
            ) {
                minter = x;
                royaltyAmount = y;
            } catch {
                minter = address(0);
                royaltyAmount = 0;
            }
            //(, , minter) = token.creator(ORDER[orderID].tokenID);
            token.safeTransferFrom(
                address(this),
                msg.sender,
                ORDER[orderID].tokenID,
                ""
            );
        }

        ORDER[orderID].amountToSell = ORDER[orderID].amountToSell.sub(
            buyAmount
        );
        if (ORDER[orderID].amountToSell == 0) {
            emit TokenUnlisted(
                msg.sender,
                address(ORDER[orderID].contractAddr),
                ORDER[orderID].tokenID,
                orderID,
                ORDER[orderID].publisherID
            );
            ORDER[orderID].stage = Stage.ORDER_CLOSED;
        } else ORDER[orderID].stage = Stage.PARTIALLY_SOLD;
        emit TokenPurchased(
            ORDER[orderID].seller,
            msg.sender,
            address(ORDER[orderID].contractAddr),
            orderID,
            ORDER[orderID].tokenID,
            buyAmount,
            cost,
            _publisherID
        );
        if (ORDER[orderID].seller != minter)
            if (royaltyAmount != 0) payable(minter).transfer(royaltyAmount);
        ORDER[orderID].seller.transfer(cost.sub(listShare.add(sellShare).add(protocolShare).add(royaltyAmount)));
    }



    function viewWhiteList() public view returns (address[] memory) {
        require(
            msg.sender == protocolFundsWithdrawer ||
                msg.sender == signers[0] ||
                msg.sender == signers[1] ||
                msg.sender == signers[2] ||
                msg.sender == signers[3],
            "Invalid caller!!!"
        );
        return whiteList;
    }

    // changes address of protocolFundsWithdrawer
    function changeAddress(bytes[4] memory sigs, address _newAddress) public {
        require(
            msg.sender == signers[0] ||
                msg.sender == signers[1] ||
                msg.sender == signers[2] ||
                msg.sender == signers[3],
            "Invalid caller!!!"
        );
        uint256 count = 0;
        for (uint256 i = 0; i < 4; i++) {
            if (verify(signers[i], sigs[i])) count++;
        }
        if (count >= 3) {
            protocolFundsWithdrawer = _newAddress;
        }
        nonce = nonce + 1;
        messageHash = keccak256(
            abi.encodePacked(
                signers[0],
                signers[1],
                signers[2],
                signers[3],
                nonce
            )
        );
    }

    function addToWhiteList(bytes[4] memory sigs, address _address) public {
        require(
            msg.sender == signers[0] ||
                msg.sender == signers[1] ||
                msg.sender == signers[2] ||
                msg.sender == signers[3],
            "Invalid caller!!!"
        );
        uint256 count = 0;
        for (uint256 i = 0; i < 4; i++) {
            if (verify(signers[i], sigs[i])) count++;
        }
        if (count >= 3) {
            whiteList.push(_address);
        }
        nonce = nonce + 1;
        messageHash = keccak256(
            abi.encodePacked(
                signers[0],
                signers[1],
                signers[2],
                signers[3],
                nonce
            )
        );
    }

    function removeFromWhiteList(bytes[4] memory sigs, address _address)
        public
    {
        require(
            msg.sender == signers[0] ||
                msg.sender == signers[1] ||
                msg.sender == signers[2] ||
                msg.sender == signers[3],
            "Invalid caller!!!"
        );
        uint256 count = 0;
        for (uint256 i = 0; i < 4; i++) {
            if (verify(signers[i], sigs[i])) count++;
        }
        if (count >= 3) {
            int256 pos = -1;
            for (uint256 j = 0; j < whiteList.length; j++) {
                if (whiteList[j] == _address) {
                    pos = int256(j);
                }
            }
            if (pos != -1) {
                for (uint256 k = uint256(pos); k < whiteList.length - 1; k++) {
                    whiteList[k] = whiteList[k + 1];
                }
                whiteList.pop();
            }
        }
        nonce = nonce + 1;
        messageHash = keccak256(
            abi.encodePacked(
                signers[0],
                signers[1],
                signers[2],
                signers[3],
                nonce
            )
        );
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        internal
        pure
        returns (bytes32)
    {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function verify(address _signer, bytes memory signature)
        internal
        view
        returns (bool)
    {
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    function changeMinWithdrawl(uint256 _newMinWithdrawl) public onlyOwner{
        minWithdrawl = _newMinWithdrawl;
    }

    function disburseAllEarnings() public onlyOwner{

        for(uint256 i = 1; i <= member.memberCount();i++){
            uint256 x = balance(i);
            if(x>0){
                withdrawEarnings(i,x);
            }
        }
    }

    function cancelAllOrders() public onlyOwner{
        for (uint256 i = 1; i <= orderCtr; i++){
            if(ORDER[i].stage != Stage.ORDER_CLOSED){
                if(TypeMapping[i] == orderType.sale){
                    unlistSale(i);
                }
                else if(TypeMapping[i] == orderType.auction){
                    unlistAuction(i);
                }
            }
        }
    }

    function cancelMemberOrders(uint256 _memberID) public {
        require(msg.sender == member.getAddress(_memberID),"Only Member address can perform this operation");
        for (uint256 i = 1; i <= orderCtr; i++){
            if(ORDER[i].stage != Stage.ORDER_CLOSED && ORDER[i].publisherID == _memberID){
                if(TypeMapping[i] == orderType.sale){
                    unlistSale(i);
                }
                else if(TypeMapping[i] == orderType.auction){
                    unlistAuction(i);
                }
            }
        }
    }

    function changeMinSalePrice(uint256 _new) public onlyOwner{
        minSalePrice = _new;
    }

    

    fallback() external payable {}

    receive() external payable {}

}

pragma solidity >=0.4.22 <0.9.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IMemberManagement.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract NMNFactory721 is ERC721,ERC2981, Ownable {
    using SafeMath for uint256;
    IMemberManagement member;
    uint256 public lastID;
    //here 100 means 10%
    // uint256 public constant royaltyPercentLimit = 100;
    // struct royalty {
    //     uint256 tokenId;
    //     uint256 royaltyPercent;
    //     address creatorAddress;
    // }
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

    //tokenID to creator's public address
    //mapping(uint256 => royalty) public creator;
    //tokenID to publisher ID: To track where it was minted
    mapping(uint256 => uint256) public tokenPublisher;
    //token id to token uri
    mapping(uint256 => string) tokenuri;

    RoyaltyInfo private _defaultRoyaltyInfo;

    constructor(IMemberManagement _member) ERC721("NMN 721 v2","NMN2") {
        member = _member;
        _defaultRoyaltyInfo.receiver = _msgSender();
        _defaultRoyaltyInfo.royaltyFraction = 0;
    }
    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return tokenuri[tokenId];
    }

    //_royaltyPercent should be like 120 for 1.2%, 200 for 2%
    function nftMint(
        string memory _tokenURI,
        uint96 _royaltyNumerator,
        uint256 _publisherID
    ) public {
        require(
            member.canMint(_publisherID, msg.sender),
            "You are not allowed to mint!!!"
        );
        lastID = lastID.add(1);
        tokenuri[lastID] = _tokenURI;
        _safeMint(msg.sender, lastID, "");
        _setTokenRoyalty(lastID, msg.sender, _royaltyNumerator);
        //creator[lastID] = royalty(lastID, _royaltyNumerator, msg.sender);
        tokenPublisher[lastID] = _publisherID;
    }

    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(ownerOf(tokenId) == _msgSender(), "ERC721Burnable: caller is not owner");
        _burn(tokenId);
    }
}

pragma solidity >=0.4.22 <0.9.0;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IMemberManagement.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract NMNFactory is ERC1155,ERC2981, Ownable {
    using SafeMath for uint256;
    IMemberManagement member;
    uint256 public lastID;
    //here 100 means 10%
    //uint256 public constant royaltyPercentLimit = 100;
    // struct royalty {
    //     uint256 tokenId;
    //     uint256 royaltyPercent;
    //     address creatorAddress;
    // }
    //tokenID to URI
    mapping(uint256 => string) tokenURI;
    //tokenID to creator's public address
    //mapping(uint256 => royalty) public creator;
    //tokenID to publisher ID: To track where it was minted
    mapping(uint256 => uint256) public tokenPublisher;

     RoyaltyInfo private _defaultRoyaltyInfo;

    constructor(IMemberManagement _member) ERC1155("") {
        member = _member;
        _defaultRoyaltyInfo.receiver = _msgSender();
        _defaultRoyaltyInfo.royaltyFraction = 0;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function uri(uint256 tkid) public view override returns (string memory){
        return(tokenURI[tkid]);
    }

    //_royaltyPercent should be like 120 for 1.2%, 200 for 2%
    function nftMint(
        string memory _tokenURI,
        uint256 _amt,
        uint96 _royaltyNumerator,
        uint256 _publisherID
    ) public {
        require(
            member.canMint(_publisherID, msg.sender),
            "You are not allowed to mint!!!"
        );
        lastID = lastID.add(1);
        _setURI(_tokenURI);
        emit URI(_tokenURI, lastID);
        _mint(msg.sender, lastID, _amt, "");
        tokenURI[lastID] = _tokenURI;
        _setTokenRoyalty(lastID, msg.sender, _royaltyNumerator);
        //creator[lastID] = royalty(lastID, _royaltyPercent, msg.sender);
        tokenPublisher[lastID] = _publisherID;
    }

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender(),    //only owner of tokens can burn their tokens
            "ERC1155: caller is not owner"
        );

        _burn(_msgSender(), id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender(),    //only owner of tokens can burn their tokens
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }
}

pragma solidity >=0.4.22 <0.9.0;

interface IMemberManagement {
    function tokenTradableAmongPublishers(uint256, uint256)
        external
        view
        returns (bool);

    function getCommissionDistribution(
        uint256,
        uint256,
        uint256
    ) external view returns (uint256, uint256, uint256);

    function getAddress(uint256) external view returns (address);

    function getPublisherStatus(uint256) external view returns (bool);

    function memberCount() external view returns (uint256);

    function canMint(uint256, address) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        virtual
        override
        returns (address, uint256)
    {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `tokenId` must be already minted.
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
    function isApprovedForAll(address account, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}