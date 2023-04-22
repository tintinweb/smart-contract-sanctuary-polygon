// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../interfaces/ICompany.sol";
import "../interfaces/IUser.sol";

contract Job {
    struct AppJob {
        string title;
        string location;
        string jobType;
        uint createAt;
        uint updateAt;
        uint companyId;
        uint salary;
        string field;
        bool exist;
    }

    //=============================ATTRIBUTES==========================================
    mapping(uint => AppJob) public jobs;
    mapping(address => mapping(uint => bool)) public candidateApplyJob;
    mapping(uint => address) public recruiterOwnJob;
    ICompany public company;
    IUser public user;

    constructor(address _userContract, address _companyContract) {
        user = IUser(_userContract);
        company = ICompany(_companyContract);
    }

    //=============================EVENTS==========================================
    event AddJob(
        uint id,
        string title,
        string location,
        string job_type,
        uint create_at,
        uint update_at,
        uint companyId,
        uint salary,
        string field,
        address owner_address
    );
    event UpdateJob(
        uint id,
        string title,
        string location,
        string job_type,
        uint create_at,
        uint update_at,
        uint companyId,
        uint salary,
        string field,
        address owner_address
    );
    event DeleteJob(
        uint id,
        string title,
        string location,
        string job_type,
        uint create_at,
        uint update_at,
        uint companyId,
        uint salary,
        string field,
        address owner_address
    );
    event ApplyJob(
        address indexed candidate_address,
        address indexed recruiter_address,
        uint job_id,
        bool isApplied
    );
    event DisapplyJob(
        address indexed candidate_address,
        address indexed recruiter_address,
        uint job_id,
        bool isApplied
    );

    //=============================ERRORS==========================================
    error NotExistedJob(uint id);
    error AlreadyExistedJob(uint id);

    error RecruiterNotInCompany(address recruiter_address, uint company_id);

    error NotOwnedJob(address recruiter_address, uint id);

    error NotCandidate(address user_address);
    error NotRecruiter(address user_address);

    error NotAppliedCandidate(address candidate_address, uint id);
    error AlreadyAppliedCandidate(address candidate_address, uint id);

    //=============================METHODS==========================================
    //======================JOBS==========================
    function isOwnerOfJob(
        address _recruiterAddress,
        uint _jobId
    ) public view returns (bool) {
        return recruiterOwnJob[_jobId] == _recruiterAddress;
    }

    function getJob(uint _id) public view returns (AppJob memory) {
        return jobs[_id];
    }

    // only recruiter -> later⏳
    // param _recruiterAddress must equal msg.sender -> later⏳
    // job id must not existed -> done✅
    // just for recruiter in user contract -> done✅
    // recruiter must connected with company id -> done✅
    function addJob(
        uint _id,
        string memory _title,
        string memory _location,
        string memory _jobType,
        uint _createAt,
        uint _companyId,
        uint _salary,
        string memory _field,
        address _recruiterAddress
    ) public virtual {
        if (jobs[_id].exist) {
            revert AlreadyExistedJob({id: _id});
        }
        if (
            !(user.isExisted(_recruiterAddress) &&
                user.hasType(_recruiterAddress, 1))
        ) {
            revert NotRecruiter({user_address: _recruiterAddress});
        }
        if (!company.isExistedCompanyRecruiter(_recruiterAddress, _companyId)) {
            revert RecruiterNotInCompany({
                recruiter_address: _recruiterAddress,
                company_id: _companyId
            });
        }

        jobs[_id] = AppJob(
            _title,
            _location,
            _jobType,
            _createAt,
            _createAt,
            _companyId,
            _salary,
            _field,
            true
        );

        AppJob memory job = getJob(_id);
        recruiterOwnJob[_id] = _recruiterAddress;
        address owner = recruiterOwnJob[_id];

        emit AddJob(
            _id,
            job.title,
            job.location,
            job.jobType,
            job.createAt,
            job.updateAt,
            job.companyId,
            job.salary,
            job.field,
            owner
        );
    }

    // only recruiter -> later⏳
    // job id must existed -> done✅
    // only owner of job -> later⏳
    // recruiter must connected with update company -> later⏳
    function updateJob(
        uint _id,
        string memory _title,
        string memory _location,
        string memory _jobType,
        uint _updateAt,
        uint _companyId,
        uint _salary,
        string memory _field
    ) public virtual {
        if (!jobs[_id].exist) {
            revert NotExistedJob({id: _id});
        }

        // if (!isOwnerOfJob(msg.sender, _id)) {
        //     revert NotOwnedJob({
        //         recruiter_address: msg.sender,
        //         id: _id
        //     });
        // }

        // if (!company.isExistedCompanyRecruiter(msg.sender, _companyId)) {
        //     revert RecruiterNotInCompany({
        //         recruiter_address: msg.sender,
        //         company_id: _companyId
        //     });
        // }

        jobs[_id].title = _title;
        jobs[_id].location = _location;
        jobs[_id].jobType = _jobType;
        jobs[_id].updateAt = _updateAt;
        jobs[_id].companyId = _companyId;
        jobs[_id].salary = _salary;
        jobs[_id].field = _field;

        AppJob memory job = getJob(_id);
        address owner = recruiterOwnJob[_id];

        emit UpdateJob(
            _id,
            job.title,
            job.location,
            job.jobType,
            job.createAt,
            job.updateAt,
            job.companyId,
            job.salary,
            job.field,
            owner
        );
    }

    // only recruiter -> later⏳
    // job id must existed -> done✅
    // only owner of job -> later⏳
    function deleteJob(uint _id) public virtual {
        if (!jobs[_id].exist) {
            revert NotExistedJob({id: _id});
        }

        // if (!isOwnerOfJob(msg.sender, _id)) {
        //     revert NotOwnedJob({
        //         recruiter_address: msg.sender,
        //         id: _id
        //     });
        // }

        AppJob memory job = getJob(_id);
        address ownerOfJob = recruiterOwnJob[_id];

        delete jobs[_id];
        delete recruiterOwnJob[_id];

        emit DeleteJob(
            _id,
            job.title,
            job.location,
            job.jobType,
            job.createAt,
            job.updateAt,
            job.companyId,
            job.salary,
            job.field,
            ownerOfJob
        );
    }

    //======================JOB-CANDIDATE==========================
    // only candidate -> later⏳
    // param _candidateAddress must equal msg.sender -> later⏳
    // candidate have skills to apply for the job -> later⏳ -> hard🔥
    // job must existed -> done✅
    // just candidate in user contract apply -> done✅
    // candidate have not applied this job yet -> done✅
    function connectJobCandidate(
        address _candidateAddress,
        uint _jobId
    ) public virtual {
        if (!jobs[_jobId].exist) {
            revert NotExistedJob({id: _jobId});
        }
        if (
            !(user.isExisted(_candidateAddress) &&
                user.hasType(_candidateAddress, 0))
        ) {
            revert NotCandidate({user_address: _candidateAddress});
        }
        if (candidateApplyJob[_candidateAddress][_jobId]) {
            revert AlreadyAppliedCandidate({
                candidate_address: _candidateAddress,
                id: _jobId
            });
        }

        require(jobs[_jobId].exist, "Job-Applicant: id not existed");
        require(
            !candidateApplyJob[_candidateAddress][_jobId],
            "Job-Applicant: Candidate already applied this job"
        );

        candidateApplyJob[_candidateAddress][_jobId] = true;
        address owner = recruiterOwnJob[_jobId];
        bool isApplied = candidateApplyJob[_candidateAddress][_jobId];

        emit ApplyJob(_candidateAddress, owner, _jobId, isApplied);
    }

    // only candidate -> later⏳
    // param _candidateAddress must equal msg.sender -> later⏳
    // job must existed -> done✅
    // just candidate in user contract disapply -> done✅
    // candidate have applied this job -> done✅
    function disconnectJobCandidate(
        address _candidateAddress,
        uint _jobId
    ) public virtual {
        if (!jobs[_jobId].exist) {
            revert NotExistedJob({id: _jobId});
        }
        if (
            !(user.isExisted(_candidateAddress) &&
                user.hasType(_candidateAddress, 0))
        ) {
            revert NotCandidate({user_address: _candidateAddress});
        }
        if (!candidateApplyJob[_candidateAddress][_jobId]) {
            revert NotAppliedCandidate({
                candidate_address: _candidateAddress,
                id: _jobId
            });
        }

        candidateApplyJob[_candidateAddress][_jobId] = false;
        address owner = recruiterOwnJob[_jobId];
        bool isApplied = candidateApplyJob[_candidateAddress][_jobId];

        emit DisapplyJob(_candidateAddress, owner, _jobId, isApplied);
    }

    //======================FOR INTERFACE==========================
    function isExistedJob(uint _jobId) external view returns (bool) {
        return jobs[_jobId].exist;
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