pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "../deployment/Deployer.sol";
import "../deployment/ManagedContract.sol";
import "../interfaces/IProtocolSettings.sol";
import "../interfaces/IOptionsExchange.sol";
import "../interfaces/IGovernableLiquidityPool.sol";

contract ProtocolReader is ManagedContract {

    IProtocolSettings private settings;
    IOptionsExchange private exchange;

    event IncentiveReward(address indexed from, uint value);

    function initialize(Deployer deployer) override internal {
        settings = IProtocolSettings(deployer.getContractAddress("ProtocolSettings"));
        exchange = IOptionsExchange(deployer.getContractAddress("OptionsExchange"));
    }

    function listPoolsData() external view returns (string[] memory, address[] memory){
      uint poolSymbolsMaxLen = exchange.totalPoolSymbols();
      string[] memory poolSymbols = new string[](poolSymbolsMaxLen);
      address[] memory poolAddrs = new address[](poolSymbolsMaxLen);
      for (uint i=0; i < poolSymbolsMaxLen; i++) {
          string memory pSym = exchange.poolSymbols(i);
          poolSymbols[i] = pSym;
          address poolAddr = exchange.getPoolAddress(pSym);
          poolAddrs[i] = poolAddr;
      }

      return (poolSymbols, poolAddrs);
    }
}

pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

interface IProtocolSettings {
	function getCreditWithdrawlTimeLock() external view returns (uint);
    function updateCreditWithdrawlTimeLock(uint duration) external;
	function checkPoolBuyCreditTradable(address poolAddress) external view returns (bool);
	function checkUdlIncentiveBlacklist(address udlAddr) external view returns (bool);
	function checkDexAggIncentiveBlacklist(address dexAggAddress) external view returns (bool);
    function checkPoolSellCreditTradable(address poolAddress) external view returns (bool);
	function applyCreditInterestRate(uint value, uint date) external view returns (uint);
	function getSwapRouterInfo() external view returns (address router, address token);
	function getSwapRouterTolerance() external view returns (uint r, uint b);
	function getSwapPath(address from, address to) external view returns (address[] memory path);
    function getTokenRate(address token) external view returns (uint v, uint b);
    function getCirculatingSupply() external view returns (uint);
    function getUdlFeed(address addr) external view returns (int);
    function setUdlCollateralManager(address udlFeed, address ctlMngr) external;
    function getUdlCollateralManager(address udlFeed) external view returns (address);
    function getVolatilityPeriod() external view returns(uint);
    function getAllowedTokens() external view returns (address[] memory);
    function setDexOracleTwapPeriod(address dexOracleAddress, uint256 _twapPeriod) external;
    function getDexOracleTwapPeriod(address dexOracleAddress) external view returns (uint256);
    function setBaseIncentivisation(uint amount) external;
    function getBaseIncentivisation() external view returns (uint);
    function getProcessingFee() external view returns (uint v, uint b);
    function getMinShareForProposal() external view returns (uint v, uint b);
    function isAllowedHedgingManager(address hedgeMngr) external view returns (bool);
    function isAllowedCustomPoolLeverage(address poolAddr) external view returns (bool);
    function exchangeTime() external view returns (uint256);
}

pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

interface IOptionsExchange {
    enum OptionType { CALL, PUT }
    
    struct OptionData {
        address udlFeed;
        OptionType _type;
        uint120 strike;
        uint32 maturity;
    }

    struct FeedData {
        uint120 lowerVol;
        uint120 upperVol;
    }

    struct OpenExposureVars {
        string symbol;
        uint vol;
        bool isCovered;
        address poolAddr;
        address[] _tokens;
        uint[] _uncovered;
        uint[] _holding;
    }

    struct OpenExposureInputs {
        string[] symbols;
        uint[] volume;
        bool[] isShort;
        bool[] isCovered;
        address[] poolAddrs;
        address[] paymentTokens;
    }

    function volumeBase() external view returns (uint);
    function collateral(address owner) external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function resolveToken(string calldata symbol) external view returns (address);
    function getExchangeFeeds(address udlFeed) external view returns (FeedData memory);
    function getFeedData(address udlFeed) external view returns (FeedData memory fd);
    function getBook(address owner) external view returns (string memory symbols, address[] memory tokens, uint[] memory holding, uint[] memory written, uint[] memory uncovered, int[] memory iv, address[] memory underlying);
    function getOptionData(address tkAddr) external view returns (IOptionsExchange.OptionData memory);
    function calcExpectedPayout(address owner) external view returns (int payout);
    function calcIntrinsicValue(address udlFeed, OptionType optType, uint strike, uint maturity) external view returns (int);
    function calcIntrinsicValue(OptionData calldata opt) external view returns (int value);
    function getUdlPrice(IOptionsExchange.OptionData calldata opt) external view returns (int answer);
    function calcCollateral(address owner, bool is_regular) external view returns (uint);
    function calcCollateral(address udlFeed, uint volume, OptionType optType, uint strike,  uint maturity) external view returns (uint);
    function openExposure(
        OpenExposureInputs calldata oEi,
        address to
    ) external;
    function transferBalance(address to, uint value) external;
    function poolSymbols(uint index) external view returns (string memory);
    function totalPoolSymbols() external view returns (uint);
    function getPoolAddress(string calldata poolSymbol) external view returns (address);
    function transferBalance(address from, address to, uint value) external;
    function underlyingBalance(address owner, address _tk) external view returns (uint);
    function getOptionSymbol(OptionData calldata opt) external view returns (string memory symbol);
    function cleanUp(address owner, address _tk) external;
    function release(address owner, uint udl, uint coll) external;
    function depositTokens(address to, address token, uint value) external;
    function transferOwnership(string calldata symbol, address from, address to, uint value) external;
}

pragma solidity >=0.6.0;

import "../interfaces/IOptionsExchange.sol";


interface IGovernableLiquidityPool {

    enum Operation { NONE, BUY, SELL }

    struct PricingParameters {
        address udlFeed;
        IOptionsExchange.OptionType optType;
        uint120 strike;
        uint32 maturity;
        uint32 t0;
        uint32 t1;
        uint[3] bsStockSpread; //buyStock == bsStockSpread[0], sellStock == bsStockSpread[1], spread == bsStockSpread[2]
        uint120[] x;
        uint120[] y;
    }

    struct Range {
        uint120 start;
        uint120 end;
    }

    event AddSymbol(string optSymbol);
    
    //event RemoveSymbol(string optSymbol);

    event Buy(address indexed token, address indexed buyer, uint price, uint volume);
    
    event Sell(address indexed token, address indexed seller, uint price, uint volume);

    function yield(uint dt) external view returns (uint);

    function depositTokens(address to, address token, uint value) external;

    function withdraw(uint amount) external;

    function listSymbols() external view returns (string memory available);

    function queryBuy(string calldata optSymbol, bool isBuy) external view returns (uint price, uint volume);


    function buy(string calldata optSymbol, uint price, uint volume, address token)
        external
        returns (address addr);

    function sell(
        string calldata optSymbol,
        uint price,
        uint volume
    )
        external;

    function getHedgingManager() external view returns (address manager);
    function getLeverage() external view returns (uint leverage);
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

// *** IMPORTANT ***
// "onwer" storage variable must be set to a GnosisSafe multisig wallet address:
// - https://github.com/gnosis/safe-contracts/blob/main/contracts/GnosisSafe.sol

contract Proxy {

    // ATTENTION: storage variable alignment
    address private owner;
    address private pendingOwner;
    address private implementation;
    uint private locked; // 1 = Initialized; 2 = Non upgradable
    // --------------------------------------------------------

    event OwnershipTransferRequested(address indexed from, address indexed to);
    
    event OwnershipTransferred(address indexed from, address indexed to);

    event SetNonUpgradable();

    event ImplementationUpdated(address indexed from, address indexed to);

    constructor(address _owner, address _implementation) public {

        owner = _owner;
        implementation = _implementation;
    }

    fallback () payable external {
        
        _fallback();
    }

    receive () payable external {

        _fallback();
    }
    
    function transferOwnership(address _to) external {
        
        require(msg.sender == owner);
        pendingOwner = _to;
        emit OwnershipTransferRequested(owner, _to);
    }

    function acceptOwnership() external {
    
        require(msg.sender == pendingOwner);
        address oldOwner = owner;
        owner = msg.sender;
        pendingOwner = address(0);
        emit OwnershipTransferred(oldOwner, msg.sender);
    }

    function setNonUpgradable() public {

        require(msg.sender == owner && locked == 1);
        locked = 2;
        emit SetNonUpgradable();
    }

    function setImplementation(address _implementation) public {

        require(msg.sender == owner && locked != 2);
        address oldImplementation = implementation;
        implementation = _implementation;
        emit ImplementationUpdated(oldImplementation, _implementation);
    }

    function delegate(address _implementation) internal {
        assembly {

            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result

            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    function _fallback() internal {
        willFallback();
        delegate(implementation);
    }

    function willFallback() internal virtual {
        
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Deployer.sol";
// *** IMPORTANT ***
// "onwer" storage variable must be set to a GnosisSafe multisig wallet address:
// - https://github.com/gnosis/safe-contracts/blob/main/contracts/GnosisSafe.sol

contract ManagedContract {

    // ATTENTION: storage variable alignment
    address private owner;
    address private pendingOwner;
    address private implementation;
    uint private locked; // 1 = Initialized; 2 = Non upgradable
    // --------------------------------------------------------

    function initializeAndLock(Deployer deployer) public {

        require(locked == 0, "initialization locked");
        locked = 1;
        initialize(deployer);
    }

    function initialize(Deployer deployer) virtual internal {

    }

    function getOwner() public view returns (address) {

        return owner;
    }

    function getImplementation() public view returns (address) {

        return implementation;
    }
}

pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./ManagedContract.sol";
import "./Proxy.sol";

contract Deployer {

    struct ContractData {
        string key;
        address origAddr;
        bool upgradeable;
    }

    mapping(string => address) private contractMap;
    mapping(string => string) private aliases;

    address private owner;
    ContractData[] private contracts;
    bool private deployed;

    constructor(address _owner) public {

        owner = _owner;
    }

    function hasKey(string memory key) public view returns (bool) {
        
        return contractMap[key] != address(0) || contractMap[aliases[key]] != address(0);
    }

    function setContractAddress(string memory key, address addr) public {

        setContractAddress(key, addr, true);
    }

    function setContractAddress(string memory key, address addr, bool upgradeable) public {
        
        require(!hasKey(key), buildKeyAlreadySetMessage(key));

        ensureNotDeployed();
        ensureCaller();
        
        contracts.push(ContractData(key, addr, upgradeable));
        contractMap[key] = address(1);
    }

    function addAlias(string memory fromKey, string memory toKey) public {
        
        ensureNotDeployed();
        ensureCaller();
        require(contractMap[toKey] != address(0), buildAddressNotSetMessage(toKey));
        aliases[fromKey] = toKey;
    }

    function getContractAddress(string memory key) public view returns (address) {
        
        require(hasKey(key), buildAddressNotSetMessage(key));
        address addr = contractMap[key];
        if (addr == address(0)) {
            addr = contractMap[aliases[key]];
        }
        require(addr != address(1), buildProxyNotDeployedMessage(key));
        return addr;
    }

    function getPayableContractAddress(string memory key) public view returns (address payable) {

        return address(uint160(address(getContractAddress(key))));
    }

    function isDeployed() public view returns(bool) {
        
        return deployed;
    }

    function deploy() public {

        deploy(owner);
    }

    function deploy(address _owner) public {

        ensureNotDeployed();
        ensureCaller();
        deployed = true;

        for (uint i = contracts.length - 1; i != uint(-1); i--) {
            if (contractMap[contracts[i].key] == address(1)) {
                if (contracts[i].upgradeable) {
                    Proxy p = new Proxy(_owner, contracts[i].origAddr);
                    contractMap[contracts[i].key] = address(p);
                } else {
                    contractMap[contracts[i].key] = contracts[i].origAddr;
                }
            } else {
                contracts[i] = contracts[contracts.length - 1];
                contracts.pop();
            }
        }

        for (uint i = 0; i < contracts.length; i++) {
            if (contracts[i].upgradeable) {
                address p = contractMap[contracts[i].key];
                ManagedContract(p).initializeAndLock(this);
            }
        }
    }

    function reset() public {

        ensureCaller();
        deployed = false;

        for (uint i = 0; i < contracts.length; i++) {
            contractMap[contracts[i].key] = address(1);
        }
    }

    function ensureNotDeployed() private view {

        require(!deployed, "already deployed");
    }

    function ensureCaller() private view {

        require(owner == address(0) || msg.sender == owner, "unallowed caller");
    }

    function buildKeyAlreadySetMessage(string memory key) private pure returns(string memory) {

        return string(abi.encodePacked("key already set: ", key));
    }

    function buildAddressNotSetMessage(string memory key) private pure returns(string memory) {

        return string(abi.encodePacked("contract address not set: ", key));
    }

    function buildProxyNotDeployedMessage(string memory key) private pure returns(string memory) {

        return string(abi.encodePacked("proxy not deployed: ", key));
    }
}