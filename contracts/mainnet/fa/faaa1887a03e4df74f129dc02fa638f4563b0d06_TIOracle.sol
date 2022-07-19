/**
 *Submitted for verification at polygonscan.com on 2022-07-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// import "forge-std/Test.sol";
// TIOracle is an oracle that provides reliable prices in multiple currencies
contract TIOracle {
    uint256 constant MAX_NODES = 128;
    // PriceInfo is a single piece of price information,
    // which includes TI's quotation, and the timestamp of price feeding
    struct PriceInfo {
        uint256 price; //median of peers' price
        uint256 timestamp;
    }
    // PeerPriceFeed represents price reported by each peer, with nodes' signature
    struct PeerPriceFeed {
        address peerAddress;
        bytes sig;
        uint256 price;
        uint256 timestamp;
    }
    event NodeAdded(address newNode);
    event NodeRemoved(address removedNode);
    event NodeKicked(address removedNode);
    event PriceFeed(uint256 round, uint256 feedCount, PeerPriceFeed[] info);
    // Coin name
    string public coin;
    // last updated price, with timestamp
    PriceInfo public lastPrice;
    // last round
    uint256 public lastRound;
    // count
    uint256 public feedCount;
    // owner of the contract
    address admin;
    // list of transmission nodes
    address[] public nodes;
    // map of nodes
    mapping(address => uint256) nodesOffset;
    // count per round
    uint256 public countPerRound;
    // proposals of kicking nodes
    mapping(address => address[]) public kickProposals;
    // max seconds of delay for each time of feeding
    uint256 maxDelay;

    constructor(
        string memory coinName,
        uint256 feedCountPerRound,
        uint256 timeout
    ) {
        admin = msg.sender;
        coin = coinName;
        countPerRound = feedCountPerRound;
        maxDelay = timeout;
    }

    // queryPrice returns the last updated price with timestamp
    function queryPrice() public view returns (PriceInfo memory) {
        require(lastPrice.timestamp > 0, "not initialzied");
        return lastPrice;
    }

    // queryNode returns whether the node is allowed to feed price
    function queryNode(address addr) public view returns (bool) {
        return nodesOffset[addr] > 0;
    }

    //  decide next valid node to feed price, in a round-robbin way
    function decideValidNode(uint256 roundNo) public view returns (address) {
        require(nodes.length > 0, "list of transmission nodes is empty");
        uint256 offset = roundNo % nodes.length;
        return nodes[offset];
    }

    function isMyTurn() public view returns (bool) {
        bool timeout = lastPrice.timestamp > 0 &&
            ((block.timestamp - lastPrice.timestamp) > maxDelay);
        //console.log("timeout", timeout);
        if (timeout) {
            //if timeout, any nodes in the list can feed price
            return nodesOffset[msg.sender] > 0;
        }
        //in case of not timeout, scheduling should be in a way of round-robbin
        return decideValidNode(lastRound) == msg.sender;
    }

    //FIXME, if has more gas efffetive implmentaion
    function hasDuplication(PeerPriceFeed[] memory peersPrice)
        internal
        view
        returns (bool)
    {
        bool[MAX_NODES] memory seen;
        for (uint256 i = 0; i < peersPrice.length; i++) {
            uint256 offset = nodesOffset[peersPrice[i].peerAddress];
            require(offset > 0, "peer not in valid list");
            if (seen[offset - 1]) {
                return true;
            }
            seen[offset - 1] = true;
        }
        return false;
    }

    // check whether the feeding has enough signatures from > 2/3 nodes
    function checkSignatures(
        string memory coinName,
        PeerPriceFeed[] memory peersPrice
    ) internal view returns (bool) {
        uint256 prevPeerPrice = 0;
        if ((nodes.length * 2) / 3 >= peersPrice.length) {
            return false;
        }
        require(
            !hasDuplication(peersPrice),
            "signatures has duplicated address"
        );
        for (uint256 i = 0; i < peersPrice.length; i++) {
            PeerPriceFeed memory peer = peersPrice[i];
            require(peer.timestamp > lastPrice.timestamp, "invalid timestamp");
            require(
                peer.price >= prevPeerPrice,
                "price list not soreted in increasing order"
            );
            bytes32 digest = keccak256(
                abi.encodePacked(coinName, peer.price, peer.timestamp)
            );
            address recovered = recoverSign(digest, peer.sig);
            require(recovered == peer.peerAddress, "invalid signature");
            prevPeerPrice = peer.price;
        }
        return true;
    }

    // feedPrice is called by leader node to feed price of cryptos, with a price list reported by all peers
    function feedPrice(
        string memory coinName,
        PeerPriceFeed[] memory peersPrice
    ) public {
        require(
            keccak256(bytes(coinName)) == keccak256(bytes(coin)),
            "coin mismatch"
        );
        require(isMyTurn(), "invalid transmission node");
        require(
            checkSignatures(coinName, peersPrice),
            "no enough signatures of nodes"
        );
        PriceInfo memory priceInfo;
        priceInfo.price = peersPrice[peersPrice.length / 2].price; //median
        priceInfo.timestamp = block.timestamp;
        //console.log("timestamp", block.timestamp);
        lastPrice = priceInfo;
        emit PriceFeed(lastRound, feedCount, peersPrice);
        ++feedCount;
        if (feedCount % countPerRound == 0) {
            ++lastRound; //next round
        }
    }

    // addNode: add new trasmission node
    function addNode(address newNode) public {
        require(msg.sender == admin, "invalid caller to add new node");
        nodes.push(newNode);
        require(nodes.length < MAX_NODES, "too many nodes added");
        nodesOffset[newNode] = nodes.length;
        emit NodeAdded(newNode);
    }

    // execute removing of a node
    function swapAndPop(address rmNode) internal {
        uint256 offset = nodesOffset[rmNode];
        require(offset > 0, "node not exsit");
        address tailNode = nodes[nodes.length - 1];
        nodes[offset - 1] = tailNode;
        nodesOffset[tailNode] = offset;
        nodes.pop();
        delete nodesOffset[rmNode];
    }

    // removeNode remove trasmission node from whitelist
    function removeNode(address rmNode) public {
        require(msg.sender == admin, "invalid caller to remove node");
        swapAndPop(rmNode);
        emit NodeRemoved(rmNode);
    }

    // kickNode remove trasmission node from whitelist
    function kickNode(address rmNode) public {
        //check duplicated vote
        for (uint256 i = 0; i < kickProposals[rmNode].length; i++) {
            require(kickProposals[rmNode][i] != msg.sender, "duplciated vote");
        }
        bool valid_sender = false;
        for (uint256 i = 0; i < nodes.length; i++) {
            if (nodes[i] == msg.sender) {
                valid_sender = true;
                break;
            }
        }
        require(valid_sender, "invalid node to kick others");
        // vote to kick
        kickProposals[rmNode].push(msg.sender);
        // >2/3 agree
        if ((nodes.length * 2) / 3 < kickProposals[rmNode].length) {
            swapAndPop(rmNode);
            emit NodeKicked(rmNode);
        }
    }

    // transferOwnership transfer the ownership of this contract
    function transferOwnership(address newOwner) public {
        require(msg.sender == admin, "invalid caller to transfer ownership");
        admin = newOwner;
    }

    //recover address from sign
    function recoverSign(bytes32 hash, bytes memory sig)
        public
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        //Check the signature length
        if (sig.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
    }
}