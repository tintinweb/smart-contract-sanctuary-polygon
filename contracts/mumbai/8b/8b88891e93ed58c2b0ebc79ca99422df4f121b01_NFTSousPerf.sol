/**
 *Submitted for verification at polygonscan.com on 2022-02-20
*/

pragma solidity 0.8.12;

contract NFTSousPerf {

    struct NFTSP {
        uint256 creationDate;
        uint256 validUntil;
        bool isValue;
    }

    mapping(address => NFTSP) NFTSPs;

    address creator;
    address payable creatorPayable;

    event NFTSPCreate(address indexed owner, NFTSP indexed nftsp);

    event NFTSPTransaction(address indexed oldOwner, address indexed newOwner, NFTSP indexed nftsp);

    event NFTSPRefresh(address indexed owner, NFTSP indexed nftsp);

    uint256 amountToRefresh = 1;
    uint256 secondsToRefresh = 30 * 24 * 60 * 60;
    uint256 secondsInitial = secondsToRefresh;

    constructor() {
        creator = msg.sender;
        creatorPayable = payable(msg.sender);
    }

    function createNFTSP(address destination) payable public {
        assert(creator == msg.sender);
        assert(!NFTSPs[destination].isValue);

        uint256 currentTime = block.timestamp;

        NFTSPs[destination] = NFTSP({
            creationDate: currentTime,
            validUntil: currentTime + secondsToRefresh,
            isValue: true
        });

        emit NFTSPCreate(destination, NFTSPs[destination]);
    }

    function sendNFTSP(address destination) payable public {
        assert(NFTSPs[msg.sender].isValue);
        assert(!NFTSPs[destination].isValue);
        assert(NFTSPs[msg.sender].validUntil >= block.timestamp);

        NFTSPs[destination] = NFTSPs[msg.sender];

        NFTSPs[msg.sender] = NFTSP({
            creationDate: 0,
            validUntil: 0,
            isValue: false
        });

        emit NFTSPTransaction(msg.sender, destination, NFTSPs[destination]);
    }

    function refreshNFTSP() payable public {
        assert(NFTSPs[msg.sender].isValue);
        assert(NFTSPs[msg.sender].validUntil >= block.timestamp);
        assert(msg.value == amountToRefresh);
        creatorPayable.transfer(msg.value);

        NFTSPs[msg.sender].validUntil = NFTSPs[msg.sender].validUntil + secondsToRefresh;

        emit NFTSPRefresh(msg.sender, NFTSPs[msg.sender]);
    }

    function hasValidNFTSP(address addr) view public returns (bool) {
        return NFTSPs[addr].isValue && NFTSPs[addr].validUntil >= block.timestamp;
    }
}