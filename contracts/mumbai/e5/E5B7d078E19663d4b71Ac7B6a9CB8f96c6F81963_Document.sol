/**
 *Submitted for verification at polygonscan.com on 2022-06-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Document {

    struct UserDocument {
        address user;
        string documentOne;
        string documentTwo;
        string documentThree;
    }

    mapping(address => UserDocument) private documents;

    mapping(address => mapping(address => bool)) private approval;

    function uploadDocument(string memory _documentOne, string memory _documentTwo, string memory _documentThree) public {
        
        UserDocument memory newDocument = UserDocument(
            msg.sender,
            _documentOne,
            _documentTwo,
            _documentThree
        );

        documents[msg.sender] = newDocument;
    }

    function approveDocument(address _approveTo, bool _approve) public {
        approval[msg.sender][_approveTo] = _approve;
    }

}