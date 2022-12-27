// SPDX-License-Identifier: MIT
/*
/$$      /$$                  /$$                  /$$$$$$                      /$$                    
|  $$   /$$/                 | $$                 /$$__  $$                    |__/                    
 \  $$ /$$//$$$$$$  /$$   /$$| $$  /$$$$$$       | $$  \ $$  /$$$$$$   /$$$$$$  /$$  /$$$$$$  /$$$$$$$ 
  \  $$$$//$$__  $$|  $$ /$$/| $$ /$$__  $$      | $$$$$$$$ /$$__  $$ /$$__  $$| $$ |____  $$| $$__  $$
   \  $$/| $$$$$$$$ \  $$$$/ | $$| $$$$$$$$      | $$__  $$| $$  \ $$| $$  \ $$| $$  /$$$$$$$| $$  \ $$
    | $$ | $$_____/  >$$  $$ | $$| $$_____/      | $$  | $$| $$  | $$| $$  | $$| $$ /$$__  $$| $$  | $$
    | $$ |  $$$$$$$ /$$/\  $$| $$|  $$$$$$$      | $$  | $$| $$$$$$$/| $$$$$$$/| $$|  $$$$$$$| $$  | $$
    |__/  \_______/|__/  \__/|__/ \_______/      |__/  |__/| $$____/ | $$____/ |__/ \_______/|__/  |__/
                                                           | $$      | $$                              
                                                           | $$      | $$                              
                                                           |__/      |__/                                                                                                                                                                   
*/
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import './UserContract.sol';

contract YexleAppian is ERC721Burnable, Ownable {

    /*
    It saves bytecode to revert on custom errors instead of using require
    statements. We are just declaring these errors for reverting with upon various
    conditions later in this contract. Thanks, Chiru Labs!
    */
    error URIQueryForNonexistentToken();    
    error zeroAddressNotSupported();
    error approverAlreadyExist();
    error NotAnAdmin();
    error NotOwnerOfID();
    error notApproverAddress();
    error alreadyApproved();
    error notL1Approver();
    error notL2Approver();
    error L1Rejected();
    error ownerRejectedTheOffer();
    error userContractError();
   
    address private userContract;
    address public L1Approver;
    address public L2Approver;
    string private contracturi;
    string public metadataUri;
    uint private l1Appovals;
    uint private l2Appovals;
    uint private totalLands;
    uint private completedRegistration;
    uint private totalLimit;
    bytes4 public constant IID_IERC721 = type(IERC721).interfaceId;
    
    event OwnershipTransferOfLand(address indexed from, address indexed to, uint indexed tokenId);
    event AccessGrantedToView(address indexed Viewer, uint indexed Token);
    event OwnershipGranted(address to);

    modifier onlyAdmin () {
    if (_msgSender() != owner() && !administrators[_msgSender()]) {
      revert NotAnAdmin();
    }
        _;
    }

    mapping ( address => bool ) private administrators;
    mapping(uint256 => string) private holdUri;
    mapping(uint256 => address) private _owners;
    mapping(address => bool) private approverAddress;
    mapping(uint => uint) private approvecount;
    mapping(address => mapping(uint => bool)) private voteRecord;
    mapping(uint => mapping(address => bool)) private approverDecision;
    mapping(uint => mapping(address => bool)) private landRequest;
    mapping(address => bool) private ownerAcceptLandSales;
    mapping(uint => bool) private saleStatus;
    mapping(uint => string) private registrationDocument;
    mapping(uint => bool) private registrationDocumentStatus;
    mapping(address => mapping(uint => bool)) private L1statusForRequester;
    mapping(address => mapping(uint => bool)) private viewAccessGranted;
    mapping(address => mapping(uint => bool)) private L2statusForRequester;
    mapping(address => mapping(uint => bool)) private L2statusForL1Approver;
    mapping(uint => bool) private L1approverDecision;
    mapping(uint => bool) private L2approverDecision;
    mapping(address => string[]) private allURI;
    mapping(uint => address[]) private allViewRequesterAddressToView;
    mapping(uint => uint) private noOfRequestsToViewLandDoc;
    mapping(uint => string) private recordUri;
    /**
        * If registrationProcess[tokenId] = false; // Then land is still in process.
        * If registrationProcess[tokenId] = true; // Then land registration is completed.
    */
    mapping(uint => bool) private registrationProcess;
    
    struct approverData{
        address _sellingTo;
        uint _tokenId;
        bool status;
    }

    struct approverDataForL2{
        address _previousOwner;
        address _sellingTo;
        uint _tokenId;
        bool status;
    }

    /**
        * constructor - ERC721 constructor
        * @param _metadata - base URI : https://ipfs.io/ipfs
    */
    constructor(string memory _metadata) ERC721("Yexele Appian", "Yexele_Land"){
        metadataUri = _metadata;
        totalLimit = 0;
        contracturi = "https://ipfs.io/ipfs/QmSf39izZ2iSHeXpSWKsfDEzqkEfHth6f8LuXdW1Ccge3B";
    }

    /**
        * whitelistApproverL1 - only admin can call this function and set an address as L1 Approver
        * @param _approverAd - address of L1 Approver
    */
    function whitelistApproverL1(address _approverAd) external onlyAdmin{
        if(_approverAd == address(0)){ revert zeroAddressNotSupported();}
        if(approverAddress[_approverAd] == true){revert approverAlreadyExist();}
        approverAddress[_approverAd] = true;
        L1Approver = _approverAd;
    }

    /**
        * whitelistApproverL2 - only admin can call this function and set an address as L2 Approver
        * @param _approverAd - address of L2 Approver
    */
    function whitelistApproverL2(address _approverAd) external onlyAdmin{
        if(_approverAd == address(0)){ revert zeroAddressNotSupported();}
        if(approverAddress[_approverAd] == true){revert approverAlreadyExist();}
        approverAddress[_approverAd] = true;
        L2Approver = _approverAd;
    }

    /**
        * whitelistUserContract - only admin can call this function and set an address as userContract address
         and connect this YexleAppian contract with userContract.
        * @param _userContractAd - address of already deployed userContract
    */
    function whitelistUserContract(address _userContractAd) external onlyAdmin{
        if(_userContractAd == address(0)){ revert zeroAddressNotSupported();}
        userContract = _userContractAd;
    }
   
    /**
        * setContractURI
        * This is sepcifically for setting royalty.
        * @param _contractURI manually set the contract uri json or ipfs hash 
        * When setting the contractURI, make sure it you input both baseuri + tokenuri
    */
    function setContractURI(string memory _contractURI) external onlyAdmin returns(bool){
        contracturi = _contractURI;
        return true;
    } 
     
    /**
        * mint - only admin can call this function and mint an ERC721 land token to a user with L1's approval.
        * @param l1Address - address of L1Approver
          @param _to - address of the user to whom the land belongs ERC721 land token will be minted to this address
          @param _tokenId - an integer ID which will represent the ERC721 land token.
          @param _tokenUri - CID hash that points to the documents that are related to the land.
        *
    */
    function mint(address l1Address, address _to, uint256 _tokenId, string memory _tokenUri) external onlyAdmin{
        UserContract useC = UserContract(userContract);
        (bool status) = useC.verifyUser(_to);
        if(!status){ revert userContractError();}
        if(l1Address == L1Approver){
            holdUri[_tokenId] = bytes(metadataUri).length != 0 ? string(abi.encodePacked(_tokenUri)) : '';
            _mint(_to, _tokenId);
            _owners[_tokenId] = _to;
            totalLands += 1;
            totalLimit = totalLimit + 1;
            string memory local = string(abi.encodePacked(metadataUri, holdUri[_tokenId]));
            allURI[_to].push(local);
            recordUri[_tokenId] = _tokenUri;
            emit OwnershipTransferOfLand(address(0), _to, _tokenId);
        }else{
            revert("Connected address does not have access to create land");
        } 
    }

    /**
        * This function sets the tokenURI if the token belongs to the address.
        * The token owner can set the tokenURI
        * @param _id The token id.
        * @param _tokenUri The token uri string.
    */
    function setTokenURI(uint256 _id, string memory _tokenUri) external {
        require(msg.sender == _owners[_id],"you are not the owner");
        holdUri[_id] = bytes(metadataUri).length != 0
        ? string(abi.encodePacked(_tokenUri))
        : '';
        string memory local = string(abi.encodePacked(metadataUri,holdUri[_id]));
        allURI[msg.sender].push(local);
    }

    /** 
        *landDocumentViewRequestApprove - only admin can call this function and allow a requesting user to view another user's 
           land documents
          @param l1Address - address of L1 approver
          @param _requester - address of the user requesting to view someone else's land document with intention of buying it
          @param tokenId - tokenID of the land documents which the requester is wishing to see
          @param _status - true or false. true if the admin grants access, false if admin doesn't grant access to requester.
        *
    */
    function landDocumentViewRequestApprove(address l1Address, address _requester, uint tokenId, bool _status) external onlyAdmin{
        UserContract useC = UserContract(userContract);
        (bool status) = useC.verifyUser(_requester);
        if(!status){ revert userContractError();}
        if(l1Address != L1Approver){ revert notL1Approver();}
        if(_status){
            viewAccessGranted[_requester][tokenId] = true;
            noOfRequestsToViewLandDoc[tokenId] += 1;
            allViewRequesterAddressToView[tokenId].push(_requester);
            emit AccessGrantedToView(_requester, tokenId);
        }else{
            viewAccessGranted[_requester][tokenId] = false;
        }
    }

    /**
        * requestLandForSale - this function can be called only by Admin. This sends a request from buyer to the land owner 
            expressing the buyer's wish to purchase the land.
        * @param _requester - this is the address of the buyer who wishes to buy a land.
        * @param _tokenId - this is the tokenId of the land documents collection that the buyer wishes to buy.
    */
    function requestLandForSale(address _requester, uint _tokenId) external onlyAdmin{
        UserContract useC = UserContract(userContract);
        (bool status) = useC.verifyUser(_requester);
        if(!status){ revert userContractError();}
        if(viewAccessGranted[_requester][_tokenId]){  // whoever willing to buy this land.
            landRequest[_tokenId][_requester] = true;
        }else{
            revert("You dont have access");
        }
    }
     
    /** 
        *ownerDecisionforRaisedRequest - this function can be called only by Admin. This function sets if the owner of the land 
           approves the buyer to purchase his land or not
        *@param oldOwner - address of the seller/owner of the land
        *@param _requester - address of the buyer
        *@param _tokenId - tokenId set to the land documents
        *@param _status - true or false status. true means the owner of the land approves the buyer to purchase his land. 
    */
    function ownerDecisionforRaisedRequest(address oldOwner, address _requester, uint _tokenId, bool _status) external onlyAdmin{
        UserContract useC = UserContract(userContract);
        (bool status) = useC.verifyUser(_requester);
        if(!status){ revert userContractError();}
        require(oldOwner == _owners[_tokenId],"you are not the owner of nft");
        if(viewAccessGranted[_requester][_tokenId] && landRequest[_tokenId][_requester] && _status){
            ownerAcceptLandSales[_requester]= _status;
            saleStatus[_tokenId] = true;
        }else{
            revert("Owner rejected the offer");
        }
    }

    /**
        *registrationForLandByBuyer - the buyer submits a request to register the land in his name
        *@param requester - buyer's address
        *@param tokenId - the tokenId of the land documents that buyer wishes to purchase
        *@param _DocumentUri - IPFS URI of the land documents that buyer wishes to purchase
    */
    function registrationForLandByBuyer(address requester, uint tokenId, string memory _DocumentUri) external onlyAdmin{
        require(ownerAcceptLandSales[requester] == true, "registration is not possible");
        require(saleStatus[tokenId] == true, "sale status is false");
        registrationDocument[tokenId] = _DocumentUri;
        registrationDocumentStatus[tokenId] = true;
    }


    /**
        *approveByL1 - L1 approver approves the sale first
        *@param l1Approver - L1 Approver's address
        *@param _data - a struct approverData containing _sellingTo, tokenId and status. sellingTo is address of the buyer, tokenId is
          the tokenId of the land documents and status is true or false status stating if L1 approver approves or not.
    */
    function approveByL1(address l1Approver, approverData memory _data) external onlyAdmin{
        UserContract useC = UserContract(userContract);
        (bool status) = useC.verifyUser(_data._sellingTo);
        if(!status){ revert userContractError();}
        if(l1Approver != L1Approver){ revert notL1Approver();}
        if(voteRecord[msg.sender][_data._tokenId]){ revert alreadyApproved();}
        if(registrationDocumentStatus[_data._tokenId] && _data.status == true){
            L1approverDecision[_data._tokenId] = _data.status;
            voteRecord[msg.sender][_data._tokenId] = true;
            L1statusForRequester[_data._sellingTo][_data._tokenId] = true;
            l1Appovals += 1;
            approvecount[_data._tokenId] += 1;
        }else{
            L1statusForRequester[_data._sellingTo][_data._tokenId] = false;
        }
    }

    /**
        *approveByL1 - L2 approver approves the sale after L1 approves it.
        *@param l2Approver - L2 Approver's address
        *@param _data - a struct approverDataforL2 containing _previousOwner which is seller address, _sellingTo which has 
         buyer address and status which is true or false status of L2Approver's approval.
    */ 
    function approveByL2(address l2Approver, approverDataForL2 memory _data) external onlyAdmin{
        UserContract useC = UserContract(userContract);
        (bool status) = useC.verifyUser(_data._sellingTo);
        if(!status){ revert userContractError();}
        if(l2Approver != L2Approver){ revert notL2Approver();}
        if(!L1approverDecision[_data._tokenId]){ revert L1Rejected();}
        if(_data.status == true){
            L2approverDecision[_data._tokenId] = _data.status;
            L2statusForRequester[_data._sellingTo][_data._tokenId] = _data.status;
            L2statusForL1Approver[_data._sellingTo][_data._tokenId] = _data.status;
            l2Appovals += 1;
            completedRegistration += 1;
            registrationProcess[_data._tokenId] = true; // Then land registration is completed.
            approvecount[_data._tokenId] += 1;
        }else{
            L2statusForRequester[_data._sellingTo][_data._tokenId] = _data.status;
            L2statusForL1Approver[_data._sellingTo][_data._tokenId] = _data.status;
        }
        if(approvecount[_data._tokenId] == 2 && L2approverDecision[_data._tokenId]){
            // The Owner of NFT needs to provide approve action to let L2 to change ownership
            transferFrom(_data._previousOwner, _data._sellingTo, _data._tokenId);
            string memory local = string(abi.encodePacked(metadataUri,recordUri[_data._tokenId]));
            allURI[_data._sellingTo].push(local);
            _owners[_data._tokenId] = _data._sellingTo;
            emit OwnershipTransferOfLand(_data._previousOwner, _data._sellingTo, _data._tokenId);
        }
    }

    /**
        * removeUri
        * @param index - Enter the index number and delete the array.
        * @param _ad - Enter the address of the landOwner.
    */
    function removeUri(uint256 index, address _ad) external onlyAdmin{
        if (index >= allURI[_ad].length) return;
        for (uint i = index; i < allURI[_ad].length - 1; i++) {
           allURI[_ad][i] = allURI[_ad][i+1];
        }
        allURI[_ad].pop();
    }
    
    
    // READ FUNCTIONS:
    /**
        *vidwDocumentByOwnerOrLevelApprovers - owner of the land, L1 and L2 approver, these people can view the land documents
        *@param _docViewRequester - address of the person who wishes to see the land document.
        *@param _tokenId - tokenId of the land documents
    */
    function viewDocumentByOwnerOrLevelApprovers(address _docViewRequester, uint _tokenId) external view returns(string memory DocumentUri){
        if(!_exists(_tokenId)) { revert URIQueryForNonexistentToken();}
        if(_docViewRequester == _owners[_tokenId] || _docViewRequester == L1Approver || _docViewRequester == L2Approver){
            return string(abi.encodePacked(metadataUri, holdUri[_tokenId]));
        }else{
            return "address is not owner of the land nft or view rights is not provided";
        }
    }


    // View Land Document: (Who ever got access by L1approver can view the doc).
    /**
        *vidwDocumentByOwnerOrLevelApprovers - owner of the land, L1 and L2 approver, these people can view the land documents
        *@param _requester - address of the person who wishes to see the land document.
        *@param _tokenId - tokenId of the land documents
    */
    function viewDocumentByRequesters(address _requester, uint _tokenId) external view returns(string memory DocumentURI){
        if(!_exists(_tokenId)) { revert URIQueryForNonexistentToken();}
        if(viewAccessGranted[_requester][_tokenId] && !saleStatus[_tokenId]){
            if (!_exists(_tokenId)) { revert URIQueryForNonexistentToken(); }
            return string(abi.encodePacked(metadataUri, holdUri[_tokenId]));
        }else{
            revert("View access is denied by L1Approver or The land is listed for sale");
        }
    }

    /**
        *LandRequesterStatus- All the buyer request can be checked using this read function
        *@param _requester - address of the person who wishes to see the land document.
        *@param _tokenId - tokenId of the land documents
    */
    function LandRequesterStatus(address _requester, uint _tokenId) 
    external 
    view 
    returns(bool ViewDocumentStatus, 
    bool L1ApproverStatusForRequester, 
    bool L2ApproverstatusForRequester, uint approveCountForTokenIdByApprovers){
        return (viewAccessGranted[_requester][_tokenId],
        L1statusForRequester[_requester][_tokenId], 
        L2statusForRequester[_requester][_tokenId], 
        approvecount[_tokenId]);
    }

    /**
        *L2ApproverStatusForL1Approver- L2 approver status can be checked by the L1 approver.
        *@param _requester - address of the person who wishes to see the land document.
        *@param _tokenId - tokenId of the land documents
    */
    function L2ApproverStatusForL1Approver(address _requester, uint _tokenId) external view returns(bool){
        return  L2statusForL1Approver[_requester][_tokenId];
    }

    /**
        * L1ApprovalCounts 
    */
    function L1ApprovalCounts() external view returns(uint totalL1ApprovalCounts){
        return l1Appovals;
    }

    /**
        * L2ApprovalCounts 
    */
    function L2ApprovalCounts() external view returns(uint totalL2ApprovalCounts){
        return l2Appovals;
    }

    /**
        * LandCounts 
    */
    function LandCounts() external view returns(uint totalLandCount){
        return totalLands;
    }

    /**
        * LandRegistrationStatus
    */
    function LandRegistrationStatus(uint _landId) external view returns(bool registrationStatus){
        return registrationProcess[_landId];
    }

    /**
        * CompletedRegistrations
    */
    function completedRegistrations() external view returns(uint totalCompletedRegistrations){
        return completedRegistration;
    }

    /**
        * noOfRequestersInfoToViewDoc 
        * @param tokenId - pass the unique ID which represents the land. created during minting the land NFT
    */
    function noOfRequestersInfoToViewDoc(uint tokenId) external view returns(uint allRequesterCount){
        return noOfRequestsToViewLandDoc[tokenId]; 
    }

    /**
        * returnAllUriForLandOwner
        * @param landOwnerAddress - Enter the land owner address 
    */
    function returnAllUriForLandOwner(address landOwnerAddress) external view returns(string[] memory returnallUris){
        return allURI[landOwnerAddress];
    }

    /**
        * allRequesterAddressForViewDocument.
        * @param _tokenId. 
    */
    function allRequesterAddressForViewDocument(uint _tokenId) external view returns(address[] memory allRequesters){
        return allViewRequesterAddressToView[_tokenId];
    }

    /**
        * supportsInterface
        * @param interfaceId Pass interfaceId, to let users know whether the ERC standard is used in this contract or not
    */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool){
        return interfaceId == IID_IERC721 || super.supportsInterface(interfaceId);
    }

    /**
        * contractURI()
        * Get the contract URI, which can be helpful for royalty setup with opensea. 
    */
    function contractURI() public view returns (string memory) {
        return contracturi;
    }

    /**
        * _baseURI - returns the base IPFS URI where the land documents are stored with their unique CID
     */
    function _baseURI() internal pure override returns (string memory) {
        return "https://ipfs.io/ipfs/";
    }
}

// SPDX-License-Identifier: MIT
/*
/$$      /$$                  /$$                  /$$$$$$                      /$$                    
|  $$   /$$/                 | $$                 /$$__  $$                    |__/                    
 \  $$ /$$//$$$$$$  /$$   /$$| $$  /$$$$$$       | $$  \ $$  /$$$$$$   /$$$$$$  /$$  /$$$$$$  /$$$$$$$ 
  \  $$$$//$$__  $$|  $$ /$$/| $$ /$$__  $$      | $$$$$$$$ /$$__  $$ /$$__  $$| $$ |____  $$| $$__  $$
   \  $$/| $$$$$$$$ \  $$$$/ | $$| $$$$$$$$      | $$__  $$| $$  \ $$| $$  \ $$| $$  /$$$$$$$| $$  \ $$
    | $$ | $$_____/  >$$  $$ | $$| $$_____/      | $$  | $$| $$  | $$| $$  | $$| $$ /$$__  $$| $$  | $$
    | $$ |  $$$$$$$ /$$/\  $$| $$|  $$$$$$$      | $$  | $$| $$$$$$$/| $$$$$$$/| $$|  $$$$$$$| $$  | $$
    |__/  \_______/|__/  \__/|__/ \_______/      |__/  |__/| $$____/ | $$____/ |__/ \_______/|__/  |__/
                                                           | $$      | $$                              
                                                           | $$      | $$                              
                                                           |__/      |__/                                                                                                                                                                   
*/

pragma solidity ^0.8.9;

contract UserContract{
    /*
        It saves bytecode to revert on custom errors instead of using require
        statements. We are just declaring these errors for reverting with upon various
        conditions later in this contract. Thanks, Chiru Labs!
    */
    error notAdmin();
    error addressAlreadyRegistered();
    error zeroAddressNotSupported();
    error adminAlreadyExist();
    error notL1Address();
    error approverAlreadyExist();
    error notOwner();
    
    address[] private pushUsers;
    address[] private adminAddresses;
    address public owner;
    address private L1Approver;
    uint private totalUsersCount;
    
    mapping(address => bool) private isUser;
    mapping(address => bool) private adminAddress;
    mapping(address => bool) private approverAddress;

    struct userBulkData{
        address _ad;
    }

    struct userAdd{
        address _l1;
        address _ad;
    }

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner,"you are not the admin");
        _;
    }

    /**
        *  whitelistApproverL1
        * @param _approverAd - Enter the L1 approver address to the smart contract.
    */
    function whitelistApproverL1(address _approverAd) external onlyOwner{
        if(_approverAd == address(0)){ revert zeroAddressNotSupported();}
        if(approverAddress[_approverAd] == true){revert approverAlreadyExist();}
        approverAddress[_approverAd] = true;
        L1Approver = _approverAd;
    }
    
    /**
        *  addUser
        * @param _data - Admin has the access to enter the user address to the blockchain.
    */
    function addUser(userAdd memory _data) external onlyOwner{
        if(_data._l1 != L1Approver){ revert notL1Address();}
        if(isUser[_data._ad] == true){ revert addressAlreadyRegistered();}
        isUser[_data._ad] = true;
        totalUsersCount += 1;
        pushUsers.push(_data._ad);
    }

    /**
        * addUserBulk
        * @param _userData - Enter the user data (address and type) as array format.
    */
    function addUserBulk(address l1Address, userBulkData[] memory _userData) external onlyOwner{
        if(l1Address != L1Approver){ revert notL1Address();}
        for(uint i = 0; i < _userData.length; i++){
            if(isUser[_userData[i]._ad] == true){ revert addressAlreadyRegistered();}
            isUser[_userData[i]._ad] = true;
            totalUsersCount += 1;
            pushUsers.push(_userData[i]._ad);
        }
    }

    /**
        * addUserBulk1.
        * @param l1Address - Enter the Level 1 approver address.
        * @param _userData - Enter the array of user addresses.
    */
    function addUserBulk1(address l1Address, address[] memory _userData) external onlyOwner{
        if(l1Address != L1Approver){ revert notL1Address();}
        for(uint i = 0; i < _userData.length; i++){
            if(isUser[_userData[i]] == true){ revert addressAlreadyRegistered();}
            isUser[_userData[i]] = true;
            totalUsersCount += 1;
            pushUsers.push(_userData[i]);
        }
    }

    /**
        * verifyUser
        * @param _ad - Enter the address, to know about the role
    */
    function verifyUser(address _ad) external view returns(bool){
        if(isUser[_ad]){
            return true;
        }else{
            return false;
        }
    }

    /**
        * getAllUserAddress
        * outputs all the entered user address from the blockchain.
    */
    function getAllUserAddress() external view returns(address[] memory){
        return pushUsers;
    }   

    /**
        * L1ApproverAddress
        * Get the L1 approver address. 
    */
    function L1ApproverAddress() external view returns(address){
        return L1Approver;
    }

    /**
        * UserCounts  
    */ 
    function UserCounts() external view returns(uint totalCountOfUsers){
        return totalUsersCount;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}