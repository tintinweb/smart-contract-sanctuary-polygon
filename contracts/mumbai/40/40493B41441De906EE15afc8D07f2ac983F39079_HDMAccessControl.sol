/**
 *Submitted for verification at polygonscan.com on 2022-12-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract HDMAccessControl {
    mapping(uint256 => DataPermissions) public permissions;
    mapping(address => DataRequest[]) public requests;
    address[] public users;

    struct DataRequest {
        address requestee;
        uint256 data;
    }

    struct DataPermissions {
        address owner;
        address user;
        bool isRevoked;
    }

    event DataRequested (
        address requester,
        address requestee,
        uint256 requestIndex
    );

    event DataPermissionsGranted (
        address user,
        address owner,
        uint256 requestIndex,
        uint256 dataHash
    );

    event DataPermissionsRevoked (
        address user,
        address owner,
        uint256 dataHash
    );

    function _registerUser(address _user) private {
        if (requests[_user].length == 0) {
            users.push(_user);
        }
    }

    function requestData(
        address _requestee,
        uint256 _data
    ) public {
        _registerUser(msg.sender);

        requests[msg.sender].push(
            DataRequest(
                _requestee,
                _data
            )
        );

        uint256 requestIndex = requests[msg.sender].length - 1;

        emit DataRequested(
            msg.sender,
            _requestee,
            requestIndex
        );
    }

    function getDataRequestInfo(address _requester, uint256 _requestIndex)
        external
        view
        returns (DataRequest memory)
    {
        return requests[_requester][_requestIndex];
    }

    function acceptDataRequest(
        address _requester,
        uint256 _requestIndex,
        uint256 _dataHash
    ) public {
        _registerUser(msg.sender);

        DataRequest storage requestRef = requests[_requester][_requestIndex];

        require(
            requestRef.requestee == msg.sender, 
            "HDMAccessControl: user has no rights to accept this data request."
        );

        permissions[_dataHash] = DataPermissions(
            msg.sender,
            _requester,
            false
        );

        emit DataPermissionsGranted(
            _requester,
            msg.sender,
            _requestIndex,
            _dataHash
        );
    }

    function revokeAccess(
        uint256 _dataHash
    ) public {
        DataPermissions storage permsRef = permissions[_dataHash];

        require(
            permsRef.owner == msg.sender, 
            "HDMAccessControl: user has no rights to manage this data object."
        );

        require(
            permsRef.isRevoked, 
            "HDMAccessControl: data had been revoked already."
        );

        permissions[_dataHash].isRevoked = true;

        emit DataPermissionsRevoked(
            permsRef.user,
            msg.sender,
            _dataHash
        );
    }


    function getDataPermissionsInfo(uint256 _dataHash)
        external
        view
        returns (DataPermissions memory)
    {
        return permissions[_dataHash];
    }
}