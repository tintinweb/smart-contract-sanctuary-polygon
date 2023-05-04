// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract JobApplication {
    // Struct to store data about a job application
    struct Application {
        uint id; // Unique identifier for the job application
        uint jobId; // Job ID associated with this application
        address applicant; // Address of the applicant
        string coverLetter; // Cover letter submitted by the applicant
        uint256 timestamp; // Timestamp when the application was submitted
        bool isWithdrawn; // Status of the application: true if withdrawn, false otherwise
    }

    // Counter to keep track of the total number of applications
    uint private applicationCounter;

    // Mapping to store applications by their unique identifier
    mapping(uint => Application) private applications;

    // Mapping to store applications associated with a specific job
    mapping(uint => uint[]) private jobApplications;

    // Mapping to store applications submitted by a specific user
    mapping(address => uint[]) private userApplications;

    // Event emitted when a new job application is submitted
    event ApplicationSubmitted(
        uint indexed applicationId,
        uint indexed jobId,
        address indexed applicant,
        string coverLetter,
        uint256 timestamp
    );

    // Event emitted when a job application is withdrawn
    event ApplicationWithdrawn(uint indexed applicationId);

    // Function to submit a new job application
    function submitApplication(uint _jobId, string memory _coverLetter) public {
        applicationCounter++;

        // Create a new Application struct and store it in the applications mapping
        Application memory newApplication = Application(
            applicationCounter,
            _jobId,
            msg.sender,
            _coverLetter,
            block.timestamp,
            false
        );
        applications[applicationCounter] = newApplication;

        // Update the jobApplications and userApplications mappings
        jobApplications[_jobId].push(applicationCounter);
        userApplications[msg.sender].push(applicationCounter);

        // Emit the ApplicationSubmitted event
        emit ApplicationSubmitted(
            applicationCounter,
            _jobId,
            msg.sender,
            _coverLetter,
            block.timestamp
        );
    }

    // Function to withdraw a job application
    function withdrawApplication(uint _applicationId) public {
        Application storage application = applications[_applicationId];

        // Ensure that only the applicant can withdraw the application
        require(
            application.applicant == msg.sender,
            "Only the applicant can withdraw the application"
        );
        // Ensure that the application is not already withdrawn
        require(!application.isWithdrawn, "Application is already withdrawn");

        application.isWithdrawn = true;

        // Emit the ApplicationWithdrawn event
        emit ApplicationWithdrawn(_applicationId);
    }

    // Function to get the details of a job application by its ID
    function getApplication(
        uint _applicationId
    ) public view returns (Application memory) {
        return applications[_applicationId];
    }

    // Function to get all job applications associated with a specific job
    function getApplicationsByJob(
        uint _jobId
    ) public view returns (Application[] memory) {
        uint[] memory jobAppIds = jobApplications[_jobId];
        Application[] memory jobApps = new Application[](jobAppIds.length);

        for (uint i = 0; i < jobAppIds.length; i++) {
            jobApps[i] = applications[jobAppIds[i]];
        }

        return jobApps;
    }

    // Function to get all job applications submitted by a specific user
    function getApplicationsByUser(
        address _applicant
    ) public view returns (Application[] memory) {
        // Get the array of application IDs submitted by the user
        uint[] memory userAppIds = userApplications[_applicant];

        // Create an array to store the Application structs
        Application[] memory userApps = new Application[](userAppIds.length);

        // Iterate through the array of application IDs and fetch the corresponding Application structs
        for (uint i = 0; i < userAppIds.length; i++) {
            userApps[i] = applications[userAppIds[i]];
        }

        // Return the array of Application structs
        return userApps;
    }
}