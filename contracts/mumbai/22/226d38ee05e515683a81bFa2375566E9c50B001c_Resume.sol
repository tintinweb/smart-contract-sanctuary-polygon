// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../interfaces/IUser.sol";

// import "./abstract-contract/AccessControl.sol";

contract Resume {
    struct AppResume {
        string data;
        uint createAt;
        uint updateAt;
        bool exist;
    }

    //=============================ATTRIBUTES==========================================
    mapping(uint => AppResume) public resumes;
    mapping(address => mapping(uint => bool)) public resumeApprovals;
    mapping(uint => address) public candidateOwnResume;
    IUser public user;

    constructor(address _contract) {
        user = IUser(_contract);
    }

    //=============================EVENTS==========================================
    event AddResume(
        uint id,
        string data,
        uint create_at,
        uint update_at,
        address indexed owner_address
    );
    event DeleteResume(
        uint id,
        string data,
        uint create_at,
        uint update_at,
        address indexed owner_address
    );
    event UpdateResume(
        uint id,
        string data,
        uint create_at,
        uint update_at,
        address indexed owner_address
    );
    event Approval(
        address candidate_address,
        address recruiter_address,
        uint resume_id,
        bool isApproved
    );

    //=============================ERRORS==========================================
    error NotExistedResume(uint id);
    error AlreadyApprovedResume(uint id);

    error NotOwnedResume(address candidate_address, uint id);

    error NotRecruiter(address user_address);
    error NotCandidate(address user_address);

    error NotApprovedRecruiter(address recruiter_address, uint id);
    error AlreadyApprovedRecruiter(address recruiter_address, uint id);

    //=============================METHODS==========================================

    //======================RESUMES==========================
    function isOwnerOfResume(
        address _candidateAddress,
        uint _id
    ) public view returns (bool) {
        return candidateOwnResume[_id] == _candidateAddress;
    }

    function getResume(uint _id) public view returns (AppResume memory) {
        return resumes[_id];
    }

    // only candidate -> later⏳
    // param _candidateAddress must equal msg.sender -> later⏳
    // resume must not existed -> done✅
    // just add for candidate -> done✅
    function addResume(
        uint _id,
        string memory _data,
        uint _createAt,
        address _candidateAddress
    ) public {
        if (resumes[_id].exist) {
            revert AlreadyApprovedResume({id: _id});
        }
        if (
            !(user.isExisted(_candidateAddress) &&
                user.hasType(_candidateAddress, 0))
        ) {
            revert NotCandidate({user_address: _candidateAddress});
        }

        resumes[_id].data = _data;
        resumes[_id].createAt = _createAt;
        resumes[_id].updateAt = _createAt;
        resumes[_id].exist = true;

        candidateOwnResume[_id] = _candidateAddress;

        AppResume memory resume = getResume(_id);
        address owner = candidateOwnResume[_id];

        emit AddResume(
            _id,
            resume.data,
            resume.createAt,
            resume.updateAt,
            owner
        );
    }

    // only candidate -> later⏳
    // resume must existed -> done✅
    // caller must own resume -> later⏳
    // caller must be candidate in user contract -> later⏳
    function updateResume(
        uint _id,
        string memory _data,
        uint256 _updateAt
    ) public {
        if (!resumes[_id].exist) {
            revert NotExistedResume({id: _id});
        }
        // if (isOwnerOfResume(msg.sender, _id)) {
        //     revert NotOwnedResume({id: _id, candidate_address: msg.sender});
        // }

        resumes[_id].data = _data;
        resumes[_id].updateAt = _updateAt;

        AppResume memory resume = getResume(_id);
        address owner = candidateOwnResume[_id];

        emit UpdateResume(
            _id,
            resume.data,
            resume.createAt,
            resume.updateAt,
            owner
        );
    }

    // only candidate -> later⏳
    // resume must existed -> done✅
    // caller must own resume -> later⏳
    // caller must be candidate in user contract -> later⏳
    function deleteResume(uint _id) public {
        if (!resumes[_id].exist) {
            revert NotExistedResume({id: _id});
        }

        // if (isOwnerOfResume(msg.sender, _id)) {
        //     revert NotOwnedResume({id: _id, candidate_address: msg.sender});
        // }

        AppResume memory resume = getResume(_id);
        address ownerAddress = candidateOwnResume[_id];

        delete resumes[_id];

        emit DeleteResume(
            _id,
            resume.data,
            resume.createAt,
            resume.updateAt,
            ownerAddress
        );
    }

    //======================RESUME-RECRUITER==========================
    function isExistedResumeRecruiter(
        address _recruiterAddress,
        uint _resumeId
    ) public view returns (bool) {
        return resumeApprovals[_recruiterAddress][_resumeId];
    }

    // only candidate role -> later⏳
    // resume must existed -> done✅
    // candidate must own resume -> later⏳
    // just aprrove for recruiter -> done✅
    // recruiter have not been approved yet -> done✅
    function connectResumeRecruiter(
        address _recruiterAddress,
        uint _resumeId
    ) public {
        if (!resumes[_resumeId].exist) {
            revert NotExistedResume({id: _resumeId});
        }
        // if (isOwnerOfResume(msg.sender, _resumeId)) {
        //     revert NotOwnedResume({
        //         id: _resumeId,
        //         candidate_address: msg.sender
        //     });
        // }
        if (
            !(user.isExisted(_recruiterAddress) &&
                user.hasType(_recruiterAddress, 1))
        ) {
            revert NotRecruiter({user_address: _recruiterAddress});
        }
        if (resumeApprovals[_recruiterAddress][_resumeId]) {
            revert AlreadyApprovedRecruiter({
                recruiter_address: _recruiterAddress,
                id: _resumeId
            });
        }

        resumeApprovals[_recruiterAddress][_resumeId] = true;
        address ownerAddress = candidateOwnResume[_resumeId];

        emit Approval(
            ownerAddress,
            _recruiterAddress,
            _resumeId,
            resumeApprovals[_recruiterAddress][_resumeId]
        );
    }

    // only candidate -> later⏳
    // resume must existed -> done✅
    // candidate must own resume -> later⏳
    // just disaprrove for recruiter -> done✅
    // recruiter have been approved -> done✅
    function disconnectResumeRecruiter(
        address _recruiterAddress,
        uint _resumeId
    ) public {
        if (!resumes[_resumeId].exist) {
            revert NotExistedResume({id: _resumeId});
        }
        // if (isOwnerOfResume(msg.sender, _resumeId)) {
        //     revert NotOwnedResume({
        //         id: _resumeId,
        //         candidate_address: msg.sender
        //     });
        // }
        if (
            !(user.isExisted(_recruiterAddress) &&
                user.hasType(_recruiterAddress, 1))
        ) {
            revert NotRecruiter({user_address: _recruiterAddress});
        }
        if (!resumeApprovals[_recruiterAddress][_resumeId]) {
            revert NotApprovedRecruiter({
                recruiter_address: _recruiterAddress,
                id: _resumeId
            });
        }

        resumeApprovals[_recruiterAddress][_resumeId] = false;
        address ownerAddress = candidateOwnResume[_resumeId];

        emit Approval(
            ownerAddress,
            _recruiterAddress,
            _resumeId,
            resumeApprovals[_recruiterAddress][_resumeId]
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