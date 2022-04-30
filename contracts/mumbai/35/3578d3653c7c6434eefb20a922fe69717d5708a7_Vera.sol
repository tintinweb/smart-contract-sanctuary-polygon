/**
 *Submitted for verification at polygonscan.com on 2022-04-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Vera
 */
contract Vera {

    //Vera developers for privileged access operations such as registering users by government officials for the first time, etc.
    mapping (address => bool) private veraDeveloperAccess;

    //mapping of registered users
    mapping (address => bool) private registeredVeraWallets;

    //checking access for privileged functions only Vera developers are allowed to access
    modifier onlyVera {
        require(veraDeveloperAccess[msg.sender]);
        _;
    }

    //switching the privilege level for any given Vera developer
    function switchDeveloperAccess(address a, bool b) public onlyVera{
        veraDeveloperAccess[a] = b;
    }


    //registering the first Vera developer with the contract constructor
    constructor() {
        veraDeveloperAccess[msg.sender] = true;
    }

    //approved verifier list with permission bits
    mapping (address => bool) private verifierList;
    mapping (address => uint[20]) private verifierPermissions;
    modifier onlyVerifiers {
        require(verifierList[msg.sender] == true, "You have to be a government registered verifier to use this function");
        _;
    }

    function changeVerifierPermissions(address verifier, uint[20] memory permissionBits) public onlyVera{
        verifierList[verifier] = true;
        verifierPermissions[verifier] = permissionBits;
    }

    function revokeVerifier(address verifier) public onlyVera{
        verifierList[verifier] = false;
    }

    //outstanding pharmacy scripts with a validity status
    mapping (address => mapping (string => bool)) private pharmaScripts;

    //encrypted taxation information
    mapping (address => string) private taxesOutstanding;
    mapping (address => string) private taxesPaid;

    //encrypted identity information
    mapping (address => string) private name;
    mapping (address => string) private surname;
    mapping (address => string) private age;
    mapping (address => string) private nationality;
    mapping (address => string) private title;
    mapping (address => string) private gender;
    mapping (address => mapping (string => string))  private licensesAndPassports;

    //encrypted bill information
    mapping (address => string) private waterBillInformation;
    mapping (address => string) private gasBillInformation;
    mapping (address => string) private internetBillInformation;
    mapping (address => string) private phoneBillInformation;

    //encrypted insurance information 
    mapping (address => mapping (string => string)) private insuranceInformation;

    //encrypted transport information
    mapping (address => string) private metroBalance;
    mapping (address => string) private roadTollBalance;

    //encrypted welfare information;
    mapping (address => mapping (string => string)) private allergies;
    mapping (address => string) private bloodType;
    mapping (address => mapping (string => string)) private vitalConditions;

    //encrypted police records
    mapping (address => string) private policeRecords;

    //COVID vaccination report
    mapping (address => string) private COVIDReport;

    //registering a new Vera user
    function registerUser(address userAddress,
                          string memory encryptedName,
                          string memory encryptedSurname,
                          string memory encryptedAge,
                          string memory encryptedNationality,
                          string memory encryptedTitle,
                          string memory encryptedGender)
    public onlyVera{
        require(registeredVeraWallets[msg.sender]==false, "Vera wallet is already in use");
        name[userAddress] = encryptedName;
        surname[userAddress] = encryptedSurname;
        age[userAddress] = encryptedAge;
        nationality[userAddress] = encryptedNationality;
        title[userAddress] = encryptedTitle;
        gender[userAddress] = encryptedGender;
    }

    function addPharmacyScripts(address veraUser, string memory encryptedScript) public onlyVerifiers{
        pharmaScripts[veraUser][encryptedScript] = true;
    }

    function addTaxationInformation(address veraUser, string memory encryptedTaxesPaidInfo, string memory encryptedTaxesOutstandingInfo) public onlyVerifiers{
        taxesPaid[veraUser] = encryptedTaxesPaidInfo;
        taxesOutstanding[veraUser] = encryptedTaxesOutstandingInfo;
    }

    function addLicenceOrPassport(address veraUser, string memory encryptedLicenseType, string memory encryptedLicenseInfo) public onlyVerifiers{
        licensesAndPassports[veraUser][encryptedLicenseType] = encryptedLicenseInfo;
    }

    function addInsuranceInformation(address veraUser, string memory encryptedInsuranceType, string memory encryptedInsuranceInfo) public onlyVerifiers{
        insuranceInformation[veraUser][encryptedInsuranceType] = encryptedInsuranceInfo;
    }

    function addBillInfo(address veraUser, string memory encryptedWaterBill, string memory encryptedGasBill, string memory encryptedInternetBill, string memory encryptedPhoneBill) public onlyVerifiers{
        waterBillInformation[veraUser]       = encryptedWaterBill;
        gasBillInformation[veraUser]         = encryptedGasBill;
        internetBillInformation[veraUser]    = encryptedInternetBill;
        phoneBillInformation[veraUser]       = encryptedPhoneBill;
    }

    function addTransportInfo(address veraUser, string memory encryptedMetroBalance, string memory encryptedRoadTollBalance) public onlyVerifiers{
        metroBalance[veraUser] = encryptedMetroBalance;
        roadTollBalance[veraUser] = encryptedRoadTollBalance;
    }

    function addWelfareBloodtype(address veraUser, string memory encryptedBloodType) public onlyVerifiers{
        bloodType[veraUser] = encryptedBloodType;
    }

    function addWelfareAllergy(address veraUser, string memory encryptedAllergy, string memory encryptedAllergyStatus) public onlyVerifiers{
        allergies[veraUser][encryptedAllergy] = encryptedAllergyStatus;
    }

    function addWelfareVitalCondition(address veraUser, string memory encryptedVitalCondition, string memory encryptedVitalConditionStatus) public onlyVerifiers{
        vitalConditions[veraUser][encryptedVitalCondition] = encryptedVitalConditionStatus;
    }

    function modifyPoliceRecords(address veraUser, string memory encryptedPoliceRecordInfo) public onlyVerifiers{
        policeRecords[veraUser] = encryptedPoliceRecordInfo;
    }

    function addCOVIDReport(address veraUser, string memory encryptedCOVIDReport) public onlyVerifiers{
        COVIDReport[veraUser] = encryptedCOVIDReport;
    }


}