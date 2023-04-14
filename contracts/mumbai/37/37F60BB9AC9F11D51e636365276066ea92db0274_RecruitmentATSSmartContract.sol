pragma solidity ^0.8.0;

contract RecruitmentATSSmartContract {
    // Define a struct to store user information
    struct User {
        string email;
        bool isRegistered;
    }

    // Struct to represent an applicant
    struct Applicant {
        string name;
        uint age;
        string resumeHash;
        address applicantAddress;
        string emailAddress;
    }

    // Struct to represent a job
    struct Job {
        uint jobId;
        string title;
        uint salary;
        string description;
        address employerAddress;
    }

    // Struct to represent a job application
    struct Application {
        address applicantAddress;
        address employerAddress;
        uint jobId;
        bool accepted;
        bool rejected;
    }

    // Struct to represent an employer
    struct Employer {
        string emailAddress;
        string name;
        address ethAddress;
    }

    event NewApplicantAdded(
        address indexed applicantAddress,
        string name,
        uint age,
        string resumeHash
    );
    event NewJobAdded(
        uint indexed jobId,
        string title,
        uint salary,
        string description,
        address indexed employerAddress
    );
    event NewJobApplication(
        address indexed applicantAddress,
        uint indexed jobId
    );
    event JobApplicationAccepted(
        address indexed employerAddress,
        address indexed applicantAddress,
        uint indexed jobId
    );
    event JobApplicationRejected(
        address indexed employerAddress,
        address indexed applicantAddress,
        uint indexed jobId
    );

    Job[] public allJobs;

    // Mapping to store the list of applicants
    mapping(address => Applicant) public applicants;

    // Mapping to store user data by username
    mapping(string => User) private users;

    // Mapping to store the list of jobs
    mapping(uint => Job) public jobs;


    mapping(address => uint[]) public jobsByEmployer;

    // Mapping to store the list of applications
    mapping(uint => mapping(address => Application)) public applications;

    // Mapping to store the list of jobs applied by an applicant
    mapping(address => uint[]) public jobsByApplicant;

    // Mapping to store the list of employers
    mapping(address => Employer) public employers;

    mapping(string => Employer) public employersByEmail;

    mapping(string => Applicant) public applicantByEmail;

    // Modifier to restrict access to employer-only functions
    modifier onlyEmployer() {
        require(
            employers[msg.sender].ethAddress != address(0),
            'Only employers can call this function.'
        );
        _;
    }

    // Modifier to restrict access to applicant-only functions
    modifier onlyApplicant() {
        require(
            applicants[msg.sender].age > 0,
            'Only applicants can call this function.'
        );
        _;
    }

    // Function to add an employer
    function addEmployer(
        string memory name,
        string memory emailAddress,
        address ethAddressIn
    ) public {
        // Ensure the employer does not already exist
        require(
            employers[ethAddressIn].ethAddress == address(0),
            'Employer already exists.'
        );

        // Add the employer
        employers[ethAddressIn] = Employer(emailAddress, name, ethAddressIn);
        employersByEmail[emailAddress] = Employer(
            emailAddress,
            name,
            ethAddressIn
        );
    }

    // Function to add an applicant
    function addApplicant(
        string memory name,
        uint age,
        string memory resumeHash,
        string memory emailAddress,
        address ethAddressIn
    ) public {
        // Ensure the applicant does not already exist
        require(applicants[ethAddressIn].age == 0, 'Applicant already exists.');

        // Add the applicant
        applicants[ethAddressIn] = Applicant(
            name,
            age,
            resumeHash,
            ethAddressIn,
            emailAddress
        );

        applicantByEmail[emailAddress] = Applicant(
            name,
            age,
            resumeHash,
            ethAddressIn,
            emailAddress
        );

        // Emit a NewApplicantAdded event
        emit NewApplicantAdded(msg.sender, name, age, resumeHash);
    }

    // Function to add a job
    function postJob(
        string memory title,
        uint salary,
        string memory description
    ) public onlyEmployer {
        // Ensure the employer exists
        require(
            employers[msg.sender].ethAddress != address(0),
            'Employer does not exist.'
        );

        // Generate a new job ID
        uint jobId = uint(
            keccak256(abi.encodePacked(block.timestamp, msg.sender))
        );

        // Add the job
        jobs[jobId] = Job(jobId, title, salary, description, msg.sender);

        jobsByEmployer[msg.sender].push(jobId);

        allJobs.push(jobs[jobId]);

        // Emit a NewJobAdded event
        emit NewJobAdded(jobId, title, salary, description, msg.sender);
    }

    // Function to apply for a job
    function applyJob(uint jobId) public onlyApplicant {
        // Ensure the job exists
        require(jobs[jobId].salary > 0, 'Job does not exist.');

        // Ensure the applicant has not already applied for this job
        require(
            applications[jobId][msg.sender].applicantAddress != msg.sender,
            'You have already applied for this job.'
        );
        // Add the application
        applications[jobId][msg.sender] = Application(
            msg.sender,
            jobs[jobId].employerAddress,
            jobId,
            false,
            false
        );

        // Add the job ID to the list of jobs applied by the applicant
        jobsByApplicant[msg.sender].push(jobId);

        // Emit a NewJobApplication event
        emit NewJobApplication(msg.sender, jobId);
    }

    // Function to accept an application
    function acceptApplication(
        uint jobId,
        address applicantAddress
    ) public onlyEmployer {
        // Ensure the job exists
        require(jobs[jobId].salary > 0, 'Job does not exist.');

        // Ensure the application exists
        require(
            applications[jobId][applicantAddress].applicantAddress ==
                applicantAddress,
            'Application does not exist.'
        );

        // Ensure the application has not already been accepted or rejected
        require(
            !applications[jobId][applicantAddress].accepted &&
                !applications[jobId][applicantAddress].rejected,
            'Application has already been accepted or rejected.'
        );

        // Set the application as accepted
        applications[jobId][applicantAddress].accepted = true;

        // Emit a JobApplicationAccepted event
        emit JobApplicationAccepted(
            jobs[jobId].employerAddress,
            applicantAddress,
            jobId
        );
    }

    // Function to reject an application
    function rejectApplication(
        uint jobId,
        address applicantAddress
    ) public onlyEmployer {
        // Ensure the job exists
        require(jobs[jobId].salary > 0, 'Job does not exist.');

        // Ensure the application exists
        require(
            applications[jobId][applicantAddress].applicantAddress ==
                applicantAddress,
            'Application does not exist.'
        );

        // Ensure the application has not already been accepted or rejected
        require(
            !applications[jobId][applicantAddress].accepted &&
                !applications[jobId][applicantAddress].rejected,
            'Application has already been accepted or rejected.'
        );

        // Set the application as rejected
        applications[jobId][applicantAddress].rejected = true;

        // Ensure the application was successfully rejected
        assert(applications[jobId][applicantAddress].rejected == true);

        // Emit a JobApplicationRejected event
        emit JobApplicationRejected(
            jobs[jobId].employerAddress,
            applicantAddress,
            jobId
        );
    }

    // Function to get job details by ID
    function getJobDetails(
        uint jobId
    ) public view returns (uint, string memory, uint, string memory, address) {
        // Ensure the job exists
        require(jobs[jobId].salary > 0, 'Job does not exist.');

        // Return the job details
        return (
            jobId,
            jobs[jobId].title,
            jobs[jobId].salary,
            jobs[jobId].description,
            jobs[jobId].employerAddress
        );
    }

    // Function to get applicant details by address
    function getApplicantDetails(
        address applicantAddress
    ) public view returns (string memory, uint, string memory, address) {
        // Ensure the applicant exists
        require(
            applicants[applicantAddress].age > 0,
            'Applicant does not exist.'
        );

        // Return the applicant details
        return (
            applicants[applicantAddress].name,
            applicants[applicantAddress].age,
            applicants[applicantAddress].resumeHash,
            applicants[applicantAddress].applicantAddress
        );
    }

    // Function to get employer details by address
    function getEmployerDetailsByEmail(
        string memory emailAddress
    ) public view returns (string memory, string memory, address) {
        // Ensure the employer exists
        require(
            employersByEmail[emailAddress].ethAddress != address(0),
            'Employer does not exist.'
        );

        // Return the employer details
        return (
            employersByEmail[emailAddress].name,
            employersByEmail[emailAddress].emailAddress,
            employersByEmail[emailAddress].ethAddress
        );
    }

    // Function to get employer details by address
    function getApplicantDetailsByEmail(
        string memory emailAddress
    ) public view returns (string memory, uint, string memory, string memory, address) {
        // Ensure the employer exists
        require(
            applicantByEmail[emailAddress].age > 0,
            'Applicant does not exist.'
        );

        // Return the employer details
        return (
            applicantByEmail[emailAddress].name,
            applicantByEmail[emailAddress].age,
            applicantByEmail[emailAddress].resumeHash,
            applicantByEmail[emailAddress].emailAddress,
            applicantByEmail[emailAddress].applicantAddress

        );
    }

    // Function to get employer details by address
    function getEmployerDetailsAddress(
        address ethAddress
    ) public view returns (string memory, string memory, address) {
        // Ensure the employer exists
        require(
            employers[ethAddress].ethAddress != address(0),
            'Employer does not exist.'
        );

        // Return the employer details
        return (
            employers[ethAddress].name,
            employers[ethAddress].emailAddress,
            employers[ethAddress].ethAddress
        );
    }

    // Function to get application details by job ID and applicant address
    function getApplicationDetails(
        uint jobId,
        address applicantAddress
    ) public view returns (bool accepted, bool rejected) {
        // Ensure the application exists
        require(
            applications[jobId][applicantAddress].applicantAddress ==
                applicantAddress,
            'Application does not exist.'
        );
        // Return the application details
        return (
            applications[jobId][applicantAddress].accepted,
            applications[jobId][applicantAddress].rejected
        );
    }

    // Function to get all jobs posted by an employer
    function getAllJobsByEmployerAddress(
        address employerAddress
    ) public view returns (Job[] memory) {
        // Initialize an empty array of jobs
        Job[] memory jobList = new Job[](100);
        uint jobCount = 0;

        // Iterate through all jobs posted by the employer and add to the list
        for (uint i = 0; i < jobsByEmployer[employerAddress].length; i++) {
            uint jobId = jobsByEmployer[employerAddress][i];
            if (jobs[jobId].salary > 0) {
                jobList[jobCount] = jobs[jobId];
                jobCount++;
            }
        }

        // Resize the job list to the number of jobs posted by the employer
        assembly {
            mstore(jobList, jobCount)
        }

        return jobList;
    }

    // Function to get all jobs applied by an applicant
    function getAllJobsByApplicantAddress(
        address applicantAddress
    ) public view returns (Job[] memory) {
        // Initialize an empty array of jobs
        Job[] memory jobList = new Job[](100);
        uint jobCount = 0;

        // Iterate through all jobs applied by the applicant and add to the list
        for (uint i = 0; i < jobsByApplicant[applicantAddress].length; i++) {
            uint jobId = jobsByApplicant[applicantAddress][i];
            if (jobs[jobId].salary > 0) {
                jobList[jobCount] = jobs[jobId];
                jobCount++;
            }
        }

        // Resize the job list to the number of jobs applied by the applicant
        assembly {
            mstore(jobList, jobCount)
        }

        return jobList;
    }

    // Function to register a new user
    function registerUser(string memory _email) public {
        require(!users[_email].isRegistered, 'Username already exists');

        users[_email] = User({email: _email, isRegistered: true});
    }

    // Function to authenticate a user by checking if the username exists in the mapping
    function authenticateUser(string memory _email) public view returns (bool) {
        return users[_email].isRegistered;
    }

    function getAllJobs() public view returns (Job[] memory) {
     return allJobs;
    }
}