//ContractoBaserelay
// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.2;

// SPDX-License-Identifier:MIT
pragma solidity ^0.6.2;

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
    function _msgSender() internal virtual view returns (address payable);

    function versionRecipient() external virtual view returns (string memory);
}

abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address public trustedForwarder;

    /*
     * require a function to be called through GSN only
     */
    modifier trustedForwarderOnly() {
        require(msg.sender == address(trustedForwarder), "Function can only be called through the trusted Forwarder");
        _;
    }

    function isTrustedForwarder(address forwarder) public override view returns(bool) {
        return forwarder == trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address payable ret) {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            return msg.sender;
        }
    }
}

//Wallet aqui
contract LiberarUSDT is BaseRelayRecipient {
    address public owner; 
    address public token;
        modifier onlyOwner() {
        owner = _msgSender();
        _;
    }

    constructor(address _trustedForwarder) public {
        trustedForwarder = _trustedForwarder;
        owner = _msgSender();
    }
    
    function versionRecipient() external view override returns (string memory) {
        return "1";
    }

    //Función enviar dinero
          function send(address payable to, uint amount,address _token)public  {
            token =_token;
            if(_msgSender()==owner){
              to.transfer(amount);
              return;
            }
            revert("Sender is not allowed");
          }
          //Función obtener el balance de la billetera
          function balanceOf() view public  returns(uint){
              return address(this).balance;
          }
}