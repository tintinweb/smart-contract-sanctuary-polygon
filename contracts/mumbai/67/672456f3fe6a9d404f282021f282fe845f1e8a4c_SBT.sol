// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract SBT {

    struct Soul {
        string id;
        string url;
        uint256 score;
        uint256 timestamp;
        address owner;
        bool available;
    }

    mapping (address => Soul) public souls;

    string public name;
    string public description;
    address public operator;
    bytes32 private zeroHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    
    event Mint(address _soul);
    event Burn(address _soul);
    event Update(address _soul);

    constructor(string memory _name, string memory _description) {
        name = _name;
        description = _description;
        operator = msg.sender;
    }

    function mint(address _soul, Soul memory _soulData) external {
        require(keccak256(bytes(souls[_soul].id)) == zeroHash, "Soul already exists");
        require(msg.sender == operator, "Only operator can mint new souls");
        souls[_soul] = _soulData;
        emit Mint(_soul);
    }

    function burn(address _soul) external {
        require(msg.sender == _soul || msg.sender == operator, "Only users and issuers have rights to delete their data");
        delete souls[_soul];
        emit Burn(_soul);
    }
    

    function update(address _soul, Soul memory _soulData) external {
        require(msg.sender == operator, "Only operator can update soul data");
        require(keccak256(bytes(souls[_soul].id)) != zeroHash, "Soul does not exist");
        souls[_soul] = _soulData;
        emit Update(_soul);
    }

    function hasSoul(address _soul) external view returns (bool) {
        if (keccak256(bytes(souls[_soul].id)) == zeroHash) {
            return false;
        } else {
            return true;
        }
    }

    function getSoul(address _soul) external view returns (Soul memory) {
        return souls[_soul];
    }
    
}