//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;
import './Ownable.sol';
import './Verifiable.sol';

error SignatureNotVerified();
error AdminNotAuthorized();
error AdminNotSet();
error LengthMismatch();

contract Governance is Ownable, Verifiable {

    mapping (string => string) public pollResult;

    event PollPublished(string _pollId, string _result);
    event AdminUpdated(address _newAdmin);
    event AdminAuthorizationUpdated(address admin, bool _isAuthorized);

    constructor(address owner) Ownable(owner){}

    /**
    * @param _pollId : The poll id string corresponding to the id offchain
    * @return _pollResult :  The IPFS CID hash corresponding to the result of the rating of the poll
    * Returns the IPFS url of the poll rating containing the voting data
    */
    function getPollResult(string calldata _pollId) external view returns(string memory _pollResult) {
        return pollResult[_pollId];
    }

    /**
    * @param _pollId : The id of the poll corresponding to offchain poll id
    * @param _result : The IPFS CID hash corresponding to the voting result of the rating of the poll
    * @param _signature : The signature corresponding to the pollId and ipfs hash
    * @return success : Returns boolean value true when flow is completed successfully
    * To create a new poll entry, with some data (pollId, poll transaction hash) included for future verification with offchain data
    */
    function setPollResult(string calldata _pollId, string calldata _result, bytes memory _signature) public returns(bool success){
        if(!verify(owner(), msg.sender, _pollId, _result, _signature)) revert SignatureNotVerified();

        pollResult[_pollId] = _result;
        emit PollPublished(_pollId, _result);
        return true;
    }

    /**
    * @param _pollIds : The array of ids of the poll corresponding to offchain poll ids
    * @param _results : The array of transaction hashes corresponding to the result of the rating of the polls
    * @param _signatures : The array of signatures corresponding to the pollId array and ipfs hash array
    * @return success : Returns boolean value true when flow is completed successfully
    * To create a new poll entry, with some data (pollId, poll transaction hash) included for future verification with offchain data
    */
    function multiSetPollResult(string[] calldata _pollIds, string[] calldata _results, bytes[] memory _signatures) 
    external returns(bool success){
       if(!(_pollIds.length == _results.length) || !(_results.length == _signatures.length)) revert LengthMismatch();

        for (uint256 i = 0; i < _pollIds.length; i++) {
            setPollResult(_pollIds[i], _results[i], _signatures[i]);
        }
        return true;
    }

        /**
    * @param _pollId : The id of the poll corresponding to offchain poll id
    * @param _result : The IPFS CID hash corresponding to the voting result of the rating of the poll
    * @param _signature : The signature corresponding to the pollId and ipfs hash
    * @return success : Returns boolean value true when flow is completed successfully
    * To create a new poll entry, with some data (pollId, poll transaction hash) included for future verification with offchain data using admin signature
    */
    function setPollResultThroughAdmin(string calldata _pollId, string calldata _result, bytes memory _signature) public returns(bool success){

        if(admin == address(0)) revert AdminNotSet();
        if(!isAdminAuthorized) revert AdminNotAuthorized();
        if(!verify(admin, msg.sender, _pollId, _result, _signature)) revert SignatureNotVerified();

        pollResult[_pollId] = _result;
        emit PollPublished(_pollId, _result);
        return true;
    }

    /**
    * @param _pollIds : The array of ids of the poll corresponding to offchain poll ids
    * @param _results : The array of transaction hashes corresponding to the result of the rating of the polls
    * @param _signatures : The array of signatures corresponding to the pollId array and ipfs hash array
    * @return success : Returns boolean value true when flow is completed successfully
    * To create a new poll entry, with some data (pollId, poll transaction hash) included for future verification with offchain data using admin signature
    */
    function multiSetPollResultThroughAdmin(string[] calldata _pollIds, string[] calldata _results, bytes[] memory _signatures) 
    external returns(bool success){
       if(_pollIds.length != _results.length || _results.length != _signatures.length) revert LengthMismatch();

        for (uint256 i = 0; i < _pollIds.length; i++) {
            setPollResultThroughAdmin(_pollIds[i], _results[i], _signatures[i]);
        }
        return true;
    }

    /**
    * @param _pollId : The id of the poll corresponding to offchain poll id
    * @param _result : The IPFS CID hash corresponding to the voting result of the rating of the poll
    * @return success : Returns boolean value true when flow is completed successfully
    * To create a new poll entry, with some data (pollId, poll transaction hash) included for future verification with offchain data
    * Can be executed only by the owner of the governance smart contract
    */
    function setPollResultOwnerOrAdmin(string calldata _pollId, string calldata _result) public onlyOwnerOrAdmin returns(bool success){
        pollResult[_pollId] = _result;
        emit PollPublished(_pollId, _result);
        return true;
    }

    /**
    * @param _pollIds : The array of ids of the poll corresponding to offchain poll ids
    * @param _results : The array of transaction hashes corresponding to the result of the rating of the polls
    * @return success : Returns boolean value true when flow is completed successfully
    * To create a new poll entry, with some data (pollId, poll transaction hash) included for future verification with offchain data
    * Can be executed only by the owner of the governance smart contract
    */
    function multiSetPollResultOwnerOrAdmin(string[] calldata _pollIds, string[] calldata _results) 
    external onlyOwnerOrAdmin returns(bool success){
        if(_pollIds.length != _results.length) revert LengthMismatch();

        for (uint256 i = 0; i < _pollIds.length; i++) {
            setPollResultOwnerOrAdmin(_pollIds[i], _results[i]);
        }
        return true;
    }

    /**
    * @param _newAdmin : The poll id string corresponding to the id offchain
    * To set the admin address, who can set poll results without owner signature
    */
    function setAdmin(address _newAdmin) external onlyOwner{
        admin = _newAdmin;
        emit AdminUpdated(_newAdmin);
    }

    /**
    * @param _isAuthorized : The poll id string corresponding to the id offchain
    * To authorize or revoke admin permission for setting poll results
    */
    function setAdminAuthorization(bool _isAuthorized) external onlyOwner{
        isAdminAuthorized = _isAuthorized;
        emit AdminAuthorizationUpdated(admin, _isAuthorized);
    }
}