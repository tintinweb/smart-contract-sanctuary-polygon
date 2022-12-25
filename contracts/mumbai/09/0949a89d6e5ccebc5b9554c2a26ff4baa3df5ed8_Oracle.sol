/**
 *Submitted for verification at polygonscan.com on 2022-12-25
*/

pragma solidity >=0.7.0 <0.9.0;
 
/**
 * @title Oracle
 * @dev Store & retrieve value in a variable
 */
contract Oracle {
 
    event LogRequest(RequestData);
    event LogRegister(string, address);
    
    struct RequestData {
        string pubkey;        //the sender's pubkey for encryption
        string encryptdata;   //the data encrypted use oracle's public key
        address requester;    //The contract address that invoke the oracle
        address identifier;   //Identify the data consumer
    }
    
    function register(string calldata encrypted_data) public {
        emit LogRegister(encrypted_data, msg.sender);
    }
    
    function requestEncrypt(string calldata pubkey, string calldata requestdata, address identifier) public {
        RequestData memory d = RequestData(pubkey, requestdata, msg.sender, identifier);
        emit LogRequest(d);
    }
    
    function callback(string calldata encrypted, address receiver, address identifier) public {
        receiver.call{gas:2100000}(abi.encodeWithSelector(bytes4(keccak256('getNewEncrypted(string,address)')), encrypted, identifier));
    }
}