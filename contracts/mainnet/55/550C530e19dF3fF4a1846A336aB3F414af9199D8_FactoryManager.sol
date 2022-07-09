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
import "./IGatedERC20.sol";

contract FactoryManager is Owned, TokensRecoverable {
    using SafeMath for uint;

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
        address rootToken;
        address eliteToken;
        address payable MGE;
        address MGD;
        
    }
    struct MGEInfo {
        address MGE;
        address artist;
        uint raisedMatic;
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
    mapping (uint => MGEInfo) public mgeInfo;

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

    function deployNewTokens(
        string calldata name,
        string calldata symbol) public onlySignedAdmin() {
            RootedToken _rootToken = tokenFactory.createRooted(address(this), name, symbol);
            EliteToken _eliteToken = tokenFactory.createElite(address(this));
            tokenDeployments[counter].name = name;
            tokenDeployments[counter].ID = counter;
            tokenDeployments[counter].signedAdministrator = signedAdmin;
            tokenDeployments[counter].rootToken = address(_rootToken);
            tokenDeployments[counter].eliteToken = address(_eliteToken);

        }

    function deployNewMGE() public onlySignedAdmin() {
            //set manager as owner of mge
        MarketGeneration _MGE = mgeFactory.createMGE(address(this));
        MarketDistribution _MGD = mgeFactory.createMGD(address(this));
        tokenDeployments[counter].MGE = address(_MGE);
        tokenDeployments[counter].MGD = address(_MGD);
        //MarketGeneration(tokenDeployments[counter].MGE).setMGEController(address(this));
        
    
    }

    function deployGates() public onlySignedAdmin() {
        LazarusPit _burnPit = calculatorFactory.createLazarusPit(RootedToken(tokenDeployments[counter].rootToken));
        RootedTransferGate _transGate = calculatorFactory.createTransferGate(address(this),RootedToken(tokenDeployments[counter].rootToken));
        EliteFloorCalculatorV1 _calcV1 = calculatorFactory.createCalculatorV1(RootedToken(tokenDeployments[counter].rootToken));
        EliteFloorCalculator _calc = calculatorFactory.createCalculator(RootedToken(tokenDeployments[counter].rootToken), EliteToken(tokenDeployments[counter].eliteToken));
        deployData[counter].burnPit = address(_burnPit);
        deployData[counter].transGate = address(_transGate);
        deployData[counter].calcV1 = address(_calcV1);
        deployData[counter].calc = address(_calc);
    }
    function deployFeeSplitter() public onlySignedAdmin() {
     FeeSplitter _feeSplitter = feeSplitterFactory.createFeeSplitter(address(this));
     MarketDistribution(tokenDeployments[counter].MGD).init(RootedToken(tokenDeployments[counter].rootToken), EliteToken(tokenDeployments[counter].eliteToken), deployData[counter].burnPit, address(_router), _router, MarketGeneration(tokenDeployments[counter].MGE), 1, 100);
     LiquidityController _liquidityController = controllerFactory.createLiquidityController(address(this),RootedToken(tokenDeployments[counter].rootToken), EliteToken(tokenDeployments[counter].eliteToken), EliteFloorCalculator(deployData[counter].calc), RootedTransferGate(deployData[counter].transGate));
     deployData[counter].feeSplitter = address(_feeSplitter);
     deployData[counter].liquidityController = address(_liquidityController);
    
    }
    function deployStaking(string calldata xName, string calldata xSymbol) public onlySignedAdmin(){
        StakingToken _staking = feeSplitterFactory.createStaking(address(this), RootedToken(tokenDeployments[counter].rootToken), xName, xSymbol);
        RoyaltyPump _pump = feeSplitterFactory.createRoyaltyPump(address(this), address(_staking), address(RootedToken(tokenDeployments[counter].rootToken)), RootedTransferGate(deployData[counter].transGate));
        TokenTimelock _tokenLock = controllerFactory.createTokenTimelock(address(this));
        deployData[counter].staking = address(_staking);
        deployData[counter].royaltyPump = address(_pump);
        deployData[counter].tokenLock = address(_tokenLock);
    }

    function MGESetup() public onlySignedAdmin() {
         MarketGeneration(tokenDeployments[counter].MGE).init(wrappedToken);
        //TODO Update signed admin before deeploying any contracts
        
        MarketGeneration(tokenDeployments[counter].MGE).setMGEController(signedAdmin, true);
        MarketDistribution(tokenDeployments[counter].MGD).init(RootedToken(tokenDeployments[counter].rootToken), EliteToken(tokenDeployments[counter].eliteToken), deployData[counter].burnPit, deployData[counter].liquidityController, _router, MarketGeneration(tokenDeployments[counter].MGE), 1, 100);
        MarketDistribution(tokenDeployments[counter].MGD).setupEliteRooted();
        MarketDistribution(tokenDeployments[counter].MGD).setupBaseRooted();
        MarketDistribution(tokenDeployments[counter].MGD).completeSetup(); 
    }

    function rootSetup() public onlySignedAdmin() {
        RootedToken(tokenDeployments[counter].rootToken).setTransferGate(RootedTransferGate(deployData[counter].transGate));
        RootedToken(tokenDeployments[counter].rootToken).setMinter(tokenDeployments[counter].MGD);
        RootedToken(tokenDeployments[counter].rootToken).setLiquidityController(address(this), true);
        RootedToken(tokenDeployments[counter].rootToken).setLiquidityController(deployData[counter].transGate, true);

    }
    function eliteSetup() public onlySignedAdmin() {

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

    function transGateSetup() public onlySignedAdmin(){

        

         address _pool = _factory.getPair(address(wrappedToken), tokenDeployments[counter].rootToken);
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

        uint16[] _collectRates = new uint16[](5);
        address[] _collectors = new address[](5);
        function initializeFeeRates() public onlySignedAdmin() {
            _collectRates[0] = 1000;//signed lc
            _collectRates[1] = 500; //burn
            _collectRates[2] = 5000; //staking
            _collectRates[3] = 500; //artist LC
            _collectRates[4] = 3000; //ARTIST
            _collectors[0] = signedLiquidityController; //LC STATIC -- can be removed
            _collectors[1] = address(0x0000000000000000000000000000000000000001); //burn STATIC -- can be removed
            _collectors[2] = address(0x0000000000000000000000000000000000000001); //staking CHANGES -- always going to be on feeSplitters
            _collectors[3] = address(0x0000000000000000000000000000000000000001); //artist lc CHANGES -- always going to be on feeSplitters
            _collectors[4] = address(0x0000000000000000000000000000000000000001); //artist CHANGES -- always going to be on feeSplitters
        }

        function updateCollectRatesOnDeploy(uint16[] memory rates) public onlySignedAdmin(){
            _collectRates = rates;
        }
        function updateCollectorsOnDeploy(address[] memory collectors) public onlySignedAdmin(){
            _collectors = collectors;
        }
        

    function feeLiqSetup(address _artist) public onlySignedAdmin() {

        uint len = _collectors.length;
        _collectors[len.sub(1)] = _artist;
        _collectors[len.sub(2)] = deployData[counter].liquidityController;
        _collectors[len.sub(3)] = deployData[counter].staking;



        FeeSplitter(deployData[counter].feeSplitter).setFees(RootedToken(tokenDeployments[counter].rootToken), 0, 0, 10000);

        //FeeSplitter(deployData[counter].feeSplitter).setChainTokenFeeCollectors(RootedToken(tokenDeployments[counter].rootToken), _collectors, _collectRates);

        FeeSplitter(deployData[counter].feeSplitter).setRootedTokenFeeCollectors(RootedToken(tokenDeployments[counter].rootToken), _collectors, _collectRates);
        
        LiquidityController(deployData[counter].liquidityController).setLiquidityController(address(this), true);
        LiquidityController(deployData[counter].liquidityController).setLiquidityController(tokenDeployments[counter].MGD, true);
        LiquidityController(deployData[counter].liquidityController).setLiquidityController(deployData[counter].transGate, true);
        
        RoyaltyPump(deployData[counter].royaltyPump).setRoyaltyCollector(signedAdmin);

        mgeInfo[counter].artist = _artist;
    }

     function CompleteTokenSetup(
    ) public onlySignedAdmin() {
        counter++;
    } 

 
    //MGE FUNCTIONS

    function setMGELength(uint256 _seconds, uint mgeID) public onlySignedAdmin(){
        MarketGeneration(tokenDeployments[mgeID].MGE).setMGELength(_seconds);
    }

    function setMGECap(uint256 value, uint mgeID) public onlySignedAdmin(){
        MarketGeneration(tokenDeployments[mgeID].MGE).setHardCap(value);
    }

    function activateMGE(uint mgeID, uint mgeLength) public onlySignedAdmin(){
        MarketGeneration(tokenDeployments[mgeID].MGE).activate(MarketDistribution(tokenDeployments[mgeID].MGD), mgeLength);
    }

    function CompleteMGE(uint mgeID) public onlySignedAdmin(){
        MarketGeneration(tokenDeployments[mgeID].MGE).complete(0, 9000, 500);
        stakeAndLockArtistTokens(mgeID);
        liquidityRecovery(mgeID);
        //log MGEInfo to mapping
        mgeInfo[mgeID].MGE = tokenDeployments[mgeID].MGE;
        mgeInfo[mgeID].raisedMatic = MarketGeneration(tokenDeployments[mgeID].MGE).totalContribution();
    }  

    function allowRefunds(uint mgeID) public onlySignedAdmin(){
        MarketGeneration(tokenDeployments[mgeID].MGE).allowRefunds();
    }

    //FEESPLITTER FUNCTIONS
    function setFeeSplitterController(uint deploymentID, address _controller) public onlySignedAdmin(){
        FeeSplitter(deployData[deploymentID].feeSplitter).setRoyaltyCollector(_controller);
    }

    function setFeeSplitterFees(uint deploymentID, uint _burn, uint _sell, uint _keep) public onlySignedAdmin(){
        FeeSplitter(deployData[deploymentID].feeSplitter).setFees(RootedToken(tokenDeployments[deploymentID].rootToken), _burn, _sell, _keep);
    }

    function setChainTokenFeeCollectors(uint deploymentId, address[] memory collectors, uint16[]  memory collectRates) public onlySignedAdmin(){
        FeeSplitter(deployData[deploymentId].feeSplitter).setChainTokenFeeCollectors(RootedToken(tokenDeployments[deploymentId].rootToken), _collectors, _collectRates);
    }

    function setRootedTokenFeeCollectors(uint deploymentId, address[] memory collectors, uint16[]  memory collectRates) public onlySignedAdmin(){
        FeeSplitter(deployData[deploymentId].feeSplitter).setRootedTokenFeeCollectors(RootedToken(tokenDeployments[deploymentId].rootToken), _collectors, _collectRates);
    }

    function payOutFeeSplitter(uint deploymentId) public onlySignedAdmin(){
        FeeSplitter(deployData[deploymentId].feeSplitter).payFees(IGatedERC20(tokenDeployments[deploymentId].rootToken));
    }
    function recoverTokensFeeSplitter(uint deploymentId, address tokenAddress) public onlySignedAdmin(){
        FeeSplitter(deployData[deploymentId].feeSplitter).recoverTokens(IERC20(tokenAddress));
    }

    //liquidity Controller functions
    function setLiquidityController(uint deploymentId, address _controller) public onlySignedAdmin(){
        LiquidityController(deployData[deploymentId].liquidityController).setLiquidityController(_controller, true);
    }
    function addLiquidity(uint deploymentId, address eliteOrBase, uint256 baseAmount) public onlySignedAdmin(){
        LiquidityController(deployData[deploymentId].liquidityController).addLiquidity(eliteOrBase, baseAmount);
    }
    function removeLiquidity(uint deploymentId, address eliteOrBase, uint256 baseAmount) public onlySignedAdmin(){
        LiquidityController(deployData[deploymentId].liquidityController).removeLiquidity(eliteOrBase, baseAmount);
    }
    

    //TRANSFER GATE
    function setFreeParticipant(uint deploymentId, address _participant, bool allow) public onlySignedAdmin(){
        RootedTransferGate(deployData[deploymentId].transGate).setFreeParticipant(_participant, allow);
    }
    function setUnrestrictedController(uint deploymentId, address _controller, bool _allow) public onlySignedAdmin(){
        RootedTransferGate(deployData[deploymentId].transGate).setUnrestrictedController(_controller, _allow);
    }

    //ROYALTY PUMP functions
    function setRoyaltyCollector(uint deploymentId, address _collector) public onlySignedAdmin(){
        RoyaltyPump(deployData[deploymentId].royaltyPump).setRoyaltyCollector(_collector);
    }

    function depositRoyalties(uint deploymentId) public payable onlySignedAdmin(){
        RoyaltyPump(deployData[deploymentId].royaltyPump).depositRoyalties{value: msg.value}();
    }

    //PRIVATE FUNCTIONS
    function stakeAndLockArtistTokens(uint mgeID) private {
        //artist gets 9% of wmatic raised
        uint256 artistWmatic = mgeInfo[mgeID].raisedMatic * 9 / 100;
        //transfer wmatic to artist
        wrappedToken.transfer(mgeInfo[mgeID].artist, artistWmatic);

        //approve stakingtoken contract to spend rooted tokens
        RootedToken(tokenDeployments[mgeID].rootToken).approve(deployData[mgeID].staking, uint256(-1));
        //stake 100k root tokens
        StakingToken(deployData[mgeID].staking).stake(100000000000000000000000);

        //approve tokenlock contract to spend staking tokens
        StakingToken(deployData[mgeID].staking).approve(deployData[mgeID].tokenLock, uint256(-1));

        //lock staking tokens balance
        TokenTimelock(deployData[mgeID].tokenLock).lockTokens(deployData[mgeID].staking, mgeInfo[mgeID].artist, (uint256(100000000000000000000)*1000));
    }

    function liquidityRecovery(uint deploymentId) private {
        //address _elitePool = _factory.getPair(tokenDeployments[deploymentId].eliteToken, tokenDeployments[deploymentId].rootToken);
        uint256 amountToRemove = EliteToken(tokenDeployments[deploymentId].eliteToken).balanceOf(deployData[deploymentId].liquidityController);
        
        LiquidityController(deployData[deploymentId].liquidityController).removeLiquidity(tokenDeployments[deploymentId].eliteToken, amountToRemove);
        LiquidityController(deployData[deploymentId].liquidityController).recoverTokens(IERC20(tokenDeployments[deploymentId].rootToken));

        //transfer recovered tokens to owner
        uint256 balance = IERC20(tokenDeployments[deploymentId].rootToken).balanceOf(address(this));
        IERC20(tokenDeployments[deploymentId].rootToken).transfer(owner, balance);

         //IPancakePair _mainPool = IPancakePair(_pool);
    }



    //RECOVER FUNCTIONS

    function recoverTokensLiquidityController(uint deploymentId, address tokenAddress) public onlySignedAdmin(){
        LiquidityController(deployData[deploymentId].liquidityController).recoverTokens(IERC20(tokenAddress));
    }

    function recoverTokensTransferGate(uint deploymentId, address tokenAddress) public onlySignedAdmin(){
        RootedTransferGate(deployData[deploymentId].transGate).recoverTokens(IERC20(tokenAddress));
    }
    function recoverTokensRooted(uint deploymentId, address tokenAddress) public onlySignedAdmin(){
        RootedToken(tokenDeployments[deploymentId].rootToken).recoverTokens(IERC20(tokenAddress));
    }
    function recoverTokensElite(uint deploymentId, address tokenAddress) public onlySignedAdmin(){
        EliteToken(tokenDeployments[deploymentId].eliteToken).recoverTokens(IERC20(tokenAddress));
    }
    function recoverTokensMGE(uint deploymentId, address tokenAddress) public onlySignedAdmin(){
        MarketGeneration(tokenDeployments[deploymentId].MGE).recoverTokens(IERC20(tokenAddress));
    }
    function recoverTokensMGD(uint deploymentId, address tokenAddress) public onlySignedAdmin(){
        MarketDistribution(tokenDeployments[deploymentId].MGD).recoverTokens(IERC20(tokenAddress));
    }
    function recoverTokensRoyaltyPump(uint deploymentId, address tokenAddress) public onlySignedAdmin(){
        RoyaltyPump(deployData[deploymentId].royaltyPump).recoverTokens(IERC20(tokenAddress));
    }
    function recoverTokensTimelock(uint deploymentId, address tokenAddress) public onlySignedAdmin(){
        TokenTimelock(deployData[deploymentId].tokenLock).recoverTokens(IERC20(tokenAddress));
    }
    function recoverTokensStaking(uint deploymentId, address tokenAddress) public onlySignedAdmin(){
        StakingToken(deployData[deploymentId].staking).recoverTokens(IERC20(tokenAddress));
    }


    
}