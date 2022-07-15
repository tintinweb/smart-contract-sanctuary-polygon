/**
 *Submitted for verification at polygonscan.com on 2022-07-14
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

contract StaticMetadataService {
    string private _uri;

    constructor(string memory _metaDataUri) {
        _uri = _metaDataUri;
    }

    function uri(uint256) public view returns (string memory) {
        return _uri;
    }
}