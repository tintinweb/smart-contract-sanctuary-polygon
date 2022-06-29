//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./libraries/LibStorage.sol";
import "./interfaces/IDiamondCutter.sol";

contract Diamond {

    constructor(address _diamondCutterFacet) {
        // set ownership to deployer
        LibStorage.DiamondStorage storage ds = LibStorage.diamondStorage();
        ds.contractOwner = msg.sender;

        // Add the diamondCut function to the deployed diamondCutter
        bytes4 cutterSelector = IDiamondCutter.diamondCut.selector;
        ds.selectors.push(cutterSelector);
        ds.facets[cutterSelector] = LibStorage.Facet({
            facetAddress: _diamondCutterFacet,
            selectorPosition: 0
        });
    }

    // Search address associated with the selector and delegate execution
    fallback() external payable {
        LibStorage.DiamondStorage storage ds;
        bytes32 position = LibStorage.DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds.facets[msg.sig].facetAddress;
        require(facet != address(0), "Signature not found");
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {revert(0, returndatasize())}
            default {return (0, returndatasize())}
        }
    }

    receive() external payable {}

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibStorage {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("xyz.swidge.storage.diamond");
    bytes32 constant APP_STORAGE_POSITION = keccak256("xyz.swidge.storage.app");

    struct DiamondStorage {
        // function selector => facet address and selector position in selectors array
        mapping(bytes4 => Facet) facets;
        bytes4[] selectors;
        // owner of the contract
        address contractOwner;
        // relayer account
        address relayerAddress;
    }

    struct AppStorage {
        mapping(uint8 => Provider) bridgeProviders;
        mapping(uint8 => Provider) swapProviders;
    }

    struct Facet {
        address facetAddress;
        uint16 selectorPosition;
    }

    struct Provider {
        uint8 code;
        bool enabled;
        address implementation;
        address handler;
    }

    enum DexCode {ZeroEx}
    enum BridgeCode {Anyswap}

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function appStorage() internal pure returns (AppStorage storage s) {
        bytes32 position = APP_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "Must be contract owner");
    }

    function enforceIsRelayer() internal view {
        require(msg.sender == diamondStorage().relayerAddress, "Must be relayer");
    }

    function nativeToken() internal pure returns (address) {
        return address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    }

    function getBridge(uint8 _code) internal view returns (Provider storage) {
        return appStorage().bridgeProviders[_code];
    }

    function getSwapper(uint8 _code) internal view returns (Provider storage) {
        return appStorage().swapProviders[_code];
    }

    function send(
        uint8 _code,
        address _token,
        uint256 _amount,
        uint256 _toChainId,
        bytes memory _data
    ) internal returns(bool){
        Provider storage bridge = getBridge(_code);

        if (!bridge.enabled) {
            revert("Bridge not enabled");
        }

        //;
        (bool success,) = bridge.implementation.delegatecall(
            abi.encodeWithSelector(
                bytes4(keccak256(bytes('send(address,address,uint256,uint256,bytes)'))),
                bridge.handler, _token, _amount, _toChainId, _data
            )
        );

        require(success, "Bridge failed");

        return true;
    }

    function swap(
        uint8 _code,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        bytes memory _data
    ) internal returns (uint256) {
        Provider memory swapper = getSwapper(_code);

        if (!swapper.enabled) {
            revert("Swapper not enabled");
        }

        // bytes4(keccak256(bytes('swap(address,address,uint256,bytes)')))
        (bool success, bytes memory data) = swapper.implementation.delegatecall(
            abi.encodeWithSelector(0x43a0a7f2, _tokenIn, _tokenOut, _amountIn, _data)
        );

        require(success, "Swap failed");

        (uint256 boughtAmount) = abi.decode(data, (uint256));

        return boughtAmount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*************************************************************\
Forked from https://github.com/mudgen/diamond
/*************************************************************/

interface IDiamondCutter {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        FacetCutAction action;
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions
    /// @param _diamondCut Contains the facet addresses and function selectors
    function diamondCut(FacetCut[] calldata _diamondCut) external;
}