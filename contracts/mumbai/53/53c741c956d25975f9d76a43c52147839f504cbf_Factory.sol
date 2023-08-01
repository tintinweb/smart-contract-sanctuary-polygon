//SPDX-License-Identifier: none
pragma solidity 0.8.19;

import "./interfaces/IFactory.sol";
import "./AIGC_NFT_PROXY.sol";
import "./library/Owned.sol";

contract Factory is IFactory, Owned {
    address public implementation;

    mapping(address nfts => bool exist) public nfts;
    mapping(address owner => address[] nfts) internal ownerNfts;

    constructor(address owner_) Owned(owner_) {}

    /*//////////////////////////////////////////////////////////////
                           NEW NFT
    //////////////////////////////////////////////////////////////*/

    function newNFT(
        string memory name_,
        string memory symbol_,
        uint256 maxNftSupply_,
        uint256 saleStart_,
        uint256 maxPurchaseOnce_
    ) external override returns (address payable nftAddress) {
        nftAddress = payable(address(new AIGC_NFT_PROXY(address(this))));

        nfts[nftAddress] = true;
        ownerNfts[msg.sender].push(nftAddress);

        /* Another way to invoke the setInitialOwnership function 
        AIGC_NFT nft = AIGC_NFT(accountAddress);
        nft.setInitialOwnership(msg.sender); */

        //@todo  [ ] initialize NFT
        /*        (bool success, bytes memory data) = nftAddress.call(
            abi.encodeWithSignature("setInitialOwnership(address)", msg.sender)
        ); */
        (bool success, bytes memory data) = nftAddress.call(
            abi.encodeWithSignature(
                "initialize(address,string,string,uint256,uint256,uint256)",
                msg.sender,
                name_,
                symbol_,
                maxNftSupply_,
                saleStart_,
                maxPurchaseOnce_
            )
        );

        if (!success) revert FailedToSetNFTOwner(data);

        (success, data) = nftAddress.call(abi.encodeWithSignature("VERSION()"));
        if (!success) revert NFTFailedToFetchVersion(data);

        emit NewNFT({
            creator: msg.sender,
            nft: nftAddress,
            version: abi.decode(data, (string))
        });
    }

    /*//////////////////////////////////////////////////////////////
                             UPGRADABILITY
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IFactory
    function upgradeNFTImplementation(
        address implementation_
    ) external override onlyOwner {
        // ) external override {
        implementation = implementation_;
        emit NFTImplementationUpgraded({implementation: implementation_});
    }

    function updateNftOwnership(
        address newOwner_,
        address oldOwner_
    ) external override {
        if (!nfts[msg.sender]) revert NftDoesNotExist();
        uint256 length = ownerNfts[oldOwner_].length;
        for (uint256 i = 0; i < length; ) {
            if (ownerNfts[oldOwner_][i] == msg.sender) {
                // remove nft from ownerNfts mapping for old owner
                ownerNfts[oldOwner_][i] = ownerNfts[oldOwner_][length - 1];
                ownerNfts[oldOwner_].pop();

                // add nft to ownerNfts mapping for new owner
                ownerNfts[newOwner_].push(msg.sender);
                return;
            }
            unchecked {
                ++i;
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                                 VIEWS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IFactory
    function getNftOwner(address nft_) public view override returns (address) {
        // ensure account is registered
        if (!nfts[nft_]) revert NftDoesNotExist();

        // fetch owner from nft
        (bool success, bytes memory data) = nft_.staticcall(
            abi.encodeWithSignature("owner()")
        );
        assert(success); // should never fail (account is a contract)

        return abi.decode(data, (address));
    }

    /// @inheritdoc IFactory
    function getNftsOwnedBy(
        address owner_
    ) external view override returns (address[] memory) {
        return ownerNfts[owner_];
    }
}

//SPDX-License-Identifier: none
pragma solidity 0.8.19;

interface IFactory {
    event NewNFT(address indexed creator, address indexed nft, string version);

    event NFTImplementationUpgraded(address implementation);

    error NftDoesNotExist();
    error FailedToSetNFTOwner(bytes data);
    error NFTFailedToFetchVersion(bytes data);

    function newNFT(
        string memory name_,
        string memory symbol_,
        uint256 maxNftSupply_,
        uint256 saleStart_,
        uint256 maxPurchaseOnce_
    ) external returns (address payable nftAddress);

    function implementation() external view returns (address);

    function updateNftOwnership(address newOwner_, address oldOwner_) external;

    function upgradeNFTImplementation(address implementation_) external;

    function getNftOwner(address nft_) external view returns (address);

    function getNftsOwnedBy(
        address owner_
    ) external view returns (address[] memory);
}

//SPDX-License-Identifier: none
pragma solidity 0.8.19;
import {IAIGC_NFT_PROXY} from "./interfaces/IAIGC_NFT_PROXY.sol";

contract AIGC_NFT_PROXY is IAIGC_NFT_PROXY {
    bytes32 internal constant _BEACON_STORAGE_SLOT =
        bytes32(uint256(keccak256("eip1967.proxy.beacon")) - 1);

    struct AddressSlot {
        address value;
    }

    /// @dev returns the storage slot where the beacon address is stored
    function _getAddressSlot(
        bytes32 slot
    ) internal pure returns (AddressSlot storage r) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }
    }

    /* ------CONSTRUCTOR------ */
    
    /// @notice constructor for proxy
    /// @param _beaconAddress: address of beacon (i.e. factory address)
    /// @dev {Factory.sol} will store the implementation address,
    /// thus acting as the beacon
    constructor(address _beaconAddress) {
        _getAddressSlot(_BEACON_STORAGE_SLOT).value = _beaconAddress;
    }

    function _beacon() internal view returns (address beacon) {
        beacon = _getAddressSlot(_BEACON_STORAGE_SLOT).value;
        if (beacon == address(0)) revert BeaconNotSet();
    }

    /// @return implementation address (i.e. the account logic address)
    function _implementation() internal returns (address implementation) {
        (bool success, bytes memory data) = _beacon().call(
            abi.encodeWithSignature("implementation()")
        );
        if (!success) revert BeaconCallFailed();
        implementation = abi.decode(data, (address));
        if (implementation == address(0)) revert ImplementationNotSet();
    }

    fallback() external payable {
        _fallback();
    }

    receive() external payable {
        _fallback();
    }

    function _fallback() internal {
        _delegate(_implementation());
    }

    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(
                gas(),
                implementation,
                0,
                calldatasize(),
                0,
                0
            )

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())
            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

//SPDX-License-Identifier: none
pragma solidity 0.8.19;

interface IAIGC_NFT_PROXY {
    error BeaconNotSet();
    error ImplementationNotSet();
    error BeaconCallFailed();
}