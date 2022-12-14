/**
 *Submitted for verification at polygonscan.com on 2022-12-14
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: contracts/accessRegistryContract.sol


pragma solidity ^0.8.9;


contract AccessRegistryContract {
    using SafeMath for uint256;

    // events

    event ownerAddition(address indexed owner);
    event OwnersRequired(uint256 indexed requiredOwners);
    event ownerDiscarded(address indexed _renounceOwner);
    event TxAdded(uint256 indexed txId);
    event Deposit(uint256 indexed value,address indexed sender);
    event Approve(uint256 indexed txId,address indexed approval);
    event Executed(uint256 indexed txId);
    event Revoked(address indexed revoker,uint256 indexed txId);

    address public admin;
    address[] public owners;  
    mapping(address => bool) public  isOwner; 
    uint256 public requiredOwners;                   //required owners for approval of transactions

/*   
   minimum of three owners need to be the owners of wallet */

    constructor(address[] memory _owners){
        admin=msg.sender;
       
        require(_owners.length >= 3 ,"Minimum of three owners are required");
        /* Copying the neew owners to original owners array */
        
        for(uint256 i=0; i < _owners.length ; i++ ){
            owners.push(_owners[i]);
        }
        
        /* marking true of such address who are owners */
        
        for(uint256 i=0 ;i<_owners.length; i++){
            isOwner[_owners[i]]=true;
        }
       
       
        uint256 num = SafeMath.mul(owners.length,60);
        requiredOwners = SafeMath.div(num,100);

    }

    /*   Modifiers    */
    modifier NotUnknown(address caller){
        require(caller!=address(0),"Unknown address ");
        _;
    }

    modifier OnlyAdmin(){
        require(msg.sender==admin , " Not admin of the contract");
        _;
    }

    modifier OnlyOwner(address owner){
        require(isOwner[owner] , " Not Owner of the wallet");
        _;
    }

    modifier NotOwner(address notowner){
        require( !isOwner[notowner], " address is Owner of the wallet");
        _;
    }

    /*

    Public functions 
    
    */

    function addOwners(address _owner) public OnlyAdmin NotOwner(_owner) NotUnknown(msg.sender) {
    //  require(msg.sender!=address(0)," Unknown caller ");
        owners.push(_owner);
        isOwner[_owner]=true;
        //emiting the event for new owner addition
        emit ownerAddition(_owner);

        //calling the internal function to update the requiredowners for approval of any transaction
        ownersUpdate(owners);

    }

    function renounce(address _renounceOwner) public OnlyAdmin OnlyOwner(_renounceOwner) NotUnknown(msg.sender)
    NotUnknown(_renounceOwner){
        uint256 index;
        for(uint256 i=0; i < owners.length ; i++){
         
            if(owners[i]==_renounceOwner){
               index=i;
               break;                
            }
        }
        owners[index]=owners[owners.length-1];
        owners.pop();
        isOwner[_renounceOwner]=false;
         
        // emiting an event for discarding the owner 
        emit ownerDiscarded(_renounceOwner);
        ownersUpdate(owners);
    }

    function transferSignature(address _from,address _to) public OnlyOwner(_from) NotOwner(_to) OnlyAdmin
    NotUnknown(_from) NotUnknown(_to){

        for(uint256 i=0 ;i < owners.length ;i++){
            if( owners[i]==_from ){

                owners[i]=_to;
            }
        }
        isOwner[_from]=false;
        isOwner[_to]=true;

        emit ownerDiscarded(_from);
        emit ownerAddition(_to);
    }

    /* Internal functions */
    
    function ownersUpdate(address[] memory _owners) internal {

        uint num = SafeMath.mul(_owners.length,60);
        requiredOwners = SafeMath.div(num , 100);
        
        emit OwnersRequired(requiredOwners);

    } 

}


// File: contracts/MULTisigWallet.sol



pragma solidity ^0.8.9;



interface Iaccess{
    function addOwners(address _owner) external ;
    function renounce(address _renounceOwner) external;
    function transferSignature(address _from,address _to) external;
    function approve(uint _txId) external; 
    function execute(uint256 _txId) external;
    function revoke(uint256 _txId) external;
}


contract MultiSig is AccessRegistryContract {
    using SafeMath for uint256;
    struct Transaction{
        address to;
        uint256 value;
        bytes data;
        bool execute;
    }

    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public approved; 
   
    fallback() external payable {
       require(msg.value > 0, "Amount must be greater than zero.");
       emit Deposit(msg.value, msg.sender);
    }

    receive() payable external{
        require(msg.value > 0,"pay some ether");
        emit Deposit(msg.value,msg.sender);
    }

    modifier Onlyowner(){
           require(isOwner[msg.sender],"not owner");
           _;      
    }
    modifier txexist(uint tx_id){
           require(tx_id>=0 && tx_id<transactions.length,"transaction doesnot exist");
           _;  
    }
    modifier txNotapproved(uint tx_id){
        require(!approved[tx_id][msg.sender],"transaction already approved by you");
        _;
    }
    modifier txNotexecuted(uint tx_id){
        require(!transactions[tx_id].execute,"transaction alreadry executed");
        _;
    }
    /*[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,
       0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
       0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db]
    
    */

    constructor(address[] memory _owners) AccessRegistryContract(_owners) {}

    /*
    [0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7,10000000000000000000,0x00]
    */

    function addTransaction(address _to,uint256 _value,bytes memory _data)
        public Onlyowner{
            transactions.push(Transaction({
                                           to: _to,
                                           value: _value,
                                           data: _data,
                                           execute: false
                                    }));
            emit TxAdded(transactions.length-1);

    }
    //0x17F6AD8Ef982297579C203069C1DbfFE4348c372,1000000000000000000,0x00
    function approve(uint256 _txId) public Onlyowner txexist(_txId) txNotexecuted(_txId) txNotapproved(_txId){

        approved[_txId][msg.sender]=true;
        emit Approve(_txId,msg.sender);
    }

    function getNoofapproval(uint256 _txId) private view returns(uint256 count){
        for(uint256 i=0; i < owners.length ;i++){
            
            if( approved[_txId][msg.sender])  count++;

        }
    }

    function execute(uint256 _txId) public Onlyowner txexist(_txId) txNotexecuted(_txId){

        require(getNoofapproval(_txId)>=requiredOwners,"Not enough approval");
        Transaction storage transaction = transactions[_txId];
        transaction.execute = true;
        (bool success, )=transaction.to.call{value:transaction.value}(transaction.data);
        require(success,"transaction failed");
     
        emit Executed(_txId);

    }

    function revoke(uint256 _txId) public Onlyowner txexist(_txId) txNotexecuted(_txId){

        require(approved[_txId][msg.sender]==true,"already Not approved");
        approved[_txId][msg.sender]=false;

        emit Revoked(msg.sender,_txId);

    } 
    //[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db]
   //[0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7,10000000000000000000,0x00]
}