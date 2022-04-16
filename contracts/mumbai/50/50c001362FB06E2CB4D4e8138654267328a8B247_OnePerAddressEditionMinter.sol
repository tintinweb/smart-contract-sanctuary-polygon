// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

interface IEditionSingleMintable {
  function mintEdition(address to) external returns (uint256);
  function mintEditions(address[] memory to) external returns (uint256);
  function numberCanMint() external view returns (uint256);
  function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {IEditionSingleMintable} from "@zoralabs/nft-editions-contracts/contracts/IEditionSingleMintable.sol";

import { BaseRelayRecipient } from "../utils/BaseRelayRecipient.sol";

contract OnePerAddressEditionMinter is BaseRelayRecipient {
    error AlreadyMinted(address collection, address operator);

    mapping(bytes32 => bool) minted;

    constructor(address _trustedForwarder) {
        trustedForwarder = _trustedForwarder;
    }

    function mintEdition(address collection, address _to) external {
        address operator = _msgSender();
        recordMint(collection, operator);
        if (operator != _to) {
            recordMint(collection, _to);
        }

        IEditionSingleMintable(collection).mintEdition(_to);
    }

    function recordMint(address collection, address minter) internal {
        bytes32 _mintId = mintId(collection, minter);

        if (minted[_mintId]) {
            revert AlreadyMinted(collection, minter);
        }

        minted[_mintId] = true;
    }

    function mintId(address collection, address operator) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(collection, operator));
    }

    function hasMinted(address collection, address operator) public view returns (bool) {
        return minted[mintId(collection, operator)];
    }
}

// SPDX-License-Identifier:MIT
pragma solidity =0.8.7;

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient {
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

    function isTrustedForwarder(address forwarder) public view returns (bool) {
        return forwarder == trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal view virtual returns (address ret) {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }
}