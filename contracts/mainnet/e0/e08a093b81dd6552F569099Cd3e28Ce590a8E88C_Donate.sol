/**
 *Submitted for verification at polygonscan.com on 2022-06-20
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}
pragma solidity ^0.8.0;

 
contract Donate is ReentrancyGuard  {
    

    modifier isOwner() {    
        require(msg.sender == owner, "restricted");
        _;
    }

    modifier legitAddress(address payable _address){
        require(_address.send(0), "address invalid");
        require(recievers[ _address] != 1, "address already registered");
        require(recievers[ _address] != 2, "address is suspended");
        require(recievers[ _address] != 3, "address is banned");
        _; 
    }
    

    event addStatus(
        address reciever,
        bool status    
    );
    event releaseFund(
        address fundreciever,
        uint256 value
    );
    event inTx(
        address donater,
        uint256 amount
    );
 
    mapping(uint256 => address payable) private id ;
    mapping(address => uint256) public recievers ; 

    address private owner;
 
    uint256 public totalReciever;
    uint256 public totalDonation;

    uint256 private _reciever;
    uint256 public thresholdValue;

    uint256 public time; 
    uint256 public releaseTime;
 
 
    constructor() ReentrancyGuard() {
        owner = msg.sender;
        Time();
    }
   
    receive() payable external{
        totalDonation += msg.value;
        emit inTx(msg.sender, msg.value);    
    }


        function TransferOwnership ( address newOwner) external isOwner{
            owner = newOwner;
        }
        
        function Time() private {
            time = block.timestamp;
            releaseTime = block.timestamp + 1 days;
        }
 
        function SetValue( uint256 _threshold ) external isOwner{
            thresholdValue = _threshold;
        }

        function AvailableReciever() public view returns(uint256){
            uint256 _availablereciever;
            for (uint i = 0; i < _reciever; i++){  
                if  (recievers[id[i]] == 1){
                    _availablereciever ++; 
                }  
             }
             return _availablereciever;   
        }
       
        
        function AddReciever ( address payable _address ) external legitAddress(_address) {
                id[_reciever] = _address;
                recievers[_address] = 1;                
                _reciever++;
                totalReciever++;                
                emit addStatus(id[_reciever], true);
        }
 


        function  Release() nonReentrant() external {
            require (address(this).balance > thresholdValue, "Wait for the minimum amount");
            require (block.timestamp > releaseTime, "Wait for 24 hours");
            
            uint256 _availablereciever = AvailableReciever();
            
            require (_availablereciever > 1, "not enough reciever");

            uint netAmount;

            if( _availablereciever != 0){

                netAmount = (address(this).balance)/ _availablereciever;
            }
            require (netAmount > 0 , "Value to small");
            
            address payable empty;

             for (uint256 i = 0; i < _reciever; i++){  
                if  (recievers[id[i]] == 1){
                    id[i].transfer(netAmount);
                    emit releaseFund(id[i], netAmount);
                    recievers[id[i]] = 0; 
                }                
                id[i] = empty;
             }
            _reciever = 0;
            Time();
        }

        
        function Suspend( address _address, uint256 status ) external isOwner{
            recievers[_address] = status;
        }

        function end () external isOwner{
            address payable empty;
            selfdestruct(empty);
        }
    
}