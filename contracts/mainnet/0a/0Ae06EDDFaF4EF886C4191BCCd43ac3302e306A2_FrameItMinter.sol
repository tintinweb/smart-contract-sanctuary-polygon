// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../utils/Ownable.sol";
import "../metatx/FrameItContext.sol";
import "../nfts/IFrameItNFT.sol";

contract FrameItMinter is FrameItContext, Ownable {
    address public manager;

    event ManagerChanged(address _manager);
    event FrameMinted(address indexed _nft, address indexed _owner, uint256 _id);
    event FramesMinted(address indexed _nft, address indexed _owner, uint256[] _ids);

    constructor(address _forwarder, address _manager) FrameItContext(_forwarder) {
        manager = _manager;
    }

    function setManager(address _manager) external {
        require(_msgSender() == owner, "OnlyOwner");
        manager = _manager;

        emit ManagerChanged(_manager);
    }

    function mintFrame(address _nft, uint256 _id, address _owner) external {
        require(_msgSender() == manager, "OnlyManager");
        IFrameItNFT(_nft).mint(_owner, _id);

        emit FrameMinted(_nft, _owner, _id);
    }

    function mintFrames(address _nft, uint256[] calldata _ids, address _owner) external {
        require(_msgSender() == manager, "OnlyManager");
        IFrameItNFT(_nft).mint(_owner, _ids);

        emit FramesMinted(_nft, _owner, _ids);
    }

    function mintFrames(address[] calldata _nfts, uint256[] calldata _ids, address _owner) external {
        require(_msgSender() == manager, "OnlyManager");

        for (uint256 i=0; i<=_nfts.length; i++) {
            address _nft = _nfts[i];
            IFrameItNFT(_nft).mint(_owner, _ids);

            emit FramesMinted(_nft, _owner, _ids);
        }
    }
}

// SPDX-License-Identifier: MIT
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
abstract contract Ownable {
    address public owner;
    address public ownerPendingClaim;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event NewOwnershipProposed(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(msg.sender);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "OnlyOwner");
        _;
    }

    function proposeChangeOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "ZeroAddress");
        ownerPendingClaim = newOwner;

        emit NewOwnershipProposed(msg.sender, newOwner);
    }

    function claimOwnership() external {
        require(msg.sender == ownerPendingClaim, "OnlyProposedOwner");

        ownerPendingClaim = address(0);
        _transferOwnership(msg.sender);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IFrameItNFT {

    function initialize(string memory _newuri, address _owner, address _minter, uint256 _royaltyFeeInBips, address _salesWallet) external;
    function mint(address _to, uint256 _id) external;
    function mint(address _to, uint256[] calldata _ids) external;
    function salesWallet() external view returns(address);
    function owner() external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

contract FrameItContext is ERC2771Context {

    constructor (address _forwarder) ERC2771Context(_forwarder) {
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}