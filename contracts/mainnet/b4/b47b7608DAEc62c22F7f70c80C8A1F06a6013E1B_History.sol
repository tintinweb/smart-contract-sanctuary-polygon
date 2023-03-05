/**
 *Submitted for verification at polygonscan.com on 2023-03-05
*/

// SPDX-License-Identifier: MIT 
pragma solidity 0.8.17;// 1 726 745 gas

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

interface IStream{
    struct Stream{
        uint256 ratePerSecond;
        uint256 remainingBalance;
        uint256 remainder; 
        bool isEntity;
    }

    function getStream(uint256 id) view external returns (Stream memory stream); 
}

// УСТАНОВИТЬ КОНТРАКТ TREAM!!!
contract History is Ownable{

    IStream public streamContract;
    
    
    

    function changeStreamContract(address _newStreamContract) external onlyOwner{
        require (_newStreamContract != address(0), "Zero address");
        streamContract = IStream(_newStreamContract);
    }

    modifier onlyStreamContract{
        require( msg.sender == address(streamContract), "Access is denied");
            _;

    }

    // get all id by address
    mapping (address => uint256[]) private addressIds; 

    function getNumberOfArray(address _user) external view returns(uint256){
      return addressIds[_user].length;
    }

     

    //  get parameters of stream
    mapping(uint256 => StreamHistory) public streams;//id -> struct 
    
    // get withDraw parameters
    mapping (uint256 => mapping(uint256 => WithDraw)) public withdraws;

    struct WithDraw{
            uint256 amount;
            uint256 timeW;
        }

    struct StreamHistory {
            
            uint256 deposit;
            
            uint256 startTime;
            uint256 stopTime;
            uint256 blockTime;
            uint256 cancelTime;

            uint256 recipientAmountOnCancel;

            
            address sender;
            uint32 numberOfWithdraws;

            address recipient;
            uint8 status; //1 canceled, 2 paused
            uint8 whoCancel; 
            
            string purpose;
            
        }



// add Stream parameters to history storage
        function addStream(
            uint256 streamId, 
            address recipient,
            address sender, 
            uint256 deposit, 
            uint256 startTime, 
            uint256 stopTime, 
            uint256 blockTime, 
            string memory title,
            uint8 whoCancel
            
        ) external onlyStreamContract  {
                   
            

            streams[streamId] = StreamHistory({
            deposit: deposit,
            recipientAmountOnCancel: 0,
            whoCancel: whoCancel,
            startTime: startTime,
            stopTime: stopTime,
            blockTime: blockTime,
            cancelTime: 0,
            sender: sender,
            recipient: recipient,
            status: 0, //1 canceled, 2 paused
            purpose: title,
            numberOfWithdraws: 0
             
            });
            addUserId(sender, streamId);
            addUserId(recipient, streamId);
            
            
        }

        function getHistoryStream(uint256 _id) external view returns(StreamHistory memory streamHistory){
            return streams[_id];
        }

           

        // add only WithDraw parameters to history storage by id
        function addWithdraw(uint256  _id, uint256 _amount) external onlyStreamContract {
            streams[_id].numberOfWithdraws = streams[_id].numberOfWithdraws + 1;
            withdraws[_id][streams[_id].numberOfWithdraws] = WithDraw({amount: _amount, timeW: block.timestamp});
            
            } 

        
     

       function addCancel (uint256 _id, uint256 _amount) external onlyStreamContract{
             streams[_id].status = 1;
             streams[_id].cancelTime = block.timestamp;
             streams[_id].recipientAmountOnCancel = _amount;

       }

       function addUserId(address _user, uint256 _id ) internal onlyStreamContract {
          addressIds[_user].push(_id); 
       }

       

}