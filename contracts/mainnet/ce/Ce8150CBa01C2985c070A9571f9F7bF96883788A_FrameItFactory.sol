// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../metatx/FrameItContext.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./IFrameItFactory.sol";
import "../nfts/IFrameItNFT.sol";
import "../royalties/IFrameItSalesSplitter.sol";
import "../utils/Ownable.sol";

contract FrameItFactory is IFrameItFactory, FrameItContext, Ownable {

    address public nftTemplate;
    address public nftMinter;
    address public salesSplitterTemplate;
    address public marketplace;
    address public auctionMarketplace;
   
    event FrameItCollectionCreated(address indexed _nft, address indexed _salesSplitter, address indexed _owner);
    event NFTTemplateUpdated(address _nftTemplate);
    event LootBoxTemplateUpdated(address _lootBoxTemplate);
    event SalesSplitterTemplateUpdated(address _salesSplitterTemplate);
    event MarketplaceTemplateUpdated(address _marketplace);
    event AuctionMarketplaceTemplateUpdated(address _auctionMarketplace);
    event NFTMinterUpdated(address _nftMinter);

    constructor (
        address _forwarder,
        address _nftTemplate,
        address _nftMinter,
        address _salesSplitterTemplate, 
        address _marketplace, 
        address _auctionMarketplace
    ) FrameItContext(_forwarder) {
        nftTemplate = _nftTemplate;
        salesSplitterTemplate = _salesSplitterTemplate;
        marketplace = _marketplace;
        auctionMarketplace = _auctionMarketplace;
        nftMinter = _nftMinter;
    }

    function updateNFTTemplate(address _nftTemplate) external onlyOwner {
        require(_nftTemplate != address(0), "NullAddress");

        nftTemplate = _nftTemplate;
        emit NFTTemplateUpdated(_nftTemplate);
    }

    function updateNFTMinter(address _nftMinter) external onlyOwner {
        require(_nftMinter != address(0), "NullAddress");

        nftMinter = _nftMinter;
        emit NFTMinterUpdated(_nftMinter);
    }

    function updateSalesSplitterTemplate(address _salesSplitterTemplate) external onlyOwner {
        require(_salesSplitterTemplate != address(0), "NullAddress");

        salesSplitterTemplate = _salesSplitterTemplate;
        emit SalesSplitterTemplateUpdated(_salesSplitterTemplate);
    }

    function updateMarketplace(address _marketplace) external onlyOwner {
        require(_marketplace != address(0), "NullAddress");

        marketplace = _marketplace;
        emit MarketplaceTemplateUpdated(_marketplace);
    }

    function updateAuctionMarketplace(address _auctionMarketplace) external onlyOwner {
        require(_auctionMarketplace != address(0), "NullAddress");

        auctionMarketplace = _auctionMarketplace;
        emit AuctionMarketplaceTemplateUpdated(_auctionMarketplace);
    }

    function createCollection(
        string memory _nftUri,
        uint48 _royaltiesFeeInBips,
        uint256[] calldata _splitPercentagesSaleInBips,
        address[] calldata _splitWallets
    ) external {
        address nft = Clones.clone(nftTemplate);
        address salesSplitter = Clones.clone(salesSplitterTemplate);

        IFrameItNFT(nft).initialize(_nftUri, _msgSender(), nftMinter, _royaltiesFeeInBips, salesSplitter);
        IFrameItSalesSplitter(salesSplitter).initialize(owner, _splitPercentagesSaleInBips, _splitWallets);

        emit FrameItCollectionCreated(nft, salesSplitter, _msgSender());
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

interface IFrameItSalesSplitter {

    function initialize(address _owner, uint256[] memory _royaltyFeesInBips, address[] memory _royaltyWallets) external;
    function setWallets(uint256[] calldata _royaltyFeesInBips, address[] calldata _royaltyWallets) external;

    function paymentWallets() external view returns (uint256[] memory fees, address[] memory wallets);
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
pragma solidity ^0.8.16;

interface IFrameItFactory {
    function marketplace() external view returns(address);
    function auctionMarketplace() external view returns(address);
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
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