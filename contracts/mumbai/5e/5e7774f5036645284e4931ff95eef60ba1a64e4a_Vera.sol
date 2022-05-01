/**
 *Submitted for verification at polygonscan.com on 2022-05-01
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
    mapping (address => mapping (uint => bool)) private verifierPermissions;
    modifier onlyVerifiers {
        require(verifierList[msg.sender] == true, "You have to be a government registered verifier to use this function");
        _;
    }

    function changeVerifierPermissions(address verifier, uint index, bool newVal) public onlyVera{
        verifierList[verifier] = true;
        verifierPermissions[verifier][index] = newVal;
    }

    function changeVerifierPermissionsMultiple(address verifier, uint[30] memory permissionBits) public onlyVera{
        verifierList[verifier] = true;
        for (uint i = 0 ; i < 30; i ++){
            verifierPermissions[verifier][i] = permissionBits[i] == 1 ? true : false;
        }
    }

    function revokeVerifier(address verifier) public onlyVera{
        verifierList[verifier] = false;
    }

    //outstanding pharmacy scripts with a validity status
    mapping (address => bytes) private pharmaScripts;

    //encrypted taxation information
    mapping (address => bytes) private taxesOutstanding;
    mapping (address => bytes) private taxesPaid;

    //encrypted identity information
    mapping (address => bytes) private name;
    mapping (address => bytes) private surname;
    mapping (address => bytes) private age;
    mapping (address => bytes) private nationality;
    mapping (address => bytes) private title;
    mapping (address => bytes) private gender;
    mapping (address => bytes) private licensesAndPassports;

    //encrypted bill information
    mapping (address => bytes) private waterBillInformation;
    mapping (address => bytes) private gasBillInformation;
    mapping (address => bytes) private internetBillInformation;
    mapping (address => bytes) private phoneBillInformation;

    //encrypted insurance information 
    mapping (address => bytes) private insuranceInformation;

    //encrypted transport information
    mapping (address => bytes) private metroBalance;
    mapping (address => bytes) private roadTollBalance;

    //encrypted welfare information;
    mapping (address => bytes) private allergies;
    mapping (address => bytes) private bloodType;
    mapping (address => bytes) private vitalConditions;

    //encrypted police records
    mapping (address => bytes) private policeRecords;

    //COVID vaccination report
    mapping (address => bytes) private COVIDReport;

    //Verification event
    event VeraVerification(bytes32 computedHash); 

    //registering a new Vera user
    function registerUser(address userAddress,
                          bytes memory encryptedName,
                          bytes memory encryptedSurname,
                          bytes memory encryptedAge,
                          bytes memory encryptedNationality,
                          bytes memory encryptedTitle,
                          bytes memory encryptedGender)
    public onlyVera{
        require(registeredVeraWallets[msg.sender]==false, "Vera wallet is already in use");
        name[userAddress] = encryptedName;
        surname[userAddress] = encryptedSurname;
        age[userAddress] = encryptedAge;
        nationality[userAddress] = encryptedNationality;
        title[userAddress] = encryptedTitle;
        gender[userAddress] = encryptedGender;
    }

    function addPharmacyScripts(address veraUser, bytes memory encryptedScript) public onlyVerifiers{
        require(verifierPermissions[msg.sender][5]==true && 
                verifierPermissions[msg.sender][8]==true && 
                verifierPermissions[msg.sender][13]==true && 
                verifierPermissions[msg.sender][15]==true, "Only pharmacists or doctors with required privileges are allowed to add pharamacy scripts");
        pharmaScripts[veraUser]= encryptedScript;
    }

    function addTaxationInformation(address veraUser, bytes memory encryptedTaxesPaidInfo, bytes memory encryptedTaxesOutstandingInfo) public onlyVerifiers{
        require(verifierPermissions[msg.sender][7]==true &&
                verifierPermissions[msg.sender][15]==true &&
                verifierPermissions[msg.sender][16]==true &&
                verifierPermissions[msg.sender][17]==true &&
                verifierPermissions[msg.sender][18]==true &&
                verifierPermissions[msg.sender][19]==true &&
                verifierPermissions[msg.sender][20]==true &&
                verifierPermissions[msg.sender][21]==true, "Only registered police and federal officers can ammend tax records"
                );
        taxesPaid[veraUser] = encryptedTaxesPaidInfo;
        taxesOutstanding[veraUser] = encryptedTaxesOutstandingInfo;
    }

    function addLicenceOrPassport(address veraUser, bytes memory encryptedLicenseInfo) public onlyVerifiers{
        require(verifierPermissions[msg.sender][7]==true &&
                verifierPermissions[msg.sender][15]==true &&
                verifierPermissions[msg.sender][16]==true &&
                verifierPermissions[msg.sender][17]==true &&
                verifierPermissions[msg.sender][18]==true &&
                verifierPermissions[msg.sender][19]==true &&
                verifierPermissions[msg.sender][20]==true &&
                verifierPermissions[msg.sender][21]==true, "Only registered police and federal officers can ammend license records"
                );
        licensesAndPassports[veraUser] = encryptedLicenseInfo;
    }

    function addInsuranceInformation(address veraUser, bytes memory encryptedInsuranceInfo) public onlyVerifiers{
        require(verifierPermissions[msg.sender][6]==true, "Only registered insurance agents can ammend license records"
                );
        insuranceInformation[veraUser] = encryptedInsuranceInfo;
    }

    function addBillInfo(address veraUser, bytes memory encryptedWaterBill, bytes memory encryptedGasBill, bytes memory encryptedInternetBill, bytes memory encryptedPhoneBill) public onlyVerifiers{
        require(verifierPermissions[msg.sender][0]==true && 
                verifierPermissions[msg.sender][1]==true &&
                verifierPermissions[msg.sender][2]==true &&
                verifierPermissions[msg.sender][3]==true, "Only registered utility agents can ammend bill information"
        );
        waterBillInformation[veraUser]       = encryptedWaterBill;
        gasBillInformation[veraUser]         = encryptedGasBill;
        internetBillInformation[veraUser]    = encryptedInternetBill;
        phoneBillInformation[veraUser]       = encryptedPhoneBill;
    }

    function addTransportInfo(address veraUser, bytes memory encryptedMetroBalance, bytes memory encryptedRoadTollBalance) public onlyVerifiers{
        require(verifierPermissions[msg.sender][11]==true && 
                verifierPermissions[msg.sender][12]==true, "Only registered transportation officers can ammend transportation credit information"
        );
        metroBalance[veraUser] = encryptedMetroBalance;
        roadTollBalance[veraUser] = encryptedRoadTollBalance;
    }

    function addWelfareBloodtype(address veraUser, bytes memory encryptedBloodType) public onlyVerifiers{
        require(verifierPermissions[msg.sender][4]==true && 
                verifierPermissions[msg.sender][5]==true &&
                verifierPermissions[msg.sender][13]==true &&
                verifierPermissions[msg.sender][14]==true &&
                verifierPermissions[msg.sender][15]==true &&
                verifierPermissions[msg.sender][17]==true &&
                verifierPermissions[msg.sender][18]==true &&
                verifierPermissions[msg.sender][19]==true &&
                verifierPermissions[msg.sender][20]==true &&
                verifierPermissions[msg.sender][21]==true, "Only registered doctors and paramedics can ammend welfare records"
        );
        bloodType[veraUser] = encryptedBloodType;
    }

    function addWelfareAllergy(address veraUser, bytes memory encryptedAllergyStatus) public onlyVerifiers{
        require(verifierPermissions[msg.sender][4]==true && 
                verifierPermissions[msg.sender][5]==true &&
                verifierPermissions[msg.sender][13]==true &&
                verifierPermissions[msg.sender][14]==true &&
                verifierPermissions[msg.sender][15]==true &&
                verifierPermissions[msg.sender][17]==true &&
                verifierPermissions[msg.sender][18]==true &&
                verifierPermissions[msg.sender][19]==true &&
                verifierPermissions[msg.sender][20]==true &&
                verifierPermissions[msg.sender][21]==true, "Only registered doctors and paramedics can ammend welfare records"
        );
        allergies[veraUser] = encryptedAllergyStatus;
    }

    function addWelfareVitalCondition(address veraUser, bytes memory encryptedVitalConditionStatus) public onlyVerifiers{
        require(verifierPermissions[msg.sender][4]==true && 
                verifierPermissions[msg.sender][5]==true &&
                verifierPermissions[msg.sender][13]==true &&
                verifierPermissions[msg.sender][14]==true &&
                verifierPermissions[msg.sender][15]==true &&
                verifierPermissions[msg.sender][17]==true &&
                verifierPermissions[msg.sender][18]==true &&
                verifierPermissions[msg.sender][19]==true &&
                verifierPermissions[msg.sender][20]==true &&
                verifierPermissions[msg.sender][21]==true, "Only registered doctors and paramedics can ammend welfare records"
        );
        vitalConditions[veraUser] = encryptedVitalConditionStatus;
    }

    function modifyPoliceRecords(address veraUser, bytes memory encryptedPoliceRecordInfo) public onlyVerifiers{
        require(verifierPermissions[msg.sender][7]==true &&
                verifierPermissions[msg.sender][15]==true &&
                verifierPermissions[msg.sender][16]==true &&
                verifierPermissions[msg.sender][17]==true &&
                verifierPermissions[msg.sender][18]==true &&
                verifierPermissions[msg.sender][19]==true &&
                verifierPermissions[msg.sender][20]==true &&
                verifierPermissions[msg.sender][21]==true, "Only registered police and federal officers can ammend license records"
        );
        policeRecords[veraUser] = encryptedPoliceRecordInfo;
    }

    function addCOVIDReport(address veraUser, bytes memory encryptedCOVIDReport) public onlyVerifiers{
        require(verifierPermissions[msg.sender][4]==true && 
                verifierPermissions[msg.sender][5]==true &&
                verifierPermissions[msg.sender][13]==true &&
                verifierPermissions[msg.sender][14]==true &&
                verifierPermissions[msg.sender][15]==true &&
                verifierPermissions[msg.sender][17]==true &&
                verifierPermissions[msg.sender][18]==true &&
                verifierPermissions[msg.sender][19]==true &&
                verifierPermissions[msg.sender][20]==true &&
                verifierPermissions[msg.sender][21]==true, "Only registered doctors and paramedics can ammend COVID reports"
        );
        COVIDReport[veraUser] = encryptedCOVIDReport;
    }

    function stringToBytes(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function substring(string memory str, uint startIndex, uint endIndex) public pure returns (string memory ) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }

function encryptDecryptBytes (bytes memory data, bytes memory key)
    public pure returns (bytes memory result) {
    // Store data length on stack for later use
    uint256 length = data.length;

    assembly {
        // Set result to free memory pointer
        result := mload (0x40)
        // Increase free memory pointer by lenght + 32
        mstore (0x40, add (add (result, length), 32))
        // Set result length
        mstore (result, length)
    }

    // Iterate over the data stepping by 32 bytes
    for (uint i = 0; i < length; i += 32) {
        // Generate hash of the key and offset
        bytes32 hash = keccak256 (abi.encodePacked (key, i));

        bytes32 chunk;
        assembly {
        // Read 32-bytes data chunk
        chunk := mload (add (data, add (i, 32)))
        }
        // XOR the chunk with hash
        chunk ^= hash;
        assembly {
        // Write 32-byte encrypted chunk
        mstore (add (result, add (i, 32)), chunk)
        }
    }
}

    function encryptStringToBytes(string memory source, bytes memory key) public pure returns(bytes memory){
        bytes memory sourceToBytes = abi.encodePacked(stringToBytes(source));
        bytes memory sourceToBytesEncrypted = encryptDecryptBytes(sourceToBytes, key);
        return sourceToBytesEncrypted;
    }

    function decryptBytesToString(bytes memory source, bytes memory key) public pure returns(string memory){
        bytes memory bytesDecrypted = encryptDecryptBytes(source, key);
        string memory result = bytesToString(bytesDecrypted);
        return result;
    }

    function bytesToString(bytes memory byteCode) public pure returns(string memory stringData){
        uint256 blank = 0; //blank 32 byte value
        uint256 length = byteCode.length;

        uint cycles = byteCode.length / 0x20;
        uint requiredAlloc = length;

        if (length % 0x20 > 0) //optimise copying the final part of the bytes - to avoid looping with single byte writes
        {
            cycles++;
            requiredAlloc += 0x20; //expand memory to allow end blank, so we don't smack the next stack entry
        }

        stringData = new string(requiredAlloc);

        //copy data in 32 byte blocks
        assembly {
            let cycle := 0

            for
            {
                let mc := add(stringData, 0x20) //pointer into bytes we're writing to
                let cc := add(byteCode, 0x20)   //pointer to where we're reading from
            } lt(cycle, cycles) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
                cycle := add(cycle, 0x01)
            } {
                mstore(mc, mload(cc))
            }
        }

        //finally blank final bytes and shrink size (part of the optimisation to avoid looping adding blank bytes1)
        if (length % 0x20 > 0)
        {
            uint offsetStart = 0x20 + length;
            assembly
            {
                let mc := add(stringData, offsetStart)
                mstore(mc, mload(add(blank, 0x20)))
                //now shrink the memory back so the returned object is the correct size
                mstore(stringData, length)
            }
        }
    }

    function append(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    function computeVerification(bytes memory key,
                                 address verifierAddress, 
                                 string memory timestamp, 
                                 string memory nonce) public  {
        //for ease of use
        address v = verifierAddress;
        require(verifierList[v] == true, "must be a valid verifier");
        //the address in different formats
        bytes memory vBytes = abi.encodePacked(v);
        string memory vString = bytesToString(vBytes);

    string memory result = "";
    if(verifierPermissions[v][0] && bytes(waterBillInformation[msg.sender]).length>0){
        string memory intermediateResult = decryptBytesToString(waterBillInformation[msg.sender], key);
        result = append(result, intermediateResult);
    }
    if(verifierPermissions[v][1] && bytes(gasBillInformation[msg.sender]).length>0){
        string memory intermediateResult = decryptBytesToString(gasBillInformation[msg.sender], key);
        result = append(result, intermediateResult);
    }
    if(verifierPermissions[v][2] && bytes(internetBillInformation[msg.sender]).length>0){
        string memory intermediateResult = decryptBytesToString(internetBillInformation[msg.sender], key);
        result = append(result, intermediateResult);
    }
    if(verifierPermissions[v][3] && bytes(phoneBillInformation[msg.sender]).length>0){
        string memory intermediateResult = decryptBytesToString(phoneBillInformation[msg.sender], key);
        result = append(result, intermediateResult);
    }
    if(verifierPermissions[v][4] && bytes(gender[msg.sender]).length>0){
        string memory intermediateResult = decryptBytesToString(gender[msg.sender], key);
        result = append(result, intermediateResult);    
    }
    if(verifierPermissions[v][5] && bytes(COVIDReport[msg.sender]).length>0){
        string memory intermediateResult = decryptBytesToString(COVIDReport[msg.sender], key);
        result = append(result, intermediateResult);
    }
    if(verifierPermissions[v][6] && bytes(insuranceInformation[msg.sender]).length>0){
        string memory intermediateResult = decryptBytesToString(insuranceInformation[msg.sender], key);
        result = append(result, intermediateResult);
    }
    if(verifierPermissions[v][7] && bytes(licensesAndPassports[msg.sender]).length>0){
        string memory intermediateResult = decryptBytesToString(licensesAndPassports[msg.sender], key);
        result = append(result, intermediateResult);
    }
    if(verifierPermissions[v][8] && bytes(pharmaScripts[msg.sender]).length>0){
        string memory intermediateResult = decryptBytesToString(pharmaScripts[msg.sender], key);
        result = append(result, intermediateResult);
    }
    if(verifierPermissions[v][9] && bytes(taxesPaid[msg.sender]).length>0){
        string memory intermediateResult = decryptBytesToString(taxesPaid[msg.sender], key);
        result = append(result, intermediateResult);
    }
    if(verifierPermissions[v][10] && bytes(taxesOutstanding[msg.sender]).length>0){
        string memory intermediateResult = decryptBytesToString(taxesOutstanding[msg.sender], key);
        result = append(result, intermediateResult);
    }
    if(verifierPermissions[v][11] && bytes(metroBalance[msg.sender]).length>0){
        string memory intermediateResult = decryptBytesToString(metroBalance[msg.sender], key);
        result = append(result, intermediateResult);
    }
    if(verifierPermissions[v][12] && bytes(roadTollBalance[msg.sender]).length>0){
        string memory intermediateResult = decryptBytesToString(roadTollBalance[msg.sender], key);
        result = append(result, intermediateResult);
    }
    if(verifierPermissions[v][13] && bytes(allergies[msg.sender]).length>0){
        string memory intermediateResult = decryptBytesToString(allergies[msg.sender], key);
        result = append(result, intermediateResult);
    }
    if(verifierPermissions[v][14] && bytes(bloodType[msg.sender]).length>0){
        string memory intermediateResult = decryptBytesToString(bloodType[msg.sender], key);
        result = append(result, intermediateResult);
    }
    if(verifierPermissions[v][15] && bytes(vitalConditions[msg.sender]).length>0){
        string memory intermediateResult = decryptBytesToString(vitalConditions[msg.sender], key);
        result = append(result, intermediateResult);
    }
    if(verifierPermissions[v][16] && bytes(policeRecords[msg.sender]).length>0){
        string memory intermediateResult = decryptBytesToString(policeRecords[msg.sender], key);
        result = append(result, intermediateResult);
    }
    if(verifierPermissions[v][17] && bytes(name[msg.sender]).length>0){
        string memory intermediateResult = decryptBytesToString(name[msg.sender], key);
        result = append(result, intermediateResult);
    }
    if(verifierPermissions[v][18] && bytes(surname[msg.sender]).length>0){
        string memory intermediateResult = decryptBytesToString(surname[msg.sender], key);
        result = append(result, intermediateResult);
    }
    if(verifierPermissions[v][19] && bytes(age[msg.sender]).length>0){
        string memory intermediateResult = decryptBytesToString(age[msg.sender], key);
        result = append(result, intermediateResult);
    }
    if(verifierPermissions[v][20] && bytes(nationality[msg.sender]).length>0){
        string memory intermediateResult = decryptBytesToString(nationality[msg.sender], key);
        result = append(result, intermediateResult);
    }
    if(verifierPermissions[v][21] && bytes(title[msg.sender]).length>0){
        string memory intermediateResult = decryptBytesToString(title[msg.sender], key);
        result = append(result, intermediateResult);
    }

    result = append(result, vString);
    result = append(result, timestamp);
    result = append(result, nonce);

    emit VeraVerification(keccak256(abi.encodePacked(result)));
    
    
    }
}