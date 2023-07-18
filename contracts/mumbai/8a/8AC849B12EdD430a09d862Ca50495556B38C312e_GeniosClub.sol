// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "./IGeniosClub.sol";
import "./IPool.sol";

contract GeniosClub is IGeniosClub {
  address public Id0;
  address public TOKEN;
  bool internal Locked;

  struct User {
    uint256 Id;
    address Ref;
    uint256 Amount;
    uint256 TotalTeam;
    uint256 DirectRefs;
    uint256 G3X2Earnings;
    uint256 G3X7Earnings;
    uint256[] DirectRefsIds;
    mapping(uint8 => Rank) Ranks;
    mapping(uint8 => RankTeam) RankTeams;
    mapping(uint8 => G3X2) G3X2Matrix;
    mapping(uint8 => G3X7) G3X7Matrix;
    mapping(uint8 => bool) ActiveG3X2Levels;
    mapping(uint8 => bool) ActiveG3X7Levels;
    mapping(uint8 => uint256) G3X7MatrixRecycleAmount;
  }

  struct Rank {
    bool IsActive;
    uint256 TotalTeam;
    uint256 DirectRefs;
  }

  struct RankTeam {
    uint256 G3x7FirstTeam;
    uint256 G3x7SecondTeam;
    uint256 G3x7ThirdTeam;
    uint256 G3x7FourthTeam;
    uint256 G3x7FifthTeam;
    uint256 G3x7SixthTeam;
    uint256 G3x7SeventhTeam;
  }

  struct G3X2 {
    address CurrentRef;
    address[] FirstLevelRefs;
    address[] SecondLevelRefs;
    bool Blocked;
    uint256 ReinvestCount;
    uint256 ReinvestTime;
    uint256 Earnings;
  }

  struct G3X7 {
    address CurrentRef;
    address[] FirstLevelRefs;
    address[] SecondLevelRefs;
    address[] ThirdLevelRefs;
    address[] FourthLevelRefs;
    address[] FifthLevelRefs;
    address[] SixthLevelRefs;
    address[] SeventhLevelRefs;
    bool Blocked;
    uint256 ReinvestCount;
    uint256 ReinvestTime;
    uint256 Earnings;
  }

  struct Teams {
    // G3x2
    uint256 G3x2FirstTeam;
    uint256 G3x2SecondTeam;
    // G3x7
    uint256 G3x7FirstTeam;
    uint256 G3x7SecondTeam;
    uint256 G3x7ThirdTeam;
    uint256 G3x7FourthTeam;
    uint256 G3x7FifthTeam;
    uint256 G3x7SixthTeam;
    uint256 G3x7SeventhTeam;
  }

  struct Plat {
    uint256 G3X2TotalEarnings;
    uint256 G3X7TotalEarnings;
  }

  Plat public Platform;
  uint256 public LastUserId = 1;
  mapping(address => User) public Users;
  mapping(address => Teams) public UsersTeams;
  mapping(address => bool) public IsUserExists;
  mapping(uint256 => address) public IdToAddress;

  uint8 public constant LAST_LEVEL = 8;
  uint256[9] public LevelPrice = [
    0,
    2.5e18,
    10e18,
    40e18,
    160e18,
    640e18,
    2560e18,
    10240e18,
    40960e18
  ];
  uint256[9] public RankReqTotalTeam = [
    0,
    10,
    40,
    160,
    640,
    2560,
    10240,
    40960,
    163840
  ];
  uint256[9] public RankTeamPerLineLimit = [
    0,
    10,
    10,
    40,
    160,
    640,
    2560,
    10240,
    40960
  ];
  uint8[8] public LevelPricePercentage = [0, 15, 10, 5, 5, 5, 5, 5];

  uint8 public RanksComm = 25;
  uint8 public AcademyAndMarketingComm = 25;

  address public PoolAddr;
  address public AcademyAndMarketingAddr;

  constructor(
    address id0,
    address tokenAddr,
    address poolAddr,
    address academyAndMarketingAddr
  ) {
    Id0 = id0;
    TOKEN = tokenAddr;
    PoolAddr = poolAddr;
    AcademyAndMarketingAddr = academyAndMarketingAddr;

    Users[Id0].Id = 0;
    IdToAddress[0] = Id0;
    IsUserExists[Id0] = true;
    for (uint8 i = 1; i <= LAST_LEVEL; i++) {
      Users[Id0].Ranks[i].IsActive = true;
      Users[Id0].ActiveG3X2Levels[i] = true;
      Users[Id0].ActiveG3X7Levels[i] = true;
      Users[Id0].G3X7Matrix[i].CurrentRef = Id0;
    }

    IPool(PoolAddr).setContractAddr(address(this), Id0);
  }

  modifier noReentrant() {
    require(!Locked, "No re-entrancy");
    Locked = true;
    _;
    Locked = false;
  }

  function RegistrationExt(
    address refAddr,
    address curRefaddr
  ) external noReentrant {
    TransferHelper.safeTransferFrom(
      TOKEN,
      msg.sender,
      address(this),
      LevelPrice[1] * 2
    );

    _registration(msg.sender, refAddr, curRefaddr);
  }

  function buyNewLevel(
    address curRefaddr,
    uint8 level,
    uint8 matrix
  ) external noReentrant {
    require(matrix == 1 || matrix == 2, "GC: Invalid matrix");

    TransferHelper.safeTransferFrom(
      TOKEN,
      msg.sender,
      address(this),
      LevelPrice[level]
    );

    if (matrix == 1) {
      return _buyNewLevelG3X2(msg.sender, level);
    }

    _buyNewLevelG3X7(msg.sender, curRefaddr, level);
  }

  function _registration(
    address userAddr,
    address refAddr,
    address curRefaddr
  ) private {
    require(!IsUserExists[userAddr], "GC: User exists");
    require(IsUserExists[refAddr], "GC: Referrer not exists");

    uint8 level = 1;

    Users[userAddr].Id = LastUserId;
    Users[userAddr].Ref = refAddr;

    IdToAddress[LastUserId] = userAddr;
    Users[userAddr].Ref = refAddr;
    IsUserExists[userAddr] = true;
    LastUserId++;

    Users[refAddr].DirectRefs++;
    Users[refAddr].DirectRefsIds.push(LastUserId);

    Users[userAddr].ActiveG3X2Levels[level] = true;
    Users[userAddr].ActiveG3X7Levels[level] = true;

    if (!Users[refAddr].Ranks[level].IsActive)
      Users[refAddr].Ranks[level].DirectRefs++;

    address freeG3X2Ref = findFreeG3X2Referrer(userAddr, level);
    updateG3X2Referrer(userAddr, freeG3X2Ref, level);

    updateG3X7Referrer(userAddr, curRefaddr, level);

    emit UserAdd(userAddr, curRefaddr, level);
    emit Registration(userAddr, refAddr, Users[userAddr].Id, Users[refAddr].Id);
  }

  function _buyNewLevelG3X2(address userAddr, uint8 level) internal {
    require(IsUserExists[userAddr], "GC: Register first.");

    require(!Users[userAddr].ActiveG3X2Levels[level], "GC: Level activated");

    require(level > 1 && level <= LAST_LEVEL, "GC: Invalid level");

    require(
      Users[userAddr].ActiveG3X2Levels[level - 1],
      "GC: Previous level inactive"
    );

    Users[userAddr].ActiveG3X2Levels[level] = true;
    if (Users[userAddr].G3X2Matrix[level - 1].Blocked) {
      Users[userAddr].G3X2Matrix[level - 1].Blocked = false;
    }

    address freeG3X2Ref = findFreeG3X2Referrer(userAddr, level);
    updateG3X2Referrer(userAddr, freeG3X2Ref, level);

    emit Upgrade(Users[userAddr].Id, userAddr, freeG3X2Ref, 1, level);
  }

  function _buyNewLevelG3X7(
    address userAddr,
    address curRefaddr,
    uint8 level
  ) internal {
    require(IsUserExists[userAddr], "GC: Register first.");

    require(!Users[userAddr].ActiveG3X7Levels[level], "GC: Level activated");

    require(level > 1 && level <= LAST_LEVEL, "GC: Invalid level");

    require(
      Users[userAddr].ActiveG3X7Levels[level - 1],
      "GC: Previous level inactive"
    );

    Users[userAddr].ActiveG3X7Levels[level] = true;
    if (Users[userAddr].G3X7Matrix[level - 1].Blocked) {
      Users[userAddr].G3X7Matrix[level - 1].Blocked = false;
    }

    if (
      !Users[userAddr].Ranks[level - 1].IsActive &&
      Users[userAddr].Ranks[level - 1].DirectRefs >= 3 &&
      Users[userAddr].Ranks[level - 1].TotalTeam >= RankReqTotalTeam[level - 1]
    ) {
      _activeUserRank(userAddr, level - 1);
    }

    updateG3X7Referrer(userAddr, curRefaddr, level);

    emit UserAdd(userAddr, curRefaddr, level);
    emit Upgrade(Users[userAddr].Id, userAddr, curRefaddr, 1, level);
  }

  function updateG3X2Referrer(
    address userAddr,
    address refAddr,
    uint8 level
  ) private {
    require(
      Users[refAddr].ActiveG3X2Levels[level],
      "GC: Referrer level inactive"
    );

    if (Users[refAddr].G3X2Matrix[level].FirstLevelRefs.length < 3) {
      Users[refAddr].G3X2Matrix[level].FirstLevelRefs.push(userAddr);
      UsersTeams[refAddr].G3x2FirstTeam++;

      emit NewUserPlace(
        userAddr,
        refAddr,
        Users[refAddr].Id,
        1,
        level,
        uint8(Users[refAddr].G3X2Matrix[level].FirstLevelRefs.length)
      );

      //set current level
      Users[userAddr].G3X2Matrix[level].CurrentRef = refAddr;

      if (refAddr == Id0) {
        return sendG3X2TokenDividends(refAddr, userAddr, level);
      }

      address ref = Users[refAddr].G3X2Matrix[level].CurrentRef;
      Users[ref].G3X2Matrix[level].SecondLevelRefs.push(userAddr);
      UsersTeams[ref].G3x2SecondTeam++;

      emit NewUserPlace(
        userAddr,
        ref,
        Users[refAddr].Id,
        1,
        level,
        uint8(Users[refAddr].G3X2Matrix[level].FirstLevelRefs.length)
      );

      return updateG3X2RefSecondLevel(userAddr, ref, level);
    }

    Users[refAddr].G3X2Matrix[level].SecondLevelRefs.push(userAddr);
    UsersTeams[refAddr].G3x2SecondTeam++;

    if (
      (Users[Users[refAddr].G3X2Matrix[level].FirstLevelRefs[0]]
        .G3X2Matrix[level]
        .FirstLevelRefs
        .length <=
        Users[Users[refAddr].G3X2Matrix[level].FirstLevelRefs[1]]
          .G3X2Matrix[level]
          .FirstLevelRefs
          .length) &&
      (Users[Users[refAddr].G3X2Matrix[level].FirstLevelRefs[1]]
        .G3X2Matrix[level]
        .FirstLevelRefs
        .length <=
        Users[Users[refAddr].G3X2Matrix[level].FirstLevelRefs[2]]
          .G3X2Matrix[level]
          .FirstLevelRefs
          .length)
    ) {
      updateG3X2(userAddr, refAddr, level, 0);
    } else if (
      Users[Users[refAddr].G3X2Matrix[level].FirstLevelRefs[1]]
        .G3X2Matrix[level]
        .FirstLevelRefs
        .length <=
      Users[Users[refAddr].G3X2Matrix[level].FirstLevelRefs[2]]
        .G3X2Matrix[level]
        .FirstLevelRefs
        .length
    ) {
      updateG3X2(userAddr, refAddr, level, 1);
    } else {
      updateG3X2(userAddr, refAddr, level, 2);
    }

    updateG3X2RefSecondLevel(userAddr, refAddr, level);
  }

  function updateG3X2(
    address userAddr,
    address refAddr,
    uint8 level,
    uint8 x2
  ) private {
    Users[Users[refAddr].G3X2Matrix[level].FirstLevelRefs[x2]]
      .G3X2Matrix[level]
      .FirstLevelRefs
      .push(userAddr);

    UsersTeams[Users[refAddr].G3X2Matrix[level].FirstLevelRefs[x2]]
      .G3x2FirstTeam++;

    emit NewUserPlace(
      userAddr,
      Users[refAddr].G3X2Matrix[level].FirstLevelRefs[x2],
      Users[refAddr].Id,
      1,
      level,
      uint8(
        Users[Users[refAddr].G3X2Matrix[level].FirstLevelRefs[x2]]
          .G3X2Matrix[level]
          .FirstLevelRefs
          .length
      )
    );

    emit NewUserPlace(
      userAddr,
      refAddr,
      Users[refAddr].Id,
      1,
      level,
      uint8(
        Users[Users[refAddr].G3X2Matrix[level].FirstLevelRefs[x2]]
          .G3X2Matrix[level]
          .FirstLevelRefs
          .length
      )
    );

    //set current level
    Users[userAddr].G3X2Matrix[level].CurrentRef = Users[refAddr]
      .G3X2Matrix[level]
      .FirstLevelRefs[x2];
  }

  function updateG3X2RefSecondLevel(
    address userAddr,
    address refAddr,
    uint8 level
  ) private {
    uint256 len = Users[refAddr].G3X2Matrix[level].SecondLevelRefs.length;

    if (len < 9) {
      if (
        !Users[refAddr].ActiveG3X2Levels[level + 1] &&
        level != LAST_LEVEL &&
        len > 4
      ) {
        Users[refAddr].Amount += LevelPrice[level];

        if (Users[refAddr].Amount >= LevelPrice[level + 1]) {
          _buyNewLevelG3X2(refAddr, level + 1);
          Users[refAddr].Amount -= LevelPrice[level + 1];
        }
        return;
      }

      return sendG3X2TokenDividends(refAddr, userAddr, level);
    }

    // recycle
    Users[refAddr].G3X2Matrix[level].FirstLevelRefs = new address[](0);
    Users[refAddr].G3X2Matrix[level].SecondLevelRefs = new address[](0);

    if (!Users[refAddr].ActiveG3X2Levels[level + 1] && level != LAST_LEVEL) {
      Users[refAddr].G3X2Matrix[level].Blocked = true;
    }

    Users[refAddr].G3X2Matrix[level].ReinvestCount++;
    Users[refAddr].G3X2Matrix[level].ReinvestTime = block.timestamp;

    if (refAddr != Id0) {
      address freeRefAddr = findFreeG3X2Referrer(refAddr, level);
      emit Reinvest(
        Users[refAddr].Id,
        refAddr,
        freeRefAddr,
        userAddr,
        1,
        level
      );

      updateG3X2Referrer(refAddr, freeRefAddr, level);
    } else {
      emit Reinvest(Users[Id0].Id, Id0, address(0), userAddr, 1, level);
      sendG3X2TokenDividends(Id0, userAddr, level);
    }
  }

  function findFreeG3X2Referrer(
    address userAddr,
    uint8 level
  ) public view returns (address refAddr) {
    while (true) {
      if (Users[Users[userAddr].Ref].ActiveG3X2Levels[level]) {
        return Users[userAddr].Ref;
      }
      userAddr = Users[userAddr].Ref;
    }
  }

  function _activeUserRank(address userAddr, uint8 level) private {
    if (
      !Users[Users[userAddr].Ref].Ranks[level].IsActive &&
      Users[userAddr].Ref != Id0 &&
      level != LAST_LEVEL
    ) Users[Users[userAddr].Ref].Ranks[level + 1].DirectRefs++;

    IPool(PoolAddr).AddUser(level, userAddr);
    Users[userAddr].Ranks[level].IsActive = true;
    emit RankEarners(Users[userAddr].Id, userAddr, level);
  }

  function updateG3X7Referrer(
    address userAddr,
    address curRefaddr,
    uint8 level
  ) private {
    require(
      Users[curRefaddr].ActiveG3X7Levels[level] &&
        Users[curRefaddr].G3X7Matrix[level].FirstLevelRefs.length < 3,
      "GC: Referrer level inactive"
    );

    // Update the referrer's referrals based on the level
    Users[curRefaddr].G3X7Matrix[level].FirstLevelRefs.push(userAddr);
    Users[userAddr].G3X7Matrix[level].CurrentRef = curRefaddr;
    UsersTeams[curRefaddr].G3x7FirstTeam++;
    Users[curRefaddr].TotalTeam++;

    if (
      RankTeamPerLineLimit[level] >=
      Users[curRefaddr].RankTeams[level].G3x7FirstTeam &&
      !Users[curRefaddr].Ranks[level].IsActive
    ) {
      Users[curRefaddr].Ranks[level].TotalTeam++;
      Users[curRefaddr].RankTeams[level].G3x7FirstTeam++;
    }

    if (
      !Users[curRefaddr].Ranks[level].IsActive &&
      Users[curRefaddr].Ranks[level].DirectRefs >= 3 &&
      Users[curRefaddr].Ranks[level].TotalTeam >= RankReqTotalTeam[level]
    ) {
      if (
        (Users[curRefaddr].ActiveG3X7Levels[level + 1] &&
          level != LAST_LEVEL) || level == LAST_LEVEL
      ) {
        _activeUserRank(curRefaddr, level);
      }
    }

    if (curRefaddr == Id0) {
      return sendG3X7TokenDividends(curRefaddr, userAddr, level, address(0));
    }

    address ref_currentRef = Users[curRefaddr].G3X7Matrix[level].CurrentRef;
    Users[ref_currentRef].G3X7Matrix[level].SecondLevelRefs.push(userAddr);
    UsersTeams[ref_currentRef].G3x7SecondTeam++;
    Users[ref_currentRef].TotalTeam++;

    if (
      RankTeamPerLineLimit[level] >=
      Users[ref_currentRef].RankTeams[level].G3x7SecondTeam &&
      !Users[ref_currentRef].Ranks[level].IsActive
    ) {
      Users[ref_currentRef].Ranks[level].TotalTeam++;
      Users[ref_currentRef].RankTeams[level].G3x7SecondTeam++;
    }

    if (
      !Users[ref_currentRef].Ranks[level].IsActive &&
      Users[ref_currentRef].Ranks[level].DirectRefs >= 3 &&
      Users[ref_currentRef].Ranks[level].TotalTeam >= RankReqTotalTeam[level]
    ) {
      if (
        (Users[ref_currentRef].ActiveG3X7Levels[level + 1] &&
          level != LAST_LEVEL) || level == LAST_LEVEL
      ) {
        _activeUserRank(ref_currentRef, level);
      }
    }

    if (ref_currentRef == Id0) {
      return sendG3X7TokenDividends(curRefaddr, userAddr, level, address(0));
    }

    ref_currentRef = Users[ref_currentRef].G3X7Matrix[level].CurrentRef;
    Users[ref_currentRef].G3X7Matrix[level].ThirdLevelRefs.push(userAddr);
    UsersTeams[ref_currentRef].G3x7ThirdTeam++;
    Users[ref_currentRef].TotalTeam++;

    if (
      RankTeamPerLineLimit[level] >=
      Users[ref_currentRef].RankTeams[level].G3x7SecondTeam &&
      !Users[ref_currentRef].Ranks[level].IsActive
    ) {
      Users[ref_currentRef].Ranks[level].TotalTeam++;
      Users[ref_currentRef].RankTeams[level].G3x7SecondTeam++;
    }

    if (
      !Users[ref_currentRef].Ranks[level].IsActive &&
      Users[ref_currentRef].Ranks[level].DirectRefs >= 3 &&
      Users[ref_currentRef].Ranks[level].TotalTeam >= RankReqTotalTeam[level]
    ) {
      if (
        (Users[ref_currentRef].ActiveG3X7Levels[level + 1] &&
          level != LAST_LEVEL) || level == LAST_LEVEL
      ) {
        _activeUserRank(ref_currentRef, level);
      }
    }

    if (ref_currentRef == Id0) {
      return sendG3X7TokenDividends(curRefaddr, userAddr, level, address(0));
    }

    ref_currentRef = Users[ref_currentRef].G3X7Matrix[level].CurrentRef;
    Users[ref_currentRef].G3X7Matrix[level].FourthLevelRefs.push(userAddr);
    UsersTeams[ref_currentRef].G3x7FourthTeam++;
    Users[ref_currentRef].TotalTeam++;

    if (
      RankTeamPerLineLimit[level] >=
      Users[ref_currentRef].RankTeams[level].G3x7SecondTeam &&
      !Users[ref_currentRef].Ranks[level].IsActive
    ) {
      Users[ref_currentRef].Ranks[level].TotalTeam++;
      Users[ref_currentRef].RankTeams[level].G3x7SecondTeam++;
    }

    if (
      !Users[ref_currentRef].Ranks[level].IsActive &&
      Users[ref_currentRef].Ranks[level].DirectRefs >= 3 &&
      Users[ref_currentRef].Ranks[level].TotalTeam >= RankReqTotalTeam[level]
    ) {
      if (
        (Users[ref_currentRef].ActiveG3X7Levels[level + 1] &&
          level != LAST_LEVEL) || level == LAST_LEVEL
      ) {
        _activeUserRank(ref_currentRef, level);
      }
    }

    if (ref_currentRef == Id0) {
      return sendG3X7TokenDividends(curRefaddr, userAddr, level, address(0));
    }

    ref_currentRef = Users[ref_currentRef].G3X7Matrix[level].CurrentRef;
    Users[ref_currentRef].G3X7Matrix[level].FifthLevelRefs.push(userAddr);
    UsersTeams[ref_currentRef].G3x7FifthTeam++;
    Users[ref_currentRef].TotalTeam++;

    if (
      RankTeamPerLineLimit[level] >=
      Users[ref_currentRef].RankTeams[level].G3x7SecondTeam &&
      !Users[ref_currentRef].Ranks[level].IsActive
    ) {
      Users[ref_currentRef].Ranks[level].TotalTeam++;
      Users[ref_currentRef].RankTeams[level].G3x7SecondTeam++;
    }

    if (
      !Users[ref_currentRef].Ranks[level].IsActive &&
      Users[ref_currentRef].Ranks[level].DirectRefs >= 3 &&
      Users[ref_currentRef].Ranks[level].TotalTeam >= RankReqTotalTeam[level]
    ) {
      if (
        (Users[ref_currentRef].ActiveG3X7Levels[level + 1] &&
          level != LAST_LEVEL) || level == LAST_LEVEL
      ) {
        _activeUserRank(ref_currentRef, level);
      }
    }

    if (ref_currentRef == Id0) {
      return sendG3X7TokenDividends(curRefaddr, userAddr, level, address(0));
    }

    ref_currentRef = Users[ref_currentRef].G3X7Matrix[level].CurrentRef;
    Users[ref_currentRef].G3X7Matrix[level].SixthLevelRefs.push(userAddr);
    UsersTeams[ref_currentRef].G3x7SixthTeam++;
    Users[ref_currentRef].TotalTeam++;

    if (
      RankTeamPerLineLimit[level] >=
      Users[ref_currentRef].RankTeams[level].G3x7SecondTeam &&
      !Users[ref_currentRef].Ranks[level].IsActive
    ) {
      Users[ref_currentRef].Ranks[level].TotalTeam++;
      Users[ref_currentRef].RankTeams[level].G3x7SecondTeam++;
    }

    if (
      !Users[ref_currentRef].Ranks[level].IsActive &&
      Users[ref_currentRef].Ranks[level].DirectRefs >= 3 &&
      Users[ref_currentRef].Ranks[level].TotalTeam >= RankReqTotalTeam[level]
    ) {
      if (
        (Users[ref_currentRef].ActiveG3X7Levels[level + 1] &&
          level != LAST_LEVEL) || level == LAST_LEVEL
      ) {
        _activeUserRank(ref_currentRef, level);
      }
    }

    if (ref_currentRef == Id0) {
      return sendG3X7TokenDividends(curRefaddr, userAddr, level, address(0));
    }

    ref_currentRef = Users[ref_currentRef].G3X7Matrix[level].CurrentRef;
    Users[ref_currentRef].G3X7Matrix[level].SeventhLevelRefs.push(userAddr);
    UsersTeams[ref_currentRef].G3x7SeventhTeam++;
    Users[ref_currentRef].TotalTeam++;

    if (
      RankTeamPerLineLimit[level] >=
      Users[ref_currentRef].RankTeams[level].G3x7SecondTeam &&
      !Users[ref_currentRef].Ranks[level].IsActive
    ) {
      Users[ref_currentRef].Ranks[level].TotalTeam++;
      Users[ref_currentRef].RankTeams[level].G3x7SecondTeam++;
    }

    if (
      !Users[ref_currentRef].Ranks[level].IsActive &&
      Users[ref_currentRef].Ranks[level].DirectRefs >= 3 &&
      Users[ref_currentRef].Ranks[level].TotalTeam >= RankReqTotalTeam[level]
    ) {
      if (
        (Users[ref_currentRef].ActiveG3X7Levels[level + 1] &&
          level != LAST_LEVEL) || level == LAST_LEVEL
      ) {
        _activeUserRank(ref_currentRef, level);
      }
    }

    updateG3X7RefLastLevel(userAddr, curRefaddr, level);
  }

  function updateG3X7RefLastLevel(
    address userAddr,
    address curRefaddr,
    uint8 level
  ) private {
    uint256 len = Users[curRefaddr].G3X7Matrix[level].SeventhLevelRefs.length;

    if (len <= 2167) {
      return sendG3X7TokenDividends(curRefaddr, userAddr, level, address(0));
    }

    if (len < 2187) {
      uint256 amount = calPerc(LevelPrice[level], LevelPricePercentage[1]);
      Users[curRefaddr].G3X7MatrixRecycleAmount[level] += amount;
      return sendG3X7TokenDividends(curRefaddr, userAddr, level, curRefaddr);
    }

    Users[curRefaddr].G3X7MatrixRecycleAmount[level] = 0;
    sendG3X7TokenDividends(curRefaddr, userAddr, level, curRefaddr);

    // recycle
    Users[curRefaddr].G3X7Matrix[level].FirstLevelRefs = new address[](0);
    Users[curRefaddr].G3X7Matrix[level].SecondLevelRefs = new address[](0);
    Users[curRefaddr].G3X7Matrix[level].ThirdLevelRefs = new address[](0);
    Users[curRefaddr].G3X7Matrix[level].FourthLevelRefs = new address[](0);
    Users[curRefaddr].G3X7Matrix[level].FifthLevelRefs = new address[](0);
    Users[curRefaddr].G3X7Matrix[level].SixthLevelRefs = new address[](0);
    Users[curRefaddr].G3X7Matrix[level].SeventhLevelRefs = new address[](0);

    if (!Users[curRefaddr].ActiveG3X7Levels[level + 1] && level != LAST_LEVEL) {
      Users[curRefaddr].G3X7Matrix[level].Blocked = true;
    }

    Users[curRefaddr].G3X7Matrix[level].ReinvestCount++;
    Users[curRefaddr].G3X7Matrix[level].ReinvestTime = block.timestamp;

    if (curRefaddr != Id0) {
      address freeRefAddr = findFreeG3X7Referrer(curRefaddr, level);

      emit Reinvest(
        Users[curRefaddr].Id,
        curRefaddr,
        freeRefAddr,
        userAddr,
        2,
        level
      );

      sendG3X7TokenDividends(freeRefAddr, userAddr, level, address(0));
    } else {
      emit Reinvest(Users[Id0].Id, Id0, address(0), userAddr, 2, level);
      sendG3X7TokenDividends(Id0, userAddr, level, address(0));
    }
  }

  function findFreeG3X7Referrer(
    address userAddr,
    uint8 level
  ) public view returns (address refAddr) {
    while (true) {
      if (Users[Users[userAddr].Ref].ActiveG3X7Levels[level]) {
        return Users[userAddr].Ref;
      }
      userAddr = Users[userAddr].Ref;
    }
  }

  function sendG3X2TokenDividends(
    address refAddr,
    address userAddr,
    uint8 level
  ) private {
    (address receiver, bool isExtraDividends) = findTokenG3X2Receiver(
      refAddr,
      userAddr,
      level
    );

    uint256 amount1 = LevelPrice[level];
    TransferHelper.safeTransfer(TOKEN, receiver, amount1);

    Platform.G3X2TotalEarnings += amount1;
    Users[receiver].G3X2Earnings += amount1;
    Users[receiver].G3X2Matrix[level].Earnings += amount1;

    if (isExtraDividends)
      emit SentExtraTokenDividends(
        Users[userAddr].Id,
        userAddr,
        receiver,
        1,
        level
      );
  }

  function sendG3X7TokenDividends(
    address refAddr,
    address userAddr,
    uint8 level,
    address lastRef
  ) private {
    (address receiver, bool isExtraDividends) = findTokenG3X7Receiver(
      refAddr,
      userAddr,
      level
    );

    updateG3X7Pool(receiver, level);
    updateG3X7Academy(receiver, level);

    uint8 i = 1;
    while (i <= 7) {
      if (i > 1 && receiver != Id0)
        receiver = Users[receiver].G3X7Matrix[level].CurrentRef;

      if (lastRef == receiver) return;

      uint256 amount2 = calPerc(LevelPrice[level], LevelPricePercentage[i]);
      TransferHelper.safeTransfer(TOKEN, receiver, amount2);

      Platform.G3X7TotalEarnings += amount2;
      Users[receiver].G3X7Earnings += amount2;
      Users[receiver].G3X7Matrix[level].Earnings += amount2;

      if (isExtraDividends)
        emit SentExtraTokenDividends(
          Users[userAddr].Id,
          userAddr,
          receiver,
          2,
          level
        );

      i++;
    }
  }

  function findTokenG3X2Receiver(
    address refAddr,
    address userAddr,
    uint8 level
  ) private returns (address _receiver, bool _isExtraDividends) {
    address receiver = refAddr;
    bool isExtraDividends;

    while (true) {
      if (Users[receiver].G3X2Matrix[level].Blocked) {
        emit MissedTokenReceive(
          Users[receiver].Id,
          receiver,
          userAddr,
          2,
          level
        );
        isExtraDividends = true;
        receiver = Users[receiver].G3X2Matrix[level].CurrentRef;
      } else {
        return (receiver, isExtraDividends);
      }
    }
  }

  function findTokenG3X7Receiver(
    address refAddr,
    address userAddr,
    uint8 level
  ) private returns (address _receiver, bool _isExtraDividends) {
    address receiver = refAddr;
    bool isExtraDividends;

    while (true) {
      if (Users[receiver].G3X7Matrix[level].Blocked) {
        emit MissedTokenReceive(
          Users[receiver].Id,
          receiver,
          userAddr,
          2,
          level
        );
        isExtraDividends = true;
        receiver = Users[receiver].G3X7Matrix[level].CurrentRef;
      } else {
        return (receiver, isExtraDividends);
      }
    }
  }

  function updateG3X7Pool(address userAddr, uint8 level) private {
    uint256 commAmount = calPerc(LevelPrice[level], RanksComm);
    TransferHelper.safeTransfer(TOKEN, PoolAddr, commAmount);
    IPool(PoolAddr).DepositAmount(level, commAmount);
    emit G3X7RankUpdated(Users[userAddr].Id, userAddr, level, commAmount);
  }

  function updateG3X7Academy(address userAddr, uint8 level) private {
    uint256 commAmount = calPerc(LevelPrice[level], AcademyAndMarketingComm);
    TransferHelper.safeTransfer(TOKEN, AcademyAndMarketingAddr, commAmount);
    emit G3X7AcademyUpdated(Users[userAddr].Id, userAddr, level, commAmount);
  }

  function activateAllG3X2Levels(address userAddr) public {
    require(Id0 == msg.sender, "GC: !Id0");

    for (uint8 i = 1; i <= LAST_LEVEL; i++) {
      Users[userAddr].ActiveG3X2Levels[i] = true;
      Users[userAddr].G3X2Matrix[i].Blocked = false;
    }
  }

  function activateAllG3X7Levels(address userAddr) public {
    require(Id0 == msg.sender, "GC: !Id0");

    for (uint8 i = 1; i <= LAST_LEVEL; i++) {
      Users[userAddr].ActiveG3X7Levels[i] = true;
      Users[userAddr].G3X7Matrix[i].Blocked = false;
    }
  }

  function usersActiveG3X2Levels(
    address userAddr,
    uint8 level
  ) public view returns (bool) {
    return Users[userAddr].ActiveG3X2Levels[level];
  }

  function usersActiveG3X7Levels(
    address userAddr,
    uint8 level
  ) public view returns (bool) {
    return Users[userAddr].ActiveG3X7Levels[level];
  }

  function usersRanks(
    address userAddr,
    uint8 level
  ) public view returns (Rank memory) {
    return
      Rank({
        IsActive: Users[userAddr].Ranks[level].IsActive,
        TotalTeam: Users[userAddr].Ranks[level].TotalTeam,
        DirectRefs: Users[userAddr].Ranks[level].DirectRefs
      });
  }

  function usersRankTeams(
    address userAddr,
    uint8 level
  ) public view returns (RankTeam memory) {
    return
      RankTeam({
        G3x7FirstTeam: Users[userAddr].RankTeams[level].G3x7FirstTeam,
        G3x7SecondTeam: Users[userAddr].RankTeams[level].G3x7SecondTeam,
        G3x7ThirdTeam: Users[userAddr].RankTeams[level].G3x7ThirdTeam,
        G3x7FourthTeam: Users[userAddr].RankTeams[level].G3x7FourthTeam,
        G3x7FifthTeam: Users[userAddr].RankTeams[level].G3x7FifthTeam,
        G3x7SixthTeam: Users[userAddr].RankTeams[level].G3x7SixthTeam,
        G3x7SeventhTeam: Users[userAddr].RankTeams[level].G3x7SeventhTeam
      });
  }

  function usersG3X2Matrix(
    address userAddr,
    uint8 level
  ) public view returns (G3X2 memory) {
    return
      G3X2({
        CurrentRef: Users[userAddr].G3X2Matrix[level].CurrentRef,
        FirstLevelRefs: Users[userAddr].G3X2Matrix[level].FirstLevelRefs,
        SecondLevelRefs: Users[userAddr].G3X2Matrix[level].SecondLevelRefs,
        Blocked: Users[userAddr].G3X2Matrix[level].Blocked,
        ReinvestCount: Users[userAddr].G3X2Matrix[level].ReinvestCount,
        ReinvestTime: Users[userAddr].G3X2Matrix[level].ReinvestTime,
        Earnings: Users[userAddr].G3X2Matrix[level].Earnings
      });
  }

  function usersG3X7Matrix(
    address userAddr,
    uint8 level
  ) public view returns (G3X7 memory) {
    return
      G3X7({
        CurrentRef: Users[userAddr].G3X7Matrix[level].CurrentRef,
        FirstLevelRefs: Users[userAddr].G3X7Matrix[level].FirstLevelRefs,
        SecondLevelRefs: Users[userAddr].G3X7Matrix[level].SecondLevelRefs,
        ThirdLevelRefs: Users[userAddr].G3X7Matrix[level].ThirdLevelRefs,
        FourthLevelRefs: Users[userAddr].G3X7Matrix[level].FourthLevelRefs,
        FifthLevelRefs: Users[userAddr].G3X7Matrix[level].FifthLevelRefs,
        SixthLevelRefs: Users[userAddr].G3X7Matrix[level].SixthLevelRefs,
        SeventhLevelRefs: Users[userAddr].G3X7Matrix[level].SeventhLevelRefs,
        Blocked: Users[userAddr].G3X7Matrix[level].Blocked,
        ReinvestCount: Users[userAddr].G3X7Matrix[level].ReinvestCount,
        ReinvestTime: Users[userAddr].G3X7Matrix[level].ReinvestTime,
        Earnings: Users[userAddr].G3X7Matrix[level].Earnings
      });
  }

  function withdraw() external noReentrant {
    require(IsUserExists[msg.sender], "GC: Users not exists");
    require(Users[msg.sender].Amount > 0, "GC: Users didn't have any amount");

    TransferHelper.safeTransfer(TOKEN, msg.sender, Users[msg.sender].Amount);
    Users[msg.sender].Amount = 0;
  }

  function getDirectRefsIds(
    address userAddr
  ) public view returns (uint256[] memory refs) {
    return Users[userAddr].DirectRefsIds;
  }

  function calPerc(uint256 tAmount, uint8 tPerc) public pure returns (uint256) {
    uint256 perc = (tAmount * tPerc) / 100;
    return perc;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGeniosClub {
  event Registration(
    address indexed user,
    address indexed referrer,
    uint256 indexed userId,
    uint256 referrerId
  );

  event UserAdd(address indexed user, address indexed ref, uint8 indexed level);

  event Reinvest(
    uint256 indexed userId,
    address indexed user,
    address indexed CurrentRef,
    address caller,
    uint8 matrix,
    uint8 level
  );

  event Upgrade(
    uint256 indexed userId,
    address indexed user,
    address indexed referrer,
    uint8 matrix,
    uint8 level
  );

  event NewUserPlace(
    address indexed user,
    address indexed referrer,
    uint256 indexed userId,
    uint8 matrix,
    uint8 level,
    uint8 place
  );

  event MissedTokenReceive(
    uint256 indexed userId,
    address indexed receiver,
    address indexed from,
    uint8 matrix,
    uint8 level
  );

  event SentExtraTokenDividends(
    uint256 indexed userId,
    address indexed from,
    address indexed receiver,
    uint8 matrix,
    uint8 level
  );

  event G3X7RankUpdated(
    uint256 indexed userId,
    address indexed user,
    uint8 indexed level,
    uint256 amount
  );

  event G3X7ClubUpdated(
    uint256 indexed userId,
    address indexed user,
    uint8 indexed level,
    uint256 amount
  );

  event G3X7AcademyUpdated(
    uint256 indexed userId,
    address indexed user,
    uint8 indexed level,
    uint256 amount
  );

  event RankEarners(
    uint256 indexed userId,
    address indexed user,
    uint8 indexed level
  );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPool {
  event Deposit(uint8 indexed level, uint256 amount, uint256 week);
  event Withdraw(address indexed account, uint256 amount, uint256 week);
  event UserAdded(address indexed account, uint8 indexed level, uint256 week);

  function DepositAmount(uint8 level, uint256 amount) external returns (bool);

  function AddUser(uint8 level, address userAddr) external returns (bool);

  function setContractAddr(
    address contAddr,
    address userAddr
  ) external returns (bool);
}