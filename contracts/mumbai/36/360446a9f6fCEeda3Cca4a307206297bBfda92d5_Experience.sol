// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../interfaces/ICompany.sol";
import "../interfaces/IUser.sol";

contract Experience {
    struct AppExperience {
        string position;
        uint start;
        uint finish;
        uint companyId;
        bool exist;
    }

    //=============================ATTRIBUTES==========================================
    mapping(uint => AppExperience) experiences;
    mapping(address => mapping(uint => bool)) experienceOfUser;
    ICompany company;
    IUser user;

    constructor(address _userContract, address _companyContract) {
        user = IUser(_userContract);
        company = ICompany(_companyContract);
    }

    //=============================EVENTS=====================================
    event AddExperience(
        uint id,
        string position,
        uint start,
        uint finish,
        uint company_id,
        address indexed user_address
    );
    event UpdateExperience(
        uint id,
        string position,
        uint start,
        uint finish,
        uint company_id,
        address indexed user_address
    );
    event DeleteExperience(
        uint id,
        string position,
        uint start,
        uint finish,
        uint company_id,
        address indexed user_address
    );

    //=============================ERRORS==========================================
    error AlreadyExistedExperience(uint experience_id, address user_address);
    error NotExistedExperience(uint experience_id, address user_address);

    error NotExistedCompany(uint experience_id, uint company_id);
    error NotExistedUser(address user_address);

    error AlreadyConnectedExperienceUser(
        uint experience_id,
        address user_address
    );
    error NotConnectedExperienceUser(uint experience_id, address user_address);

    //=============================METHODS==========================================
    //=================EXPERIENCES========================
    // only user -> later⏳
    // param _user must equal msg.sender -> later⏳
    // experience id must not existed -> done✅
    // company must existed -> done✅
    // just for user -> done✅
    // experience have not been connected with user yet -> done✅
    function addExperience(
        address _user,
        uint _id,
        string memory _position,
        uint _start,
        uint _finish,
        uint _companyId
    ) public {
        if (experiences[_id].exist) {
            revert AlreadyExistedExperience({
                experience_id: _id,
                user_address: _user
            });
        }
        if (!company.isExistedCompany(_companyId)) {
            revert NotExistedCompany({
                experience_id: _id,
                company_id: _companyId
            });
        }
        if (!user.isExisted(_user)) {
            revert NotExistedUser({user_address: _user});
        }
        if (experienceOfUser[_user][_id]) {
            revert AlreadyConnectedExperienceUser({
                experience_id: _id,
                user_address: _user
            });
        }

        experiences[_id] = AppExperience(
            _position,
            _start,
            _finish,
            _companyId,
            true
        );
        experienceOfUser[_user][_id] = true;

        AppExperience memory exp = experiences[_id];

        emit AddExperience(
            _id,
            exp.position,
            exp.start,
            exp.finish,
            exp.companyId,
            _user
        );
    }

    // only user -> later⏳
    // experience id must existed -> done✅
    // company must existed -> done✅
    // just for user -> done✅
    function updateExperience(
        address _user,
        uint _id,
        string memory _position,
        uint _start,
        uint _finish,
        uint _companyId
    ) public {
        if (!experiences[_id].exist) {
            revert NotExistedExperience({
                experience_id: _id,
                user_address: _user
            });
        }
        if (!company.isExistedCompany(_companyId)) {
            revert NotExistedCompany({
                experience_id: _id,
                company_id: _companyId
            });
        }
        if (!user.isExisted(_user)) {
            revert NotExistedUser({user_address: _user});
        }

        experiences[_id].position = _position;
        experiences[_id].start = _start;
        experiences[_id].finish = _finish;
        experiences[_id].companyId = _companyId;

        AppExperience memory exp = experiences[_id];

        emit UpdateExperience(
            _id,
            exp.position,
            exp.start,
            exp.finish,
            exp.companyId,
            _user
        );
    }

    // only user -> later⏳
    // param _user must equal msg.sender -> later⏳
    // experience id must existed -> done✅
    // just for user -> done✅
    // experience have been connected with user yet -> done✅
    function deleteExperience(address _user, uint _id) public {
        if (!experiences[_id].exist) {
            revert NotExistedExperience({
                experience_id: _id,
                user_address: _user
            });
        }
        if (!user.isExisted(_user)) {
            revert NotExistedUser({user_address: _user});
        }
        if (!experienceOfUser[_user][_id]) {
            revert NotConnectedExperienceUser({
                experience_id: _id,
                user_address: _user
            });
        }

        AppExperience memory exp = experiences[_id];

        delete experiences[_id];
        delete experienceOfUser[_user][_id];

        emit AddExperience(
            _id,
            exp.position,
            exp.start,
            exp.finish,
            exp.companyId,
            _user
        );
    }

    function getExperience(
        uint _id
    ) public view returns (AppExperience memory) {
        return experiences[_id];
    }

    //======================INTERFACES==========================
    function setUserInterface(address _contract) public {
        user = IUser(_contract);
    }

    function setCompanyInterface(address _contract) public {
        company = ICompany(_contract);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICompany {
    function isExistedCompanyRecruiter(
        address _recruiterAddress,
        uint _companyId
    ) external view returns (bool);

    function isExistedCompany(uint _id) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUser {
    function isExisted(address _userAddress) external view returns (bool);

    function hasType(address _user, uint _type) external view returns (bool);
}