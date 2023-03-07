/**
 *Submitted for verification at polygonscan.com on 2023-03-07
*/

/**
 gas on deploy 0.19 Matic // 2 898 950
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// interface of the History contract - dataBase

interface IHistory{

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

    

    function addUserId(address _user, uint256 _id ) external;


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
       
    ) external;
 
    function addWithdraw(uint256 _id, uint256 _amount) external;

    function addCancel (uint256 _id, uint256 _amount) external;

    function getHistoryStream(uint256 _id) external view returns(StreamHistory memory streamHistory);
}




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

abstract contract Pausable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        //_paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}













contract MyStream is Ownable, Pausable{
    
      
    
    // Variables
    IHistory public immutable history; 
    uint256 public nextStreamId;
    uint256 public  fee;
    
     constructor(address _history, uint _nextStreamId)  {
         require(_history != address(0), "zero address");
         require(_nextStreamId != 0, "Stream id is zero");
        history = IHistory(_history);
        fee = 100;
        nextStreamId = _nextStreamId;
    }
    
    //Mappings
    
    mapping(uint256 => Stream) private streams; 
    uint256 public contractFeeBalance;
    
    //Modifiers
    
     
    modifier onlySenderOrRecipient(uint256 streamId) {
        IHistory.StreamHistory memory s = IHistory(history).getHistoryStream(streamId);
        
        require(
            msg.sender == s.sender || msg.sender == s.recipient,
            "caller is not the sender/recipient"
        );
        _;
    }

    modifier onlyRecipient(uint256 streamId) {
        IHistory.StreamHistory memory s = IHistory(history).getHistoryStream(streamId);
        require(msg.sender == s.recipient,
            "caller is not the recipient"
        );
        _;
    }

   
    modifier streamExists(uint256 streamId) {
        require(streams[streamId].isEntity, "stream does not exist");
        _;
    }
    
    function exist(uint256 streamId) public view returns (bool){
        return streams[streamId].isEntity;
    }
    
    // Structs
    struct Stream{
        uint256 ratePerSecond;
        uint256 remainingBalance;
        uint256 remainder; 
        bool isEntity;
        
    }
    
       
      
    
    struct CreateStreamLocalVars {
        
        uint256 duration;
        uint256 ratePerSecond;
    }
    
    struct BalanceOfLocalVars {
        
        uint256 recipientBalance;
        uint256 withdrawalAmount;
        uint256 senderBalance;
    }
    
    
    
    // Events
   
      
        
    event withdrawFee(
        uint256 amount,
        address indexed reciver
    );


    
    function createStream(address recipient, uint256 startTime, uint256 stopTime, uint256 blockTime, uint8 whoCancel, string memory title) whenNotPaused external payable returns (uint256){
         
        uint256 deposit = msg.value - feeCharge(msg.value);
        

        if (startTime == 0){
            startTime = block.timestamp;
        }
        require (whoCancel < 4, "Invalid input");
        require(recipient != address(0), "stream to the zero address");
        require(recipient != address(this), "stream to the contract itself");
        require(recipient != msg.sender, "stream to the caller");
        require(deposit != 0, "deposit is zero");
        require(startTime >= block.timestamp, "startTime before block.timestamp");
        require(stopTime > startTime, "Invalid stop/start time");
        require (blockTime == 0 || blockTime <= stopTime, "Invalid blockTime");

        CreateStreamLocalVars memory vars;

        unchecked{
        vars.duration = stopTime - startTime;
        }

        /* Without this, the rate per second would be zero. */
        require(deposit >= vars.duration, "deposit smaller than time delta");

        /* This condition avoids dealing with remainders */
        //require(deposit % vars.duration == 0, "deposit not multiple of time delta");
        
        
        
        uint256 rem;
        
        if (deposit % vars.duration == 0){
            rem = 0;
        }
        
        else{
            rem = deposit % vars.duration;
            contractFeeBalance = contractFeeBalance + rem;
        }

        vars.ratePerSecond = deposit / vars.duration;
        
        
        /* Create and store the stream object. */
        uint256 streamId = nextStreamId;
        streams[streamId] = Stream({
            remainingBalance: deposit,
            isEntity: true,
            ratePerSecond: vars.ratePerSecond,
            remainder: rem
           
        });

        /* Increment the next stream id. */
        unchecked{
        nextStreamId = nextStreamId + 1;
        }
        
              
       
        addToHistory(
          streamId,
          recipient,
          msg.sender, 
          deposit, 
          startTime, 
          stopTime, 
          blockTime, 
          title,
          whoCancel
          

        );

        distribute(msg.sender, recipient);       
        
        return streamId;
    }

    function feeCharge (uint256 deposit) internal returns (uint256){// change to internal
        uint256 feeRate = calculateFee(deposit);
        uint256 feeAmount = deposit * feeRate / 10000;
        contractFeeBalance = contractFeeBalance + feeAmount;
        return feeAmount;
        
        
    }

    uint256 public fix = 15000 gwei;

    function setFix (uint256 newFix) external onlyOwner {
        // require();
        fix = newFix;
    }


   

    function distribute (address sender, address recipient) internal {
        contractFeeBalance = contractFeeBalance - (fix * 2);
        (bool success1, ) = sender.call{value: fix}("");//TODO
        require(success1, "Failed to send Ether");
        (bool success2, ) = recipient.call{value: fix}("");// TODO REENTRANCY
        require(success2, "Failed to send Ether");
    }
      
    
   function addToHistory (
       uint256 streamId, 
       address recipient,
       address sender, 
       uint256 deposit, 
       uint256 startTime, 
       uint256 stopTime, 
       uint256 blockTime, 
       string memory title,
       uint8 whoCancel
       ) internal{
      
      IHistory(history).addStream(
          streamId,
          recipient,
          sender, 
          deposit, 
          startTime, 
          stopTime, 
          blockTime, 
          title,
          whoCancel
          );
   }
   
  

    function getStream(uint256 id)external view returns(Stream memory stream){
    return streams[id];
    }

    
    
    function cancelStream(uint256 streamId)
        external
        streamExists(streamId)
        onlySenderOrRecipient(streamId)
        returns (bool)
    {
               
        
        cancelStreamInternal(streamId);
        
        return true;
    }
    
    
    function cancelStreamInternal(uint256 streamId) internal {
        //Stream memory stream = streams[streamId];
        IHistory.StreamHistory memory s = IHistory(history).getHistoryStream(streamId);
        
        uint256 period = s.startTime + s.blockTime;
        
        require (period <= block.timestamp,"stream not started");
        require (s.stopTime >= block.timestamp, "stream finished");
        
        if (msg.sender == s.sender && s.whoCancel != 1 && s.whoCancel != 3 ){
            return;
        }
        if (msg.sender == s.recipient && s.whoCancel  != 2 && s.whoCancel != 3){
            return;
        }
        
        
        uint256 senderBalance = balanceOf(streamId, s.sender);
        uint256 recipientBalance = balanceOf(streamId, s.recipient);
        

       // delete streams[streamId];

       history.addCancel(streamId, senderBalance);

       
             if (recipientBalance != 0){
               (bool success1, ) = s.recipient.call{value: recipientBalance}("");//TODO
               require(success1, "recipient transfer failure");
             }     
        
            
                       
         
            if (senderBalance != 0){
                (bool success1, ) = s.sender.call{value: senderBalance}("");//TODO
                require(success1, "recipient transfer failure");
            }
          

        
    }
    
    function balanceOf(uint256 streamId, address who) public view streamExists(streamId) returns (uint256 balance) {
        IHistory.StreamHistory memory s = IHistory(history).getHistoryStream(streamId);
        Stream memory stream = streams[streamId];
        BalanceOfLocalVars memory vars;

        uint256 delta = deltaOf(streamId);
        vars.recipientBalance = delta * stream.ratePerSecond;
       

        /*
         * If the stream `balance` does not equal `deposit`, it means there have been withdrawals.
         * We have to subtract the total amount withdrawn from the amount of money that has been
         * streamed until now.
         */
        if (s.deposit > stream.remainingBalance) {
            vars.withdrawalAmount = s.deposit - stream.remainingBalance;
            
            vars.recipientBalance = vars.recipientBalance - vars.withdrawalAmount;
            
        }

        if (who == s.recipient) return vars.recipientBalance;
        if (who == s.sender) {
            vars.senderBalance = stream.remainingBalance - vars.recipientBalance;
            
            return vars.senderBalance;
        }
        return 0;
    }
    
    function deltaOf(uint256 streamId) internal view streamExists(streamId) returns (uint256 delta) {
        
        IHistory.StreamHistory memory s = IHistory(history).getHistoryStream(streamId);
        
        if (block.timestamp <= s.startTime) return 0;
        
        if (block.timestamp < s.stopTime) return block.timestamp - s.startTime;
        
        return s.stopTime - s.startTime;
    }
    
    
    
    
    function withdrawFromStream(uint256 streamId, uint256 amount)
        external
        //whenNotPaused
        streamExists(streamId)
        onlyRecipient(streamId)
        returns (bool)
    {
        require(amount != 0, "amount is zero");
       
        IHistory.StreamHistory memory s = IHistory(history).getHistoryStream(streamId);
        uint256 balance = balanceOf(streamId, s.recipient);
        
        require(balance >= amount, "amount exceeds the available balance");
        address recipient = s.recipient;
        withdrawFromStreamInternal(streamId, amount, recipient);

        history.addWithdraw (streamId, amount); 
        
        return true;
    }
    
    function withdrawFromStreamInternal(uint256 streamId, uint256 amount,  address recipient) internal {
        Stream memory stream = streams[streamId];
        
        
        streams[streamId].remainingBalance = stream.remainingBalance - amount;
        

        if (streams[streamId].remainingBalance == 0) delete streams[streamId];
        
        (bool sent, ) = recipient.call{value: amount}("");
        require(sent, "Failed to send Ether");        
          
       
        
               
        
        
        
        
    }
    
     // Admin functions
     
    // WithDraw fees  
    
    function withdrawFeeForHolders(uint256 amount, address reciver) external onlyOwner returns (bool){
        require (amount <= contractFeeBalance);
        require(reciver != address(0));
        contractFeeBalance = contractFeeBalance - amount;
        (bool success, ) = reciver.call{value: amount}("");
        require(success, "Failed to send Ether");  
        
        emit withdrawFee (amount, reciver);
        return true;
    }
    
    
    uint256 x = 700;
    uint256 y = 200;
    uint256 z = 100;

    function changeFeeParameters(uint256 _x, uint256 _y, uint256 _z) external onlyOwner {
        require (_x != 0, "Zero parameter");
        require (_y != 0, "Zero parameter");
        require (_z != 0, "Zero parameter");
        x = _x;// fee 5 ether
        y = _y;// fee on 5 ether < value <= 50 ether
        z = _z;// fee more 50 ether
    }

    // Fee calculation depends on value

    function calculateFee(uint256 deposit) public view returns (uint256) {

        require(deposit >= 0.05 ether, "Small deposit");
        
        if (0.05 ether <= deposit && deposit <= 0.2 ether){
            return x;
            }
        else if (0.2 ether < deposit && deposit < 0.5 ether){
            return y;
        }

        else if (deposit >= 0.5 ether){
            return z;
        }
        
    } 
    
    
    
    
    
    
}