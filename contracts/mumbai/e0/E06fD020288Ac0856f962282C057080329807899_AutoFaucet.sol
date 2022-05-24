// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

import "@opengsn/contracts/src/BaseRelayRecipient.sol";

// import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

// OR MyContract is ERC2771Context

contract AutoFaucet is BaseRelayRecipient {
      uint256  public tokenAmount;
      uint256  public waitTime;
     address public owner;

     ERC20 public tokenInstance;
 mapping(address=>uint256) nextRequestAt;
  modifier onlyOwner() {
        require(owner == _msgSender(), "");
        _;
    }

    /** 
     * Set the trustedForwarder address either in constructor or 
     * in other init function in your contract
     */ 
// OR constructor(address _trustedForwarder) public ERC2771Context(_trustedForwarder)
    constructor(address _trustedForwarder){
        _setTrustedForwarder(_trustedForwarder);
       // require(_tokenInstance != address(0));
       tokenInstance = ERC20(0x0000000000000000000000000000000000001010);
       waitTime = 60;
       tokenAmount = 15000000000000000;
       owner = _msgSender();
    }
   

  function requestTokens() external payable {

        require(address(this).balance >= tokenAmount, "Not enough funds in the faucet. Please donate");
        //require(lastAccessTime[_msgSender()] < block.timestamp + waitTime, "Patience is a virtue. You already requested funds recently.");
       // require(allowedToWithdraw(_msgSender()));
        
        require(nextRequestAt[_msgSender()] < block.timestamp, "FaucetError: Patience is a virtue. You already requested funds recently.");
        
        // Next request from the address can be made only after 5 minutes         
        nextRequestAt[_msgSender()] = block.timestamp + waitTime; 
        
       payable(_msgSender()).transfer(tokenAmount);
        
                }

    /**
     * OPTIONAL
     * You should add one setTrustedForwarder(address _trustedForwarder)
     * method with onlyOwner modifier so you can change the trusted
     * forwarder address to switch to some other meta transaction protocol
     * if any better protocol comes tomorrow or the current one is upgraded.
     */
    
    /** 
     * Override this function.
     * This version is to keep track of BaseRelayRecipient you are using
     * in your contract. 
     */
     function setTrustForwarder(address _trustedForwarder) public onlyOwner {
        _setTrustedForwarder(_trustedForwarder);
    }


 function versionRecipient() external pure override returns (string memory) {
        return "1";
    }
    
   function setTokenAmount(uint256 _amount) external onlyOwner {
       tokenAmount = _amount;
       }

   function changeWait(uint256  _wait) external onlyOwner  {
      waitTime = _wait;
   }



   // function allowedToWithdraw(address _address) public view returns (bool) {
      //  if(lastAccessTime[_address] == 0) {
       //     return true;
     //   } else if(block.timestamp >= lastAccessTime[_address]) {
     //       return true;
     //   }
     //   return false;
   // }
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal virtual view returns (bytes calldata);

    function versionRecipient() external virtual view returns (string memory);
}

// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;

import "./interfaces/IRelayRecipient.sol";

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    function trustedForwarder() public virtual view returns (address){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}