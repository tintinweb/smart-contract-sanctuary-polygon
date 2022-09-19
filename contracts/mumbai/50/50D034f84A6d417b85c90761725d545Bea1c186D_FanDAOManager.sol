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
    uint256 public MaxSupply = 100000000 * 10**18;

    address public TokenStakingFactory;
    address public FanTokenFactory;
    address public FeeCollectorFactory;
    address public TokenLockFactory;
    address public IDOFactory;
    address public WETH;

    mapping(address => FanDAO[]) public fanDAOs;

    struct FanDAO {
        address owner;
        address fanToken;
        address tokenStaking;
        address feeCollector;
        address tokenLock;
        address ido;
        string name;
        string symbol;
        uint256 maxSupply;
    }

    event FanDAOCreated(
        address owner,
        address fanToken,
        address tokenStaking,
        address feeCollector,
        address tokenLock,
        address ido,
        string name,
        string symbol,
        uint256 maxSupply
    );
    event FanTokenCreate(
        address fanTokenAddress,
        string name,
        string symbol,
        uint256 maxSupply
    );
    event TokenLockCreate(
        address tokenLockAddress,
        address fanTokenAddress,
        address locker,
        uint256 lockAmount,
        uint256 idoStartTime,
        uint256 idoEndTime
    );
    event IDOCreate(
        address idoAddress,
        address fanTokenAddress,
        uint256 amount,
        uint256 price
    );
    event FeeCollectorCreate(
        address feeCollectorAddress,
        address stakingAddress
    );
    event TokenStakingCreate(
        address tokenStakingAddress,
        address fanTokenAddress
    );

    constructor(
        address _WETH,
        address fanTokenFactory,
        address tokenStakingFactory,
        address feeCollectorFactory,
        address tokenLockFactory,
        address _IDOFactory
    ) {
        WETH = _WETH;
        FanTokenFactory = fanTokenFactory;
        TokenStakingFactory = tokenStakingFactory;
        FeeCollectorFactory = feeCollectorFactory;
        TokenLockFactory = tokenLockFactory;
        IDOFactory = _IDOFactory;
    }

    function initialFan(
        string memory name,
        string memory symbol,
        uint256 idoStartTime,
        uint256 idoEndTime,
        uint256 releaseStartTime,
        uint256 releaseEndTime,
        uint256 idoPrice
    ) public {
        require(
            idoStartTime < idoEndTime,
            "idoStartTime must be less than idoEndTime"
        );
        require(
            releaseStartTime < releaseEndTime,
            "releaseEndTime must be greater than idoEndTime"
        );
        FanDAO memory fanDAO;
        fanDAO.maxSupply = MaxSupply;
        fanDAO.name = name;
        fanDAO.symbol = symbol;
        fanDAO.owner = msg.sender;
        // create fan token
        fanDAO.fanToken = createFanToken(name, symbol);
        // create token lock
        fanDAO.tokenLock = createTokenLock(
            fanDAO.fanToken,
            MaxSupply / 2,
            releaseStartTime,
            releaseEndTime
        );
        // create IDO
        fanDAO.ido = createIDO(
            fanDAO.fanToken,
            MaxSupply / 2,
            idoPrice,
            idoStartTime,
            idoEndTime,
            WETH
        );

        // create Staking Contract
        fanDAO.tokenStaking = ITokenStakingFactory(TokenStakingFactory)
            .createTokenStaking(WETH, fanDAO.fanToken);
        emit TokenStakingCreate(fanDAO.tokenStaking, fanDAO.fanToken);
        // create FeeCollector
        fanDAO.feeCollector = IFeeCollectorFactory(FeeCollectorFactory)
            .createFeeCollector(WETH, fanDAO.tokenStaking);
        emit FeeCollectorCreate(fanDAO.feeCollector, fanDAO.tokenStaking);

        fanDAOs[msg.sender].push(fanDAO);
        emit FanDAOCreated(
            fanDAO.owner,
            fanDAO.fanToken,
            fanDAO.tokenStaking,
            fanDAO.feeCollector,
            fanDAO.tokenLock,
            fanDAO.ido,
            fanDAO.name,
            fanDAO.symbol,
            fanDAO.maxSupply
        );
    }

    function createFanToken(string memory name, string memory symbol)
        internal
        returns (address)
    {
        address fanToken = IFanTokenFactory(FanTokenFactory).createFanToken(
            name,
            symbol
        );
        emit FanTokenCreate(fanToken, name, symbol, MaxSupply);
        return fanToken;
    }

    function createTokenLock(
        address fanToken,
        uint256 lockAmount,
        uint256 releaseStartTime,
        uint256 releaseEndTime
    ) internal returns (address) {
        address tokenLock = ITokenLockFactory(TokenLockFactory).createTokenLock(
            fanToken
        );
        IFanToken(fanToken).mint(address(tokenLock), lockAmount);
        ITokenLock(tokenLock).lock(
            lockAmount,
            releaseStartTime,
            releaseEndTime,
            msg.sender
        );
        emit TokenLockCreate(
            tokenLock,
            fanToken,
            msg.sender,
            lockAmount,
            releaseStartTime,
            releaseEndTime
        );
        return tokenLock;
    }

    function createIDO(
        address fanToken,
        uint256 amount,
        uint256 price,
        uint256 startTime,
        uint256 endTime,
        address WETH
    ) internal returns (address) {
        address ido = IIDOFactory(IDOFactory).createIDO(
            fanToken,
            WETH,
            msg.sender
        );
        IFanToken(fanToken).mint(ido, amount);
        IIDO(ido).createIDO(price, amount, startTime, endTime);
        emit IDOCreate(ido, fanToken, amount, price);
        return ido;
    }

    function recordDAO(
        address owner,
        address fanToken,
        address tokenLock,
        address ido,
        address feeCollector,
        address tokenStaking,
        string memory name,
        string memory symbol,
        uint256 maxSupply
    ) public {
        FanDAO memory fanDAO = FanDAO(
            owner,
            fanToken,
            tokenStaking,
            feeCollector,
            tokenLock,
            ido,
            name,
            symbol,
            maxSupply
        );

        fanDAOs[owner].push(fanDAO);
        emit FanDAOCreated(
            owner,
            fanToken,
            tokenStaking,
            feeCollector,
            tokenLock,
            ido,
            name,
            symbol,
            maxSupply
        );
    }

    function getDAOs(address owner)
        public
        view
        returns (FanDAO[] memory fanDAOs_)
    {
        return fanDAOs[owner];
    }

    function getDAO(address owner, uint256 index)
        public
        view
        returns (FanDAO memory fanDAO)
    {
        return fanDAOs[owner][index];
    }
}

pragma solidity ^0.8.0;

interface IFanToken {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function totalSupply() external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external view returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

pragma solidity ^0.8.0;

interface IFanTokenFactory {
    function createFanToken(string memory name, string memory symbol)
        external
        returns (address);
}

pragma solidity ^0.8.0;

interface IFeeCollectorFactory {
    function createFeeCollector(address WETH, address fanToken)
        external
        returns (address);
}

pragma solidity ^0.8.0;

interface IIDO {
    function createIDO(
        uint256 _price,
        uint256 amount,
        uint256 _startTime,
        uint256 _endTime
    ) external;

    function buy(uint256 _amount) external payable;
}

pragma solidity ^0.8.0;

interface IIDOFactory {
    function createIDO(
        address _fanToken,
        address _WETH,
        address _receiver
    ) external returns (address);
}

pragma solidity ^0.8.0;

interface ITokenLock {
    function lock(
        uint256 _lockedAmount,
        uint256 _releaseStartTime,
        uint256 _releaseEndTime,
        address _locker
    ) external;
}

pragma solidity ^0.8.0;

interface ITokenLockFactory {
    function createTokenLock(address _lockedToken) external returns (address);
}

pragma solidity ^0.8.0;

interface ITokenStakingFactory {
    function createTokenStaking(address WETH, address fanToken)
        external
        returns (address);
}