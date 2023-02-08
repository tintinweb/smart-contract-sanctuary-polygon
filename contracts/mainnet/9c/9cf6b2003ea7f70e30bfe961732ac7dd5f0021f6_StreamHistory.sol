/**
 *Submitted for verification at polygonscan.com on 2023-02-08
*/

// SPDX-License-Identifier: MIT 
pragma solidity 0.8.17;
//  Polygon
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}



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



contract StreamHistory is Ownable{

    address public streamContract;

    

    function changeStreamContract(address _newStreamContract) external onlyOwner{
        require (_newStreamContract != address(0), "Zero address");
        streamContract = _newStreamContract;
    }

    modifier onlyStreamContract{
        require(streamContract == msg.sender, "Access is denied");
            _;

    }

// get all id by address
mapping (address => uint256[]) addressIds; 


//  get parameters of stream
mapping(uint256 => Stream) streams;//id -> struct  

mapping (uint256 => mapping (uint256 => WithDraw)) withdrawParameters;// id -> number of Withdraws -> parameters

// withdraw parameters
struct WithDraw{

    uint256 amount;
    uint256 withdrawTime;
}

struct Stream {
        uint256 deposit;
       
        uint64 startTime;
        uint64 stopTime;
        uint64 blockDate;
        uint64 cancelDate;
        
        uint8 recieveOrSenderCanCancel; 
        address recipient;
        
        address sender;
        uint8 status; //1, 2 canceled paused
                
        address tokenAddress;
        uint256 numberOfWithdraws;
        string purpose;
        
    }

    // get array ids by user address 
    function addUserId(address _user, uint256 _id ) external onlyStreamContract{
        addressIds[_user].push(_id);
    }


    // get stream parameters by id
    function getStreamById(uint256 _id) external view returns (
            uint256 deposit,
            uint64 startTime,
            uint64 stopTime,

            uint64 blockDate,
            uint64 cancelDate,
            uint8 recieveOrSenderCanCancel, 
        
            address recipient,
            address sender,
            uint8 status, //1, 2 canceled paused
                    
            address tokenAddress,
            
            uint256 numberOfWithdraws,
            
            string memory purpose
        )
        { 
            deposit = streams[_id].deposit;
            startTime = streams[_id].startTime;
            stopTime = streams[_id].stopTime;

            blockDate = streams[_id].blockDate;
            cancelDate = streams[_id].cancelDate;
            recieveOrSenderCanCancel = streams[_id].recieveOrSenderCanCancel; 
        
            recipient = streams[_id].recipient;
            sender = streams[_id].sender;
            status = streams[_id].status; 
                    
            tokenAddress = streams[_id].tokenAddress;
            
            numberOfWithdraws = streams[_id].numberOfWithdraws;
            purpose = streams[_id].purpose;
        }

    //get withdraw parameters by id and number withdraw
       function getWithdrawParameters(uint256 _id, uint256 _numberOfWithdraw) external view returns (
            uint256 amount,
            uint256 withdrawTime
       )
       {
           
           amount = withdrawParameters[_id][_numberOfWithdraw].amount; 
           withdrawTime = withdrawParameters[_id][_numberOfWithdraw].withdrawTime;
       }




       function addStream(
           uint256 _id, 
           uint256 _deposit,         
           address _tokenAddress,
           uint64 _startTime,
           uint64 _stopTime,
           uint64 _blockDate,
           uint64 _cancelDate,
           uint8 _recieveOrSenderCanCancel,
           address _sender,
           address _recipient,
           uint8 _status, 
           string memory _purpose ) external onlyStreamContract{


        streams[_id] = Stream({
           deposit: _deposit,         
           tokenAddress: _tokenAddress,
           startTime: _startTime,
           stopTime: _stopTime,
           blockDate: _blockDate,
           cancelDate: _cancelDate,
           recieveOrSenderCanCancel: _recieveOrSenderCanCancel,
           sender: _sender,
           recipient: _recipient,
           status: _status,
           numberOfWithdraws: 0, 
           purpose: _purpose
           
               
       });
       }

       function addWithdraw(uint256 _id, uint256 _amount, uint256 _withdrawTime) external onlyStreamContract{
          streams[_id].numberOfWithdraws = ++streams[_id].numberOfWithdraws; 
          withdrawParameters[_id][streams[_id].numberOfWithdraws].amount = _amount;
          withdrawParameters[_id][streams[_id].numberOfWithdraws].withdrawTime = _withdrawTime;
       }


}