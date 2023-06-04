// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "./EpigeonInterfaces_080.sol";

//----------------------------------------------------------------------------------------------------
contract LimitedLockablePigeonFactory is IPigeonFactory{

    address public lockableCoin;

    address public _owner;
    uint256 private _factoryId = 100;
    uint256 private _mintingPrice;
    uint256 private _maxSupply;
    uint256 private _totalSupply;
    address public epigeon;
    address public chat;
    string private _metadata = "https://www.epigeon.org/Meta/LimitedLockablePigeonMetadata.json";
    mapping (address => uint256) internal ApprovedTokenPrice;
    
    event PigeonCreated(ICryptoPigeon pigeon);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    function factoryId() external view returns (uint256 id){return _factoryId;}
    function mintingPrice() external view returns (uint256 price){return _mintingPrice;}
    function totalSupply() external view returns (uint256 supply){return _totalSupply;}
    function maxSupply() external view returns (uint256 supply){return _maxSupply;}

    constructor (address epigeonAddress, address coinAddress, address chatAddress, uint256 price){
        _owner = msg.sender;
        epigeon = epigeonAddress;
        lockableCoin = coinAddress;
        chat = chatAddress;
        _mintingPrice = price;
        _maxSupply = 100;
    }
    
    function amIEpigeon() public view returns (bool ami){
        return epigeon == msg.sender;
    }
    
    function createCryptoPigeon(address to) public returns (ICryptoPigeon pigeonaddress) {
        require(epigeon == msg.sender);
        require(_totalSupply < _maxSupply);
        
        ICryptoPigeon pigeon = new LimitedLockableCryptoPigeon(to, msg.sender, lockableCoin, chat, _factoryId);
        _totalSupply += 1;
        emit PigeonCreated(pigeon);
        return pigeon;
    }
    
    function getFactoryTokenPrice(address ERC20Token) public view returns (uint256 price){
        return ApprovedTokenPrice[ERC20Token];
    }
    
    function getMetaDataForPigeon(address pigeon) public view returns (string memory metadata){
        if (pigeon == address(0)){
            return _metadata;
        }
        else{
            return _metadata;
        }
    }
    
    function iAmFactory() public pure returns (bool isIndeed) {
        return true;
    }
    
    function setMintingPrice(uint256 price) public {
        require(msg.sender == _owner);
        _mintingPrice = price;
    }
    
    function setBasicMetaDataForPigeon(string memory metadata) public {
        require(msg.sender == _owner);
        _metadata = metadata;
    }
    
    function setMintingPrice(address ERC20Token, uint256 price) public {
        require(msg.sender == _owner);
        ApprovedTokenPrice[ERC20Token] = price;
    }
    
    function transferOwnership(address newOwner) public {    
        require(_owner == msg.sender, "Only _owner");
        require(newOwner != address(0), "Zero address");
        emit OwnershipTransferred(_owner, newOwner);
        payable(_owner).transfer(address(this).balance);
        _owner = newOwner;
    }
} 
//----------------------------------------------------------------------------------------------------

contract LimitedLockableCryptoPigeon is ICryptoPigeon{

    uint256 private _factoryId;  
    address private _owner;
    address private _manager;
    string public message;
    bytes32 internal message_hash;
    string public answer;
    uint256 public messageTimestamp;
    uint256 public answerTimestamp;
    address private _toAddress;
    bool private _hasFlown;
    bool public isRead;
    ILockable public lockable;
    address public epigeonContractAddress;
    address public chat;
    bool public clearAtTransfer;
    bool public sentByManager;

    event AnswerSent(address sender, string message, uint256 messageTimestamp);  
    event MessageSent(address sender, string rmessage, address toAddress, uint256 messageTimestamp);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ValueClaimed(address receiver);
    
    function hasFlown() external view returns (bool HasFlown){return _hasFlown;}
    function toAddress() external view returns (address addressee){return _toAddress;} 
    function owner() external view returns (address owned){return _owner;}
    function manager() external view returns (address managed){return _manager;}
    function factoryId() external view returns (uint256 id){return _factoryId;}
    
    constructor (address _mintedto, address epigeonAddress, address coinAddress, address chatAddress, uint256 fid){
        _owner = _mintedto;
        _manager = _mintedto;
        lockable = ILockable(coinAddress);
        epigeonContractAddress = epigeonAddress;
        chat = chatAddress;
        _factoryId = fid;
        _hasFlown = false;
        clearAtTransfer = true;
    }
	
	function connectToChat() public {
		require(msg.sender == _toAddress, "Do not have invite");
		if (!IChat(chat).isContact(_owner, _toAddress)){
			IChat(chat).addContactByPigeon(_owner, _toAddress);
		}
		if (!IChat(chat).isContact(_toAddress, _owner)){
			IChat(chat).addContactByPigeon(_toAddress, _owner);
		}
	}
    
    function burnPigeon() public {
        require(msg.sender == epigeonContractAddress);
        if (message_hash != 0){
            //clear balances
            lockable.operatorReclaim(_owner, _toAddress, message, "", "");
        }
        address wallet = _owner;
        selfdestruct(payable(wallet));
    }  

    function getValueForMessage(string memory textMessage) public {
        require(msg.sender == _toAddress);
        require(keccak256(bytes(textMessage)) == keccak256(bytes(message)));
        lockable.operatorUnlock(_toAddress, message, "", "");
        delete message_hash;
        isRead = true;
        emit ValueClaimed(_toAddress);
    }
    
    function iAmPigeon() public pure returns (bool isIndeed) {
        return true;
    }
    
    function recallValue() public {
        require(msg.sender == _owner || msg.sender == _manager);
        require(message_hash != 0);
        lockable.operatorReclaim(_owner, _toAddress, message, "", "");
        delete message_hash;
    }
    
    function sendAnswer(string memory textMessage) public {
        require(msg.sender == _toAddress);
        answer = textMessage;
        answerTimestamp = block.timestamp;
        emit AnswerSent(msg.sender, answer, answerTimestamp);
    }
    
    function sendMessage(string memory textMessage, address addressee) public {
        require(msg.sender == _owner || msg.sender == _manager);
        if (msg.sender == _manager){
            if (sentByManager == false) {sentByManager = true;}
        }
        else{
            if (sentByManager == true) {sentByManager = false;}
        }
        
        //clear balances
        if (message_hash != 0){
            lockable.operatorReclaim(_owner, _toAddress, message, "", "");
            delete message_hash;
        }
        
        if (addressee != _toAddress){
            //Need to tell for the mailboxes
            if (_hasFlown){
                IEpigeon(epigeonContractAddress).pigeonDestinations().changeToAddress(addressee, _toAddress);
            }
            else{
                _hasFlown = true;
                IEpigeon(epigeonContractAddress).pigeonDestinations().setToAddress(addressee);
            }
            _toAddress = addressee;
            delete answer;
            delete answerTimestamp;
        }
        
        message = textMessage;
        messageTimestamp = block.timestamp;
        isRead = false;
        
        emit MessageSent(msg.sender, message, _toAddress, messageTimestamp);
    }
    
    function sendMessagewithLockable(string memory textMessage, address addressee, uint256 amount) public {
        require(msg.sender == _owner || msg.sender == _manager);
        require(amount > 0);
        require(IERC777(address(lockable)).balanceOf(msg.sender) > amount);
        
        if (msg.sender == _manager){
            if (sentByManager == false) {sentByManager = true;}
        }
        else{
            if (sentByManager == true) {sentByManager = false;}
        }
        
        if (addressee != _toAddress){
            //Need to tell for the mailboxes
            if (_hasFlown){
                IEpigeon(epigeonContractAddress).pigeonDestinations().changeToAddress(addressee, _toAddress);
            }
            else{
                _hasFlown = true;
                IEpigeon(epigeonContractAddress).pigeonDestinations().setToAddress(addressee);
            }
            _toAddress = addressee;
            delete answer;
            delete answerTimestamp;
        }
        
        if (message_hash != 0){
            //clear balances
            lockable.operatorReclaim(_owner, _toAddress, message, "", "");
        }
        
        //lock value
        bytes32 hash = keccak256(bytes(textMessage));
        lockable.operatorLock(msg.sender, addressee, amount, hash, "", "");
        
        message = textMessage;
        message_hash = hash;
        messageTimestamp = block.timestamp;
        isRead = false;
        
        emit MessageSent(msg.sender, message, _toAddress, messageTimestamp);
    }
    
    function setMessageRead() public returns (string memory rmessage){
        require(_toAddress == msg.sender);       
        isRead = true;
        rmessage = message;
    }
    
    function setClearAtTransfer(bool clear) public {
        require(msg.sender == _owner);
        clearAtTransfer = clear;
    }
    
    function setManager(address managerAddress) public {
        require(msg.sender == _owner || msg.sender == _manager);
        _manager = managerAddress;
    }  
    
    function transferOwnership(address to) public{
        require(msg.sender == _owner);
        IEpigeon(epigeonContractAddress).transferPigeon(msg.sender, to, address(this));
    }
    
    function transferPigeon(address newOwner) public {
        require(msg.sender == epigeonContractAddress);
        if (message_hash != 0){
            //clear balances
            lockable.operatorReclaim(_owner, _toAddress, message, "", "");
            delete message_hash;
        }
        if (clearAtTransfer){
            //delete MessageArchive;
            //delete AnswerArchive;
            delete message;
            delete answer;
            delete messageTimestamp;
            delete answerTimestamp;
            payable(_owner).transfer(address(this).balance);
        }
        _owner = newOwner;
        _manager = newOwner;
        _hasFlown = false;
        isRead = false;
        delete _toAddress;
        emit OwnershipTransferred(_owner, newOwner);
    }
    
    function viewValue() public view returns (uint256 value){
        return lockable.lockedAmount(_owner, message_hash);
    }
}
//----------------------------------------------------------------------------------------------------