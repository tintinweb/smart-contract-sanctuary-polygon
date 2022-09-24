/**
 *Submitted for verification at polygonscan.com on 2022-09-22
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.2;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

// import "@opengsn/gsn/contracts/BaseRelayRecipient.sol";

// import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

// SPDX-License-Identifier:MIT
// solhint-disable no-inline-assembly

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

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise, return `msg.data`
     * should be used in the contract instead of msg.data, where the difference matters (e.g. when explicitly
     * signing or hashing the
     */
    function _msgData() internal virtual view returns (bytes memory);

    function versionRecipient() external virtual view returns (string memory);
}

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address public trustedForwarder;

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

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise, return `msg.data`
     * should be used in the contract instead of msg.data, where the difference matters (e.g. when explicitly
     * signing or hashing the
     */
    function _msgData() internal override virtual view returns (bytes memory ret) {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // we copy the msg.data , except the last 20 bytes (and update the total length)
            assembly {
                let ptr := mload(0x40)
                // copy only size-20 bytes
                let size := sub(calldatasize(),20)
                // structure RLP data as <offset> <length> <bytes>
                mstore(ptr, 0x20)
                mstore(add(ptr,32), size)
                calldatacopy(add(ptr,64), 0, size)
                return(ptr, add(size,64))
            }
        } else {
            return msg.data;
        }
    }
}


// OR MyContract is ERC2771Context
contract MyContract is BaseRelayRecipient {
  uint256 public _value;

  /**
   * Set the trustedForwarder address either in constructor or
   * in other init function in your contract
   */
  // OR constructor(address _trustedForwarder) public ERC2771Context(_trustedForwarder)
  constructor(address _trustedForwarder) public {
    trustedForwarder = _trustedForwarder;
  }

  /**
   * OPTIONAL
   * You should add one setTrustedForwarder(address _trustedForwarder)
   * method with onlyOwner modifier so you can change the trusted
   * forwarder address to switch to some other meta transaction protocol
   * if any better protocol comes tomorrow or the current one is upgraded.
   */

  function setTrustedForwarder(address _trustedForwarder) public {
    trustedForwarder = _trustedForwarder;
  }

  /**
   * Override this function.
   * This version is to keep track of BaseRelayRecipient you are using
   * in your contract.
   */
  function versionRecipient() external view override returns (string memory) {
    return "1";
  }

  /**
   * This is the function that will be called when someone calls
   * your contract via GSN. You can use msg.sender here as it will
   * be the actual sender of the transaction and not the GSN.
   */
  function setValue(uint256 value) public {
    _value = value;
  }

  function getValue() public view returns (uint256) {
    return _value;
  }

  /**
   * This is the function that will be called when someone calls
   * your contract via GSN. You can use msg.sender here as it will
   * be the actual sender of the transaction and not the GSN.
   */
}