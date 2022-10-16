/**
 *Submitted for verification at polygonscan.com on 2022-10-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Certification {
    address public owner;

    event ownerChanged(address indexed _prevOwner, address indexed _newOwner);
    event certificateAdded(string[] indexed _cid, string[] indexed _ipfs, uint256 indexed _totalCerificates);
    event validate(string indexed _cid, bool indexed _exist);
    
    constructor() {
        owner = msg.sender;
    }

    fallback() external {}

    modifier onlyOwner {
        require(msg.sender == owner, "You are not a owner");
         _;
    }


    function changeOwner(address _newOwner) public onlyOwner {
        owner == _newOwner;

        emit ownerChanged(owner, _newOwner);
    }

    // mapping of hashes(cid) with encrypted IPFS url
    mapping (string => string) private certificates;

    // mapping of all the hashes
    mapping (string => bool) private certificatesValid;

    
    // Read fn
    function certificateExist(string memory _cid) public returns(string memory) {
        
        bool exist;
        
        if (certificatesValid[_cid] == false) exist =  false;
        else exist = true;

        emit validate(_cid, exist);

        require(exist == true, "Certificate does not exist");

        string memory ipfsLink = sendCertificateLink(_cid);

        return ipfsLink;

    }

    function sendCertificateLink(string memory _cid) private view returns(string memory) {
        return certificates[_cid];
    }

    // Write fn
    function addCertificate(string[] memory _cid, string[] memory _ipfsUrl) public {
        require(_cid.length == _ipfsUrl.length, "There is some missing fields. Check Again!");

        for (uint i = 0; i < _cid.length; i++) {
            string memory currentCid = _cid[i];   
            
            certificates[currentCid] = _ipfsUrl[i];
            certificatesValid[currentCid] = true;
        }

        emit certificateAdded( _cid, _ipfsUrl, _cid.length);
    }
}