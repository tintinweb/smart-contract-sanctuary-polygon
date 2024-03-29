// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../Factory/GmxFactory.sol";
import "../NFT/IPositionNFT.sol";

contract GmxFactoryV2 is GmxFactory {
    IPositionNFT public positionNFT;
    address public owner;

    constructor(
        address _router,
        address _positionRouter
    ) GmxFactory(_router, _positionRouter) {
        owner = msg.sender;
    }

    /**
     * @dev Set the position NFT contract address.
     * @param _positionNFTAddress The address of the position NFT contract.
     */
    function setPositionNFT(address _positionNFTAddress) external onlyOwner {
        positionNFT = IPositionNFT(_positionNFTAddress);
    }

    /**
     * @dev Create an NFT representing a pair of long and short positions.
     * @param _path The token path for the position.
     * @param _indexToken The index token for the position.
     * @param _amountIn The amount of tokens to invest.
     * @param _minOut The minimum acceptable amount of output tokens.
     * @param _sizeDelta The change in position size.
     * @param _acceptablePriceLong The acceptable price for the long position.
     * @param _acceptablePriceShort The acceptable price for the short position.
     */
    function createNFT(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        uint256 _acceptablePriceLong,
        uint256 _acceptablePriceShort
    ) external payable  {
        bytes32 longPositionId;
        bytes32 shortPositionId;

    {
        // Call the original `openLongPosition` function
        bytes memory bytecode = type(GmxAdapter).creationCode;
        address adapter;
        assembly {
            adapter := create(0, add(bytecode, 32), mload(bytecode))
        }
        IGmxAdapter(adapter).initialize(ROUTER, POSITION_ROUTER, msg.sender);
        IGmxAdapter(adapter).approvePlugin(POSITION_ROUTER);
        address collateral = _path[0];
        IERC20(collateral).transferFrom(msg.sender, adapter, _amountIn);
        IGmxAdapter(adapter).approve(collateral, ROUTER, _amountIn);
        longPositionId = IGmxAdapter(adapter).createIncreasePosition{value: msg.value/2}(_path, _indexToken, _amountIn, _minOut, _sizeDelta, true, _acceptablePriceLong);
        positionAdapters[longPositionId] = adapter;
        positionOwners[longPositionId] = msg.sender;
        positions[msg.sender] += 1;
        indexedPositions[msg.sender][positions[msg.sender]] = longPositionId;
    }

    {
        // Call the original `openShortPosition` function
        bytes memory bytecode = type(GmxAdapter).creationCode;
        address adapter;
        assembly {
            adapter := create(0, add(bytecode, 32), mload(bytecode))
        }
        IGmxAdapter(adapter).initialize(ROUTER, POSITION_ROUTER, msg.sender);
        IGmxAdapter(adapter).approvePlugin(POSITION_ROUTER);
        address collateral = _path[0];
        IERC20(collateral).transferFrom(msg.sender, adapter, _amountIn);
        IGmxAdapter(adapter).approve(collateral, ROUTER, _amountIn);
        shortPositionId = IGmxAdapter(adapter).createIncreasePosition{value: msg.value/2}(_path, _indexToken, _amountIn, _minOut, _sizeDelta, false, _acceptablePriceShort);
        positionAdapters[shortPositionId] = adapter;
        positionOwners[shortPositionId] = msg.sender;
        positions[msg.sender] += 1;
        indexedPositions[msg.sender][positions[msg.sender]] = shortPositionId;
    }
        
        // Mint the NFT with the long and short position IDs
        positionNFT.mint(msg.sender, longPositionId, shortPositionId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IPositionNFT {
    function mint(
        address to,
        bytes32 _long,
        bytes32 _short
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../GMX/interfaces/IERC20.sol";
import "../GMX/interfaces/IRouter.sol";
import "../GMX/interfaces/IReader.sol";
import "../GMX/interfaces/IGmxAdapter.sol";
import "../Adapters/GmxAdapter.sol";

contract GmxFactory {
    
    address public OWNER;
    address public ROUTER;
    address public POSITION_ROUTER;

    mapping (bytes32 => address) public positionAdapters;

    mapping (bytes32 => address) public positionOwners;

    mapping (address => uint256) public positions;

    mapping (address => mapping (uint => bytes32)) public indexedPositions;

    constructor(address _router, address _positionRouter) {
        OWNER = msg.sender;
        ROUTER = _router;
        POSITION_ROUTER = _positionRouter;
    }

    modifier onlyOwner() {
        require(OWNER == msg.sender, "caller is not the owner");
        _;
    }

    function withdrawToken(address token, address to, uint256 amount) external onlyOwner returns (bool) {
        return IERC20(token).transfer(to, amount);
    }

    function withdrawEth(address to, uint256 amount) external onlyOwner returns (bool) {
        (bool success,) = to.call{ value: amount}("");
        require(success, "Transfer failed!");
        return success;
    }

    function openLongPosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        uint256 _acceptablePrice
    ) public payable returns (bytes32) {
        bytes memory bytecode = type(GmxAdapter).creationCode;
        address adapter;
        assembly {
            adapter := create(0, add(bytecode, 32), mload(bytecode))
        }
        IGmxAdapter(adapter).initialize(ROUTER, POSITION_ROUTER, msg.sender);
        IGmxAdapter(adapter).approvePlugin(POSITION_ROUTER);
        address collateral = _path[0];
        IERC20(collateral).transferFrom(msg.sender, adapter, _amountIn);
        IGmxAdapter(adapter).approve(collateral, ROUTER, _amountIn);
        bytes32 positionId = IGmxAdapter(adapter).createIncreasePosition{value: msg.value}(_path, _indexToken, _amountIn, _minOut, _sizeDelta, true, _acceptablePrice);
        positionAdapters[positionId] = adapter;
        positionOwners[positionId] = msg.sender;
        positions[msg.sender] += 1;
        indexedPositions[msg.sender][positions[msg.sender]] = positionId;
        return positionId;
    }

    function openLongPositionEth(
        address[] memory _path,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        uint256 _acceptablePrice
    ) public payable returns (bytes32) {
        bytes memory bytecode = type(GmxAdapter).creationCode;
        address adapter;
        assembly {
            adapter := create(0, add(bytecode, 32), mload(bytecode))
        }
        IGmxAdapter(adapter).initialize(ROUTER, POSITION_ROUTER, msg.sender);
        IGmxAdapter(adapter).approvePlugin(POSITION_ROUTER);
        bytes32 positionId = IGmxAdapter(adapter).createIncreasePositionETH{value: msg.value}(_path, _indexToken, _minOut, _sizeDelta, true, _acceptablePrice);
        positionAdapters[positionId] = adapter;
        positionOwners[positionId] = msg.sender;
        positions[msg.sender] += 1;
        indexedPositions[msg.sender][positions[msg.sender]] = positionId;
        return positionId;
    }

    function openShortPosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        uint256 _acceptablePrice
    ) public payable returns (bytes32) {
        bytes memory bytecode = type(GmxAdapter).creationCode;
        address adapter;
        assembly {
            adapter := create(0, add(bytecode, 32), mload(bytecode))
        }
        IGmxAdapter(adapter).initialize(ROUTER, POSITION_ROUTER, msg.sender);
        IGmxAdapter(adapter).approvePlugin(POSITION_ROUTER);
        address collateral = _path[0];
        IERC20(collateral).transferFrom(msg.sender, adapter, _amountIn);
        IGmxAdapter(adapter).approve(collateral, ROUTER, _amountIn);
        bytes32 positionId = IGmxAdapter(adapter).createIncreasePosition{value: msg.value}(_path, _indexToken, _amountIn, _minOut, _sizeDelta, false, _acceptablePrice);
        positionAdapters[positionId] = adapter;
        positionOwners[positionId] = msg.sender;
        positions[msg.sender] += 1;
        indexedPositions[msg.sender][positions[msg.sender]] = positionId;
        return positionId;
    }

    function openShortPositionEth(
        address[] memory _path,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        uint256 _acceptablePrice
    ) public payable returns (bytes32) {
        bytes memory bytecode = type(GmxAdapter).creationCode;
        address adapter;
        assembly {
            adapter := create(0, add(bytecode, 32), mload(bytecode))
        }
        IGmxAdapter(adapter).initialize(ROUTER, POSITION_ROUTER, msg.sender);
        IGmxAdapter(adapter).approvePlugin(POSITION_ROUTER);
        bytes32 positionId = IGmxAdapter(adapter).createIncreasePositionETH{value: msg.value}(_path, _indexToken, _minOut, _sizeDelta, false, _acceptablePrice);
        positionAdapters[positionId] = adapter;
        positionOwners[positionId] = msg.sender;
        positions[msg.sender] += 1;
        indexedPositions[msg.sender][positions[msg.sender]] = positionId;
        return positionId;
    }

    function closePosition(bytes32 positionId, address[] memory _path, uint256 _acceptablePrice, bool _withdrawETH) external payable {
        require(msg.sender == positionOwners[positionId], "not a position owner");
        address adapter = positionAdapters[positionId];
        IGmxAdapter(adapter).closePosition{value: msg.value}(_path, msg.sender, _acceptablePrice, _withdrawETH);
    }

    function getPosition(bytes32 positionId, address reader, address vault) external view returns(uint256[] memory) {
        address account = positionAdapters[positionId];
        (, address collateralToken, address indexToken, , , , bool isLong,) = IGmxAdapter(account).getPositionData(); 
        address[] memory collateralTokens = new address[](1);
        collateralTokens[0] = collateralToken;
        address[] memory indexTokens = new address[](1);
        indexTokens[0] = indexToken;
        bool[] memory isLongs = new bool[](1);
        isLongs[0] = isLong;
        return IReader(reader).getPositions(vault, account, collateralTokens, indexTokens, isLongs);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../GMX/interfaces/IERC20.sol";
import "../GMX/interfaces/IGmxAdapter.sol";

contract GmxAdapter {

    address public FACTORY;
    address public OWNER;
    address public ROUTER;
    address public POSITION_ROUTER;
    address constant ZERO_ADDRESS = address(0);
    bytes32 constant ZERO_VALUE = 0x0000000000000000000000000000000000000000000000000000000000000000;
    
    address[] path;
    address collateralToken;
    address indexToken;
    uint256 amountIn;
    uint256 minOut;
    uint256 sizeDelta;
    bool isLong;
    uint256 acceptablePrice;
        
    modifier onlyOwner() {
        require(OWNER == msg.sender || FACTORY == msg.sender, "caller is not the owner or factory");
        _;
    }
    
    receive() external payable {}
    
    constructor() {
        FACTORY = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _router, address _positionRouter, address _owner) external {
        require(msg.sender == FACTORY, 'GmxAdapter: FORBIDDEN'); // sufficient check
        ROUTER = _router;
        POSITION_ROUTER = _positionRouter;
        OWNER = _owner;
    }

    function approve(address token, address spender, uint256 amount) external onlyOwner returns (bool) {
        return IERC20(token).approve(spender, amount);
    }

    function approvePlugin(address _plugin) external onlyOwner {
        IRouter(ROUTER).approvePlugin(_plugin);
    }

    function createIncreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice
    ) external payable onlyOwner returns (bytes32) {
        uint256 _executionFee = IPositionRouter(POSITION_ROUTER).minExecutionFee();
        bytes32 result = IPositionRouter(POSITION_ROUTER).createIncreasePosition{value: msg.value}(_path, _indexToken, _amountIn, _minOut, _sizeDelta, _isLong, _acceptablePrice, _executionFee, ZERO_VALUE, ZERO_ADDRESS);
        setPositionData(_path, _indexToken, _amountIn, _minOut, _sizeDelta, _isLong, _acceptablePrice);
        return result;
    }

    function createIncreasePositionETH(
        address[] memory _path,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice
    ) external payable onlyOwner returns (bytes32) {
        uint256 _executionFee = IPositionRouter(POSITION_ROUTER).minExecutionFee();
        bytes32 result = IPositionRouter(POSITION_ROUTER).createIncreasePositionETH{value: msg.value}(_path, _indexToken, _minOut, _sizeDelta, _isLong, _acceptablePrice, _executionFee, ZERO_VALUE, ZERO_ADDRESS);
        setPositionData(_path, _indexToken, msg.value - _executionFee, _minOut, _sizeDelta, _isLong, _acceptablePrice);
        return result;
    }
    
    function closePosition(address[] memory _path, address _receiver, uint256 _acceptablePrice, bool _withdrawETH) external payable onlyOwner returns (bytes32) {
        uint256 _executionFee = IPositionRouter(POSITION_ROUTER).minExecutionFee();
        try IPositionRouter(POSITION_ROUTER).createDecreasePosition{value: msg.value}(_path, indexToken, 0, sizeDelta, isLong, _receiver, _acceptablePrice, 0, _executionFee, _withdrawETH, ZERO_ADDRESS) returns (bytes32 result) {
            return result;
        }
        catch {
            address collateral = path[path.length - 1];
            uint256 collateralBalance = IERC20(collateral).balanceOf(address(this));
            if (collateralBalance > 0) {
                IERC20(collateral).transfer(_receiver, collateralBalance);
            }
            else if (address(this).balance > 0) {
                (bool success,) = _receiver.call{ value: address(this).balance}("");
                require(success, "Transfer failed!");
            }
        }
        return "";
    }
    
    function withdrawToken(address token, address to, uint256 amount) external onlyOwner returns (bool) {
        return IERC20(token).transfer(to, amount);
    }

    function withdrawEth(address to, uint256 amount) external onlyOwner returns (bool) {
        (bool success,) = to.call{ value: amount}("");
        require(success, "Transfer failed!");
        return success;
    }

    function setPositionData (address[] memory _path, address _indexToken, uint256 _amountIn, uint256 _minOut, uint256 _sizeDelta, bool _isLong, uint256 _acceptablePrice) internal {
        path = _path;
        collateralToken = _path[_path.length - 1];
        indexToken = _indexToken;
        amountIn = _amountIn;
        minOut = _minOut;
        sizeDelta = _sizeDelta;
        isLong = _isLong;
        acceptablePrice = _acceptablePrice;
    }

    function getPositionData() external view returns (address[] memory, address, address, uint256, uint256, uint256, bool, uint256) {
        return (path, collateralToken, indexToken, amountIn, minOut, sizeDelta, isLong, acceptablePrice);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IERC20.sol";
import "./IRouter.sol";
import "./IPositionRouter.sol";

interface IGmxAdapter is IERC20, IRouter, IPositionRouter {
    function initialize(address _router, address _positionRouter, address _owner) external;
    function approve(address token, address spender, uint256 amount) external;
    function createIncreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice
    ) external payable returns (bytes32);
    function createIncreasePositionETH(
        address[] memory _path,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice
    ) external payable returns (bytes32);
    function closePosition(
        address[] memory _path, 
        address _receiver, 
        uint256 _acceptablePrice, 
        bool _withdrawETH
    ) external payable returns (bytes32);
    function withdrawToken(address token, address to, uint256 amount) external returns (bool);
    function withdrawEth(address to, uint256 amount) external returns (bool);
    function getPositionData() external view returns (address[] memory, address, address, uint256, uint256, uint256, bool, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IReader {
    function getPositions(address _vault, address _account, address[] memory _collateralTokens, address[] memory _indexTokens, bool[] memory _isLong) external view returns(uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IRouter {
    function approvePlugin(address _plugin) external;
    function vault() external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IPositionRouter {
    function minExecutionFee() external returns (uint256);
    
    function createIncreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) external payable returns (bytes32);
    
    function createIncreasePositionETH(
        address[] memory _path,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) external payable returns (bytes32);
    
    function createDecreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _acceptablePrice,
        uint256 _minOut,
        uint256 _executionFee,
        bool _withdrawETH,
        address _callbackTarget
    ) external payable returns (bytes32);
    
}