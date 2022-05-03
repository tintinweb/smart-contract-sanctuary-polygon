/**
 *Submitted for verification at polygonscan.com on 2022-05-02
*/

/*

 __     __  ________  _______    ______             ______           
/  |   /  |/        |/       \  /      \          _/      \_         
$$ |   $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |        / $$$$$$   \        
$$ |   $$ |$$ |__    $$ |__$$ |$$ |__$$ |       /$$$ ___$$$  \       
$$  \ /$$/ $$    |   $$    $$< $$    $$ |      /$$/ /     $$  |      
 $$  /$$/  $$$$$/    $$$$$$$  |$$$$$$$$ |      $$ |/$$$$$ |$$ |      
  $$ $$/   $$ |_____ $$ |  $$ |$$ |  $$ |      $$ |$$  $$ |$$ |      
   $$$/    $$       |$$ |  $$ |$$ |  $$ |      $$ |$$  $$  $$/       
    $/     $$$$$$$$/ $$/   $$/ $$/   $$/       $$  \$$$$$$$$/        
                                                $$   \__/   |        
                                                 $$$    $$$/         
                                                   $$$$$$/           
         
 __    __  __    __        __       __  ______  _______  
/  |  /  |/  \  /  |      /  |  _  /  |/      |/       \ 
$$ |  $$ |$$  \ $$ |      $$ | / \ $$ |$$$$$$/ $$$$$$$  |
$$ |  $$ |$$$  \$$ |      $$ |/$  \$$ |  $$ |  $$ |  $$ |
$$ |  $$ |$$$$  $$ |      $$ /$$$  $$ |  $$ |  $$ |  $$ |
$$ |  $$ |$$ $$ $$ |      $$ $$/$$ $$ |  $$ |  $$ |  $$ |
$$ \__$$ |$$ |$$$$ |      $$$$/  $$$$ | _$$ |_ $$ |__$$ |
$$    $$/ $$ | $$$ |      $$$/    $$$ |/ $$   |$$    $$/ 
 $$$$$$/  $$/   $$/       $$/      $$/ $$$$$$/ $$$$$$$/  
                                                                                                            
 __    __                      __                    __      __                           
/  |  /  |                    /  |                  /  |    /  |                          
$$ |  $$ |  ______    _______ $$ |   __   ______   _$$ |_   $$ |____    ______   _______  
$$ |__$$ | /      \  /       |$$ |  /  | /      \ / $$   |  $$      \  /      \ /       \ 
$$    $$ | $$$$$$  |/$$$$$$$/ $$ |_/$$/  $$$$$$  |$$$$$$/   $$$$$$$  |/$$$$$$  |$$$$$$$  |
$$$$$$$$ | /    $$ |$$ |      $$   $$<   /    $$ |  $$ | __ $$ |  $$ |$$ |  $$ |$$ |  $$ |
$$ |  $$ |/$$$$$$$ |$$ \_____ $$$$$$  \ /$$$$$$$ |  $$ |/  |$$ |  $$ |$$ \__$$ |$$ |  $$ |
$$ |  $$ |$$    $$ |$$       |$$ | $$  |$$    $$ |  $$  $$/ $$ |  $$ |$$    $$/ $$ |  $$ |
$$/   $$/  $$$$$$$/  $$$$$$$/ $$/   $$/  $$$$$$$/    $$$$/  $$/   $$/  $$$$$$/  $$/   $$/ 
                                                                                                                                                                                                                                                                

*/

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.0 <0.9.0;

/**
 *  Dear Audience, we are team Vera and before you is the code we have created for our prototype solution to the challenge
 *  under the theme "Blockchain For Good". The Vera contract serves to be a rather simplified illustration of how sensitive 
 *  data of day-to-day citizens in modern cities can be stored on the blockchain with no privacy leaks. By hosting it on an
 *  efficient L2 Ethereum-Virtual-Machine such as the Polygon Network, it is also important to highlight that such a solut-
 *  ion is exceptionally fast/cheap/easy to use, especially with the advent of 5G and modern devices making the internet a
 *  practically ubiquitous utility. As such, a smart contract akin to Vera will be all but universally accessible in the 
 *  future at lightning speeds from nearly all devices. Registered government officials, police and federal officers, para-
 *  medics, cashiers, bankers, insurance agents, pharmacists, security guards, utility company agents, transport officers, 
 *  taxation officers, amongst countless of myriad other occupations will be able to leverage a contract such as Vera to 
 *  its full power by being able to query whether users' data on-chain matches their expectations: for example, this can be
 *  a taxation officer ensuring that all outstanding taxes of a citizen are paid, or a pharamacist ensuring that the script
 *  for medicine is legitimate, or even toll gates quering a smart device for a user balance in terms of metro credits, 
 *  amongst a sea of other potential applications. At each step of the way, data will always be encrypted, with only the 
 *  results of the required checks, should the requestor have the permissions to access such data, returned to the request-
 *  or in encrypted form they can verify if the user chooses to submits the verification to the blockchain. We are aware 
 *  of a small number of simplifications that result in privacy leaks in our prototype, however we would like to highlight
 *  that ZKP solutions such as those available on the Polygon Network, albeit immensely complex, can render such a vision
 *  into reality - those were avoided due to their immense sophistication and time constraints. We would also like to high-
 *  light that by hosting the Vera front-end portal through IPFS, Vera's uptime and attacks such as DNS cache poisoning, 
 *  amongst countless others such as DDoS attacks become more or less futile. Lastly, we would like to note that we have
 *  explicitly references a good amount of data by the users' addresses in plaintext, but this could have easily been 
 *  obfuscated to be in encrypted form, which we have avoided doing for simplicity of understanding and for simplicity of 
 *  use. 
**/
contract Vera {

    //Vera developers addresess for privileged access operations such as registering users 
    //by government officials for the first time, etc.
    mapping (address => bool) private veraDeveloperAccess;

    //mapping of registered users to determine if they have been registered priorly
    mapping (address => bool) private registeredVeraWallets;

    //checking access for privileged functions only Vera developers (such as government officials) are allowed to access
    modifier onlyVera {
        require(veraDeveloperAccess[msg.sender]);
        _;
    }

    //switching the privilege level for any given Vera developer - for instance to remove a retired Vera dev's access
    function switchDeveloperAccess(address a, bool b) public onlyVera{
        veraDeveloperAccess[a] = b;
    }

    //registering the first Vera developer with the contract constructor as the first privileged user 
    constructor() {
        veraDeveloperAccess[msg.sender] = true;
    }

    //approved list of verifiers - these are police officers, transportation officers/booths, cashiers, etc. 
    mapping (address => bool) private verifierList;

    //their access to users' data will be dependent upon the roles they have - for instance police officers will of course 
    //be able to access more sensitive information than say cashiers
    mapping (address => mapping (uint => bool)) private verifierPermissions;


    //this is a Solidity modifier to prevent standard non-verifier users form being able to call privileged functions
    modifier onlyVerifiers {
        require(verifierList[msg.sender] == true, "You have to be a government registered verifier to use this function");
        _;
    }

    //this function serves as a safeguard for Vera developers/government officials to be able to change any verifiers' 
    //permissions for a specific field, it also ensures the vierifer is registered
    function changeVerifierPermissions(address verifier, uint index, bool newVal) public onlyVera{
        verifierList[verifier] = true;
        verifierPermissions[verifier][index] = newVal;
    }

    //this function serves the same purpose as the above, however, all permissions relevant to some verifier
    //are set in one go in this function at once
    function changeVerifierPermissionsMultiple(address verifier, uint[30] memory permissionBits) public onlyVera{
        verifierList[verifier] = true;
        for (uint i = 0 ; i < 30; i ++){
            verifierPermissions[verifier][i] = permissionBits[i] == 1 ? true : false;
        }
    }

    //this function immediately revokes a verifier independent of which permission bits they may retain
    function revokeVerifier(address verifier) public onlyVera{
        verifierList[verifier] = false;
    }

    //outstanding pharmacy scripts for any given Vera user's address
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

    //encrypted utility bill information
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

    //encrypted COVID vaccination report
    mapping (address => bytes) private COVIDReport;

    //Verification event emited to the blockchain by the verifying party for the verifier
    event VeraVerification(bytes32 computedHash); 

    //registering a new Vera user - onboarding with base identity by Vera developers
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

    //adding/modifying pharmacy scripts by a verifier with the appropriate privileges 
    function addPharmacyScripts(address veraUser, bytes memory encryptedScript) public onlyVerifiers{
        require(verifierPermissions[msg.sender][5]==true && 
                verifierPermissions[msg.sender][8]==true && 
                verifierPermissions[msg.sender][13]==true && 
                verifierPermissions[msg.sender][15]==true, 
                "Only pharmacists or doctors with required privileges are allowed to add pharamacy scripts");
        pharmaScripts[veraUser]= encryptedScript;
    }

    //adding/modifying taxation information by a verifier with the appropriate privileges 
    function addTaxationInformation(address veraUser, bytes memory encryptedTaxesPaidInfo, 
    bytes memory encryptedTaxesOutstandingInfo) public onlyVerifiers{
        require(verifierPermissions[msg.sender][7]==true &&
                verifierPermissions[msg.sender][15]==true &&
                verifierPermissions[msg.sender][16]==true &&
                verifierPermissions[msg.sender][17]==true &&
                verifierPermissions[msg.sender][18]==true &&
                verifierPermissions[msg.sender][19]==true &&
                verifierPermissions[msg.sender][20]==true &&
                verifierPermissions[msg.sender][21]==true, 
                "Only registered police and federal officers can ammend tax records"
                );
        taxesPaid[veraUser] = encryptedTaxesPaidInfo;
        taxesOutstanding[veraUser] = encryptedTaxesOutstandingInfo;
    }

    //adding/modifying license/passport information by a verifier with the appropriate privileges 
    function addLicenceOrPassport(address veraUser, bytes memory encryptedLicenseInfo) 
    public onlyVerifiers{
        require(verifierPermissions[msg.sender][7]==true &&
                verifierPermissions[msg.sender][15]==true &&
                verifierPermissions[msg.sender][16]==true &&
                verifierPermissions[msg.sender][17]==true &&
                verifierPermissions[msg.sender][18]==true &&
                verifierPermissions[msg.sender][19]==true &&
                verifierPermissions[msg.sender][20]==true &&
                verifierPermissions[msg.sender][21]==true, 
                "Only registered police and federal officers can ammend license records"
                );
        licensesAndPassports[veraUser] = encryptedLicenseInfo;
    }

    //adding/modifying insurance information by a verifier with the appropriate privileges 
    function addInsuranceInformation(address veraUser, bytes memory encryptedInsuranceInfo) 
    public onlyVerifiers{
        require(verifierPermissions[msg.sender][6]==true, 
        "Only registered insurance agents can ammend license records"
                );
        insuranceInformation[veraUser] = encryptedInsuranceInfo;
    }

    //adding/modifying utility bill information by a verifier with the appropriate privileges 
    function addBillInfo(address veraUser, bytes memory encryptedWaterBill,
                         bytes memory encryptedGasBill, 
                         bytes memory encryptedInternetBill, 
                         bytes memory encryptedPhoneBill) public onlyVerifiers{
        require(verifierPermissions[msg.sender][0]==true && 
                verifierPermissions[msg.sender][1]==true &&
                verifierPermissions[msg.sender][2]==true &&
                verifierPermissions[msg.sender][3]==true, 
                "Only registered utility agents can ammend bill information"
        );
        waterBillInformation[veraUser]       = encryptedWaterBill;
        gasBillInformation[veraUser]         = encryptedGasBill;
        internetBillInformation[veraUser]    = encryptedInternetBill;
        phoneBillInformation[veraUser]       = encryptedPhoneBill;
    }

    //adding/modifying transportation information/credits by a verifier with the appropriate privileges 
    function addTransportInfo(address veraUser, bytes memory encryptedMetroBalance, 
                              bytes memory encryptedRoadTollBalance) public onlyVerifiers{
        require(verifierPermissions[msg.sender][11]==true && 
                verifierPermissions[msg.sender][12]==true, 
                "Only registered transportation officers can ammend transportation credit information"
        );
        metroBalance[veraUser] = encryptedMetroBalance;
        roadTollBalance[veraUser] = encryptedRoadTollBalance;
    }

    //adding/modifying blood type by a verifier with the appropriate privileges 
    function addWelfareBloodtype(address veraUser, bytes memory encryptedBloodType) 
    public onlyVerifiers{
        require(verifierPermissions[msg.sender][4]==true && 
                verifierPermissions[msg.sender][5]==true &&
                verifierPermissions[msg.sender][13]==true &&
                verifierPermissions[msg.sender][14]==true &&
                verifierPermissions[msg.sender][15]==true &&
                verifierPermissions[msg.sender][17]==true &&
                verifierPermissions[msg.sender][18]==true &&
                verifierPermissions[msg.sender][19]==true &&
                verifierPermissions[msg.sender][20]==true &&
                verifierPermissions[msg.sender][21]==true, 
                "Only registered doctors and paramedics can ammend welfare records"
        );
        bloodType[veraUser] = encryptedBloodType;
    }

    //adding/modifying allergy information by a verifier with the appropriate privileges 
    function addWelfareAllergy(address veraUser, bytes memory encryptedAllergyStatus) 
    public onlyVerifiers{
        require(verifierPermissions[msg.sender][4]==true && 
                verifierPermissions[msg.sender][5]==true &&
                verifierPermissions[msg.sender][13]==true &&
                verifierPermissions[msg.sender][14]==true &&
                verifierPermissions[msg.sender][15]==true &&
                verifierPermissions[msg.sender][17]==true &&
                verifierPermissions[msg.sender][18]==true &&
                verifierPermissions[msg.sender][19]==true &&
                verifierPermissions[msg.sender][20]==true &&
                verifierPermissions[msg.sender][21]==true, 
                "Only registered doctors and paramedics can ammend welfare records"
        );
        allergies[veraUser] = encryptedAllergyStatus;
    }

    //adding/modifying vital condition information by a verifier with the appropriate privileges 
    function addWelfareVitalCondition(address veraUser, bytes memory encryptedVitalConditionStatus) 
    public onlyVerifiers{
        require(verifierPermissions[msg.sender][4]==true && 
                verifierPermissions[msg.sender][5]==true &&
                verifierPermissions[msg.sender][13]==true &&
                verifierPermissions[msg.sender][14]==true &&
                verifierPermissions[msg.sender][15]==true &&
                verifierPermissions[msg.sender][17]==true &&
                verifierPermissions[msg.sender][18]==true &&
                verifierPermissions[msg.sender][19]==true &&
                verifierPermissions[msg.sender][20]==true &&
                verifierPermissions[msg.sender][21]==true, 
                "Only registered doctors and paramedics can ammend welfare records"
        );
        vitalConditions[veraUser] = encryptedVitalConditionStatus;
    }

    //adding/modifying police record information by a police or federal officer
    function modifyPoliceRecords(address veraUser, bytes memory encryptedPoliceRecordInfo) 
    public onlyVerifiers{
        require(verifierPermissions[msg.sender][7]==true &&
                verifierPermissions[msg.sender][15]==true &&
                verifierPermissions[msg.sender][16]==true &&
                verifierPermissions[msg.sender][17]==true &&
                verifierPermissions[msg.sender][18]==true &&
                verifierPermissions[msg.sender][19]==true &&
                verifierPermissions[msg.sender][20]==true &&
                verifierPermissions[msg.sender][21]==true, 
                "Only registered police and federal officers can ammend license records"
        );
        policeRecords[veraUser] = encryptedPoliceRecordInfo;
    }

    //adding/modifying COVID information by a verifier with the appropriate privileges 
    function addCOVIDReport(address veraUser, bytes memory encryptedCOVIDReport) 
    public onlyVerifiers{
        require(verifierPermissions[msg.sender][4]==true && 
                verifierPermissions[msg.sender][5]==true &&
                verifierPermissions[msg.sender][13]==true &&
                verifierPermissions[msg.sender][14]==true &&
                verifierPermissions[msg.sender][15]==true &&
                verifierPermissions[msg.sender][17]==true &&
                verifierPermissions[msg.sender][18]==true &&
                verifierPermissions[msg.sender][19]==true &&
                verifierPermissions[msg.sender][20]==true &&
                verifierPermissions[msg.sender][21]==true, 
                "Only registered doctors and paramedics can ammend COVID reports"
        );
        COVIDReport[veraUser] = encryptedCOVIDReport;
    }

    //a function to convert a string to a bytes32 object
    //please note - we are well aware of strings being sometimes far longer than 32 characters
    //this could have easily been implemented with a bytes mapping or array, however for the
    //purposes of our prototype 32 characters for each field of information more than sufficed :)
    function stringToBytes(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
    }

    //a function to ocnvert a bytes32 object to a string
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

    //a helper function to return the substring of a given string
    function substring(string memory str, uint startIndex, uint endIndex) public pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }

    //a function to encrypt a set of bytes with a given key in the form of bytes
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

    //convert a string to bytes and encrypt the bytes with the key passed
    function encryptStringToBytes(string memory source, bytes memory key) public pure returns(bytes memory){
        bytes memory sourceToBytes = abi.encodePacked(stringToBytes(source));
        bytes memory sourceToBytesEncrypted = encryptDecryptBytes(sourceToBytes, key);
        return sourceToBytesEncrypted;
    }

    //decrypt passed bytes with the key passed and convert to string
    function decryptBytesToString(bytes memory source, bytes memory key) public pure returns(string memory){
        bytes memory bytesDecrypted = encryptDecryptBytes(source, key);
        string memory result = bytesToString(bytesDecrypted);
        return result;
    }

    //convert bytes object to its string representation
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

    //a helper function to concatenate two strings a and b
    function append(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    //a function to compute the verification of the requested data parameters for a verifier along with
    //the passed timestamp and nonce
    //
    //please note - we are aware that while we reveal only data on an as-needed basis, it could also have
    //been further obfuscated by means of merely returning the boolean result of some given check; hopefully
    //it is clear that that is a rather trivial extension we have avoided as we are merely demonstrating 
    //that only certain verifiers are allowed to verify certain data. we are also aware that the timestamp,
    //verifier address, and nonce could be encrypted in an ideal scenario with the use of ZKP, but these are
    //immensely complicated extensions with highly involved algorithms we have not utilized due to time 
    //constraints, as we have mentioned before 
    function computeVerification(bytes memory key,
                                 address verifierAddress, 
                                 string memory timestamp, 
                                 string memory nonce) public  {
        //for ease of use, v = verifierAddress :)
        address v = verifierAddress;
        require(verifierList[v] == true, "must be a valid verifier");
        //the address in different formats (bytes, string)
        bytes memory vBytes = abi.encodePacked(v);
        string memory vString = bytesToString(vBytes);

    //this variable will house all the concatenated data that the verifier is allowed to see
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

    //compute the verification and emit event to the blockchain for public to see
    emit VeraVerification(keccak256(abi.encodePacked(result)));
    }
}