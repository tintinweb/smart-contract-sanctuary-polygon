// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IRandomNumberGenerator {
    function randomNumberGenerator(uint8 number) external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TransferHelper.sol";
import "./IRandomNumberGenerator.sol";
import "../openzeppelin/contracts/utils/Counters.sol";
import "../openzeppelin/contracts/access/Ownable.sol";

contract LuckyMe_v2 is Ownable {
  using Counters for Counters.Counter;
  IRandomNumberGenerator public Number;
  address public Token;

  /**
      User Data
   */
  struct userGame {
    uint8 Game;
    uint8 Prize;
    uint256 GameId;
    uint8 LuckyNumber;
  }
  struct pick {
    uint8 Game;
    uint256 GameId;
    uint8 Number;
  }
  struct user {
    uint8 Plan;
    uint256 Id;
    uint256 Ref;
    address Address;
    uint256[] AllRef;
    uint256 registerAt;
    uint256 TimeToRenew;
    uint256 TotalPrizesAmount;
    uint256 TotalPicksRewards;
    uint256 TotalReferralRewards;
    pick[] Picks;
    userGame[] AllWinLuckyDraw;
  }
  uint32 public Year = 365 days;
  Counters.Counter public UsersIds;
  mapping(uint256 => user) public User;
  mapping(address => uint256) public UserId;
  mapping(address => bool) public isUserExists;
  mapping(uint8 => mapping(uint256 => uint256)) public MembersRefByLevel;
  mapping(uint8 => mapping(uint256 => uint256)) public PartnersRefByLevel;

  /**
      Membership plans
   */
  struct totalRewardsPaid {
    uint256 Prize;
    uint256 PicksRef;
    uint256 MemberRef;
  }
  totalRewardsPaid public TotalRewardsPaid;

  /**
      Membership plans
   */
  uint8 public Plans;
  uint256 public Members;
  uint256 public Partners;
  mapping(uint8 => uint256) public MembershipPlan;

  /**
      lucky draws ( Game )
   */
  uint8 public TotalGames;
  uint8 public TotalParticipates;
  mapping(uint8 => uint256) public GameEntryFee;

  /**
      lucky draws ( Game ) user data
   */
  struct game {
    uint256 StartedAt;
    uint256 EndedAt;
    bool GameOver;
    bool Withdraw;
    uint8[] Winners;
    uint256[] WinnersId;
    uint8[] AllNumbers;
    uint256[100] AllParticipates;
    uint256 TotalPrizeAmount;
    mapping(uint8 => bool) Sold;
    mapping(uint8 => uint256) UserId;
  }
  struct compGame {
    uint8 Game;
    uint256 GameId;
  }
  compGame[] compGames;
  uint256 public TotalPicksAmount;
  Counters.Counter public TotalPicks;
  mapping(uint8 => Counters.Counter) public GameIds;
  mapping(uint8 => mapping(uint256 => game)) internal Game;
  mapping(uint8 => mapping(uint256 => mapping(uint256 => bool)))
    internal UserInGame;

  /**
      Membership Referrals
   */
  uint8 public TotalPrizes;
  mapping(uint8 => uint8) public Prizes;

  /**
      Membership Referrals
   */
  uint8 public RefLevels;
  mapping(uint8 => uint8) public MembershipRefLevels;

  /**
      Purchase Referrals
   */
  uint8 public PurLevels;
  mapping(uint8 => uint8) public PurchaseRefLevels;

  /********************************************************
                        Constructor
  ********************************************************/

  constructor(
    address _Token,
    address _OwnerAddress,
    address _RandomNumberGenerator
  ) Ownable(_OwnerAddress) {
    Token = _Token;
    Number = IRandomNumberGenerator(_RandomNumberGenerator);

    /**
      Registering user
    */
    uint256 _id = UsersIds.current();
    User[_id].Id = _id;
    User[_id].Ref = _id;
    User[_id].Plan = 1;
    User[_id].Address = owner();
    UserId[owner()] = _id;
    isUserExists[owner()] = true;
    User[_id].registerAt = block.timestamp;

    /**
        Membership plans
     */
    Plans = 1;
    MembershipPlan[0] = 0 ether;
    MembershipPlan[1] = 20 ether;

    /**
        Lucky draws ( Game )
     */
    TotalGames = 9;
    TotalParticipates = 100;
    GameEntryFee[0] = 1 ether;
    GameEntryFee[1] = 2 ether;
    GameEntryFee[2] = 5 ether;
    GameEntryFee[3] = 10 ether;
    GameEntryFee[4] = 25 ether;
    GameEntryFee[5] = 50 ether;
    GameEntryFee[6] = 100 ether;
    GameEntryFee[7] = 250 ether;
    GameEntryFee[8] = 500 ether;

    /**
     * game start time
     */
    Game[0][0].StartedAt = block.timestamp;
    Game[1][0].StartedAt = block.timestamp;
    Game[2][0].StartedAt = block.timestamp;
    Game[3][0].StartedAt = block.timestamp;
    Game[4][0].StartedAt = block.timestamp;
    Game[5][0].StartedAt = block.timestamp;
    Game[6][0].StartedAt = block.timestamp;
    Game[7][0].StartedAt = block.timestamp;
    Game[8][0].StartedAt = block.timestamp;

    /**
        Membership Referrals
     */
    RefLevels = 5;
    MembershipRefLevels[0] = 25;
    MembershipRefLevels[1] = 10;
    MembershipRefLevels[2] = 5;
    MembershipRefLevels[3] = 5;
    MembershipRefLevels[4] = 5;
    //               Total = 50%
    // and 50% goes to admin it total 100%

    /**
        Purchase Referrals
     */
    PurLevels = 5;
    PurchaseRefLevels[0] = 15;
    PurchaseRefLevels[1] = 4;
    PurchaseRefLevels[2] = 3;
    PurchaseRefLevels[3] = 2;
    PurchaseRefLevels[4] = 1;
    //             Total = 25%
    // and 5% goes to admin it total 30%

    /**
        Prizes
     */
    TotalPrizes = 3;
    Prizes[0] = 40;
    Prizes[1] = 20;
    Prizes[2] = 10;
    //  Total = 70%
  }

  /********************************************************
                        Modifier
  ********************************************************/

  bool internal Locked;
  modifier noReentrant() {
    require(!Locked, "No re-entrancy");
    Locked = true;
    _;
    Locked = false;
  }

  /********************************************************
                        Public Functions
  ********************************************************/

  function register(
    uint256 _ref,
    uint8 _plan,
    address _user
  ) public noReentrant {
    require(Plans >= _plan, "Please choose correct plan");
    require(!isUserExists[_user], "User exists");
    require(isUserExists[User[_ref].Address], "Ref not exists");

    uint256 _amount = MembershipPlan[_plan];
    if (_plan == 1)
      TransferHelper.safeTransferFrom(
        Token,
        msg.sender,
        address(this),
        _amount
      );

    UsersIds.increment();
    uint256 _id = UsersIds.current();

    User[_id].Id = _id;
    User[_id].Ref = _ref;
    User[_id].Plan = _plan;
    User[_id].Address = _user;
    User[_id].TimeToRenew = block.timestamp + Year;
    User[_id].registerAt = block.timestamp;
    UserId[_user] = _id;
    isUserExists[_user] = true;

    User[_ref].AllRef.push(_id);

    if (_plan == 0) Members++;
    if (_plan == 1) Partners++;

    registerRefByLevel(_plan, _ref);
    if (_plan == 1) registerUplineMemberRef(_id, _ref, _amount);

    emit _registered(_id, _ref, _plan, _user, block.timestamp);
  }

  function renew(uint256 _id) public noReentrant {
    user memory _user = User[_id];

    require(isUserExists[_user.Address], "User not exists");
    require(_user.Plan == 1, "Premium members only");

    uint256 _amount = MembershipPlan[_user.Plan];
    TransferHelper.safeTransferFrom(Token, msg.sender, address(this), _amount);

    User[_id].TimeToRenew = block.timestamp + Year;
    renewUplineMemberRef(_id, _user.Ref, _amount);

    emit _renewed(_id, _user.Ref, _user.Plan, _user.Address, block.timestamp);
  }

  function upgradePlan(uint256 _id) public noReentrant {
    user memory _user = User[_id];

    require(isUserExists[_user.Address], "User not exists");
    require(_user.Plan == 0, "Already upgraded");

    uint256 _amount = MembershipPlan[1];
    TransferHelper.safeTransferFrom(Token, msg.sender, address(this), _amount);

    Members--;
    Partners++;
    User[_id].Plan = 1;
    User[_id].TimeToRenew = block.timestamp + Year;

    upgradeRefByLevel(_user.Ref);
    upgradePlanUplineMemberRef(_id, _user.Ref, _amount);

    emit _upgraded(_id, _user.Ref, _user.Plan, _user.Address, block.timestamp);
  }

  function enterGame(
    uint8 _game,
    uint8 _number,
    uint256 _id
  ) public noReentrant {
    require(TotalGames > _game, "Please choose correct game");
    require(TotalParticipates > _number, "Number is not correct");

    user memory _user = User[_id];
    require(isUserExists[_user.Address], "User not exists");
    if (_user.Plan == 1 && _id != 0) {
      require(_user.TimeToRenew > block.timestamp, "It's Time To Renew");
    }

    uint256 _gameId = GameIds[_game].current();
    require(!Game[_game][_gameId].Sold[_number], "This number is already sold");

    uint256 _amount = GameEntryFee[_game];
    TransferHelper.safeTransferFrom(Token, msg.sender, address(this), _amount);

    game storage _Game = Game[_game][_gameId];
    require(!_Game.GameOver, "Game Over");

    _Game.Sold[_number] = true;
    _Game.UserId[_number] = _id;
    _Game.AllParticipates[_number] = _id;
    _Game.AllNumbers.push(_number);

    if (_Game.StartedAt == 0) _Game.StartedAt = block.timestamp;

    TotalPicks.increment();
    TotalPicksAmount += _amount;
    UserInGame[_game][_gameId][_id] = true;
    User[_id].Picks.push(pick(_game, _gameId, _number));

    uplinePicksRef(_id, _game, _user.Ref, _amount);
    _Game.TotalPrizeAmount += Percentage(_amount, 85);

    emit _picked(
      _id,
      _user.Ref,
      _user.Plan,
      _game,
      _gameId,
      _amount,
      block.timestamp
    );

    if (_Game.AllNumbers.length == TotalParticipates) {
      withdrawPrizes(_game, _gameId);

      _Game.GameOver = true;
      _Game.EndedAt = block.timestamp;

      compGames.push(compGame(_game, _gameId));
      GameIds[_game].increment();

      emit _winnersAnnounced(_game, _gameId, _Game.Winners, block.timestamp);
    }
  }

  function withdrawPrizes(uint8 _game, uint256 _gameId) internal {
    uint256 _amount = GameEntryFee[_game] * 100;
    game storage _Game = Game[_game][_gameId];

    for (uint8 i = 0; i < TotalPrizes; i++) {
      uint8 _luckyNumber = Number.randomNumberGenerator(i) % 99;

      user memory _User = User[_Game.AllParticipates[_luckyNumber]];

      _Game.Winners.push(_luckyNumber);
      _Game.WinnersId.push(_User.Id);

      uint256 _Percentage = Percentage(_amount, Prizes[i]);
      TransferHelper.safeTransfer(Token, _User.Address, _Percentage);

      TotalRewardsPaid.Prize += _Percentage;
      User[_User.Id].TotalPrizesAmount += _Percentage;
      User[_User.Id].AllWinLuckyDraw.push(
        userGame(_game, i, _gameId, _luckyNumber)
      );

      emit _prizesWinner(
        _User.Id,
        _User.Ref,
        _User.Plan,
        _User.Address,
        _game,
        _gameId,
        i,
        _Percentage,
        block.timestamp
      );
    }

    _Game.Withdraw = true;
    emit _prizesWithdraw(_game, _gameId, _amount, block.timestamp);
  }

  /********************************************************
                        onlyOwner Functions
  ********************************************************/

  function emergencyWithdrawPrizes(uint8 _game) public onlyOwner {
    uint256 _gameId = GameIds[_game].current();
    game storage _Game = Game[_game][_gameId];

    require(!_Game.Withdraw, "already Withdraw");
    require(_Game.AllNumbers.length != 0, "no participant");

    uint256 _amount = (GameEntryFee[_game] * _Game.AllNumbers.length);

    if (_Game.AllNumbers.length <= TotalPrizes) {
      uint256 _Percentage = Percentage(
        _amount,
        Prizes[0] + Prizes[1] + Prizes[2]
      );

      for (uint8 i = 0; i < _Game.AllNumbers.length; i++) {
        uint8 _number = _Game.AllNumbers[i];
        user memory _User = User[_Game.AllParticipates[_number]];

        TransferHelper.safeTransfer(
          Token,
          _User.Address,
          _Percentage / _Game.AllNumbers.length
        );

        _Game.Winners.push(_number);
        _Game.WinnersId.push(_User.Id);

        TotalRewardsPaid.Prize += _Percentage;
        User[_User.Id].TotalPrizesAmount += _Percentage;
        User[_User.Id].AllWinLuckyDraw.push(
          userGame(_game, i, _gameId, _number)
        );

        emit _prizesWinner(
          _User.Id,
          _User.Ref,
          _User.Plan,
          _User.Address,
          _game,
          _gameId,
          i,
          _Percentage,
          block.timestamp
        );
      }
    } else {
      for (uint8 i = 0; i < TotalPrizes; i++) {
        uint8 _luckyNumber = Number.randomNumberGenerator(i) %
          (uint8(_Game.AllNumbers.length) - 1);

        uint8 _number = _Game.AllNumbers[_luckyNumber];
        user memory _User = User[_Game.AllParticipates[_number]];

        uint256 _Percentage = Percentage(_amount, Prizes[i]);
        TransferHelper.safeTransfer(Token, _User.Address, _Percentage);

        _Game.Winners.push(_number);
        _Game.WinnersId.push(_User.Id);

        TotalRewardsPaid.Prize += _Percentage;
        User[_User.Id].TotalPrizesAmount += _Percentage;
        User[_User.Id].AllWinLuckyDraw.push(
          userGame(_game, i, _gameId, _luckyNumber)
        );

        emit _prizesWinner(
          _User.Id,
          _User.Ref,
          _User.Plan,
          _User.Address,
          _game,
          _gameId,
          i,
          _Percentage,
          block.timestamp
        );
      }
    }

    _Game.Withdraw = true;
    _Game.GameOver = true;
    _Game.EndedAt = block.timestamp;

    compGames.push(compGame(_game, _gameId));
    GameIds[_game].increment();

    emit _winnersAnnounced(_game, _gameId, _Game.Winners, block.timestamp);
    emit _prizesWithdraw(_game, _gameId, _amount, block.timestamp);
  }

  /********************************************************
                        private Functions
  ********************************************************/

  function registerRefByLevel(uint8 _plan, uint256 _ref) private {
    for (uint8 j = 0; j < RefLevels; j++) {
      if (_plan == 0) MembersRefByLevel[j][_ref] += 1;
      if (_plan == 1) PartnersRefByLevel[j][_ref] += 1;

      _ref = User[_ref].Ref;
    }
  }

  function registerUplineMemberRef(
    uint256 _id,
    uint256 _ref,
    uint256 _amount
  ) private {
    uint8 j;
    uint256 _Percentage;

    while (j < RefLevels) {
      user memory _user = User[_ref];

      if (
        (_user.Plan == 1 && _user.TimeToRenew > block.timestamp) || _ref == 0
      ) {
        _Percentage = Percentage(_amount, MembershipRefLevels[j]);

        TransferHelper.safeTransfer(Token, _user.Address, _Percentage);

        TotalRewardsPaid.MemberRef += _Percentage;
        User[_ref].TotalReferralRewards += _Percentage;

        emit _uplineMemberRef(
          _id,
          _user.Id,
          User[_id].Plan,
          User[_id].Address,
          _Percentage,
          block.timestamp
        );

        j++;
      }

      _ref = _user.Ref;
    }

    _Percentage = Percentage(_amount, 50);
    TransferHelper.safeTransfer(Token, owner(), _Percentage);

    TotalRewardsPaid.MemberRef += _Percentage;
    User[0].TotalReferralRewards += _Percentage;
  }

  function upgradeRefByLevel(uint256 _ref) private {
    for (uint8 j = 0; j < RefLevels; j++) {
      MembersRefByLevel[j][_ref] -= 1;
      PartnersRefByLevel[j][_ref] += 1;

      _ref = User[_ref].Ref;
    }
  }

  function upgradePlanUplineMemberRef(
    uint256 _id,
    uint256 _ref,
    uint256 _amount
  ) private {
    uint8 j;
    uint256 _Percentage;

    while (j < RefLevels) {
      user memory _user = User[_ref];
      if (
        (_user.Plan == 1 && _user.TimeToRenew > block.timestamp) || _ref == 0
      ) {
        _Percentage = Percentage(_amount, MembershipRefLevels[j]);

        TransferHelper.safeTransfer(Token, _user.Address, _Percentage);

        TotalRewardsPaid.MemberRef += _Percentage;
        User[_ref].TotalReferralRewards += _Percentage;

        emit _uplineMemberRef(
          _id,
          _user.Id,
          User[_id].Plan,
          User[_id].Address,
          _Percentage,
          block.timestamp
        );

        j++;
      }

      _ref = _user.Ref;
    }

    _Percentage = Percentage(_amount, 50);
    TransferHelper.safeTransfer(Token, owner(), _Percentage);

    TotalRewardsPaid.MemberRef += _Percentage;
    User[0].TotalReferralRewards += _Percentage;
  }

  function renewUplineMemberRef(
    uint256 _id,
    uint256 _ref,
    uint256 _amount
  ) private {
    uint8 j;
    uint256 _Percentage;

    while (j < RefLevels) {
      user memory _user = User[_ref];
      if (
        (_user.Plan == 1 && _user.TimeToRenew > block.timestamp) || _ref == 0
      ) {
        _Percentage = Percentage(_amount, MembershipRefLevels[j]);
        TransferHelper.safeTransfer(Token, _user.Address, _Percentage);

        TotalRewardsPaid.MemberRef += _Percentage;
        User[_ref].TotalReferralRewards += _Percentage;

        emit _uplineMemberRef(
          _id,
          _user.Id,
          User[_id].Plan,
          User[_id].Address,
          _Percentage,
          block.timestamp
        );

        j++;
      }
      _ref = _user.Ref;
    }

    _Percentage = Percentage(_amount, 50);
    TransferHelper.safeTransfer(Token, owner(), _Percentage);

    TotalRewardsPaid.MemberRef += _Percentage;
    User[0].TotalReferralRewards += _Percentage;
  }

  function uplinePicksRef(
    uint256 _id,
    uint8 _game,
    uint256 _ref,
    uint256 _amount
  ) private {
    uint8 j;
    uint256 _Percentage;

    while (j < PurLevels) {
      user memory _user = User[_ref];

      if (
        (_user.Plan == 1 && _user.TimeToRenew > block.timestamp) || _ref == 0
      ) {
        _Percentage = Percentage(_amount, PurchaseRefLevels[j]);
        TransferHelper.safeTransfer(Token, _user.Address, _Percentage);

        TotalRewardsPaid.PicksRef += _Percentage;
        User[_ref].TotalPicksRewards += _Percentage;

        emit _uplinePicksRef(
          _id,
          _user.Id,
          User[_id].Plan,
          User[_id].Address,
          _game,
          _Percentage,
          block.timestamp
        );

        j++;
      }
      _ref = _user.Ref;
    }

    _Percentage = Percentage(_amount, 5);
    TransferHelper.safeTransfer(Token, owner(), _Percentage);

    TotalRewardsPaid.PicksRef += _Percentage;
    User[0].TotalPicksRewards += _Percentage;
  }

  /********************************************************
                        Reusable Functions
  ********************************************************/

  function Percentage(uint256 a, uint8 n) internal pure returns (uint256) {
    // a = amount , n = number, p = percentage

    uint256 p = a * 1e18;
    p = (p * n) / 100;
    p = p / 1e18;

    return p;
  }

  /********************************************************
                        View Functions
  ********************************************************/

  struct gameDetail {
    uint256 Id;
    uint256 StartedAt;
    uint256 EndedAt;
    bool GameOver;
    bool Withdraw;
    uint256 EntryFee;
    uint8[] Winners;
    uint256[] WinnersId;
    uint8[] AllNumbers;
    uint256[100] AllParticipates;
    uint256 TotalPrizeAmount;
  }

  function singleGameDetail(
    uint8 _game,
    uint8 _gameId
  ) public view returns (gameDetail memory) {
    game storage _Game = Game[_game][_gameId];

    return
      gameDetail(
        _gameId,
        _Game.StartedAt,
        _Game.EndedAt,
        _Game.GameOver,
        _Game.Withdraw,
        GameEntryFee[_game],
        _Game.Winners,
        _Game.WinnersId,
        _Game.AllNumbers,
        _Game.AllParticipates,
        _Game.TotalPrizeAmount
      );
  }

  function currentGameDetail(
    uint8 _game
  ) public view returns (gameDetail memory) {
    uint256 _GameId = GameIds[_game].current();
    game storage _Game = Game[_game][_GameId];

    return
      gameDetail(
        _GameId,
        _Game.StartedAt,
        _Game.EndedAt,
        _Game.GameOver,
        _Game.Withdraw,
        GameEntryFee[_game],
        _Game.Winners,
        _Game.WinnersId,
        _Game.AllNumbers,
        _Game.AllParticipates,
        _Game.TotalPrizeAmount
      );
  }

  function currentUserInGame(
    uint8 _game,
    uint256 _id
  ) public view returns (bool) {
    return UserInGame[_game][GameIds[_game].current()][_id];
  }

  function userDetail(uint256 _userId) public view returns (user memory) {
    require(isUserExists[User[_userId].Address], "User not exists");
    return User[_userId];
  }

  function userTotalRefrerrs(
    uint256 _id
  )
    public
    view
    returns (uint256[] memory memberLevels, uint256[] memory partnersLevels)
  {
    uint256[] memory _memberLevels = new uint256[](5);
    uint256[] memory _partnersLevels = new uint256[](5);

    for (uint8 i = 0; i < 5; i++) {
      _memberLevels[i] = MembersRefByLevel[i][_id];
      _partnersLevels[i] = PartnersRefByLevel[i][_id];
    }

    return (_memberLevels, _partnersLevels);
  }

  function CompGames() public view returns (compGame[] memory) {
    return compGames;
  }

  /********************************************************
                        View Functions
  ********************************************************/

  event _registered(
    uint256 indexed _id,
    uint256 _ref,
    uint8 _plan,
    address _address,
    uint256 timestamp
  );

  event _upgraded(
    uint256 indexed _id,
    uint256 _ref,
    uint8 _plan,
    address _address,
    uint256 timestamp
  );

  event _renewed(
    uint256 indexed _id,
    uint256 _ref,
    uint8 _plan,
    address _address,
    uint256 timestamp
  );

  event _uplineMemberRef(
    uint256 indexed _id,
    uint256 _ref,
    uint8 _plan,
    address _address,
    uint256 _amount,
    uint256 timestamp
  );

  // >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

  event _picked(
    uint256 indexed _id,
    uint256 _ref,
    uint8 _plan,
    uint8 _game,
    uint256 _gameId,
    uint256 _amount,
    uint256 _timestamp
  );

  event _uplinePicksRef(
    uint256 indexed _id,
    uint256 _ref,
    uint8 _plan,
    address _address,
    uint8 _game,
    uint256 _amount,
    uint256 timestamp
  );

  // >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

  event _winnersAnnounced(
    uint8 _game,
    uint256 _gameId,
    uint8[] _winners,
    uint256 _timestamp
  );

  event _prizesWithdraw(
    uint8 _game,
    uint256 _gameId,
    uint256 _amount,
    uint256 _timestamp
  );

  event _prizesWinner(
    uint256 indexed _id,
    uint256 _ref,
    uint8 _plan,
    address _address,
    uint8 _game,
    uint256 _gameId,
    uint8 _prize,
    uint256 _amount,
    uint256 _timestamp
  );
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

import "../openzeppelin/contracts/token/ERC20/IERC20.sol";

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
  function safeApprove(address token, address to, uint256 value) internal {
    // bytes4(keccak256(bytes('approve(address,uint256)')));
    (bool success, bytes memory data) = token.call(
      abi.encodeWithSelector(0x095ea7b3, to, value)
    );
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      "TransferHelper::safeApprove: approve failed"
    );
  }

  function safeTransfer(address token, address to, uint256 value) internal {
    // bytes4(keccak256(bytes('transfer(address,uint256)')));
    (bool success, bytes memory data) = token.call(
      abi.encodeWithSelector(0xa9059cbb, to, value)
    );
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      "TransferHelper::safeTransfer: transfer failed"
    );
  }

  function safeTransferFrom(
    address token,
    address from,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    (bool success, bytes memory data) = token.call(
      abi.encodeWithSelector(0x23b872dd, from, to, value)
    );
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      "TransferHelper::transferFrom: transferFrom failed"
    );
  }

  function safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{ value: value }(new bytes(0));
    require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor(address _ownerAddress) {
    _transferOwnership(_ownerAddress);
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    _checkOwner();
    _;
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view virtual returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if the sender is not the owner.
   */
  function _checkOwner() internal view virtual {
    require(owner() == _msgSender(), "Ownable: caller is not the owner");
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public virtual onlyOwner {
    _transferOwnership(address(0));
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Internal function without access restriction.
   */
  function _transferOwnership(address newOwner) internal virtual {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}