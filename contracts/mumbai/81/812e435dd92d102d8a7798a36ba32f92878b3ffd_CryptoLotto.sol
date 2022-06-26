// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./Affiliates.sol";
import "./Owners.sol";
import "./Players.sol";
import "./LuckyNumberGenerator.sol";
import "./Gameplay.sol";
import "./Web3App.sol";

contract CryptoLotto {
    Affiliates private _affiliatesContract;
    Owners private _ownersContract;
    Players private _playersContract;
    LuckyNumberGenerator private _luckyNumberGenerator;
    Gameplay private _gameplayContract;
    Web3App private _web3AppContract;
    
    bool private _isAlive;

    event GameChanged(uint256);
    event AffiliateRegistered(string, address);
    event AffiliateChanged(address);
    event PlayerChanged(address);

    constructor(
        address ownerssContractAddress,
        address affiliatesContractAddress,
        address playersContractAddress,
        address luckyNumberGeneratorAddress,
        address gameplayContractAddress,
        address web3AppContractAddress
    ) {
        _ownersContract = Owners(ownerssContractAddress);
        _ownersContract.setProxy(payable(address(this)));
        _ownersContract.addOwner(msg.sender);

        _affiliatesContract = Affiliates(affiliatesContractAddress);
        _affiliatesContract.setProxy(payable(address(this)));

        _playersContract = Players(playersContractAddress);
        _playersContract.setProxy(payable(address(this)));

        _gameplayContract = Gameplay(gameplayContractAddress);
        _gameplayContract.setProxy(payable(address(this)));

        _luckyNumberGenerator = LuckyNumberGenerator(luckyNumberGeneratorAddress);
        _luckyNumberGenerator.setProxy(payable(address(this)));

        _web3AppContract = Web3App(web3AppContractAddress);
        _web3AppContract.setProxy(payable(address(this)));

        _gameplayContract.init();
        _isAlive = true;
    }

    modifier onlyIsAlive() {
        require(_isAlive, "Not Alive");
        _;
    }

    modifier onlyOwners() {
        require(_ownersContract.isOwner(msg.sender), "Not in the owners list");
        _;
    }

    modifier onlyOwnersAndAffiliates() {
        require(
            _ownersContract.isOwner(msg.sender) || _affiliatesContract.isAffiliate(msg.sender),
            "Not in the owners and affiliates lists"
        );
        _;
    }

    function getOwners() external view onlyIsAlive onlyOwners returns (address[] memory) {
        return _ownersContract.getOwners();
    }

    function addOwner(address owner) external onlyIsAlive onlyOwners {
        _ownersContract.addOwner(owner);
    }

    function isOwner() external view onlyIsAlive returns (bool) {
        return _ownersContract.isOwner(msg.sender);
    }

    function removeOwner(address owner) external onlyIsAlive onlyOwners {
        return _ownersContract.removeOwner(msg.sender, owner);
    }

    function getOwnersBalance() external view onlyIsAlive onlyOwners returns (uint256) {
        return _ownersContract.getOwnersBalance();
    }

    function withdrawProfit(uint256 amount) external onlyIsAlive onlyOwners {
        _ownersContract.withdrawProfit(msg.sender, amount);
    }

    function subsidizePrizePool() external payable onlyIsAlive onlyOwnersAndAffiliates {
        _gameplayContract.subsidizePrizePool(msg.value);
        Game memory game = _gameplayContract.getCurrentGameIInfo();
        emit GameChanged(game.gameIndex);
    }

    function getGamesCount() external view onlyIsAlive returns (uint256) {
        return _gameplayContract.getGamesCount();
    }

    function getGameInfo(uint256 cnt) external view onlyIsAlive returns (Game memory) {
        return _gameplayContract.getGameInfo(cnt);
    }

    function getGamesInfo(uint256 fromIndex, uint256 toIndex) external view onlyIsAlive returns (Game[] memory) {
        return _gameplayContract.getGamesInfo(fromIndex, toIndex);
    }

    function buyTickets(
        uint256[] memory ticketNumbers,
        uint256 gameNumber,
        string memory slug
    ) external payable onlyIsAlive {
        _gameplayContract.buyTickets(ticketNumbers, gameNumber, msg.value);

        Game memory currentGame = _gameplayContract.getGameInfo(gameNumber);
        _playersContract.buyTickets(msg.sender, currentGame, ticketNumbers);

        if (!_affiliatesContract.isAffiliateBySlug(slug)) {
            _ownersContract.addToBalalnce{value: (ticketNumbers.length * (currentGame.ticketPrice * 20)) / 100}();
        } else {
            Affiliate memory affiliate = _affiliatesContract.getAffiliateBySlug(slug);
            _affiliatesContract.registerSell{value: (ticketNumbers.length * (currentGame.ticketPrice * 10)) / 100}(
                affiliate.affiliateAddress,
                ticketNumbers.length
            );
            _ownersContract.addToBalalnce{value: (ticketNumbers.length * (currentGame.ticketPrice * 10)) / 100}();
        }
        emit GameChanged(gameNumber);
        emit PlayerChanged(msg.sender);
    }

    function getMyTicketsInfoCount(uint256 gameNumber) external view returns (uint256) {
        Game memory game = _gameplayContract.getGameInfo(gameNumber);
        return _playersContract.getMyTicketsInfoCount(msg.sender, game);
    }

    function getMyTicketsInfo(
        uint256 gameNumber,
        uint256 fromIndex,
        uint256 toIndex
    ) external view onlyIsAlive returns (uint256[] memory) {
        Game memory game = _gameplayContract.getGameInfo(gameNumber);
        return _playersContract.getMyTicketsInfo(msg.sender, game, fromIndex, toIndex);
    }

    function getUnclaimedRewardsInfo(uint256 gameNumber) external view onlyIsAlive returns (uint256) {
        Game memory currentGame = _gameplayContract.getCurrentGameIInfo();
        if (currentGame.gameIndex - gameNumber > 10) {
            return 0;
        }
        Game memory game = _gameplayContract.getGameInfo(gameNumber);
        require(game.completed, "Game still not completed !!!");
        return _playersContract.getUnclaimedRewardsInfo(msg.sender, game);
    }

    function claimRewards(uint256 gameNumber) external onlyIsAlive {
        Game memory currentGame = _gameplayContract.getCurrentGameIInfo();
        Game memory game = _gameplayContract.getGameInfo(gameNumber);

        require(currentGame.gameIndex - game.gameIndex <= 10, "Too late !!!");

        // Game storage game = _games[gameNumber];
        require(game.completed == true, "Game still not completed !!!");
        uint256 valueToTransfer = _playersContract.getUnclaimedRewardsInfo(msg.sender, game);
        require(valueToTransfer > 0, "No rewards to be claimed !!!");
        _playersContract.claimRewards(msg.sender, game);
        _gameplayContract.rewardsClaimed(gameNumber, valueToTransfer);

        (bool success, ) = msg.sender.call{value: valueToTransfer}("");
        require(success, "Transfer failed.");
        emit GameChanged(gameNumber);
        emit PlayerChanged(msg.sender);
    }

    function registerAffiliate(address affiliateAddress, string memory slug) external onlyIsAlive onlyOwners {
        _affiliatesContract.registerAffiliate(affiliateAddress, slug);
        emit AffiliateRegistered(slug, affiliateAddress);
    }

    function getAffiliateCount() external view onlyIsAlive onlyOwners returns (uint256) {
        return _affiliatesContract.getAffiliateCount();
    }

    function getAffiliates(uint256 start, uint256 maxReturnedCount)
        external
        view
        onlyIsAlive
        onlyOwners
        returns (Affiliate[] memory)
    {
        return _affiliatesContract.getAffiliates(start, maxReturnedCount);
    }

    function registerAsAffiliate(string memory slug) external payable onlyIsAlive {
        Game memory currentGame = _gameplayContract.getCurrentGameIInfo();
        require(msg.value == 1000 * currentGame.ticketPrice, "You need to send 1000 * single ticket value !!!");
        _gameplayContract.subsidizePrizePool(msg.value);
        _affiliatesContract.registerAsAffiliate(msg.sender, slug);
        emit AffiliateRegistered(slug, msg.sender);
    }

    function unregisterAsAffiliate() external onlyIsAlive {
        _affiliatesContract.unregisterAsAffiliate(msg.sender);
    }

    function getMyAffiliateInfo() external view onlyIsAlive returns (Affiliate memory) {
        return _affiliatesContract.getMyAffiliateInfo(msg.sender);
    }

    function isAffiliate() external view onlyIsAlive returns (bool) {
        return _affiliatesContract.isAffiliate(msg.sender);
    }

    function claimProfit() external onlyIsAlive {
        _affiliatesContract.claimProfit(msg.sender);
        emit AffiliateChanged(msg.sender);
    }

    function completeCurrentGame(uint256 gameIndex) external onlyIsAlive {
        Game memory game = _gameplayContract.getGameInfo(gameIndex);
        _gameplayContract.completeCurrentGame(gameIndex, _luckyNumberGenerator.generateLuckyNumber(game));
        emit GameChanged(gameIndex);
    }

    function addWebAppVersion(string memory afffiliateSlug, string memory cid) external onlyIsAlive {
        if(_compareStrings(afffiliateSlug, "_")) {
            require(_ownersContract.isOwner(msg.sender), "Not in the owners list");
        } else {
            require(_affiliatesContract.isAffiliateBySlug(afffiliateSlug), "Not a valid affiliate !!!");
        }
        _web3AppContract.addVersion(afffiliateSlug, cid);
    }

    function getWebAppVersionsCount(string memory afffiliateSlug) external view onlyIsAlive returns (uint256) {
        return _web3AppContract.getVersionsCount(afffiliateSlug);
    }

    function getWebAppVersionsList(string memory afffiliateSlug, uint256 fromIndex, uint256 toIndex)
        external
        view
        onlyIsAlive
        returns (string[] memory)
    {
        return _web3AppContract.getList(afffiliateSlug, fromIndex, toIndex);
    }

    function isAlive() external view returns (bool) {
        return _isAlive;
    }

    function transferOwnership(address newOwner) external onlyIsAlive onlyOwners returns(address[] memory) {
        address[] memory currentOwners = _ownersContract.getOwners();
        _ownersContract.addOwner(newOwner);
        for (uint256 i = 0; i < currentOwners.length; i++) {
            _ownersContract.removeOwner(newOwner, currentOwners[i]);
        }
        return _ownersContract.getOwners();
    }

    function kill() external onlyIsAlive onlyOwners {
        uint256 gameCount = _gameplayContract.getGamesCount();
        require(gameCount >= 11, "Not possible to kill it. It is still in use !!!");

        uint256 toIndex = gameCount;
        uint256 fromIndex = toIndex - 11;

        Game[] memory lastGames = _gameplayContract.getGamesInfo(fromIndex, toIndex);
        for (uint256 i = 0; i < lastGames.length; i++) {
            require(
                lastGames[i].totalSoldTickets == 0,
                "Not possible to kill it. It is still in use !!!"
            );
        }

        _isAlive = false;
        _ownersContract.kill();
        _affiliatesContract.kill();
        _playersContract.kill();
        _gameplayContract.kill();
        _luckyNumberGenerator.kill();
        _web3AppContract.kill();

        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function _compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}