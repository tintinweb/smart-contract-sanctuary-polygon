// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../../diamond/LibDiamond.sol";
import "../../libraries/LibApp.sol";
import "../../router/LibRouter.sol";
import "../interfaces/ICore.sol";
import "../LibCore.sol";

contract CoreFacet is ICore {

    AppStorage internal s;

    function updateWeth(address weth) external override {
        LibDiamond.enforceIsContractOwner();
        LibCore.updateWeth(weth);
    }

    function swap(SwapArgs calldata swapArgs) external override returns(uint256 amountOut) {
        amountOut = LibCore.swap(swapArgs);
    }

}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

struct CurveSettings {
    address mainRegistry;
    address cryptoRegistry;
    address cryptoFactory;
}

struct Amm {
    uint8 protocolId;
    address addr;
}

struct AppStorage {
    address weth;
    mapping(uint16 => Amm) amms;
    CurveSettings curveSettings;
}

library LibApp {
    function getStorage() internal pure returns (AppStorage storage s) {
        assembly { s.slot := 0 }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import "../libraries/LibApp.sol";
import "../libraries/LibAsset.sol";
import "../libraries/LibUint256Array.sol";
import "../core/LibCore.sol";
import "./LibBalancerV2.sol";
import "./LibCurve.sol";
import "./LibUniswapV2.sol";
import "./LibUniswapV3.sol";

struct RouterHop {
    uint8 amountIn;
    uint8 poolData;
    uint16 ammId;
    bytes32 path;
}

struct AmmHop {
    address addr;
    uint256 amountIn;
    bytes32 poolData;
    address[] path;
}

struct SwapArgs {
    RouterHop[] hops;
    uint256 amountOutMin;
    uint256[] amountIns;
    address[] assets;
    bytes32[] poolDataList;
}

struct SwapState {
    uint256 i;
    uint256 lastAmountOut;
    uint256 hopsLength;
    uint256 amountIn;
    uint256 amountInAcc;
    address fromAssetAddress;
    address toAssetAddress;
    address currentFromAssetAddress;
}

error InvalidAmm();
error SwapFailed();
error InsufficientOutputAmount();
error InvalidAmountIn();

library LibRouter {
    using LibAsset for address;
    using LibUint256Array for uint256[];

    function getPath(bytes32 path, address[] memory assets) internal pure returns(address[] memory) {
        uint256 pathSize;

        assembly {
            pathSize := shr(mul(31, 8), path)
        }

        address[] memory result = new address[](pathSize);

        assembly {
            let i := 1
            let pathPosition := add(result, 32)
            let assetPosition := add(assets, 32)
            let l := add(pathSize, 1)

            for
            {}            
            lt(i, l)
            {
                i := add(i, 1)
                pathPosition := add(pathPosition, 32)
            }
            {
                mstore(pathPosition, mload(add(assetPosition, mul(shr(248, shl(mul(i, 8), path)) /* pathIndex */, 32))))
            }
        }

        return result;
    }

    function swap(SwapArgs memory swapArgs) internal returns(uint256 amountOut) {
        AppStorage storage s = LibApp.getStorage();

        SwapState memory ss = SwapState({
            i: 0,
            lastAmountOut: 0,
            hopsLength: swapArgs.hops.length,
            amountIn: swapArgs.amountIns.sum(),
            amountInAcc: 0,
            fromAssetAddress: swapArgs.assets[1].isNative() ? s.weth : swapArgs.assets[1],
            toAssetAddress: swapArgs.assets[2].isNative() ? s.weth : swapArgs.assets[2],
            currentFromAssetAddress: swapArgs.assets[1].isNative() ? s.weth : swapArgs.assets[1]
        });

        AmmHop memory ammHop = AmmHop({
            addr: address(0),
            amountIn: 0,
            poolData: '0x',
            path: new address[](0)
        });

        if (ss.hopsLength == 0) {
            amountOut = ss.amountIn;
        }

        for (ss.i; ss.i < ss.hopsLength - 1;) {
            ammHop.addr = s.amms[swapArgs.hops[ss.i].ammId].addr;
            ammHop.amountIn = (ss.currentFromAssetAddress == ss.fromAssetAddress ? swapArgs.amountIns[swapArgs.hops[ss.i].amountIn] : ss.lastAmountOut);
            ammHop.poolData = swapArgs.poolDataList[swapArgs.hops[ss.i].poolData];
            ammHop.path = getPath(swapArgs.hops[ss.i].path, swapArgs.assets);
            address hopToAssetAddress = ammHop.path[ammHop.path.length-1];

            if (ss.currentFromAssetAddress == ss.fromAssetAddress) {
                ss.amountInAcc += ammHop.amountIn;
            }

            if (s.amms[swapArgs.hops[ss.i].ammId].protocolId == 1) {
                LibUniswapV2.swapUniswapV2(ammHop);
            } else if (s.amms[swapArgs.hops[ss.i].ammId].protocolId == 2 || s.amms[swapArgs.hops[ss.i].ammId].protocolId == 3) {
                LibBalancerV2.swapBalancerV2(ammHop);
            } else if (s.amms[swapArgs.hops[ss.i].ammId].protocolId == 6) {
                LibUniswapV3.swapUniswapV3(ammHop);
            } else if (s.amms[swapArgs.hops[ss.i].ammId].protocolId == 4 || s.amms[swapArgs.hops[ss.i].ammId].protocolId == 5 || s.amms[swapArgs.hops[ss.i].ammId].protocolId == 7) {
                LibCurve.swapCurve(ammHop);
            }

            ss.lastAmountOut = hopToAssetAddress.getBalance();

            if (hopToAssetAddress == ss.toAssetAddress) {
                amountOut += ss.lastAmountOut;
                ss.currentFromAssetAddress = ss.fromAssetAddress;
            } else {
                ss.currentFromAssetAddress = hopToAssetAddress;
            }

            unchecked { ss.i++; }
        }

        if (amountOut < swapArgs.amountOutMin || amountOut == 0) {
            revert InsufficientOutputAmount();
        }

        if (ss.amountIn != ss.amountInAcc) {
            revert InvalidAmountIn();
        }
    }

    event AddAmm(address indexed sender, uint16 ammId, Amm amm);

    function addAmm(uint16 ammId, Amm memory amm) internal {
        AppStorage storage s = LibApp.getStorage();

        s.amms[ammId] = amm;

        emit AddAmm(msg.sender, ammId, amm);
    }

    event RemoveAmm(address indexed sender, uint16 ammId);

    function removeAmm(uint16 ammId) internal {
        AppStorage storage s = LibApp.getStorage();

        delete s.amms[ammId];

        emit RemoveAmm(msg.sender, ammId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { IDiamondCut } from "./interfaces/IDiamondCut.sol";

error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();        
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);            
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }    


    function addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {        
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            return;
        }
        enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");        
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up error
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../libraries/LibApp.sol";
import "../libraries/LibAsset.sol";
import "../router/LibRouter.sol";
import "../libraries/LibUint256Array.sol";

library LibCore {
    using LibAsset for address;

    event UpdateWeth(address indexed sender, address weth);

    function updateWeth(address weth) internal {
        AppStorage storage s = LibApp.getStorage();

        s.weth = weth;

        emit UpdateWeth(msg.sender, weth);
    }

    event Swap(address indexed from, address indexed to, address fromAsset, address toAsset, uint256 amountIn, uint256 amountOut);

    function swap(SwapArgs memory swapArgs) internal returns(uint256 amountOut) {
        AppStorage storage s = LibApp.getStorage();

        uint256 amountIn = LibUint256Array.sum(swapArgs.amountIns);

        swapArgs.assets[1].deposit(s.weth, amountIn);

        amountOut = LibRouter.swap(swapArgs);

        swapArgs.assets[2].withdraw(s.weth, swapArgs.assets[0], amountOut);

        emit Swap(msg.sender, swapArgs.assets[0], swapArgs.assets[1], swapArgs.assets[2], amountIn, amountOut);
    }

    // TODO: add swapIn and swapOut

}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import "../../router/LibRouter.sol";

interface ICore {

    event UpdateWeth(address indexed sender, address weth);

    function updateWeth(address weth) external;

    event Swap(address indexed from, address indexed to, address fromAsset, address toAsset, uint256 amountIn, uint256 amountOut);

    function swap(SwapArgs calldata swapArgs) external returns(uint256 amountOut);

}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

library LibUint256Array {
    function sum(uint256[] memory self) internal pure returns (uint256 amountOut) {
        uint256 selfLength = self.length * 32;

        assembly {
            let selfPosition := add(self, 32)
            let endPosition := add(selfPosition, selfLength)

            for
                {}
                lt(selfPosition, endPosition)
                {
                    selfPosition := add(selfPosition, 32)
                }
            {
                amountOut := add(amountOut, mload(selfPosition))
            }

        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import "../libraries/LibApp.sol";
import "../libraries/LibAsset.sol";
import "../interfaces/curve/IAddressProvider.sol";
import "../interfaces/curve/ICryptoFactory.sol";
import "../interfaces/curve/ICryptoPool.sol";
import "../interfaces/curve/ICryptoRegistry.sol";
import "../interfaces/curve/ICurvePool.sol";
import "../interfaces/curve/IRegistry.sol";
import "./LibRouter.sol";

struct ExchangeArgs {
    address pool;
    address from;
    address to;
    uint256 amount;
}

library LibCurve {
    using LibAsset for address;

    function mainExchange(ExchangeArgs memory exchangeArgs, address registry) private {
        int128 i = 0;
        int128 j = 0;
        bool isUnderlying = false;
        (i, j, isUnderlying) = IRegistry(registry).get_coin_indices(
            exchangeArgs.pool,
            exchangeArgs.from,
            exchangeArgs.to
        );

        if (isUnderlying) {
            ICurvePool(exchangeArgs.pool).exchange_underlying(i, j, exchangeArgs.amount, 0);
        } else {
            ICurvePool(exchangeArgs.pool).exchange(i, j, exchangeArgs.amount, 0);
        }
    }

    function cryptoExchange(ExchangeArgs memory exchangeArgs, address registry) private {
        uint256 i = 0;
        uint256 j = 0;
        address initial = exchangeArgs.from;
        address target = exchangeArgs.to;

        (i, j) = ICryptoRegistry(registry).get_coin_indices(exchangeArgs.pool, initial, target);

        ICryptoPool(exchangeArgs.pool).exchange(i, j, exchangeArgs.amount, 0);
    }

    function swapCurve(AmmHop memory h) internal {
        AppStorage storage s = LibApp.getStorage();

        bytes32 poolData = h.poolData;
        address pool;

        assembly {
            pool := shr(96, poolData)
        }

        ExchangeArgs memory exchangeArgs = ExchangeArgs({
            pool: pool,
            from: h.path[0],
            to: h.path[1],
            amount: h.amountIn
        });

        h.path[0].approve(exchangeArgs.pool, h.amountIn);

        if (ICryptoRegistry(s.curveSettings.cryptoRegistry).get_decimals(exchangeArgs.pool)[0] > 0) {
            cryptoExchange(exchangeArgs, s.curveSettings.cryptoRegistry);
            // Some networks dont have cryptoFactory
        } else if (ICryptoFactory(s.curveSettings.cryptoFactory).get_decimals(exchangeArgs.pool)[0] > 0) {
            cryptoExchange(exchangeArgs, s.curveSettings.cryptoFactory);
        } else {
            mainExchange(exchangeArgs, s.curveSettings.mainRegistry);
        }
    }

    event UpdateCurveSettings(address indexed sender, CurveSettings curveSettings);

    function updateCurveSettings(address addressProvider) internal {
        AppStorage storage s = LibApp.getStorage();

        s.curveSettings = CurveSettings({
          mainRegistry: IAddressProvider(addressProvider).get_address(0),
          cryptoRegistry: IAddressProvider(addressProvider).get_address(5),
          cryptoFactory: IAddressProvider(addressProvider).get_address(6)
        });

        emit UpdateCurveSettings(msg.sender, s.curveSettings);
    }

}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IWETH.sol";

error AssetNotReceived();
error TransferFromFailed();
error TransferFailed();
error ApprovalFailed();

library LibAsset {
    using LibAsset for address;

    address constant NATIVE_ASSETID = address(0);

    function isNative(address self) internal pure returns (bool) {
        return self == NATIVE_ASSETID;
    }

    function getBalance(address self) internal view returns (uint256) {
        return self.isNative() ? address(this).balance : IERC20(self).balanceOf(address(this));
    }

    function transferFrom(
        address self,
        address from,
        address to,
        uint256 amount
    ) internal {
        IERC20 token = IERC20(self);
        bytes4 selector = token.transferFrom.selector;
        bool isSuccessful;
        assembly {
            let data := mload(0x40)

            mstore(data, selector)
            mstore(add(data, 0x04), from)
            mstore(add(data, 0x24), to)
            mstore(add(data, 0x44), amount)
            isSuccessful := call(gas(), token, 0, data, 100, 0x0, 0x20)
            if isSuccessful {
                switch returndatasize()
                case 0 { isSuccessful := gt(extcodesize(token), 0) }
                default { isSuccessful := and(gt(returndatasize(), 31), eq(mload(0), 1)) }
            }
        }
        if (!isSuccessful) {
            revert TransferFromFailed();
        }
    }

    function transfer(
        address self,
        address payable recipient,
        uint256 amount
    ) internal {
        bool isSuccessful;
        if (self.isNative()) {
            (isSuccessful,) = recipient.call{value: amount}("");
        } else {
            IERC20 token = IERC20(self);
            bytes4 selector = token.transfer.selector;
            assembly {
                let data := mload(0x40)

                mstore(data, selector)
                mstore(add(data, 0x04), recipient)
                mstore(add(data, 0x24), amount)
                isSuccessful := call(gas(), token, 0, data, 0x44, 0x0, 0x20)
                if isSuccessful {
                    switch returndatasize()
                    case 0 { isSuccessful := gt(extcodesize(token), 0) }
                    default { isSuccessful := and(gt(returndatasize(), 31), eq(mload(0), 1)) }
                }
            }
        }

        if (!isSuccessful) {
            revert TransferFailed();
        }
    }

    function approve(
        address self,
        address spender,
        uint256 amount
    ) internal {
        bool isSuccessful = IERC20(self).approve(spender, amount);
        if (!isSuccessful) {
            revert ApprovalFailed();
        }
    }

    function getAllowance(
        address self,
        address owner,
        address spender
    ) internal view returns (uint256) {
        return IERC20(self).allowance(owner, spender);
    }

    function deposit(address self, address weth, uint256 amount) internal {
        if (self.isNative()) {
            if (msg.value < amount) {
                revert AssetNotReceived();
            }
            IWETH(weth).deposit{value: amount}();
        } else {
            self.transferFrom(msg.sender, address(this), amount);
        }
    }

    function withdraw(address self, address weth, address to, uint256 amount) internal {
        if (self.isNative()) {
            IWETH(weth).withdraw(amount);
        }
        self.transfer(payable(to), amount);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import "../interfaces/balancer-v2/IAsset.sol";
import "../interfaces/balancer-v2/IVault.sol";
import "../libraries/LibAsset.sol";
import "./LibRouter.sol";

library LibBalancerV2 {
    using LibAsset for address;

    function swapBalancerV2(AmmHop memory h) internal {
        h.path[0].approve(h.addr, h.amountIn);
        IVault.FundManagement memory funds = IVault.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });
        if (h.path.length == 2) {
            IVault(h.addr).swap(
                IVault.SingleSwap({
                    poolId: h.poolData,
                    kind: IVault.SwapKind.GIVEN_IN,
                    assetIn: IAsset(h.path[0]),
                    assetOut: IAsset(h.path[1]),
                    amount: h.amountIn,
                    userData: "0x"
                }),
                funds,
                0,
                block.timestamp
            );
        } else {
            uint256 i;
            uint256 l = h.path.length;
            IVault.BatchSwapStep[] memory swaps = new IVault.BatchSwapStep[](h.path.length - 1);
            IAsset[] memory balancerAssets = new IAsset[](h.path.length);
            int256[] memory limits = new int256[](h.path.length);

            for (i = 0; i < l - 1;) {
                swaps[i] = IVault.BatchSwapStep({
                    poolId: h.poolData,
                    assetInIndex: i,
                    assetOutIndex: i + 1,
                    amount: i == 0 ? h.amountIn : 0,
                    userData: "0x"
                });
                balancerAssets[i] = IAsset(h.path[i]);
                limits[i] = i == 0 ? int256(h.amountIn) : int256(0);

                if (i == h.path.length - 2) {
                    balancerAssets[i + 1] = IAsset(h.path[i + 1]);
                    limits[i + 1] = 0;
                }

                unchecked { i++; }
            }

            IVault(h.addr).batchSwap(IVault.SwapKind.GIVEN_IN, swaps, balancerAssets, funds, limits, block.timestamp);
        }
    }

}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import "../interfaces/uniswap-v2/IUniswapV2Router.sol";
import "../libraries/LibAsset.sol";
import "./LibRouter.sol";

library LibUniswapV2 {
    using LibAsset for address;

    function swapUniswapV2(AmmHop memory h) internal {
        h.path[0].approve(h.addr, h.amountIn);
        IUniswapV2Router(h.addr).swapExactTokensForTokens(h.amountIn, 0, h.path, address(this), block.timestamp);
    }

}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import "../interfaces/uniswap-v3/IUniswapV3Router.sol";
import "../libraries/LibAsset.sol";
import "./LibRouter.sol";

library LibUniswapV3 {
    using LibAsset for address;

    function getUniswapV3Path(bytes32 poolData, address[] memory path) private pure returns(bytes memory) {
        bytes memory payload;
        uint256 pathSize = path.length;

        assembly {
            payload := mload(0x40)
            let i := 0
            let payloadPosition := add(payload, 32)
            let pathPosition := add(path, 32)
            let feePathSize := sub(pathSize, 1)

            for
            {}
            lt(i, pathSize)
            {
                i := add(i, 1)
                pathPosition := add(pathPosition, 32)
            }
            {
                mstore(payloadPosition, shl(96, mload(pathPosition)))
                payloadPosition := add(payloadPosition, 20)
                if lt(i, feePathSize) {
                    mstore(payloadPosition, shl(mul(i, 24), poolData))
                    payloadPosition := add(payloadPosition, 3)
                }
            }

            mstore(payload, sub(sub(payloadPosition, payload), 32))
            mstore(0x40, and(add(payloadPosition, 31), not(31)))
        }

        return payload;
    }

    function swapUniswapV3(AmmHop memory h) internal {
        h.path[0].approve(h.addr, h.amountIn);
        if (h.path.length == 2) {
            bytes32 poolData = h.poolData;
            uint24 fee;

            assembly {
                fee := shr(232, poolData)
            }

            IUniswapV3Router(h.addr).exactInputSingle(IUniswapV3Router.ExactInputSingleParams({
                tokenIn: h.path[0],
                tokenOut: h.path[1],
                fee: fee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: h.amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            }));
        } else {
            IUniswapV3Router(h.addr).exactInput(IUniswapV3Router.ExactInputParams({
                path: getUniswapV3Path(h.poolData, h.path),
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: h.amountIn,
                amountOutMinimum: 0
            }));
        }
    }

}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

interface IAddressProvider {
    function admin() external view returns (address);

    function get_registry() external view returns (address);

    function get_address(uint256 idx) external view returns (address);
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

interface ICryptoRegistry {
    function get_coin_indices(
        address _pool,
        address _from,
        address _to
    ) external view returns (uint256, uint256);

    function get_decimals(address _pool) external view returns (uint256[8] memory);
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

interface ICryptoFactory {
    function get_coin_indices(
        address _pool,
        address _from,
        address _to
    ) external view returns (uint256, uint256);

    function get_decimals(address _pool) external view returns (uint256[2] memory);
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

interface ICryptoPool {
    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external payable;

    function exchange_underlying(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external payable;

    function get_dy(
        uint256 i,
        uint256 j,
        uint256 amount
    ) external view returns (uint256);

    function get_dy_underlying(
        uint256 i,
        uint256 j,
        uint256 amount
    ) external view returns (uint256);
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

interface ICurvePool {
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external payable;

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external payable;

    function get_dy(
        int128 i,
        int128 j,
        uint256 amount
    ) external view returns (uint256);

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 amount
    ) external view returns (uint256);

    function coins(uint256 i) external view returns (address);
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

interface IRegistry {
    function address_provider() external view returns (address);

    function get_A(address _pool) external view returns (uint256);

    function get_fees(address _pool) external view returns (uint256[2] memory);

    function get_coin_indices(
        address _pool,
        address _from,
        address _to
    )
        external
        view
        returns (
            int128,
            int128,
            bool
        );

    function get_n_coins(address _pool) external view returns (uint256[2] memory);

    function get_balances(address _pool) external view returns (uint256[] memory);

    function get_underlying_balances(address _pool) external view returns (uint256[] memory);

    function get_rates(address _pool) external view returns (uint256[] memory);

    function get_decimals(address _pool) external view returns (uint256[] memory);

    function get_underlying_decimals(address _pool) external view returns (uint256[] memory);

    function find_pool_for_coins(
        address _from,
        address _to,
        uint256 i
    ) external view returns (address);

    function get_lp_token(address _pool) external view returns (address);

    function is_meta(address _pool) external view returns (bool);
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

/**
 * @dev This is an empty interface used to represent either ERC20-conforming token contracts or ETH (using the zero
 * address sentinel value). We're just relying on the fact that `interface` can be used to declare new address-like
 * types.
 *
 * This concept is unrelated to a Pool's Asset Managers.
 */
interface IAsset {

}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IAsset.sol";

interface IVault {
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory);

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds
    ) external returns (int256[] memory assetDeltas);
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.2;

interface IUniswapV2Router {

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.2;

interface IUniswapV3Router {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}