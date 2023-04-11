/**
 *Submitted for verification at polygonscan.com on 2023-04-11
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: newtoken.sol


pragma solidity ^0.8.8;
pragma abicoder v2;

interface ERC20 {
    function totalSupply() external view returns (uint theTotalSupply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}
contract ENVO_migration is Ownable{
     address public contractAddr = address(this);
    
 
   
    uint256 i=0;
   
  
 
mapping(address => uint) public userStake;
mapping(address => mapping(uint => bool)) public monthlyClaim;
mapping(address => mapping(uint => uint)) public monthlylimit;
mapping(address => mapping(uint => uint)) public timeforClaim;
    address  buytokenAddr = 0x383E1C3EA636F0ffc13464B275282B3641fe4c4b; //gsvp
  


    function swapTostake( uint _numberOftokens )  public {
        require(_numberOftokens > 0,"please enter the correct amount!");
         uint amount = userStake[msg.sender];
        ERC20 sendtoken = ERC20(buytokenAddr);
        ERC20 receiveToken = ERC20(0x776A48AD9323050E39089dC97709b1028d7F5fA5);///Testnet gsvp
    require(sendtoken.balanceOf(address(this)) > _numberOftokens, "Insufficient contract balance");
     require(receiveToken.balanceOf(msg.sender) > _numberOftokens, "Insufficient user balance");
        uint tokenAmount = _numberOftokens * 1000000000000000000;   
 userStake[msg.sender]= tokenAmount + amount;
       uint months= 10;
       uint d =0;
       for ( d = 0 ;  d <= months; d++ ){
           uint monthlyAmount = tokenAmount / 10;
           if(monthlyClaim[msg.sender][d] == false){
  monthlylimit[msg.sender][d]=monthlyAmount; 
           }
           uint time = timeforClaim[msg.sender][d];
           
           timeforClaim[msg.sender][d]= block.timestamp + time + 1 minutes;
       }
       
      receiveToken.transferFrom(msg.sender, contractAddr, tokenAmount);
    }
    function claim () public {
        uint c = 0;
        for( c ; c <= 10 ; c++){
            if(monthlyClaim[msg.sender][c] != true){
                require(block.timestamp > timeforClaim[msg.sender][c] , "You havn't reached the claim date yet!");
               uint TokenAmount2 = monthlylimit[msg.sender][c];
               ERC20 sendtoken = ERC20(buytokenAddr);
                 bool isTransfered =  sendtoken.transfer(msg.sender, TokenAmount2);
                
            }

        }
    }
         function Token1Withdraw( uint TokenAmount) public onlyOwner{
require(TokenAmount > 0,"please enter the correct amount!");
ERC20  sendtoken= ERC20(0x776A48AD9323050E39089dC97709b1028d7F5fA5);//EnvoAddress
    require(sendtoken.balanceOf(address(this)) > TokenAmount, "Insufficient contract balance");
     uint TokenAmount2 = TokenAmount * 1000000000000000000;
          bool isTransfered =  sendtoken.transfer(msg.sender, TokenAmount2);
         }
         function Token2Withdraw( uint TokenAmount) public onlyOwner{
require(TokenAmount > 0,"please enter the correct amount!");
ERC20  sendtoken=ERC20(buytokenAddr);//gsvpAddress
    require(sendtoken.balanceOf(address(this)) > TokenAmount, "Insufficient contract balance");
     uint TokenAmount2 = TokenAmount * 1000;
          bool isTransfered =  sendtoken.transfer(msg.sender, TokenAmount2);
         }







        function withdraw() public onlyOwner {
    uint256 amount = address(this).balance;
    require(amount > 0, "Nothing to withdraw; contract balance empty");

    address _owner = owner();
    (bool sent, ) = _owner.call{value: amount}("");
    require(sent, "Failed to send Ether");
  }

  // Function to receive Ether. msg.data must be empty
  receive() external payable {}

  // Fallback function is called when msg.data is not empty
  fallback() external payable {}
   


}