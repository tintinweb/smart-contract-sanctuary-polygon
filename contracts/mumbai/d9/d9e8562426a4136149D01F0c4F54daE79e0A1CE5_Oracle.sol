// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

// import "hardhat/console.sol";

struct Quote {
    uint216 price;
    uint40 timestamp;
}

struct Request {
    address requester;
    uint256 propertyId;
    uint40 timestamp;
}

contract Oracle {
    address public immutable owner; //wallet
    mapping(uint256 propertyId => Quote) internal quotes;
    mapping(bytes32 requestId => Request) internal requests;

    event NewRequest(
        bytes32 indexed requestId,
        uint256 indexed propertyId,
        address indexed requester
    );
    event QuoteUpdated(uint256 indexed propertyId, uint216 price);

    error UnauthorizedAccess();
    error RequestExists(bytes32 requestId);
    error QuoteNotFound(uint256 propertyId);

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyAuthorized() {
        if(msg.sender != owner) revert UnauthorizedAccess();
        _;
    }

    /*
        @param _propertyId The unique ID of the property
        @return requestId The unique ID of the request
    */
    function requestQuote(
        uint256 _propertyId
    ) external onlyAuthorized returns (bytes32 requestId) {
        requestId = keccak256(abi.encodePacked(_propertyId, quotes[_propertyId].timestamp));

        if(requests[requestId].timestamp != 0) revert RequestExists(requestId);

        Request memory req = Request(msg.sender, _propertyId, uint40(block.timestamp));
        requests[requestId] = req;
        emit NewRequest(requestId, _propertyId, msg.sender);
    }

    /*
        @param _propertyId The unique ID of the property
        @param _price price of the property to store
    */
    function setPrice(
        uint256 _propertyId,
        uint216 _price
    ) external onlyAuthorized {
        bytes32 requestId = keccak256(abi.encodePacked(_propertyId, quotes[_propertyId].timestamp));

        delete requests[requestId];

        quotes[_propertyId] = Quote(_price, uint40(block.timestamp));

        emit QuoteUpdated(
            _propertyId,
            _price
        );
    }

    /*
        @param _propertyId The unique ID of the property
        @return price The price requested
    */
    function getQuote(
        uint256 _propertyId
    ) external view returns (uint216 price, uint40 timestamp) {
        if(quotes[_propertyId].timestamp == 0) revert QuoteNotFound(_propertyId);

        Quote memory req = quotes[_propertyId];
        return (req.price, req.timestamp);
    }
}