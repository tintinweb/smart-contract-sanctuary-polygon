// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import "./libs/Structs.sol";
import "./Ownable.sol";
import "./Job.sol";

error BuildingOwner__UserAlreadyRegistered();
error BuildingOwner__OnlyOwnerCanRegisterBuildingOwners();

contract BuildingOwner is Ownable {

  mapping(address=>bool) public registered_building_owners;
  
  event BuildingOwnerRegistered(address indexed buildingOwnerAddress);

  function addBuildingOwner(address buildingOwnerAddress) public {
    if (msg.sender != owner()) {
      revert BuildingOwner__OnlyOwnerCanRegisterBuildingOwners(); 
    }
    if (registered_building_owners[buildingOwnerAddress] != false) {
      revert BuildingOwner__UserAlreadyRegistered();
    }
    registered_building_owners[buildingOwnerAddress] = true;
    emit BuildingOwnerRegistered(buildingOwnerAddress);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./libs/Structs.sol";

contract Job {
  using Structs for Structs.Job;

  mapping (string => Structs.Job) public jobs;
  
  event JobCreated(string job_id);

  function createJob(
    string memory job_id, 
    string memory job_metadata_IPFS_URI, 
    address service_provider_id,
    address building_owner_id
  ) public {
    // check is a building owner
    // msg.sender === building owner address
    // add job to jobs (remember to set status to pendingAcceptance)
        // Structs.Job memory job = Job(job_id, job_metadata_IPFS_URI, service_provider_id, building_owner_id);
        // people[key] = person;
    // emit event that a job has been created
    jobs[job_id] = Structs.Job({
      job_metadata_IPFS_URI: job_metadata_IPFS_URI,
      job_status: "pendingAcceptance", 
      building_owner_id: building_owner_id, 
      service_provider_id: service_provider_id, 
      start_date: 0, 
      completion_date: 0, 
      service_provider_job_update_IPFS_URIs: new string[](0)
    });

    emit JobCreated(job_id);
  }

  function getJob(string memory job_id) public view returns (string memory, string memory, address, address, uint, uint, string[] memory) {
      Structs.Job memory job = jobs[job_id];
      return (
        job.job_metadata_IPFS_URI, 
        job.job_status,
        job.service_provider_id,
        job.building_owner_id, 
        job.start_date,
        job.completion_date,
        job.service_provider_job_update_IPFS_URIs);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library Structs {
  struct Job {
      string job_metadata_IPFS_URI;
      string job_status;
      address building_owner_id;
      address service_provider_id;
      uint64 start_date;
      uint64 completion_date;
      string[] service_provider_job_update_IPFS_URIs;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./libs/Structs.sol";
import "./BuildingOwner.sol";
import "./ServiceProvider.sol";

// job creation errors
error Marketplace__OnlyBuildingOwnerCanCreateJobs();
error Marketplace__CannotCreateJobWithUnregisteredServiceProvider();

// accept job errors
error Marketplace__OnlyServiceProviderCanAcceptJobs();
error Marketplace__OnlyServiceProviderSignedToJobCanAccecpt();
error Marketplace__CanOnlyAcceptJobsWithPendingAcceptanceStatus();

// add job update errors
error Marketplace__OnlyServiceProviderCanAddJobUpdates();
error Marketplace__OnlyServiceProviderSignedToJobCanAddJobUpdates();
error Marketplace__CanOnlyAddJobUpdatesToExistingJobs();
error Marketplace__CanOnlyAddJobUpdatesToAnOngoingJob();

// close job errors
error Marketplace__OnlyServiceProviderCanCloseJob();
error Marketplace__OnlyServiceProviderSignedToJobCanCloseIt();
error Marketplace__CanOnlyCloseAnOngoingJob();

contract Marketplace is BuildingOwner, ServiceProvider {
  using Structs for Structs.Job;

  // jobs = job_id => Job
  mapping (string => Structs.Job) public jobs;
  // service_providers_closed_jobs = service_provider_id => job_ids[]
  mapping (address => string[]) public service_providers_closed_jobs;
  
  event JobCreated(string indexed job_id, address building_owner_id, address service_provider_id);
  event JobAccepted(string indexed job_id, address service_provider_id);
  event JobUpdateAdded(string indexed job_id, address service_provider_id, string job_update_IPFS_URI, uint index);
  event JobClosed(string indexed job_id, address service_provider_id, uint service_provider_closed_jobs_index);

  function createJob(
    string memory job_id, 
    string memory job_metadata_IPFS_URI, 
    address service_provider_id
  ) public {

    // check the function caller is a registered building owner
    bool buildingOwnerCheck = isBuildingOwner(msg.sender);
    if (!buildingOwnerCheck) {
      revert Marketplace__OnlyBuildingOwnerCanCreateJobs();
    }
    // check the service_provider_id provided is that of a registered service provider
    bool serviceProviderCheck = isServiceProvider(service_provider_id);
    if (!serviceProviderCheck) {
      revert Marketplace__CannotCreateJobWithUnregisteredServiceProvider();
    }

    jobs[job_id] = Structs.Job({
      job_metadata_IPFS_URI: job_metadata_IPFS_URI,
      job_status: "pendingAcceptance", 
      building_owner_id: msg.sender, 
      service_provider_id: service_provider_id, 
      start_date: 0, 
      completion_date: 0, 
      service_provider_job_update_IPFS_URIs: new string[](0)
    });

    emit JobCreated(job_id, msg.sender, service_provider_id);
  }

  function acceptJob(string memory job_id) public {
    // check the function caller is a registered service provider 
    bool serviceProviderRegisteredCheck = isServiceProvider(msg.sender);
    if (!serviceProviderRegisteredCheck) {
      revert Marketplace__OnlyServiceProviderCanAcceptJobs();
    }
    // check the function caller is the appointed service provider for the job 
    bool serviceProviderForJobCheck = isJobForServiceProvider(job_id, msg.sender);
    if (!serviceProviderForJobCheck) {
      revert Marketplace__OnlyServiceProviderSignedToJobCanAccecpt();
    }
    // check that the job status is 'pendingAcceptance'
    bool jobIsPendingAcceptance = 
      (keccak256(abi.encodePacked(jobs[job_id].job_status )) 
        == keccak256(abi.encodePacked("pendingAcceptance")));
    if (!jobIsPendingAcceptance) {
      revert Marketplace__CanOnlyAcceptJobsWithPendingAcceptanceStatus();
    }
    
    // update jobs[job_id].job_status to "ongoing"
    Structs.Job storage job = jobs[job_id]; 
    job.job_status = "ongoing";

    // update the start_date field with block.timestamp
    job.start_date = uint64(block.timestamp);

    // update jobs mapping with the updated job
    jobs[job_id] = job;

    emit JobAccepted(job_id, msg.sender);
  } 

  function addJobUpdate(string memory job_id, string memory job_update_IPFS_URI) public {
    // check the job exists
    bool jobExistsCheck = jobExists(job_id);
    if (!jobExistsCheck) {
      revert Marketplace__CanOnlyAddJobUpdatesToExistingJobs();
    }
    // check the function caller is a registered service provider 
    bool serviceProviderRegisteredCheck = isServiceProvider(msg.sender);
    if (!serviceProviderRegisteredCheck) {
      revert Marketplace__OnlyServiceProviderCanAddJobUpdates();
    }
    // check the function caller is the appointed service provider for the job 
    bool serviceProviderForJobCheck = isJobForServiceProvider(job_id, msg.sender);
    if (!serviceProviderForJobCheck) {
      revert Marketplace__OnlyServiceProviderSignedToJobCanAddJobUpdates();
    }

    // check job status is "ongoing"
    bool jobIsOngoing = 
      (keccak256(abi.encodePacked(jobs[job_id].job_status )) 
        == keccak256(abi.encodePacked("ongoing")));
    if (!jobIsOngoing) {
      revert Marketplace__CanOnlyAddJobUpdatesToAnOngoingJob();
    }
    
    // add job update ipfs uri to jobs[job_id].service_provider_job_update_IPFS_URIs
    Structs.Job storage job = jobs[job_id]; 
    job.service_provider_job_update_IPFS_URIs.push(job_update_IPFS_URI);

    // update the jobs mapping with the updated job
    jobs[job_id] = job;
    emit JobUpdateAdded(job_id, msg.sender, job_update_IPFS_URI, 
                        job.service_provider_job_update_IPFS_URIs.length - 1);
  } 

  function closeJob(string memory job_id) public {
    // check the function caller is a registered service provider 
    bool serviceProviderRegisteredCheck = isServiceProvider(msg.sender);
    if (!serviceProviderRegisteredCheck) {
      revert Marketplace__OnlyServiceProviderCanCloseJob();
    }
    // check the function caller is the appointed service provider for the job 
    bool serviceProviderForJobCheck = isJobForServiceProvider(job_id, msg.sender);
    if (!serviceProviderForJobCheck) {
      revert Marketplace__OnlyServiceProviderSignedToJobCanCloseIt();
    }
    // check job status is "ongoing"
    bool jobIsOngoing = 
      (keccak256(abi.encodePacked(jobs[job_id].job_status )) 
        == keccak256(abi.encodePacked("ongoing")));
    if (!jobIsOngoing) {
      revert Marketplace__CanOnlyCloseAnOngoingJob();
    }

    // update jobs[job_id].job_status to "closed"
    Structs.Job storage job = jobs[job_id]; 
    job.job_status = "closed";

    // update the completion_ date field with block.timestamp
    job.completion_date = uint64(block.timestamp);

    // update the jobs mapping with the updated job
    jobs[job_id] = job;

    // add job_id to service_providers_closed_jobs[msg.sender]
    service_providers_closed_jobs[msg.sender].push(job_id);
    emit JobClosed(job_id, msg.sender, service_providers_closed_jobs[msg.sender].length - 1);
  } 

  function getJob(string memory job_id) public view returns (
    string memory,
    string memory,
    address,
    address,
    uint,
    uint,
    string[] memory) 
    {
      Structs.Job memory job = jobs[job_id];
      return (
        job.job_metadata_IPFS_URI, 
        job.job_status,
        job.service_provider_id,
        job.building_owner_id, 
        job.start_date,
        job.completion_date,
        job.service_provider_job_update_IPFS_URIs);
  }

  function getClosedJobs(address service_provider_id) public view returns (
    string[] memory) {
      string[] memory closedJobs = service_providers_closed_jobs[service_provider_id];
      return closedJobs;
  }

  function getJobUpdates(string memory job_id) public view returns (string[] memory) {
    return jobs[job_id].service_provider_job_update_IPFS_URIs;
  }

  function isServiceProvider(address service_provider_id) internal view returns (bool) {
    return registered_service_providers[service_provider_id];
  }

  function isJobForServiceProvider(string memory job_id, address service_provider_id) internal view returns (bool) {
    return jobs[job_id].service_provider_id == service_provider_id;
  }

  function isBuildingOwner(address building_owner_id) internal view returns (bool) {
    return registered_building_owners[building_owner_id];
  }

  function jobExists(string memory job_id) internal view returns (bool) {
    return (keccak256(abi.encodePacked(jobs[job_id].job_status )) 
        != keccak256(abi.encodePacked("")));
  }  
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

error Ownable__OnlyOwnerCanTransferOwnership();

contract Ownable {
    address private _owner;
    
    constructor() {
        _owner = msg.sender;
    }
    
    function owner() public view returns (address) {
        return _owner;
    }
    
    function transferOwnership(address newOwner) public {
        if(msg.sender == _owner){
          revert Ownable__OnlyOwnerCanTransferOwnership();
        } 
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import "./libs/Structs.sol";
import "./Ownable.sol";

error serviceProvider__UserAlreadyRegistered();
error serviceProvider__OnlyOwnerCanRegisterServiceProviders();

contract ServiceProvider is Ownable{

  mapping(address=>bool) public registered_service_providers ;
  
  event serviceProviderRegistered(address indexed serviceProviderAddress);

  function addServiceProvider(address serviceProviderAddress) public {
    if (msg.sender != owner()) {
      revert serviceProvider__OnlyOwnerCanRegisterServiceProviders();
    }
    if (registered_service_providers[serviceProviderAddress] != false) {
      revert serviceProvider__UserAlreadyRegistered();
    }
    registered_service_providers[serviceProviderAddress] = true;
    emit serviceProviderRegistered(serviceProviderAddress);
  }
}