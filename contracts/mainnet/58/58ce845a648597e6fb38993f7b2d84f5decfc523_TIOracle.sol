/**
 *Submitted for verification at polygonscan.com on 2022-06-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
// TIOracle is an oracle that provides reliable prices in multiple currencies
contract TIOracle {
    // PriceInfo is a single piece of price information,
    // which includes TI's quotation, on-chain DEX quotation, and the timestamp of price feeding
    struct PriceInfo {
        uint256 tiPrice;
        uint256 dexPrice;
        uint256 timestamp;
    }
    event NodeAdded(address newNode);
    event NodeRemoved(address removedNode);
    event NodeKicked(address removeNode);
    event PriceFeed(PriceInfo info);
    // coin name => price, with 8 digits of precision
    mapping(string => PriceInfo) lastPrice;
    // last round
    uint256 public lastRound;
    // count
    uint256 public feedCount;
    // owner of the contract
    address admin;
    // list of transmission nodes
    address[] public nodes;
    // count per round
    uint256 public countPerRound;
    // proposals of deleteing nodes
    mapping(address => address[]) public kickProposals;

    constructor(uint256 feedCountPerRound) {
        admin = msg.sender;
        countPerRound = feedCountPerRound;
    }

    // get the current price in Uniswap, and the quote should be usdc
    function estimateDexPrice(string memory coinName) public view returns (uint256) {
        //TODO call uniswap to estimate
        return 123;
    }

    // compare two prices from TI and Uniswap
    function crossValidate(uint256 tiPrice, uint256 dexPrice) internal pure returns (bool) {
        // TODO do cross validation
        return tiPrice > 0 && dexPrice > 0;
    }

    //queryPrice get the last price feeded of certain coin
    function queryPrice(string memory coinName) public view returns (PriceInfo memory) {
        return lastPrice[coinName];
    }

    //  decide next valid node to feed price, in a round-robbin way
    function decideValidNode(uint256 roundNo) public view returns (address) {
        require(nodes.length > 0, "list of transmission nodes is empty");
        uint256 offset = roundNo % nodes.length;
        return nodes[offset];
    }

    function isMyTurn() public view returns (bool)  {
        return decideValidNode(lastRound) == msg.sender;
    }

    // feedPrice is called by transmission nodes to feed price of cryptos
    function feedPrice(string memory coinName, uint256 price) public {
        address validNode = decideValidNode(lastRound);
        require(msg.sender == validNode, "invalid transmission node");
        ++feedCount;
        if (feedCount % countPerRound == 0) {
            ++lastRound;
        }
        PriceInfo memory priceInfo;
        priceInfo.tiPrice = price;
        priceInfo.timestamp = block.timestamp;
        uint256 dexPrice = estimateDexPrice(coinName);
        require(crossValidate(price, dexPrice), "This price deviates too much from Uniswap and is rejected for submission");
        priceInfo.dexPrice = dexPrice;
        lastPrice[coinName] = priceInfo;
        emit PriceFeed(priceInfo);
    }

    // addNode: vote to add new trasmission node
    function addNode(address newNode) public {
        require(msg.sender == admin, "invalid caller to add new node");
        nodes.push(newNode);
        emit NodeAdded(newNode);
    }

    // removeNode remove trasmission node from whitelist
    function removeNode(address rmNode) public {
        require(msg.sender == admin, "invalid caller to remove node");
        for(uint i=0; i<nodes.length; i++) {
            if (nodes[i] == rmNode) {
                nodes[i] = nodes[nodes.length-1];
                nodes.pop();
                emit NodeRemoved(rmNode);
                break;
            }
        }
    }

    // kickNode remove trasmission node from whitelist
    function kickNode(address rmNode) public {
        //check duplicated vote
        for (uint256 i=0; i<kickProposals[rmNode].length; i++) {
            require(kickProposals[rmNode][i] != msg.sender, "duplciated vote");
        }
        bool valid_sender = false;
        for (uint256 i=0; i<nodes.length;i++) {
            if (nodes[i] == msg.sender) {
                valid_sender = true;
                break;
            }
        }
        require(valid_sender, "invalid node to kick others");
        // vote to kick
        kickProposals[rmNode].push(msg.sender);
        // >2/3 agree
        if (nodes.length * 2 / 3 < kickProposals[rmNode].length) {
            for(uint i=0; i<nodes.length; i++) {
                if (nodes[i] == rmNode) {
                    nodes[i] = nodes[nodes.length-1];
                    nodes.pop();
                    emit NodeKicked(rmNode);
                    break;
                }
            }
        }
    }

    // transferOwnership transfer the ownership of this contract
    function transferOwnership(address newOwner) public {
        require(msg.sender == admin, "invalid caller to transfer ownership");
        admin =  newOwner;
    }
}