/**
 *Submitted for verification at polygonscan.com on 2023-05-19
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Certification {
    uint256 cId = 0;

    address owner;

    constructor() {
        owner = msg.sender;
    }

    struct Certificate {
        bytes32 certId;
        string candidate_name;
        string academi;
        string course_name;
        string passing_year;
        string gred;
    }

    Certificate[] allCertificates;
    mapping(bytes32 => Certificate) certificates;

    event createCertificate(
        bytes32 _certificateId,
        string candidate_name,
        string academi,
        string course_name,
        string passing_year,
        string gred
    );

    function stringToBytes32(uint256 _id, string memory _name)
        private
        pure
        returns (bytes32)
    {
        string memory data = string(abi.encodePacked(_id, " ", _name));
        bytes memory bData = bytes(data);
        return keccak256(bData);
    }

    function generateCertificate(
        string memory _candidate_name,
        string memory _academi,
        string memory _course_name,
        string memory _passing_year,
        string memory _grade
    ) public returns (bytes32) {
        bytes32 byte_id;
        byte_id = stringToBytes32(cId, _candidate_name);
        cId++;
        certificates[byte_id] = Certificate(
            byte_id,
            _candidate_name,
            _academi,
            _course_name,
            _passing_year,
            _grade
        );
        emit createCertificate(
            byte_id,
            _candidate_name,
            _academi,
            _course_name,
            _passing_year,
            _grade
        );
        allCertificates.push(
            Certificate(
                byte_id,
                _candidate_name,
                _academi,
                _course_name,
                _passing_year,
                _grade
            )
        );
        return byte_id;
    }

    function getData(bytes32 _id) public view returns (Certificate memory) {
        Certificate memory temp = certificates[_id];
        return (temp);
    }

    function getAllData() public view returns (Certificate[] memory) {
        require(msg.sender == owner, "You are not Authorized");
        return allCertificates;
    }

    // Editing Part
    uint256 editId = 0;
    struct edited {
        bytes32 oldAdd;
        bytes32 newAdd;
    }

    mapping(bytes32 => edited) edites;
    event editEvent(bytes32 oldAdd, bytes32 newAdd);

    edited[] editChain;

    function editCertificate(
        bytes32 _old,
        string memory _candidate_name,
        string memory _academi,
        string memory _course_name,
        string memory _passing_year,
        string memory _grade
    ) public returns (bytes32) {
        bytes32 editedCertificate = generateCertificate(
            _candidate_name,
            _academi,
            _course_name,
            _passing_year,
            _grade
        );
        bytes32 byte_id;
        byte_id = stringToBytes32(editId, _candidate_name);
        emit editEvent(_old, editedCertificate);
        edites[byte_id] = edited(_old, editedCertificate);
        editChain.push(edited(_old, editedCertificate));
        editId++;
        return editedCertificate;
    }

    function getEditedChain() public view returns (edited[] memory) {
        return editChain;
    }
}