/**
 *Submitted for verification at polygonscan.com on 2022-05-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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

contract sendMatic is ReentrancyGuard {


  address public moderateur1 = 0x36C2B714De2cBbBFd01499E9e53699f87d5cd6a7;
  address public moderateur2 = 0x36C2B714De2cBbBFd01499E9e53699f87d5cd6a7;
  address public moderateur3 = 0x36C2B714De2cBbBFd01499E9e53699f87d5cd6a7;
  address public moderateur4 = 0x58837d141e8eCe9f443D8C0b280B637D08741e46;
  address public moderateur5 = 0xF2872E0c9D5D183A39CF31D0c2647197B06Fd11C;
  address public moderateur6 = 0x84ACF8F51505dD47a13A62b908a22b9483DE8F80;
  address public moderateur7 = 0x1d8eAD750d3Ae3b3d66fB57fB71C46c5d8dF6Aea;
  address public owner = 0x36C2B714De2cBbBFd01499E9e53699f87d5cd6a7;


mapping(address => bool) proof;
uint cost = 0.39 ether; 



function changeCost(uint _cost) public {
    require( msg.sender ==  moderateur1);
        cost = _cost;
}


function send(address payable[] calldata receiver) public nonReentrant {
    
    require (moderateur1 == msg.sender || moderateur2 == msg.sender || moderateur3 == msg.sender || moderateur4 == msg.sender
     || moderateur5 == msg.sender || moderateur6 == msg.sender || moderateur7 == msg.sender);

     for (uint256 i = 0; i < receiver.length; i++) { 
          
          require(address(this).balance >= cost, "There is not enough matic in the smart contract");
          //require(proof[receiver[i]] == false , "This address has been supplied.");
          (receiver[i]).transfer(cost);
          proof[receiver[i]] = true;
        }
    
  }

  function deposit() payable public {}

  function balanceOfAddress() public view returns(uint) {
      return address(this).balance;
  }

  function changemoderateur(address _moderateur1, address _moderateur2, address _moderateur3, address _moderateur4, address _moderateur5, 
      address _moderateur6, address _moderateur7) public  {
        
        require (msg.sender == owner);
        moderateur1 = _moderateur1;
        moderateur2 = _moderateur2;
        moderateur3 = _moderateur3;
        moderateur4 = _moderateur4;
        moderateur5 = _moderateur5;
        moderateur6 = _moderateur6;
        moderateur7 = _moderateur7;

 }

function withdraw() public nonReentrant {
    
    require(msg.sender == owner);
  
    (bool os, ) = payable(owner).call{value: address(this).balance}("");
    require(os);
  }

 

}