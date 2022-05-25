/**
 *Submitted for verification at polygonscan.com on 2022-05-25
*/

// File: contracts/interfaces/IPlayerselfRegistry.sol


pragma solidity ^0.8.1;

interface IPlayerselfRegistry {

    struct NFT {
        bool enabled;
        bool supportsBatch;
    }

    function isSupported(address addr) external view returns(bool);
    function getNFT(address addr) external view returns (NFT memory);

}
// File: contracts/PlayerselfRegistry.sol


pragma solidity ^0.8.1;


contract PlayerselfRegistry is IPlayerselfRegistry {
    address private _owner;
    mapping(address => NFT) private _contracts;

    event NFTRegistered(address indexed contractAddress, bool supportsBatch);
    event NFTDisabled(address indexed contractAddress);

    constructor() {
        _owner = msg.sender;
    }

    modifier _onlyOwner() {
        require(msg.sender == _owner, 'Unauthorized.');
        _;
    }

    function setContract(address addr, bool supportsBatch) public _onlyOwner {
        require(addr != address(0), "Invalid address.");
        if (_contracts[addr].enabled) {
            emit NFTDisabled(addr);
        } else {
            emit NFTRegistered(addr, supportsBatch);
        }
        _contracts[addr] = NFT(!_contracts[addr].enabled, supportsBatch);
    }

    function isSupported(address addr) override public view returns (bool) {
        return _contracts[addr].enabled;
    }

    function getNFT(address addr) override public view returns (NFT memory) {
        return _contracts[addr];
    }
}