/**
 *Submitted for verification at polygonscan.com on 2023-04-15
*/

pragma solidity ^0.8.0;
/*
  权限认证存储证明哈希值
  附加library SafeMath
  映射版本
  @author yyx
  @since 2023-4-14
 */

contract SafeHashVerifyStorage {
    mapping(bytes32 => bool) private hashExists;
    bytes32[] private hashes;
    mapping(address => bool) private authorized;
    address public owner;

    modifier onlyAuthorized() {
        require(authorized[msg.sender], "Unauthorized");
        _;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner can call this function"
        );
        _;
    }

    constructor() {
        owner = msg.sender;
        authorized[msg.sender] = true;
    }

    function addHash(bytes32 _hash) public onlyAuthorized {
        require(!hashExists[_hash], "Hash already exists");
        hashes.push(_hash);
        hashExists[_hash] = true;
    }

    function addHashes(bytes32[] memory _hashes) public onlyAuthorized {
        for (uint256 i = 0; i < _hashes.length; i++) {
            require(!hashExists[_hashes[i]], "Hash already exists");
            hashes.push(_hashes[i]);
            hashExists[_hashes[i]] = true;
        }
    }

    function removeHash(uint256 index) public onlyAuthorized {
        require(index < hashes.length, "Index out of bounds");

        bytes32 hashToRemove = hashes[index];

        for (uint256 i = index; i < hashes.length - 1; i++) {
            hashes[i] = hashes[i + 1];
        }
        hashes.pop();

        hashExists[hashToRemove] = false;
    }

    function updateHashes(uint256[] memory indices, bytes32[] memory newHashes)
        public
        onlyAuthorized
    {
        require(
            indices.length == newHashes.length,
            "Input lengths do not match"
        );

        for (uint256 i = 0; i < indices.length; i++) {
            require(indices[i] < hashes.length, "Index out of bounds");

            bytes32 oldHash = hashes[indices[i]];
            bytes32 newHash = newHashes[i];

            require(oldHash != newHash, "New hash is the same as the old one");
            require(!hashExists[newHash], "New hash already exists");

            hashes[indices[i]] = newHash;
            hashExists[oldHash] = false;
            hashExists[newHash] = true;
        }
    }

    function getAllHashes() public view returns (bytes32[] memory) {
        return hashes;
    }

    function verifyHash(bytes32 hashToVerify) public view returns (bool) {
        return hashExists[hashToVerify];
    }

    function verifyHashes(bytes32[] memory hashesToVerify)
        public
        view
        returns (bool[] memory)
    {
        bool[] memory results = new bool[](hashesToVerify.length);

        for (uint256 i = 0; i < hashesToVerify.length; i++) {
            results[i] = hashExists[hashesToVerify[i]];
        }

        return results;
    }

    function addAuthorized(address _address) public onlyAuthorized {
        authorized[_address] = true;
    }

    function removeAuthorized(address _address) public onlyAuthorized {
        authorized[_address] = false;
    }

    function isOwner(address _address) public view returns (bool) {
        return authorized[_address];
    }

    function destroy() public onlyOwner {
        selfdestruct(payable(owner));
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * @title SafeMath32
 * @dev SafeMath library implemented for uint32
 */
library SafeMath32 {
    function mul(uint32 a, uint32 b) internal pure returns (uint32) {
        if (a == 0) {
            return 0;
        }
        uint32 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint32 a, uint32 b) internal pure returns (uint32) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint32 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint32 a, uint32 b) internal pure returns (uint32) {
        assert(b <= a);
        return a - b;
    }

    function add(uint32 a, uint32 b) internal pure returns (uint32) {
        uint32 c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * @title SafeMath16
 * @dev SafeMath library implemented for uint16
 */
library SafeMath16 {
    function mul(uint16 a, uint16 b) internal pure returns (uint16) {
        if (a == 0) {
            return 0;
        }
        uint16 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint16 a, uint16 b) internal pure returns (uint16) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint16 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint16 a, uint16 b) internal pure returns (uint16) {
        assert(b <= a);
        return a - b;
    }

    function add(uint16 a, uint16 b) internal pure returns (uint16) {
        uint16 c = a + b;
        assert(c >= a);
        return c;
    }
}