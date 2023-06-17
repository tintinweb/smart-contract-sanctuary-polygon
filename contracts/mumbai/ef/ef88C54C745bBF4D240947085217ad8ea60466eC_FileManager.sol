// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./File.sol";

struct Files {
    mapping(string => File) _files;
    string[] _keys;
}

library FileManager {
    function allFiles(Files storage self) internal view returns(File[] memory) {
        File[] memory _files = new File[](self._keys.length);
        for (uint i = 0; i < self._keys.length; i++) {
            _files[i] = self._files[self._keys[i]];
        }
        return _files;
    }

    event FileCreated();

    function addFile(Files storage self, string memory name, string memory fileType, string memory ipfsHash, string memory key) internal {
        File memory f = File(
           {
            _name: name,
            _fileType: fileType,
            _ipfsHash: ipfsHash,
            _key: key
           }
        );
        self._files[ipfsHash] = f;
        self._keys.push(ipfsHash);
        emit FileCreated();
    }

    event FileDeleted();
    function deleteFile(Files storage self, string memory ipfsHash) internal {
        require(abi.encodePacked(self._files[ipfsHash]._ipfsHash).length > 0, "IOB" );
        delete self._files[ipfsHash];
        for (uint i = 0; i < self._keys.length; i++) {
            if (keccak256(abi.encodePacked(self._keys[i])) == keccak256(abi.encodePacked(ipfsHash))) {
                // delete filesKeys[i];
                self._keys[i] = self._keys[self._keys.length-1];
                self._keys.pop();
            }
        }
        emit FileDeleted();
    }

    event FilesImported();
    function migrateFiles(Files storage self, File[] memory _files) public{
        for (uint i = 0; i < _files.length; i++ ){
            self._files[_files[i]._ipfsHash] = _files[i];
            self._keys.push(_files[i]._ipfsHash);
        }
        emit FilesImported();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


struct File {
    string _name;
    string _fileType;
    string _ipfsHash;
    string _key;
}