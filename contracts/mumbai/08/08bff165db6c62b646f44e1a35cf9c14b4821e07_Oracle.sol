/**
 *Submitted for verification at polygonscan.com on 2023-03-05
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Oracle {
    address public owner;

    struct CoinInfo{
        string name;
        uint256 price;
        uint256 lastUpdated;
    }

    mapping (uint256 => CoinInfo) private _CoinsInfo;

    uint256 public coinCounter = 0;
    
    event PriceUpdated(uint256 indexed timeStamp, uint256 price, uint256 coinId);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function addCoin(string memory name) public onlyOwner {
        uint256 i;
        for (i = 0; i < coinCounter; i = i + 1) {
            require(keccak256(abi.encodePacked(_CoinsInfo[i + 1].name)) != keccak256(abi.encodePacked(name)), "Coin already exists");
        }
        coinCounter = coinCounter + 1;
        _CoinsInfo[coinCounter].name = name;
        _CoinsInfo[coinCounter].price = 0;
        _CoinsInfo[coinCounter].lastUpdated = 0;
    }

    function updatePrice(uint256 _coinId, uint256 _price) external {
        require(_coinId <= coinCounter, "Coin not added");
        _CoinsInfo[_coinId].price = _price;
        _CoinsInfo[_coinId].lastUpdated = block.timestamp;
        emit PriceUpdated(block.timestamp, _price, _coinId);
    }

    function getInfo(uint256 _coinId) public view returns(CoinInfo memory _info) {
        return _CoinsInfo[_coinId];
    }

    function getCount() public view returns(uint256 count) {
        return coinCounter;
    }
}