// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

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
    function createOnePager(bytes32 _onePagerCombine, bytes memory _uri,string memory _userName, string memory _fileName, uint _timeOfUpload) public onlyOwner {
        onePager[_onePagerCombine] = _uri;
        uploadFileStatus[_userName][_fileName][_timeOfUpload] = true;
        emit uploadDetails(_userName, _fileName, _timeOfUpload);
    }
   
    function createStory(bytes32 _storyCombine, bytes memory _uri,string memory _userName, string memory _fileName, uint _timeOfUpload) public onlyOwner {
        story[_storyCombine] = _uri;
        uploadFileStatus[_userName][_fileName][_timeOfUpload] = true;
        emit uploadDetails(_userName, _fileName, _timeOfUpload);
    }

    function createSampleScript(bytes32 _combineSampleScript, bytes memory _uri,string memory _userName, string memory _fileName, uint _timeOfUpload) public onlyOwner {
        sampleScript[_combineSampleScript] = _uri;
        uploadFileStatus[_userName][_fileName][_timeOfUpload] = true;
        emit uploadDetails(_userName, _fileName, _timeOfUpload);
    }

    function createFullScript(bytes32 _combineFullScript, bytes memory _uri,string memory _userName, string memory _fileName, uint _timeOfUpload) public onlyOwner {
        fullScript[_combineFullScript] = _uri;
        uploadFileStatus[_userName][_fileName][_timeOfUpload] = true;
        emit uploadDetails(_userName, _fileName, _timeOfUpload);
    }

    function createFootage(bytes32 _combineFootage, bytes memory _uri,string memory _userName, string memory _fileName, uint _timeOfUpload) public onlyOwner {
        footage[_combineFootage] = _uri;
        uploadFileStatus[_userName][_fileName][_timeOfUpload] = true;
        emit uploadDetails(_userName, _fileName, _timeOfUpload);
    }

    function createPitchDeck(bytes32 _combinePitchDeck, bytes memory _uri,string memory _userName, string memory _fileName, uint _timeOfUpload) public onlyOwner {
        pitchDeck[_combinePitchDeck] = _uri;
        uploadFileStatus[_userName][_fileName][_timeOfUpload] = true;
        emit uploadDetails(_userName, _fileName, _timeOfUpload);
    }
    
    function createSampleNarration(bytes32 _combineSampleNarration, bytes memory _uri,string memory _userName, string memory _fileName, uint _timeOfUpload) public onlyOwner {
        sampleNarration[_combineSampleNarration] = _uri;
        uploadFileStatus[_userName][_fileName][_timeOfUpload] = true;
        emit uploadDetails(_userName, _fileName, _timeOfUpload);
    }    

    function createFullNarration(bytes32 _combineFullNarration, bytes memory _uri,string memory _userName, string memory _fileName, uint _timeOfUpload) public onlyOwner {
        fullNarration[_combineFullNarration] = _uri;
        uploadFileStatus[_userName][_fileName][_timeOfUpload] = true;
        emit uploadDetails(_userName, _fileName, _timeOfUpload);
    }

    function createScriptAnalysis(bytes32 _combineScriptAnalysis, bytes memory _uri,string memory _userName, string memory _fileName, uint _timeOfUpload) public onlyOwner {
        scriptAnalysis[_combineScriptAnalysis] = _uri;
        uploadFileStatus[_userName][_fileName][_timeOfUpload] = true;
        emit uploadDetails(_userName, _fileName, _timeOfUpload);
    }   

    function createCharacterIntro(bytes32 _combineCharacterIntro, bytes memory _uri,string memory _userName, string memory _fileName, uint _timeOfUpload) public onlyOwner{
        characterIntroduction[_combineCharacterIntro] = _uri;
        uploadFileStatus[_userName][_fileName][_timeOfUpload] = true;
        emit uploadDetails(_userName, _fileName, _timeOfUpload);
    }   
    function createPPTconversion(bytes32 _pptCombine, bytes[2] memory _uri,string memory _userName, string memory _fileName, uint _timeOfUpload) public onlyOwner {
        pptConvert[_pptCombine][0] = _uri[0];
        pptConvert[_pptCombine][1] = _uri[1];
        uploadFileStatus[_userName][_fileName][_timeOfUpload] = true;
        emit uploadDetails(_userName, _fileName, _timeOfUpload);
    }      

    function createStoryConversion(bytes32 _storyCombine, bytes[2] memory _uri,string memory _userName, string memory _fileName, uint _timeOfUpload) public onlyOwner {
        storyConvert[_storyCombine][0] = _uri[0];
        storyConvert[_storyCombine][1] = _uri[1];
        uploadFileStatus[_userName][_fileName][_timeOfUpload] = true;
        emit uploadDetails(_userName, _fileName, _timeOfUpload);
    }      

    function createBookConversion(bytes32 _bookCombine, bytes[2] memory _uri,string memory _userName, string memory _fileName, uint _timeOfUpload) public onlyOwner {
        bookConvert[_bookCombine][0] = _uri[0];
        bookConvert[_bookCombine][1] = _uri[1];        
        uploadFileStatus[_userName][_fileName][_timeOfUpload] = true;
        emit uploadDetails(_userName, _fileName, _timeOfUpload);
    }

    function createScriptConversion(bytes32 _scriptCombine, bytes[2] memory _uri,string memory _userName, string memory _fileName, uint _timeOfUpload) public onlyOwner{
        scriptConvert[_scriptCombine][0] = _uri[0];
        scriptConvert[_scriptCombine][1] = _uri[1];        
        uploadFileStatus[_userName][_fileName][_timeOfUpload] = true;
        emit uploadDetails(_userName, _fileName, _timeOfUpload);
    }    

    function createPitchDeckConversion(bytes32 _pitchDeckCombine, bytes memory _uri,string memory _userName, string memory _fileName, uint _timeOfUpload) public onlyOwner {
        pitchDeckConvert[_pitchDeckCombine] = _uri;        
        uploadFileStatus[_userName][_fileName][_timeOfUpload] = true;
        emit uploadDetails(_userName, _fileName, _timeOfUpload);
    }   

    function createViewerLoungeForVideo(bytes32 _viewerLoungeVideoCombine, bytes memory _uri,string memory _userName, string memory _fileName, uint _timeOfUpload) public onlyOwner {
        viewerLoungeVideo[_viewerLoungeVideoCombine] = _uri;        
        uploadFileStatus[_userName][_fileName][_timeOfUpload] = true;
        emit uploadDetails(_userName, _fileName, _timeOfUpload);
    } 
        
    function createviewerLoungeForLink(bytes32 _viewerLoungeLinkCombine, bytes memory _uri,string memory _userName, string memory _fileName, uint _timeOfUpload) public onlyOwner {
        viewerLoungeLink[_viewerLoungeLinkCombine] = _uri;        
        uploadFileStatus[_userName][_fileName][_timeOfUpload] = true;
        emit uploadDetails(_userName, _fileName, _timeOfUpload);
    }

    function createScriptPad(bytes32 _scriptPadCombine, bytes memory _uri,string memory _userName, string memory _fileName, uint _timeOfUpload) public onlyOwner {
        scriptPad[_scriptPadCombine] = _uri;        
        uploadFileStatus[_userName][_fileName][_timeOfUpload] = true;
        emit uploadDetails(_userName, _fileName, _timeOfUpload);
    } 

    function createPreviewChamber(bytes32 _previewChamberCombine, bytes memory _uri,string memory _userName, string memory _fileName, uint _timeOfUpload) public onlyOwner {
        previewChamber[_previewChamberCombine] = _uri;        
        uploadFileStatus[_userName][_fileName][_timeOfUpload] = true;
        emit uploadDetails(_userName, _fileName, _timeOfUpload);
    } 

    function createProjectCenter(bytes32 _projectCenterCombine, bytes memory _uri,string memory _userName, string memory _fileName, uint _timeOfUpload) public onlyOwner {
        projectCenter[_projectCenterCombine] = _uri;        
        uploadFileStatus[_userName][_fileName][_timeOfUpload] = true;
        emit uploadDetails(_userName, _fileName, _timeOfUpload);
    } 
    
    function createSubscription(bytes32 _subscriptionCombine, string memory startDate, string memory endDate,string memory _userName, string memory _fileName, uint _timeOfUpload) public onlyOwner {
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

    function changeDocumentOwnership(bytes32 _email, bytes32 _previewName, string memory _fileFrom,bytes32 _onePagerCombine, string memory _userName, string memory _fileName, uint _timeOfUpload) public onlyOwner {
        bytes32 _combine = keccak256(abi.encodePacked(_email,_previewName,_timeOfUpload));
        if(keccak256(abi.encodePacked(_fileFrom)) == keccak256(abi.encodePacked("onePager"))){
            bytes memory _uri = onePager[_combine];
            require(_uri.length != 0,"Wrong Input");
            createOnePager(_onePagerCombine,_uri,_userName,_fileName,_timeOfUpload);
            delete onePager[_combine];
		}
        else if(keccak256(abi.encodePacked(_fileFrom)) == keccak256(abi.encodePacked("story"))){
            bytes memory _uri = story[_combine];
            require(_uri.length != 0,"Wrong Input");
            createStory(_onePagerCombine,_uri,_userName,_fileName,_timeOfUpload);
            delete story[_combine];
        }
        else if(keccak256(abi.encodePacked(_fileFrom)) == keccak256(abi.encodePacked("sampleScript"))){
            bytes memory _uri = sampleScript[_combine];
            require(_uri.length != 0,"Wrong Input");
            createSampleScript(_onePagerCombine,_uri,_userName,_fileName,_timeOfUpload);
            delete sampleScript[_combine];
        }
        else if(keccak256(abi.encodePacked(_fileFrom)) == keccak256(abi.encodePacked("fullScript"))){
            bytes memory _uri = fullScript[_combine];
            require(_uri.length != 0,"Wrong Input");
            createFullScript(_onePagerCombine,_uri,_userName,_fileName,_timeOfUpload);
            delete fullScript[_combine];
        }
        else if(keccak256(abi.encodePacked(_fileFrom)) == keccak256(abi.encodePacked("footage"))){
            bytes memory _uri = footage[_combine];
            require(_uri.length != 0,"Wrong Input");
            createFootage(_onePagerCombine,_uri,_userName,_fileName,_timeOfUpload);
            delete footage[_combine];
        }
        else if(keccak256(abi.encodePacked(_fileFrom)) == keccak256(abi.encodePacked("pitchDeck"))){
            bytes memory _uri = pitchDeck[_combine];
            require(_uri.length != 0,"Wrong Input");
            createPitchDeck(_onePagerCombine,_uri,_userName,_fileName,_timeOfUpload);
            delete pitchDeck[_combine];
        }
        else if(keccak256(abi.encodePacked(_fileFrom)) == keccak256(abi.encodePacked("sampleNarration"))){
            bytes memory _uri = sampleNarration[_combine];
            require(_uri.length != 0,"Wrong Input");
            createSampleNarration(_onePagerCombine,_uri,_userName,_fileName,_timeOfUpload);
            delete sampleNarration[_combine];
        }
        else if(keccak256(abi.encodePacked(_fileFrom)) == keccak256(abi.encodePacked("fullNarration"))){
            bytes memory _uri = fullNarration[_combine];
            require(_uri.length != 0,"Wrong Input");
            createFullNarration(_onePagerCombine,_uri,_userName,_fileName,_timeOfUpload);
            delete fullNarration[_combine];
        }
        else if(keccak256(abi.encodePacked(_fileFrom)) == keccak256(abi.encodePacked("scriptAnalysis"))){
            bytes memory _uri = scriptAnalysis[_combine];
            require(_uri.length != 0,"Wrong Input");
            createScriptAnalysis(_onePagerCombine,_uri,_userName,_fileName,_timeOfUpload);
            delete scriptAnalysis[_combine];
        }
        else if(keccak256(abi.encodePacked(_fileFrom)) == keccak256(abi.encodePacked("characterIntroduction"))){
            bytes memory _uri = characterIntroduction[_combine];
            require(_uri.length != 0,"Wrong Input");
            createCharacterIntro(_onePagerCombine,_uri,_userName,_fileName,_timeOfUpload);
            delete characterIntroduction[_combine];
        }
    }

    function remove() public {
        require(msg.sender == owner(), "msg.sender is not the owner");
        selfdestruct(payable(owner()));
    }

    fallback() external payable{
        payable(owner()).transfer(msg.value); 
    } 
    receive() external payable{
        payable(owner()).transfer(msg.value); 
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Context.sol";

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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