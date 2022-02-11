// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./Events.sol";
import "./Ownable.sol";
import "./BlokSportsStorage.sol";
import "./BlokSportsStructs.sol";
import "./DebugEvents.sol";
import "./BaseRelayRecipient.sol";

//extends BaseRelayRecipient for metaTransactions
contract BlokSportsEndpointV0 is Ownable, BlokSportsStructs, Events, DebugEvents, BaseRelayRecipient{

    // TODO
    // REPLACE GAS_BET_CLAIM_CONSUMPTION(

    BlokSportsStorage BLKStorage;

    //overriding _msgSender() to avoid Error: Two or more base classes define function with same name and parameter types
    function _msgSender() internal override(Context, BaseRelayRecipient)
    view returns (address payable) {
      return BaseRelayRecipient._msgSender();
    }

    //overriding _msgData() to avoid Error: Two or more base classes define function with same name and parameter types
    function _msgData() internal override(Context,BaseRelayRecipient)
    view returns (bytes memory ret) {
      return BaseRelayRecipient._msgData();
    }

    // Storage getters
    function ADMIN_ROLE() public view returns(bytes32) {
        return BLKStorage.ADMIN_ROLE();
    }

    function PLAYER_ROLE() public view returns(bytes32) {
        return BLKStorage.PLAYER_ROLE();
    }

    function  chainId()  public view returns(uint) {
        return BLKStorage.chainId();
    }

    function betStorage(uint _betId) public view returns(bool, uint) {
        return BLKStorage.betStorage(_betId);
    }

    function defaultToken() public view returns(address) {
        return BLKStorage.defaultToken();
    }

    function ignoreSignatures() external view returns (bool) {
        return BLKStorage.ignoreSignatures();
    }

    function maxBackedAmount() public view returns(uint) {
        return BLKStorage.maxBackedAmount();
    }

    function minBackedAmount() public view returns(uint) {
        return BLKStorage.minBackedAmount();
    }

    function txFee() public view returns(uint) {
        return BLKStorage.txFee();
    }

    function blokFee() public view returns(uint) {
        return BLKStorage.blokFee();
    }

    function version() public view returns(string memory) {
        return BLKStorage.version();
    }

    function playerSettings(address _player) public view returns(
        bool exists, uint expirity, uint gameLapse, uint blokFee,
        uint txFee, uint maxBackedAmount, uint minBackedAmount
    ) {
        return BLKStorage.playerSettings(_player);
    }

    /// @notice Returns a given player settings
    /// @param playerAddress address of the player to update settings
    /// @return expirity expirity time for the player's settings
    /// @return gameLapse player's current gameLapse
    /// @return blokFee player's current Blokfee percentage
    /// @return txFee player's current transactio fee
    /// @return maxBackedAmount player's custom max backed amount
    /// @return minBackedAmount player's custum minimum amount
    function getPlayerSettings(address playerAddress) external view returns (
        uint , uint , uint , uint , uint , uint
    ) {
        return BLKStorage.getPlayerSettings(playerAddress);
    }


    function DIVISION_PADDING() public view returns(uint) {
        return BLKStorage.DIVISION_PADDING();
    }

    function DOMAIN_SEPARATOR() public view returns(bytes32) {
        return BLKStorage.DOMAIN_SEPARATOR();
    }

    function GAS_PLAYER_CLAIM_CONSUMPTION() public returns(uint) {
        return BLKStorage.GAS_PLAYER_CLAIM_CONSUMPTION();
    }

    function GAS_BET_CLAIM_CONSUMPTION() public returns(uint) {
        return BLKStorage.GAS_BET_CLAIM_CONSUMPTION();
    }

    function _roundAmount(uint amount) public view returns(uint) {
        return BLKStorage._roundAmount(amount);
    }

    // TODO make initialize
    constructor(address _storageAddress, address _trustedForwarder) Ownable() {
        BLKStorage = BlokSportsStorage(_storageAddress);
        trustedForwarder = _trustedForwarder;
    }

    modifier setUp() {
        require(address(BLKStorage) != address(0), "Storage Address is not yet set");
        _;
    }

    modifier onlyAdmin() {
        //Use _msgSender() instead of msg.sender for meta transactions
        //_msgSender() returns the caller address. if the call came through trusted forwarder, returns the original sender. otherwise, it returns `msg.sender`.
        require(
            isAdmin(_msgSender()),
            "AdminRole: caller does not have the Admin role"
        );
        _;
    }

    modifier isStorageContract() {
        require(
            _msgSender() == address(BLKStorage),
            "Only Storage contract can emit Events"
        );
        _;
    }

    ///@notice This version is to keep track of BaseRelayRecipient you are using in your contract.
    function versionRecipient() external view override returns (string memory) {
        return "1";
    }

    ///@notice updates the trustedForwarder address
    ///@param _newTrustedForwarder address of new Trusted Forwarder
    function updateTrustedForwarder(address _newTrustedForwarder)
        external
        onlyAdmin
    {
        require(_newTrustedForwarder != address(0), "Invalid TrustedForwarder");
        trustedForwarder = _newTrustedForwarder;
    }


    function updateStorageAddress(address _storageAddress) public setUp onlyAdmin {
        BLKStorage = BlokSportsStorage(_storageAddress);
    }

// USER MANAGEMENT

    /// @notice Adds an admin role to an address
    /// @dev the account cannot have the player role
    /// @param _account address of the new administrator
    function addAdmin(address _account) public setUp {
        BLKStorage.addAdmin(_account);
        emit AdminAdded(_account);
    }

    /// @notice Removes an admintrator role to an address
    /// @dev the account cannot have the administrator role
    /// @param _account address of the new player
    function removeAdmin(address _account) public setUp {
        BLKStorage.removeAdmin(_account);
        emit AdminRemoved(_account);
    }

    /// @notice Returns true if a given account has the admin role
    /// @param _account address to be checked
    /// @return true if _account has the admin role
    function isAdmin(address _account) public view returns(bool) {
        return BLKStorage.isAdmin(_account);
    }

    /// @notice Adds a player role to an address
    /// @dev the account cannot have the administrator role
    /// @param _account address of the new player
    function addPlayer(address _account) public setUp {
        BLKStorage.addPlayer(_account);
        emit PlayerAdded(_account);
    }

    /// @notice Removes a player address
    /// @dev the account has to have the player role
    /// @param _account address of the new player
    function removePlayer(address _account) public setUp {
        BLKStorage.removePlayer(_account);
        PlayerRemoved(_account);
    }

    /// @notice Returns true if a given account has the player role
    /// @param _account address to be checked
    /// @return true if _account has the player role
    function isPlayer(address _account) public view returns(bool) {
        return BLKStorage.isPlayer(_account);
    }

    /// @notice returns a minified bet infomration of a bet
    /// @dev function will revert if the bet Id does not exists
    /// @param _betId id of the bet being required
    function bets(uint _betId) public view returns(
        uint bettingEventId,
        uint betType,
        uint odds,
        int line,
        uint expirity,
        uint8 makerBackedOutcome,
        uint backedLimitAmount,
        uint backedAmount,
        uint takenAmount,
        address maker
    ) {
        return BLKStorage.getBet(_betId);
    }

    function getBetTypeName(uint _betTypeId) public view returns(string memory ) {
        return BLKStorage.getBetTypeName(_betTypeId);
    }

    function getBettor(uint betId, address player) public view returns (
        bool exists, bool isMaker, uint bettorAmount, uint bettorOutcome, bool claimed
    ){
        return BLKStorage.getBettor(betId, player);
    }

    function getBetTakers(uint betId) external view returns (address[] memory) {
        return BLKStorage.getBetTakers(betId);
    }

    function isAmountInRange(address player, uint amount) public view returns (bool){
        return BLKStorage.isAmountInRange(player, amount);
    }

    function isBettingEventLapsed(uint bettingEventId) public view returns (bool) {
        return BLKStorage.isBettingEventLapsed(bettingEventId);
    }

    function betToTakeAmount(uint _betId) public view returns (uint) {
        return BLKStorage.betToTakeAmount(_betId);
    }

    function betPayoutAmount(uint _betId)  public view returns (uint) {
        return BLKStorage.betPayoutAmount(_betId);
    }

    function getMakerDebit(uint amount, uint division_padding, uint odds_m1)
    view public returns(uint){
        return BLKStorage.getMakerDebit(amount, division_padding, odds_m1);
    }

    function getBettingEventScores(uint _betingEventId) public view returns(uint16, uint16) {
        return BLKStorage.getBettingEventScores(_betingEventId);
    }

    function betToWinAmount(uint _betId) public view returns(uint) {
        return BLKStorage.betToWinAmount(_betId);
    }

    function toWinAmount(uint odds, uint backedAmount) public view returns(uint) {
        return BLKStorage.toWinAmount(odds, backedAmount);
    }

    function getWinnerOutcome(uint _betId) public view returns (uint16) {
        return BLKStorage.getWinnerOutcome(_betId);
    }

    /// @notice gets the operative amount that can be used on betting
    /// @dev returns 0 if there is no records for the queried address (does not revert)
    /// @param playerAddress address for the queried player account
    /// @return blance of the payer
    function getTokenBalance(address playerAddress) public view returns(uint) {
        return BLKStorage.getTokenBalance(playerAddress);
    }

    function payoutAmount(uint odds, uint backedAmount) external view returns (uint) {
        return BLKStorage.payoutAmount(odds, backedAmount);
    }

    /// @notice gets the current setting for the user
    /// @dev will revert if the flag is out of range
    /// @param playerAddess wallet address of the player to be used
    /// @param flag numeric value of required settings
    /// @return value for the choosen variable
    function getCurrentSetting(address playerAddess, uint8 flag) public view returns (uint value) {
        return BLKStorage.getCurrentSetting(playerAddess, flag);
    }


    function bettingEvents(uint bettingEventsId) public view returns(
          bool exists, uint id, bool resolved, bool cancelled, uint gameLapse, uint homeScore, uint awayScore
    ) {
        return BLKStorage.bettingEvents(bettingEventsId);
    }

    /// TODO descide if switching to empty arrays instad of revert is better (consider gas implications)
    /// @notice returns an array with the addresses that are winners of a bet
    /// @dev function returns an empty array if there isn't a winner for the bet
    /// @param betId numeri id of the bet that you are using
    /// @return address[] wallets identified as bet winners
    function getBetWinners(uint betId) public view returns (address[] memory) {
        return BLKStorage.getBetWinners(betId);
    }

    /// @notice claims bets in batch
    /// @dev claiming actions must be traced using the events
    /// @param claimingBets uint array of bet ids
    /// @return uint
    function batchClaimBet(uint[] memory claimingBets) public returns(uint) {
        return BLKStorage.batchClaimBet(claimingBets);
    }

    /// @notice calculates the winning amount corresponding to a take
    /// @param partialTakeSize size of the take
    /// @param totalTakeSize size of cumulative takes
    /// @param backedAmount size of the amount betting against
    /// @return winningAmount
    function calculateWinnings(uint partialTakeSize, uint totalTakeSize, uint backedAmount)
        public view returns (uint)
    {
        return BLKStorage.calculateWinnings(partialTakeSize, totalTakeSize, backedAmount);
    }

    /// @notice cancels a bet
    /// @dev only the maker of the bet can cancel the bet
    /// @param betId id of the bet to cancel
    function cancelBet(uint betId) public {

        ( uint backedLimitAmount, uint backedAmount ) = BLKStorage.cancelBet(betId);

        emit BetCancelled(betId, backedAmount, backedLimitAmount);
    }

    /// @notice cancels a bet using metaTransaction
    /// @dev only the maker of the bet can cancel the bet
    /// @param betId id of the bet to cancel
    function cancelBetMeta(uint betId) public {
        ( uint backedLimitAmount, uint backedAmount ) = BLKStorage.cancelBetMeta(betId, _msgSender());
        emit BetCancelled(betId, backedAmount, backedLimitAmount);
    }


    /// @notice STUB Claims a bet given its betId
    /// @dev returns the betted funds ATM does not resolve a winner
    /// @param betId numeric id of a bet
    /// @param player address of the player claiming the bet
    function claimBet(uint betId, address player) public {
        uint claimedAmount = BLKStorage.claimBet(betId, player);
        (uint bettingEventId, , , , , , , , ,) = BLKStorage.getBet(betId);
        emit BetClaimed(bettingEventId, betId, player, claimedAmount);
    }

    /// @notice Adds a contract as a bet type
    /// @param contractAddress address of the contract to be added
    /// @dev Will revert if the if the contract in address does not has an owner
    /// @dev Emits a newBetType event
    function createBetType(address contractAddress, uint betTypeId) external onlyAdmin {
        BLKStorage.createBetType(contractAddress, betTypeId);
        // TODO TODO_ fetch betType name
        emit NewBettingType("TODO_" ,betTypeId, contractAddress);
    }

    /// @notice Creates a bettingEvents as created by its bettingEventId
    /// @dev an event can only be created once as created only callable from an admin account
    /// @param bettingEventId Numeric identifier of the new event
    /// @param lapse time when the event starts
    function createBettingEvent(uint bettingEventId, uint lapse) external {
        BLKStorage.createBettingEvent(bettingEventId, lapse);

        emit BettingEventCreated(bettingEventId, lapse);
    }

    function cancelBettingEvent(uint bettingEventId) external onlyAdmin {
        BLKStorage.cancelBettingEvent(bettingEventId);
        emit BettingEventCancelled(bettingEventId);
    }

    /// @notice takes a bet, creates a game and bet from a signature if they don't exists
    /// @dev Recieves 3 arrays contextually organized, function implements validations such as
    ///
    ///     metaData
    ///     * [0] bettingEventId must match the admintrator signatures if it doesn't exists.
    ///     * [1] eventLapseTime time must be a timestamp in seconds since the epoch
    ///         will be reverted if the current timestamp is greater than the lapse time
    ///     * [2] betId The selected betId must not be cancelled or taken to its fullest
    ///     * [3] expirityTime TODO will set the time where the event will be considered to be
    ///         cancelled will allow funds to be taken back by their corresponding owners
    ///
    ///     amountsData
    ///     * [0] backedAmount The maxAmount amount the backer is commited to fund the current bet
    ///     * [1] takenAmount The amount that the taker is commiting to the current bet. Taker must
    ///         have the full amount expressed in the current take request
    ///
    ///     lineData
    ///     * [0] BetType must be within the following values:
    ///         1 = for overunder bets
    ///         2 = for pointspread bets
    ///         3 = for moneyline bets
    ///     * [1] makerPosition Side of the bet that the maker is backing:
    ///         0 = Over  || Home Team
    ///         1 = Under || Away Team
    ///     * [2] odds for the bet, expressed in decimal format and multiplied by 1000000000000
    ///     * [3] line packed in a positive format. (line*10)+10000
    ///
    ///     makerSignature signature of the maker authorizing the backed current bet
    ///
    ///     adminSignature signature of an administrator authorizing the current bettingEvent
    ///
    ///     maker Address of the maker account, must be player and match the makerSignature author
    ///         at the moment the bet is created.
    /// @param metaData uint32[] Metadata  of the bet
    /// @param metaData[0] uint32 bettingEventId
    /// @param metaData[1] uint32 eventLapseTime
    /// @param metaData[2] uint32 betId
    /// @param metaData[3] uint32 expirityTime
    /// @param amountsData uint[] Amounts from the maker and taker
    /// @param amountsData[0] uint backedAmount
    /// @param amountsData[1] uint takenAmount
    /// @param lineData uint64[] smaller footprint bet information
    /// @param lineData[0] uint64 betType
    /// @param lineData[1] uint64 makerPosition
    /// @param lineData[2] uint64 odds
    /// @param lineData[3] uint64 line
    /// @param makerSignature bytes bet maker signature
    /// @param adminSignature bytes betting event administrator signature
    /// @param maker address makerAddress
    function postBet(
        uint32[] memory metaData,
        uint[] memory amountsData,
        uint64[] memory lineData,
        bytes memory makerSignature,
        bytes memory adminSignature,
        address maker,
        bool isPartialAllow
    ) public {
        // (bool eventCreated, uint fee, uint takerDebit, uint makerDebit)
        (uint takerDebit, uint makerDebit, uint fee, bool newEvent) = BLKStorage.postBet(
            metaData,
            amountsData,
            lineData,
            makerSignature,
            adminSignature,
            maker,
            isPartialAllow
        );
        _postBetGetTokens(metaData, lineData, maker, fee, takerDebit, makerDebit, newEvent);
    }


    /// @param metaData uint32[] Metadata  of the bet
    /// @param metaData[0] uint32 bettingEventId
    /// @param metaData[1] uint32 eventLapseTime
    /// @param metaData[2] uint32 betId
    /// @param metaData[3] uint32 expirityTime
    /// @param amountsData uint[] Amounts from the maker and taker
    /// @param amountsData[0] uint backedAmount
    /// @param amountsData[1] uint takenAmount
    /// @param lineData uint64[] smaller footprint bet information
    /// @param lineData[0] uint64 betType
    /// @param lineData[1] uint64 makerPosition
    /// @param lineData[2] uint64 odds
    /// @param lineData[3] uint64 line
    /// @param makerSignature bytes bet maker signature
    /// @param adminSignature bytes betting event administrator signature
    /// @param maker address makerAddress
    /// @param isPartialAllow bool isPartialAllow
    function postBetMeta(
        uint32[] memory metaData,
        uint[] memory amountsData,
        uint64[] memory lineData,
        bytes memory makerSignature,
        bytes memory adminSignature,
        address maker,
        bool isPartialAllow
    ) public {
        // (bool eventCreated, uint fee, uint takerDebit, uint makerDebit)
        (uint takerDebit, uint makerDebit, uint fee, bool newEvent) = BLKStorage.postBetMeta(
            metaData,
            amountsData,
            lineData,
            makerSignature,
            adminSignature,
            maker,
            _msgSender(), // here msg.sender will be taker for bet
            isPartialAllow
        );

        _postBetGetTokens(metaData, lineData, maker, fee, takerDebit, makerDebit, newEvent);
    }

    function _postBetGetTokens(
        uint32[] memory metaData,
        uint64[] memory lineData,
        address maker,
        uint fee,
        uint takerDebit,
        uint makerDebit,
        bool newEvent
    ) internal {

        address _defaultToken = defaultToken();

        emit BetTaken(
            metaData[2], _msgSender(), lineData[0], takerDebit, fee, maker, makerDebit
        );

        if(newEvent) {
            emit BettingEventCreated(metaData[0], metaData[1]);
        }

        require(
            IERC20(_defaultToken).transferFrom(_msgSender(), address(BLKStorage), takerDebit),
            "taker failed to fund bet"
        );

        require(
            IERC20(_defaultToken).transferFrom(maker, address(BLKStorage), makerDebit),
            "maker failed to fund bet"
        );
    }

    /// @notice Update contract Settings
    /// @dev emits SettingsUpdated event
    /// @param initBlokFee global new blok fee percentage
    /// @param initTxFee global new flat fee
    /// @param initMaxBackedAmount global new maximum backed amount
    /// @param initMinBackedAmount global new minimum backed amount
    function updateSettings(
        uint initBlokFee, uint initTxFee, uint initMaxBackedAmount,
        uint initMinBackedAmount, bool initIgnoreSignatures
    ) public onlyAdmin  {
        BLKStorage.updateSettings(
            initBlokFee, initTxFee, initMaxBackedAmount, initMinBackedAmount, initIgnoreSignatures
        );
        emit SettingsUpdated(
            _msgSender(), initBlokFee, initTxFee, initMaxBackedAmount, initMinBackedAmount, initIgnoreSignatures
        );
    }

    /// @notice Writes the complete configuration for a player
    /// @param playerAddress address of the player to update settings
    /// @param newExpirity players setting expirity period
    /// @param newGameLapse players new game lapse
    /// @param newBlokFee players new blok fee percentage
    /// @param newTxFee players new flat fee
    /// @param newMaxBackedAmount players new maximum backed amount
    /// @param newMinBackedAmount players new minimum backed amount
    function setPlayerSettings(
        address playerAddress,
        uint newExpirity,
        uint newGameLapse,
        uint newBlokFee,
        uint newTxFee,
        uint newMaxBackedAmount,
        uint newMinBackedAmount
    ) external onlyAdmin {
        BLKStorage.setPlayerSettings(
            playerAddress, newExpirity, newGameLapse, newBlokFee, newTxFee, newMaxBackedAmount, newMinBackedAmount
        );
    }

    /// @notice STUB Resolves a bettingEvent
    /// @dev emits event BettingEventResolved
    /// @param bettingEventId numeric id of a betingEvent
    /// @param homeScore score for the Home team
    /// @param awayScore score for the away team
    function resolveBettingEvent(
        uint bettingEventId, uint16 homeScore, uint16 awayScore
    ) external  onlyAdmin {
        BLKStorage.resolveBettingEvent(bettingEventId, homeScore, awayScore);
        emit BettingEventResolved(bettingEventId, homeScore, awayScore);
    }


    /// @notice Returns false if the mssage cannot be validated by an admin
    /// @dev does not revert on failed checks
    /// @param bettingEventId numeric representation of the bettingEvent
    /// @param lapse numeric representation of time for a game starting
    /// @param adminSignature the signature string of the message
    /// @return true if the message has been signed by an admin account
    function verifyAdminMessage( uint bettingEventId, uint lapse, bytes memory adminSignature) public view returns (bool) {
        return BLKStorage.verifyAdminMessage(bettingEventId, lapse, adminSignature);
    }

    /// @notice Returns false if message cannot be validated or the author does
    ///         not match the player
    /// @dev does not revert on failed checks
    /// @param maker maker address
    /// @param bettingEventId event id
    /// @param betId bet id
    /// @param betType bet type
    /// @param backedAmount backed amount
    /// @param odds bet ods
    /// @param makerPosition maker position
    /// @param expirityTime expirity time
    /// @param makerSignature maker signature
    /// @return boolean
    function verifyMakerMessage(
        address maker, uint32 bettingEventId, uint32 betId, uint16 betType, uint256 backedAmount,
        uint64 odds, uint16 makerPosition, uint16 line, uint32 expirityTime, bytes memory makerSignature
    ) public view returns(bool) {
        return BLKStorage.verifyMakerMessage(
            maker, bettingEventId, betId, betType, backedAmount, odds,
            makerPosition, line, expirityTime, makerSignature
        );
    }

}