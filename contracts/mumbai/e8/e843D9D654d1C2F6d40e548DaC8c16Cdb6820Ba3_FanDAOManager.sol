// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./interfaces/IFanTokenFactory.sol";
import "./interfaces/IFanToken.sol";
import "./interfaces/IIDO.sol";
import "./interfaces/IIDOFactory.sol";
import "./interfaces/ITokenLock.sol";
import "./interfaces/ITokenLockFactory.sol";
import "./interfaces/ITokenStakingFactory.sol";
import "./interfaces/IFeeCollectorFactory.sol";

contract FanDAOManager {
    // 100 million
    uint public MaxSupply = 100000000 * 10 ** 18;

    address public TokenStakingFactory;
    address public FanTokenFactory;
    address public FeeCollectorFactory;
    address public TokenLockFactory;
    address public IDOFactory;

    address public WETH;

    event FanTokenCreate(address fanTokenAddress, string name, string symbol);
    event TokenLockCreate(address tokenLockAddress, address fanTokenAddress, address locker, uint lockAmount, uint startTime, uint endTime);
    event IDOCreate(address idoAddress, address fanTokenAddress, uint amount, uint price);
    event FeeCollectorCreate(address feeCollectorAddress, address stakingAddress);
    event TokenStakingCreate(address tokenStakingAddress, address fanTokenAddress);

    constructor(address _WETH, address fanTokenFactory, address tokenStakingFactory, address feeCollectorFactory,
        address tokenLockFactory,
        address _IDOFactory) {
        WETH = _WETH;
        FanTokenFactory = fanTokenFactory;
        TokenStakingFactory = tokenStakingFactory;
        FeeCollectorFactory = feeCollectorFactory;
        TokenLockFactory = tokenLockFactory;
        IDOFactory = _IDOFactory;
    }

    function initialFan(string memory name, string memory symbol, uint startTime, uint endTime, uint idoPrice) public {
        // create fan token
        address fanToken = IFanTokenFactory(FanTokenFactory).createFanToken(name, symbol);
        emit FanTokenCreate(fanToken, name, symbol);
        // create token lock
        address tokenLock = ITokenLockFactory(TokenLockFactory).createTokenLock(fanToken);
        // mint for IDO
        // address _fanToken, address _WETH, uint _price, uint amount, address _receiver
        address ido = IIDOFactory(IDOFactory).createIDO(fanToken, WETH, msg.sender);
        IFanToken(fanToken).mint(ido, MaxSupply / 2);
        IIDO(ido).createIDO(idoPrice, MaxSupply / 2, startTime, endTime);
        emit IDOCreate(ido, fanToken, MaxSupply / 2, 1 * 10 ** 18);

        // mint for lock
        IFanToken(fanToken).mint(address(tokenLock), MaxSupply / 2);
        ITokenLock(tokenLock).lock(MaxSupply / 2, startTime, endTime, msg.sender);
        emit TokenLockCreate(address(tokenLock), fanToken, msg.sender, MaxSupply / 2, startTime, endTime);

        // create Staking Contract
        address tokenStaking = ITokenStakingFactory(TokenStakingFactory).createTokenStaking(WETH, fanToken);
        emit TokenStakingCreate(tokenStaking, fanToken);

        // create FeeCollector
        address feeCollector = IFeeCollectorFactory(FeeCollectorFactory).createFeeCollector(WETH, tokenStaking);
        emit FeeCollectorCreate(feeCollector, tokenStaking);

    }
}

pragma solidity ^0.8.0;

interface IFanToken {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external view returns (bytes32);
    function nonces(address owner) external view returns (uint256);
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}

pragma solidity ^0.8.0;

interface IFanTokenFactory {
    function createFanToken(string memory name, string memory symbol) external returns (address);
}

pragma solidity ^0.8.0;

interface IFeeCollectorFactory {
    function createFeeCollector(address WETH, address fanToken) external returns (address);
}

pragma solidity ^0.8.0;

interface IIDO {
    function createIDO(uint _price, uint amount, uint _startTime, uint _endTime) external;
}

pragma solidity ^0.8.0;

interface IIDOFactory {
    function createIDO(address _fanToken, address _WETH, address _receiver) external returns (address);
}

pragma solidity ^0.8.0;

interface ITokenLock {
    function lock(uint _lockedAmount, uint _releaseStartTime, uint _releaseEndTime, address _locker) external;
}

pragma solidity ^0.8.0;

interface ITokenLockFactory {
    function createTokenLock(address _lockedToken) external returns (address);
}

pragma solidity ^0.8.0;

interface ITokenStakingFactory {
    function createTokenStaking(address WETH, address fanToken) external returns (address);
}