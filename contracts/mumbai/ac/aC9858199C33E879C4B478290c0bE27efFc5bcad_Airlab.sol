// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Airlab {

    constructor() {}

	struct Lab{
		uint256 labID;
		address ownerOfLab;
		string typeOfLab; //
		// bool accreditation;
		// Service Offering
		// bool certification;
		// bool consulting;
		// bool testing;
		// bool manufacturing;
		// bool rNd;
		// bool inspection;
		// bool whiteLab;
		// string otherService;
		//Company address
		string address1; //
		// string address2;
		string city; //
		string state;//
		string country;//
		//map
		// string xcoordinate;
		// string ycoordinate;
		//describe your lab
		string labName; //
		// string labDescription; // 
		// string labVisibility;
		// here a textfield was given but wasn't defined, leaving a space for it for later

		// bool homeTest;
		// bool openForCollaborations;
		string bannerPhoto; //ipfs
		string logo; //ipfs
		string link;//
		// uint256 motnhlyCost; //
		// uint256 testPrice;//
		// uint256 rating; //
		Service[] services;

		uint256 fundsInLab;

	}


	struct Service{
		uint256 labID;
		uint256 serviceID;
		// Select category
		string category;
		// Listing Details
		string testName;
		string testMethod;
		//Releasing of resluts
		// bool electronic;
		// bool papers;
		// string otherMethodForResult;
		// custom test file goes into database
		
		// Availability
		uint256 date;
		// Listing price
		// string listingType;
		uint256 price;
		uint256 rating;
		//custom test file goes into database
		
		// string testMethodDescription;
		string serviceImage; // ipfs
		// lab test method text field confusion
		
	}




	// struct BookALab{
	// 	uint256 startDate;
	// 	uint256 endDate;
	// 	string test;
	// 	string Country;
	// 	bool Courier;
	// 	bool travelingForWork;
	// 	bool smoker;
	// 	// Submitter form
	// 	string submitterCompanyName;
	// 	string senderContactPerson;
	// 	string submitterAddress;
	// 	string submitterPhoneNo;
	// 	string submitterFax;
	// 	string submitterEmail;
	// 	string submitterCountry;
	// 	// Reciever form
	// 	string recieverName;
	// 	string recieverContactPerson;
	// 	string recieverAddress;
	// 	string recieverPhoneNo;
	// 	string recieverFax;
	// 	string recieverEmail;
	// 	string recieverCountry;
	// 	// Description from
	// 	string sampleDescription;
	// 	string sampleSize;
	// 	string storageConditions;
	// 	// Select additional services
	// 	uint256[] selectedServices;
	// 	// payment for booking; skipping this part for now
	// 	//  as we will make it a dapp and 
	// 	// not add any centralized payment method

	// 	// Shipping details/ reporting details
	// 	uint256 reportingDate;
	// 	string signature;
	// 	string courier;
	// 	string connote;
	// 	string additionalReportsRecipient;

	// 	// Check this page and ask what's going on here		// http://localhost:3000/page8

	// 	// here the front end will send an email to the person booking the lab


	// }

	// User[] public users;
	
	uint256 public numOfLabs = 0;
    mapping(uint => Lab) public labs;

	uint256 public numOfServices = 0;

    mapping(uint256 => Service) public services;


    mapping(uint256 => Lab) public servicesInLabs;


	// increment this whenever you create a lab

	 function getNumOfLabs() view public returns (uint256) {
        return numOfLabs;
    }

	function setLab(
		uint256 _labID,
		address _ownerOfLab,
		string memory _typeOfLab,
		// bool _accreditation,
		// Service Offering
		// bool _certification,
		// bool _consulting,
		// bool _testing,
		// bool _manufacturing,
		// bool _rNd,
		// bool _inspection,
		// bool _whiteLab,
		// string memory _otherService,
		//Company address
		string memory _address1,
		// string memory _address2,
		string memory _city,
		string memory _state,
		string memory _country,
		//map
		// string memory _xcoordinate,
		// string memory _ycoordinate,
		//describe your lab
		string memory _labName,
		string memory _labDescription,
		// string memory _labVisibility,
		// here a textfield was given but wasn't defined, leaving a space for it for later

		// bool _homeTest,
		// bool _openForCollaborations,
		string memory _bannerPhoto, //ipfs
		string memory _logo, //ipfs
		string memory _link
	) public returns (uint256) {

        Lab storage lab = labs[numOfLabs];

		lab.labID = _labID;
		 lab.ownerOfLab = _ownerOfLab;
		 lab.typeOfLab = _typeOfLab;
		//  lab.accreditation = _accreditation;
		// Service Offering
		//  lab.certification = _certification;
		//  lab.consulting = _consulting;
		//  lab.testing = _testing;
		//  lab.manufacturing = _manufacturing;
		//  lab.rNd = _rNd;
		//  lab.inspection = _inspection;
		//  lab.whiteLab = _whiteLab;
		//  lab.otherService = _otherService;
		//Company address
		 lab.address1 = _address1;
		//  lab.address2 = _address2;
		 lab.city = _city;
		 lab.state = _state;
		 lab.country = _country;
		//map
		//  lab.xcoordinate = _xcoordinate;
		//  lab.ycoordinate = _ycoordinate;
		//describe your lab
		 lab.labName = _labName;
		//  lab.labDescription = _labDescription;
		//  lab.labVisibility = _labVisibility;
		// here a textfield was given but wasn't defined, leaving a space for it for later

		//  lab.homeTest = _homeTest;
		//  lab.openForCollaborations = _openForCollaborations;
		 lab.bannerPhoto = _bannerPhoto; //ipfs
		 lab.logo = _logo; //ipfs
		 lab.link = _link;

		numOfLabs++;

        return numOfLabs - 1;

	}


	function setService(
		uint256 _labID,
		uint256 _serviceID,
		// Select category
		string memory _category,
		// Listing Details
		string memory _testName,
		string memory _testMethod,
		//Releasing of resluts
		// bool _electronic,
		// bool _papers,
		// string memory _otherMethodForResult,
		// custom test file goes into database
		
		// Availability
		uint256 _date,
		// Listing price
		// string memory _listingType,
		uint256 _price,
		//custom test file goes into database
		
		// string memory _testMethodDescription,
		string memory _serviceImage // ipfs
		// lab test method text field confusion
		) public returns (uint256){

		Service storage service = services[numOfServices];


		service.labID = _labID;
		service.serviceID = _serviceID;
		// Select category
		service.category = _category;
		// Listing Details
		service.testName = _testName;
		service.testMethod = _testMethod;
		//Releasing of resluts
		// service.electronic = _electronic;
		// service.papers = _papers;
		// service.otherMethodForResult = _otherMethodForResult;
		// custom test file goes into database
		
		// Availability
		service.date = _date;
		// Listing price
		// service.listingType = _listingType;
		service.price = _price;
		//custom test file goes into database
		
		// service.testMethodDescription = _testMethodDescription;
		service.serviceImage = _serviceImage; // ipfs
		// lab test method text field confusion

		// add service to its lab
		labs[_labID].services.push(service);

		numOfServices++;

        return numOfServices - 1;
	}

	function getServiceDetails(uint256 _serviceID, uint256 _labID) public view 
	returns(string memory,string memory,string memory,string memory,string memory) {
		  return(
			// The commented details will be coming 
			// to the next page by props in frontend

			// services[_serviceID].testName,  
            services[_serviceID].testMethod, 
            // services[_serviceID].price, 
            // services[_serviceID].serviceImage, 
            labs[_labID].city,
            labs[_labID].country,
			// lab details
			// labs[_labID].labName,
			// labs[_labID].address1,
			labs[_labID].logo,
			labs[_labID].link
			// labs[_labID].labDescription
		  );
	}

	function getServicesDataForCards(uint256 _serviceID) public view 
		returns(string memory, uint256, uint256, string memory,  string memory, string memory) {
			return(
			services[_serviceID].testName,  
			services[_serviceID].price,    
			services[_serviceID].rating,    
			services[_serviceID].serviceImage,  
			labs[services[_serviceID].labID].labName,
			labs[services[_serviceID].labID].address1
			);
	}

	function getLabsDataForCards(uint256 _labID) public view 
	returns(string memory, string memory, string memory, string memory){
		return(
		labs[_labID].labName,
		labs[_labID].city,
		labs[_labID].typeOfLab,
		labs[_labID].bannerPhoto
		// labs[_labID].motnhlyCost,
		// labs[_labID].testPrice,
		// labs[_labID].rating
		);
	}

	function getLabDetails(uint256 _labID) public view
	returns(string memory,  string memory, string memory, string memory, string memory ){
		return(
			labs[_labID].address1,
			// labs[_labID].labDescription,
			labs[_labID].link,
			labs[_labID].country,
			labs[_labID].state,
			labs[_labID].logo
		);
	}

	// chutiapa below
	// function bookALab(
	// 	uint256 _labID, 
	// 	string memory _testType, 
	// 	string memory _testName, 
	// 	string memory phoneNumber, 
	// 	string memory time, 
	// 	string memory date, 
	// 	string memory _cost,
	// 	string memory _promoCode
	// ) public payable {

	// 	address user = msg.sender;

	// }      

	function bookAService(uint256 _serviceID, uint256 _labID) public payable {
		uint256 amount = services[_serviceID].price;
		require(msg.value >= amount);
		(bool sent,) = payable(labs[_labID].ownerOfLab).call{value: amount}("");
		
		if (sent){
		labs[_labID].fundsInLab += amount;
		}
	}

	modifier labOwner(uint256 _labID){
        // Project storage project = projects[_projectIndex];

        require(labs[_labID].ownerOfLab == msg.sender,"Sorry, only the owner of the project can withdraw the funds.");
         _;
    }

	function witdrawFunds(uint256 _labID) public payable labOwner(_labID){

		address owner = labs[_labID].ownerOfLab;
		uint256 amount = labs[_labID].fundsInLab;

		(bool sent,) = payable(owner).call{value: amount}("");

		if (sent){
		labs[_labID].fundsInLab = 0;
		}


	}



	fallback() external payable {}
    receive() external payable {}
}