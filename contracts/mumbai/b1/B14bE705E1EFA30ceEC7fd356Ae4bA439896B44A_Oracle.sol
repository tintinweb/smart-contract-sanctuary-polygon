/**
 *Submitted for verification at polygonscan.com on 2023-04-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

// import "hardhat/console.sol";

struct Request {
    bytes32 id;
    uint256 price;
    uint256 blocknumber;
}

contract Oracle {
    address public owner;
    mapping(address => bool) private authorizedNodes;
    mapping(bytes32 => Request) public requests;

    event NewRequest(
        bytes32 indexed requestId,
        uint256 price
    );

    event UpdatedRequest(bytes32 indexed requestId, uint256 indexed tokenId);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyAuthorized() {
        require(
            authorizedNodes[msg.sender] || msg.sender == owner,
            "Unauthorized"
        );
        _;
    }

    modifier isValidRequest(bytes32 _requestId) {
        require(
            requests[_requestId].id != bytes32(""),
            "Must have a valid requestId"
        );
        _;
    }

    /*
        @param _requestId unique request id
        @param _price price of the property to store
    */
    function setPrice(
        bytes32 _requestId,
        uint256 _price
    ) external onlyAuthorized {
        Request memory req = Request(_requestId, _price, block.number);
        requests[_requestId] = req;
        emit NewRequest(_requestId, _price);
    }

    /*
        @param _requestId The unique ID of the request
        @return price The price requested
    */
    function getQuote(
        bytes32 _requestId
    ) external view isValidRequest(_requestId) returns (uint256, uint256) {
        Request memory req = requests[_requestId];
        return (req.price, req.blocknumber);
    }

    function setAuthorizedNode(address _newNode) external onlyAuthorized {
        authorizedNodes[_newNode] = true;
    }
}