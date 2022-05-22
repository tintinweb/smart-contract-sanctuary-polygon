//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Statements {

    struct Request {
        uint256 from;
        uint256 to;
        bool processed;
        bytes cid;
    }

    uint256 constant public baseFee = 10 ** 17;
    uint256 constant public multiplier = 10 ** 7;

    mapping(address => Request[]) public requests;
    address public appAddress;
    address public owner;

    constructor(address _appAddress) {
        appAddress = _appAddress;
        owner = msg.sender;
    }

    modifier onlyApp {
        require(msg.sender == appAddress, "caller is not an app");
        _;
    }

    event StatementRequest(address requestor, uint256 index);

    function requestStatement(uint256 from, uint256 to) public payable {
        require(from < to, "'from' timestamp is greater then 'to' timestamp");
        require(msg.value >= baseFee + (to - from) * multiplier, "payment is too low");

        uint256 index = requests[msg.sender].length;

        Request memory request;
        request.from = from;
        request.to = to;
        request.processed = false;
        requests[msg.sender].push(request);

        emit StatementRequest(msg.sender, index);
    }

    function markProcessed(address requestInitiator, uint256 index, bytes calldata cid) public onlyApp {
        Request storage request = requests[requestInitiator][index];
        require(!request.processed, "can't process request twice");

        request.processed = true;
        request.cid = cid;
    }

    function withdrawAll() public {
        payable(owner).transfer(address(this).balance);
    }
}