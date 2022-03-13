/**
 *Submitted for verification at polygonscan.com on 2022-03-13
*/

// File: @chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol


pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easilly be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// File: @chainlink/contracts/src/v0.8/KeeperBase.sol


pragma solidity ^0.8.0;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// File: @chainlink/contracts/src/v0.8/KeeperCompatible.sol


pragma solidity ^0.8.0;



abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: Escrow.sol

// contracts/GameItems.sol




pragma solidity ^0.8.0;



contract Escrow is KeeperCompatibleInterface {
    struct Agreement {
        string agreementId;
        address buyer;
        address seller;
        uint256 deadline;
        string file;
        uint256 amount;
        AgreementState currState;
        bool exist;
                 
    }


    string[] allAgreements; 
    mapping (string => Agreement) agreements;

    enum AgreementState { NOT_INITIATED, Created, Accepted , Cancelled ,SellerMissedDeadLine, BuyerMissedDeadLine,SellerUploadedFiles,BuyerRejected, Completed}
    event AgreementCreated(string agreementId,address buyer,address seller,uint256 amount,uint256 dateCreated);
    event AgreementAccepted(string agreementId,address seller,uint256 dateAccepted);
    event AgreementCancelled(string agreementId,uint256 dateCancelled);
    event SellerMissedDeadLine(string agreementId,uint256 dateMissed);
    event BuyerMissedDeadLine(string agreementId,uint256 dateMissed);
    event SellerUploadedFiles(string agreementId,string file,uint256 dateUploaded);
    event BuyerRejected(string agreementId,uint256 dateReject);
    event AgreementCompleted(string agreementId,uint256 dateCompleted);
    
    address USDC_ADDRESS = address(0x2058A9D7613eEE744279e3856Ef0eAda5FCbaA7e); //Polygon USDC
    IERC20 internal usdcToken;
    

     /**
   * @dev Modifier isAgreement. Make sure details exist for agreement
   * @param   agreementId  
   **/	  
	  
    modifier isAgreement (string memory agreementId){
	
	  require(agreements[agreementId].exist == true, "Agreement does not exist.");
    
   _; 
 }

/**
   * @dev Modifier isNotAgreement. Make sure details doesn't exist for agreement
   * @param   agreementId  
   **/	  
	  
    modifier isNotAgreement (string memory agreementId){
	
	  require(agreements[agreementId].exist == false, "Agreement exist.");
    
   _; 
 }
     /**
   * @dev Modifier isBuyer. Make sure only buyer can run function
   * @param   agreementId  
   **/	  
	  
    modifier isBuyer (string memory agreementId){
	
	  require(agreements[agreementId].exist == true, "Agreement does not exist.");
      require(agreements[agreementId].buyer == msg.sender, "Only Buyer can run this.");
      
   _; 
 }


 /**
   * @dev Modifier isSeller. Make sure only seller can run function
   * @param   agreementId  
   **/	  
	  
    modifier isSeller (string memory agreementId){
	
	  require(agreements[agreementId].exist == true, "Agreement does not exist.");
      require(agreements[agreementId].seller == msg.sender, "Only Seller can run this.");
      
   _; 
 }



     constructor() {
      usdcToken =   IERC20(USDC_ADDRESS);

    }


    //Create Agreement
 function createAgreement(string calldata agreementId,address seller, uint256 deadline,uint256 amount) isNotAgreement(agreementId) public
 {
     require(deadline > block.timestamp,"Date must be in the future");
     require(usdcToken.balanceOf(msg.sender) >= amount*10**6,"Not enough balance");

     agreements[agreementId].exist = true;
     agreements[agreementId].agreementId  = agreementId;
     agreements[agreementId].deadline = deadline;
     agreements[agreementId].amount = amount*10**6; 
     agreements[agreementId].buyer = msg.sender;
     agreements[agreementId].seller = seller;

     agreements[agreementId].currState = AgreementState.Created;
     allAgreements.push(agreementId);
     usdcToken.transferFrom(msg.sender,address(this),amount*10**6);
     emit AgreementCreated(agreementId,msg.sender,seller, amount,block.timestamp);


 }
    //Accept Agreement

  function acceptAgreement(string calldata agreementId) isAgreement(agreementId) isSeller(agreementId)  public
 {
     require(agreements[agreementId].currState == AgreementState.Created,"You cannot accept this agreement.");
     agreements[agreementId].currState = AgreementState.Accepted;
     emit AgreementAccepted(agreementId,msg.sender,block.timestamp);
 }   
 
  //Cancel Agreement
 function cancelAgreement(string calldata agreementId) isAgreement(agreementId) isBuyer(agreementId)  public
 {
     require(agreements[agreementId].currState == AgreementState.Created,"You cannot cancel this agreement.");
     agreements[agreementId].currState = AgreementState.Cancelled;
     usdcToken.transfer(msg.sender,agreements[agreementId].amount);
     emit AgreementCancelled(agreementId,block.timestamp);
 } 

//Seller Upload Files
function uploadFiles(string calldata agreementId,string calldata file) isAgreement(agreementId) isSeller(agreementId)  public
 {
     require(agreements[agreementId].currState == AgreementState.Accepted,"You cannot upload files.");
     require(agreements[agreementId].deadline > block.timestamp,"Deadline has past");
     agreements[agreementId].currState = AgreementState.SellerUploadedFiles;
     agreements[agreementId].file = file;

     //Send 25 % to Seller 
     uint256 amount  = (agreements[agreementId].amount/1000)*250;
     usdcToken.transfer(msg.sender,amount);
     emit SellerUploadedFiles(agreementId,file,block.timestamp);
 }

    //Buyer Reject 

  function rejectAgreement(string calldata agreementId) isAgreement(agreementId) isBuyer(agreementId)  public
 {
     require(agreements[agreementId].currState == AgreementState.SellerUploadedFiles,"You cannot reject this agreement.");
     require(agreements[agreementId].deadline > block.timestamp,"Deadline has past");

     agreements[agreementId].currState = AgreementState.BuyerRejected;
    
    //Send 75 % to Buyer 
     uint256 amount  = (agreements[agreementId].amount/1000)*750;
     usdcToken.transfer(msg.sender,amount);   
     emit BuyerRejected(agreementId,block.timestamp);
 } 

  //Complete Agreement

  function completeAgreement(string calldata agreementId) isAgreement(agreementId) isBuyer(agreementId)  public
 {
     require(agreements[agreementId].currState == AgreementState.SellerUploadedFiles,"You cannot reject this agreement.");
     require(agreements[agreementId].deadline >  block.timestamp,"Deadline has past");

     agreements[agreementId].currState = AgreementState.Completed;
    
    //Send 75 % to Seller 
     uint256 amount  = (agreements[agreementId].amount/1000)*750;
     usdcToken.transfer(agreements[agreementId].seller,amount);   
     emit AgreementCompleted(agreementId,block.timestamp);
 } 
    
    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory /* performData */) {
       for(uint256 loop=0;loop < allAgreements.length;loop++)
       {
           //check if agreement deadline reached and Files not uploaded
           if( agreements[allAgreements[loop]].currState == AgreementState.Accepted && block.timestamp >  agreements[allAgreements[loop]].deadline )     
           {
               return(true,abi.encode(loop));
           }      


             //check if agreement deadline reached and Files not approved by Buyer
           if( agreements[allAgreements[loop]].currState == AgreementState.SellerUploadedFiles && block.timestamp >  agreements[allAgreements[loop]].deadline )     
           {
               return(true,abi.encode(loop));
           }  
       }

       return(false,bytes(""));

    }

    function performUpkeep(bytes calldata performData) external {
      uint256 _agreementId = abi.decode(performData, (uint256));

           //check if agreement deadline reached and Files not uploaded
           if( agreements[allAgreements[_agreementId]].currState == AgreementState.Accepted && block.timestamp >  agreements[allAgreements[_agreementId]].deadline )     
           {
               //Send 75 % to Buyer 
              uint256 amount  = (agreements[allAgreements[_agreementId]].amount/1000)*750;
              usdcToken.transfer(agreements[allAgreements[_agreementId]].buyer,amount); 
              agreements[allAgreements[_agreementId]].currState  = AgreementState.SellerMissedDeadLine;  
              emit SellerMissedDeadLine(agreements[allAgreements[_agreementId]].agreementId,block.timestamp);
    
           }

          //check if agreement deadline reached and Files not approved by Buyer
           if( agreements[allAgreements[_agreementId]].currState == AgreementState.SellerUploadedFiles && block.timestamp >  agreements[allAgreements[_agreementId]].deadline )     
           {

              //Send 75 % to Seller 
              uint256 amount  = (agreements[allAgreements[_agreementId]].amount/1000)*750;
              usdcToken.transfer(agreements[allAgreements[_agreementId]].seller,amount); 
              agreements[allAgreements[_agreementId]].currState  = AgreementState.BuyerMissedDeadLine;  
              emit BuyerMissedDeadLine(agreements[allAgreements[_agreementId]].agreementId,block.timestamp);
    
           } 

    }


}