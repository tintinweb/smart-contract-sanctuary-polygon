/**
 *Submitted for verification at polygonscan.com on 2023-03-30
*/

pragma solidity ^0.8.0;
/*
  存储证明哈希值
  映射版本
  @author yyx
  @since 2023-3-30
 */

contract HashVerifyStorage {
    mapping(bytes32 => bool) private hashExists;
    bytes32[] private hashes;

    function addHash(bytes32 _hash) public {//添加一个新的哈希值，如果哈希值已存在则会抛出异常
        require(!hashExists[_hash], "Hash already exists");
        hashes.push(_hash);
        hashExists[_hash] = true;
    }

     function addHashes(bytes32[] memory _hashes) public {//添加批量新的哈希值，如果哈希值已存在则会抛出异常
        for (uint256 i = 0; i < _hashes.length; i++) {
            require(!hashExists[_hashes[i]], "Hash already exists");
            hashes.push(_hashes[i]);
            hashExists[_hashes[i]] = true;
        }
    }

    function removeHash(uint256 index) public {//移除指定索引的哈希值，并且保证哈希值唯一性
        require(index < hashes.length, "Index out of bounds");

        bytes32 hashToRemove = hashes[index];

        for (uint256 i = index; i < hashes.length - 1; i++) {
            hashes[i] = hashes[i+1];
        }
        hashes.pop();

        hashExists[hashToRemove] = false;
    }

    function updateHashes(uint256[] memory indices, bytes32[] memory newHashes) public {//批量更新指定索引的哈希值，保证新的哈希值唯一性，并且确保新旧哈希值不相同
        require(indices.length == newHashes.length, "Input lengths do not match");

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

    function getAllHashes() public view returns (bytes32[] memory) {//获取所有当前存储的哈希值
        return hashes;
    }

    function verifyHash(bytes32 hashToVerify) public view returns (bool) {//验证单个哈希值是否存在
        return hashExists[hashToVerify];
    }

    function verifyHashes(bytes32[] memory hashesToVerify) public view returns (bool[] memory) {//批量验证哈希值是否存在
        bool[] memory results = new bool[](hashesToVerify.length);

        for (uint256 i = 0; i < hashesToVerify.length; i++) {
            results[i] = hashExists[hashesToVerify[i]];
        }

        return results;
    }
}