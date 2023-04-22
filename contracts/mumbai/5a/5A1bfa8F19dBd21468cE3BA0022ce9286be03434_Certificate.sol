// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../interfaces/IUser.sol";

contract Certificate {
    struct AppCertificate {
        string name;
        uint verifiedAt;
        bool exist;
    }

    //=============================ATTRIBUTES==========================================
    mapping(uint => AppCertificate) certs;
    mapping(uint => address) candidateOwnCert;
    IUser user;

    constructor(address _userContract) {
        user = IUser(_userContract);
    }

    //=============================EVENTS==========================================
    event AddCertificate(
        uint id,
        string name,
        uint verified_at,
        address indexed owner_address
    );
    event UpdateCertificate(
        uint id,
        string name,
        uint verified_at,
        address indexed owner_address
    );
    event DeleteCertificate(
        uint id,
        string name,
        uint verified_at,
        address indexed owner_address
    );

    //=============================ERRORS==========================================
    error NotExisted(uint id);
    error AlreadyExisted(uint id);
    error NotOwned(uint id, address candidate_address);

    error NotCandidate(address user_address);

    //=============================METHODs==========================================
    //==================CERTIFICATES=======================
    function isOwnerOfCertificate(
        address _candidateAddress,
        uint _id
    ) public view returns (bool) {
        return candidateOwnCert[_id] == _candidateAddress;
    }

    function getCertificate(
        uint _id
    ) public view returns (AppCertificate memory) {
        return certs[_id];
    }

    // only candidate -> later⏳
    // param _candidateAddress must equal msg.sender -> later⏳
    // id must not existed -> done✅
    // just add for candidate -> done✅
    function addCertificate(
        uint _id,
        string memory _name,
        uint _verifiedAt,
        address _candidateAddress
    ) public {
        if (certs[_id].exist) {
            revert AlreadyExisted({id: _id});
        }
        if (
            !(user.isExisted(_candidateAddress) &&
                user.hasType(_candidateAddress, 0))
        ) {
            revert NotCandidate({user_address: _candidateAddress});
        }

        certs[_id] = AppCertificate(_name, _verifiedAt, true);
        candidateOwnCert[_id] = _candidateAddress;

        AppCertificate memory cert = certs[_id];

        emit AddCertificate(_id, cert.name, cert.verifiedAt, _candidateAddress);
    }

    // only candidate -> later⏳
    // candidate must own certificate -> later⏳
    // id must not existed -> later⏳
    function updateCertificate(
        uint _id,
        string memory _name,
        uint _verifiedAt
    ) public {
        if (!certs[_id].exist) {
            revert NotExisted({id: _id});
        }

        // if (isOwnerOfCertificate(msg.sender, _id)) {
        //     revert NotOwned({id: _id, candidate_address: msg.sender});
        // }

        certs[_id].name = _name;
        certs[_id].verifiedAt = _verifiedAt;
        AppCertificate memory cert = certs[_id];

        address candidateAddress = candidateOwnCert[_id];

        emit UpdateCertificate(
            _id,
            cert.name,
            cert.verifiedAt,
            candidateAddress
        );
    }

    // only candidate -> later⏳
    // candidate must own certificate -> later⏳
    // id must not existed -> done✅
    function deleteCertificate(uint _id) public {
        if (!certs[_id].exist) {
            revert NotExisted({id: _id});
        }

        if (isOwnerOfCertificate(msg.sender, _id)) {
            revert NotOwned({id: _id, candidate_address: msg.sender});
        }

        AppCertificate memory certificate = certs[_id];
        address ownerAddress = candidateOwnCert[_id];

        delete certs[_id];
        delete candidateOwnCert[_id];

        emit DeleteCertificate(
            _id,
            certificate.name,
            certificate.verifiedAt,
            ownerAddress
        );
    }

    //======================USER CONTRACT==========================
    function setUserInterface(address _contract) public {
        user = IUser(_contract);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUser {
    function isExisted(address _userAddress) external view returns (bool);

    function hasType(address _user, uint _type) external view returns (bool);
}