/**
 *Submitted for verification at polygonscan.com on 2022-09-16
*/

// File: Eighteen.sol


pragma solidity 0.8.16;


interface IPUSHCommInterface {
    function sendNotification(address _channel, address _recipient, bytes calldata _identity) external;
}

contract Eighteen{

    address payable owner;
    address nullAddress;
    uint nOfValidators;
    uint nOfTranslators;
    uint nOfRequests; 
    uint nOfPendingTranslators;
    uint voteId;
    uint fee=2500000000000000;
    uint [] languages= [1,2,3];

    mapping(address=>Translator) public findTranslator;
    mapping(address=> PendingTranslator) public findPendingTranslator;
    mapping(uint=>Request) public findRequest;
    mapping(uint=>Vote) public findVote;
    mapping(address=>mapping(uint=>bool)) public hasWorked;
    mapping(address=>mapping(uint=>bool)) public hasApproved;
    mapping(address=>mapping(uint=>bool)) public hasDenied;
    mapping(address=>mapping(uint=>bool)) public hasCollected;
    mapping(address=>mapping(uint=>bool)) public isFluent;


    struct Translator{
        address translator;
        uint translatorId;
        uint nOfLanguages;
        uint nOfRequests;
        bool validator;
    }

    struct PendingTranslator{
        address translator;
        uint pendingTranslatorId;
        uint lang1;
        uint lang2;
        uint nOfRequests;
        uint approvals;
        uint denials;
        bool rejected;
    }

    struct Vote{
        uint voteId;
        Translator translator;
        uint yes;
        uint no;
        bool rejected;
    }

    struct Request{
        uint requestId;
        uint amount;
        string description;
        address client;
        address translator;
        uint docLang;
        uint langNeeded;
        bool accepted;
        uint approvals;
        uint denials;
        uint stage;
    }

        event NewTranslationRequest(uint requestId, uint docLang, uint langNeeded);
        event TranslatorAcceptedRequest(uint requestId, address indexed translator);
        event TranslationSubmitted(uint requestId);
        event TranslationApproved(uint requestId, address indexed Validator);
        event TranslationDenied(uint requestId, address indexed Validator);
        event RequestClosed(uint requestId);
        event NewPendingTranslator(address indexed translator, uint lang1, uint lang2);
        event NewTranslator(address indexed translator);
        event NewApplicationForValidator(address indexed translator);
        event NewLanguage(uint languageId, string language);

    constructor() payable{
        owner=payable(msg.sender);
    }


    function applyForTranslatorRole(uint lang1, uint lang2) external {
        require(findPendingTranslator[msg.sender].pendingTranslatorId==0);
        nOfPendingTranslators+=1;
        PendingTranslator memory newPendingtranslator;
        newPendingtranslator= PendingTranslator(msg.sender, nOfPendingTranslators, lang1, lang2, 0,0,0, false);
        findPendingTranslator[msg.sender]=newPendingtranslator;

        IPUSHCommInterface(0xb3971BCef2D791bc4027BbfedFb47319A4AAaaAa).sendNotification( //Careful it is Polygon!!!
        0x99F270c37478aDEFaaccCdCc173f86d96C267bdb, // from channel - once contract is deployed, go back and add the contract address as delegate for your channel
        address(this), // to recipient, put address(this) in case you want Broadcast or Subset. For Targetted put the address to which you want to send
        bytes(
            string(abi.encodePacked(
                "0", // this is notification identity
                "+", // segregator
                "1", // this is payload type: (1, 3 or 4) = (Broadcast, targetted or subset)
                "+", // segregator
                "New applicant for translator role", // this is notificaiton title
                "+", // segregator
                "The more the better" // notification body
                )
            )
        )
);

        emit NewPendingTranslator(msg.sender, lang1, lang2);
    }

    function voteTranslator(address pendingTrans, bool vote) external onlyValidator{
        require(findPendingTranslator[pendingTrans].nOfRequests>2, "Translator doesn't have enough Requests");
        require(findTranslator[pendingTrans].translatorId==0, "Role already granted");
        
        if(vote==true){
             findPendingTranslator[pendingTrans].approvals+=1;
            if(findPendingTranslator[pendingTrans].approvals>2){
                addTranslator(pendingTrans);
            }
        }else{
            findPendingTranslator[pendingTrans].denials+=1;
            if(findPendingTranslator[pendingTrans].denials>2){
                findPendingTranslator[pendingTrans].rejected=true;
            }
        }
    }

    function addTranslator(address addr) private {
        nOfTranslators+=1;
        Translator memory newTranslator;
        newTranslator=Translator(addr, nOfTranslators, 2, 0, false);
        findTranslator[addr]=newTranslator;

        isFluent[addr][findPendingTranslator[addr].lang1]=true;
        isFluent[addr][findPendingTranslator[addr].lang2]=true;
    
        emit NewTranslator(addr);
    }

    function applyForValidatorRole() external onlyTranslator {
        require(findTranslator[msg.sender].validator==false, "Role already granted");
        require(findTranslator[msg.sender].nOfRequests>4, "You don't have enough Requests");

        voteId++;
        Vote memory newVote;
        newVote=Vote(voteId,findTranslator[msg.sender], 0, 0, false);
        emit NewApplicationForValidator(msg.sender);
    }

    function voteValidator(uint _voteId, bool vote) external onlyValidator{
        require(findVote[_voteId].rejected==false, "Vote has already been rejected");
        
        if(vote==true){
            findVote[_voteId].yes++;
            if(findVote[_voteId].yes >2){
                addValidator(_voteId);
            }
        }else{
            findVote[_voteId].no++;
            if(findVote[_voteId].no >2){
                findVote[_voteId].rejected=true;
            }
        }
    }

    function addValidator(uint _voteId) private{
        findTranslator[findVote[_voteId].translator.translator].validator=true;
    }


    function requestTranslation(string calldata _IPFS, uint docLang, uint langNeeded) external payable{
        require(msg.value>10000000000000000, "You must deposit at least 0.01 Matic");

        nOfRequests+=1;
        Request memory newRequest;

        newRequest=Request(nOfRequests, msg.value-fee, _IPFS, msg.sender,nullAddress, docLang, langNeeded, false, 0, 0, 1);
        findRequest[nOfRequests]=newRequest;

        emit NewTranslationRequest(nOfRequests, docLang, langNeeded);

    }

    function giveTestTranslation(address pendingTrans, string calldata _IPFS, uint docLang, uint langNeeded) external onlyValidator{
        require(findPendingTranslator[pendingTrans].pendingTranslatorId>0, "Not a pending translator");
        nOfRequests+=1;
        Request memory newTest;

        newTest=Request(nOfRequests, 0, _IPFS, nullAddress, pendingTrans, docLang, langNeeded, true, 0, 0, 2);
        findRequest[nOfRequests]=newTest;
    }

    function acceptTranslation(uint requestId) external onlyTranslator{
        findRequest[requestId].accepted=true;
        findRequest[requestId].translator=msg.sender;
        findRequest[requestId].stage=2;
        emit TranslatorAcceptedRequest(requestId, msg.sender);
    }

    function submitTranslation(uint requestId, string calldata _IPFS) external {
        require(findRequest[requestId].translator==msg.sender, "This is not your request");
        require(findRequest[requestId].stage==2, "This function is not available");
 
            findRequest[requestId].stage=3;
            emit TranslationSubmitted(requestId);
        

        IPUSHCommInterface(0xb3971BCef2D791bc4027BbfedFb47319A4AAaaAa).sendNotification( //Careful it is Polygon!!!
        0x99F270c37478aDEFaaccCdCc173f86d96C267bdb, // from channel - once contract is deployed, go back and add the contract address as delegate for your channel
        address(this), // to recipient, put address(this) in case you want Broadcast or Subset. For Targetted put the address to which you want to send
        bytes(
            string(abi.encodePacked(
                "0", // this is notification identity
                "+", // segregator
                "1", // this is payload type: (1, 3 or 4) = (Broadcast, targetted or subset)
                "+", // segregator
                "New applicant for translator role", // this is notificaiton title
                "+", // segregator
                _IPFS // notification body
                )
            )
            )
        );
    }

    function ApproveTranslation(uint requestId) external onlyValidator {
        require(findRequest[requestId].stage==3, "This function is not available");
        
            hasApproved[msg.sender][requestId]=true;
            findRequest[requestId].approvals+=1;
            emit TranslationApproved(requestId, msg.sender);
        
            if(findRequest[requestId].approvals>1){ //Chaneg for test
                findRequest[requestId].stage=4;
                emit RequestClosed(requestId);
            }
    }

    function denyTranslation(uint requestId) external onlyValidator {
        require(findRequest[requestId].stage==3, "This function is not available");

        hasDenied[msg.sender][requestId]=true;
        findRequest[requestId].denials+=1;
       emit TranslationDenied(requestId, msg.sender);
    
        if(findRequest[requestId].denials>1){ //Chaneg for test
            findRequest[requestId].stage=5;
            emit RequestClosed(requestId);
        }
    }

    function recollectFunds(uint requestId) external hasNotCollected(requestId){
        require(findRequest[requestId].stage==5, "This function is not available");
        require(findRequest[requestId].client==msg.sender,"This is not your Request");

        hasCollected[msg.sender][requestId]=true ;
        uint amount=findRequest[requestId].amount;
        (bool sent, ) = payable(msg.sender).call{value:amount}("");
        require(sent, "Failed to send back funds");
        
    }

    function collectRequest(uint requestId) external hasNotCollected(requestId){
        require(findRequest[requestId].stage==4, "This function is not available");
        require(findRequest[requestId].translator==msg.sender, "You have not worked on this request");

        hasCollected[msg.sender][requestId]=true;
        findPendingTranslator[findRequest[requestId].translator].nOfRequests+=1;
    }

    function getPaidAfterApproval (uint requestId) external hasNotCollected(requestId){
        require(findRequest[requestId].stage==4, "This function is not available");
        require(hasApproved[msg.sender][requestId]==true, "You have not validated this request" );

        hasCollected[msg.sender][requestId]=true ;
        address payable validator=payable(msg.sender);
        (bool sent1, ) =validator.call{value:fee}("");
        require(sent1, "Failed to pay validating Validator");
    }

    function getPaidAfterDenial (uint requestId)external hasNotCollected(requestId){
        require(findRequest[requestId].stage==5, "This function is not available");
        require(hasDenied[msg.sender][requestId]==true, "You have not denied this request");

        hasCollected[msg.sender][requestId]=true ;
        address payable validator=payable(msg.sender);
        (bool sent1, ) =validator.call{value:fee}("");
        require(sent1, "Failed to pay validating Validator");
    }

    function getPaidTranslator(uint requestId) external hasNotCollected(requestId) onlyTranslator{
        require(findRequest[requestId].stage==4, "This function is not available");
        require(findRequest[requestId].translator==msg.sender, "You have not worked on this request");

        hasCollected[msg.sender][requestId]=true ;
        (bool sent3, )=payable(msg.sender).call{value:fee}("");
        require(sent3, "Failed to pat translator");
    }

    function addLanguage(string memory language) external onlyOwner{

        languages.push(languages.length+1);
        emit NewLanguage(languages.length, language);
    }

    function addFluency(address addr, uint languageId) external onlyOwner{
        require(findTranslator[addr].translatorId>0, "Address is not a translator");
        require(isFluent[addr][languageId]==false, "Already fluent");

        isFluent[addr][languageId]=true;
        findTranslator[addr].nOfLanguages++;
    }

    function deposit() external payable onlyOwner{}

    function withdraw() external onlyOwner{
        uint amount1=address(this).balance;

        (bool success2, )= owner.call{value: amount1}("");
        require(success2, "Failed to withdraw funds" );
    }
  
    function changeRequest(
        uint requestId,
        uint denials,
        uint approvals,
        uint _stage) external{
        findRequest[requestId].requestId=requestId;
        findRequest[requestId].stage=_stage;
        findRequest[requestId].client=msg.sender;
        findRequest[requestId].translator=msg.sender;
        findRequest[requestId].amount=3000000;
        findRequest[requestId].docLang=1;
        findRequest[requestId].langNeeded=2;
        findRequest[requestId].approvals=approvals;
        findRequest[requestId].denials=denials;
    }

    function changeRole(address addr, uint id, uint n, bool validator) public {
        findTranslator[addr].translator=addr;
        findTranslator[addr].translatorId=id;
        findTranslator[addr].nOfRequests=n;
        findTranslator[addr].validator=validator;
        
    }

    function changeVotes(address addr, address translator, uint id, uint yes, uint no, uint n, bool finish) public{
        findVote[voteId].voteId=id;
        findVote[voteId].yes=yes;
        findVote[voteId].no=no;
        findVote[voteId].translator.translator=addr;
        findVote[voteId].rejected= finish;
        findTranslator[translator].nOfRequests=n;
    }


    function changePendingRole(address addr, uint id, uint yes, uint no, uint n) public {
        findPendingTranslator[addr].pendingTranslatorId=id;
        findPendingTranslator[addr].denials=no;
        findPendingTranslator[addr].approvals=yes;
        findPendingTranslator[addr].translator=addr;
        findPendingTranslator[addr].nOfRequests=n;
    }

    modifier onlyOwner() {
        require (msg.sender == owner, "You are not the Owner");
        _;
    }

    modifier onlyValidator() {
        require(findTranslator[msg.sender].validator==true, "You are not a Validator");
        _;
    }

    modifier onlyTranslator() {
        require(findTranslator[msg.sender].translatorId>0, "You are not a Translator");
        _;
    }

    modifier hasNotCollected(uint requestId){
        require(hasCollected[msg.sender][requestId]==false, "You have already used this function");
     _;
    }

}