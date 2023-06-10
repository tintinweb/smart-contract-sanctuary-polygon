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

contract GeniosClub_G3X2_Matrix is IGeniosClub {
  address public Id1;
  address public TOKEN;

  struct User {
    uint256 Id;
    address Ref;
    uint256 Amount;
    uint256 PartnersCount;
    mapping(uint8 => bool) ActiveG3X2Levels;
    mapping(uint8 => G3X2) G3X2Matrix;
  }

  struct G3X2 {
    address CurrentRef;
    address[] FirstLevelRefs;
    address[] SecondLevelRefs;
    bool Blocked;
    uint256 ReinvestCount;
  }

  uint256 public LastUserId = 2;
  mapping(address => User) public Users;
  mapping(uint256 => address) public IdToAddress;

  uint8 public constant LAST_LEVEL = 8;
  mapping(uint8 => uint256) public LevelPrice;

  constructor(address token, address id1) {
    Id1 = id1;
    TOKEN = token;

    LevelPrice[1] = 2.5e18;
    LevelPrice[2] = 10e18;
    LevelPrice[3] = 40e18;
    LevelPrice[4] = 160e18;
    LevelPrice[5] = 640e18;
    LevelPrice[6] = 2560e18;
    LevelPrice[7] = 10240e18;
    LevelPrice[8] = 40960e18;

    Users[Id1].Id = 1;
    Users[Id1].Ref = address(0);
    Users[Id1].PartnersCount = uint256(0);

    IdToAddress[1] = Id1;
    for (uint8 i = 1; i <= LAST_LEVEL; i++) {
      Users[Id1].ActiveG3X2Levels[i] = true;
    }
  }

  function registrationExt(address refAddr) external {
    TransferHelper.safeTransferFrom(
      TOKEN,
      msg.sender,
      address(this),
      LevelPrice[1]
    );

    _registration(msg.sender, refAddr);
  }

  function buyNewLevel(uint8 level) external {
    TransferHelper.safeTransferFrom(
      TOKEN,
      msg.sender,
      address(this),
      LevelPrice[level]
    );

    _buyNewLevel(msg.sender, level);
  }

  function _registration(address userAddr, address refAddr) private {
    require(!isUserExists(userAddr), "user exists");
    require(isUserExists(refAddr), "referrer not exists");

    Users[userAddr].Id = LastUserId;
    Users[userAddr].Ref = refAddr;
    Users[userAddr].PartnersCount = uint(0);

    IdToAddress[LastUserId] = userAddr;
    Users[userAddr].Ref = refAddr;
    LastUserId++;

    Users[refAddr].PartnersCount++;
    Users[userAddr].ActiveG3X2Levels[1] = true;

    address freeX12Referrer = findFreeX12Referrer(userAddr, 1);
    updateX12Referrer(userAddr, freeX12Referrer, 1);

    emit Registration(userAddr, refAddr, Users[userAddr].Id, Users[refAddr].Id);
  }

  function _buyNewLevel(address userAddr, uint8 level) internal {
    require(isUserExists(userAddr), "user is not exists. Register first.");

    require(
      !Users[userAddr].ActiveG3X2Levels[level],
      "level already activated"
    );

    require(level > 1 && level <= LAST_LEVEL, "invalid level");
    require(
      Users[userAddr].ActiveG3X2Levels[level - 1],
      "buy previous level first"
    );

    Users[userAddr].ActiveG3X2Levels[level] = true;
    if (Users[userAddr].G3X2Matrix[level - 1].Blocked) {
      Users[userAddr].G3X2Matrix[level - 1].Blocked = false;
    }

    address freeX12Referrer = findFreeX12Referrer(userAddr, level);
    updateX12Referrer(userAddr, freeX12Referrer, level);
    emit Upgrade(userAddr, freeX12Referrer, 2, level);
  }

  function updateX12Referrer(
    address userAddr,
    address refAddr,
    uint8 level
  ) private {
    require(
      Users[refAddr].ActiveG3X2Levels[level],
      "500. Referrer level is inactive"
    );

    if (Users[refAddr].G3X2Matrix[level].FirstLevelRefs.length < 3) {
      Users[refAddr].G3X2Matrix[level].FirstLevelRefs.push(userAddr);

      emit NewUserPlace(
        userAddr,
        refAddr,
        2,
        level,
        uint8(Users[refAddr].G3X2Matrix[level].FirstLevelRefs.length)
      );

      //set current level
      Users[userAddr].G3X2Matrix[level].CurrentRef = refAddr;

      if (refAddr == Id1) {
        return sendTokenDividends(refAddr, userAddr, 2, level);
      }

      address ref = Users[refAddr].G3X2Matrix[level].CurrentRef;
      Users[ref].G3X2Matrix[level].SecondLevelRefs.push(userAddr);

      uint len = Users[ref].G3X2Matrix[level].FirstLevelRefs.length;

      if (
        (len == 3) &&
        (Users[ref].G3X2Matrix[level].FirstLevelRefs[2] == refAddr)
      ) {
        emit NewUserPlace(
          userAddr,
          ref,
          2,
          level,
          9 + uint8(Users[refAddr].G3X2Matrix[level].FirstLevelRefs.length)
        );
      } else if (
        (len == 3 || len == 2) &&
        (Users[ref].G3X2Matrix[level].FirstLevelRefs[1] == refAddr)
      ) {
        emit NewUserPlace(
          userAddr,
          ref,
          2,
          level,
          6 + uint8(Users[refAddr].G3X2Matrix[level].FirstLevelRefs.length)
        );
      } else if (
        (len == 3 || len == 2 || len == 1) &&
        (Users[ref].G3X2Matrix[level].FirstLevelRefs[0] == refAddr)
      ) {
        emit NewUserPlace(
          userAddr,
          ref,
          2,
          level,
          3 + uint8(Users[refAddr].G3X2Matrix[level].FirstLevelRefs.length)
        );
      }

      return updateX12RefSecondLevel(userAddr, ref, level);
    }

    Users[refAddr].G3X2Matrix[level].SecondLevelRefs.push(userAddr);

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
      updateX12(userAddr, refAddr, level, 0);
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
      updateX12(userAddr, refAddr, level, 1);
    } else {
      updateX12(userAddr, refAddr, level, 2);
    }

    updateX12RefSecondLevel(userAddr, refAddr, level);
  }

  function updateX12(
    address userAddr,
    address refAddr,
    uint8 level,
    int x2
  ) private {
    if (x2 == 0) {
      Users[Users[refAddr].G3X2Matrix[level].FirstLevelRefs[0]]
        .G3X2Matrix[level]
        .FirstLevelRefs
        .push(userAddr);

      emit NewUserPlace(
        userAddr,
        Users[refAddr].G3X2Matrix[level].FirstLevelRefs[0],
        2,
        level,
        uint8(
          Users[Users[refAddr].G3X2Matrix[level].FirstLevelRefs[0]]
            .G3X2Matrix[level]
            .FirstLevelRefs
            .length
        )
      );

      emit NewUserPlace(
        userAddr,
        refAddr,
        2,
        level,
        3 +
          uint8(
            Users[Users[refAddr].G3X2Matrix[level].FirstLevelRefs[0]]
              .G3X2Matrix[level]
              .FirstLevelRefs
              .length
          )
      );

      //set current level
      Users[userAddr].G3X2Matrix[level].CurrentRef = Users[refAddr]
        .G3X2Matrix[level]
        .FirstLevelRefs[0];
    } else if (x2 == 1) {
      Users[Users[refAddr].G3X2Matrix[level].FirstLevelRefs[1]]
        .G3X2Matrix[level]
        .FirstLevelRefs
        .push(userAddr);

      emit NewUserPlace(
        userAddr,
        Users[refAddr].G3X2Matrix[level].FirstLevelRefs[1],
        2,
        level,
        uint8(
          Users[Users[refAddr].G3X2Matrix[level].FirstLevelRefs[1]]
            .G3X2Matrix[level]
            .FirstLevelRefs
            .length
        )
      );

      emit NewUserPlace(
        userAddr,
        refAddr,
        2,
        level,
        6 +
          uint8(
            Users[Users[refAddr].G3X2Matrix[level].FirstLevelRefs[1]]
              .G3X2Matrix[level]
              .FirstLevelRefs
              .length
          )
      );

      //set current level
      Users[userAddr].G3X2Matrix[level].CurrentRef = Users[refAddr]
        .G3X2Matrix[level]
        .FirstLevelRefs[1];
    } else {
      Users[Users[refAddr].G3X2Matrix[level].FirstLevelRefs[2]]
        .G3X2Matrix[level]
        .FirstLevelRefs
        .push(userAddr);

      emit NewUserPlace(
        userAddr,
        Users[refAddr].G3X2Matrix[level].FirstLevelRefs[2],
        2,
        level,
        uint8(
          Users[Users[refAddr].G3X2Matrix[level].FirstLevelRefs[2]]
            .G3X2Matrix[level]
            .FirstLevelRefs
            .length
        )
      );

      emit NewUserPlace(
        userAddr,
        refAddr,
        2,
        level,
        9 +
          uint8(
            Users[Users[refAddr].G3X2Matrix[level].FirstLevelRefs[2]]
              .G3X2Matrix[level]
              .FirstLevelRefs
              .length
          )
      );

      //set current level
      Users[userAddr].G3X2Matrix[level].CurrentRef = Users[refAddr]
        .G3X2Matrix[level]
        .FirstLevelRefs[2];
    }
  }

  function updateX12RefSecondLevel(
    address userAddr,
    address refAddr,
    uint8 level
  ) private {
    uint256 len = Users[refAddr].G3X2Matrix[level].SecondLevelRefs.length;

    if (len < 9) {
      if (len >= 5 && len <= 8 && !Users[refAddr].ActiveG3X2Levels[level + 1]) {
        Users[refAddr].Amount += LevelPrice[level];
        return;
      }

      return sendTokenDividends(refAddr, userAddr, 2, level);
    }

    // recycle
    Users[refAddr].G3X2Matrix[level].FirstLevelRefs = new address[](0);
    Users[refAddr].G3X2Matrix[level].SecondLevelRefs = new address[](0);

    if (!Users[refAddr].ActiveG3X2Levels[level + 1] && level != LAST_LEVEL) {
      if (Users[refAddr].Amount >= LevelPrice[level + 1]) {
        _buyNewLevel(refAddr, level + 1);
        Users[refAddr].Amount -= LevelPrice[level + 1];
      } else {
        Users[refAddr].G3X2Matrix[level].Blocked = true;
      }
    }

    Users[refAddr].G3X2Matrix[level].ReinvestCount++;

    if (refAddr != Id1) {
      address freeRefAddr = findFreeX12Referrer(refAddr, level);
      emit Reinvest(refAddr, freeRefAddr, userAddr, 2, level);

      updateX12Referrer(refAddr, freeRefAddr, level);
    } else {
      emit Reinvest(Id1, address(0), userAddr, 2, level);
      sendTokenDividends(Id1, userAddr, 2, level);
    }
  }

  function findFreeX12Referrer(
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

  function sendTokenDividends(
    address refAddr,
    address userAddr,
    uint8 matrix,
    uint8 level
  ) private {
    (address receiver, bool isExtraDividends) = findTokenReceiver(
      refAddr,
      userAddr,
      level
    );

    TransferHelper.safeTransfer(TOKEN, receiver, LevelPrice[level]);

    if (isExtraDividends) {
      emit SentExtraTokenDividends(userAddr, receiver, matrix, level);
    }
  }

  function findTokenReceiver(
    address refAddr,
    address userAddr,
    uint8 level
  ) private returns (address _receiver, bool _isExtraDividends) {
    address receiver = refAddr;
    bool isExtraDividends;

    while (true) {
      if (Users[receiver].G3X2Matrix[level].Blocked) {
        emit MissedTokenReceive(receiver, userAddr, 2, level);
        isExtraDividends = true;
        receiver = Users[receiver].G3X2Matrix[level].CurrentRef;
      } else {
        return (receiver, isExtraDividends);
      }
    }
  }

  function activateAllX12Levels(address userAddr) public {
    require(Id1 == msg.sender, "!Id1");

    for (uint8 i = 1; i <= LAST_LEVEL; i++) {
      Users[userAddr].ActiveG3X2Levels[i] = true;
      Users[userAddr].G3X2Matrix[i].Blocked = false;
    }
  }

  function withdraw() public {
    require(isUserExists(msg.sender), "Users not exists");
    require(Users[msg.sender].Amount > 0, "Users didn't have any amount");
    TransferHelper.safeTransfer(TOKEN, msg.sender, Users[msg.sender].Amount);
  }

  function usersActiveX12Levels(
    address userAddr,
    uint8 level
  ) public view returns (bool) {
    return Users[userAddr].ActiveG3X2Levels[level];
  }

  function usersX12Matrix(
    address userAddr,
    uint8 level
  ) public view returns (address currentRef, address[] memory firstLevelRefs, address[] memory secondLevelRefs, bool blocked) {
    return (
      Users[userAddr].G3X2Matrix[level].CurrentRef,
      Users[userAddr].G3X2Matrix[level].FirstLevelRefs,
      Users[userAddr].G3X2Matrix[level].SecondLevelRefs,
      Users[userAddr].G3X2Matrix[level].Blocked
    );
  }

  function isUserExists(address user) public view returns (bool) {
    return (Users[user].Id != 0);
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

  event Reinvest(
    address indexed user,
    address indexed CurrentRef,
    address indexed caller,
    uint8 matrix,
    uint8 level
  );

  event Upgrade(
    address indexed user,
    address indexed referrer,
    uint8 matrix,
    uint8 level
  );

  event NewUserPlace(
    address indexed user,
    address indexed referrer,
    uint8 matrix,
    uint8 level,
    uint8 place
  );

  event MissedTokenReceive(
    address indexed receiver,
    address indexed from,
    uint8 matrix,
    uint8 level
  );

  event SentExtraTokenDividends(
    address indexed from,
    address indexed receiver,
    uint8 matrix,
    uint8 level
  );
}