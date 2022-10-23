/**
 *Submitted for verification at polygonscan.com on 2022-10-23
*/

pragma solidity >=0.5.0 <0.6.0;

contract CollectibleCreator {

    event NewCollectible(uint collectibleId, string name, uint dna);

    uint dnaDigits = 16;
    uint dnaModulus = 10 ** dnaDigits;

    struct Collectible {
        string name;
        uint dna;
    }

    mapping (uint => address) public collectibleToOwner;
    mapping (address => uint) ownerCollectibleCount;

    Collectible[] public collectibles;

    function _createCollectible(string memory _name, uint _dna) private {
        uint id = collectibles.push(Collectible(_name, _dna)) - 1;
        collectibleToOwner[id] = msg.sender;
        ownerCollectibleCount[msg.sender]++;
        emit NewCollectible(id, _name, _dna);
    }

    function _generateRandomDna(string memory _str) private view returns (uint) {
        uint rand = uint(keccak256(abi.encodePacked(_str)));
        return rand % dnaModulus;
    }

    function createRandomCollectible(string memory _name) public {
        uint randDna = _generateRandomDna(_name);
        _createCollectible(_name, randDna);
    }

    function getCollectiblesByOwner(address _owner) external view returns(uint[] memory) {
        uint[] memory result = new uint[](ownerCollectibleCount[_owner]);
        uint counter = 0;
        for (uint i = 0; i < collectibles.length; i++) {
            if (collectibleToOwner[i] == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

}