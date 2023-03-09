// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ICurate {
    function isRegistered(bytes32 _itemID) external view returns (bool);

    function getAddress(bytes32 _itemID) external view returns (address);
}

interface ISVG {
    function getSVG(address _market, uint256 _tokenID) external view returns (string memory);

    function getRef(address _market, uint256 _tokenID) external view returns (string memory);
}

interface IBilling {
    function registerPayment(address _market) external payable;
}

contract FirstPriceAuction {
    struct Bid {
        bytes32 previousBidPointer;
        bytes32 nextBidPointer;
        address bidder;
        uint64 startTimestamp;
        bool removed;
        uint256 bidPerSecond;
        uint256 balance;
        bytes32 itemID; // on curate
    }

    uint256 public constant MIN_OFFER_DURATION = 1800; // 30 min. Can be avoided if manually removed.

    ICurate public curatedAds;
    IBilling public billing;
    mapping(bytes32 => Bid) public bids;

    event BidUpdate(
        address indexed _market,
        address indexed _bidder,
        bytes32 _itemID,
        uint256 indexed _bidPerSecond,
        uint256 _newBalance
    );

    event NewHighestBid(address indexed _market, address _bidder, bytes32 _itemID);

    constructor(ICurate _curatedAds, IBilling _billing) {
        curatedAds = _curatedAds;
        billing = _billing;
    }

    /** @dev Creates and places a new bid or replaces an existing one.
     *  @param _itemID The id of curated ad.
     *  @param _market The address of the market the bid will be placed to.
     *  @param _bidPerSecond The amount of tokens (xDAI) per second that will be payed if the bid gets the highest position, now or at some point.
     */
    function placeBid(
        bytes32 _itemID,
        address _market,
        uint256 _bidPerSecond
    ) external payable {
        executeHighestBid(_market);

        require(curatedAds.isRegistered(_itemID), "Item must be registered");

        bytes32 bidID = keccak256(abi.encode(_market, _itemID, msg.sender));
        Bid storage bid = bids[bidID];

        bool increaseBalanceOnly = bid.bidPerSecond == _bidPerSecond;
        if (bid.bidder == msg.sender && !bid.removed && !increaseBalanceOnly) {
            _forceRemoveBid(_itemID, _market);
        }

        bid.bidPerSecond = _bidPerSecond;
        bid.balance += msg.value;
        bid.itemID = _itemID;
        require(bid.balance / _bidPerSecond > MIN_OFFER_DURATION, "Not enough funds");

        if (bid.bidder != msg.sender || bid.removed || !increaseBalanceOnly) {
            _insertBid(_market, bidID);
        }
        bid.removed = false;
        bid.bidder = msg.sender;

        emit BidUpdate(_market, msg.sender, _itemID, _bidPerSecond, bid.balance);
    }

    /** @dev Removes bid.
     *  @param _itemID The id of curated ad.
     *  @param _market The address of the market the bid will be placed to.
     */
    function _forceRemoveBid(bytes32 _itemID, address _market) internal {
        bytes32 bidID = keccak256(abi.encode(_market, _itemID, msg.sender));
        Bid storage bid = bids[bidID];

        bytes32 startID = keccak256(abi.encode(_market));
        if (bid.previousBidPointer == startID) {
            if (bid.nextBidPointer != 0x0) {
                Bid storage newHighestBid = bids[bid.nextBidPointer];
                newHighestBid.startTimestamp = uint64(block.timestamp);
                emit NewHighestBid(_market, newHighestBid.bidder, newHighestBid.itemID);
            }
        }

        bids[bid.nextBidPointer].previousBidPointer = bid.previousBidPointer;
        bids[bid.previousBidPointer].nextBidPointer = bid.nextBidPointer;
    }

    /** @dev Removes an existing bid.
     *  @param _itemID The id of curated ad.
     *  @param _market The address of the market the bid will be placed to.
     */
    function removeBid(bytes32 _itemID, address _market) external {
        bytes32 bidID = keccak256(abi.encode(_market, _itemID, msg.sender));
        Bid storage bid = bids[bidID];
        require(bid.bidder == msg.sender, "Bid does not exist");
        require(!bid.removed, "Bid already removed");
        bid.removed = true;
        bids[bid.nextBidPointer].previousBidPointer = bid.previousBidPointer;
        bids[bid.previousBidPointer].nextBidPointer = bid.nextBidPointer;

        bytes32 startID = keccak256(abi.encode(_market));
        if (bid.previousBidPointer == startID) {
            _registerPayment(bid, _market);

            if (bid.nextBidPointer != 0x0) {
                Bid storage newHighestBid = bids[bid.nextBidPointer];
                newHighestBid.startTimestamp = uint64(block.timestamp);
                emit NewHighestBid(_market, newHighestBid.bidder, newHighestBid.itemID);
            }
        }

        emit BidUpdate(_market, msg.sender, _itemID, bid.bidPerSecond, 0);

        uint256 remainingBalance = bid.balance;
        bid.balance = 0;
        requireSendXDAI(payable(msg.sender), remainingBalance);
    }

    /** @dev Either:
     *    - removes the current highest bid if the balance is empty or if it was removed from curate.
     *    - collects the current highest bid billing.
     *  @param _market The address of the market.
     */
    function executeHighestBid(address _market) public {
        bytes32 startID = keccak256(abi.encode(_market));
        bytes32 highestBidID = bids[startID].nextBidPointer;
        if (highestBidID == 0x0) return;

        Bid storage bid = bids[highestBidID];

        uint256 price = (block.timestamp - bid.startTimestamp) * bid.bidPerSecond;
        if (price >= bid.balance || !curatedAds.isRegistered(bid.itemID)) {
            // Report bid
            bid.removed = true;
            bids[bid.nextBidPointer].previousBidPointer = bid.previousBidPointer;
            bids[bid.previousBidPointer].nextBidPointer = bid.nextBidPointer;

            bid.startTimestamp = 0;
            uint256 remainingBalance = bid.balance;
            bid.balance = 0;
            billing.registerPayment{value: remainingBalance}(_market);

            if (bid.nextBidPointer != 0x0) {
                Bid storage newHighestBid = bids[bid.nextBidPointer];
                newHighestBid.startTimestamp = uint64(block.timestamp);
                emit NewHighestBid(_market, newHighestBid.bidder, newHighestBid.itemID);
            }
        } else {
            // Collect payment from active bid
            bid.startTimestamp = uint64(block.timestamp);
            bid.balance -= price;
            billing.registerPayment{value: price}(_market);
        }

        emit BidUpdate(_market, bid.bidder, bid.itemID, bid.bidPerSecond, bid.balance);
    }

    function _insertBid(address _market, bytes32 _bidID) internal {
        // Insert the bid in the ordered list.
        Bid storage bid = bids[_bidID];
        bytes32 startID = keccak256(abi.encode(_market));
        bytes32 currentID = startID;
        bytes32 nextID = bids[startID].nextBidPointer;
        while (bids[nextID].bidPerSecond >= bid.bidPerSecond) {
            currentID = nextID;
            nextID = bids[nextID].nextBidPointer;
        }
        bids[currentID].nextBidPointer = _bidID;
        bid.previousBidPointer = currentID;
        bid.nextBidPointer = nextID;
        bids[nextID].previousBidPointer = _bidID;

        if (currentID == startID) {
            // Highest bid! Activate the new bid and process the previous highest bid.
            bid.startTimestamp = uint64(block.timestamp);

            if (nextID != 0x0) {
                Bid storage nextBid = bids[nextID];
                _registerPayment(nextBid, _market);

                if (nextBid.balance == 0) {
                    // remove bid from list.
                    nextBid.removed = true;
                    bids[nextBid.nextBidPointer].previousBidPointer = _bidID;
                    bid.nextBidPointer = nextBid.nextBidPointer;
                }
                emit BidUpdate(
                    _market,
                    nextBid.bidder,
                    nextBid.itemID,
                    nextBid.bidPerSecond,
                    nextBid.balance
                );
            }
            emit NewHighestBid(_market, msg.sender, bid.itemID);
        }
    }

    function _registerPayment(Bid storage _bid, address _market) internal {
        uint256 price = (block.timestamp - _bid.startTimestamp) * _bid.bidPerSecond;
        uint256 bill = price > _bid.balance ? _bid.balance : price;
        _bid.startTimestamp = 0;
        _bid.balance -= bill;
        billing.registerPayment{value: bill}(_market);
    }

    function requireSendXDAI(address payable _to, uint256 _value) internal {
        (bool success, ) = _to.call{value: _value}(new bytes(0));
        require(success, "Send XDAI failed");
    }

    function getAd(address _market, uint256 _tokenID) external view returns (string memory) {
        bytes32 startID = keccak256(abi.encode(_market));
        bytes32 highestBidID = bids[startID].nextBidPointer;
        if (highestBidID == 0x0) return "";

        Bid storage bid = bids[highestBidID];
        address svgAddress = curatedAds.getAddress(bid.itemID);
        // Check if address is a contract. See @openzeppelin/contracts/utils/Address.sol
        if (svgAddress.code.length == 0) return "";

        try ISVG(svgAddress).getSVG(_market, _tokenID) returns (string memory svg) {
            return svg;
        } catch {
            return "";
        }
    }

    function getRef(address _market, uint256 _tokenID) external view returns (string memory) {
        bytes32 startID = keccak256(abi.encode(_market));
        bytes32 highestBidID = bids[startID].nextBidPointer;
        if (highestBidID == 0x0) return "";

        Bid storage bid = bids[highestBidID];
        address svgAddress = curatedAds.getAddress(bid.itemID);
        // Check if address is a contract. See @openzeppelin/contracts/utils/Address.sol
        if (svgAddress.code.length == 0) return "";

        try ISVG(svgAddress).getRef(_market, _tokenID) returns (string memory ref) {
            return ref;
        } catch {
            return "";
        }
    }

    function getBids(
        address _market,
        uint256 _from,
        uint256 _to
    ) external view returns (Bid[] memory) {
        Bid[] memory bidsArray = new Bid[](_to - _from);
        bytes32 startID = keccak256(abi.encode(_market));
        bytes32 currentID = startID;
        bytes32 nextID = bids[startID].nextBidPointer;

        for (uint256 i = 0; i <= _to; i++) {
            if (i >= _from) {
                bidsArray[i] = bids[nextID];
            }

            if (bids[nextID].nextBidPointer == 0x0) break;

            currentID = nextID;
            nextID = bids[nextID].nextBidPointer;
        }

        return bidsArray;
    }
}