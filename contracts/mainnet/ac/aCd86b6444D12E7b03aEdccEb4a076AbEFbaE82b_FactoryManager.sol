// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "./IERC20.sol";
import "./RootedToken.sol";
import "./Owned.sol";
import "./EliteToken.sol";
import "./MarketGeneration.sol";
import "./MarketDistribution.sol";
import "./LazarusPit.sol";
import "./RootedTransferGate.sol";
import "./EliteFloorCalculator.sol";
import "./EliteFloorCalculatorV1.sol";
import "./FeeSplitter.sol";
import "./LiquidityController.sol";
import "./StakingToken.sol";
import "./RoyaltyPump.sol";
import "./TokenTimelock.sol";
import "./TokenFactory.sol";
import "./MGEFactory.sol";
import "./CalculatorFactory.sol";
import "./FeeSplitterFactory.sol";
import "./ControllerFactory.sol";

contract FactoryManager is Owned {

    TokenFactory tokenFactory;
    MGEFactory mgeFactory;
    CalculatorFactory calculatorFactory;
    FeeSplitterFactory feeSplitterFactory;
    ControllerFactory controllerFactory;

    constructor(TokenFactory _tokenFactory, MGEFactory _mgeFactory ,CalculatorFactory _calculatorFactory, FeeSplitterFactory _feeSplitterFactory, ControllerFactory _controllerFactory) {
        tokenFactory = _tokenFactory;
        mgeFactory = _mgeFactory;
        calculatorFactory = _calculatorFactory;
        feeSplitterFactory = _feeSplitterFactory;
        controllerFactory = _controllerFactory;
    }

    address public signedAdmin;
    address public signedLiquidityController = 0x6cFd1B788ecC0900b6e1f352FF73BEf58FeEc88a;

    //WETH MATIC MAINNET
    IERC20 wrappedToken = IERC20(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    //Pancake MATIC MAINNET
    IPancakeRouter02 _router = IPancakeRouter02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
    IPancakeFactory _factory = IPancakeFactory(0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32);
    struct TokenDeployment {
        string name;
        uint ID;
        address signedAdministrator;
        address rootAddress;
        address eliteToken;
        address payable MGE;
        address MGD;
        
    }
    struct deployInfo {
        address burnPit;
        address transGate;
        address calcV1;
        address calc;
        address feeSplitter;
        address liquidityController;
        address staking;
        address royaltyPump;
        address tokenLock;
    }
    mapping (uint => TokenDeployment) public tokenDeployments;
    mapping (uint => deployInfo) public deployData;

    uint public counter = 0;

    event ERC20TokenCreated(address tokenAddress);

    modifier onlySignedAdmin()
    {
        require(msg.sender == signedAdmin|| msg.sender == owner);
        _;
    }
    

    function updateSignedAddress(address _signedAddress) public ownerOnly() {
        signedAdmin = _signedAddress;
    }

    function deployNewERC20Token(
        string calldata name,
        string calldata symbol,
        string calldata eName,
        string calldata eSymbol,
        address _musicianAddress
    ) public onlySignedAdmin() returns (address) {
        

        RootedToken _rootToken = tokenFactory.createRooted(name, symbol);
        EliteToken _eliteToken = tokenFactory.createElite(eName, eSymbol);
        //set manager as owner of mge
        MarketGeneration _MGE = mgeFactory.createMGE(address(this));
        MarketDistribution _MGD = mgeFactory.createMGD(address(this));
        
        
        
        tokenDeployments[counter] = TokenDeployment(name, counter, signedAdmin, address(_rootToken), address(_eliteToken), address(_MGE), address (_MGD));
        deployPartTwo();
        
       MGESetup();
       rootSetup();
       eliteSetup();
       transGateSetup();
       feeLiqSetup(_musicianAddress); 

        counter++;
        emit ERC20TokenCreated(address(_rootToken));

        return address(_rootToken);
    } 

     function deployPartTwo() private {
        LazarusPit _burnPit = calculatorFactory.createLazarusPit(RootedToken(tokenDeployments[counter].rootAddress));
        RootedTransferGate _transGate = calculatorFactory.createTransferGate(RootedToken(tokenDeployments[counter].rootAddress));
        EliteFloorCalculatorV1 _calcV1 = calculatorFactory.createCalculatorV1(RootedToken(tokenDeployments[counter].rootAddress));
        EliteFloorCalculator _calc = calculatorFactory.createCalculator(RootedToken(tokenDeployments[counter].rootAddress), EliteToken(tokenDeployments[counter].eliteToken));
        FeeSplitter _feeSplitter = feeSplitterFactory.createFeeSplitter(address(this));
        LiquidityController _liquidityController = controllerFactory.createLiquidityController(RootedToken(tokenDeployments[counter].rootAddress), EliteToken(tokenDeployments[counter].eliteToken), _calc, _transGate);
        StakingToken _staking = feeSplitterFactory.createStaking(RootedToken(tokenDeployments[counter].rootAddress));
        RoyaltyPump _pump = feeSplitterFactory.createRoyaltyPump(address(this), address(_staking), address(RootedToken(tokenDeployments[counter].rootAddress)), _transGate);
        TokenTimelock _tokenLock = controllerFactory.createTokenTimelock();

        deployData[counter] = deployInfo(address(_burnPit), address(_transGate), address(_calcV1), address(_calc), address(_feeSplitter), address(_liquidityController), address(_staking), address(_pump), address(_tokenLock));
    }
    

    function MGESetup() private {
         MarketGeneration(tokenDeployments[counter].MGE).init(wrappedToken);
        //TODO Update signed admin before deeploying any contracts
        
        MarketGeneration(tokenDeployments[counter].MGE).setMGEController(signedAdmin);
        MarketDistribution(tokenDeployments[counter].MGD).init(RootedToken(tokenDeployments[counter].rootAddress), EliteToken(tokenDeployments[counter].eliteToken), deployData[counter].burnPit, deployData[counter].liquidityController, _router, MarketGeneration(tokenDeployments[counter].MGE), 1, 100);
        MarketDistribution(tokenDeployments[counter].MGD).setupEliteRooted();
        MarketDistribution(tokenDeployments[counter].MGD).setupBaseRooted();
        MarketDistribution(tokenDeployments[counter].MGD).completeSetup(); 
    }

    function rootSetup() private {
        RootedToken(tokenDeployments[counter].rootAddress).setTransferGate(RootedTransferGate(deployData[counter].transGate));
        RootedToken(tokenDeployments[counter].rootAddress).setMinter(tokenDeployments[counter].MGD);
        RootedToken(tokenDeployments[counter].rootAddress).setLiquidityController(address(this), true);
        RootedToken(tokenDeployments[counter].rootAddress).setLiquidityController(deployData[counter].transGate, true);

    }
    function eliteSetup() private {

        EliteToken(tokenDeployments[counter].eliteToken).setBurnRateController(deployData[counter].transGate, true);
        EliteToken(tokenDeployments[counter].eliteToken).setBurnRate(9000);
        EliteToken(tokenDeployments[counter].eliteToken).setFreeParticipantController(address(this), true);
        EliteToken(tokenDeployments[counter].eliteToken).setFreeParticipant(deployData[counter].liquidityController, true);
        EliteToken(tokenDeployments[counter].eliteToken).setFreeParticipant(tokenDeployments[counter].MGE, true);
        EliteToken(tokenDeployments[counter].eliteToken).setFreeParticipant(tokenDeployments[counter].MGD, true);
        EliteToken(tokenDeployments[counter].eliteToken).setFreeParticipant(deployData[counter].burnPit, true);
        EliteToken(tokenDeployments[counter].eliteToken).setFreeParticipant(address(this), true);
        RootedTransferGate(deployData[counter].transGate).setUnrestrictedController(tokenDeployments[counter].MGD, true);
        EliteToken(tokenDeployments[counter].eliteToken).setFloorCalculator(EliteFloorCalculatorV1(deployData[counter].calcV1));
        EliteToken(tokenDeployments[counter].eliteToken).setSweeper(address(this), true);
        EliteToken(tokenDeployments[counter].eliteToken).setSweeper(tokenDeployments[counter].MGD, true);
        EliteToken(tokenDeployments[counter].eliteToken).setSweeper(deployData[counter].liquidityController, true);
        EliteToken(tokenDeployments[counter].eliteToken).setSweeper(tokenDeployments[counter].MGE, true);

    }

    function transGateSetup() private{

        

         address _pool = _factory.getPair(address(wrappedToken), tokenDeployments[counter].rootAddress);
         IPancakePair _mainPool = IPancakePair(_pool);

        RootedTransferGate(deployData[counter].transGate).setFeeSplitter(deployData[counter].feeSplitter);
        RootedTransferGate(deployData[counter].transGate).setFeeControllers(deployData[counter].liquidityController, true);
        RootedTransferGate(deployData[counter].transGate).setFees(500);
        RootedTransferGate(deployData[counter].transGate).setFreeParticipant(deployData[counter].liquidityController, true);
        RootedTransferGate(deployData[counter].transGate).setFreeParticipant(address(this), true);
        RootedTransferGate(deployData[counter].transGate).setFreeParticipant(deployData[counter].burnPit, true);
        RootedTransferGate(deployData[counter].transGate).setFreeParticipant(tokenDeployments[counter].MGD, true);
        RootedTransferGate(deployData[counter].transGate).setFreeParticipant(tokenDeployments[counter].MGE, true);
        RootedTransferGate(deployData[counter].transGate).setFreeParticipant(deployData[counter].feeSplitter, true);
        RootedTransferGate(deployData[counter].transGate).setFreeParticipant(deployData[counter].staking, true);
        RootedTransferGate(deployData[counter].transGate).setFreeParticipant(deployData[counter].royaltyPump, true);
        RootedTransferGate(deployData[counter].transGate).setFreeParticipant(signedAdmin, true);
        RootedTransferGate(deployData[counter].transGate).setFreeParticipant(signedLiquidityController, true);
        RootedTransferGate(deployData[counter].transGate).setFreeParticipant(deployData[counter].tokenLock, true);
        RootedTransferGate(deployData[counter].transGate).setMainPool(_mainPool);
        RootedTransferGate(deployData[counter].transGate).setPoolTaxRate(_pool, 500);
        RootedTransferGate(deployData[counter].transGate).setUnrestrictedController(deployData[counter].liquidityController, true);
        RootedTransferGate(deployData[counter].transGate).setUnrestrictedController(address(this), true);
        RootedTransferGate(deployData[counter].transGate).setUnrestrictedController(deployData[counter].royaltyPump, true);
        RootedTransferGate(deployData[counter].transGate).setUnrestrictedController(address(signedAdmin), true);
        RootedTransferGate(deployData[counter].transGate).setFeeControllers(address(this), true);

    }

    function feeLiqSetup(address _artist) private {
        
        //TODO UPDATE BELOW
        uint16[5] memory _collectRates = [
            1000,
            5000,
            500,
            500,
            3000
        ];
        //TODO UPDATE BELOW
        address[5] memory _collectors = [
            signedLiquidityController,
            deployData[counter].staking,
            address(0x0000000000000000000000000000000000000001),
            deployData[counter].liquidityController,
            _artist

        ];
        FeeSplitter(deployData[counter].feeSplitter).setFees(RootedToken(tokenDeployments[counter].rootAddress), 0, 0, 10000);

        //FeeSplitter(deployData[counter].feeSplitter).setChainTokenFeeCollectors(RootedToken(tokenDeployments[counter].rootAddress), _collectors, _collectRates);

        FeeSplitter(deployData[counter].feeSplitter).setRootedTokenFeeCollectors(RootedToken(tokenDeployments[counter].rootAddress),_collectors,_collectRates);
        
        LiquidityController(deployData[counter].liquidityController).setLiquidityController(address(this), true);
        LiquidityController(deployData[counter].liquidityController).setLiquidityController(tokenDeployments[counter].MGD, true);
        LiquidityController(deployData[counter].liquidityController).setLiquidityController(deployData[counter].transGate, true);
        
        RoyaltyPump(deployData[counter].royaltyPump).setRoyaltyCollector(signedAdmin);
    }

 
    //MGE FUNCTIONS

    function setMGELength(uint256 _seconds, uint mgeID) public onlySignedAdmin(){
        MarketGeneration(tokenDeployments[mgeID].MGE).setMGELength(_seconds);
    }

    function setMGECap(uint256 value) public onlySignedAdmin(){
        MarketGeneration(tokenDeployments[counter].MGE).setHardCap(value);
    }

    function activateMGE(uint mgeID, uint mgeLength) public onlySignedAdmin(){
        MarketGeneration(tokenDeployments[mgeID].MGE).activate(MarketDistribution(tokenDeployments[mgeID].MGD), mgeLength);
    }

    function CompleteMGE(uint mgeID) public onlySignedAdmin(){
        MarketGeneration(tokenDeployments[mgeID].MGE).complete(0, 9000, 500);
    }  

    
}