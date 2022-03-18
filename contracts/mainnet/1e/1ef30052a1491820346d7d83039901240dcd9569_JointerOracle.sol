/**
 *Submitted for verification at polygonscan.com on 2022-03-17
*/

/**
 *Submitted for verification at BscScan.com on 2020-10-21
*/

pragma solidity ^0.6.0;


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
contract Ownable {
    
    address payable public owner;
    
    address payable public newOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        _trasnferOwnership(msg.sender);
    }
    
    function _trasnferOwnership(address payable _whom) internal {
        emit OwnershipTransferred(owner,_whom);
        owner = _whom;
    }
    

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "ERR_AUTHORIZED_ADDRESS_ONLY");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable _newOwner)
        external
        virtual
        onlyOwner
    {
        require(_newOwner != address(0),"ERR_ZERO_ADDRESS");
        newOwner = _newOwner;
    }
    
    
    function acceptOwnership() external
        virtual
        returns (bool){
            require(msg.sender == newOwner,"ERR_ONLY_NEW_OWNER");
            owner = newOwner;
            emit OwnershipTransferred(owner, newOwner);
            newOwner = address(0);
            return true;
        }
    
    
}


interface Oraclize{
    function oracleCallback(uint256 requsestId,uint256 balance) external returns(bool);
    function oracleCallback(uint256 requsestId,uint256[] calldata balance) external returns(bool);
}

contract JointerOracle is Ownable{
    
    uint256 public requsestId;

    mapping(address => bool) public isAllowedAddress;
    mapping(uint256 => bool) public requestFullFilled;
    mapping(uint256 => address) public requestedBy;
    mapping(uint256 => address) public requestedToken;
    mapping(uint256 => address) public requestedUser;
    
    mapping(uint256 => address[]) public requestedBatchUser;
    
    event BalanceRequested(uint256 requsestId,uint256 network,address token,address user);
    event BalanceRequestedBatch(uint256 requsestId,uint256 network,address token,address[] user);
    event BalanceUpdated(uint256 requsestId,address token,address user,uint256 balance);
    event BalanceUpdatedBatch(uint256 requsestId,address token,address[] user,uint256[] balance);
        
    // parmeter pass networkId like eth_mainNet = 1,ropsten = 97 etc 
    // token pramter is which token balance you want for native currnecy pass address(0)
    // user which address you want to show
    function getBalance(uint256 network,address token,address user) external returns(uint256){
        require(isAllowedAddress[msg.sender],"ERR_ALLOWED_ADDRESS_ONLY");
        requsestId +=1;
        requestedBy[requsestId] = msg.sender;
        requestedUser[requsestId] = user;
        requestedToken[requsestId] = token;
        emit BalanceRequested(requsestId,network,token,user);
        return requsestId;
    }
    
    function getBalance(uint256 network,address token,address[] calldata user) external returns(uint256){
        require(isAllowedAddress[msg.sender],"ERR_ALLOWED_ADDRESS_ONLY");
        requsestId +=1;
        requestedBy[requsestId] = msg.sender;
        requestedBatchUser[requsestId] = user;
        requestedToken[requsestId] = token;
        emit BalanceRequestedBatch(requsestId,network,token,user);
        return requsestId;
    }
    
    function oracleCallback(uint256 _requsestId,uint256[] calldata _balances) external onlyOwner returns(bool){
        require(requestFullFilled[_requsestId]==false,"ERR_REQUESTED_IS_FULLFILLED");
        address _requestedBy = requestedBy[_requsestId];
        Oraclize(_requestedBy).oracleCallback(_requsestId,_balances);
        emit BalanceUpdatedBatch(_requsestId,requestedToken[_requsestId],requestedBatchUser[_requsestId],_balances);
        requestFullFilled[_requsestId] = true;
        return true;
    }
    
    
    function oracleCallback(uint256 _requsestId,uint256 _balances) external onlyOwner returns(bool){
        require(requestFullFilled[_requsestId]==false,"ERR_REQUESTED_IS_FULLFILLED");
        address _requestedBy = requestedBy[_requsestId];
        Oraclize(_requestedBy).oracleCallback(_requsestId,_balances);
        emit BalanceUpdated(_requsestId,requestedToken[_requsestId],requestedUser[_requsestId],_balances);
        requestFullFilled[_requsestId] = true;
        return true;
    }
    
    function changeAllowedAddress(address _which,bool _bool) external onlyOwner returns(bool){
        isAllowedAddress[_which] = _bool;
        return true;
    }

}