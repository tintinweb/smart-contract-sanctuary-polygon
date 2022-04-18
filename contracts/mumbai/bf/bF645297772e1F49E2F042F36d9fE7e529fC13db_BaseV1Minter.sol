// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "../../lib/Math.sol";
import "../../interface/IUnderlying.sol";
import "../../interface/IVoter.sol";
import "../../interface/IVe.sol";
import "../../interface/IVeDist.sol";
import "../../interface/IMinter.sol";

/// @title Codifies the minting rules as per ve(3,3),
///        abstracted from the token to support any token that allows minting
contract BaseV1Minter is IMinter {

  /// @dev Allows minting once per week (reset every Thursday 00:00 UTC)
  uint internal constant week = 86400 * 7;
  uint internal constant emission = 98;
  uint internal constant tail_emission = 2;
  /// @dev 2% per week target emission
  uint internal constant target_base = 100;
  /// @dev 0.2% per week target emission
  uint internal constant tail_base = 1000;
  IUnderlying public immutable _token;
  IVoter public immutable _voter;
  IVe public immutable _ve;
  IVeDist public immutable _ve_dist;
  uint public weekly = 5_000_000e18;
  uint public initial_stub_circulation_supply;
  uint public active_period;
  uint internal constant lock = 86400 * 7 * 52 * 4;

  address internal initializer;

  event Mint(address indexed sender, uint weekly, uint growth, uint circulating_supply, uint circulating_emission);

  constructor(
    address __voter, // the voting & distribution system
    address __ve, // the ve(3,3) system that will be locked into
    address __ve_dist // the distribution system that ensures users aren't diluted
  ) {
    initializer = msg.sender;
    _token = IUnderlying(IVe(__ve).token());
    _voter = IVoter(__voter);
    _ve = IVe(__ve);
    _ve_dist = IVeDist(__ve_dist);
    active_period = (block.timestamp + (2 * week)) / week * week;
  }

  /// @dev sum amounts / max = % ownership of top protocols,
  ///      so if initial 20m is distributed, and target is 25% protocol ownership,
  ///      then max - 4 x 20m = 80m
  function initialize(
    address[] memory claimants,
    uint[] memory amounts,
    uint total_amount
  ) external {
    require(initializer == msg.sender);
    _token.mint(address(this), total_amount);
    // 20% of minted will be a stub circulation supply for a warming up period
    initial_stub_circulation_supply = total_amount / 5;
    _token.approve(address(_ve), type(uint).max);
    uint sum;
    for (uint i = 0; i < claimants.length; i++) {
      _ve.create_lock_for(amounts[i], lock, claimants[i]);
      sum += amounts[i];
    }
    require(sum == total_amount, "Wrong total_amount");
    initializer = address(0);
    active_period = (block.timestamp + week) / week * week;
  }

  /// @dev Calculate circulating supply as total token supply - locked supply - veDist balance - minter balance
  function circulating_supply() external view returns (uint) {
    return _circulating_supply();
  }

  function _circulating_supply() internal view returns (uint) {
    return _token.totalSupply() - IUnderlying(address(_ve)).totalSupply()
    // exclude veDist token balance from circulation - users unable to claim them without lock
    // late claim will lead to wrong circulation supply calculation
    - _token.balanceOf(address(_ve_dist))
    // exclude balance on minter, it is obviously locked
    - _token.balanceOf(address(this));
  }

  function _circulating_supply_adjusted() internal view returns (uint) {
    // we need a stub supply for cover initial gap when huge amount of tokens was distributed and locked
    return Math.max(_circulating_supply(), initial_stub_circulation_supply);
  }

  /// @dev Emission calculation is 2% of available supply to mint adjusted by circulating / total supply
  function calculate_emission() external view returns (uint) {
    return _calculate_emission();
  }

  function _calculate_emission() internal view returns (uint) {
    // use adjusted circulation supply for avoid first weeks gaps
    return weekly * emission * _circulating_supply_adjusted() / target_base / _token.totalSupply();
  }

  /// @dev Weekly emission takes the max of calculated (aka target) emission versus circulating tail end emission
  function weekly_emission() external view returns (uint) {
    return _weekly_emission();
  }

  function _weekly_emission() internal view returns (uint) {
    return Math.max(_calculate_emission(), _circulating_emission());
  }

  /// @dev Calculates tail end (infinity) emissions as 0.2% of total supply
  function circulating_emission() external view returns (uint) {
    return _circulating_emission();
  }

  function _circulating_emission() internal view returns (uint) {
    return _circulating_supply() * tail_emission / tail_base;
  }

  /// @dev Calculate inflation and adjust ve balances accordingly
  function calculate_growth(uint _minted) external view returns (uint) {
    return _calculate_growth(_minted);
  }

  function _calculate_growth(uint _minted) internal view returns (uint) {
    return IUnderlying(address(_ve)).totalSupply() * _minted / _token.totalSupply();
  }

  /// @dev Update period can only be called once per cycle (1 week)
  function update_period() external override returns (uint) {
    uint _period = active_period;
    if (block.timestamp >= _period + week && initializer == address(0)) {// only trigger if new week
      _period = block.timestamp / week * week;
      active_period = _period;
      uint _weekly = _weekly_emission();
      // slightly decrease weekly emission
      weekly = weekly * emission / target_base;
      // decrease stub supply every week until reach nearly zero amount
      if (initial_stub_circulation_supply > 100) {
        initial_stub_circulation_supply -= initial_stub_circulation_supply / 10;
      }

      uint _growth = _calculate_growth(_weekly);
      uint _required = _growth + _weekly;
      uint _balanceOf = _token.balanceOf(address(this));
      if (_balanceOf < _required) {
        _token.mint(address(this), _required - _balanceOf);
      }

      require(_token.transfer(address(_ve_dist), _growth));
      // checkpoint token balance that was just minted in ve_dist
      _ve_dist.checkpoint_token();
      // checkpoint supply
      _ve_dist.checkpoint_total_supply();

      _token.approve(address(_voter), _weekly);
      _voter.notifyRewardAmount(_weekly);

      emit Mint(msg.sender, _weekly, _growth, _circulating_supply(), _circulating_emission());
    }
    return _period;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

library Math {

  function max(uint a, uint b) internal pure returns (uint) {
    return a >= b ? a : b;
  }

  function min(uint a, uint b) internal pure returns (uint) {
    return a < b ? a : b;
  }

  function closeTo(uint a, uint b, uint target) internal pure returns (bool) {
    if (a > b) {
      if (a - b <= target) {
        return true;
      }
    } else {
      if (b - a <= target) {
        return true;
      }
    }
    return false;
  }

  function sqrt(uint y) internal pure returns (uint z) {
    if (y > 3) {
      z = y;
      uint x = y / 2 + 1;
      while (x < z) {
        z = x;
        x = (y / x + x) / 2;
      }
    } else if (y != 0) {
      z = 1;
    }
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IUnderlying {
  function approve(address spender, uint value) external returns (bool);

  function mint(address, uint) external;

  function totalSupply() external view returns (uint);

  function balanceOf(address) external view returns (uint);

  function transfer(address, uint) external returns (bool);

  function decimals() external returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IVoter {

  function _ve() external view returns (address);

  function attachTokenToGauge(uint _tokenId, address account) external;

  function detachTokenFromGauge(uint _tokenId, address account) external;

  function emitDeposit(uint _tokenId, address account, uint amount) external;

  function emitWithdraw(uint _tokenId, address account, uint amount) external;

  function distribute(address _gauge) external;

  function notifyRewardAmount(uint amount) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IVe {

  struct Point {
    int128 bias;
    int128 slope; // # -dweight / dt
    uint ts;
    uint blk; // block
  }
  /* We cannot really do block numbers per se b/c slope is per time, not per block
  * and per block could be fairly bad b/c Ethereum changes blocktimes.
  * What we can do is to extrapolate ***At functions */

  struct LockedBalance {
    int128 amount;
    uint end;
  }

  function token() external view returns (address);

  function balanceOfNFT(uint) external view returns (uint);

  function isApprovedOrOwner(address, uint) external view returns (bool);

  function create_lock_for(uint, uint, address) external returns (uint);

  function user_point_epoch(uint tokenId) external view returns (uint);

  function epoch() external view returns (uint);

  function user_point_history(uint tokenId, uint loc) external view returns (Point memory);

  function point_history(uint loc) external view returns (Point memory);

  function checkpoint() external;

  function deposit_for(uint tokenId, uint value) external;

  function attach(uint tokenId) external;

  function detach(uint tokenId) external;

  function voting(uint tokenId) external;

  function abstain(uint tokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IVeDist {
  function checkpoint_token() external;

  function checkpoint_total_supply() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IMinter {
  function update_period() external returns (uint);
}