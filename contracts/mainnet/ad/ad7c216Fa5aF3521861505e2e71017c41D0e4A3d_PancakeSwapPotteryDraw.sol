pragma solidity ^0.8.4;

import {IERC165} from "./IERC165.sol";
import {Ownable} from "./Ownable.sol";
import {SafeERC20, IERC20} from "./SafeERC20.sol";
import {IRandomNumberGenerator} from "./IRandomNumberGenerator.sol";
import {Pottery} from "./Pottery.sol";
import {Vault} from "./Vault.sol";
import {IPancakeSwapPotteryDraw} from "./IPancakeSwapPotteryDraw.sol";
import {IPancakeSwapPotteryVault} from "./IPancakeSwapPotteryVault.sol";
import {IPotteryVaultFactory} from "./IPotteryVaultFactory.sol";
import {ICakePool} from "./ICakePool.sol";
import {IPotteryKeeper} from "./IPotteryKeeper.sol";

contract PancakeSwapPotteryDraw is IPancakeSwapPotteryDraw, Ownable {
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 reward;
        uint256 winCount;
    }

    IERC20 immutable cake;
    ICakePool immutable cakePool;
    IRandomNumberGenerator rng;
    IPotteryVaultFactory vaultFactory;
    IPotteryKeeper keeper;

    uint8 constant NUM_OF_WINNER = 8;
    uint8 constant NUM_OF_DRAW = 10;
    uint32 constant POTTERY_PERIOD = 1 weeks;
    uint32 constant START_TIME_BUFFER = 2 weeks;
    uint32 constant DRAW_TIME_BUFFER = 1 weeks;

    mapping(address => Pottery.Pot) pots;

    mapping(address => UserInfo) public userInfos;

    Pottery.Draw[] draws;

    address treasury;
    uint16 public claimFee;

    bool initialize;

    event Init(address admin);

    event CreatePottery(
        address indexed vault,
        uint256 totalPrize,
        uint256 lockTime,
        uint256 drawTime,
        uint256 maxTotalDeposit,
        address admin
    );

    event RedeemPrize(address indexed vault, uint256 actualPrize, uint256 redeemPrize);

    event StartDraw(
        uint256 indexed drawId,
        address indexed vault,
        uint256 indexed requestId,
        uint256 totalPrize,
        uint256 timestamp,
        address admin
    );
    event CloseDraw(
        uint256 indexed drawId,
        address indexed vault,
        uint256 indexed requestId,
        address[] winners,
        uint256 timestamp,
        address admin
    );

    event ClaimReward(address indexed winner, uint256 prize, uint256 fee, uint256 winCount);

    event SetVaultFactory(address admin, address vaultFactory);

    event SetKeeper(address admin, address keeper);

    event SetTreasury(address admin, address treasury);

    event SetClaimFee(address admin, uint16 fee);

    event CancelPottery(address indexed vault, uint256 totalPrize, address admin);

    modifier onlyKeeperOrOwner() {
        require(msg.sender == address(keeper) || msg.sender == owner(), "only keeper or owner");
        _;
    }

    constructor(IERC20 _cake, ICakePool _cakePool) {
        require(address(_cake) != address(0) && address(_cakePool) != address(0), "zero address");

        cake = _cake;
        cakePool = _cakePool;

        initialize = false;
    }

    function init(
        address _rng,
        address _vaultFactory,
        address _keeper,
        address _treasury
    ) external onlyOwner {
        require(!initialize, "init already");

        require(IERC165(_rng).supportsInterface(type(IRandomNumberGenerator).interfaceId), "invalid rng");
        rng = IRandomNumberGenerator(_rng);

        setVaultFactory(_vaultFactory);
        setKeeper(_keeper);
        setTreasury(_treasury);
        setClaimFee(800);

        initialize = true;
        emit Init(msg.sender);
    }

    function generatePottery(
        uint256 _totalPrize,
        uint256 _lockTime,
        uint256 _drawTime,
        uint256 _maxTotalDeposit
    ) public override onlyOwner {
        require(_totalPrize > 0, "zero prize");
        // draw time must be larger than lock time
        require(_drawTime > _lockTime, "draw time earlier than lock time");
        // draw time must be within 1 week of the lock time to finish the draw before unlock
        require(_drawTime < _lockTime + DRAW_TIME_BUFFER, "draw time outside draw buffer time");
        // everything must start in 2 weeks
        require(_drawTime < block.timestamp + START_TIME_BUFFER, "draw time outside start buffer time");
        // the _maxDepositAmount should be greater than 0
        require(_maxTotalDeposit > 0, "zero total deposit");
        uint256 denominator = NUM_OF_DRAW * NUM_OF_WINNER;
        uint256 prize = _totalPrize / denominator;
        require(prize > 0, "zero prize in each winner");
        require(prize % denominator == 0, "winner prize has reminder");

        cake.safeTransferFrom(msg.sender, address(this), _totalPrize);
        address vault = vaultFactory.generateVault(
            cake,
            cakePool,
            PancakeSwapPotteryDraw(address(this)),
            msg.sender,
            address(keeper),
            _lockTime,
            _maxTotalDeposit
        );
        require(vault != address(0), "zero deploy address");
        IPotteryKeeper(keeper).addActiveVault(vault);
        pots[vault] = Pottery.Pot({
            numOfDraw: 0,
            totalPrize: _totalPrize,
            drawTime: _drawTime,
            lastDrawId: 0,
            startDraw: false
        });

        emit CreatePottery(vault, _totalPrize, _lockTime, _drawTime, _maxTotalDeposit, msg.sender);
    }

    function redeemPrizeByRatio() external override {
        // only allow call from vault
        uint256 totalPrize = pots[msg.sender].totalPrize;
        require(totalPrize > 0, "pot not exist");
        require(IPancakeSwapPotteryVault(msg.sender).getStatus() == Vault.Status.BEFORE_LOCK, "pot pass before lock");
        uint256 depositRatio = (IPancakeSwapPotteryVault(msg.sender).totalAssets() * 10000) /
            IPancakeSwapPotteryVault(msg.sender).getMaxTotalDeposit();
        uint256 actualPrize = (totalPrize * depositRatio) / 10000;

        uint256 denominator = NUM_OF_DRAW * NUM_OF_WINNER;
        uint256 prize = actualPrize / denominator;
        require(prize > 0, "zero prize in each winner");
        if (actualPrize % denominator != 0) actualPrize -= actualPrize % denominator;

        uint256 redeemPrize = totalPrize - actualPrize;
        pots[msg.sender].totalPrize = actualPrize;
        if (redeemPrize > 0) cake.safeTransfer(treasury, redeemPrize);

        emit RedeemPrize(msg.sender, actualPrize, redeemPrize);
    }

    function startDraw(address _vault) external override onlyKeeperOrOwner {
        Pottery.Pot storage pot = pots[_vault];
        require(pot.totalPrize > 0, "pot not exist");
        require(pot.numOfDraw < NUM_OF_DRAW, "over draw limit");
        require(timeToDraw(_vault), "too early to draw");
        if (pot.startDraw) {
            Pottery.Draw memory draw = draws[pot.lastDrawId];
            require(draw.closeDrawTime != 0, "last draw has not closed");
        }
        uint256 prize = pot.totalPrize / NUM_OF_DRAW;
        uint256 requestId = rng.requestRandomWords(NUM_OF_WINNER, _vault);
        uint256 drawId = draws.length;
        draws.push(
            Pottery.Draw({
                requestId: requestId,
                vault: IPancakeSwapPotteryVault(_vault),
                startDrawTime: block.timestamp,
                closeDrawTime: 0,
                winners: new address[](NUM_OF_WINNER),
                prize: prize
            })
        );

        pot.lastDrawId = drawId;
        if (!pot.startDraw) pot.startDraw = true;

        emit StartDraw(drawId, _vault, requestId, prize, block.timestamp, msg.sender);
    }

    function forceRequestDraw(address _vault) external override onlyOwner {
        Pottery.Pot storage pot = pots[_vault];
        Pottery.Draw storage draw = draws[pot.lastDrawId];
        require(address(draw.vault) != address(0), "draw not exist");
        require(draw.startDrawTime != 0 && draw.closeDrawTime == 0, "draw has closed");
        require(!rng.fulfillRequest(draw.requestId), "request has fulfilled");
        uint256 requestId = rng.requestRandomWords(NUM_OF_WINNER, _vault);

        draw.requestId = requestId;

        emit StartDraw(pot.lastDrawId, _vault, requestId, draw.prize, block.timestamp, msg.sender);
    }

    function closeDraw(uint256 _drawId) external override onlyKeeperOrOwner {
        Pottery.Draw storage draw = draws[_drawId];
        require(address(draw.vault) != address(0), "draw not exist");
        require(draw.startDrawTime != 0, "draw has not started");
        require(draw.closeDrawTime == 0, "draw has closed");
        draw.closeDrawTime = block.timestamp;

        require(draw.requestId == rng.getLatestRequestId(address(draw.vault)), "requestId not match");
        require(rng.fulfillRequest(draw.requestId), "rng request not fulfill");
        uint256[] memory randomWords = rng.getRandomWords(draw.requestId);
        require(randomWords.length == NUM_OF_WINNER, "winning number not match");
        address[] memory winners = draw.vault.draw(randomWords);
        require(winners.length == NUM_OF_WINNER, "winners not match");
        uint256 eachWinnerPrize = draw.prize / NUM_OF_WINNER;
        for (uint256 i = 0; i < NUM_OF_WINNER; i++) {
            draw.winners[i] = winners[i];
            userInfos[winners[i]].reward += eachWinnerPrize;
            userInfos[winners[i]].winCount += 1;
        }

        Pottery.Pot storage pot = pots[address(draw.vault)];
        pot.numOfDraw += 1;

        emit CloseDraw(_drawId, address(draw.vault), draw.requestId, draw.winners, block.timestamp, msg.sender);
    }

    function claimReward() external override {
        require(userInfos[msg.sender].reward > 0, "nothing to claim");
        uint256 reward = userInfos[msg.sender].reward;
        uint256 winCount = userInfos[msg.sender].winCount;
        uint256 fee = (reward * claimFee) / 10000;
        userInfos[msg.sender].reward = 0;
        userInfos[msg.sender].winCount = 0;
        if (fee > 0) cake.safeTransfer(treasury, fee);
        cake.safeTransfer(msg.sender, (reward - fee));

        emit ClaimReward(msg.sender, reward, fee, winCount);
    }

    function timeToDraw(address _vault) public view override returns (bool) {
        Pottery.Pot storage pot = pots[_vault];
        if (pot.startDraw) {
            Pottery.Draw storage draw = draws[pot.lastDrawId];
            return (draw.startDrawTime + POTTERY_PERIOD <= block.timestamp);
        } else {
            return (pot.drawTime <= block.timestamp);
        }
    }

    function rngFulfillRandomWords(uint256 _drawId) public view override returns (bool) {
        Pottery.Draw storage draw = draws[_drawId];
        return rng.fulfillRequest(draw.requestId);
    }

    function getWinners(uint256 _drawId) external view override returns (address[] memory) {
        return draws[_drawId].winners;
    }

    function getDraw(uint256 _drawId) external view override returns (Pottery.Draw memory) {
        return draws[_drawId];
    }

    function getPot(address _vault) external view override returns (Pottery.Pot memory) {
        return pots[_vault];
    }

    function getNumOfDraw() external view override returns (uint8) {
        return NUM_OF_DRAW;
    }

    function getNumOfWinner() external view override returns (uint8) {
        return NUM_OF_WINNER;
    }

    function getPotteryPeriod() external view override returns (uint256) {
        return POTTERY_PERIOD;
    }

    function getTreasury() external view override returns (address) {
        return treasury;
    }

    function setVaultFactory(address _factory) public onlyOwner {
        require(_factory != address(0), "zero address");
        vaultFactory = IPotteryVaultFactory(_factory);

        emit SetVaultFactory(msg.sender, _factory);
    }

    function setKeeper(address _keeper) public onlyOwner {
        require(_keeper != address(0), "zero address");
        keeper = IPotteryKeeper(_keeper);

        emit SetKeeper(msg.sender, _keeper);
    }

    function setTreasury(address _treasury) public onlyOwner {
        require(_treasury != address(0), "zero address");
        treasury = _treasury;

        emit SetTreasury(msg.sender, _treasury);
    }

    function setClaimFee(uint16 _fee) public onlyOwner {
        require(_fee <= 1000, "over max fee limit");
        claimFee = _fee;

        emit SetClaimFee(msg.sender, _fee);
    }

    function cancelPottery(address _vault) external onlyOwner {
        require(IPancakeSwapPotteryVault(_vault).getStatus() == Vault.Status.BEFORE_LOCK, "pottery started");
        Pottery.Pot storage pot = pots[_vault];
        require(pot.totalPrize > 0, "pottery not exist");
        require(pot.numOfDraw == 0, "pottery cancelled");
        uint256 prize = pot.totalPrize;
        pot.totalPrize = 0;
        pot.numOfDraw = NUM_OF_DRAW;
        cake.safeTransfer(treasury, prize);

        emit CancelPottery(_vault, prize, msg.sender);
    }
}