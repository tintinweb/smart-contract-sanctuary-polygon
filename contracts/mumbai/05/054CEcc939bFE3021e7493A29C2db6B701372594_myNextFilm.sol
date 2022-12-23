// SPDX-License-Identifier: MIT 

pragma solidity 0.8.7;
import "./Ownable.sol";
contract myNextFilm is Ownable{
    struct subscription{
        string subscriptionStartTime;
        string subscriptionEndTime;
    }
    mapping(bytes32 => bytes) public onePager;
    mapping(bytes32 => bytes) public story;
    mapping(bytes32 => bytes) public sampleScript;
    mapping(bytes32 => bytes) public fullScript;
    mapping(bytes32 => bytes) public footage; 
    mapping(bytes32 => bytes) public pitchDeck;
    mapping(bytes32 => bytes) public sampleNarration;
    mapping(bytes32 => bytes) public fullNarration;
    mapping(bytes32 => bytes) public scriptAnalysis;
    mapping(bytes32 => bytes) public characterIntroduction;
    mapping(bytes32 => bytes[2]) public pptConvert;
    mapping(bytes32 => bytes[2]) public storyConvert;
    mapping(bytes32 => bytes[2]) public bookConvert;
    mapping(bytes32 => bytes[2]) public scriptConvert;
    mapping(bytes32 => bytes) public pitchDeckConvert;
    mapping(bytes32 => bytes) public viewerLoungeVideo;
    mapping(bytes32 => bytes) public viewerLoungeLink;
    mapping(bytes32 => bytes) public scriptPad;
    mapping(bytes32 => bytes) public previewChamber;
    mapping(bytes32 => bytes) public projectCenter;
    mapping(bytes32 => subscription) public subscribe;    

    mapping(string =>mapping(string => mapping(uint => bool))) public uploadFileStatus;  

    event uploadDetails(string indexed uploaderName, string indexed fileName, uint indexed timeOfUpload);          
    function createOnePager(bytes32 _onePagerCombine, bytes memory _uri,string memory _userName, string memory _fileName, uint _timeOfUpload) public {
        onePager[_onePagerCombine] = _uri;
        uploadFileStatus[_userName][_fileName][_timeOfUpload] = true;
        emit uploadDetails(_userName, _fileName, _timeOfUpload);
    }
   
    function createStory(bytes32 _storyCombine, bytes memory _uri,string memory _userName, string memory _fileName, uint _timeOfUpload) public {
        story[_storyCombine] = _uri;
        uploadFileStatus[_userName][_fileName][_timeOfUpload] = true;
        emit uploadDetails(_userName, _fileName, _timeOfUpload);
    }

    function createSampleScript(bytes32 _combineSampleScript, bytes memory _uri,string memory _userName, string memory _fileName, uint _timeOfUpload) public {
        sampleScript[_combineSampleScript] = _uri;
        uploadFileStatus[_userName][_fileName][_timeOfUpload] = true;
        emit uploadDetails(_userName, _fileName, _timeOfUpload);
    }

    function createFullScript(bytes32 _combineFullScript, bytes memory _uri,string memory _userName, string memory _fileName, uint _timeOfUpload) public {
        fullScript[_combineFullScript] = _uri;
        uploadFileStatus[_userName][_fileName][_timeOfUpload] = true;
        emit uploadDetails(_userName, _fileName, _timeOfUpload);
    }

    function createFootage(bytes32 _combineFootage, bytes memory _uri,string memory _userName, string memory _fileName, uint _timeOfUpload) public {
        footage[_combineFootage] = _uri;
        uploadFileStatus[_userName][_fileName][_timeOfUpload] = true;
        emit uploadDetails(_userName, _fileName, _timeOfUpload);
    }

    function createPitchDeck(bytes32 _combinePitchDeck, bytes memory _uri,string memory _userName, string memory _fileName, uint _timeOfUpload) public {
        pitchDeck[_combinePitchDeck] = _uri;
        uploadFileStatus[_userName][_fileName][_timeOfUpload] = true;
        emit uploadDetails(_userName, _fileName, _timeOfUpload);
    }
    
    function createSampleNarration(bytes32 _combineSampleNarration, bytes memory _uri,string memory _userName, string memory _fileName, uint _timeOfUpload) public {
        sampleNarration[_combineSampleNarration] = _uri;
        uploadFileStatus[_userName][_fileName][_timeOfUpload] = true;
        emit uploadDetails(_userName, _fileName, _timeOfUpload);
    }    

    function createFullNarration(bytes32 _combineFullNarration, bytes memory _uri,string memory _userName, string memory _fileName, uint _timeOfUpload) public {
        fullNarration[_combineFullNarration] = _uri;
        uploadFileStatus[_userName][_fileName][_timeOfUpload] = true;
        emit uploadDetails(_userName, _fileName, _timeOfUpload);
    }

    function createScriptAnalysis(bytes32 _combineScriptAnalysis, bytes memory _uri,string memory _userName, string memory _fileName, uint _timeOfUpload) public {
        scriptAnalysis[_combineScriptAnalysis] = _uri;
        uploadFileStatus[_userName][_fileName][_timeOfUpload] = true;
        emit uploadDetails(_userName, _fileName, _timeOfUpload);
    }   

    function createCharacterIntro(bytes32 _combineCharacterIntro, bytes memory _uri,string memory _userName, string memory _fileName, uint _timeOfUpload) public {
        characterIntroduction[_combineCharacterIntro] = _uri;
        uploadFileStatus[_userName][_fileName][_timeOfUpload] = true;
        emit uploadDetails(_userName, _fileName, _timeOfUpload);
    }   
    function createPPTconversion(bytes32 _pptCombine, bytes[2] memory _uri,string memory _userName, string memory _fileName, uint _timeOfUpload) public {
        pptConvert[_pptCombine][0] = _uri[0];
        pptConvert[_pptCombine][1] = _uri[1];
        uploadFileStatus[_userName][_fileName][_timeOfUpload] = true;
        emit uploadDetails(_userName, _fileName, _timeOfUpload);
    }      

    function createStoryConversion(bytes32 _storyCombine, bytes[2] memory _uri,string memory _userName, string memory _fileName, uint _timeOfUpload) public {
        storyConvert[_storyCombine][0] = _uri[0];
        storyConvert[_storyCombine][1] = _uri[1];
        uploadFileStatus[_userName][_fileName][_timeOfUpload] = true;
        emit uploadDetails(_userName, _fileName, _timeOfUpload);
    }      

    function createBookConversion(bytes32 _bookCombine, bytes[2] memory _uri,string memory _userName, string memory _fileName, uint _timeOfUpload) public {
        bookConvert[_bookCombine][0] = _uri[0];
        bookConvert[_bookCombine][1] = _uri[1];        
        uploadFileStatus[_userName][_fileName][_timeOfUpload] = true;
        emit uploadDetails(_userName, _fileName, _timeOfUpload);
    }

    function createScriptConversion(bytes32 _scriptCombine, bytes[2] memory _uri,string memory _userName, string memory _fileName, uint _timeOfUpload) public {
        scriptConvert[_scriptCombine][0] = _uri[0];
        scriptConvert[_scriptCombine][1] = _uri[1];        
        uploadFileStatus[_userName][_fileName][_timeOfUpload] = true;
        emit uploadDetails(_userName, _fileName, _timeOfUpload);
    }    

    function createPitchDeckConversion(bytes32 _pitchDeckCombine, bytes memory _uri,string memory _userName, string memory _fileName, uint _timeOfUpload) public {
        pitchDeckConvert[_pitchDeckCombine] = _uri;        
        uploadFileStatus[_userName][_fileName][_timeOfUpload] = true;
        emit uploadDetails(_userName, _fileName, _timeOfUpload);
    }   

    function createViewerLoungeForVideo(bytes32 _viewerLoungeVideoCombine, bytes memory _uri,string memory _userName, string memory _fileName, uint _timeOfUpload) public {
        viewerLoungeVideo[_viewerLoungeVideoCombine] = _uri;        
        uploadFileStatus[_userName][_fileName][_timeOfUpload] = true;
        emit uploadDetails(_userName, _fileName, _timeOfUpload);
    } 
        
    function createviewerLoungeForLink(bytes32 _viewerLoungeLinkCombine, bytes memory _uri,string memory _userName, string memory _fileName, uint _timeOfUpload) public {
        viewerLoungeLink[_viewerLoungeLinkCombine] = _uri;        
        uploadFileStatus[_userName][_fileName][_timeOfUpload] = true;
        emit uploadDetails(_userName, _fileName, _timeOfUpload);
    }

    function createScriptPad(bytes32 _scriptPadCombine, bytes memory _uri,string memory _userName, string memory _fileName, uint _timeOfUpload) public {
        scriptPad[_scriptPadCombine] = _uri;        
        uploadFileStatus[_userName][_fileName][_timeOfUpload] = true;
        emit uploadDetails(_userName, _fileName, _timeOfUpload);
    } 

    function createPreviewChamber(bytes32 _previewChamberCombine, bytes memory _uri,string memory _userName, string memory _fileName, uint _timeOfUpload) public {
        previewChamber[_previewChamberCombine] = _uri;        
        uploadFileStatus[_userName][_fileName][_timeOfUpload] = true;
        emit uploadDetails(_userName, _fileName, _timeOfUpload);
    } 

    function createProjectCenter(bytes32 _projectCenterCombine, bytes memory _uri,string memory _userName, string memory _fileName, uint _timeOfUpload) public {
        projectCenter[_projectCenterCombine] = _uri;        
        uploadFileStatus[_userName][_fileName][_timeOfUpload] = true;
        emit uploadDetails(_userName, _fileName, _timeOfUpload);
    } 
    
    function createSubscription(bytes32 _subscriptionCombine, string memory startDate, string memory endDate,string memory _userName, string memory _fileName, uint _timeOfUpload) public {
        subscription memory sub = subscribe[_subscriptionCombine];
        sub.subscriptionStartTime = startDate;
        sub.subscriptionEndTime = endDate;
        subscribe[_subscriptionCombine] = sub;
        uploadFileStatus[_userName][_fileName][_timeOfUpload] = true;
        emit uploadDetails(_userName, _fileName, _timeOfUpload);
    } 
      
    function showOnePager(string memory _email,string memory _previewName, uint _timeStamp) public view returns (bytes memory){
        bytes32 _encryptedEmail = keccak256(abi.encodePacked(_email));
        bytes32 _encryptedPreview = keccak256(abi.encodePacked(_previewName));
        bytes32 _combine = keccak256(abi.encodePacked(_encryptedEmail,_encryptedPreview,_timeStamp));
        return onePager[_combine];
    }

    function remove() public {
        require(msg.sender == owner(), "msg.sender is not the owner");
        selfdestruct(payable(owner()));
    }
    
    function showStory(string memory _email,string memory _previewName, uint _timeStamp) public view returns (bytes memory){
        bytes32 _encryptedEmail = keccak256(abi.encodePacked(_email));
        bytes32 _encryptedPreview = keccak256(abi.encodePacked(_previewName));
        bytes32 _combine = keccak256(abi.encodePacked(_encryptedEmail,_encryptedPreview,_timeStamp));
        return story[_combine];
    }

    function showSampleScript(string memory _email,string memory _previewName, uint _timeStamp) public view returns (bytes memory){
        bytes32 _encryptedEmail = keccak256(abi.encodePacked(_email));
        bytes32 _encryptedPreview = keccak256(abi.encodePacked(_previewName));
        bytes32 _combine = keccak256(abi.encodePacked(_encryptedEmail,_encryptedPreview,_timeStamp));
        return sampleScript[_combine];
    }

    function showFullScript(string memory _email,string memory _previewName, uint _timeStamp) public view returns (bytes memory){
        bytes32 _encryptedEmail = keccak256(abi.encodePacked(_email));
        bytes32 _encryptedPreview = keccak256(abi.encodePacked(_previewName));
        bytes32 _combine = keccak256(abi.encodePacked(_encryptedEmail,_encryptedPreview,_timeStamp));
        return fullScript[_combine];
    }

    function showFootage(string memory _email,string memory _previewName, uint _timeStamp) public view returns (bytes memory){
        bytes32 _encryptedEmail = keccak256(abi.encodePacked(_email));
        bytes32 _encryptedPreview = keccak256(abi.encodePacked(_previewName));
        bytes32 _combine = keccak256(abi.encodePacked(_encryptedEmail,_encryptedPreview,_timeStamp));
        return footage[_combine];
    }

    function showPitchDeck(string memory _email,string memory _previewName, uint _timeStamp) public view returns (bytes memory){
        bytes32 _encryptedEmail = keccak256(abi.encodePacked(_email));
        bytes32 _encryptedPreview = keccak256(abi.encodePacked(_previewName));
        bytes32 _combine = keccak256(abi.encodePacked(_encryptedEmail,_encryptedPreview,_timeStamp));
        return pitchDeck[_combine];
    }

    function showSampleNarration(string memory _email,string memory _previewName, uint _timeStamp) public view returns (bytes memory){
        bytes32 _encryptedEmail = keccak256(abi.encodePacked(_email));
        bytes32 _encryptedPreview = keccak256(abi.encodePacked(_previewName));
        bytes32 _combine = keccak256(abi.encodePacked(_encryptedEmail,_encryptedPreview,_timeStamp));
        return sampleNarration[_combine];
    }

    function showFullNarration(string memory _email,string memory _previewName, uint _timeStamp) public view returns (bytes memory){
        bytes32 _encryptedEmail = keccak256(abi.encodePacked(_email));
        bytes32 _encryptedPreview = keccak256(abi.encodePacked(_previewName));
        bytes32 _combine = keccak256(abi.encodePacked(_encryptedEmail,_encryptedPreview,_timeStamp));
        return fullNarration[_combine];
    }

    function showScriptAnalysis(string memory _email,string memory _previewName, uint _timeStamp) public view returns (bytes memory){
        bytes32 _encryptedEmail = keccak256(abi.encodePacked(_email));
        bytes32 _encryptedPreview = keccak256(abi.encodePacked(_previewName));
        bytes32 _combine = keccak256(abi.encodePacked(_encryptedEmail,_encryptedPreview,_timeStamp));
        return scriptAnalysis[_combine];
    }

    function showCharacterIntro(string memory _email,string memory _previewName, uint _timeStamp) public view returns (bytes memory){
        bytes32 _encryptedEmail = keccak256(abi.encodePacked(_email));
        bytes32 _encryptedPreview = keccak256(abi.encodePacked(_previewName));
        bytes32 _combine = keccak256(abi.encodePacked(_encryptedEmail,_encryptedPreview,_timeStamp));
        return characterIntroduction[_combine];
    }
    
    function showPPTconvert(string memory _email,string memory _previewName, uint _timeStamp) public view returns (bytes[2] memory){
        bytes32 _encryptedEmail = keccak256(abi.encodePacked(_email));
        bytes32 _encryptedPreview = keccak256(abi.encodePacked(_previewName));
        bytes32 _combine = keccak256(abi.encodePacked(_encryptedEmail,_encryptedPreview,_timeStamp));
        return pptConvert[_combine];
    }

    function showStoryConvert(string memory _email,string memory _previewName, uint _timeStamp) public view returns (bytes[2] memory){
        bytes32 _encryptedEmail = keccak256(abi.encodePacked(_email));
        bytes32 _encryptedPreview = keccak256(abi.encodePacked(_previewName));
        bytes32 _combine = keccak256(abi.encodePacked(_encryptedEmail,_encryptedPreview,_timeStamp));
        return storyConvert[_combine];
    }

    function showBookConvert(string memory _email,string memory _previewName, uint _timeStamp) public view returns (bytes[2] memory){
        bytes32 _encryptedEmail = keccak256(abi.encodePacked(_email));
        bytes32 _encryptedPreview = keccak256(abi.encodePacked(_previewName));
        bytes32 _combine = keccak256(abi.encodePacked(_encryptedEmail,_encryptedPreview,_timeStamp));
        return bookConvert[_combine];
    }

    function showScriptConvert(string memory _email,string memory _previewName, uint _timeStamp) public view returns (bytes[2] memory){
        bytes32 _encryptedEmail = keccak256(abi.encodePacked(_email));
        bytes32 _encryptedPreview = keccak256(abi.encodePacked(_previewName));
        bytes32 _combine = keccak256(abi.encodePacked(_encryptedEmail,_encryptedPreview,_timeStamp));
        return scriptConvert[_combine];
    }

    function showPitchDeckConvert(string memory _email,string memory _previewName, uint _timeStamp) public view returns (bytes memory){
        bytes32 _encryptedEmail = keccak256(abi.encodePacked(_email));
        bytes32 _encryptedPreview = keccak256(abi.encodePacked(_previewName));
        bytes32 _combine = keccak256(abi.encodePacked(_encryptedEmail,_encryptedPreview,_timeStamp));
        return pitchDeckConvert[_combine];
    } 

    function showViewerLoungeVideo(string memory _email,string memory _previewName, uint _timeStamp) public view returns (bytes memory){
        bytes32 _encryptedEmail = keccak256(abi.encodePacked(_email));
        bytes32 _encryptedPreview = keccak256(abi.encodePacked(_previewName));
        bytes32 _combine = keccak256(abi.encodePacked(_encryptedEmail,_encryptedPreview,_timeStamp));
        return viewerLoungeVideo[_combine];
    }

    function showViewerLoungeLink(string memory _email,string memory _previewName, uint _timeStamp) public view returns (bytes memory){
        bytes32 _encryptedEmail = keccak256(abi.encodePacked(_email));
        bytes32 _encryptedPreview = keccak256(abi.encodePacked(_previewName));
        bytes32 _combine = keccak256(abi.encodePacked(_encryptedEmail,_encryptedPreview,_timeStamp));
        return viewerLoungeLink[_combine];
    }
     
     function showScriptPad(string memory _email,string memory _previewName, uint _timeStamp) public view returns (bytes memory){
        bytes32 _encryptedEmail = keccak256(abi.encodePacked(_email));
        bytes32 _encryptedPreview = keccak256(abi.encodePacked(_previewName));
        bytes32 _combine = keccak256(abi.encodePacked(_encryptedEmail,_encryptedPreview,_timeStamp));
        return scriptPad[_combine];
    }

    function showPreviewChamber(string memory _email,string memory _previewName, uint _timeStamp) public view returns (bytes memory){
        bytes32 _encryptedEmail = keccak256(abi.encodePacked(_email));
        bytes32 _encryptedPreview = keccak256(abi.encodePacked(_previewName));
        bytes32 _combine = keccak256(abi.encodePacked(_encryptedEmail,_encryptedPreview,_timeStamp));
        return previewChamber[_combine];
    }
    
    function showprojectCenter(string memory _email,string memory _previewName, uint _timeStamp) public view returns (bytes memory){
        bytes32 _encryptedEmail = keccak256(abi.encodePacked(_email));
        bytes32 _encryptedPreview = keccak256(abi.encodePacked(_previewName));
        bytes32 _combine = keccak256(abi.encodePacked(_encryptedEmail,_encryptedPreview,_timeStamp));
        return projectCenter[_combine];
    }

    function showSubscription(string memory _email,string memory _previewName, uint _timeStamp) public view returns (subscription memory){
        bytes32 _encryptedEmail = keccak256(abi.encodePacked(_email));
        bytes32 _encryptedPreview = keccak256(abi.encodePacked(_previewName));
        bytes32 _combine = keccak256(abi.encodePacked(_encryptedEmail,_encryptedPreview,_timeStamp));
        return subscribe[_combine];
    }
}