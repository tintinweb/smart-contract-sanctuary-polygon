/**
 *Submitted for verification at polygonscan.com on 2022-03-05
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

pragma solidity 0.8.12;

 
contract donate is ReentrancyGuard  {
    

    modifier isOwner() {    
        require(msg.sender == owner, "restricted");
        _;
    }
    modifier legitAddress(address payable _address){
        _address.transfer(0);
        require(recivers[ _address] != 1, "address already registered");
        require(recivers[ _address] != 2, "address is suspended");
        require(recivers[ _address] != 3, "address is banned");
        _; // execute fx 
    }
    

    event addStatus(
        address reciver,
        string status    
    );
    event releaseFund(
        address fundReciver,
        uint value
    );
    event inTx(
        address donater,
        uint amount
    );
    event orgTx(
        uint value,
        uint time
    );
 
    mapping(uint => address payable) public id ;
    mapping(address => uint) public recivers ; // 0-not registered 1-active 2-suspended 3-inactive

    address public owner;
    address payable orgWallet;
 
    uint public totalReciver;
    uint public thresholdValue;
    uint256 public time; 
    uint256 public releaseTime;
 
 
    constructor(address payable _Wallet) ReentrancyGuard() {
        owner = msg.sender;
        orgWallet = _Wallet;
        thresholdValue = 100;
        Time();
    }
   
    receive() payable external{
        emit inTx(msg.sender, msg.value);    
    }


        function transferOwnership (address newOwner) public isOwner{
            owner = newOwner;
        }
        function trasferOrgwallet (address payable newWallet) public isOwner{
            orgWallet = newWallet;
        }

        function Time() private {
            time = block.timestamp;
            releaseTime = block.timestamp + 1 days;
        }

        function currentBalance()view public returns (uint){
            return address(this).balance;
        }
 
        function setValue(uint _threshold) public isOwner{
            require (_threshold > 100, "Need more than 100");
            thresholdValue = _threshold;
        }

        function availableReciver() public view returns(uint256){
            uint _availableReciver;
            for (uint i = 0; i < totalReciver; i++){  
                if  (recivers[id[i]] == 1){
                    _availableReciver ++; 
                }  
             }
             return _availableReciver;   
        }
       
        
        function addReciver (address payable _address) public legitAddress(_address) {

            if (recivers[ _address] == 0){
                id[totalReciver] = _address;
                recivers[_address] = 1;                
                totalReciver++;                
                emit addStatus(id[totalReciver], "address active");

            }else{
                emit addStatus(_address, "address registration error");
            }

        }
 


        function  release() nonReentrant() public {
            require (address(this).balance > thresholdValue, "Wait for the minimum amount");
            require (block.timestamp > releaseTime, "Wait for 24 hours");
            
            uint _availableReciver = availableReciver();
            
            require (_availableReciver > 1, "not enough reciver");


            uint orgAmount = (address(this).balance / 100)*2;
            uint netAmount;

            if( _availableReciver != 0){

                netAmount = (address(this).balance - orgAmount)/ _availableReciver;
            }
            require (netAmount > 0 , "Value to small");

            orgWallet.transfer(orgAmount);
            emit orgTx(orgAmount,block.timestamp);
            
            address payable empty;

             for (uint i = 0; i < totalReciver; i++){  
                if  (recivers[id[i]] == 1){
                    
                    emit releaseFund(id[i], netAmount);
                    id[i].transfer(netAmount);
                    recivers[id[i]] = 0; 
                }                
                id[i] = empty;
             }
            totalReciver = 0;
            Time();

         
        }

        function suspend(address _address, uint256 status) public isOwner{
            recivers[_address] = status;
        }

        function END () external isOwner{
            address payable empty;
            selfdestruct(empty);
        }
    
}