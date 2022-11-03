// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }
}

contract MultiTransfer {
  using SafeMath for uint256;

  function multiTransferToken(
    address[] memory _tokens,
    address[] memory _dsts,
    uint256[] memory _values
  ) external {
    address sender = msg.sender;
    for (uint256 i = 0; i < _tokens.length; i++) {
      if (_tokens[i] == address(0)) {
        safeTransfer(_dsts[i], _values[i]);
      }
      safeTransferTokenFrom(_tokens[i], sender, _dsts[i], _values[i]);
    }
  }

  function safeTransferTokenFrom(
    address token,
    address from,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      'TransferHelper::transferFrom: transferFrom failed'
    );
  }

  function safeTransfer(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, 'TransferHelper::safeTransferETH: coin transfer failed');
  }
}