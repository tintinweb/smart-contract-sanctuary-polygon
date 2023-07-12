/**
 *Submitted for verification at polygonscan.com on 2023-07-11
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;
/// @title A contract for Dmail3 application
/// @notice This contract manages all mails for Dmail3 application

contract DMail3{

	// Defining a structure to store a task
	struct Task
	{
        int _box;
		string tag;
		string task;
		address receiver;
		bool _seen;
		uint _index;
		uint _time_stamp;
	}

	struct Account{
		string key;
		uint _last_inbox_length;
		uint _no_inbox_delete;
		uint _no_sentbox_delete;
		uint _no_bans_delete;
        uint _no_spambox;
	}

	mapping (address => Account) private account;
	mapping (address => Task[]) private inbox;
	mapping (address => Task[]) private sentbox;

	mapping (address => address[]) private bans;
	mapping (address => mapping(address=>bool) ) private ban;
	mapping (address => mapping(address =>uint) ) private bans_ref;
	
	event mailSent(address indexed from,address indexed to,uint indexed _time_stamp,uint _index);


	modifier _requireRegister{
		require(bytes(account[msg.sender].key).length>0,'Registration is required');
		_;
	}

	modifier _requireUserRegister(address sender){
		require(_isUserRegistered(sender),'User is not registered');
		_;
	}

	modifier _requireNotRegistered{
		require(bytes(account[msg.sender].key).length==0,'Already registered');
		_;
	}

	modifier _requireIsSelfPermit(address receiver){
		require(!isSelfBan(receiver),'You are not allowed to mail this user');
		_;
	}

	modifier _requireNotSelf(address receiver){
		require(msg.sender!=address(receiver),'cannot mail self');
		_;
	}

	modifier _requireValidString(string calldata data){
		require(bytes(data).length>0,'invalid input string');
		_;
	}

	modifier _requireValidStringArray(string[] calldata data){
		require(data.length>0,'invalid input string array');
		_;
	}

	modifier _requireValidAddressArray(address[] calldata data){
		require(data.length>0,'invalid input address array');
		_;
	}

	modifier _requireValidUintArray(uint[] calldata data){
		require(data.length>0,'invalid input uint array');
		_;
	}

	modifier _requireValidIntArray(int[] calldata data){
		require(data.length>0,'invalid input int array');
		_;
	}

	modifier _requireValidUint(uint _data){
		require(_data>0,'invalid input integer');
		_;
	}

	modifier _requireNonEmptyInbox(){
		require(inbox[msg.sender].length>0,'Empty inbox');
		_;
	}

	modifier _requireMinInbox(uint _min){
		require(_min>0 && inbox[msg.sender].length>_min,'out of inbox bounds');
		_;
	}

	modifier _requireValidInboxTask(uint _taskIndex){
		require(_taskIndex>0 && inbox[msg.sender][_taskIndex]._index>0,'invalid inbox task');
		_;
	}

	modifier _requireNonEmptySentbox(){
		require(sentbox[msg.sender].length>0,'Empty sentbox');
		_;
	}

	modifier _requireMinSentbox(uint _min){
		require(_min>0 && sentbox[msg.sender].length>_min,'out of sentbox bounds');
		_;
	}

	modifier _requireValidSentboxTask(uint _taskIndex){
		require(_taskIndex>0 && sentbox[msg.sender][_taskIndex]._index>0,'invalid sentbox task');
		_;
	}

	modifier _requireNotSpam(uint _taskIndex){
		require(_taskIndex>0 && inbox[msg.sender][_taskIndex]._box!=-1,'invalid non-spam target');
		_;
	}

	modifier _requireSpam(uint _taskIndex){
		require(_taskIndex>0 && inbox[msg.sender][_taskIndex]._box!=0,'invalid spam target');
		_;
	}

	// Defining function to add a task
	function toInbox(address receiver, string calldata task) public _requireRegister _requireValidString(task) _requireUserRegister(receiver) _requireNotSelf(receiver) _requireIsSelfPermit(receiver)
	{
		//uint _len=inbox[receiver].length;
		inbox[receiver].push(Task({
			_box:0,
			tag:'',
			task:task,
			receiver:receiver,
			_seen:false,
			_index:inbox[receiver].length+1,
			_time_stamp:block.timestamp
		}));
		//emit mailSent(msg.sender,receiver,block.timestamp,inbox[receiver].length);
	}

	// Defining function to add a task
	function toInboxMulti(address[] calldata receivers, string calldata task) external _requireRegister _requireValidString(task) _requireValidAddressArray(receivers)
	{
		uint _len=receivers.length;
		for(uint i=0;i<_len;i++) toInbox(receivers[i], task);
	}

	// Defining a function to get details of an inbox task
	function fromInbox(uint _taskIndex) external view returns (Task memory task)
	{
		if(_taskIndex>=0 && inbox[msg.sender].length>_taskIndex) task = inbox[msg.sender][_taskIndex];
	}

	// Defining a function to get all inbox task
	function allInbox() external view returns (Task[] memory)
	{
		return inbox[msg.sender];
	}

	// Defining a function to get all inbox task
	function updateLastInboxIndex() external
	{
		account[msg.sender]._last_inbox_length=inbox[msg.sender].length;
	}

	// Defining a function to get all new inbox task
	function allNewInbox() external view returns (Task[] memory)
	{
		Task[] memory newTask;
		uint _len=inbox[msg.sender].length;
		uint _prev_len=account[msg.sender]._last_inbox_length;
		if(_len>_prev_len) for(uint i=_prev_len;i<_len;i++) newTask[i]=inbox[msg.sender][i];
		return newTask;
	}

	// Defining a function to get number of new inbox task
	function noNewInbox() external view returns (uint)
	{
		return inbox[msg.sender].length-account[msg.sender]._last_inbox_length;
	}

    // Defining a function to get number of new inbox task
	function noInbox() external view returns (uint)
	{
		return inbox[msg.sender].length-account[msg.sender]._no_spambox-account[msg.sender]._no_inbox_delete;
	}

	// Defining a function to get all inbox task range
	function allInboxRange(uint _from,uint _length) external view returns (Task[] memory)
	{
		Task[] memory newTask;
		uint _len=inbox[msg.sender].length;
		if(_from>=0 && _len>_from){
			uint _end=(_length>0 && (_len-_from)>=_length)?(_from+_length):_len;
			for(uint i=_from;i<_end;i++) newTask[i]=inbox[msg.sender][i];
		}
		return newTask;
	}

	// Defining a function to set status of an inbox task
	function setSeen(uint256 _taskIndex,bool _seen) public _requireMinInbox(_taskIndex)
	{
		inbox[msg.sender][_taskIndex]._seen = _seen;
	}

	// Defining a function to set status of multiple inbox task
	function setSeenMulti(uint256[] calldata tasksIndex,bool _seen) public _requireRegister _requireValidUintArray(tasksIndex)
	{
		uint _len=tasksIndex.length;
		for(uint i=0;i<_len;i++) setSeen(tasksIndex[i],_seen);
	}

	// Defining a function to set tag of an inbox task
	function setInboxTaskTag(uint256 _taskIndex,string memory tag) external _requireMinInbox(_taskIndex)
	{
		inbox[msg.sender][_taskIndex].tag = tag;
	}

	// Defining a function to delete an inbox task
	function deleteFromInbox(uint256 _taskIndex) public _requireMinInbox(_taskIndex) _requireValidInboxTask(_taskIndex)
	{
		if(_taskIndex>=0 && inbox[msg.sender].length>_taskIndex && inbox[msg.sender][_taskIndex]._index>0){
			account[msg.sender]._no_inbox_delete++;
			delete inbox[msg.sender][_taskIndex];
		}
	}

	// Defining a function to delete multiple inbox task
	function deleteFromInboxMulti(uint256[] calldata tasksIndex)  external _requireRegister _requireValidUintArray(tasksIndex)
	{
		uint _len=tasksIndex.length;
		for(uint i=0;i<_len;i++) deleteFromInbox(tasksIndex[i]);
	}
	
	// Sentbox Operations

	function toSentbox(string calldata task,address receiver) external _requireRegister _requireValidString(task)
	{
		sentbox[msg.sender].push(Task({
			_box:0,
			tag:'',
			task:task,
			receiver:receiver,
			_seen:true,
			_index:sentbox[msg.sender].length+1,
			_time_stamp:block.timestamp
		}));
	}

	// Defining a function to get all sentbox task
	function allSentbox() external view returns (Task[] memory)
	{
		return sentbox[msg.sender];
	}

	// Defining a function to get details of a sentbox task
	function fromSentbox(uint _taskIndex) external view returns (Task memory)
	{
		Task memory task;
		if(_taskIndex>=0 && sentbox[msg.sender].length>_taskIndex) task = sentbox[msg.sender][_taskIndex];
		return task;
	}

	// Defining a function to get all sentbox task range
	function allSentboxRange(uint _from,uint _length) external view returns (Task[] memory)
	{
		Task[] memory newTask;
		uint _len=sentbox[msg.sender].length;

		if(_from>=0 && _len>_from){
			uint _end=(_length>0 && (_len-_from)>=_length)?(_from+_length):_len;
			for(uint i=_from;i<_end;i++) newTask[i]=sentbox[msg.sender][i];
		}
		return newTask;
	}
    
	// Defining a function to set tag of a sentbox task
	function setSentboxTaskTag(uint256 _taskIndex,string memory tag) external _requireMinSentbox(_taskIndex)
	{
		sentbox[msg.sender][_taskIndex].tag = tag;
	}

	// Defining a function to delete a sentbox task
	function deleteFromSentbox(uint256 _taskIndex) public _requireMinSentbox(_taskIndex) _requireValidSentboxTask(_taskIndex)
	{
		account[msg.sender]._no_sentbox_delete++;
		delete sentbox[msg.sender][_taskIndex];
	}

	// Defining a function to delete multiple sentbox task
	function deleteFromSentboxMulti(uint256[] calldata tasksIndex)  external _requireRegister _requireValidUintArray(tasksIndex)
	{
		uint _len=tasksIndex.length;
		for(uint i=0;i<_len;i++) deleteFromSentbox(tasksIndex[i]);
	}

	// Defining a function to get sentbox task count.
	function noSentCount() external view returns (uint256)
	{
		return sentbox[msg.sender].length-account[msg.sender]._no_sentbox_delete;
	}


	// Spambox Operations

	function toSpambox(uint _taskIndex) public _requireMinInbox(_taskIndex) _requireValidInboxTask(_taskIndex) _requireNotSpam(_taskIndex)
	{
		inbox[msg.sender][_taskIndex]._box=-1;
		account[msg.sender]._no_spambox++;
	}

	// Defining a function to move multiple inbox task to spambox
	function toSpamboxMulti(uint256[] calldata tasksIndex)  external _requireRegister _requireValidUintArray(tasksIndex)
	{
		uint _len=tasksIndex.length;
		for(uint i=0;i<_len;i++) toSpambox(tasksIndex[i]);
	}

	function restoreFromSpambox(uint _taskIndex) public _requireMinInbox(_taskIndex) _requireValidInboxTask(_taskIndex) _requireSpam(_taskIndex)
	{
		inbox[msg.sender][_taskIndex]._box=0;
		account[msg.sender]._no_spambox--;
	}

	// Defining a function to move multiple spambox task to inbox
	function restorFromSpamboxMulti(uint256[] calldata tasksIndex)  external _requireRegister _requireValidUintArray(tasksIndex)
	{
		uint _len=tasksIndex.length;
		for(uint i=0;i<_len;i++) restoreFromSpambox(tasksIndex[i]);
	}


	// Defining a function to set ban for address
	function setBan(address sender,bool _status) public _requireRegister
	{
		address sender_address=address(sender);
		if(ban[msg.sender][sender_address]!=_status) {
			ban[msg.sender][sender_address]=_status;
			if(_status) {
				bans[msg.sender].push(sender_address);
				bans_ref[msg.sender][sender_address]=bans[msg.sender].length;
			}
			else{
				delete bans[msg.sender][bans_ref[msg.sender][sender_address]];
				bans_ref[msg.sender][sender_address]=0;
				account[msg.sender]._no_bans_delete++;
			}
		}
	}

	// Defining a function to set ban for multiple address
	function setBanMulti(address[] calldata sender,bool _status) external _requireRegister _requireValidAddressArray(sender)
	{
		uint _len=sender.length;
		if(_len>0) for(uint i=0;i<_len;i++) setBan(sender[i],_status);
	}

	// Defining a function to ban an address
/*	function banAddress(address sender) public returns(uint _resp){
		_resp=setBan(sender,true);
	}

	// Defining a function to ban multiple address
	function banUserMulti(address[] calldata sender) external returns(uint _resp){
		uint _len=sender.length;
		if(_len>0) for(uint i=0;i<_len;i++) setBan(sender[i],true);
		else _resp=1;
	}
*/

	//Define a function to know if self is banned by user
	function isSelfBan(address sender) private view returns(bool){
		return ban[sender][msg.sender];
	}

	//Define a function to know if user is banned by self
	function isUserBan(address sender) external view returns(bool){
		return ban[msg.sender][sender];
	}

	//Define a function to get all bans
	function allBans() public view returns(address[] memory){
		return bans[msg.sender];
	}

	// Defining a function to get all sentbox task range
/*	function allBansRange(uint _from,uint _length) external view returns (address[] memory)
	{
		address[] memory newBans;
		uint _len=bans[msg.sender].length;


		if(_from>=0 && _len>_from){
			uint _end=((_len-_from)>=_length)?(_from+_length):_len;
			for(uint i=_from;i<_end;i++) newBans[i]=bans[msg.sender][i];
		}
		return newBans;
	}
	*/

	// Defining a function to set address public key
	function register(string calldata key) public _requireValidString(key) _requireNotRegistered
	{
		account[msg.sender]=Account({
			key:key,
			_last_inbox_length:0,
			_no_inbox_delete:0,
			_no_sentbox_delete:0,
			_no_spambox:0,
			_no_bans_delete:0
		});
	}

	// Defining a function to get address public key
	function getAccount() public view returns (Account memory)
	{
		return account[msg.sender];
	}

	// Defining a function to get address public key
	function getAccountKey(address sender) external view returns (string memory)
	{
		return account[sender].key;
	}

	// Defining a function to get own address public key
	function getOwnKey() external view returns (string memory)
	{
		return account[msg.sender].key;
	}

	// Defining a function to delete account
	function deleteAccount() public
	{
		delete inbox[msg.sender];
		delete sentbox[msg.sender];
		delete bans[msg.sender];
		delete account[msg.sender];
	}

	function _isUserRegistered(address sender) private view returns(bool){
		return bytes(account[sender].key).length>0;
	}

	function _isRegistered() public view returns(bool){
		return _isUserRegistered(msg.sender);
	}
}