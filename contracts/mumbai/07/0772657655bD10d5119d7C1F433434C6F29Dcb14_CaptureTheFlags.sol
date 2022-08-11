// SPDX-License-Identifier: none
pragma solidity ^0.8.9;

import "../Abstracts/BaseRelayRecipient.sol";

contract CaptureTheFlags is BaseRelayRecipient {
  event FlagCaptured(address previousHolder, address currentHolder);

  constructor(address forwarder_) {
    _setTrustedForwarder(forwarder_);
  }

  address public currentHolder = address(0);
  
  function captureTheFlags() external {
    address previousHolder = currentHolder;
    currentHolder = _msgSender();
    emit FlagCaptured(previousHolder, currentHolder);
  }
}

import "../Interfaces/IRelayRecipient.sol";
// SPDX-License-Identifier: none

pragma solidity ^0.8.9;

abstract contract BaseRelayRecipient is IRelayRecipient {
    address private _trustedForwarder;
        string public override versionRecipient = "0.0.1";

    function trustedForwarder() public virtual view returns (address){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: none

pragma solidity ^0.8.9;

abstract contract IRelayRecipient {
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    function _msgSender() internal virtual view returns (address);

    function _msgData() internal virtual view returns (bytes calldata);

    function versionRecipient() external virtual view returns (string memory);
}